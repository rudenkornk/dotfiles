import logging
import os
from pathlib import Path

from ..utils import REPO_PATH, run_shell

_logger = logging.getLogger(__name__)


def _choose_impl(*, candidates_list: list[Path], theme: Path, candidates_out: Path) -> None:
    shell = os.environ["SHELL"]
    candidates_out.touch()
    with candidates_out.open(mode="+a") as candidates:
        for candidate in candidates_list:
            _logger.info(candidate)
            theme.unlink(missing_ok=True)
            theme.symlink_to(candidate)
            res = run_shell([shell], check=False)
            if res.returncode == 0:
                candidates.write(candidate.name + "\n")
            elif res.returncode == 100:  # Allow user to stop this
                return


def choose(*, from_all: bool) -> None:
    theme = Path.home() / ".config" / "oh-my-posh" / "theme.json"
    themes_dir = Path.home() / ".config" / "oh-my-posh" / "themes"
    candidates_path = REPO_PATH / "roles" / "shell_utils" / "files" / "oh-my-posh-themes"
    if from_all or not candidates_path.exists():
        candidates_list = list(themes_dir.iterdir())
    else:
        candidates_list = [themes_dir / name for name in candidates_path.read_text().splitlines()]

    _choose_impl(candidates_list=candidates_list, theme=theme, candidates_out=candidates_path)
