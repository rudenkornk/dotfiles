import getpass
import logging
import secrets
import string
from pathlib import Path

import click
from click_help_colors import HelpColorsGroup

from . import utils
from .targets import bootstrap
from .targets import config as config_target
from .targets import gnome as gnome_target
from .targets import hooks as hooks_target
from .targets import lint as lint_target
from .targets import roles_graph as roles_graph_target
from .targets import update as update_target

_logger = logging.getLogger(__name__)


@click.group(
    help="main script for spawning Ansible operations or managing dotfiles.",
    context_settings={"help_option_names": ["-h", "--help"], "show_default": True},
    cls=HelpColorsGroup,
    help_headers_color="yellow",
    help_options_color="green",
)
@click.option(
    "-l",
    "--log-level",
    type=click.Choice(["debug", "info", "warning", "error", "critical", "d", "i", "w", "e", "c"], case_sensitive=False),
    default="info",
    help="Logging level.",
)
def cli(log_level: str) -> None:
    level_map = {
        "debug": logging.DEBUG,
        "info": logging.INFO,
        "warning": logging.WARNING,
        "error": logging.ERROR,
        "d": logging.DEBUG,
        "i": logging.INFO,
        "w": logging.WARNING,
        "e": logging.ERROR,
        "c": logging.CRITICAL,
    }
    logging.getLogger().setLevel(level_map[log_level])


@cli.command(help="Configure systems.")
@click.option(
    "-t",
    "--host",
    type=click.Choice(list(config_target.hosts().keys())),
    default=["localhost"],
    help="Hosts to configure. Note, that 'dotfiles_*' hostnames have a special meaning: "
    "they are actually a podman containers, which are automatically started and used for testing purposes.",
    multiple=True,
)
@click.option(
    "-u",
    "--user",
    type=str,
    default=getpass.getuser(),
    help="Target user to configure.",
)
@click.option(
    "-v", "--verify-unchanged", is_flag=True, help="This is an idempotency check. If anything was changed, fail."
)
@click.option(
    "-m",
    "--mode",
    type=click.Choice(config_target.ConfigMode.values()),
    default="full",
    help="Configuration mode. "
    "'bootstrap' will only install python and create target user on the host. "
    "'minimal' will install only the most critical parts like credentials and shell utils. "
    "'server' will skip all GUI tools. "
    "'full' will do full configuration.",
)
def config(host: list[str], user: str, verify_unchanged: bool, mode: str) -> None:
    mode_enum = config_target.ConfigMode[mode.upper()]
    config_target.config(hostnames=host, user=user, verify_unchanged=verify_unchanged, mode=mode_enum)


@cli.command(help="Check that main.sh bootstrapping script works correctly on different systems.")
@click.option(
    "-i",
    "--image",
    type=click.Choice(config_target.images()),
    default=[config_target.images()[0]],
    help="Target container image, where to check bootstrap.sh script.",
    multiple=True,
)
def check_bootstrap(image: list[str]) -> None:
    for image_ in image:
        bootstrap.check_bootstrap(image_)


@cli.command(help="Lint code.")
@click.option("-a", "--exclude-ansible", is_flag=True, help="Run only Ansible linters.")
@click.option("-p", "--exclude-python", is_flag=True, help="Run only Python linters.")
@click.option("-s", "--exclude-secrets", is_flag=True, help="Run only secrets linters.")
def lint(exclude_ansible: bool, exclude_python: bool, exclude_secrets: bool) -> None:
    lint_target.lint_code(ansible=not exclude_ansible, python=not exclude_python, secrets=not exclude_secrets)


@cli.command(name="format", help="Format code.")
def format_code() -> None:
    lint_target.format_code()


@cli.command(help="Setup repo git hooks.")
def hooks() -> None:
    hooks_target.hooks()


@cli.command(help="Update components versions.")
@click.option(
    "-c",
    "--components",
    type=click.Choice(["all"] + update_target.get_update_choices()),
    default=["all"],
    help="Component to update.",
    multiple=True,
)
@click.option("-d", "--dry-run", is_flag=True, help="Do not actually change versions.")
def update(components: list[str], dry_run: bool) -> None:
    if "all" in components:
        components = update_target.get_update_choices()

    update_target.update(components, dry_run)


@cli.command(help="Regenerate gnome settings")
def gnome() -> None:
    gnome_target.gnome_config()


@cli.command(help="Generate ansible roles dependency graph.")
@click.option("-s", "--silent", is_flag=True, help="Do not open graph in image viewer.")
def graph(silent: bool) -> None:
    roles_graph_target.generate_png(silent)


@cli.command(help="Generate random password.")
@click.option(
    "-a",
    "--alphabet",
    type=str,
    default=string.ascii_lowercase,
    help="Password alphabet.",
)
@click.option("-l", "--length", type=int, default=24, help="Password length.")
@click.option(
    "-o",
    "--output",
    type=click.Path(dir_okay=False, writable=True, executable=False, path_type=Path),
    default=utils.ARTIFACTS_PATH / "password.txt",
    help="Where to store generated password.",
)
@click.option("-n", "--number", type=int, default=1, help="Number of passwords to generate.")
def password(alphabet: str, length: int, output: Path, number: int) -> None:
    passwords_str = "".join(secrets.choice(alphabet) for _ in range(length * number))
    passwords = [passwords_str[i : i + length] + "\n" for i in range(0, len(passwords_str), length)]
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("a") as output_file:
        output_file.writelines(passwords)
    _logger.info(f"Password saved to the end of {output} file")
