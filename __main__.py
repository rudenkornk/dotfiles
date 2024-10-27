#!/usr/bin/env python3

import shutil

from scripts import utils
from scripts.cli import cli


@utils.main()
def _main() -> None:
    cli(max_content_width=shutil.get_terminal_size(fallback=(120, 24)).columns)


if __name__ == "__main__":
    _main()
