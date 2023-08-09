#!/usr/bin/env python3

import copy as _copy
import logging as _logging
import re as _re
import shutil as _shutil
import subprocess as _subprocess
from dataclasses import dataclass as _dataclass
from pathlib import Path as _Path
from typing import Any as _Any

import git as _git
import requests as _requests
import semver as _semver
from pydriller import Repository as _Repository  # type: ignore

from . import utils as _utils

_logger = _logging.getLogger(__name__)


def update_commit(origin: str, from_commit: str, locked: bool) -> str:
    num_new_commits = 0
    max_log = 5
    hash_len = 7
    tab = "  "
    locked_msg = " (version is locked)" if locked else ""
    _logger.info(tab + f"Updating {origin}{locked_msg}")
    if locked:
        return from_commit
    for commit in _Repository(origin, from_commit=from_commit, order="reverse").traverse_commits():
        if num_new_commits == 0:
            last_hash: str = commit.hash
        if from_commit is not None and from_commit == commit.hash:
            continue
        num_new_commits += 1
        header = commit.msg.splitlines()[0]
        info = 2 * tab + commit.hash[:hash_len]
        breaking = "breaking" in commit.msg.lower()
        if breaking:
            info += " [POSSIBLY BREAKING]"
        info += " " + header
        if num_new_commits <= max_log or breaking:
            _logger.info(info)
    if num_new_commits > max_log:
        _logger.info(f"{tab * 2}...")
    if num_new_commits > 0:
        _logger.info(f"{tab * 2}Total {num_new_commits} new commits.")
    return last_hash


def update_tag(origin: str, from_tag: str, locked: bool) -> str:
    tab = "  "
    locked_msg = " (version is locked)" if locked else ""
    _logger.info(tab + f"Updating {origin}{locked_msg}")
    if locked:
        return from_tag

    repo_normalized = _re.sub(r"[^0-9a-zA-Z_\.]+", "_", origin)
    repo_path = _utils.get_build_path() / "tmp" / repo_normalized
    repo = _git.Repo.init(repo_path)
    for remote in repo.remotes:
        remote.remove(repo, remote.name)
    remote = repo.create_remote("origin", origin)
    remote.fetch()

    current_semver = _semver.VersionInfo.parse(from_tag)

    for tag_obj in sorted(repo.tags, key=lambda t: t.commit.committed_datetime, reverse=True):
        tag = tag_obj.name
        try:
            semver = _semver.VersionInfo.parse(tag)
        except ValueError:
            _logger.info(f"{2 * tab}{tag} -- skipping (could not parse as semver)")
            continue
        if semver == current_semver:
            _logger.info(f"{2 * tab}{tag} == {from_tag} -- return (reached current version)")
            chosen_tag = from_tag
            break
        if semver.prerelease is not None:
            _logger.info(f"{2 * tab}{tag} -- skipping (marked as prerelease)")
            continue
        if semver.build is not None:
            _logger.info(f"{2 * tab}{tag} -- skipping (marked as intermediate build)")
            continue
        if semver < current_semver:
            _logger.warning(f"{2 * tab}{tag} < {from_tag} -- skipping and returning current (missed current version)")
            chosen_tag = from_tag
            break
        if semver > current_semver:
            breaking_note = ""
            if semver.major > current_semver.major:
                breaking_note = " [POSSIBLY BREAKING]"
            _logger.info(f"{2 * tab}{tag} > {from_tag}{breaking_note} -- return (found latest version)")
            chosen_tag = tag
            break
        assert False
    return chosen_tag


@_dataclass
class GitHubTagInfo:
    tag: str
    version: str
    semver: _semver.VersionInfo | None

    def __init__(self, tag: str):
        self.tag = tag
        self.version = tag
        self.semver = None
        tag_parsed = _re.search(r"v?(.*)", tag)
        if tag_parsed:
            self.version = tag_parsed.group(1)
        try:
            semver = _semver.VersionInfo.parse(self.version)
            self.semver = semver
        except ValueError:
            pass


