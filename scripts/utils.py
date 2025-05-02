import functools
import logging
import os
import shlex
import subprocess
import time
from multiprocessing import cpu_count as _cpu_count
from pathlib import Path
from typing import IO, Any, Callable, Concatenate, Mapping, ParamSpec, Sequence, TypeVar, overload

import luadata  # type: ignore
from rich.logging import RichHandler
from ruamel.yaml import YAML

_logger = logging.getLogger(__name__)


REPO_PATH = Path(__file__).parent.parent
ARTIFACTS_PATH = REPO_PATH / "__artifacts__"
TMP_PATH = ARTIFACTS_PATH / "tmp"
DATA_PATH = Path(__file__).parent / "data"
SCRIPTS_PATH = DATA_PATH / "scripts"


def _cgroup_cpu_count() -> int | None:
    cgroup_info = Path("/sys/fs/cgroup/cpu.max")
    if not cgroup_info.exists():
        return None
    # Wrap with try-except in case we encounter a weird system
    try:
        cpu_micros_str = cgroup_info.read_text(encoding="utf-8").strip().split()[0]
        if cpu_micros_str == "max":
            return None
        cpu_micros = int(cpu_micros_str)
        # more like milli * centi
        return int(cpu_micros / 100000)
    # pylint: disable-next=broad-except
    except Exception:
        pass
    return None


def cpu_count() -> int:
    container_cpus = _cgroup_cpu_count()
    if container_cpus is not None:
        return container_cpus

    return _cpu_count()


def _paths2shell(paths: Sequence[Path]) -> str:
    # hopefully no one is that crazy to use colon in the path...
    return ":".join([str(p) for p in paths])


def shell_command(
    cmd: Sequence[str | Path] | str,
    *,
    extra_env: Mapping[str, str | Path] | None = None,
    extra_paths: Sequence[Path] | None = None,
    capture_output: bool = False,
    inputs: None | str | bytes = None,
    stdout: None | int | IO[Any] = None,
    stderr: None | int | IO[Any] = None,
    suppress_env_log: bool = False,
    cwd: Path | None = None,
) -> str:
    extra_env = extra_env or {}
    extra_paths = extra_paths or []

    if "PATH" in extra_env:
        raise ValueError("Do not pass PATH to extra_env. Use extra_paths instead.")

    extra_paths_str = _paths2shell(extra_paths)
    print_cmd = ""

    if cwd is not None:
        print_cmd += f"cd {shlex.quote(str(cwd))} && "

    if inputs is not None:
        print_cmd += "echo $CAPTURE | "

    if not suppress_env_log:
        for k, val in extra_env.items():
            print_cmd += f"{shlex.quote(str(k))}={shlex.quote(str(val))} "

    if extra_paths:
        print_cmd += f'PATH="{extra_paths_str}:${{PATH}}" '

    if isinstance(cmd, list):
        print_cmd += " ".join([shlex.quote(str(arg)) for arg in cmd])
    else:
        assert isinstance(cmd, str)
        print_cmd += cmd

    suppress_stdout = capture_output or stdout is not None
    suppress_stderr = capture_output or stderr is not None
    if suppress_stdout and suppress_stderr:
        print_cmd += " &> $CAPTURE"
    elif suppress_stdout:
        print_cmd += " 1> $CAPTURE"
    elif suppress_stderr:
        print_cmd += " 2> $CAPTURE"

    print_cmd = print_cmd.strip()
    return print_cmd


def run_shell(
    cmd: Sequence[str | Path] | str,
    *,
    extra_env: Mapping[str, str | Path] | None = None,
    extra_paths: Sequence[Path] | None = None,
    capture_output: bool = False,
    inputs: None | str | bytes = None,
    stdout: None | int | IO[Any] = None,
    stderr: None | int | IO[Any] = None,
    suppress_cmd_log: bool = False,
    suppress_env_log: bool = False,
    cwd: Path | None = None,
    check: bool = True,
    loglevel: int = logging.INFO,
) -> subprocess.CompletedProcess[str]:
    extra_env = dict(extra_env) if extra_env is not None else {}
    extra_paths = list(extra_paths) if extra_paths is not None else []

    current_loglevel = _logger.getEffectiveLevel()
    if current_loglevel > loglevel and not capture_output and stdout is None:
        stdout = subprocess.DEVNULL
    if current_loglevel > logging.ERROR and not capture_output and stderr is None:
        stderr = subprocess.DEVNULL

    env = os.environ.copy()
    env.update({k: str(v) for k, v in extra_env.items()})

    if extra_paths:
        new_path = _paths2shell(extra_paths)
        assert new_path.strip()
        if "PATH" in env and env["PATH"].strip():
            new_path += ":" + env["PATH"]
        env["PATH"] = new_path

    if not suppress_cmd_log:
        print_cmd = shell_command(
            cmd,
            extra_env=extra_env,
            extra_paths=extra_paths,
            capture_output=capture_output,
            inputs=inputs,
            stdout=stdout,
            stderr=stderr,
            suppress_env_log=suppress_env_log,
            cwd=cwd,
        )
        _logger.log(loglevel, f"[RUNNING IN SHELL]: {print_cmd}")

    if isinstance(cmd, str):
        return subprocess.run(
            cmd,
            env=env,
            check=check,
            capture_output=capture_output,
            input=inputs,
            stdout=stdout,
            stderr=stderr,
            text=True,
            cwd=cwd,
            shell=True,
            executable="bash",
        )
    if isinstance(cmd, Sequence):
        return subprocess.run(
            cmd,
            env=env,
            check=check,
            capture_output=capture_output,
            input=inputs,
            stdout=stdout,
            stderr=stderr,
            text=True,
            cwd=cwd,
        )

    assert False, f"Unexpected command type for run_shell util: {type(cmd)}"


