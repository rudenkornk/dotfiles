import json
import logging
import os
import platform
import shutil
import subprocess
import tempfile
from collections.abc import Mapping
from pathlib import Path
from typing import Any

import typer
from ruamel.yaml import YAML
from ruamel.yaml.scalarstring import DoubleQuotedScalarString

from ..utils import git_files, run_shell, yaml_read

_logger = logging.getLogger(__name__)

_SOPS_CONFIG = ".sops.yaml"
_SOFTWARE_KEY_PREFIX = "AGE-SECRET-KEY-"
_TPM_KEY_PREFIX = "AGE-PLUGIN-TPM-"


def secret_files(repo_path: Path) -> list[str]:
    secrets = git_files(repo_path, ".sops", ".sops.yaml", ".sops.yml", ".sops.json")
    return sorted(secret for secret in secrets if Path(secret).name != _SOPS_CONFIG)


def updatekeys(
    *,
    repo_path: Path,
    env: Mapping[str, str | Path] | None = None,
    extra_env: Mapping[str, str | Path] | None = None,
) -> None:
    run_shell(["sops", "updatekeys", "--yes", *secret_files(repo_path)], cwd=repo_path, env=env, extra_env=extra_env)


def bootstrap_crypto(*, repo_path: Path) -> None:
    # The end state is always a TPM identity in `keys.txt`, so a broken TPM setup fails fast,
    # before any key is requested.
    if (problem := _tpm_problem()) is not None:
        msg = f"Cannot use TPM keys on this machine: {problem}"
        raise RuntimeError(msg)

    # `XDG_RUNTIME_DIR` is a tmpfs, so pasted and generated keys never touch persistent storage.
    runtime_dir = os.environ.get("XDG_RUNTIME_DIR", tempfile.gettempdir())
    with tempfile.TemporaryDirectory(prefix="bootstrap-crypto-", dir=runtime_dir) as tmp_str:
        tmp = Path(tmp_str)
        # An empty config home hides any real `~/.config/sops/age/keys.txt` from sops.
        (tmp / "xdg").mkdir()
        _bootstrap_crypto(repo_path=repo_path, tmp=tmp)


def _bootstrap_crypto(*, repo_path: Path, tmp: Path) -> None:
    key_file = _prompt_working_key(repo_path=repo_path, tmp=tmp)
    if key_file.read_text().startswith(_SOFTWARE_KEY_PREFIX):
        identity_file = _register_tpm_key(repo_path=repo_path, tmp=tmp, software_key_file=key_file)
    else:
        identity_file = key_file

    if identity_file is None:
        return

    _install_identity(identity_file=identity_file, tmp=tmp)
    _restart_secret_services()
    _switch_origin_to_ssh(repo_path)
    _atuin_login(repo_path)
    _logger.info("Done: this machine now decrypts repo secrets with TPM key.")


def _prompt_working_key(*, repo_path: Path, tmp: Path) -> Path:
    key_file = tmp / "supplied_key.txt"
    while True:
        key = str(typer.prompt("Paste an AGE secret key (input is hidden)", hide_input=True)).strip()
        if not key.startswith((_SOFTWARE_KEY_PREFIX, _TPM_KEY_PREFIX)):
            _logger.warning(f"Expected a single key line starting with {_SOFTWARE_KEY_PREFIX} or {_TPM_KEY_PREFIX}.")
            continue
        key_file.touch(mode=0o600)
        key_file.write_text(key + "\n")
        if _key_decrypts(repo_path=repo_path, tmp=tmp, key_file=key_file):
            _logger.info("The supplied key decrypts repo secrets.")
            return key_file
        _logger.warning("The supplied key does not decrypt repo secrets, try another one (Ctrl+C to abort).")


def _register_tpm_key(*, repo_path: Path, tmp: Path, software_key_file: Path) -> Path | None:
    hostname = platform.node()
    if not typer.confirm(f"A software key was supplied. Generate & register a TPM key for '{hostname}'?", default=True):
        _logger.info("Ok, exiting without changes.")
        return None

    _check_secrets_unmodified(repo_path)

    identity_file = tmp / "tpm_identity.txt"
    run_shell(["age-plugin-tpm", "--generate", "-o", identity_file])
    if not _add_recipient(repo_path=repo_path, recipient=_identity_recipient(identity_file), hostname=hostname):
        return None
    updatekeys(repo_path=repo_path, env=_sanitized_env(), extra_env=_sops_key_env(tmp=tmp, key_file=software_key_file))

    # Prove the full chain (recipient in `.sops.yaml`, re-encrypted files, TPM decryption) before persisting anything.
    if not _key_decrypts(repo_path=repo_path, tmp=tmp, key_file=identity_file):
        run_shell(["git", "restore", "--", _SOPS_CONFIG, *secret_files(repo_path)], cwd=repo_path)
        msg = "The new TPM key failed to decrypt re-encrypted secrets; the repo changes were rolled back."
        raise RuntimeError(msg)

    _commit_recipient_change(repo_path)
    return identity_file


