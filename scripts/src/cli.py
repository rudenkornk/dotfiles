import logging as _logging
import secrets as _secrets
import string as _string
from pathlib import Path as _Path

import click as _click
from click_help_colors import HelpColorsGroup as _HelpColorsGroup

from . import roles_graph as _roles_graph
from . import update as _update
from . import utils as _utils

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

    for component in components:
        _update.update(component, dry_run)


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
