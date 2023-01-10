#!/usr/bin/env python3

from dotty_dict import dotty as _dotty
from pathlib import Path as _Path
import logging as _logging
import luadata as _luadata
import os as _os
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


def run_shell(cmd, extra_env={}, extra_paths=[], capture_output=False):
    logger = get_logger()
    env = _os.environ.copy()
    env.update(extra_env)
    extra_paths_str = ":".join(list(map(lambda x: str(x), extra_paths)))
    env["PATH"] = extra_paths_str + (":" + env["PATH"]) if "PATH" in env else ""

    if not capture_output:
        logger.info("\n[RUNNING IN SHELL]:")
        logger.info(cmd + "\n")
    return _subprocess.run(cmd, env=env, check=True, capture_output=capture_output, text=True, shell=True)


def try_run(f, try_run_count=5, try_run_delay=5, *args, **kwargs):
    tab = "  "
    logger = get_logger()
    for i in range(try_run_count):
        try:
            return f(*args, **kwargs)
        except Exception:
            if i >= try_run_count - 1:
                raise
            logger.warning(f"{2 * tab}Function '{f.__name__}' failed. Retry {i + 1} of {try_run_count}...")
            _time.sleep(try_run_delay)


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
