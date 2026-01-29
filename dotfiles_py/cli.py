import logging
import secrets
import string
from pathlib import Path
from typing import Annotated

import click
import typer

from . import utils
from .targets import gnome as gnome_target
from .targets import hooks as hooks_target
from .targets import lint as lint_target
from .targets import secrets as secrets_target

_logger = logging.getLogger(__name__)


REPO_PATH = Path(__file__).parent.parent
DOTPY_PATH = Path(__file__).parent
ARTIFACTS_PATH = REPO_PATH / "__artifacts__"
DATA_PATH = Path(__file__).parent / "data"
SCRIPTS_PATH = DATA_PATH / "scripts"

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
def lint() -> None:
    """Lint code."""
    lint_target.lint_code(repo_path=REPO_PATH)


@app.command(name="format")
@utils.typer_exit()
def format_code(
    *,
    check: Annotated[
        bool,
        typer.Option("-c", "--check", help="Only check if code is formatted."),
    ] = False,
) -> None:
    """Format code."""
    lint_target.format_code(repo_path=REPO_PATH, check=check)


@app.command()
@utils.typer_exit()
def hooks() -> None:
    """Perform git hooks setup in repo."""
    hooks_target.hooks(repo_path=REPO_PATH, hooks_path=DATA_PATH / "hooks")


@app.command()
@utils.typer_exit()
def gnome() -> None:
    """Regenerate gnome settings."""
    domain_rules_path = REPO_PATH / "nix" / "home-manager" / "programs" / "gui" / "dconf" / "rules.yaml"
    nix_path = REPO_PATH / "nix" / "home-manager" / "programs" / "gui" / "dconf.nix"
    rules = gnome_target.DomainRules.load(domain_rules_path)
    gnome_target.gnome_config(rules=rules, nix_path=nix_path)


@app.command()
@utils.typer_exit()
def updatekeys() -> None:
    """Update AGE keys in project secrets if recipients have changed."""
    secrets_target.updatekeys(repo_path=REPO_PATH)


@app.command()
@utils.typer_exit()
def password(
    *,
    alphabet: Annotated[
        str,
        typer.Option("-a", "--alphabet", help="Password alphabet."),
    ] = string.ascii_lowercase,
    length: Annotated[int, typer.Option("-l", "--length", help="Password length.")] = 24,
    number: Annotated[int, typer.Option("-n", "--number", help="Number of passwords to generate.")] = 1,
) -> None:
    """Generate random password."""
    passwords_str = "".join(secrets.choice(alphabet) for _ in range(length * number))
    passwords = "\n".join(passwords_str[i : i + length] for i in range(0, len(passwords_str), length))
    print(passwords)  # noqa: T201
