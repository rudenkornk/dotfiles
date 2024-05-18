import functools as _functools
import hashlib as _hashlib
import inspect as _inspect
import logging as _logging
import os as _os
import shlex as _shlex
import shutil as _shutil
import subprocess as _subprocess
import sys as _sys
import time as _time
import traceback as _traceback
from pathlib import Path as _Path
from typing import IO as _IO
from typing import Any as _Any
from typing import Callable as _Callable
from typing import Concatenate as _Concatenate
from typing import ParamSpec as _ParamSpec
from typing import Sequence as _Sequence
from typing import TypeVar as _TypeVar

import luadata as _luadata  # type: ignore
from ruamel.yaml import YAML as _YAML

_logger = _logging.getLogger(__name__)


def repo_path() -> _Path:
    return _Path(__file__).parent.parent.parent


def artifacts_path() -> _Path:
    return repo_path() / "__artifacts__"


def tmp_path() -> _Path:
    return artifacts_path() / "tmp"


def _paths2shell(paths: _Sequence[_Path]) -> str:
    # hopefully no one is that crazy to use colon in the path...
    return ":".join([str(p) for p in paths])


def shell_command(
    cmd: _Sequence[str | _Path] | str,
    extra_env: dict[str, str] | None = None,
    extra_paths: _Sequence[_Path] | None = None,
    capture_output: bool = False,
    inputs: None | str | bytes = None,
    stdout: None | int | _IO[_Any] = None,
    stderr: None | int | _IO[_Any] = None,
    suppress_env_log: bool = False,
    cwd: _Path | None = None,
) -> str:
    extra_env = extra_env or {}
    extra_paths = extra_paths or []

    if "PATH" in extra_env:
        raise ValueError("Do not pass PATH to extra_env. Use extra_paths instead.")

    extra_paths_str = _paths2shell(extra_paths)
    print_cmd = ""

    if cwd is not None:
        print_cmd += f"cd {_shlex.quote(str(cwd))} && "

    if inputs is not None:
        print_cmd += "echo $CAPTURE | "

    if not suppress_env_log:
        for k, val in extra_env.items():
            print_cmd += f"{_shlex.quote(str(k))}={_shlex.quote(str(val))} "

    if extra_paths:
        print_cmd += f'PATH="{extra_paths_str}:${{PATH}}" '

    if isinstance(cmd, list):
        print_cmd += " ".join([_shlex.quote(str(arg)) for arg in cmd])
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


def get_venv(requirements_path: _Path) -> _Path:
    requirements_hash = _hashlib.md5(requirements_path.read_bytes()).hexdigest()[:12]
    venv_path = tmp_path() / "venv" / requirements_hash
    bin_path = venv_path / "bin"
    venv_executable = bin_path / "python"

    if venv_executable.exists():
        return venv_path

    _logger.debug(f"Creating virtual environment in {venv_path} with {requirements_path})")
    _shutil.rmtree(venv_path, ignore_errors=True)
    run_shell([_sys.executable, "-m", "venv", venv_path], capture_output=True, suppress_cmd_log=True)
    if not venv_executable.exists():
        raise RuntimeError("Failed to create virtual environment. Did you install pip?")
    run_shell(
        [venv_executable, "-m", "pip", "install", "-r", requirements_path],
        requirements_txt=requirements_path,
        capture_output=True,
        suppress_cmd_log=True,
    )

    return venv_path


