import logging
from collections.abc import Mapping
from pathlib import Path

from ..utils import git_files, run_shell

_logger = logging.getLogger(__name__)

_SOPS_CONFIG = ".sops.yaml"


def secret_files(repo_path: Path) -> list[str]:
    secrets = git_files(repo_path, ".sops", ".sops.yaml", ".sops.yml", ".sops.json")
    return sorted(secret for secret in secrets if Path(secret).name != _SOPS_CONFIG)


def updatekeys(
    *,
    repo_path: Path,
    env: Mapping[str, str | Path] | None = None,
    extra_env: Mapping[str, str | Path] | None = None,
) -> None:
    run_shell(["sops", "updatekeys", "--yes", *secret_files(repo_path)], cwd=repo_path, env=env, extra_env=extra_env)
