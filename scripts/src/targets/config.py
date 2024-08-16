import enum
import logging
import math
import os
import re
import shutil
import socket
from contextlib import closing
from functools import cache
from pathlib import Path
from typing import Any, Mapping

from ..utils import ARTIFACTS_PATH, REPO_PATH, SCRIPTS_PATH, run_shell, yaml_read, yaml_write
from .ansible_collections import ANSIBLE_COLLECTIONS_PATH, ansible_collections
from .bootstrap import bootstrap

_logger = logging.getLogger(__name__)

_ANSIBLE_LOGS_PATH = ARTIFACTS_PATH / "ansible_logs"


@cache
def hosts() -> dict[str, dict[str, str]]:
    inventory, _ = yaml_read(REPO_PATH / "inventory.yaml")
    assert isinstance(inventory, dict)
    return dict(inventory["all"]["hosts"])


@cache
def container_hosts() -> dict[str, dict[str, str]]:
    return {name: desc for name, desc in hosts().items() if desc.get("ansible_connection") in ("docker", "podman")}


@cache
def images() -> list[str]:
    return [desc["image"] for desc in container_hosts().values() if "image" in desc]


def _start_container(name: str) -> None:
    image = next(desc["image"] for name_, desc in hosts().items() if name_ == name)
    logs = _ANSIBLE_LOGS_PATH / f"startup_{name}.log"
    logs.parent.mkdir(parents=True, exist_ok=True)
    run_shell(
        [
            "ansible-playbook",
            "--extra-vars",
            f"container={name}",
            "--extra-vars",
            f"image={image}",
            "--inventory",
            REPO_PATH / "inventory.yaml",
            SCRIPTS_PATH / "playbook_dotfiles_container.yaml",
        ],
        extra_env={"ANSIBLE_LOG_PATH": logs, "ANSIBLE_COLLECTIONS_PATH": ANSIBLE_COLLECTIONS_PATH},
    )


def _changes(logs: str) -> list[str]:
    changes = []
    current_task = ""
    for line in logs.splitlines():
        if match := re.search(r"\d{4}-\d{2}-\d{2}.*?\| (.*)", line):
            line = match.group(1)

        if line.startswith("TASK"):
            current_task = ""
        current_task += line + "\n"
        if line.startswith("changed:"):
            changes.append(current_task)
    return changes


def _verify_unchanged() -> None:
    file_changes = []
    for logpath in _ANSIBLE_LOGS_PATH.glob("*.log"):
        log = logpath.read_text(encoding="utf-8")
        if changes := _changes(log):
            file_changes.append((logpath, changes))
        else:
            # Double check with another log search,
            # since our log parsing is fragile
            if not re.search(r"changed=[1-9]", log):
                continue
            file_changes.append((logpath, ["(Could not parse changes, but there are some)"]))

    if not file_changes:
        return

    for logpath, changes in file_changes:
        _logger.error(f"Changes detected in {logpath.name}")
        for change in changes:
            _logger.error("\n" + change)
    raise RuntimeError("\nIDEMPOTENCY CHECK FAILED!")


def _ansible_verbosity() -> str:
    if env_verbosity := os.getenv("ANSIBLE_VERBOSITY"):
        return env_verbosity

    current_level = _logger.getEffectiveLevel()
    if current_level >= logging.INFO:
        return "0"

    verbosity = math.ceil((logging.INFO - current_level) / 10) + 1
    return str(verbosity)


def _check_port(address: str, port: int) -> bool:
    with closing(socket.socket(socket.AF_INET, socket.SOCK_STREAM)) as sock:
        if sock.connect_ex((address, port)) == 0:
            return True
        return False


def _setup_ssh_port(hostname: str, host: dict[str, Any], ssh_config: Mapping[str, Any] | None) -> None:
    port_candidates = [22]
    if predefined_port := host.get("ansible_port"):
        port_candidates.append(int(predefined_port))

    if ssh_config is not None:
        port_candidates.append(ssh_config["ssh_server_config_map"][host.get("ssh_kind", "default_kind")]["port"])

    address = host.get("ansible_host", hostname)
    assert isinstance(address, str)
    for port in port_candidates:
        if not _check_port(address, port):
            continue
        if port is not None:
            host["ansible_port"] = port
        return
    raise RuntimeError(f"Could not connect to {address} on any of the following ports: {port_candidates}")