_P = ParamSpec("_P")
_R = TypeVar("_R")


@overload
def retry(
    func: Callable[_P, _R], *, delay: int | float = ..., max_tries: int = ..., suppress_logger: bool = ...
) -> Callable[_P, _R]: ...
@overload
def retry(
    func: None = None, *, delay: int | float = ..., max_tries: int = ..., suppress_logger: bool = ...
) -> Callable[[Callable[_P, _R]], Callable[_P, _R]]: ...


def retry(
    func: Callable[_P, _R] | None = None, *, delay: int | float = 5, max_tries: int = 5, suppress_logger: bool = False
) -> Callable[[Callable[_P, _R]], Callable[_P, _R]] | Callable[_P, _R]:
    assert max_tries > 0

    def retry_decorator(func: Callable[_P, _R]) -> Callable[_P, _R]:
        @functools.wraps(func)
        def wrapper(*args: _P.args, **kwargs: _P.kwargs) -> _R:
            for i in range(max_tries):
                setattr(wrapper, "current_try", i)
                try:
                    return func(*args, **kwargs)
                # pylint: disable-next=broad-except
                except Exception as exc:
                    if i + 1 >= max_tries:
                        raise
                    if not suppress_logger:
                        _logger.warning(f"Function '{func.__name__}' failed with error:")
                        _logger.warning(f"  {type(exc).__name__}: {exc}")
                        _logger.warning(f"  Retry {i + 2} of {max_tries}...")
                    time.sleep(delay)
            assert False, "Unreachable."

        return wrapper

    if func is not None:
        return retry_decorator(func)

    return retry_decorator


def makelike(
    artifact: Path, *sources: Path | Callable[[], Path], auto_create: bool = False
) -> Callable[[Callable[Concatenate[Path, list[Path], _P], None]], Callable[_P, Path]]:
    def makelike_decorator(func: Callable[Concatenate[Path, list[Path], _P], None]) -> Callable[_P, Path]:
        @functools.wraps(func)
        def wrapper(*args: _P.args, **kwargs: _P.kwargs) -> Path:
            forward_sources: list[Path] = []

            uptodate = True
            artifact_mtime = None
            reason = f"Target {func.__name__} with artifact {artifact} is "
            if not artifact.exists():
                uptodate = False
                reason += f"not up-to-date, because its artifact {artifact} does not exist"
            else:
                artifact_mtime = artifact.stat().st_mtime

            for source in sources:
                if callable(source):
                    source_path = source()
                elif isinstance(source, Path):
                    source_path = source
                else:
                    assert False

                assert (
                    source_path.exists()
                ), f"Source file {source_path} does not exist for a makelike function {func.__name__}!"
                forward_sources.append(source_path)
                if not uptodate:
                    continue

                assert artifact_mtime is not None
                if source_path.stat().st_mtime > artifact_mtime:
                    reason += f"not up-to-date, because source {source_path} is newer than artifact {artifact}"
                    uptodate = False

            if uptodate:
                reason += "up-to-date"
                _logger.debug(reason)
                return artifact

            _logger.debug(reason)
            func(artifact, forward_sources, *args, **kwargs)
            if auto_create:
                artifact.parent.mkdir(parents=True, exist_ok=True)
                artifact.touch()

            assert artifact.exists(), f"Artifact {artifact} was not created in makelike function {func.__name__}!"
            return artifact

        return wrapper

    return makelike_decorator


def lua_read(path: Path) -> dict[str, Any]:
    lua = luadata.read(path, encoding="utf-8")
    assert isinstance(lua, dict)
    return lua


def lua_write(path: Path, data: dict[str, Any]) -> None:
    luadata.write(path, data, encoding="utf-8", indent="  ", prefix="return ")


def yaml_read(path: Path) -> tuple[dict[str, Any] | list[Any], YAML]:
    yaml = YAML()
    yaml.preserve_quotes = True
    val = yaml.load(path)
    assert isinstance(val, (dict, list))
    return val, yaml


def yaml_write(path: Path, data: dict[str, Any], yaml: YAML | None = None, *, width: int = 120) -> None:
    if yaml is None:
        yaml = YAML()

    if width is not None:
        yaml.width = width

    yaml.dump(data, path)


class _LoggerFormatter(logging.Formatter):
    formats = {
        logging.DEBUG: "[grey]%(message)s[/]",
        logging.INFO: "[green]%(message)s[/]",
        logging.WARNING: "[yellow][WARNING]: %(message)s[/]",
        logging.ERROR: "[red][ERROR]: %(message)s[/]",
    }

    def __init__(self) -> None:
        super().__init__()
        self.formatters = {level: logging.Formatter(fmt) for level, fmt in self.formats.items()}

    def format(self, record: Any) -> str:
        formatter = self.formatters[logging.DEBUG]
        for level, fmt in self.formatters.items():
            if record.levelno >= level:
                formatter = fmt

        return formatter.format(record)


def setup_logger(logger: logging.Logger | None = None) -> None:
    logger = logger or logging.getLogger()
    handler = RichHandler(show_time=False, show_path=False, show_level=False, markup=True)
    handler.setFormatter(_LoggerFormatter())
    handler.console.stderr = True
    logger.addHandler(handler)
