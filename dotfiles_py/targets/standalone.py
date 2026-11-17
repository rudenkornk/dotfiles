import json
import logging
import os
import stat
import tempfile
from collections.abc import Iterator
from contextlib import contextmanager
from enum import StrEnum
from pathlib import Path
from typing import NotRequired, TypedDict, cast
from urllib.parse import parse_qs, unquote, urlsplit

from ..utils import run_shell

_logger = logging.getLogger(__name__)


class Action(StrEnum):
    add = "add"
    rm = "rm"


class ProfileEntry(TypedDict):
    originalUrl: NotRequired[str]
    attrPath: NotRequired[str]
    storePaths: list[str]


class ProfileManifest(TypedDict):
    elements: dict[str, ProfileEntry]


def _default_profile() -> Path:
    run_shell(["nix", "profile", "list", "--json"], capture_output=True)
    xdg = run_shell(["nix", "config", "show", "use-xdg-base-directories"], capture_output=True).stdout.strip()
    if xdg == "true":
        state = Path(os.environ.get("XDG_STATE_HOME") or Path.home() / ".local/state")
        link = state / "nix/profile"
    else:
        link = Path.home() / ".nix-profile"
    return link.parent / link.readlink() if link.is_symlink() else link


def _manifest(profile: Path) -> ProfileManifest:
    result = run_shell(["nix", "profile", "list", "--profile", profile, "--json"], capture_output=True)
    return cast("ProfileManifest", json.loads(result.stdout))


def _package(entry: ProfileEntry, repo_path: Path) -> str | None:
    source = urlsplit(entry.get("originalUrl", ""))
    if source.scheme not in ("git+file", "file", "path", "") or source.netloc:
        return None
    if parse_qs(source.query).get("dir", [""])[0]:
        return None
    if not source.path or Path(unquote(source.path)).resolve() != repo_path.resolve():
        return None
    match entry.get("attrPath", "").split("."):
        case ["packages", _, package]:
            return package
        case _:
            return None


def _targets(repo_path: Path, packages: list[str]) -> list[str]:
    available = {path.stem for path in (repo_path / "nix/packages").glob("*.nix") if path.is_file()}
    if packages == ["all"]:
        return sorted(available)
    if not packages or "all" in packages or set(packages) - available:
        msg = f"Specify package names from {', '.join(sorted(available))}, or 'all' alone."
        raise ValueError(msg)
    return list(dict.fromkeys(packages))


def _runtime_directory() -> Path:
    runtime = Path(os.environ.get("XDG_RUNTIME_DIR") or f"/run/user/{os.getuid()}")
    info = runtime.stat()
    if not runtime.is_dir() or info.st_uid != os.getuid() or stat.S_IMODE(info.st_mode) != stat.S_IRWXU:
        msg = "The runtime directory must be owned by the current user with permissions 0700."
        raise RuntimeError(msg)
    filesystem = run_shell(
        ["findmnt", "--noheadings", "--output", "FSTYPE", "--target", runtime], capture_output=True
    ).stdout.strip()
    if filesystem != "tmpfs":
        msg = "The runtime directory must be on tmpfs; refusing to write decrypted metadata to disk."
        raise RuntimeError(msg)
    return runtime


@contextmanager
def _metadata_file(repo_path: Path, packages: list[str]) -> Iterator[Path | None]:
    path = repo_path / "nix/secrets/corp/packages_info.sops.json"
    if not path.is_file():
        yield None
        return
    encrypted: dict[str, object] = json.loads(path.read_text())
    selected = set(packages) & (encrypted.keys() - {"sops"})
    if not selected:
        yield None
        return
    with tempfile.NamedTemporaryFile(
        mode="w", prefix="dotfiles-packages-", suffix=".json", dir=_runtime_directory()
    ) as file:
        result = run_shell(["sops", "--decrypt", path], capture_output=True)
        metadata: dict[str, object] = json.loads(result.stdout)
        json.dump({name: metadata[name] for name in sorted(selected)}, file)
        file.flush()
        yield Path(file.name)


def _removals(manifest: ProfileManifest, repo_path: Path, packages: list[str]) -> list[str]:
    matches: dict[str, list[str]] = {name: [] for name in packages}
    for name, entry in manifest["elements"].items():
        package = _package(entry, repo_path)
        if package in matches:
            matches[package].append(name)
    if any(len(entries) > 1 for entries in matches.values()):
        msg = "Multiple profile entries match a selected package; resolve duplicates with 'nix profile' first."
        raise ValueError(msg)
    return [name for entries in matches.values() for name in entries]


def _add_packages(repo_path: Path, packages: list[str], profile: Path) -> None:
    with _metadata_file(repo_path, packages) as metadata:
        run_shell(
            [
                "nix",
                "profile",
                "add",
                "--profile",
                profile,
                "--impure",
                "--no-update-lock-file",
                *[f"{repo_path}#{name}" for name in packages],
            ],
            extra_env={"DOTFILES_PACKAGES_INFO_FILE": str(metadata) if metadata is not None else ""},
            cwd=repo_path,
        )


def _publish_profile(profile: Path, staged: Path, original: Path | None) -> None:
    current = profile.readlink() if profile.is_symlink() else None
    if current != original:
        msg = "The profile changed while staging; retry without concurrent profile operations."
        raise RuntimeError(msg)
    if profile.exists() and staged.resolve() == profile.resolve():
        _logger.info("The selected standalone packages are already up to date.")
        return
    run_shell(["nix", "build", "--no-link", "--profile", profile, staged.resolve()])


def manage_packages(*, repo_path: Path, action: Action, packages: list[str], profile: Path | None = None) -> None:
    packages = _targets(repo_path, packages)
    profile = profile or _default_profile()
    original = profile.readlink() if profile.is_symlink() else None
    removals = _removals(_manifest(profile), repo_path, packages)
    if action == Action.rm and not removals:
        _logger.info("No matching standalone packages are installed.")
        return
    with tempfile.TemporaryDirectory(prefix="dotfiles-standalone-") as directory:
        staged = Path(directory) / "profile"
        if profile.exists():
            staged.symlink_to(profile.resolve())
        if removals:
            run_shell(["nix", "profile", "remove", "--profile", staged, *removals])
        if action == Action.add:
            _add_packages(repo_path, packages, staged)
        _publish_profile(profile, staged, original)
