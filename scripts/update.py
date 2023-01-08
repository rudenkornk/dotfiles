#!/usr/bin/env python3

from pathlib import Path as _Path
from pydriller import Repository as _Repository
import copy as _copy
import re as _re
import requests as _requests
import semver as _semver
import shutil as _shutil
import utils as _utils


def _update_repo(repo: str, from_commit: str, locked: bool):
    counter = 0
    max_log = 5
    hash_len = 7
    tab = "  "
    last_hash = from_commit
    logger = _utils.get_logger()
    locked_msg = " (version is locked)" if locked else ""
    logger.info(tab + f"Updating {repo}{locked_msg}")
    if locked:
        return from_commit
    for commit in _Repository(repo, from_commit=from_commit, order="reverse").traverse_commits():
        if from_commit is not None and from_commit == commit.hash:
            continue
        counter += 1
        if counter == 1:
            last_hash = commit.hash
        header = commit.msg.splitlines()[0]
        info = 2 * tab + commit.hash[:hash_len]
        breaking = "breaking" in commit.msg.lower()
        if breaking:
            info += " [POSSIBLY BREAKING]"
        info += " " + header
        if counter <= max_log or breaking:
            logger.info(info)
    if counter > max_log:
        logger.info(f"{tab * 2}...")
    if counter > 0:
        logger.info(f"{tab * 2}Total {counter} new commits.")
    return last_hash


def _parse_github_release_url(url: str):
    parsed_url = _re.search(r"(^.*?github.com)/([^/]+/[^/]+)/releases/download/([^/]+)/(.*)", url)
    prefix = parsed_url.group(1)
    repo = parsed_url.group(2)
    tag = parsed_url.group(3)
    binary = parsed_url.group(4)
    version = _re.search(r"v?(.*)", tag).group(1)
    return {
        "prefix": prefix,
        "repo": repo,
        "dir": "releases/download",
        "tag": tag,
        "binary": binary,
        "version": version,
        "url": url,
    }


def _parse_pip_entry(entry: str):
    entry = entry.strip()
    if entry.startswith("#"):
        return {
            "comment": entry,
            "entry": entry,
            "package": None,
            "version": None,
        }
    package = entry.split("==")[0].strip()
    version_comment = entry.split("==")[1].strip()
    version = version_comment.split("#")[0].strip()
    comment = " # " + version_comment.split("#")[1].strip() if "#" in version_comment else ""
    return {
        "comment": comment,
        "entry": entry,
        "package": package,
        "version": version,
    }


def _update_github_release(url: str, locked: bool):
    tab = "  "
    logger = _utils.get_logger()
    parsed = _parse_github_release_url(url)
    prefix = parsed["prefix"]
    repo = parsed["repo"]
    dir = parsed["dir"]
    current_tag = parsed["tag"]
    current_semver = _semver.VersionInfo.parse(parsed["version"])
    releases_url = f"https://github.com/{repo}/releases"
    request_url = f"https://api.github.com/repos/{repo}/releases"
    logger.info(tab + f"Updating {releases_url}")
    if locked:
        logger.info(f"{2 * tab}{current_tag} -- return (version is locked)")
        return url

    def requests_get():
        response = _requests.get(request_url)
        response.raise_for_status()
        return response

    try:
        response = _utils.try_run(requests_get, try_run_delay=10)
    except _requests.exceptions.HTTPError as e:
        if e.response.status_code == 403:
            logger.warning(f"{2 * tab}GitHub API rate limit exceeded. Skipping this repo.")
            logger.warning(2 * tab + str(e))
            return url
        raise
    releases = response.json()
    for release in releases:
        tag = release["tag_name"]
        version = _re.search(r"v?(.*)", tag).group(1)
        if release["prerelease"]:
            logger.info(f"{2 * tab}{tag} -- skipping (marked as prerelease)")
            continue
        if release["draft"]:
            logger.info(f"{2 * tab}{tag} -- skipping (marked as draft)")
            continue
        try:
            semver = _semver.VersionInfo.parse(version)
        except ValueError:
            logger.info(f"{2 * tab}{tag} -- skipping (could not parse as semver)")
            continue
        if current_semver == semver:
            logger.info(f"{2 * tab}{tag} -- return (reached current version)")
            chosen_tag = parsed["tag"]
            chosen_version = parsed["version"]
            break
        if current_semver > semver:
            logger.warning(f"{2 * tab}{tag} -- skipping and returning current (missed current version)")
            chosen_tag = parsed["tag"]
            chosen_version = parsed["version"]
            break
        if current_semver < semver:
            logger.info(f"{2 * tab}{tag} -- return (found latest version)")
            chosen_tag = tag
            chosen_version = version
            break
        assert False

    chosen_binary = parsed["binary"].replace(parsed["version"], chosen_version)
    new_url = f"{prefix}/{repo}/{dir}/{chosen_tag}/{chosen_binary}"
    return new_url


def _update_github_release_in_yaml(vars_path: _Path, url_var: str, lock_var: str, dry_run: bool):
    vars = _utils.yaml_read(vars_path)
    locked = False
    if lock_var in vars:
        locked = vars[lock_var]
    vars[url_var] = _update_github_release(vars[url_var], locked)
    if not dry_run:
        _utils.yaml_write(vars_path, vars)


def _update_repo_in_yaml(vars_path: _Path, repo_var: str, commit_var: str, lock_var: str, dry_run: bool):
    vars = _utils.yaml_read(vars_path)
    locked = False
    if lock_var in vars:
        locked = vars[lock_var]
    vars[commit_var] = _update_repo(vars[repo_var], from_commit=vars[commit_var], locked=locked)
    if not dry_run:
        _utils.yaml_write(vars_path, vars)


