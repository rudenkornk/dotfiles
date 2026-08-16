import logging
import subprocess
from collections.abc import Sequence
from concurrent.futures import ThreadPoolExecutor
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


@dataclass(frozen=True)
class Linter:
    argv: Sequence[str | Path]
    # Return codes treated as success; a linter may reserve some non-zero codes
    # for conditions that are not lint findings.
    ok_returncodes: Sequence[int] = (0,)


def _linters(repo_path: Path) -> list[Linter]:
    return [
        Linter(["gitleaks", "git"]),
        Linter(["statix", "check", repo_path]),
        Linter(["mypy", repo_path]),
        Linter(["ruff", "check"]),
        Linter(["yamllint", "--strict", repo_path / ".github"]),
        Linter(["shellcheck", *git_files(repo_path, ".sh")]),
        Linter(["typos"]),
        Linter(["markdownlint-cli2", "."]),
        # `jq` has no compile-only mode, so its programs are linted by running them on null input:
        # a broken program fails to compile (exit 3), while a healthy one either succeeds
        # or reports a runtime error about the unexpected null (exit 5).
        # `.jq` files are lint-only: the sole formatter candidate, `jqfmt`,
        # strips comments and silently drops `def` statements.
        *[
            Linter(["jq", "--null-input", "--from-file", jq_file], ok_returncodes=(0, 5))
            for jq_file in git_files(repo_path, ".jq")
        ],
    ]


def _run_linter(argv: Sequence[str | Path], repo_path: Path) -> subprocess.CompletedProcess[str]:
    # Capture output so concurrently-running linters do not interleave their streams.
    return run_shell(argv, cwd=repo_path, capture_output=True, check=False)


def lint_code(*, repo_path: Path) -> None:
    _ensure_full_history()
    linters = _linters(repo_path)

    # The linters are independent and read-only, so we run them concurrently.
    with ThreadPoolExecutor(max_workers=len(linters)) as executor:
        results = executor.map(lambda linter: (linter, _run_linter(linter.argv, repo_path)), linters)

    failures: list[str] = []
    for linter, result in results:
        name = str(linter.argv[0])
        output = (result.stdout + result.stderr).strip()
        if output:
            _logger.info(f"----- {name} -----")
            # Indent each line so the grouped output stands out from the log lines.
            print("\n".join("    " + line for line in output.splitlines()))  # noqa: T201
        if result.returncode not in linter.ok_returncodes:
            failures.append(name)

    if failures:
        msg = f"Linters reported problems: {', '.join(failures)}"
        raise RuntimeError(msg)


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
