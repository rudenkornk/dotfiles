import logging
import os
import shutil
from datetime import UTC, datetime
from pathlib import Path

_logger = logging.getLogger(__name__)

_XDG_PREFIXES = [
    (".config/", "XDG_CONFIG_HOME", ".config"),
    (".local/share/", "XDG_DATA_HOME", ".local/share"),
    (".cache/", "XDG_CACHE_HOME", ".cache"),
    (".local/state/", "XDG_STATE_HOME", ".local/state"),
]


def _resolve_xdg(rel: str, home_dir: Path) -> Path:
    for prefix, env_var, default_suffix in _XDG_PREFIXES:
        if rel.startswith(prefix):
            xdg_dir = Path(os.environ.get(env_var, home_dir / default_suffix))
            return xdg_dir / rel[len(prefix) :]
    return home_dir / rel


def _path_repr(path: Path, home_dir: Path) -> str:
    raw = "~" + str(path).removeprefix(str(home_dir)) if path.is_relative_to(home_dir) else str(path)
    return raw.replace("\n", "\\n").replace("\r", "\\r")


def _create_symlink(*, source: Path, dest: Path, home_dir: Path) -> None:
    dest_repr = _path_repr(dest, home_dir)
    source_repr = _path_repr(source, home_dir)

    if dest.is_symlink():
        _logger.debug(f"Overwriting existing symlink {dest_repr}")
        dest.unlink()
    elif dest.exists():
        msg = f"Target {dest_repr} already exists as a file or directory"
        raise RuntimeError(msg)

    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.symlink_to(source.resolve())
    _logger.info(f"Symlinked {dest_repr} -> {source_repr}")


def create_symlinks(*, source_dir: Path, target_dir: Path | None = None) -> None:
    home_dir = Path.home()
    resolved_target = home_dir if target_dir is None else target_dir
    apply_xdg = resolved_target == home_dir

    for source in sorted(source_dir.rglob("*")):
        if not source.is_file():
            continue
        rel = source.relative_to(source_dir).as_posix()
        dest = _resolve_xdg(rel, home_dir) if apply_xdg else resolved_target / rel
        _create_symlink(source=source, dest=dest, home_dir=home_dir)


def unlink_from_nix_store(link: Path) -> None:
    """Re-link given file from nix store to a local writable file.

    This function copies file from nix store to the same directory as the link,
    and then modifies the link to point to the new file.

    The function does not copy file to `link` path itself,
        since that would make home-manager clobber during activation phase,
        if `--backup` option is set.
    """
    if not link.is_symlink():
        _logger.debug(f"Requested relinking for not-symlink: {link}")
        return

    source = link.readlink()
    if not source.is_relative_to(Path("/nix/store")):
        _logger.debug(f"Link does not point to /nix/store: {link}")
        return

    date = datetime.now(tz=UTC).astimezone().strftime("%Y.%m.%d-%H.%M")
    dest = link.parent / (link.stem + "-" + date + link.suffix)
    shutil.copy2(source, dest)
    dest.chmod(dest.stat().st_mode | 0o200)  # Add write permission for owner.

    link.unlink()
    link.symlink_to(dest)
    _logger.info(f"Materialized symlink {link} -> {source}")
