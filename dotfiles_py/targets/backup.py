import glob
import logging
import os
import shutil
from collections.abc import Sequence
from pathlib import Path

from ..utils import sudo_mkdir, sudo_python
from . import _file_copy

_logger = logging.getLogger(__name__)

_USER_PATHS = (
    ".itsme",
    ".tpm2_pkcs11",
    ".local/share/keyrings",
    ".config/NetworkManager",
    ".config/netplan",
    ".config/splitty",
    ".config/strongswan",
    ".config/openvpn",
    ".config/vpnc",
    ".config/systemd/user",
    ".pki",
    ".skotty",
    ".ssh",
)
_SYSTEM_PATHS = (
    "/etc/NetworkManager",
    "/run/NetworkManager/system-connections",
    "/usr/lib/NetworkManager/system-connections",
    "/etc/netplan",
    "/run/netplan",
    "/lib/netplan",
    "/etc/network",
    "/etc/systemd/network",
    "/run/systemd/network",
    "/usr/lib/systemd/network",
    "/etc/wpa_supplicant",
    "/etc/cloud/cloud.cfg.d",
    "/etc/openvpn",
    "/etc/vpnc",
    "/etc/ipsec.conf",
    "/etc/ipsec.secrets",
    "/etc/ipsec.d",
    "/etc/strongswan*",
    "/etc/swanctl",
    "/etc/wireguard",
    "/etc/tpm2_pkcs11",
    "/etc/tpm2-pkcs11",
    "/etc/tpm2-tss",
    "/var/lib/tpm2-pkcs11",
    "/var/lib/tpm2_pkcs11",
    "/var/lib/tpm2-tss",
    "/var/lib/NetworkManager",
    "/etc/ssl",
    "/etc/pki",
    "/usr/local/share/ca-certificates",
    "/usr/share/ca-certificates",
    "/etc/ca-certificates.conf",
    "/etc/hosts",
    "/etc/host.conf",
    "/etc/hostname",
    "/etc/nsswitch.conf",
    "/etc/resolv.conf",
    "/etc/resolvconf",
    "/etc/systemd/resolved.conf",
    "/etc/systemd/resolved.conf.d",
    "/etc/systemd/system",
    "/etc/default",
    "/etc/environment",
    "/etc/osquery",
    "/var/lib/osquery",
    "/etc/splitty",
    "/etc/splitty.*",
    "/usr/lib/systemd/system/osquery*",
    "/usr/lib/systemd/system/splitty*",
    "/lib/systemd/system/osquery*",
    "/lib/systemd/system/splitty*",
)


def _copy_source(source: Path, backup_dir: Path, *, privileged: bool) -> bool:
    if not source.exists() and not source.is_symlink():
        _logger.info(f"Missing: {source}")
        return True
    resolved = source.resolve(strict=True)
    if backup_dir.is_relative_to(resolved):
        _logger.error(f"Backup directory is inside source: {source}")
        return False
    target = backup_dir / source.relative_to("/")
    _logger.info(f"Copying: {source}")
    if privileged:
        success = not (
            sudo_mkdir(target.parent, parents=True, exist_ok=True, check=False).returncode
            or sudo_python([Path(_file_copy.__file__), source, target], check=False).returncode
        )
    else:
        target.parent.mkdir(parents=True, exist_ok=True)
        success = _file_copy.copy_path(source, target)
    if not success:
        _logger.error(f"Failed: {source}")
    return success


def _copy_paths(paths: Sequence[Path], *, backup_dir: Path, privileged: bool) -> bool:
    failed = False
    for source in paths:
        try:
            if not _copy_source(source, backup_dir, privileged=privileged):
                failed = True
        except (OSError, ValueError):
            _logger.exception(f"Failed: {source}")
            failed = True
    return failed


def _backup(backup_dir: Path, home: Path) -> None:
    _logger.warning("This backup contains plaintext credentials. Keep the USB drive secure.")
    _logger.warning("Services remain running; database copies are best-effort, not guaranteed consistent.")
    _logger.warning("Custom certificate, credential and TPM store paths must be backed up separately.")
    failed = _copy_paths(
        [home / path for path in _USER_PATHS],
        backup_dir=backup_dir,
        privileged=False,
    )
    system_paths = [
        match
        for pattern in _SYSTEM_PATHS
        for match in (sorted(Path("/").glob(pattern.removeprefix("/"))) if glob.has_magic(pattern) else [Path(pattern)])
    ]
    _logger.info("User files processed. Requesting sudo for system files.")
    system_failed = _copy_paths(system_paths, backup_dir=backup_dir, privileged=True)
    if failed or system_failed:
        msg = f"Backup incomplete; review the errors above. Partial backup: {backup_dir}"
        raise RuntimeError(msg)
    _logger.info(f"Backup complete: {backup_dir}")


def backup_corp(*, backup_dir: Path) -> None:
    if os.geteuid() == 0:
        msg = "Run backup-corp as your ordinary user, not root."
        raise RuntimeError(msg)
    if shutil.which("sudo") is None:
        msg = "Required command is missing: sudo"
        raise RuntimeError(msg)

    home = Path.home().resolve(strict=True)
    previous_umask = os.umask(0o077)
    try:
        backup_dir.mkdir()
        _backup(backup_dir.resolve(strict=True), home)
    finally:
        os.umask(previous_umask)
