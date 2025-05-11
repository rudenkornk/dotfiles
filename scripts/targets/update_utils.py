import logging
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Any
from urllib.parse import urlparse

import git
import requests
from pydriller import Repository  # type: ignore
from semver import Version

from .. import utils

_logger = logging.getLogger(__name__)


def update_commit(origin: str, from_commit: str, locked: bool) -> str:
    num_new_commits = 0
    last_hash = ""
    max_log = 5
    hash_len = 7
    tab = "  "
    locked_msg = " (version is locked)" if locked else ""
    _logger.info(tab + f"Updating {origin}{locked_msg}")
    if locked:
        return from_commit

    logging.getLogger("pydriller").setLevel(logging.WARNING)

    for commit in Repository(origin, from_commit=from_commit, order="reverse").traverse_commits():
        if num_new_commits == 0:
            last_hash = commit.hash

        if commit.hash == from_commit:
            break

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

    assert last_hash
    return last_hash


def update_tag(origin: str, from_tag: str, locked: bool) -> str:
    tab = "  "
    locked_msg = " (version is locked)" if locked else ""
    _logger.info(tab + f"Updating {origin}{locked_msg}")
    if locked:
        return from_tag

    repo_normalized = re.sub(r"[^0-9a-zA-Z_\.]+", "_", origin)
    repo_path = utils.ARTIFACTS_PATH / "tmp" / repo_normalized
    repo = git.Repo.init(repo_path)
    for remote in repo.remotes:
        remote.remove(repo, remote.name)
    remote = repo.create_remote("origin", origin)
    remote.fetch()

    current_semver = Version.parse(from_tag)
    chosen_tag = from_tag

    for tag_obj in sorted(repo.tags, key=lambda t: t.commit.committed_datetime, reverse=True):
        tag = tag_obj.name
        try:
            semver = Version.parse(tag)
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


@dataclass
class GitHubTagInfo:
    tag: str
    version: str
    semver: Version | None

    def __init__(self, tag: str):
        self.tag = tag
        self.version = tag
        self.semver = None
        tag_parsed = re.search(r"v?(.*)", tag)
        if tag_parsed:
            self.version = tag_parsed.group(1)
        try:
            semver = Version.parse(self.version)
            self.semver = semver
        except ValueError:
            pass


@dataclass
class GitHubReleaseInfo:
    prefix: str
    repo: str
    path: str
    ti: GitHubTagInfo
    binary: str
    url: str

    def __init__(self, url: str):
        parsed_url = re.match(
            r"(?P<prefix>https?://github.com)/"
            r"(?P<repo>[^/]+/[^/]+)/releases/download/(?P<tag_info>[^/]+)/(?P<binary>.*)",
            url,
        )
        assert parsed_url is not None
        self.prefix = parsed_url.group("prefix")
        self.repo = parsed_url.group("repo")
        self.path = "releases/download"
        self.ti = GitHubTagInfo(parsed_url.group("tag_info"))
        self.binary = parsed_url.group("binary")
        self.url = url


def _requests_try_get(url: str) -> dict[str, Any] | list[Any] | None:
    @utils.retry(delay=10)
    def _get() -> requests.Response:
        response = requests.get(url, timeout=15)
        response.raise_for_status()
        return response

    try:
        ret = _get().json()
        assert isinstance(ret, (dict, list))
        return ret
    except requests.exceptions.HTTPError as e:
        _logger.warning("Cannot get response from url")
        _logger.warning(f"URL: {url}")
        _logger.warning(f"Status: {e.response.status_code}")
        _logger.warning(f"Error: {e}")
        return None


# pylint: disable-next=too-many-statements
def _update_github_release(url: str, locked: bool) -> str:
    tab = "  "
    cri = GitHubReleaseInfo(url)
    releases_url = f"https://github.com/{cri.repo}/releases"
    request_url = f"https://api.github.com/repos/{cri.repo}/releases"
    _logger.info(tab + f"Updating {releases_url}")
    if locked:
        _logger.info(f"{2 * tab}{cri.ti.tag} -- return (version is locked)")
        return url

    cmp_semver = cri.ti.semver is not None

    releases = _requests_try_get(request_url)
    if not releases:
        return url
    assert isinstance(releases, list)
    chosen_tag = cri.ti.tag
    chosen_version = cri.ti.version

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
            # pylint: disable-next=no-else-break
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


def _materialize_templated_url(url: str) -> str:
    dummy_map = {
        "{{ ansible_architecture }}": "x86_64",
        "{{ ansible_distribution }}": "Ubuntu",
        "{{ deb_arch }}": "amd64",
        "{{ pack_arch }}": "amd64",
        "{{ pack }}": "deb",
    }
    for key, value in dummy_map.items():
        url = url.replace(key, value)
    return url


def _ephemerize_url(url: str) -> str:
    dummy_map = {
        "x86_64": "{{ ansible_architecture }}",
        "Ubuntu": "{{ ansible_distribution }}",
        "amd64": "{{ pack_arch }}" if url.endswith(".deb") else "{{ deb_arch }}",
    }

    if url.endswith(".deb"):
        url = url[:-3] + "{{ pack }}"

    for key, value in dummy_map.items():
        url = url.replace(key, value)
    return url


def update_github_release(url: str, locked: bool) -> str:
    url = _materialize_templated_url(url)
    url = _update_github_release(url, locked)
    url = _ephemerize_url(url)
    return url


def update_neovim_plugin(neovim_manifest_path: Path, plugin: str, dry_run: bool) -> None:
    manifest = utils.lua_read(neovim_manifest_path)
    info = manifest[plugin]
    repo = "https://github.com/" + plugin
    locked = info.get("lock", False)
    info["commit"] = update_commit(repo, from_commit=info["commit"], locked=locked)
    if not dry_run:
        utils.lua_write(neovim_manifest_path, manifest)


def get_ansible_entry_type(info: dict[str, Any]) -> str:
    url = info["url"]
    parsed_url = urlparse(url)
    if parsed_url.netloc == "github.com" and "version" not in info:
        return "github_release"
    if parsed_url.netloc == "github.com" and re.match(r"[a-zA-Z0-9]{40}", info["version"]):
        return "git_commit"
    if parsed_url.netloc == "github.com" and Version.is_valid(info["version"]):
        return "git_tag"
    if parsed_url.netloc == "github.com":
        return "unknown"
    return "unknown"


def update_ansible_entry(manifest_path: Path, entry: str, dry_run: bool) -> None:
    main_vars, yaml = utils.yaml_read(manifest_path)
    assert isinstance(main_vars, dict)

    manifest_pre = main_vars.get("manifest_pre", {})
    manifest = main_vars["manifest"]
    info = manifest[entry]

    locked = info.get("lock", False)
    entry_type = get_ansible_entry_type(info)
    if entry_type == "unknown":
        _logger.warning(f"Cannot update {entry} -- no update method available")
        return

    if entry_type == "git_tag":
        info["version"] = update_tag(info["url"], from_tag=info["version"], locked=locked)
    if entry_type == "git_commit":
        info["version"] = update_commit(info["url"], from_commit=info["version"], locked=locked)
    if entry_type == "github_release":
        if entry not in manifest_pre:
            # URL is simple-templated
            info["url"] = update_github_release(info["url"], locked=locked)
        else:
            # URL is complex-templated
            urls = manifest_pre[entry]
            for key, url in urls.items():
                urls[key] = update_github_release(url, locked=locked)

    if not dry_run:
        utils.yaml_write(manifest_path, main_vars, yaml)
