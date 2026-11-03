import logging
import shutil
import stat
import sys
from pathlib import Path

_logger = logging.getLogger(__name__)


def copy_path(source: Path, target: Path, *, ancestors: frozenset[tuple[int, int]] = frozenset()) -> bool:
    try:
        metadata = source.stat()
        if stat.S_ISREG(metadata.st_mode):
            shutil.copyfile(source, target)
            return True
        if not stat.S_ISDIR(metadata.st_mode):
            _logger.error(f"Skipping unsupported special file: {source}")
            return False
        identity = (metadata.st_dev, metadata.st_ino)
        if identity in ancestors:
            _logger.error(f"Skipping directory symlink cycle: {source}")
            return False
        if target.resolve().is_relative_to(source.resolve(strict=True)):
            _logger.error(f"Copy destination is inside source: {source}")
            return False
        target.mkdir(exist_ok=True)
        success = True
        for child in source.iterdir():
            if not copy_path(child, target / child.name, ancestors=ancestors | {identity}):
                success = False
    except OSError:
        _logger.exception(f"Failed to copy {source} to {target}")
        return False
    else:
        return success


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(message)s")
    sys.exit(0 if copy_path(Path(sys.argv[1]), Path(sys.argv[2])) else 1)
