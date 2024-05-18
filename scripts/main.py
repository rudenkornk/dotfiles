#!/usr/bin/env python3

import sys as _sys

import src.setup as _setup
import src.utils as _utils


@_utils.main()
def _main() -> None:
    _setup.process_shell_args(_sys.argv)


if __name__ == "__main__":
    _main()
