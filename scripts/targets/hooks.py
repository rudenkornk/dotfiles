import logging
from pathlib import Path

from ..utils import REPO_PATH

_logger = logging.getLogger(__name__)


def hooks() -> None:
    target_base = Path("..") / ".." / "scripts" / "src" / "data" / "hooks"
    hooks_base = REPO_PATH / ".git" / "hooks"

    _logger.info(f"Symlinking {target_base} to {hooks_base}.")
    precommit = hooks_base / "pre-commit"
    precommit.unlink(missing_ok=True)
    precommit.symlink_to(target_base / "pre-commit")
