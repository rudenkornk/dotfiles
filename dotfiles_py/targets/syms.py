import logging
import os
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
