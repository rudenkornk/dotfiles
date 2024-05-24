import logging as _logging
from pathlib import Path as _Path

from .. import utils as _utils
from . import update_utils as _update_utils
from .bootstrap import bootstrap as _bootstrap

_logger = _logging.getLogger(__name__)

_ansible_manifest_path = _utils.REPO_PATH / "roles" / "manifest" / "vars" / "main.yaml"
_ansible_collections_path = _utils.REPO_PATH / "roles" / "manifest" / "vars" / "ansible.yaml"
_neovim_manifest_path = _utils.REPO_PATH / "roles" / "neovim" / "files" / "nvchad" / "plugins" / "manifest.lua"
_requirements_path = _utils.REPO_PATH / "requirements.txt"
_global_requirements_path = _utils.REPO_PATH / "roles" / "python" / "files" / "global_requirements.txt"


def get_ansible_choices(manifest_path: _Path) -> list[str]:
    yaml = _utils.yaml_read(manifest_path)
    assert isinstance(yaml, dict)
    return list(yaml["manifest"].keys())


def get_neovim_plugins_choices() -> list[str]:
    return list(_utils.lua_read(_neovim_manifest_path).keys())


def get_update_choices() -> list[str]:
    ansible_choices = get_ansible_choices(_ansible_manifest_path)
    ansible_collections_choices = get_ansible_choices(_ansible_collections_path)
    choices = ansible_choices + ansible_collections_choices + ["requirements"]
    choices.sort()
    return choices


def update(choice: str, dry_run: bool) -> None:
    _bootstrap()

    title = choice.replace("_", " ")
    suffix = " (dry run)" if dry_run else ""
    _logger.info(f"Updating {title}{suffix}:")

    if choice == "requirements":
        _logger.info("  Updating requirements.txt")
        _update_utils.update_requirements_txt(_requirements_path, dry_run=dry_run)

        _logger.info("")
        _logger.info("  Updating global_requirements.txt")
        _update_utils.update_requirements_txt(_global_requirements_path, dry_run=dry_run)
    # Deprecate nvchad
    # elif choice == "neovim_plugins":
    #    for plugin in get_neovim_plugins_choices():
    #        _update_utils.update_neovim_plugin(_neovim_manifest_path, plugin, dry_run=dry_run)
    elif choice in get_ansible_choices(_ansible_manifest_path):
        _update_utils.update_ansible_entry(_ansible_manifest_path, choice, dry_run=dry_run)
    elif choice in get_ansible_choices(_ansible_collections_path):
        _update_utils.update_ansible_entry(_ansible_collections_path, choice, dry_run=dry_run)
    else:
        assert False, f"Invalid choice: {choice}"

    _logger.info("")
