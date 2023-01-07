#!/usr/bin/env python3

import argparse as _argparse
import logging as _logging
import sys as _sys

import update as _update
import utils as _utils


def _get_components():
    prefix = "update_"
    prefix_len = len(prefix)
    components = [x[prefix_len:] for x in dir(_update) if x.startswith("update_")]
    components.sort()
    return components


def _add_update_parser(subparsers):
    update_parser = subparsers.add_parser("update", help="Update components versions.")
    update_parser.add_argument(
        "-c",
        "--components",
        choices=["all"] + _get_components(),
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


def _get_parser():
    parser = _argparse.ArgumentParser(
        description="Support scripts for dotfiles repo.", formatter_class=_argparse.ArgumentDefaultsHelpFormatter
    )
    subparsers = parser.add_subparsers(dest="command", required=True)
    _add_update_parser(subparsers)
    return parser


def _parse_update_args_hook(args):
    if "all" in args.components:
        args.components = _get_components()


def _parse_shell_args(shell_args: list):
    parser = _get_parser()
    args = parser.parse_args(shell_args[1:])
    if args.command == "update":
        _parse_update_args_hook(args)
    return args


def _process_update(args):
    for component in args.components:
        _utils.update_title(component, args.dry_run)
        update_func = getattr(_update, "update_" + component)
        update_func(dry_run=args.dry_run)
        logger.info("")


def _process_shell_args(shell_args: list):
    args = _parse_shell_args(shell_args)
    if args.command == "update":
        _process_update(args)


if __name__ == "__main__":
    _logging.basicConfig(format="%(message)s")
    logger = _utils.get_logger()
    logger.setLevel(_logging.INFO)
    try:
        _process_shell_args(_sys.argv)
    except KeyboardInterrupt:
        logger.error("Interrupted by user.")
        _sys.exit(1)