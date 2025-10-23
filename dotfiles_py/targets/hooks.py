import logging
from os.path import relpath
from pathlib import Path

_logger = logging.getLogger(__name__)


def hooks(*, repo_path: Path, hooks_path: Path) -> None:
    hooks_target = repo_path / ".git" / "hooks"
    _logger.info(f"Symlinking {hooks_path} to {hooks_target}.")

    for hook in hooks_path.iterdir():
        target = hooks_target / hook.name
        target.unlink(missing_ok=True)
        source = relpath(hook, start=hooks_target)
        target.symlink_to(source)
