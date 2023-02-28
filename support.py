#!/usr/bin/env python3

import logging as _logging
import sys as _sys

import scripts.setup as _setup
import scripts.utils as _utils

_logger = _logging.getLogger("scripts")


if __name__ == "__main__":
    _utils.format_logging()
    _logger.setLevel(_logging.INFO)
    try:
        _setup.process_shell_args(_sys.argv)
    except Exception as e:
        _logger.error(f"{type(e).__name__}: {e}")
        _sys.exit(1)
    except KeyboardInterrupt:
        _logger.error("==== Keyboard Interrupt ====")
        _sys.exit(1)
