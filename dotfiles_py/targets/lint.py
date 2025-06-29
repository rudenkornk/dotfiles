import inspect
import logging
from pathlib import Path

from ..utils import DOTPY_PATH, REPO_PATH, run_shell, yaml_read
from .ansible_collections import ANSIBLE_COLLECTIONS_PATH, ansible_collections

_logger = logging.getLogger(__name__)


def _check_registered_roles() -> None:
    _logger.info("Checking if all roles are registered in playbook.yaml...")
    playbook, _ = yaml_read(REPO_PATH / "playbook.yaml")
    if not isinstance(playbook, list):
        msg = f"Expected a list in {REPO_PATH / 'playbook.yaml'}, got {type(playbook)}"
        raise TypeError(msg)
    roles = {entry["role"] for entry in playbook[0]["roles"]}
    missing = set()
    for role_path in (REPO_PATH / "roles").iterdir():
        if (role_name := role_path.name) not in roles:
            missing.add(role_name)

    if missing:
        msg = f"Missing roles: {', '.join(missing)} in playbook.yaml"
        raise RuntimeError(msg)

    _logger.info("All roles are registered!")


def _check_leaked_credentials() -> None:
    # In order to properly check for leaked credentials,
    # we have to iterate over all commits in the repo.
    # Pinning first commit ensures, that if the check is run on some shallow cloned repo,
    # it will throw an error.
    first_commit = "78946fc7d7e562042c62d589b331abf222c688e7"

    if run_shell(["git", "cat-file", "-e", first_commit], check=False).returncode:
        _logger.error("Looks like git history is shallow and credential check cannot be performed.")
        raise RuntimeError

    run_shell(["gitleaks", "git"], cwd=REPO_PATH)


def lint_code(*, ansible: bool, python: bool, secrets: bool, sh: bool, generic: bool) -> None:
    ansible_collections()

    if secrets:
        _check_leaked_credentials()

    if ansible:
        _check_registered_roles()
        run_shell(
            ["ansible-lint", REPO_PATH / "playbook.yaml"],
            extra_env={"ANSIBLE_COLLECTIONS_PATH": ANSIBLE_COLLECTIONS_PATH},
        )
        run_shell(
            ["ansible-lint", REPO_PATH / "playbook_bootstrap_hosts.yaml"],
            extra_env={"ANSIBLE_COLLECTIONS_PATH": ANSIBLE_COLLECTIONS_PATH},
        )
        run_shell(
            ["ansible-lint", REPO_PATH / "playbook_dotfiles_container.yaml"],
            extra_env={"ANSIBLE_COLLECTIONS_PATH": ANSIBLE_COLLECTIONS_PATH},
        )
    if python:
        run_shell(["python3", "-m", "mypy", DOTPY_PATH])
        # Specifying job number for pylint somehow leads to false-positive errors
        run_shell(["python3", "-m", "ruff", "check"])
        run_shell(["python3", "-m", "yamllint", "--strict", REPO_PATH / ".github"])

    if sh:
        files = [
            Path(file)
            for file in run_shell(["git", "ls-files"], capture_output=True, cwd=REPO_PATH).stdout.splitlines()
            if file.endswith(".sh")
        ]
        run_shell(["shellcheck", *files])

    if generic:
        run_shell(["typos"])


def lint_choices() -> list[str]:
    return inspect.getfullargspec(lint_code).kwonlyargs


def format_code() -> None:
    run_shell(["python3", "-m", "ruff", "format"], cwd=REPO_PATH)
    run_shell(["python3", "-m", "ruff", "check", "--fix", "--unsafe-fixes"], cwd=REPO_PATH)

    run_shell(["npm", "install", "--save-exact"], cwd=REPO_PATH)
    run_shell(["npx", "prettier", "-w", REPO_PATH])
    run_shell(["stylua", REPO_PATH])
