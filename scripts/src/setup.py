#!/usr/bin/env python3

import argparse as _argparse
import logging as _logging
import string as _string
from argparse import Namespace as _Namespace
from argparse import _SubParsersAction
from pathlib import Path as _Path

from . import password as _password
from . import roles_graph as _roles_graph
from . import update as _update

_logger = _logging.getLogger(__name__)
_repo_path = _Path(__file__).parent.parent.parent


def _add_update_parser(subparsers: _SubParsersAction) -> None:  # type: ignore
    update_parser = subparsers.add_parser("update", help="Update components versions.")
    update_parser.add_argument(
        "-c",
        "--components",
        choices=["all"] + _update.get_update_choices(),
        default=["all"],
        dest="components",
        help="Component to update.",
        nargs="+",
        type=str,
    )
    update_parser.add_argument(
        "-d",
        "--dry-run",
        action="store_true",
        dest="dry_run",
        help="Do not actually change versions.",
    )


def _add_roles_graph_parser(subparsers: _SubParsersAction) -> None:  # type: ignore
    graph_parser = subparsers.add_parser("graph", help="Generate roles dependency graph.")
    graph_parser.add_argument(
        "-s", "--silent", dest="silent", action="store_false", help="Do not open graph in image viewer."
    )


def _add_password_parser(subparsers: _SubParsersAction) -> None:  # type: ignore
    graph_parser = subparsers.add_parser("password", help="Generate new password.")
    graph_parser.add_argument("-a", "--alphabet", type=str, default=_string.ascii_lowercase, help="Password alphabet.")
    graph_parser.add_argument("-l", "--length", type=int, default=24, help="Password length.")
    graph_parser.add_argument(
        "-o", "--output", type=_Path, default=_repo_path / "__artifacts__" / "password.txt", help="Where to store password."
    )


def _log_level_choices() -> list[str]:
    return ["debug", "info", "warning", "error", "critical", "d", "i", "w", "e", "c"]


def _log_level(choice: str) -> int:
    choice = choice.lower()
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
    return level_map[choice]


def _get_parser() -> _argparse.ArgumentParser:
    parser = _argparse.ArgumentParser(
        description="Support scripts for dotfiles repo.", formatter_class=_argparse.ArgumentDefaultsHelpFormatter
    )
    subparsers = parser.add_subparsers(dest="command", required=True)
    parser.add_argument(
        "-l", "--log-level", dest="log_level", default="info", choices=_log_level_choices(), help="Logging level."
    )
    _add_update_parser(subparsers)
    _add_roles_graph_parser(subparsers)
    _add_password_parser(subparsers)
    return parser


def _parse_update_args_hook(args: _Namespace) -> None:
    if "all" in args.components:
        args.components = _update.get_update_choices()


def _parse_roles_graph_args_hook(args: _Namespace) -> None:
    assert args


def _parse_shell_args(shell_args: list[str]) -> _Namespace:
    parser = _get_parser()
    args = parser.parse_args(shell_args[1:])
    if args.command == "update":
        _parse_update_args_hook(args)
    if args.command == "graph":
        _parse_roles_graph_args_hook(args)
    return args


def _process_update(args: _Namespace) -> None:
    for component in args.components:
        title = component.replace("_", " ")
        suffix = " (dry run)" if args.dry_run else ""
        _logger.info(f"Updating {title}{suffix}:")

        _update.update(component, args.dry_run)
        _logger.info("")


def _process_roles_graph(args: _Namespace) -> None:
    _roles_graph.generate_png(args.silent)


def _process_password(args: _Namespace) -> None:
    password = _password.generate_password(args.alphabet, args.length)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(password, encoding="utf-8")
    _logger.info(f"Password saved to {args.output}")


def process_shell_args(shell_args: list[str]) -> None:
    args = _parse_shell_args(shell_args)
    log_level = _log_level(args.log_level)
    _logging.getLogger().setLevel(log_level)
    if args.command == "update":
        _process_update(args)
    if args.command == "graph":
        _process_roles_graph(args)
    if args.command == "password":
        _process_password(args)
