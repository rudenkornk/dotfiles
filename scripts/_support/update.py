#!/usr/bin/env python3

import logging as _logging

from . import update_utils as _update_utils
from . import utils as _utils

_logger = _logging.getLogger(__name__)

_ansible_manifest_path = _utils.get_repo_path() / "roles" / "manifest" / "vars" / "main.yaml"
_neovim_manifest_path = _utils.get_repo_path() / "roles" / "neovim" / "files" / "nvchad" / "plugins" / "manifest.lua"
_requirements_path = _utils.get_repo_path() / "requirements.txt"
_global_requirements_path = _utils.get_repo_path() / "roles" / "python" / "files" / "global_requirements.txt"


def get_ansible_choices() -> list[str]:
    return list(_utils.yaml_read(_ansible_manifest_path)["manifest"].keys())


def get_neovim_plugins_choices() -> list[str]:
    return list(_utils.lua_read(_neovim_manifest_path).keys())


def get_update_choices() -> list[str]:
    ansible_choices = get_ansible_choices()
    choices = ansible_choices + ["requirements"]
    choices.sort()
    return choices


def update(choice: str, dry_run: bool) -> None:
    if choice == "requirements":
        _logger.info("  Updating requirements.txt")
        _update_utils.update_requirements_txt(_requirements_path, dry_run=dry_run)

        _logger.info("")
        _logger.info("  Updating global_requirements.txt")
        _update_utils.update_requirements_txt(_global_requirements_path, dry_run=dry_run)
    elif choice == "neovim_plugins":
        for plugin in get_neovim_plugins_choices():
            _update_utils.update_neovim_plugin(_neovim_manifest_path, plugin, dry_run=dry_run)
    elif choice in get_ansible_choices():
        _update_utils.update_ansible_entry(_ansible_manifest_path, choice, dry_run=dry_run)
    else:
        assert False, f"Invalid choice: {choice}"
