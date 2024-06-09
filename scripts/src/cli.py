import getpass as _getpass
import logging as _logging
import secrets as _secrets
import string as _string
from pathlib import Path as _Path

import click as _click
from click_help_colors import HelpColorsGroup as _HelpColorsGroup

from . import utils as _utils
from .targets import bootstrap as _bootstrap
from .targets import config as _config
from .targets import gnome as _gnome
from .targets import hooks as _hooks
from .targets import lint as _lint
from .targets import roles_graph as _roles_graph
from .targets import update as _update

_logger = _logging.getLogger(__name__)


@_click.group(
    help="main script for spawning Ansible operations or managing dotfiles.",
    context_settings={"help_option_names": ["-h", "--help"], "show_default": True},
    cls=_HelpColorsGroup,
    help_headers_color="yellow",
    help_options_color="green",
)
@_click.option(
    "-l",
    "--log-level",
    type=_click.Choice(
        ["debug", "info", "warning", "error", "critical", "d", "i", "w", "e", "c"], case_sensitive=False
    ),
    default="info",
    help="Logging level.",
)
def cli(log_level: str) -> None:
    level_map = {
        "debug": _logging.DEBUG,
        "info": _logging.INFO,
        "warning": _logging.WARNING,
        "error": _logging.ERROR,
        "d": _logging.DEBUG,
        "i": _logging.INFO,
        "w": _logging.WARNING,
        "e": _logging.ERROR,
        "c": _logging.CRITICAL,
    }
    _logging.getLogger().setLevel(level_map[log_level])


@cli.command(help="Configure systems.")
@_click.option(
    "-t",
    "--host",
    type=_click.Choice(list(_config.hosts().keys())),
    default=["localhost"],
    help="Hosts to configure. Note, that 'dotfiles_*' hostnames have a special meaning: "
    "they are actually a podman containers, which are automatically started and used for testing purposes.",
    multiple=True,
)
@_click.option(
    "-u",
    "--user",
    type=str,
    default=_getpass.getuser(),
    help="Target user to configure.",
)
@_click.option(
    "-v", "--verify-unchanged", is_flag=True, help="This is an idempotency check. If anything was changed, fail."
)
@_click.option(
    "-m",
    "--mode",
    type=_click.Choice(_config.ConfigMode.values()),
    default="full",
    help="Configuration mode. "
    "'bootstrap' will only install python and create target user on the host. "
    "'reduced' will skip some most heavy configuration steps. "
    "'full' will do full configuration.",
)
def config(host: list[str], user: str, verify_unchanged: bool, mode: str) -> None:
    mode_enum = _config.ConfigMode[mode.upper()]
    _config.config(hostnames=host, user=user, verify_unchanged=verify_unchanged, mode=mode_enum)


@cli.command(help="Check that bootstrap.sh script works correctly on different systems.")
@_click.option(
    "-i",
    "--image",
    type=_click.Choice(_config.images()),
    default=[_config.images()[0]],
    help="Target container image, where to check bootstrap.sh script.",
    multiple=True,
)
def check_bootstrap(image: list[str]) -> None:
    for image_ in image:
        _bootstrap.check_bootstrap(image_)


@cli.command(help="Lint code.")
def lint() -> None:
    _lint.lint_code()


@cli.command(name="format", help="Format code.")
def format_code() -> None:
    _lint.format_code()


@cli.command(help="Setup repo git hooks.")
def hooks() -> None:
    _hooks.hooks()


@cli.command(help="Update components versions.")
@_click.option(
    "-c",
    "--components",
    type=_click.Choice(["all"] + _update.get_update_choices()),
    default=["all"],
    help="Component to update.",
    multiple=True,
)
@_click.option("-d", "--dry-run", is_flag=True, help="Do not actually change versions.")
def update(components: list[str], dry_run: bool) -> None:
    if "all" in components:
        components = _update.get_update_choices()

    _update.update(components, dry_run)


@cli.command(help="Regenerate gnome settings")
def gnome() -> None:
    _gnome.gnome_config()


@cli.command(help="Generate ansible roles dependency graph.")
@_click.option("-s", "--silent", is_flag=True, help="Do not open graph in image viewer.")
def graph(silent: bool) -> None:
    _roles_graph.generate_png(silent)


@cli.command(help="Generate random password.")
@_click.option("-a", "--alphabet", type=str, default=_string.ascii_lowercase, help="Password alphabet.")
@_click.option("-l", "--length", type=int, default=24, help="Password length.")
@_click.option(
    "-o",
    "--output",
    type=_click.Path(dir_okay=False, writable=True, executable=False, path_type=_Path),
    default=_utils.ARTIFACTS_PATH / "password.txt",
    help="Where to store generated password.",
)
@_click.option("-f", "--force", is_flag=True, help="Overwrite output file if it exists.")
def password(alphabet: str, length: int, output: _Path, force: bool) -> None:
    password_str = "".join(_secrets.choice(alphabet) for _ in range(length))

    if output.exists() and not force:
        if output.is_relative_to(_Path.cwd()):
            output = output.relative_to(_Path.cwd())

        raise _click.BadOptionUsage(
            option_name="output",
            message=f"Output file already exists: {output}, not overwriting. Use --force to overwrite.",
        )

    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(password_str, encoding="utf-8")
    _logger.info(f"Password saved to {output}")
