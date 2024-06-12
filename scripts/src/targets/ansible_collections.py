import platform as _platform
from pathlib import Path as _Path

from ..utils import ARTIFACTS_PATH as _ARTIFACTS_PATH
from ..utils import REPO_PATH as _REPO_PATH
from ..utils import makelike as _makelike
from ..utils import run_shell as _run_shell
from ..utils import yaml_read as _yaml_read
from . import bootstrap as _bootstrap

ANSIBLE_COLLECTIONS_PATH = _ARTIFACTS_PATH / _platform.node() / "ansible_collections"


# Target is user-specific since Ansible collections are installed for a specific user by default
# In some cases we need to perform a bootstrap twice from different users.
# This tweak ensures that the collections are installed for the user who runs the bootstrap
@_makelike(
    ANSIBLE_COLLECTIONS_PATH / "marker",
    _REPO_PATH / "roles" / "manifest" / "vars" / "ansible.yaml",
    _bootstrap.bootstrap,
    _Path(__file__),
    auto_create=True,
)
def ansible_collections(artifact: _Path, sources: list[_Path]) -> None:
    yaml, _ = _yaml_read(sources[0])
    assert isinstance(yaml, dict)
    manifest = yaml["manifest"]
    _run_shell(
        [
            "ansible-galaxy",
            "collection",
            "install",
            f"community.general:{manifest['ansible_community_general']['version']}",
        ],
        extra_env={"ANSIBLE_COLLECTIONS_PATH": ANSIBLE_COLLECTIONS_PATH},
    )
    _run_shell(
        [
            "ansible-galaxy",
            "collection",
            "install",
            f"ansible.posix:{manifest['ansible_posix']['version']}",
        ],
        extra_env={"ANSIBLE_COLLECTIONS_PATH": ANSIBLE_COLLECTIONS_PATH},
    )
    _run_shell(
        [
            "ansible-galaxy",
            "collection",
            "install",
            f"containers.podman:{manifest['ansible_containers_podman']['version']}",
        ],
        extra_env={"ANSIBLE_COLLECTIONS_PATH": ANSIBLE_COLLECTIONS_PATH},
    )
    artifact.touch()
