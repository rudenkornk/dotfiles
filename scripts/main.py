#!/usr/bin/env python3

import shutil

from src import utils
from src.cli import cli


@utils.main()
def _main() -> None:
    cli(max_content_width=shutil.get_terminal_size(fallback=(120, 24)).columns)


if __name__ == "__main__":
    _main()
