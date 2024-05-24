import platform as _platform
from pathlib import Path as _Path

from ..utils import ARTIFACTS_PATH as _ARTIFACTS_PATH
from ..utils import REPO_PATH as _REPO_PATH
from ..utils import makelike as _makelike
from ..utils import run_shell as _run_shell


@_makelike(
    _ARTIFACTS_PATH / _platform.node() / "bootstap_control_node",
    _REPO_PATH / "bootstrap.sh",
    _Path(__file__),
    auto_create=True,
)
def bootstrap(_: _Path, sources: list[_Path]) -> None:
    _run_shell(["bash", sources[0]])


def check_bootstrap(image: str) -> None:
    bootstrap()

    norm_image = image.replace(":", "_").replace("/", "_")

    def run_check_bootstrap(_: _Path, sources: list[_Path]) -> None:
        _run_shell(
            [
                "podman",
                "run",
                "--rm",
                "--interactive",
                "--tty",
                "--volume",
                f"{_REPO_PATH}:{_REPO_PATH}",
                "--workdir",
                _REPO_PATH,
                image,
                "bash",
                "-c",
                f"bash {sources[0]}",
            ]
        )

    _makelike(
        _ARTIFACTS_PATH / norm_image / "bootstap_control_node",
        _REPO_PATH / "bootstrap.sh",
        _Path(__file__),
        bootstrap,
        auto_create=True,
    )(run_check_bootstrap)()
