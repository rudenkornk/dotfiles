#!/usr/bin/env python3

import logging as _logging
import sys as _sys

import scripts.setup as _setup
import scripts.utils as _utils

_logger = _logging.getLogger("scripts")


@_utils.main(_logger)
def _main() -> None:
    _setup.process_shell_args(_sys.argv)


if __name__ == "__main__":
    _main()