def update_clipboard(dry_run: bool):
    vars_path = _utils.get_repo_path() / "roles/clipboard/vars/main.yaml"
    _update_github_release_in_yaml(vars_path, "win32yank_url", "win32yank_lock", dry_run)


def update_cmake(dry_run: bool):
    vars_path = _utils.get_repo_path() / "roles/cpp/vars/main.yaml"
    _update_github_release_in_yaml(vars_path, "cmake_url", "cmake_lock", dry_run)


def update_drawio(dry_run: bool):
    vars_path = _utils.get_repo_path() / "roles/latex/vars/main.yaml"
    _update_github_release_in_yaml(vars_path, "drawio_url", "drawio_lock", dry_run)


def update_fonts(dry_run: bool):
    vars_path = _utils.get_repo_path() / "roles/fonts/vars/main.yaml"
    _update_github_release_in_yaml(vars_path, "fira_code_url", "fira_code_lock", dry_run)


def update_neovim(dry_run: bool):
    vars_path = _utils.get_repo_path() / "roles/neovim/vars/main.yaml"
    _update_github_release_in_yaml(vars_path, "neovim_url", "neovim_lock", dry_run)


def update_neovim_plugins(dry_run: bool):
    manifest_path = _utils.get_repo_path() / "roles/neovim/files/nvchad/plugins/manifest.lua"
    manifest = _utils.lua_read(manifest_path)
    for plugin, info in manifest.items():
        repo = "https://github.com/" + plugin
        locked = False
        if "lock" in info:
            locked = info["lock"]
        info["commit"] = _update_repo(repo, from_commit=info["commit"], locked=locked)
        if not dry_run:
            _utils.lua_write(manifest_path, manifest)


def update_nvchad(dry_run: bool):
    vars_path = _utils.get_repo_path() / "roles/neovim/vars/main.yaml"
    _update_repo_in_yaml(vars_path, "nvchad_url", "nvchad_version", "nvchad_lock", dry_run)


def update_python_modules(dry_run: bool):
    tab = "  "
    logger = _utils.get_logger()
    requirements_path = _utils.get_repo_path() / "requirements.txt"
    venv = _utils.get_build_path() / "venv"
    activate = f". {venv}/bin/activate && "
    new_venv = _utils.get_build_path() / "new_venv"
    new_activate = f". {new_venv}/bin/activate && "
    new_requirements_path = new_venv / "requirements.txt"
    if new_venv.exists():
        _shutil.rmtree(new_venv)
    with open(requirements_path, "r") as f:
        requirements = f.readlines()

    core_packages = []
    core_versions = []
    core_comments = []
    for requirement in requirements:
        if "added by pip freeze" in requirement:
            break
        entry = _parse_pip_entry(requirement)
        core_packages.append(entry["package"])
        core_versions.append(entry["version"])
        core_comments.append(entry["comment"])

    logger.info(f"{tab}Fetching new versions of core modules")
    new_core_versions = _copy.deepcopy(core_versions)
    outdated = _utils.run_shell(activate + "python3 -m pip list --outdated", capture_output=True)
    outdated_lines = outdated.stdout.splitlines()[2:]
    for line in outdated_lines:
        match = _re.match(r"(\S+)\s+(\S+)\s+(\S+)", line)
        package = match.group(1)
        new_version = match.group(3)
        if package in core_packages:
            index = core_packages.index(package)
            msg = ""
            if "lock" in core_comments[index]:
                msg = "-- skipping (version is locked)"
            else:
                new_core_versions[index] = new_version
            logger.info(f"{tab * 2}{package}=={core_versions[index]} -> {new_version} {msg}")

    logger.info(f"{tab}Creating temporary venv")
    _utils.run_shell(f"python3 -m venv {new_venv}", capture_output=True)
    with open(new_requirements_path, "w") as f:
        for i, package in enumerate(core_packages):
            f.write(f"{package}=={new_core_versions[i]}{core_comments[i]}\n")

    logger.info(f"{tab}Installing new requirements")
    _utils.run_shell(new_activate + f"python3 -m pip install -r {new_requirements_path}", capture_output=True)

    logger.info(f"{tab}Capturing full requirements list")
    updated = _utils.run_shell(new_activate + f"python3 -m pip freeze -r {new_requirements_path}", capture_output=True)
    new_requirements = updated.stdout.splitlines()
    new_req_str = ""
    for new_requirement in new_requirements:
        parsed_new_req = _parse_pip_entry(new_requirement)
        package = parsed_new_req["package"]
        comment = ""
        if package in core_packages:
            index = core_packages.index(package)
            comment = core_comments[index]
        new_req_str += f"{new_requirement}{comment}\n"
    if not dry_run:
        with open(requirements_path, "w") as f:
            f.write(new_req_str)
    logger.info(f"{tab}Done")
    return


def update_shell_utils(dry_run: bool):
    vars_path = _utils.get_repo_path() / "roles/shell_utils/vars/main.yaml"
    _update_repo_in_yaml(vars_path, "fzf_url", "fzf_commit", "fzf_lock", dry_run)
    _update_github_release_in_yaml(vars_path, "bat_url", "bat_lock", dry_run)
    _update_github_release_in_yaml(vars_path, "fd_url", "fd_lock", dry_run)
    _update_github_release_in_yaml(vars_path, "rg_url", "rg_lock", dry_run)


def update_tpm(dry_run: bool):
    vars_path = _utils.get_repo_path() / "roles/tmux/vars/main.yaml"
    _update_repo_in_yaml(vars_path, "tpm_url", "tpm_commit", "tpm_lock", dry_run)