@_dataclass
class GitHubReleaseInfo:
    prefix: str
    repo: str
    path: str
    ti: GitHubTagInfo
    binary: str
    url: str

    def __init__(self, url: str):
        parsed_url = _re.search(r"(^.*?github.com)/([^/]+/[^/]+)/releases/download/([^/]+)/(.*)", url)
        assert parsed_url is not None
        self.prefix = parsed_url.group(1)
        self.repo = parsed_url.group(2)
        self.path = "releases/download"
        self.ti = GitHubTagInfo(parsed_url.group(3))
        self.binary = parsed_url.group(4)
        self.url = url


def update_github_release(url: str, locked: bool) -> str:
    tab = "  "
    cri = GitHubReleaseInfo(url)
    releases_url = f"https://github.com/{cri.repo}/releases"
    request_url = f"https://api.github.com/repos/{cri.repo}/releases"
    _logger.info(tab + f"Updating {releases_url}")
    if locked:
        _logger.info(f"{2 * tab}{cri.ti.tag} -- return (version is locked)")
        return url

    cmp_semver = cri.ti.semver is not None

    @_utils.retry(delay=10)
    def requests_get() -> _requests.Response:
        response = _requests.get(request_url, timeout=15)
        response.raise_for_status()
        return response

    try:
        response = requests_get()
    except _requests.exceptions.HTTPError as e:
        if e.response.status_code == 403:
            _logger.warning(f"{2 * tab}GitHub API rate limit exceeded. Skipping this repo.")
            _logger.warning(2 * tab + str(e))
            return url
        raise
    releases = response.json()
    for release in releases:
        ti = GitHubTagInfo(release["tag_name"])
        if release["prerelease"]:
            _logger.info(f"{2 * tab}{ti.tag} -- skipping (marked as prerelease)")
            continue
        if release["draft"]:
            _logger.info(f"{2 * tab}{ti.tag} -- skipping (marked as draft)")
            continue
        if cmp_semver and not ti.semver:
            _logger.info(f"{2 * tab}{ti.tag} -- skipping (could not parse as semver)")
            continue
        if not cmp_semver:
            if ti.tag != cri.ti.tag:
                _logger.info(f"{2 * tab}{ti.tag} != {cri.ti.tag} -- return (found latest version)")
                chosen_tag = ti.tag
                chosen_version = ti.version
                break
            else:
                _logger.info(f"{2 * tab}{ti.tag} == {cri.ti.tag} -- return (reached current version)")
                chosen_tag = cri.ti.tag
                chosen_version = cri.ti.version
                break

        assert ti.semver is not None
        assert cri.ti.semver is not None
        if ti.semver == cri.ti.semver:
            _logger.info(f"{2 * tab}{ti.tag} == {cri.ti.tag} -- return (reached current version)")
            chosen_tag = cri.ti.tag
            chosen_version = cri.ti.version
            break
        if ti.semver < cri.ti.semver:
            _logger.warning(
                f"{2 * tab}{ti.tag} < {cri.ti.tag} -- skipping and returning current (missed current version)"
            )
            chosen_tag = cri.ti.tag
            chosen_version = cri.ti.version
            break
        if ti.semver.prerelease is not None:
            _logger.info(f"{2 * tab}{ti.tag} -- skipping (marked as prerelease)")
            continue
        if ti.semver > cri.ti.semver:
            breaking_note = ""
            if ti.semver.major > cri.ti.semver.major:
                breaking_note = " [POSSIBLY BREAKING]"
            _logger.info(f"{2 * tab}{ti.tag} > {cri.ti.tag}{breaking_note} -- return (found latest version)")
            chosen_tag = ti.tag
            chosen_version = ti.version
            break
        assert False

    chosen_binary = cri.binary.replace(cri.ti.version, chosen_version)
    new_url = f"{cri.prefix}/{cri.repo}/{cri.path}/{chosen_tag}/{chosen_binary}"
    return new_url


def parse_pip_entry(entry: str) -> dict[str, str | None]:
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


