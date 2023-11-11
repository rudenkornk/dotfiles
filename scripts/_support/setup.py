#!/usr/bin/env python3

import argparse as _argparse
import logging as _logging
from argparse import Namespace as _Namespace
from argparse import _SubParsersAction as _SubParsersAction

from . import roles_graph as _roles_graph
from . import update as _update

_logger = _logging.getLogger(__name__)


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


def _get_parser() -> _argparse.ArgumentParser:
    parser = _argparse.ArgumentParser(
        description="Support scripts for dotfiles repo.", formatter_class=_argparse.ArgumentDefaultsHelpFormatter
    )
    subparsers = parser.add_subparsers(dest="command", required=True)
    _add_update_parser(subparsers)
    _add_roles_graph_parser(subparsers)
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


def process_shell_args(shell_args: list[str]) -> None:
    args = _parse_shell_args(shell_args)
    if args.command == "update":
        _process_update(args)
    if args.command == "graph":
        _process_roles_graph(args)
