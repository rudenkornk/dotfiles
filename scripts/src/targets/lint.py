import logging as _logging
import re as _re
import tempfile as _tempfile

from git import Repo as _Repo

from ..utils import REPO_PATH as _REPO_PATH
from ..utils import SCRIPTS_PATH as _SCRIPTS_PATH
from ..utils import cpu_count as _cpu_count
from ..utils import run_shell as _run_shell
from ..utils import yaml_read as _yaml_read
from .ansible_collections import ANSIBLE_COLLECTIONS_PATH as _ANSIBLE_COLLECTIONS_PATH
from .ansible_collections import ansible_collections as _ansible_collections
from .bootstrap import bootstrap as _bootstrap

_logger = _logging.getLogger(__name__)


def _check_registered_roles() -> None:
    playbook = _yaml_read(_REPO_PATH / "playbook.yaml")
    assert isinstance(playbook, list)
    roles = {entry["role"] for entry in playbook[0]["roles"]}
    missing = set()
    for role_path in (_REPO_PATH / "roles").iterdir():
        if (role_name := role_path.name) not in roles:
            missing.add(role_name)

    if not missing:
        return

    raise RuntimeError(f"Missing roles: {', '.join(missing)} in playbook.yaml")


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

    repo = _Repo(_REPO_PATH)
    _logging.getLogger("git").setLevel(_logging.WARNING)
    _logger.info("Analyzing repository history for leaked credentials...")
    for commit in repo.iter_commits(f"{first_commit}..HEAD"):
        if commit.hexsha in ignored:
            continue

        for path in commit.stats.files.keys():
            if not _re.search(
                "(\\.rsa|\\.ovpn|\\.pub|\\.amnezia|\\.xray|\\.socks|\\.auth|credentials.json|private.gpg)$", str(path)
            ):
                continue
            # Error message is taken from
            # https://docs.gitguardian.com/secrets-detection/secrets-detection-engine/leaks_remediation
            _logger.error("LOOKS LIKE SSH KEY, VPN CONFIG OR SOME AUTH DATA LEAKED!!!")
            _logger.error(f"Problematic commit:     {str(commit.summary)}")
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
            raise RuntimeError("Leaked credentials detected!")
    _logger.info("Done, no leaked credentials found.")


def lint_code() -> None:
    _bootstrap()
    _ansible_collections()
    _run_shell(
        ["ansible-lint", _REPO_PATH / "playbook.yaml"],
        extra_env={"ANSIBLE_COLLECTIONS_PATH": _ANSIBLE_COLLECTIONS_PATH},
    )
    _run_shell(
        ["ansible-lint", _REPO_PATH / "playbook_bootstrap_hosts.yaml"],
        extra_env={"ANSIBLE_COLLECTIONS_PATH": _ANSIBLE_COLLECTIONS_PATH},
    )
    _run_shell(
        ["ansible-lint", _SCRIPTS_PATH / "playbook_dotfiles_container.yaml"],
        extra_env={"ANSIBLE_COLLECTIONS_PATH": _ANSIBLE_COLLECTIONS_PATH},
    )
    _run_shell(["python3", "-m", "mypy", _REPO_PATH / "main.py"])
    _run_shell(["python3", "-m", "mypy", _REPO_PATH / "scripts"])
    _run_shell(["python3", "-m", "pylint", "--jobs", str(_cpu_count()), _REPO_PATH / "main.py"])
    _run_shell(["python3", "-m", "pylint", "--jobs", str(_cpu_count()), _REPO_PATH / "scripts"])
    _run_shell(["python3", "-m", "yamllint", "--strict", _REPO_PATH / ".github"])
    _check_leaked_credentials()
    _check_registered_roles()


def format_code() -> None:
    _run_shell(["python3", "-m", "black", _REPO_PATH])
    _run_shell(["python3", "-m", "isort", _REPO_PATH])

    # All the other formatting tools require a machine to be configured,
    # Thus we ignore errors here, making these optional
    _run_shell(["npm", "install", "--save-exact"], check=False)
    with _tempfile.NamedTemporaryFile(mode="w+t") as combinedignore:
        gitignore = _REPO_PATH / ".gitignore"
        prettierignore = _REPO_PATH / ".prettierignore"
        combinedignore.write(gitignore.read_text(encoding="utf-8"))
        combinedignore.write(prettierignore.read_text(encoding="utf-8"))
        combinedignore.flush()
        _run_shell(["npx", "prettier", "--ignore-path", combinedignore.name, "-w", _REPO_PATH], check=False)

    _run_shell(["stylua", _REPO_PATH], check=False)
