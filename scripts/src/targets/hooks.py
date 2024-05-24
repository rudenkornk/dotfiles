import logging as _logging
from pathlib import Path as _Path

from ..utils import REPO_PATH as _REPO_PATH

_logger = _logging.getLogger(__name__)


def hooks() -> None:
    target_base = _Path("..") / ".." / "scripts" / "src" / "data" / "hooks"
    hooks_base = _REPO_PATH / ".git" / "hooks"

    _logger.info(f"Symlinking {target_base} to {hooks_base}.")
    precommit = hooks_base / "pre-commit"
    precommit.unlink(missing_ok=True)
    precommit.symlink_to(target_base / "pre-commit")
