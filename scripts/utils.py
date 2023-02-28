#!/usr/bin/env python3

from dotty_dict import dotty as _dotty
from pathlib import Path as _Path
from typing import Any as _Any
from typing import Callable as _Callable
import functools as _functools
import logging as _logging
import luadata as _luadata
import os as _os
import shlex as _shlex
import subprocess as _subprocess
import sys as _sys
import time as _time
import yaml as _yaml

_logger = _logging.getLogger(__name__)


def get_repo_path() -> _Path:
    return _Path(_sys.path[0])


def get_build_path() -> _Path:
    return get_repo_path() / "__build__"


def get_tmp_path() -> _Path:
    return get_build_path() / "tmp"


def _paths2shell(paths: list[_Path] = []) -> str:
    s = list(map(lambda x: str(x), paths))
    # hopefully no one is that crazy to use colon in the path...
    return ":".join(s)


def shell_command(cmd: list | str, extra_env: dict = {}, extra_paths: list[_Path] = []) -> str:
    if "PATH" in extra_env:
        raise ValueError("Do not pass PATH to extra_env. Use extra_paths instead.")

    extra_paths_str = _paths2shell(extra_paths)
    print_cmd = ""
    for k, v in extra_env.items():
        print_cmd += f"{_shlex.quote(str(k))}={_shlex.quote(str(v))} "
    if extra_paths:
        print_cmd += f'PATH="{extra_paths_str}:${{PATH}}" '

    if type(cmd) is list:
        for arg in cmd:
            print_cmd += _shlex.quote(str(arg)) + " "
    else:
        assert type(cmd) is str
        print_cmd += cmd
    print_cmd = print_cmd.strip()
    return print_cmd


def run_shell(
    cmd: list | str,
    extra_env: dict = {},
    extra_paths: list[_Path] = [],
    capture_output: bool = False,
) -> _subprocess.CompletedProcess:
    env = _os.environ.copy()
    env.update(extra_env)
    extra_paths_str = _paths2shell(extra_paths)
    env["PATH"] = extra_paths_str + (":" + env["PATH"]) if "PATH" in env else ""

    if not capture_output:
        print_cmd = shell_command(cmd, extra_env, extra_paths)
        _logger.info(f"[RUNNING IN SHELL]: {print_cmd}")

    if type(cmd) is list:
        return _subprocess.run(cmd, env=env, check=True, capture_output=capture_output, text=True)
    else:
        assert type(cmd) is str
        return _subprocess.run(
            cmd,
            env=env,
            check=True,
            capture_output=capture_output,
            text=True,
            shell=True,
            executable="bash",
        )


def retry(delay: int = 5, max_tries: int = 5, suppress_logger: bool = False) -> _Callable:
    def retry_decorator(func: _Callable) -> _Callable:
        @_functools.wraps(func)
        def wrapper(*args, **kwargs):
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

        return wrapper

    return retry_decorator


def lua_read(path: _Path) -> dict[str, _Any]:
    return _luadata.read(path, encoding="utf-8")


def lua_write(path: _Path, data: dict[str, _Any]):
    _luadata.write(path, data, encoding="utf-8", indent="  ", prefix="return ")


def yaml_read(path: _Path) -> dict[str, _Any]:
    with open(path, "r") as stream:
        return _dotty(_yaml.safe_load(stream))


def yaml_write(path: _Path, data: dict[str, _Any]):
    with open(path, "w") as stream:
        return _yaml.safe_dump(dict(data), stream=stream)


class _LoggerFormatter(_logging.Formatter):
    grey = "\x1b[38;20m"
    green = "\x1b[32;20m"
    yellow = "\x1b[33;20m"
    red = "\x1b[38;5;196m"
    bold_red = "\x1b[31;1m"
    reset = "\x1b[0m"
    ok_format = "%(message)s"
    error_format = "%(message)s (%(filename)s:%(lineno)d)"
    formats_info = {
        _logging.DEBUG: (ok_format, grey),
        _logging.INFO: (ok_format, grey),
        _logging.WARNING: (error_format, yellow),
        _logging.ERROR: (error_format, red),
        _logging.CRITICAL: (error_format, bold_red),
    }

    def format(self, record):
        fmt, color = self.formats_info.get(record.levelno)
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
