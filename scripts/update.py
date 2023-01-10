#!/usr/bin/env python3


import utils as _utils
import update_utils as _update_utils


def update_clipboard(dry_run: bool):
    vars_path = _utils.get_repo_path() / "roles/clipboard/vars/main.yaml"
    _update_utils.update_github_release_in_yaml(vars_path, "win32yank_url", "win32yank_lock", dry_run)


def update_cmake(dry_run: bool):
    vars_path = _utils.get_repo_path() / "roles/cpp/vars/main.yaml"
    _update_utils.update_github_release_in_yaml(vars_path, "cmake_url", "cmake_lock", dry_run)


def update_drawio(dry_run: bool):
    vars_path = _utils.get_repo_path() / "roles/latex/vars/main.yaml"
    _update_utils.update_github_release_in_yaml(vars_path, "drawio_url", "drawio_lock", dry_run)


def update_fonts(dry_run: bool):
    vars_path = _utils.get_repo_path() / "roles/fonts/vars/main.yaml"
    _update_utils.update_github_release_in_yaml(vars_path, "fira_code_url", "fira_code_lock", dry_run)


def update_neovim(dry_run: bool):
    vars_path = _utils.get_repo_path() / "roles/neovim/vars/main.yaml"
    _update_utils.update_github_release_in_yaml(vars_path, "neovim_url", "neovim_lock", dry_run)


def update_neovim_plugins(dry_run: bool):
    manifest_path = _utils.get_repo_path() / "roles/neovim/files/nvchad/plugins/manifest.lua"
    manifest = _utils.lua_read(manifest_path)
    for plugin, info in manifest.items():
        repo = "https://github.com/" + plugin
        locked = False
        if "lock" in info:
            locked = info["lock"]
        info["commit"] = _update_utils.update_commit(repo, from_commit=info["commit"], locked=locked)
        if not dry_run:
            _utils.lua_write(manifest_path, manifest)


def update_nvchad(dry_run: bool):
    vars_path = _utils.get_repo_path() / "roles/neovim/vars/main.yaml"
    _update_utils.update_commit_in_yaml(vars_path, "nvchad_url", "nvchad_version", "nvchad_lock", dry_run)


def update_python_modules(dry_run: bool):
    requirements_path = _utils.get_repo_path() / "requirements.txt"
    venv = _utils.get_build_path() / "venv"
    _update_utils.update_requirements_txt(requirements_path, venv, dry_run)


def update_shell_utils(dry_run: bool):
    vars_path = _utils.get_repo_path() / "roles/shell_utils/vars/main.yaml"
    _update_utils.update_commit_in_yaml(vars_path, "fzf_url", "fzf_commit", "fzf_lock", dry_run)
    _update_utils.update_github_release_in_yaml(vars_path, "bat_url", "bat_lock", dry_run)
    _update_utils.update_github_release_in_yaml(vars_path, "fd_url", "fd_lock", dry_run)
    _update_utils.update_github_release_in_yaml(vars_path, "rg_url", "rg_lock", dry_run)


def update_tpm(dry_run: bool):
    vars_path = _utils.get_repo_path() / "roles/tmux/vars/main.yaml"
    _update_utils.update_commit_in_yaml(vars_path, "tpm_url", "tpm_commit", "tpm_lock", dry_run)