def update_requirements_txt(requirements_path: _Path, venv: _Path, dry_run: bool) -> None:
    tab = "  "
    activate = f". {venv}/bin/activate && "
    new_venv = _utils.get_tmp_path() / "new_venv"
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
        entry = parse_pip_entry(requirement)
        if entry["version"] is None or entry["package"] is None:
            continue
        assert entry["comment"] is not None
        core_packages.append(entry["package"])
        core_versions.append(entry["version"])
        core_comments.append(entry["comment"])

    _logger.info(f"{tab}Fetching new versions of core modules")
    new_core_versions = _copy.deepcopy(core_versions)
    outdated = _subprocess.run(
        activate + "python3 -m pip list --outdated",
        capture_output=True,
        text=True,
        shell=True,
        executable="bash",
        check=True,
    )
    outdated = _utils.run_shell(activate + "python3 -m pip list --outdated", capture_output=True, suppress_cmd_log=True)
    outdated_lines = outdated.stdout.splitlines()[2:]
    for line in outdated_lines:
        match = _re.match(r"(\S+)\s+(\S+)\s+(\S+)", line)
        assert match is not None
        package = match.group(1)
        new_version = match.group(3)
        if package in core_packages:
            index = core_packages.index(package)
            msg = ""
            if "lock" in core_comments[index]:
                msg = "-- skipping (version is locked)"
            else:
                new_core_versions[index] = new_version
            _logger.info(f"{tab * 2}{package}=={core_versions[index]} -> {new_version} {msg}")

    _logger.info(f"{tab}Creating temporary venv")
    _utils.run_shell(f"python3 -m venv {new_venv}", capture_output=True, suppress_cmd_log=True)
    with open(new_requirements_path, "w") as f:
        for i, package in enumerate(core_packages):
            f.write(f"{package}=={new_core_versions[i]}{core_comments[i]}\n")

    _logger.info(f"{tab}Installing new requirements")
    _utils.run_shell(
        new_activate + f"python3 -m pip install -r {new_requirements_path}", capture_output=True, suppress_cmd_log=True
    )

    _logger.info(f"{tab}Capturing full requirements list")
    updated = _utils.run_shell(
        new_activate + f"python3 -m pip freeze -r {new_requirements_path}", capture_output=True, suppress_cmd_log=True
    )
    new_requirements = updated.stdout.splitlines()
    for i, new_requirement in enumerate(new_requirements):
        parsed_new_req = parse_pip_entry(new_requirement)
        package = parsed_new_req["package"]
        comment = ""
        if package in core_packages:
            index = core_packages.index(package)
            comment = core_comments[index]
        new_requirements[i] = f"{new_requirement}{comment}\n"

    with open(new_requirements_path, "w") as f:
        f.writelines(new_requirements)
    if not dry_run:
        with open(requirements_path, "w") as f:
            f.writelines(new_requirements)
    _logger.info(f"{tab}Done")


def update_neovim_plugin(neovim_manifest_path: _Path, plugin: str, dry_run: bool) -> None:
    manifest = _utils.lua_read(neovim_manifest_path)
    info = manifest[plugin]
    repo = "https://github.com/" + plugin
    locked = info.get("lock", False)
    info["commit"] = update_commit(repo, from_commit=info["commit"], locked=locked)
    if not dry_run:
        _utils.lua_write(neovim_manifest_path, manifest)


def get_ansible_entry_type(info: dict[str, _Any]) -> str:
    if "version" not in info:
        return "github_release"
    version = info["version"]
    try:
        _semver.VersionInfo.parse(version)
        return "git_tag"
    except ValueError:
        return "git_commit"
    assert False


def update_ansible_entry(manifest_path: _Path, entry: str, dry_run: bool) -> None:
    main_vars = _utils.yaml_read(manifest_path)
    manifest = main_vars["manifest"]
    info = manifest[entry]
    url = info["url"]
    locked = info.get("lock", False)
    entry_type = get_ansible_entry_type(info)
    if entry_type == "git_tag":
        info["version"] = update_tag(url, from_tag=info["version"], locked=locked)
    if entry_type == "git_commit":
        info["version"] = update_commit(url, from_commit=info["version"], locked=locked)
    if entry_type == "github_release":
        info["url"] = update_github_release(url, locked=locked)
    if not dry_run:
        _utils.yaml_write(manifest_path, main_vars)
