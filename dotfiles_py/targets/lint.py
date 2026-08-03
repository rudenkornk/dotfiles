import logging
from collections.abc import Sequence
from dataclasses import dataclass
from pathlib import Path

from ..utils import git_files, run_shell

_logger = logging.getLogger(__name__)


def _ensure_full_history() -> None:
    # In order to properly check for leaked credentials,
    # gitleaks has to iterate over all commits in the repo.
    # Pinning the first commit ensures that, if the check is run on some shallow cloned repo,
    # it throws an error instead of silently passing.
    first_commit = "78946fc7d7e562042c62d589b331abf222c688e7"

    if run_shell(["git", "cat-file", "-e", first_commit], check=False).returncode:
        msg = "Looks like git history is shallow and credential check cannot be performed."
        _logger.error(msg)
        raise RuntimeError(msg)


def _linters(repo_path: Path) -> list[Sequence[str | Path]]:
    return [
        ["gitleaks", "git"],
        ["statix", "check", repo_path],
        ["mypy", repo_path],
        ["ruff", "check"],
        ["yamllint", "--strict", repo_path / ".github"],
        ["shellcheck", *git_files(repo_path, ".sh")],
        ["typos"],
        ["markdownlint-cli2", "."],
    ]


def lint_code(*, repo_path: Path) -> None:
    _ensure_full_history()
    for argv in _linters(repo_path):
        run_shell(argv, cwd=repo_path)


@dataclass(frozen=True)
class Formatter:
    argv: Sequence[str | Path]
    # statix has no `--check`; in check mode it dry-runs and prints proposed
    # changes to stdout while still exiting 0, so any output there means failure.
    stdout_is_error: bool = False


def _formatters(repo_path: Path, *, check: bool) -> list[Formatter]:
    check_arg = ["--check"] if check else []
    diff_arg = ["--diff"] if check else []
    dry_run_arg = ["--dry-run"] if check else []
    write_arg = ["--write"] if not check else []
    fish_files = git_files(repo_path, ".fish")
    return [
        Formatter(["statix", "fix", *dry_run_arg, repo_path], stdout_is_error=check),
        Formatter(["nixfmt", "--verify", "--strict", *check_arg, *git_files(repo_path, ".nix")]),
        Formatter(["ruff", "format", *check_arg]),
        Formatter(["ruff", "check", "--fix", "--unsafe-fixes", *diff_arg]),
        Formatter(["mdformat", *git_files(repo_path, ".md"), *check_arg]),
        Formatter(["shfmt", *write_arg, *diff_arg, repo_path]),
        Formatter(["prettier", *write_arg, repo_path, *check_arg]),
        Formatter(["stylua", repo_path, *check_arg]),
        Formatter(["kdlfmt", "format" if not check else "check", *git_files(repo_path, ".kdl")]),
        # `fish_indent` is a fish builtin, so it must be invoked through a fish shell.
        Formatter(["fish", "--no-config", "--command", "fish_indent " + " ".join(write_arg + check_arg + fish_files)]),
    ]


def format_code(*, repo_path: Path, check: bool) -> None:
    for formatter in _formatters(repo_path, check=check):
        result = run_shell(formatter.argv, cwd=repo_path, capture_output=formatter.stdout_is_error)
        if formatter.stdout_is_error and result.stdout.strip():
            raise RuntimeError(result.stdout)