def _setup_ssh(hostname: str, host: dict[str, Any]) -> None:
    if host.get("ansible_connection", "ssh") != "ssh":
        return

    ssh_config_path = REPO_PATH / "roles" / "ssh_server" / "vars" / "ssh_server_config.yaml"
    ssh_config: None | dict[str, Any] = None
    if not ssh_config_path.exists():
        _logger.warning(f"SSH config is not decrypted locally: {ssh_config_path}")
        _logger.warning("Using default settings for SSH connection.")
        _logger.warning("This might result in connection issues.")
    else:
        ssh_config, _ = yaml_read(ssh_config_path)  # type: ignore

    _setup_ssh_port(hostname, host, ssh_config)


def _setup_credentials(_: str, host: dict[str, Any], user: str) -> None:
    # Containers have empty passwords, since docker/podman connections do not support passwords
    # Local connections are handled in a different way by directly supplying password
    if host.get("ansible_connection", "ssh") in ("docker", "podman", "local"):
        return

    if host.get("ansible_become_pass") is not None:
        return

    creds_config_path = REPO_PATH / "roles" / "credentials" / "vars" / "credentials_map.yaml"
    if not creds_config_path.exists():
        _logger.warning(f"Credentials config is not decrypted locally: {creds_config_path}")
        _logger.warning("This might result in priviledges escalation problems.")
        return
    creds_config, _1 = yaml_read(creds_config_path)
    assert isinstance(creds_config, dict)

    creds_host = creds_config["credentials_map"][host.get("credentials_kind", "default_kind")]
    creds_user = creds_host.get(user, creds_host["default_user"])
    host["ansible_become_pass"] = creds_user["password"]


def _setup_host(hostname: str, host: dict[str, Any]) -> dict[str, Any]:
    host = host.copy()
    _setup_ssh(hostname, host)
    _setup_credentials(hostname, host, "ansible_user")
    return host


def _setup_inventory(hostnames: list[str]) -> Path:
    # Dynamically set correct secret settings for the hosts

    inventory, yaml = yaml_read(REPO_PATH / "inventory.yaml")
    assert isinstance(inventory, dict)
    for hostname in hostnames:
        inventory["all"]["hosts"][hostname] = _setup_host(hostname, inventory["all"]["hosts"][hostname])

    private_inventory_path = ARTIFACTS_PATH / "private_inventory.yaml"
    private_inventory_path.parent.mkdir(parents=True, exist_ok=True)
    private_inventory_path.touch(exist_ok=True)
    private_inventory_path.chmod(0o600)
    yaml_write(private_inventory_path, inventory, yaml)
    return private_inventory_path


class ConfigMode(enum.Enum):
    BOOTSTRAP = enum.auto()
    REDUCED = enum.auto()
    FULL = enum.auto()

    @classmethod
    def values(cls) -> list[str]:
        return [mode.name.lower() for mode in cls]


def config(hostnames: list[str], user: str, verify_unchanged: bool, mode: ConfigMode) -> None:
    bootstrap()
    ansible_collections()

    if verify_unchanged:
        shutil.rmtree(_ANSIBLE_LOGS_PATH, ignore_errors=True)

    _ANSIBLE_LOGS_PATH.mkdir(exist_ok=True)

    container_hosts_ = container_hosts()
    for host_ in hostnames:
        if host_ in container_hosts_:
            _start_container(host_)

    inventory_path = _setup_inventory(hostnames)

    has_local = "localhost" in hostnames or "127.0.0.1" in hostnames
    hosts_var = ",".join(hostnames)

    run_shell(
        ["bash", SCRIPTS_PATH / "config.sh"],
        extra_env={
            "ANSIBLE_COLLECTIONS_PATH": ANSIBLE_COLLECTIONS_PATH,
            "ANSIBLE_VERBOSITY": _ansible_verbosity(),
            "CONFIG_MODE": mode.name.lower(),
            "HOSTS": hosts_var,
            "INVENTORY": inventory_path,
            "LOCAL": str(has_local).lower(),
            "LOGS_PATH": _ANSIBLE_LOGS_PATH,
            "PLAYBOOK": REPO_PATH / "playbook.yaml",
            "PLAYBOOK_BOOTSTRAP_HOSTS": str(REPO_PATH / "playbook_bootstrap_hosts.yaml"),
            "REMOTE_USER": user,
            "REPO_PATH": REPO_PATH,
        },
    )

    if verify_unchanged:
        _verify_unchanged()
