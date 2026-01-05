import logging
from pathlib import Path

from ..utils import run_shell

_logger = logging.getLogger(__name__)


def _check_leaked_credentials(repo_path: Path) -> None:
    # In order to properly check for leaked credentials,
    # we have to iterate over all commits in the repo.
    # Pinning first commit ensures, that if the check is run on some shallow cloned repo,
    # it will throw an error.
    first_commit = "78946fc7d7e562042c62d589b331abf222c688e7"

    if run_shell(["git", "cat-file", "-e", first_commit], check=False).returncode:
        _logger.error("Looks like git history is shallow and credential check cannot be performed.")
        raise RuntimeError

    run_shell(["gitleaks", "git"], cwd=repo_path)


def _git_files(repo_path: Path, ext: str) -> list[str]:
    return run_shell(["git", "ls-files", ext], capture_output=True, cwd=repo_path).stdout.splitlines()


def lint_code(*, repo_path: Path) -> None:
    _check_leaked_credentials(repo_path)

    run_shell(["statix", "check", repo_path])

    run_shell(["mypy", repo_path])
    run_shell(["ruff", "check"])
    run_shell(["yamllint", "--strict", repo_path / ".github"])

    run_shell(["shellcheck", *_git_files(repo_path, "*.sh")])

    run_shell(["markdownlint", "--ignore-path", repo_path / ".gitignore", repo_path], cwd=repo_path)

    run_shell(["typos"])


def format_code(*, repo_path: Path, check: bool) -> None:
    check_arg = ["--check"] if check else []
    diff_arg = ["--diff"] if check else []
    dry_run_arg = ["--dry-run"] if check else []
    write_arg = ["--write"] if not check else []

    statix_res = run_shell(["statix", "fix", *dry_run_arg, repo_path], cwd=repo_path, capture_output=check)
    if check and statix_res.stdout.strip():
        raise RuntimeError(statix_res.stdout)

    run_shell(["nixfmt", "--verify", "--strict", *check_arg, *_git_files(repo_path, "*.nix")], cwd=repo_path)
    run_shell(["ruff", "format", *check_arg], cwd=repo_path)
    run_shell(["ruff", "check", "--fix", "--unsafe-fixes", *diff_arg], cwd=repo_path)

    run_shell(["mdformat", *_git_files(repo_path, "*.md"), *check_arg])

    run_shell(["shfmt", *write_arg, *diff_arg, repo_path])
    fish_files = run_shell(["git", "ls-files", "*.fish"], capture_output=True, cwd=repo_path).stdout.splitlines()
    # fish_indent is a fish builtin, so we need to invoke a shell and pass everything as one argument.
    run_shell(["fish", "--no-config", "--command", "fish_indent " + " ".join(write_arg + check_arg + fish_files)])
    run_shell(["prettier", *write_arg, repo_path, *check_arg])
    run_shell(["stylua", repo_path, *check_arg])
