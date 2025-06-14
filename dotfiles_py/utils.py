import functools
import logging
import os
import shlex
import subprocess
import time
from collections.abc import Callable, Mapping, Sequence
from multiprocessing import cpu_count as _cpu_count
from pathlib import Path
from typing import IO, Any, ClassVar, Concatenate, ParamSpec, TypeVar, overload

import luadata  # type: ignore[import-untyped]
import typer
from rich.logging import RichHandler
from ruamel.yaml import YAML

_logger = logging.getLogger(__name__)


REPO_PATH = Path(__file__).parent.parent
DOTPY_PATH = Path(__file__).parent
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
    except Exception as exc:  # noqa: BLE001
        _logger.debug(f"Could not read cgroup cpu.max: {exc}")
    return None


def cpu_count() -> int:
    container_cpus = _cgroup_cpu_count()
    if container_cpus is not None:
        return container_cpus

    return _cpu_count()


def _paths2shell(paths: Sequence[Path]) -> str:
    # hopefully no one is that crazy to use colon in the path...
    return ":".join([str(p) for p in paths])


def shell_command(  # noqa: PLR0913, C901
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
        msg = "Do not pass PATH to extra_env. Use extra_paths instead."
        raise ValueError(msg)

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
    elif isinstance(cmd, str):
        print_cmd += cmd
    else:
        msg = f"Unexpected command type for run_shell util: {type(cmd)}"
        raise TypeError(msg)

    suppress_stdout = capture_output or stdout is not None
    suppress_stderr = capture_output or stderr is not None
    if suppress_stdout and suppress_stderr:
        print_cmd += " &> $CAPTURE"
    elif suppress_stdout:
        print_cmd += " 1> $CAPTURE"
    elif suppress_stderr:
        print_cmd += " 2> $CAPTURE"

    return print_cmd.strip()


def run_shell(  # noqa: PLR0913
    cmd: Sequence[str | Path],
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

    env = os.environ.copy()
    env.update({k: str(v) for k, v in extra_env.items()})

    if extra_paths:
        new_path = _paths2shell(extra_paths).strip()
        if not new_path:
            msg = f"PATH is empty, cannot add extra_paths {extra_paths}"
            raise ValueError(msg)
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
    return subprocess.run(  # noqa: S603
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


_P = ParamSpec("_P")
_R = TypeVar("_R")


@overload
def retry(
    func: Callable[_P, _R],
    *,
    delay: float = ...,
    max_tries: int = ...,
    suppress_logger: bool = ...,
) -> Callable[_P, _R]: ...
@overload
def retry(
    func: None = None,
    *,
    delay: float = ...,
    max_tries: int = ...,
    suppress_logger: bool = ...,
) -> Callable[[Callable[_P, _R]], Callable[_P, _R]]: ...


def retry(
    func: Callable[_P, _R] | None = None,
    *,
    delay: float = 5,
    max_tries: int = 5,
    suppress_logger: bool = False,
) -> Callable[[Callable[_P, _R]], Callable[_P, _R]] | Callable[_P, _R]:
    if max_tries <= 0:
        msg = f"max_tries must be greater than 0, got {max_tries}"
        raise ValueError(msg)

    def retry_decorator(func: Callable[_P, _R]) -> Callable[_P, _R]:
        @functools.wraps(func)
        def wrapper(*args: _P.args, **kwargs: _P.kwargs) -> _R:
            for i in range(max_tries):
                wrapper.current_try = i  # type: ignore[attr-defined]
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
            msg = "Unreachable."
            raise AssertionError(msg)

        return wrapper

    if func is not None:
        return retry_decorator(func)

    return retry_decorator


def makelike(  # noqa: C901
    artifact: Path,
    *sources: Path | Callable[[], Path],
    auto_create: bool = False,
) -> Callable[[Callable[Concatenate[Path, list[Path], _P], None]], Callable[_P, Path]]:
    def makelike_decorator(func: Callable[Concatenate[Path, list[Path], _P], None]) -> Callable[_P, Path]:  # noqa: C901
        @functools.wraps(func)
        def wrapper(*args: _P.args, **kwargs: _P.kwargs) -> Path:  # noqa: C901, PLR0912
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
                    msg = f"Unexpected type for source: {type(source)}"
                    raise TypeError(msg)

                if not source_path.exists():
                    msg = f"Source file {source_path} does not exist for a makelike function {func.__name__}!"
                    raise FileNotFoundError(msg)
                forward_sources.append(source_path)
                if not uptodate:
                    continue

                if artifact_mtime is None:
                    msg = f"Artifact {artifact} mtime is None!"
                    raise FileNotFoundError(msg)

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

            if not artifact.exists():
                msg = f"Artifact {artifact} was not created in makelike function {func.__name__}!"
                raise FileNotFoundError(msg)
            return artifact

        return wrapper

    return makelike_decorator


def lua_read(path: Path) -> dict[str, Any]:
    lua = luadata.read(path, encoding="utf-8")
    if not isinstance(lua, dict):
        msg = f"Expected a dictionary in {path}, got {type(lua)}"
        raise TypeError(msg)
    return lua


def lua_write(path: Path, data: dict[str, Any]) -> None:
    luadata.write(path, data, encoding="utf-8", indent="  ", prefix="return ")


def yaml_read(path: Path) -> tuple[dict[str, Any] | list[Any], YAML]:
    yaml = YAML()
    yaml.preserve_quotes = True
    val = yaml.load(path)
    if not isinstance(val, dict | list):
        msg = f"Expected a dictionary or list in {path}, got {type(val)}"
        raise TypeError(msg)
    return val, yaml


def yaml_write(path: Path, data: dict[str, Any], yaml: YAML | None = None, *, width: int = 120) -> None:
    if yaml is None:
        yaml = YAML()

    if width is not None:
        yaml.width = width

    yaml.dump(data, path)


class _LoggerFormatter(logging.Formatter):
    formats: ClassVar = {
        logging.DEBUG: "[grey]%(message)s[/]",
        logging.INFO: "[green]%(message)s[/]",
        logging.WARNING: "[yellow][WARNING]: %(message)s[/]",
        logging.ERROR: "[red][ERROR]: %(message)s[/]",
    }

    def __init__(self) -> None:
        super().__init__()
        self.formatters = {level: logging.Formatter(fmt) for level, fmt in self.formats.items()}

    def format(self, record: Any) -> str:  # noqa: ANN401
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


@overload
def typer_exit(
    func: Callable[_P, _R],
    *,
    exceptions: tuple[type[Exception], ...] = ...,
    code: int = ...,
) -> Callable[_P, _R]: ...


@overload
def typer_exit(
    func: None = None,
    *,
    exceptions: tuple[type[Exception], ...] = ...,
    code: int = ...,
) -> Callable[[Callable[_P, _R]], Callable[_P, _R]]: ...


def typer_exit(
    func: Callable[_P, _R] | None = None,
    *,
    exceptions: tuple[type[Exception], ...] = (Exception,),
    code: int = 1,
) -> Callable[[Callable[_P, _R]], Callable[_P, _R]] | Callable[_P, _R]:
    def exit_decorator(func: Callable[_P, _R]) -> Callable[_P, _R]:
        @functools.wraps(func)
        def wrapper(*args: _P.args, **kwargs: _P.kwargs) -> _R:
            try:
                return func(*args, **kwargs)
            except exceptions as exc:
                raise typer.Exit(code) from exc

        return wrapper

    if func is not None:
        return exit_decorator(func)

    return exit_decorator
