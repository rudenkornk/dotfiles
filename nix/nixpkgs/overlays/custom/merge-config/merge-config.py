# ruff: noqa: INP001

import argparse
import json
import re
import sys
from collections.abc import Sequence
from pathlib import Path
from typing import cast

type JsonValue = dict[str, JsonValue] | list[JsonValue] | str | int | float | bool | None
type JsonObject = dict[str, JsonValue]

MARKER_PLACEHOLDER = "{mark}"
MARKER_TEXT = "NIX MANAGED BLOCK"
LINE_MARKERS = {
    ".bash": "#",
    ".c": "//",
    ".cc": "//",
    ".clj": ";",
    ".conf": "#",
    ".cpp": "//",
    ".el": ";",
    ".fish": "#",
    ".go": "//",
    ".h": "//",
    ".hpp": "//",
    ".hs": "--",
    ".ini": "#",
    ".java": "//",
    ".js": "//",
    ".jsonc": "//",
    ".jsx": "//",
    ".kdl": "//",
    ".kts": "//",
    ".lisp": ";",
    ".lua": "--",
    ".nix": "#",
    ".pl": "#",
    ".py": "#",
    ".rb": "#",
    ".rs": "//",
    ".sh": "#",
    ".sql": "--",
    ".swift": "//",
    ".toml": "#",
    ".ts": "//",
    ".tsx": "//",
    ".vim": '"',
    ".yaml": "#",
    ".yml": "#",
    ".zsh": "#",
}
WRAPPED_MARKERS = {
    ".css": ("/*", "*/"),
    ".htm": ("<!--", "-->"),
    ".html": ("<!--", "-->"),
    ".less": ("/*", "*/"),
    ".md": ("<!--", "-->"),
    ".scss": ("/*", "*/"),
    ".svg": ("<!--", "-->"),
    ".xml": ("<!--", "-->"),
}
BASENAME_MARKERS = {
    ".env": "#",
    ".gitconfig": "#",
    "Dockerfile": "#",
    "Makefile": "#",
}


class MergeError(Exception):
    pass


def _load_json_object(text: str, path: Path) -> JsonObject:
    try:
        value = cast("JsonValue", json.loads(text))
    except json.JSONDecodeError as error:
        msg = f"failed to parse {path}: {error}"
        raise MergeError(msg) from error

    if not isinstance(value, dict):
        msg = f"{path} must contain a top-level JSON object"
        raise MergeError(msg)
    return value


def _merge_json_objects(target: JsonObject, source: JsonObject) -> JsonObject:
    result = target.copy()
    for key, source_value in source.items():
        target_value = result.get(key)
        if isinstance(target_value, dict) and isinstance(source_value, dict):
            result[key] = _merge_json_objects(target_value, source_value)
        else:
            result[key] = source_value
    return result


def _line_text(line: str) -> str:
    return line.rstrip("\r\n")


def _infer_marker(target: Path, target_lines: Sequence[str]) -> str:
    basename_marker = BASENAME_MARKERS.get(target.name)
    if basename_marker is not None:
        return f"{basename_marker} {MARKER_PLACEHOLDER} {MARKER_TEXT}"

    suffix = target.suffix.lower()
    line_marker = LINE_MARKERS.get(suffix)
    if line_marker is not None:
        return f"{line_marker} {MARKER_PLACEHOLDER} {MARKER_TEXT}"

    wrapped_marker = WRAPPED_MARKERS.get(suffix)
    if wrapped_marker is not None:
        opening, closing = wrapped_marker
        return f"{opening} {MARKER_PLACEHOLDER} {MARKER_TEXT} {closing}"

    if target_lines and _line_text(target_lines[0]).startswith("#!"):
        return f"# {MARKER_PLACEHOLDER} {MARKER_TEXT}"

    msg = f"cannot infer a comment marker for {target}; pass --marker with exactly one {MARKER_PLACEHOLDER}"
    raise MergeError(msg)


def _markers(template: str) -> tuple[str, str]:
    if "\n" in template or "\r" in template:
        msg = "marker template must fit on one line"
        raise MergeError(msg)
    if template.count(MARKER_PLACEHOLDER) != 1:
        msg = f"marker template must contain exactly one {MARKER_PLACEHOLDER}"
        raise MergeError(msg)
    return template.replace(MARKER_PLACEHOLDER, "BEGIN"), template.replace(MARKER_PLACEHOLDER, "END")


