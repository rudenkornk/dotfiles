#!/usr/bin/env python3

import shutil as _shutil

import src.utils as _utils
from src.cli import cli as _cli


@_utils.main()
def _main() -> None:
    _cli(max_content_width=_shutil.get_terminal_size(fallback=(120, 24)).columns)


if __name__ == "__main__":
    _main()