def _sanitized_env() -> dict[str, str]:
    # Ambient key material (`SOPS_AGE_KEY`, `SOPS_AGE_KEY_FILE`, ...) would defeat
    # the "does THIS key work" checks, so sops runs without it.
    return {k: v for k, v in os.environ.items() if not k.startswith("SOPS_AGE_")}


def _sops_key_env(*, tmp: Path, key_file: Path) -> dict[str, str | Path]:
    return {"SOPS_AGE_KEY_FILE": key_file, "XDG_CONFIG_HOME": tmp / "xdg"}


def _key_decrypts(*, repo_path: Path, tmp: Path, key_file: Path) -> bool:
    probe = secret_files(repo_path)[0]
    # The plaintext is captured only to keep it off the terminal and is discarded right away.
    result = run_shell(
        ["sops", "--decrypt", probe],
        env=_sanitized_env(),
        extra_env=_sops_key_env(tmp=tmp, key_file=key_file),
        capture_output=True,
        check=False,
        cwd=repo_path,
    )
    if result.returncode != 0:
        _logger.debug(f"sops failed to decrypt {probe}:\n{result.stderr}")
    return result.returncode == 0


def _tpm_problem() -> str | None:
    if shutil.which("age-plugin-tpm") is None:
        return "age-plugin-tpm is not on PATH."
    tpm_device = Path("/dev/tpmrm0")
    if not tpm_device.exists():
        return f"TPM device {tpm_device} does not exist."
    if not os.access(tpm_device, os.R_OK | os.W_OK):
        return f"TPM device {tpm_device} is not accessible, expected the user to be in the 'tss' group."
    return None


def _check_secrets_unmodified(repo_path: Path) -> None:
    cmd = ["git", "status", "--porcelain", "--", _SOPS_CONFIG, *secret_files(repo_path)]
    status = run_shell(cmd, capture_output=True, cwd=repo_path).stdout.strip()
    if status:
        msg = f"{_SOPS_CONFIG} or secret files have uncommitted changes, commit or stash them first:\n{status}"
        raise RuntimeError(msg)


def _identity_recipient(identity_file: Path) -> str:
    prefix = "# Recipient: "
    for line in identity_file.read_text().splitlines():
        if line.startswith(prefix):
            return line.removeprefix(prefix).strip()
    msg = f"No '{prefix}' line found in the generated identity {identity_file}."
    raise RuntimeError(msg)


def _represent_capitalized_bool(representer: Any, data: bool) -> Any:  # noqa: ANN401, FBT001
    return representer.represent_scalar("tag:yaml.org,2002:bool", "True" if data else "False")


def _recipient_index(recipients: Any, comment: str) -> int | None:  # noqa: ANN401
    for idx in range(len(recipients)):
        tokens = recipients.ca.items.get(idx)
        if tokens and tokens[0] and str(tokens[0].value).strip() == f"# {comment}":
            return idx
    return None


def _add_recipient(*, repo_path: Path, recipient: str, hostname: str) -> bool:
    config_path = repo_path / _SOPS_CONFIG
    data, yaml = yaml_read(config_path)
    if not isinstance(data, dict):
        msg = f"Expected a mapping at the top level of {config_path}."
        raise TypeError(msg)
    _configure_sops_yaml_style(yaml)

    recipients = data["creation_rules"][0]["age"]
    comment = f"TPM on {hostname}."
    idx = _recipient_index(recipients, comment)
    if idx is None:
        idx = len(recipients)
        recipients.append(DoubleQuotedScalarString(recipient))
    elif typer.confirm(f"{_SOPS_CONFIG} already has '# {comment}'. Replace it with the new key?", default=True):
        recipients[idx] = DoubleQuotedScalarString(recipient)
        recipients.ca.items.pop(idx, None)
    else:
        _logger.info("Ok, keeping the existing recipient and exiting without changes.")
        return False
    # 0-based column where recipient values start: six spaces of list indent plus a dash and a space.
    recipient_column = 8
    # Place the comment one space after the closing quote, matching the neighboring entries.
    recipients.yaml_add_eol_comment(comment, idx, column=recipient_column + len(recipient) + 3)
    yaml.dump(data, config_path)
    return True


def _configure_sops_yaml_style(yaml: YAML) -> None:
    # Match the hand-written style of `.sops.yaml`:
    # sequences indented under their key with a two-space dash offset, and booleans capitalized.
    yaml.indent(mapping=2, sequence=4, offset=2)
    yaml.representer.add_representer(bool, _represent_capitalized_bool)


def _restart_secret_services() -> None:
    # On a fresh machine these services have already run without keys at boot,
    # so re-run them to bring secrets online without a reboot.
    commands = [
        ["systemctl", "--user", "restart", "ssh-agent-keys.service"],
        ["systemctl", "--user", "restart", "decrypt-secrets.service"],
        ["systemctl", "--user", "restart", "merge-config.service"],
        ["sudo", "systemctl", "restart", "decrypt-secrets.service"],
        ["sudo", "systemctl", "restart", "merge-config.service"],
    ]
    for command in commands:
        if run_shell(command, check=False).returncode != 0:
            _logger.warning(f"'{' '.join(command)}' failed; this will fix itself on the next boot.")


