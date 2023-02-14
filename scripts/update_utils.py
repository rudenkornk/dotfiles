#!/usr/bin/env python3

from pathlib import Path as _Path
from pydriller import Repository as _Repository
import copy as _copy
import git as _git
import re as _re
import requests as _requests
import semver as _semver
import shutil as _shutil
import utils as _utils


def update_commit(origin: str, from_commit: str, locked: bool):
    num_new_commits = 0
    max_log = 5
    hash_len = 7
    tab = "  "
    logger = _utils.get_logger()
    locked_msg = " (version is locked)" if locked else ""
    logger.info(tab + f"Updating {origin}{locked_msg}")
    if locked:
        return from_commit
    for commit in _Repository(origin, from_commit=from_commit, order="reverse").traverse_commits():
        if num_new_commits == 0:
            last_hash = commit.hash
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
            logger.info(info)
    if num_new_commits > max_log:
        logger.info(f"{tab * 2}...")
    if num_new_commits > 0:
        logger.info(f"{tab * 2}Total {num_new_commits} new commits.")
    return last_hash


def update_tag(origin: str, from_tag: str, locked: bool):
    tab = "  "
    logger = _utils.get_logger()
    locked_msg = " (version is locked)" if locked else ""
    logger.info(tab + f"Updating {origin}{locked_msg}")
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
            logger.info(f"{2 * tab}{tag} -- skipping (could not parse as semver)")
            continue
        if semver == current_semver:
            logger.info(f"{2 * tab}{tag} == {from_tag} -- return (reached current version)")
            chosen_tag = from_tag
            break
        if semver.prerelease is not None:
            logger.info(f"{2 * tab}{tag} -- skipping (marked as prerelease)")
            continue
        if semver.build is not None:
            logger.info(f"{2 * tab}{tag} -- skipping (marked as intermediate build)")
            continue
        if semver < current_semver:
            logger.warning(f"{2 * tab}{tag} < {from_tag} -- skipping and returning current (missed current version)")
            chosen_tag = from_tag
            break
        if semver > current_semver:
            breaking_note = ""
            if semver.major > current_semver.major:
                breaking_note = " [POSSIBLY BREAKING]"
            logger.info(f"{2 * tab}{tag} > {from_tag}{breaking_note} -- return (found latest version)")
            chosen_tag = tag
            break
        assert False
    return chosen_tag


def parse_github_release_url(url: str):
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


def parse_pip_entry(entry: str):
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


def update_github_release(url: str, locked: bool):
    tab = "  "
    logger = _utils.get_logger()
    parsed = parse_github_release_url(url)
    prefix = parsed["prefix"]
    repo = parsed["repo"]
    dir = parsed["dir"]
    current_tag = parsed["tag"]
    current_version = parsed["version"]
    current_semver = _semver.VersionInfo.parse(current_version)
    releases_url = f"https://github.com/{repo}/releases"
    request_url = f"https://api.github.com/repos/{repo}/releases"
    logger.info(tab + f"Updating {releases_url}")
    if locked:
        logger.info(f"{2 * tab}{current_tag} -- return (version is locked)")
        return url

    @_utils.retry(delay=10)
    def requests_get():
        response = _requests.get(request_url)
        response.raise_for_status()
        return response

    try:
        response = requests_get()
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
        if semver == current_semver:
            logger.info(f"{2 * tab}{tag} == {current_tag} -- return (reached current version)")
            chosen_tag = current_tag
            chosen_version = current_version
            break
        if semver < current_semver:
            logger.warning(f"{2 * tab}{tag} < {current_tag} -- skipping and returning current (missed current version)")
            chosen_tag = current_tag
            chosen_version = current_version
            break
        if semver.prerelease is not None:
            logger.info(f"{2 * tab}{tag} -- skipping (marked as prerelease)")
            continue
        if semver > current_semver:
            breaking_note = ""
            if semver.major > current_semver.major:
                breaking_note = " [POSSIBLY BREAKING]"
            logger.info(f"{2 * tab}{tag} > {current_tag}{breaking_note} -- return (found latest version)")
            chosen_tag = tag
            chosen_version = version
            break
        assert False

    chosen_binary = parsed["binary"].replace(current_version, chosen_version)
    new_url = f"{prefix}/{repo}/{dir}/{chosen_tag}/{chosen_binary}"
    return new_url


def update_github_release_in_yaml(vars_path: _Path, url_var: str, lock_var: str, dry_run: bool):
    vars = _utils.yaml_read(vars_path)
    locked = False
    if lock_var in vars:
        locked = vars[lock_var]
    vars[url_var] = update_github_release(vars[url_var], locked)
    if not dry_run:
        _utils.yaml_write(vars_path, vars)


def update_commit_in_yaml(vars_path: _Path, repo_var: str, commit_var: str, lock_var: str, dry_run: bool):
    vars = _utils.yaml_read(vars_path)
    locked = False
    if lock_var in vars:
        locked = vars[lock_var]
    vars[commit_var] = update_commit(vars[repo_var], from_commit=vars[commit_var], locked=locked)
    if not dry_run:
        _utils.yaml_write(vars_path, vars)


def update_tag_in_yaml(vars_path: _Path, repo_var: str, tag_var: str, lock_var: str, dry_run: bool):
    vars = _utils.yaml_read(vars_path)
    locked = False
    if lock_var in vars:
        locked = vars[lock_var]
    vars[tag_var] = update_tag(vars[repo_var], from_tag=vars[tag_var], locked=locked)
    if not dry_run:
        _utils.yaml_write(vars_path, vars)


def update_requirements_txt(requirements_path: _Path, venv: _Path, dry_run: bool):
    tab = "  "
    logger = _utils.get_logger()
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
    logger.info(f"{tab}Done")
    return
