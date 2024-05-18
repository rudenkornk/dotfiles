#!/usr/bin/env python3

# This script must only use Python Standard Library
from __future__ import annotations

import filecmp as _filecmp
import logging as _logging
import os as _os
import platform as _platform
import shutil as _shutil
import subprocess as _subprocess
import sys as _sys
from pathlib import Path as _Path

_logger = _logging.getLogger(__name__)


def get_python310() -> str:
    if (_sys.version_info[0] == 3 and _sys.version_info[1] >= 10) or _sys.version_info[0] > 3:
        return _sys.executable

    _logger.info("At least Python 3.10 is required, trying to find one...")
    for subversion in range(10, 20):
        if (python_executable := _shutil.which(f"python3.{subversion}")) is not None:
            return python_executable

    raise RuntimeError("Failed to find Python version >= 3.10.")


def get_venv(requirements_path: _Path, artifacts_path: _Path) -> dict[str, str]:
    hostname = _platform.node()
    venv_path = artifacts_path / hostname / "venv"
    env = _os.environ.copy()

    cmp_requirements = venv_path / "requirements.txt"
    bin_path = venv_path / "bin"
    venv_executable = bin_path / "python"
    env["PATH"] = _os.pathsep.join((str(bin_path), env["PATH"]))
    env["VIRTUAL_ENV"] = str(venv_path)

    if not venv_executable.exists():
        _logger.info("Creating virtual environment...")
        _shutil.rmtree(venv_path, ignore_errors=True)
        python_executable = get_python310()
        _subprocess.run(
            [python_executable, "-m", "venv", venv_path],
            check=True,
            capture_output=False,
            text=True,
        )
        if not venv_executable.exists():
            raise RuntimeError("Failed to create virtual environment. Did you install pip?")

    if not cmp_requirements.exists() or not _filecmp.cmp(requirements_path, cmp_requirements):
        _logger.info("Updating virtual environment...")
        _subprocess.run(
            [venv_executable, "-m", "pip", "install", "-r", requirements_path],
            check=True,
            capture_output=False,
            text=True,
            env=env,
        )
        _shutil.copyfile(requirements_path, cmp_requirements)

    return env


def run_venv(requirements_path: _Path, artifacts_path: _Path, args: list[str | _Path]) -> None:
    env = get_venv(requirements_path, artifacts_path)
    setup = ["python3"] + args
    try:
        _subprocess.run(setup, capture_output=False, text=True, check=True, env=env)
    # Intercept printing exception info:
    # It should already be printed by the called process at this moment.
    except _subprocess.CalledProcessError as exc:
        assert exc.returncode != 0
        _sys.exit(exc.returncode)
    except KeyboardInterrupt:
        _sys.exit(2)


def _main() -> None:
    root = _Path(__file__).parent
    requirements_path = root / "requirements.txt"
    artifacts_path = root / "__build__"
    setup_path = root / "scripts" / "main.py"
    args: list[str | _Path] = list(_sys.argv)
    args[0] = setup_path

    run_venv(requirements_path=requirements_path, artifacts_path=artifacts_path, args=args)


if __name__ == "__main__":
    _logging.basicConfig(format="%(message)s", level=_logging.INFO)
    try:
        _main()
    # pylint: disable=broad-except
    except Exception as exception:
        _logger.error(f"{type(exception).__name__}: {exception}")
        exit_code = 1
        if isinstance(exception, _subprocess.CalledProcessError):
            assert exception.returncode != 0
            exit_code = exception.returncode
        _sys.exit(exit_code)
    except KeyboardInterrupt:
        _logger.error("==== Keyboard Interrupt ====")
        _sys.exit(2)