def _switch_origin_to_ssh(repo_path: Path) -> None:
    # The bootstrap flow clones anonymously over https; once the SSH keys are provisioned,
    # the remote can switch to ssh so that pushing works.
    https_prefix = "https://github.com/"
    result = run_shell(["git", "remote", "get-url", "origin"], capture_output=True, check=False, cwd=repo_path)
    if result.returncode != 0:
        _logger.warning("No 'origin' remote found, skipping the switch to ssh.")
        return
    url = result.stdout.strip()
    if not url.startswith(https_prefix):
        _logger.info(f"Origin '{url}' is not an https github url, leaving it as is.")
        return
    ssh_url = "git@github.com:" + url.removeprefix(https_prefix).removesuffix(".git") + ".git"
    run_shell(["git", "remote", "set-url", "origin", ssh_url], cwd=repo_path)
    _logger.info(f"Switched the 'origin' remote to {ssh_url}.")


def _atuin_login(repo_path: Path) -> None:
    secret_path = repo_path / "nix/secrets/"
    if os.getenv("USERKIND") == "corp":
        secret_path /= "corp"
    secret_path /= "atuin_credentials.sops.json"

    creds_raw = run_shell(["sops", "--decrypt", secret_path], capture_output=True, check=False)
    if creds_raw.returncode != 0:
        _logger.warning("Failed to decrypt atuin creds, skipping the atuin login.")
        return

    creds = json.loads(creds_raw.stdout)
    # Intentionally skipping encryption key -- it is decrypted at boot atuomatically.
    # Also using subprocess.run instead of run_shell to avoid printing the password.
    _logger.warning("Logging into atuin.")
    subprocess.run(  # noqa: S603
        ["atuin", "login", "--username", creds["username"], "--password", creds["password"], "--key", ""],  # noqa: S607
        check=False,
        text=True,
    )


def _commit_recipient_change(repo_path: Path) -> None:
    run_shell(["git", "add", "--", _SOPS_CONFIG, *secret_files(repo_path)], cwd=repo_path)
    message = f"feat(secrets): register tpm age key for {platform.node()}"
    run_shell(["git", "commit", "--message", message], cwd=repo_path)


def _install_identity(*, identity_file: Path, tmp: Path) -> None:
    identity = identity_file.read_text()
    key_line = _key_line(identity)
    xdg_config_home = Path(os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config")))
    _install_user_identity(target=xdg_config_home / "sops/age/keys.txt", identity=identity, key_line=key_line)
    _install_root_identity(identity=identity, key_line=key_line, tmp=tmp)


def _key_line(identity: str) -> str:
    lines = [line for line in identity.splitlines() if line and not line.startswith("#")]
    if not lines:
        msg = "No key line found in the identity content."
        raise RuntimeError(msg)
    return lines[-1]


def _merged_keys(existing: str, identity: str) -> str:
    merged = existing.rstrip("\n")
    if merged:
        merged += "\n\n"
    return merged + identity.rstrip("\n") + "\n"


def _install_user_identity(*, target: Path, identity: str, key_line: str) -> None:
    existing = target.read_text() if target.exists() else ""
    if key_line in existing:
        _logger.info(f"{target} already contains this key.")
        return
    target.parent.mkdir(parents=True, exist_ok=True)
    target.parent.chmod(0o700)
    target.parent.parent.chmod(0o700)
    target.touch(mode=0o600)
    target.write_text(_merged_keys(existing, identity))
    target.chmod(0o600)
    _logger.info(f"Installed the key into {target}.")


def _install_root_identity(*, identity: str, key_line: str, tmp: Path) -> None:
    root_keys_path = Path("/root/.config/sops/age/keys.txt")
    # Prime the sudo credential cache first, so that a failed `sudo cat` below
    # reliably means "file does not exist" rather than "authentication failed".
    run_shell(["sudo", "--validate"])
    existing_proc = run_shell(["sudo", "cat", root_keys_path], capture_output=True, check=False)
    existing = existing_proc.stdout if existing_proc.returncode == 0 else ""
    if key_line in existing:
        _logger.info(f"{root_keys_path} already contains this key.")
        return
    merged_file = tmp / "root_keys.txt"
    merged_file.touch(mode=0o600)
    merged_file.write_text(_merged_keys(existing, identity))
    run_shell(["sudo", "mkdir", "--parents", root_keys_path.parent])
    run_shell(["sudo", "chmod", "700", root_keys_path.parent.parent, root_keys_path.parent])
    run_shell(["sudo", "install", "--mode", "600", "--owner", "root", "--group", "root", merged_file, root_keys_path])
    _logger.info(f"Installed the key into {root_keys_path}.")
