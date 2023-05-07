#!/usr/bin/env python3

import functools as _functools
import inspect as _inspect
import logging as _logging
import os as _os
import shlex as _shlex
import subprocess as _subprocess
import sys as _sys
import time as _time
from pathlib import Path as _Path
from typing import IO as _IO
from typing import Any as _Any
from typing import Callable as _Callable
from typing import ParamSpec as _ParamSpec
from typing import Sequence as _Sequence
from typing import TypeVar as _TypeVar

import luadata as _luadata  # type: ignore
import yaml as _yaml

_logger = _logging.getLogger(__name__)


def get_repo_path() -> _Path:
    return _Path(_sys.path[0])


def get_build_path() -> _Path:
    return get_repo_path() / "__build__"


def get_tmp_path() -> _Path:
    return get_build_path() / "tmp"


def _paths2shell(paths: _Sequence[_Path]) -> str:
    # hopefully no one is that crazy to use colon in the path...
    return ":".join([str(p) for p in paths])


def shell_command(
    cmd: _Sequence[str | _Path] | str,
    extra_env: dict[str, str] | None = None,
    extra_paths: _Sequence[_Path] | None = None,
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

    if not suppress_env_log:
        for k, val in extra_env.items():
            print_cmd += f"{_shlex.quote(str(k))}={_shlex.quote(str(val))} "

    if extra_paths:
        print_cmd += f'PATH="{extra_paths_str}:${{PATH}}" '

    if isinstance(cmd, list):
        for arg in cmd:
            print_cmd += _shlex.quote(str(arg)) + " "
    else:
        assert isinstance(cmd, str)
        print_cmd += cmd
    print_cmd = print_cmd.strip()
    return print_cmd


def _shell_output_type(
    capture_output: bool, stdout: None | int | _IO[_Any], stderr: None | int | _IO[_Any], suppress_env_log: bool
) -> str:
    def _append(message: str, chunk: str) -> str:
        if message:
            message += ", "
        message += chunk
        return message

    output_mods = ""
    suppress_stdout = capture_output or stdout is not None
    suppress_stderr = capture_output or stderr is not None
    if suppress_stdout and suppress_stderr:
        output_mods = _append(output_mods, "output is suppressed")
    elif suppress_stdout:
        output_mods = _append(output_mods, "stdout is suppressed")
    elif suppress_stderr:
        output_mods = _append(output_mods, "stderr is suppressed")

    if suppress_env_log:
        output_mods = _append(output_mods, "extra env is hidden")

    if output_mods:
        output_mods = f" ({output_mods})"
    output_type = f"[RUNNING IN SHELL]{output_mods}"
    return output_type


def run_shell(
    cmd: _Sequence[str | _Path] | str,
    extra_env: dict[str, str] | None = None,
    extra_paths: _Sequence[_Path] | None = None,
    capture_output: bool = False,
    stdout: None | int | _IO[_Any] = None,
    stderr: None | int | _IO[_Any] = None,
    suppress_env_log: bool = False,
    cwd: _Path | None = None,
) -> _subprocess.CompletedProcess[str]:
    extra_env = extra_env or {}
    extra_paths = extra_paths or []

    env = _os.environ.copy()
    env.update(extra_env)
    if extra_paths:
        new_path = _paths2shell(extra_paths)
        assert new_path.strip()
        if "PATH" in env and env["PATH"].strip():
            new_path += ":" + env["PATH"]
        env["PATH"] = new_path

    print_cmd = shell_command(
        cmd, extra_env=extra_env, extra_paths=extra_paths, suppress_env_log=suppress_env_log, cwd=cwd
    )
    output_type = _shell_output_type(
        capture_output=capture_output, stdout=stdout, stderr=stderr, suppress_env_log=suppress_env_log
    )
    _logger.info(f"{output_type}: {print_cmd}")

    if isinstance(cmd, list):
        return _subprocess.run(
            cmd,
            env=env,
            check=True,
            capture_output=capture_output,
            stdout=stdout,
            stderr=stderr,
            text=True,
            cwd=cwd,
        )

    assert isinstance(cmd, str)
    return _subprocess.run(
        cmd,
        env=env,
        check=True,
        capture_output=capture_output,
        stdout=stdout,
        stderr=stderr,
        text=True,
        shell=True,
        executable="bash",
        cwd=cwd,
    )


_P = _ParamSpec("_P")
_R = _TypeVar("_R")


def retry(
    delay: int = 5, max_tries: int = 5, suppress_logger: bool = False
) -> _Callable[[_Callable[_P, _R]], _Callable[_P, _R]]:
    assert max_tries > 0

    def retry_decorator(func: _Callable[_P, _R]) -> _Callable[_P, _R]:
        @_functools.wraps(func)
        def wrapper(*args: _P.args, **kwargs: _P.kwargs) -> _R:
            for i in range(max_tries):
                try:
                    return func(*args, **kwargs)
                except Exception as e:
                    if i + 1 >= max_tries:
                        raise
                    if not suppress_logger:
                        _logger.warning(f"Function '{func.__name__}' failed with error:")
                        _logger.warning(f"  {type(e).__name__}: {e}")
                        _logger.warning(f"  Retry {i + 2} of {max_tries}...")
                    _time.sleep(delay)
            assert False, "Unreachable."

        return wrapper

    return retry_decorator


def lua_read(path: _Path) -> dict[str, _Any]:
    lua = _luadata.read(path, encoding="utf-8")
    assert isinstance(lua, dict)
    return lua


def lua_write(path: _Path, data: dict[str, _Any]) -> None:
    _luadata.write(path, data, encoding="utf-8", indent="  ", prefix="return ")


def yaml_read(path: _Path) -> dict[str, _Any]:
    with open(path, "r") as stream:
        return dict(_yaml.safe_load(stream))


def yaml_write(path: _Path, data: dict[str, _Any]) -> None:
    with open(path, "w") as stream:
        _yaml.safe_dump(data, stream=stream)


class _LoggerFormatter(_logging.Formatter):
    grey = "\x1b[38;20m"
    green = "\x1b[32;20m"
    yellow = "\x1b[33;20m"
    red = "\x1b[38;5;196m"
    bold_red = "\x1b[31;1m"
    reset = "\x1b[0m"
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

    def format(self, record: _Any) -> str:
        fmt, color = self.formats_info[record.levelno]
        if _sys.stdout.isatty():
            fmt = color + fmt + self.reset
        formatter = _logging.Formatter(fmt)
        return formatter.format(record)


def format_logging(logger: _logging.Logger = _logging.getLogger()) -> None:
    # Keep here stdout instead of default of stderr,
    # because container will print to the host stdout anyway.
    handler = _logging.StreamHandler(_sys.stdout)
    handler.setFormatter(_LoggerFormatter())
    logger.addHandler(handler)
    logger.setLevel(_logging.INFO)


def main(logger: _logging.Logger = _logging.getLogger()) -> _Callable[[_Callable[_P, _R]], _Callable[_P, _R]]:
    def main_decorator(func: _Callable[_P, _R]) -> _Callable[_P, _R]:
        @_functools.wraps(func)
        def wrapper(*args: _P.args, **kwargs: _P.kwargs) -> _R:
            format_logging(logger)
            try:
                return func(*args, **kwargs)
            # pylint: disable-next=broad-exception-caught
            except Exception as exception:
                file = _Path(_inspect.trace()[-1][1])
                line = _inspect.trace()[-1][2]
                _logger.error(f"{type(exception).__name__}: {exception} ({file.name}:{line})")
                _sys.exit(1)
            except KeyboardInterrupt:
                _logger.error("==== Keyboard Interrupt ====")
                _sys.exit(1)

        return wrapper

    return main_decorator