def _old_block(lines: Sequence[str], begin_marker: str, end_marker: str) -> tuple[int, int] | None:
    begin_lines = [index for index, line in enumerate(lines) if _line_text(line) == begin_marker]
    end_lines = [index for index, line in enumerate(lines) if _line_text(line) == end_marker]
    if not begin_lines and not end_lines:
        return None
    if len(begin_lines) != 1 or len(end_lines) != 1 or begin_lines[0] >= end_lines[0]:
        msg = "target contains incomplete, reversed, or duplicate managed-block markers"
        raise MergeError(msg)
    return begin_lines[0], end_lines[0] + 1


def _insertion_line(lines: Sequence[str], pattern: re.Pattern[str] | None, old_block: tuple[int, int] | None) -> int:
    if pattern is not None:
        for index, line in enumerate(lines):
            if pattern.search(_line_text(line)) is not None:
                return index + 1
    return old_block[0] if old_block is not None else len(lines)


def _adjust_after_cut(insertion_line: int, begin: int, end: int) -> int:
    if insertion_line <= begin:
        return insertion_line
    if insertion_line <= end:
        return begin
    return insertion_line - (end - begin)


def _managed_block(source: str, begin_marker: str, end_marker: str, newline: str) -> list[str]:
    source_lines = source.splitlines()
    if begin_marker in source_lines or end_marker in source_lines:
        msg = "source contains a managed-block marker"
        raise MergeError(msg)
    lines = [f"{begin_marker}{newline}"]
    lines.extend(f"{line}{newline}" for line in source_lines)
    lines.append(f"{end_marker}{newline}")
    return lines


def _merge_block(
    source: str,
    target: str,
    target_path: Path,
    marker: str | None,
    pattern: re.Pattern[str] | None,
) -> str:
    lines = target.splitlines(keepends=True)
    marker_template = marker if marker is not None else _infer_marker(target_path, lines)
    begin_marker, end_marker = _markers(marker_template)
    old_block = _old_block(lines, begin_marker, end_marker)

    insertion_line = _insertion_line(lines, pattern, old_block)
    if old_block is not None:
        begin, end = old_block
        del lines[begin:end]
        insertion_line = _adjust_after_cut(insertion_line, begin, end)

    if insertion_line > 0 and not lines[insertion_line - 1].endswith("\n"):
        lines[insertion_line - 1] += "\n"
    lines[insertion_line:insertion_line] = _managed_block(source, begin_marker, end_marker, "\n")
    return "".join(lines)


def _write_target(path: Path, content: str, previous: str) -> None:
    if content != previous:
        path.write_text(content, encoding="utf-8")


def _run_json(sources: Sequence[Path], target: Path) -> None:
    target_text = target.read_text(encoding="utf-8") if target.exists() else ""
    result = _load_json_object(target_text, target) if target_text.strip() else {}
    for source in sources:
        source_object = _load_json_object(source.read_text(encoding="utf-8"), source)
        result = _merge_json_objects(result, source_object)
    _write_target(target, json.dumps(result, allow_nan=False, ensure_ascii=False, indent=2) + "\n", target_text)


def _run_block(sources: Sequence[Path], target: Path, marker: str | None, insert_after: str) -> None:
    try:
        pattern = re.compile(insert_after) if insert_after else None
    except re.error as error:
        msg = f"invalid --insert-after regular expression: {error}"
        raise MergeError(msg) from error

    source_text = "\n".join(source.read_text(encoding="utf-8") for source in sources)
    target_text = target.read_text(encoding="utf-8") if target.exists() else ""
    result = _merge_block(source_text, target_text, target, marker, pattern)
    _write_target(target, result, target_text)


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Merge a managed source file into a mutable target file.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    json_parser = subparsers.add_parser("json", help="Recursively merge JSON objects.")
    json_parser.add_argument("--source", nargs="+", required=True, type=Path)
    json_parser.add_argument("--target", required=True, type=Path)

    block_parser = subparsers.add_parser("block", help="Insert or replace a marker-delimited text block.")
    block_parser.add_argument("--insert-after", default="", metavar="REGEX")
    block_parser.add_argument("--marker", metavar="TEMPLATE")
    block_parser.add_argument("--source", nargs="+", required=True, type=Path)
    block_parser.add_argument("--target", required=True, type=Path)
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    parser = _parser()
    arguments = parser.parse_args(argv)
    sources = cast("list[Path]", arguments.source)
    target = cast("Path", arguments.target)

    try:
        if target.exists() and any(source.samefile(target) for source in sources):
            msg = "source and target must be different files"
            raise MergeError(msg)  # noqa: TRY301
        target.parent.mkdir(parents=True, exist_ok=True)
        if arguments.command == "json":
            _run_json(sources, target)
        else:
            _run_block(sources, target, cast("str | None", arguments.marker), cast("str", arguments.insert_after))
    except (MergeError, OSError, ValueError) as error:
        sys.stderr.write(f"merge-config: {error}\n")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
