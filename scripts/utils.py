#!/usr/bin/env python3

from dotty_dict import dotty as _dotty
from pathlib import Path as _Path
import functools as _functools
import logging as _logging
import luadata as _luadata
import os as _os
import shlex as _shlex
import subprocess as _subprocess
import sys as _sys
import time as _time
import yaml as _yaml


def get_repo_path():
    return (_Path(_sys.path[0]) / "..").resolve()


def get_build_path():
    return get_repo_path() / "__build__"


def get_tmp_path():
    return get_build_path() / "tmp"


def get_logger():
    return _logging.getLogger("support")


def _stringify_paths(paths=[]):
    s = list(map(lambda x: str(x), paths))
    return ":".join(s)  # hopefully no one is that crazy to use colon in the path...


def shell_command(cmd, extra_env={}, extra_paths=[]):
    if "PATH" in extra_env:
        raise ValueError("Do not pass PATH to extra_env. Use extra_paths instead.")

    extra_paths_str = _stringify_paths(extra_paths)
    print_cmd = ""
    for k, v in extra_env.items():
        print_cmd += f"{_shlex.quote(str(k))}={_shlex.quote(str(v))} "
    if extra_paths:
        print_cmd += 'PATH="{}:${{PATH}}"'.format(extra_paths_str)
    print_cmd = print_cmd.strip()
    if extra_env or extra_paths_str:
        print_cmd += "; "

    if type(cmd) is list:
        for arg in cmd:
            print_cmd += _shlex.quote(str(arg)) + " "
    else:
        assert type(cmd) is str
        print_cmd += cmd
    print_cmd = print_cmd.strip()
    return print_cmd


def run_shell(cmd, extra_env={}, extra_paths=[], capture_output=False):
    logger = get_logger()
    env = _os.environ.copy()
    env.update(extra_env)
    extra_paths_str = _stringify_paths(extra_paths)
    env["PATH"] = extra_paths_str + (":" + env["PATH"]) if "PATH" in env else ""

    if not capture_output:
        logger.info("\n[RUNNING IN SHELL]:")
        print_cmd = shell_command(cmd, extra_env, extra_paths)
        logger.info(print_cmd + "\n")
    shell = type(cmd) is str
    return _subprocess.run(cmd, env=env, check=True, capture_output=capture_output, text=True, shell=shell)


def retry(max_tries=5, delay=5):
    def retry_decorator(func):
        @_functools.wraps(func)
        def wrapper(*args, **kwargs):
            logger = get_logger()
            for i in range(max_tries):
                try:
                    return func(*args, **kwargs)
                except Exception:
                    if i >= max_tries - 1:
                        raise
                    logger.warning(f"Function '{func.__name__}' failed. Retry {i+1} of {max_tries}...")
                    _time.sleep(delay)

        return wrapper

    return retry_decorator


def lua_read(path: _Path):
    return _luadata.read(path, encoding="utf-8")


def lua_write(path: _Path, data):
    _luadata.write(path, data, encoding="utf-8", indent="  ", prefix="return ")


def yaml_read(path: _Path):
    with open(path, "r") as stream:
        return _dotty(_yaml.safe_load(stream))


def yaml_write(path: _Path, data):
    with open(path, "w") as stream:
        return _yaml.safe_dump(dict(data), stream=stream)
