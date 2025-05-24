import logging
from os.path import relpath

from ..utils import DATA_PATH, REPO_PATH

_logger = logging.getLogger(__name__)


def hooks() -> None:
    hooks_source = DATA_PATH / "hooks"
    hooks_target = REPO_PATH / ".git" / "hooks"

    _logger.info(f"Symlinking {hooks_source} to {hooks_target}.")

    for hook in hooks_source.iterdir():
        target = hooks_target / hook.name
        target.unlink(missing_ok=True)
        source = relpath(hook, start=hooks_target)
        target.symlink_to(source)
