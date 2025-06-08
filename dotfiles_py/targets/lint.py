import inspect
import logging
import re
import tempfile

from git import Repo

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

    # There are some deep-history problematic commits, which secrets were revoked
    # Instead of rewriting history of the entire repo, let's just skip them
    ignored = [
        "ab2bd0cd41b3530c575bda668f026a7aac2c1e56",
        "a81129b55711ac920ca7ffcedc8382b210d31473",
        "e766f66940d59cb8af176c5d67ddc3e6e42bac44",
        "9e1efdf0add1b9b5d7f52e89d621fdd2d667dd63",
        "66ab8392a693e26945239e0ecf8ff78066f6f5b5",
        "d65d287dd22d85254169d4c02014675891f21f85",
    ]

    logging.getLogger("git").setLevel(logging.WARNING)
    _logger.info("Analyzing repository history for leaked credentials...")

    repo = Repo(REPO_PATH)
    for commit in repo.iter_commits(f"{first_commit}..HEAD"):
        if commit.hexsha in ignored:
            continue

        for path in commit.stats.files:
            if not re.search(
                (
                    "("
                    "\\.rsa|"
                    "\\.ed25519|"
                    "\\.ed25519_sk|"
                    "\\.ecdsa|"
                    "\\.ecdsa_sk|"
                    "\\.ovpn|"
                    "\\.amnezia|"
                    "\\.xray|"
                    "\\.socks|"
                    "\\.auth|"
                    "credentials.json|"
                    "private.gpg"
                    ")$"
                ),
                str(path),
            ):
                continue
            # Error message is taken from
            # https://docs.gitguardian.com/secrets-detection/secrets-detection-engine/leaks_remediation
            _logger.error("LOOKS LIKE SSH KEY, VPN CONFIG OR SOME AUTH DATA LEAKED!!!")
            _logger.error(f"Problematic commit:     {commit.summary!s}")
            _logger.error(f"Problematic commit SHA: {commit.hexsha}")
            _logger.error(f"Problematic path: {path}")
            _logger.error("")
            _logger.error("What you should NOT do:")
            _logger.error("  * Committing on top of the current source code version is not a solution.")
            _logger.error("    Bear in mind that git keeps track of the history,")
            _logger.error("    the secret will still be visible in previous commits.")
            _logger.error("  * Only taking down the involved repository is not a correct solution.")
            _logger.error("    The leaked credentials will still be exposed in forks of the repository,")
            _logger.error("    and attackers could still access it in mirrored versions of GitHub.")
            _logger.error("Step by step guide to remediate the leak:")
            _logger.error("  * Step 1: Revoke the exposed secret.")
            _logger.error("  * Step 2: Clean the git history.")
            _logger.error("  * Step 3: Inspect logs.")
            msg = "Leaked credentials detected!"
            raise RuntimeError(msg)
    _logger.info("Done, no leaked credentials found.")


def lint_code(*, ansible: bool, python: bool, secrets: bool, generic: bool) -> None:
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

    if generic:
        run_shell(["typos"])


def lint_choices() -> list[str]:
    return inspect.getfullargspec(lint_code).kwonlyargs


def format_code() -> None:
    run_shell(["python3", "-m", "ruff", "format"])
    run_shell(["python3", "-m", "ruff", "check", "--fix", "--unsafe-fixes"])

    # All the other formatting tools require a machine to be configured,
    # Thus we ignore errors here, making these optional
    run_shell(["npm", "install", "--save-exact"], check=False)
    with tempfile.NamedTemporaryFile(mode="w+t") as combinedignore:
        gitignore = REPO_PATH / ".gitignore"
        prettierignore = REPO_PATH / ".prettierignore"
        combinedignore.write(gitignore.read_text(encoding="utf-8"))
        combinedignore.write(prettierignore.read_text(encoding="utf-8"))
        combinedignore.flush()
        run_shell(["npx", "prettier", "--ignore-path", combinedignore.name, "-w", REPO_PATH], check=False)

    run_shell(["stylua", REPO_PATH], check=False)
