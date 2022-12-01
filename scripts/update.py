#!/usr/bin/env python3

import copy as _copy
import re as _re
import shutil as _shutil
import utils as _utils


def update_clipboard(dry_run: bool):
    vars_path = _utils.get_repo_path() / "roles/clipboard/vars/main.yaml"
    vars = _utils.yaml_read(vars_path)
    vars["win32yank_url"] = _utils.update_github_release(vars["win32yank_url"])["url"]
    if not dry_run:
        _utils.yaml_write(vars_path, vars)


def update_cmake(dry_run: bool):
    vars_path = _utils.get_repo_path() / "roles/cpp/vars/main.yaml"
    vars = _utils.yaml_read(vars_path)
    vars["cmake_url"] = _utils.update_github_release(vars["cmake_url"])["url"]
    if not dry_run:
        _utils.yaml_write(vars_path, vars)


def update_drawio(dry_run: bool):
    vars_path = _utils.get_repo_path() / "roles/latex/vars/main.yaml"
    vars = _utils.yaml_read(vars_path)
    vars["drawio_url"] = _utils.update_github_release(vars["drawio_url"])["url"]
    if not dry_run:
        _utils.yaml_write(vars_path, vars)


def update_fonts(dry_run: bool):
    vars_path = _utils.get_repo_path() / "roles/fonts/vars/main.yaml"
    vars = _utils.yaml_read(vars_path)
    vars["fira_code_url"] = _utils.update_github_release(vars["fira_code_url"])["url"]
    if not dry_run:
        _utils.yaml_write(vars_path, vars)


def update_neovim(dry_run: bool):
    vars_path = _utils.get_repo_path() / "roles/neovim/vars/main.yaml"
    vars = _utils.yaml_read(vars_path)
    vars["neovim_url"] = _utils.update_github_release(vars["neovim_url"])["url"]
    if not dry_run:
        _utils.yaml_write(vars_path, vars)


def update_neovim_plugins(dry_run: bool):
    manifest_path = _utils.get_repo_path() / "roles/neovim/files/nvchad/plugins/manifest.lua"
    manifest = _utils.lua_read(manifest_path)
    for plugin, info in manifest.items():
        repo = "https://github.com/" + plugin
        info["commit"] = _utils.update_repo(repo, from_commit=info["commit"])
        if not dry_run:
            _utils.lua_write(manifest_path, manifest)


def update_nvchad(dry_run: bool):
    vars_path = _utils.get_repo_path() / "roles/neovim/vars/main.yaml"
    vars = _utils.yaml_read(vars_path)
    vars["nvchad_version"] = _utils.update_repo(vars["nvchad_url"], from_commit=vars["nvchad_version"])
    if not dry_run:
        _utils.yaml_write(vars_path, vars)


def update_python_modules(dry_run: bool):
    tab = "  "
    logger = _utils.get_logger()
    requirements_path = _utils.get_repo_path() / "requirements.txt"
    venv = _utils.get_repo_path() / "__build__/venv"
    activate = f". {venv}/bin/activate && "
    new_venv = _utils.get_repo_path() / "__build__/new_venv"
    new_activate = f". {new_venv}/bin/activate && "
    new_requirements_path = new_venv / "requirements.txt"
    if new_venv.exists():
        _shutil.rmtree(new_venv)
    with open(requirements_path, "r") as f:
        requirements = f.readlines()

    core_packages = []
    core_requirements = []
    for requirement in requirements:
        if "added by pip freeze" in requirement:
            break
        requirement = requirement.strip()
        package = requirement.split("==")[0]
        core_packages.append(package)
        core_requirements.append(requirement)

    logger.info(f"{tab}Fetching new versions of core modules")
    new_core_requirements = _copy.deepcopy(core_requirements)
    outdated = _utils.run_shell(activate + "python3 -m pip list --outdated", capture_output=True)
    outdated_lines = outdated.stdout.splitlines()[2:]
    for line in outdated_lines:
        match = _re.match(r"(\S+)\s+(\S+)\s+(\S+)", line)
        package = match.group(1)
        new_version = match.group(3)
        if package in core_packages:
            index = core_packages.index(package)
            new_core_requirements[index] = f"{package}=={new_version}"
            logger.info(f"{tab * 2}{core_requirements[index]} -> {new_version}")

    if new_core_requirements == core_requirements:
        logger.info(f"{tab}Up to date")
        return

    logger.info(f"{tab}Creating temporary venv")
    _utils.run_shell(f"python3 -m venv {new_venv}", capture_output=True)
    with open(new_requirements_path, "w") as f:
        f.write("\n".join(new_core_requirements))

    logger.info(f"{tab}Installing new requirements")
    _utils.run_shell(new_activate + f"python3 -m pip install -r {new_requirements_path}", capture_output=True)

    logger.info(f"{tab}Capturing full requirements list")
    updated = _utils.run_shell(new_activate + f"python3 -m pip freeze -r {new_requirements_path}", capture_output=True)
    if not dry_run:
        with open(requirements_path, "w") as f:
            f.write(updated.stdout)
    logger.info(f"{tab}Done")
    return


def update_shell_utils(dry_run: bool):
    vars_path = _utils.get_repo_path() / "roles/shell_utils/vars/main.yaml"
    vars = _utils.yaml_read(vars_path)
    vars["fzf_commit"] = _utils.update_repo(vars["fzf_url"], from_commit=vars["fzf_commit"])
    if not dry_run:
        _utils.yaml_write(vars_path, vars)
    vars["rg_url"] = _utils.update_github_release(vars["rg_url"])["url"]
    if not dry_run:
        _utils.yaml_write(vars_path, vars)
    vars["bat_url"] = _utils.update_github_release(vars["bat_url"])["url"]
    if not dry_run:
        _utils.yaml_write(vars_path, vars)
    vars["fd_url"] = _utils.update_github_release(vars["fd_url"])["url"]
    if not dry_run:
        _utils.yaml_write(vars_path, vars)


def update_tpm(dry_run: bool):
    vars_path = _utils.get_repo_path() / "roles/tmux/vars/main.yaml"
    vars = _utils.yaml_read(vars_path)
    vars["tpm_commit"] = _utils.update_repo(vars["tpm_url"], from_commit=vars["tpm_commit"])
    if not dry_run:
        _utils.yaml_write(vars_path, vars)
