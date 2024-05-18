#!/usr/bin/env python3

import logging as _logging
import sys as _sys

import _support.setup as _setup
import _support.utils as _utils

_logger = _logging.getLogger("_support")


@_utils.main()
def _main() -> None:
    _setup.process_shell_args(_sys.argv)


if __name__ == "__main__":
    _main()
