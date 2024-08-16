import logging
from pathlib import Path

from .. import utils
from . import update_utils
from .bootstrap import bootstrap

_logger = logging.getLogger(__name__)

_ansible_manifest_path = utils.REPO_PATH / "roles" / "manifest" / "vars" / "main.yaml"
_ansible_collections_path = utils.REPO_PATH / "roles" / "manifest" / "vars" / "ansible.yaml"
_neovim_manifest_path = utils.REPO_PATH / "roles" / "neovim" / "files" / "nvchad" / "plugins" / "manifest.lua"
_requirements_path = utils.REPO_PATH / "requirements.txt"
_global_requirements_path = utils.REPO_PATH / "roles" / "python" / "files" / "global_requirements.txt"


def get_ansible_choices(manifest_path: Path) -> list[str]:
    yaml, _ = utils.yaml_read(manifest_path)
    assert isinstance(yaml, dict)
    return list(yaml["manifest"].keys())


def get_neovim_plugins_choices() -> list[str]:
    return list(utils.lua_read(_neovim_manifest_path).keys())


def get_update_choices() -> list[str]:
    ansible_choices = get_ansible_choices(_ansible_manifest_path)
    ansible_collections_choices = get_ansible_choices(_ansible_collections_path)
    choices = ansible_choices + ansible_collections_choices + ["requirements"]
    choices.sort()
    return choices


def _update(choice: str, dry_run: bool) -> None:
    title = choice.replace("_", " ")
    suffix = " (dry run)" if dry_run else ""
    _logger.info(f"Updating {title}{suffix}:")

    if choice == "requirements":
        _logger.info("  Updating requirements.txt")
        update_utils.update_requirements_txt(_requirements_path, dry_run=dry_run)

        _logger.info("")
        _logger.info("  Updating global_requirements.txt")
        update_utils.update_requirements_txt(_global_requirements_path, dry_run=dry_run)
    # Deprecate nvchad
    # elif choice == "neovim_plugins":
    #    for plugin in get_neovim_plugins_choices():
    #        _update_utils.update_neovim_plugin(_neovim_manifest_path, plugin, dry_run=dry_run)
    elif choice in get_ansible_choices(_ansible_manifest_path):
        update_utils.update_ansible_entry(_ansible_manifest_path, choice, dry_run=dry_run)
    elif choice in get_ansible_choices(_ansible_collections_path):
        update_utils.update_ansible_entry(_ansible_collections_path, choice, dry_run=dry_run)
    else:
        assert False, f"Invalid choice: {choice}"

    _logger.info("")


def update(choices: list[str], dry_run: bool) -> None:
    bootstrap()

    for choice in choices:
        _update(choice, dry_run=dry_run)