def run_shell(
    cmd: _Sequence[str | _Path],
    *,
    extra_env: dict[str, str] | None = None,
    requirements_txt: _Path | None = None,
    extra_paths: _Sequence[_Path] | None = None,
    capture_output: bool = False,
    inputs: None | str | bytes = None,
    stdout: None | int | _IO[_Any] = None,
    stderr: None | int | _IO[_Any] = None,
    suppress_cmd_log: bool = False,
    suppress_env_log: bool = False,
    cwd: _Path | None = None,
    check: bool = True,
    loglevel: int = _logging.INFO,
) -> _subprocess.CompletedProcess[str]:
    extra_env = extra_env.copy() if extra_env is not None else {}
    extra_paths = list(extra_paths) if extra_paths is not None else []

    current_loglevel = _logger.getEffectiveLevel()
    if current_loglevel > loglevel and not capture_output and stdout is None:
        stdout = _subprocess.DEVNULL
    if current_loglevel > _logging.ERROR and not capture_output and stderr is None:
        stderr = _subprocess.DEVNULL

    if requirements_txt is not None:
        venv_path = get_venv(requirements_txt)
        extra_paths.append(venv_path / "bin")
        extra_env["VIRTUAL_ENV"] = str(venv_path)

    env = _os.environ.copy()
    env.update(extra_env)
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

    return _subprocess.run(
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


_P = _ParamSpec("_P")
_R = _TypeVar("_R")


def retry(
    delay: int | float = 5, max_tries: int = 5, suppress_logger: bool = False
) -> _Callable[[_Callable[_P, _R]], _Callable[_P, _R]]:
    assert max_tries > 0

    def retry_decorator(func: _Callable[_P, _R]) -> _Callable[_P, _R]:
        @_functools.wraps(func)
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
                    _time.sleep(delay)
            assert False, "Unreachable."

        return wrapper

    return retry_decorator


def makelike(
    artifact: _Path, *sources: _Path | _Callable[[], _Path], auto_create: bool = False
) -> _Callable[[_Callable[_Concatenate[_Path, list[_Path], _P], None]], _Callable[_P, _Path]]:
    def makelike_decorator(func: _Callable[_Concatenate[_Path, list[_Path], _P], None]) -> _Callable[_P, _Path]:
        @_functools.wraps(func)
        def wrapper(*args: _P.args, **kwargs: _P.kwargs) -> _Path:
            forward_sources: list[_Path] = []

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
                elif isinstance(source, _Path):
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


def lua_read(path: _Path) -> dict[str, _Any]:
    lua = _luadata.read(path, encoding="utf-8")
    assert isinstance(lua, dict)
    return lua


def lua_write(path: _Path, data: dict[str, _Any]) -> None:
    _luadata.write(path, data, encoding="utf-8", indent="  ", prefix="return ")


def yaml_read(path: _Path) -> dict[str, _Any]:
    val = _YAML().load(path)
    assert isinstance(val, dict)
    return val


def yaml_write(path: _Path, data: dict[str, _Any]) -> None:
    yaml = _YAML()
    yaml.width = 120
    _YAML().dump(data, path)


class _LoggerFormatter(_logging.Formatter):
    grey = "\x1b[38;20m"
    green = "\x1b[32;20m"
    yellow = "\x1b[33;20m"
    red = "\x1b[38;5;196m"
    bold_red = "\x1b[31;1m"
    bg_palette = [
        "\x1b[41m",
        "\x1b[42m",
        "\x1b[43m",
        "\x1b[44m",
        "\x1b[45m",
        "\x1b[46m",
        "\x1b[47m",
        "\x1b[100m",
        "\x1b[101m",
        "\x1b[102m",
        "\x1b[103m",
        "\x1b[104m",
        "\x1b[105m",
        "\x1b[106m",
        "\x1b[107m",
    ]
    reset = "\x1b[0m"
    bg_reset = "\x1b[49m"
    ok_format = "%(message)s"
    warning_format = "[WARNING]: %(message)s"
    error_format = "[ERROR]: %(message)s"
    formats_info = {
        _logging.DEBUG: (ok_format, grey),
        _logging.INFO: (ok_format, green),
        _logging.WARNING: (warning_format, yellow),
        _logging.ERROR: (error_format, red),
        _logging.CRITICAL: (error_format, bold_red),
    }

    def __init__(self, stream: _IO[_Any]) -> None:
        self._stream = stream
        self.indent = ""
        self.stack_based_indent = False
        self.stack_based_color = False
        self._formatters = self._get_formatters(stream)
        super().__init__()

    @staticmethod
    def _get_formatters(stream: _IO[_Any]) -> dict[int, _logging.Formatter]:
        formatters = {}
        for level, (fmt, color) in _LoggerFormatter.formats_info.items():
            if stream.isatty():
                fmt = color + fmt + _LoggerFormatter.reset
            formatter = _logging.Formatter(fmt)
            formatters[level] = formatter
        return formatters

    @staticmethod
    def _stack_based_indent(stream: _IO[_Any], indented: bool, colored: bool) -> str:
        indent = ""
        stacklen = len(_inspect.stack())
        home = str(_Path.home())
        interesting_index: int | None = None
        stack = _inspect.stack()
        skip_asyncio = False
        # pylint: disable-next=consider-using-enumerate
        for index in range(len(stack)):
            filename = stack[index].filename
            # print(stack[index].filename, stack[index].function)
            if "asyncio" in filename.split(_os.sep):
                skip_asyncio = True
            if filename.startswith(home) and interesting_index is None and not filename == __file__:
                interesting_index = index

        skip = 7
        if skip_asyncio:
            skip += 6
        if interesting_index is not None:
            skip += interesting_index
        indent_len = max(0, stacklen - skip)
        if indented:
            indent += "  " * indent_len

        if stream.isatty() and colored:
            bg_color_index = 0
            if interesting_index is not None:
                interesting = _inspect.stack()[interesting_index]
                frame_hash = hash(str(id(interesting.frame)))
                bg_color_index = frame_hash % len(_LoggerFormatter.bg_palette)
            bg_color = _LoggerFormatter.bg_palette[bg_color_index]
            indent = indent + bg_color + " " + _LoggerFormatter.bg_reset

        return indent

    def _format(self, msg: str) -> str:
        indent = self.indent
        indent += self._stack_based_indent(self._stream, self.stack_based_indent, self.stack_based_color)

        return indent + msg

    def format(self, record: _Any) -> str:
        formatter = self._formatters[record.levelno]
        raw_result = formatter.format(record)
        result = self._format(raw_result)
        return result


class _LoggerFilter(_logging.Filter):
    def __init__(self, min_level: int, max_level: int) -> None:
        self._min = min_level
        self._max = max_level
        super().__init__()

    def filter(self, record: _Any) -> bool:
        check = self._min <= record.levelno < self._max
        assert isinstance(check, bool)
        return check


def format_logging(logger: _logging.Logger = _logging.getLogger(), stack_based: bool = False) -> None:
    stdout_handler = _logging.StreamHandler(_sys.stdout)
    stdout_formatter = _LoggerFormatter(_sys.stdout)
    stdout_formatter.stack_based_indent = stack_based
    stdout_formatter.stack_based_color = False
    stdout_handler.setFormatter(stdout_formatter)
    stdout_handler.addFilter(_LoggerFilter(_logging.DEBUG, _logging.WARNING))
    logger.addHandler(stdout_handler)

    stderr_handler = _logging.StreamHandler(_sys.stderr)
    stderr_formatter = _LoggerFormatter(_sys.stderr)
    stderr_formatter.stack_based_indent = stack_based
    stderr_formatter.stack_based_color = False
    stderr_handler.setFormatter(stderr_formatter)
    stderr_handler.addFilter(_LoggerFilter(_logging.WARNING, _logging.CRITICAL + 1000))
    logger.addHandler(stderr_handler)


def main(stack_based: bool = False) -> _Callable[[_Callable[_P, _R]], _Callable[_P, _R]]:
    def main_decorator(func: _Callable[_P, _R]) -> _Callable[_P, _R]:
        @_functools.wraps(func)
        def wrapper(*args: _P.args, **kwargs: _P.kwargs) -> _R:
            format_logging(stack_based=stack_based)
            try:
                return func(*args, **kwargs)
            # pylint: disable-next=broad-exception-caught
            except Exception as exception:
                loglevel = _logger.getEffectiveLevel()
                if loglevel <= _logging.DEBUG:
                    _traceback.print_exc()

                file = _Path(_inspect.trace()[-1][1])
                line = _inspect.trace()[-1][2]
                _logger.error(f"{type(exception).__name__}: {exception} ({file.name}:{line})")
                exit_code = 1
                if isinstance(exception, _subprocess.CalledProcessError):
                    exit_code = exception.returncode
                _sys.exit(exit_code)
            except KeyboardInterrupt:
                _logger.error("==== Keyboard Interrupt ====")
                _sys.exit(2)

        return wrapper

    return main_decorator
