from pathlib import Path

from ..utils import ARTIFACTS_PATH, REPO_PATH, makelike, run_shell


def check_bootstrap(image: str) -> None:
    norm_image = image.replace(":", "_").replace("/", "_")

    def run_check_bootstrap(_: Path, sources: list[Path]) -> None:
        run_shell(
            [
                "podman",
                "run",
                "--rm",
                "--interactive",
                "--tty",
                "--volume",
                f"{REPO_PATH}:{REPO_PATH}",
                "--workdir",
                REPO_PATH,
                image,
                "bash",
                "-c",
                f"bash {sources[0]}",
            ]
        )

    makelike(
        ARTIFACTS_PATH / norm_image / "bootstap_control_node",
        REPO_PATH / "main.sh",
        Path(__file__),
        auto_create=True,
    )(run_check_bootstrap)()
