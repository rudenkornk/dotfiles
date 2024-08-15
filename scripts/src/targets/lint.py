import logging
import re
import tempfile

from git import Repo

from ..utils import REPO_PATH, SCRIPTS_PATH, cpu_count, run_shell, yaml_read
from .ansible_collections import ANSIBLE_COLLECTIONS_PATH, ansible_collections
from .bootstrap import bootstrap
from .roles_graph import roles_graph

_logger = logging.getLogger(__name__)


def _check_registered_roles() -> None:
    _logger.info("Checking if all roles are registered in playbook.yaml...")
    playbook, _ = yaml_read(REPO_PATH / "playbook.yaml")
    assert isinstance(playbook, list)
    roles = {entry["role"] for entry in playbook[0]["roles"]}
    missing = set()
    for role_path in (REPO_PATH / "roles").iterdir():
        if (role_name := role_path.name) not in roles:
            missing.add(role_name)

    if missing:
        raise RuntimeError(f"Missing roles: {', '.join(missing)} in playbook.yaml")

    _logger.info("All roles are registered!")


def _check_secrets_deps() -> None:
    # This ansible config uses secrets to fully setup hosts.
    # Since the configuration is tested inside some untrusted CI, it should work even if secrets are not decrypted.
    # Thus, all of the tasks, which use secrets are "optional" and skipped in case secrets are not decrypted.
    # This creates a potential configuration mistake:
    # one can create some role, which uses secrets, but forget to add "secrets" role as a dependency.
    # Since all secrets tasks are optional, CI will not catch such mistake, but local scenarios might be broken.
    # In order to prevent such case, there is a linting check, which ensures that all roles containing secrets
    # are also depend on the "secrets" role.

    _logger.info("Checking if all secrets are properly used by roles...")

    secrets_index = REPO_PATH / ".gitsecret" / "paths" / "mapping.cfg"
    secrets_raw = secrets_index.read_text(encoding="utf-8").splitlines()
    secrets = {line.split(":", maxsplit=1)[0] for line in secrets_raw}
    graph = roles_graph()

    for secret in secrets:
        if not secret.startswith("roles/"):
            continue

        if secret.startswith("roles/secrets/"):
            continue

        role = secret.split("/")[1]

        if role not in graph:
            raise RuntimeError(f"Secret {secret} is not used by any role!")

        if "secrets" in graph[role]:
            continue

        msg = (
            f"Looks like {role} role uses {secret} secret,\n"
            "but the role does not have 'secrets' role in its dependencies!\n"
            "This is likely a configuration error and can lead to unexpected behavior.\n"
        )
        raise RuntimeError(msg)

    _logger.info("All secrets are properly used!")


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

        for path in commit.stats.files.keys():
            if not re.search(
                (
                    "("
                    "\\.rsa|"
                    "\\.ovpn|"
                    "\\.pub|"
                    "\\.amnezia|"
                    "\\.xray|"
                    "\\.socks|"
                    "\\.auth|"
                    "credentials.json|"
                    "credentials_map.yaml|"
                    "private.gpg"
                    ")$"
                ),
                str(path),
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
    bootstrap()
    ansible_collections()

    _check_leaked_credentials()
    _check_registered_roles()
    _check_secrets_deps()

    run_shell(
        ["ansible-lint", REPO_PATH / "playbook.yaml"],
        extra_env={"ANSIBLE_COLLECTIONS_PATH": ANSIBLE_COLLECTIONS_PATH},
    )
    run_shell(
        ["ansible-lint", REPO_PATH / "playbook_bootstrap_hosts.yaml"],
        extra_env={"ANSIBLE_COLLECTIONS_PATH": ANSIBLE_COLLECTIONS_PATH},
    )
    run_shell(
        ["ansible-lint", SCRIPTS_PATH / "playbook_dotfiles_container.yaml"],
        extra_env={"ANSIBLE_COLLECTIONS_PATH": ANSIBLE_COLLECTIONS_PATH},
    )
    run_shell(["python3", "-m", "mypy", REPO_PATH / "main.py"])
    run_shell(["python3", "-m", "mypy", REPO_PATH / "scripts"])
    run_shell(["python3", "-m", "pylint", "--jobs", str(cpu_count()), REPO_PATH / "main.py"])
    run_shell(["python3", "-m", "pylint", "--jobs", str(cpu_count()), REPO_PATH / "scripts"])
    run_shell(["python3", "-m", "yamllint", "--strict", REPO_PATH / ".github"])


def format_code() -> None:
    run_shell(["python3", "-m", "black", REPO_PATH])
    run_shell(["python3", "-m", "isort", REPO_PATH])

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
