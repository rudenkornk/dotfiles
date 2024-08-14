import enum as _enum
import logging as _logging
import math as _math
import os as _os
import re as _re
import shutil as _shutil
from functools import cache as _cache

from ..utils import ARTIFACTS_PATH as _ARTIFACTS_PATH
from ..utils import REPO_PATH as _REPO_PATH
from ..utils import SCRIPTS_PATH as _SCRIPTS_PATH
from ..utils import run_shell as _run_shell
from ..utils import yaml_read as _yaml_read
from .ansible_collections import ANSIBLE_COLLECTIONS_PATH as _ANSIBLE_COLLECTIONS_PATH
from .ansible_collections import ansible_collections as _ansible_collections
from .bootstrap import bootstrap as _bootstrap

_logger = _logging.getLogger(__name__)

_ANSIBLE_LOGS_PATH = _ARTIFACTS_PATH / "ansible_logs"


@_cache
def hosts() -> dict[str, dict[str, str]]:
    inventory, _ = _yaml_read(_REPO_PATH / "inventory.yaml")
    assert isinstance(inventory, dict)
    return dict(inventory["all"]["hosts"])


@_cache
def container_hosts() -> dict[str, dict[str, str]]:
    return {name: desc for name, desc in hosts().items() if desc.get("ansible_connection") in ("docker", "podman")}


@_cache
def images() -> list[str]:
    return [desc["image"] for desc in container_hosts().values() if "image" in desc]


def _start_container(name: str) -> None:
    image = next(desc["image"] for name_, desc in hosts().items() if name_ == name)
    logs = _ANSIBLE_LOGS_PATH / f"startup_{name}.log"
    logs.parent.mkdir(parents=True, exist_ok=True)
    _run_shell(
        [
            "ansible-playbook",
            "--extra-vars",
            f"container={name}",
            "--extra-vars",
            f"image={image}",
            "--inventory",
            _REPO_PATH / "inventory.yaml",
            _SCRIPTS_PATH / "playbook_dotfiles_container.yaml",
        ],
        extra_env={"ANSIBLE_LOG_PATH": logs, "ANSIBLE_COLLECTIONS_PATH": _ANSIBLE_COLLECTIONS_PATH},
    )


def _changes(logs: str) -> list[str]:
    changes = []
    current_task = ""
    for line in logs.splitlines():
        if match := _re.search(r"\d{4}-\d{2}-\d{2}.*?\| (.*)", line):
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
            if not _re.search(r"changed=[1-9]", log):
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
    if env_verbosity := _os.getenv("ANSIBLE_VERBOSITY"):
        return env_verbosity

    current_level = _logger.getEffectiveLevel()
    if current_level >= _logging.INFO:
        return "0"

    verbosity = _math.ceil((_logging.INFO - current_level) / 10) + 1
    return str(verbosity)


class ConfigMode(_enum.Enum):
    BOOTSTRAP = _enum.auto()
    REDUCED = _enum.auto()
    FULL = _enum.auto()

    @classmethod
    def values(cls) -> list[str]:
        return [mode.name.lower() for mode in cls]


def config(hostnames: list[str], user: str, verify_unchanged: bool, mode: ConfigMode) -> None:
    _bootstrap()
    _ansible_collections()

    if verify_unchanged:
        _shutil.rmtree(_ANSIBLE_LOGS_PATH, ignore_errors=True)

    _ANSIBLE_LOGS_PATH.mkdir(exist_ok=True)

    container_hosts_ = container_hosts()
    for host_ in hostnames:
        if host_ in container_hosts_:
            _start_container(host_)

    has_local = "localhost" in hostnames or "127.0.0.1" in hostnames
    hosts_var = ",".join(hostnames)

    _run_shell(
        ["bash", _SCRIPTS_PATH / "config.sh"],
        extra_env={
            "ANSIBLE_COLLECTIONS_PATH": _ANSIBLE_COLLECTIONS_PATH,
            "ANSIBLE_VERBOSITY": _ansible_verbosity(),
            "CONFIG_MODE": mode.name.lower(),
            "HOSTS": hosts_var,
            "INVENTORY": _REPO_PATH / "inventory.yaml",
            "LOCAL": str(has_local).lower(),
            "LOGS_PATH": _ANSIBLE_LOGS_PATH,
            "PLAYBOOK": _REPO_PATH / "playbook.yaml",
            "PLAYBOOK_BOOTSTRAP_HOSTS": str(_REPO_PATH / "playbook_bootstrap_hosts.yaml"),
            "REMOTE_USER": user,
            "REPO_PATH": _REPO_PATH,
        },
    )

    if verify_unchanged:
        _verify_unchanged()
