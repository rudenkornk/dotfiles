import platform
from pathlib import Path

from ..utils import ARTIFACTS_PATH, REPO_PATH, makelike, run_shell, yaml_read

ANSIBLE_COLLECTIONS_PATH = ARTIFACTS_PATH / platform.node() / "ansible_collections"


# Target is user-specific since Ansible collections are installed for a specific user by default
# In some cases we need to perform a bootstrap twice from different users.
# This tweak ensures that the collections are installed for the user who runs the bootstrap
@makelike(
    ANSIBLE_COLLECTIONS_PATH / "marker",
    REPO_PATH / "roles" / "manifest" / "vars" / "ansible.yaml",
    Path(__file__),
    auto_create=True,
)
def ansible_collections(artifact: Path, sources: list[Path]) -> None:
    yaml, _ = yaml_read(sources[0])
    if not isinstance(yaml, dict):
        msg = f"Expected a dictionary in {sources[0]}, got {type(yaml)}"
        raise TypeError(msg)

    manifest = yaml["manifest"]
    run_shell(
        [
            "ansible-galaxy",
            "collection",
            "install",
            f"community.general:{manifest['ansible_community_general']['version']}",
        ],
        extra_env={"ANSIBLE_COLLECTIONS_PATH": ANSIBLE_COLLECTIONS_PATH},
    )
    run_shell(
        [
            "ansible-galaxy",
            "collection",
            "install",
            f"ansible.posix:{manifest['ansible_posix']['version']}",
        ],
        extra_env={"ANSIBLE_COLLECTIONS_PATH": ANSIBLE_COLLECTIONS_PATH},
    )
    run_shell(
        [
            "ansible-galaxy",
            "collection",
            "install",
            f"containers.podman:{manifest['ansible_containers_podman']['version']}",
        ],
        extra_env={"ANSIBLE_COLLECTIONS_PATH": ANSIBLE_COLLECTIONS_PATH},
    )
    artifact.touch()
