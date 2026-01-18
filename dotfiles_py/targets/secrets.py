import logging
from pathlib import Path

from ..utils import git_files, run_shell

_logger = logging.getLogger(__name__)


def updatekeys(*, repo_path: Path) -> None:
    secrets = git_files(repo_path, ".sops", ".sops.yaml", ".sops.yml", ".sops.json")
    config_file_name = ".sops.yaml"
    secrets = [secret for secret in secrets if Path(secret).name != config_file_name]

    run_shell(["sops", "updatekeys", "--yes", *secrets], cwd=repo_path)
