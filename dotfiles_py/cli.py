import getpass
import logging
import secrets
import string
from pathlib import Path
from typing import Annotated

import click
import typer

from . import utils
from .targets import bootstrap, oh_my_posh
from .targets import config as config_target
from .targets import gnome as gnome_target
from .targets import hooks as hooks_target
from .targets import lint as lint_target
from .targets import roles_graph as roles_graph_target
from .targets import update as update_target

_logger = logging.getLogger(__name__)


app = typer.Typer(
    context_settings={"help_option_names": ["-h", "--help"]},
    help="Main script for spawning Ansible operations or managing dotfiles.",
)

loglevel_map = {
    "s": logging.DEBUG - 5,
    "spam": logging.DEBUG - 5,
    "d": logging.DEBUG,
    "debug": logging.DEBUG,
    "v": logging.INFO - 5,
    "verbose": logging.INFO - 5,
    "i": logging.INFO,
    "info": logging.INFO,
    "n": logging.WARNING - 5,
    "notice": logging.WARNING - 5,
    "w": logging.WARNING,
    "warning": logging.WARNING,
    "u": logging.ERROR - 5,
    "success": logging.ERROR - 5,
    "e": logging.ERROR,
    "error": logging.ERROR,
    "c": logging.CRITICAL,
    "critical": logging.CRITICAL,
}


@app.callback()
def setup_app(
    *,
    loglevel: Annotated[
        str,
        typer.Option(
            "-l",
            "--log-level",
            click_type=click.Choice(list(loglevel_map.keys())),
            help="Logging level.",
            case_sensitive=False,
        ),
    ] = "info",
) -> None:
    logging.getLogger().setLevel(loglevel_map[loglevel])
    utils.setup_logger()


@app.command()
@utils.typer_exit()
def config(
    *,
    host: Annotated[
        list[str],
        typer.Option(
            "-t",
            "--host",
            click_type=click.Choice(list(config_target.hosts().keys())),
            help="Hosts to configure. Note, that 'dotfiles_*' hostnames have a special meaning: "
            "they are actually podman containers, which are automatically started and used for testing purposes.",
            show_choices=True,
            case_sensitive=False,
        ),
    ] = ["localhost"],  # noqa: B006
    user: Annotated[
        str,
        typer.Option("-u", "--user", help="Target user to configure."),
    ] = getpass.getuser(),
    verify_unchanged: Annotated[
        bool,
        typer.Option("-v", "--verify-unchanged", help="This is an idempotency check. If anything was changed, fail."),
    ] = False,
    mode: Annotated[
        config_target.ConfigMode,
        typer.Option(
            "-m",
            "--mode",
            case_sensitive=False,
            help="Configuration mode. "
            "'bootstrap' will only install python and create target user on the host. "
            "'minimal' will install only the most critical parts like credentials and shell utils. "
            "'server' will skip all GUI tools. "
            "'full' will do full configuration.",
        ),
    ] = config_target.ConfigMode.FULL,
) -> None:
    """Configure systems."""
    config_target.config(hostnames=host, user=user, verify_unchanged=verify_unchanged, mode=mode)


@app.command()
@utils.typer_exit()
def check_bootstrap(
    *,
    image: Annotated[
        list[str],
        typer.Option(
            "-i",
            "--image",
            help="Target container image, where to check bootstrap.sh script.",
            click_type=click.Choice(config_target.images()),
        ),
    ] = [config_target.images()[0]],  # noqa: B006, B008
) -> None:
    """Check that main.sh bootstrapping script works correctly on different systems."""
    for image_ in image:
        bootstrap.check_bootstrap(image_)


@app.command()
@utils.typer_exit()
def lint(
    *,
    only: Annotated[
        list[str],
        typer.Option(
            "-o",
            "--only",
            help="Only lint these.",
            click_type=click.Choice(["all", *lint_target.lint_choices()]),
        ),
    ] = ["all"],  # noqa: B006
) -> None:
    """Lint code."""
    if "all" in only:
        args = dict.fromkeys(lint_target.lint_choices(), True)
    else:
        args = {arg: arg in only for arg in lint_target.lint_choices()}
    lint_target.lint_code(**args)


@app.command(name="format")
@utils.typer_exit()
def format_code() -> None:
    """Format code."""
    lint_target.format_code()


@app.command()
@utils.typer_exit()
def hooks() -> None:
    """Perform git hooks setup in repo."""
    hooks_target.hooks()


@app.command()
@utils.typer_exit()
def update(
    *,
    components: Annotated[
        list[str],
        typer.Option(
            "-c",
            "--components",
            help="Component to update.",
            click_type=click.Choice(["all", *update_target.get_update_choices()]),
        ),
    ] = ["all"],  # noqa: B006
    dry_run: Annotated[bool, typer.Option("-d", "--dry-run", help="Do not actually change versions.")] = False,
) -> None:
    """Update components versions."""
    if "all" in components:
        components = update_target.get_update_choices()

    update_target.update(components, dry_run=dry_run)


@app.command()
@utils.typer_exit()
def gnome() -> None:
    """Regenerate gnome settings."""
    gnome_target.gnome_config()


@app.command()
@utils.typer_exit()
def graph(
    *,
    silent: Annotated[bool, typer.Option("-s", "--silent", help="Do not open graph in image viewer.")] = False,
) -> None:
    """Generate ansible roles dependency graph."""
    roles_graph_target.generate_png(view=silent)


@app.command()
@utils.typer_exit()
def password(
    *,
    alphabet: Annotated[
        str,
        typer.Option("-a", "--alphabet", help="Password alphabet."),
    ] = string.ascii_lowercase,
    length: Annotated[int, typer.Option("-l", "--length", help="Password length.")] = 24,
    output: Annotated[
        Path,
        typer.Option("-o", "--output", help="Where to store generated password.", dir_okay=False, writable=True),
    ] = utils.ARTIFACTS_PATH / "password.txt",
    number: Annotated[int, typer.Option("-n", "--number", help="Number of passwords to generate.")] = 1,
) -> None:
    """Generate random password."""
    passwords_str = "".join(secrets.choice(alphabet) for _ in range(length * number))
    passwords = [passwords_str[i : i + length] + "\n" for i in range(0, len(passwords_str), length)]
    output.parent.mkdir(parents=True, exist_ok=True)
    output.touch(0o600)
    output.chmod(0o600)
    with output.open("a") as output_file:
        output_file.writelines(passwords)
    _logger.info(f"Password saved to the end of {output} file")


@app.command(name="omp-themes")
@utils.typer_exit()
def omp_themes(
    *,
    from_all: Annotated[
        bool, typer.Option("-a", "--from-all", help="Choose from all themes, not from already chosen candidates.")
    ] = False,
) -> None:
    """Choose oh-my-posh theme candidates."""
    oh_my_posh.choose(from_all=from_all)
