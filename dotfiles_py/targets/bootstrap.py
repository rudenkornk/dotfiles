from pathlib import Path

from ..utils import ARTIFACTS_PATH, REPO_PATH, makelike, run_shell


def check_bootstrap(image: str) -> None:
    norm_image = image.replace(":", "_").replace("/", "_")

    @makelike(
        ARTIFACTS_PATH / norm_image / "bootstrap_control_node",
        REPO_PATH / "main.sh",
        REPO_PATH / "pyproject.toml",
        REPO_PATH / "uv.lock",
        REPO_PATH / "roles" / "manifest" / "vars" / "main.yaml",
        Path(__file__),
        auto_create=True,
    )
    def run_check_bootstrap(_: Path, sources: list[Path]) -> None:
        venv = ARTIFACTS_PATH / norm_image / "venv"
        venv.mkdir(parents=True, exist_ok=True)
        run_shell(
            [
                "podman",
                "run",
                "--rm",
                "--interactive",
                "--tty",
                "--volume",
                f"{REPO_PATH}:{REPO_PATH}",
                "--volume",
                f"{venv}:{REPO_PATH}/.venv",
                "--workdir",
                REPO_PATH,
                image,
                "bash",
                "-c",
                f"bash {sources[0]}",
            ],
        )

    run_check_bootstrap()
