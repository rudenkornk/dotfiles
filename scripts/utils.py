#!/usr/bin/env python3

from pathlib import Path as _Path
from pydriller import Repository as _Repository
import logging as _logging
import luadata as _luadata
import os as _os
import re as _re
import requests as _requests
import semver as _semver
import subprocess as _subprocess
import sys as _sys
import time as _time
import yaml as _yaml


def get_repo_path():
    return (_Path(_sys.path[0]) / "..").resolve()


def get_logger():
    return _logging.getLogger("support")


def get_build_dir():
    return "__build__"


def get_build_path():
    return get_repo_path() / get_build_dir()


def run_shell(cmd, extra_env={}, extra_paths=[], capture_output=False):
    logger = get_logger()
    env = _os.environ.copy()
    env.update(extra_env)
    extra_paths_str = ":".join(list(map(lambda x: str(x), extra_paths)))
    env["PATH"] = extra_paths_str + (":" + env["PATH"]) if "PATH" in env else ""

    if not capture_output:
        logger.info("\n[RUNNING IN SHELL]:")
        logger.info(cmd + "\n")
    return _subprocess.run(cmd, env=env, check=True, capture_output=capture_output, text=True, shell=True)


def try_run(f, try_run_count=5, try_run_delay=5, *args, **kwargs):
    tab = "  "
    logger = get_logger()
    for i in range(try_run_count):
        try:
            return f(*args, **kwargs)
        except Exception:
            if i >= try_run_count - 1:
                raise
            logger.warning(f"{2 * tab}Function '{f.__name__}' failed. Retry {i + 1} of {try_run_count}...")
            _time.sleep(try_run_delay)


def lua_read(path: _Path):
    return _luadata.read(path, encoding="utf-8")


def lua_write(path: _Path, data):
    _luadata.write(path, data, encoding="utf-8", indent="  ", prefix="return ")


def yaml_read(path: _Path):
    with open(path, "r") as stream:
        return _yaml.safe_load(stream)


def yaml_write(path: _Path, data):
    with open(path, "w") as stream:
        return _yaml.safe_dump(data, stream=stream)


def update_title(title: str, dry_run: bool):
    logger = get_logger()
    title = title.replace("_", " ")
    suffix = " (dry run)" if dry_run else ""
    logger.info(f"Updating {title}{suffix}:")


def update_repo(repo: str, from_commit: str = None):
    counter = 0
    max_log = 5
    hash_len = 7
    tab = "  "
    last_hash = from_commit
    logger = get_logger()
    logger.info(tab + f"Updating {repo}")
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


def update_github_release(url: str):
    tab = "  "
    logger = get_logger()
    parsed = parse_github_release_url(url)
    prefix = parsed["prefix"]
    repo = parsed["repo"]
    dir = parsed["dir"]
    current_semver = _semver.VersionInfo.parse(parsed["version"])
    releases_url = f"https://github.com/{repo}/releases"
    request_url = f"https://api.github.com/repos/{repo}/releases"
    logger.info(tab + f"Updating {releases_url}")

    def requests_get():
        response = _requests.get(request_url)
        response.raise_for_status()
        return response

    try:
        response = try_run(requests_get, try_run_delay=10)
    except _requests.exceptions.HTTPError as e:
        if e.response.status_code == 403:
            logger.warning(f"{2 * tab}GitHub API rate limit exceeded. Skipping this repo.")
            logger.warning(str(e))
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
    return parse_github_release_url(new_url)
