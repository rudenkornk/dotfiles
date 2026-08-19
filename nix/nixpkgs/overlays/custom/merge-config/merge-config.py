# ruff: noqa: INP001

import argparse
import json
import re
import stat
import subprocess
import sys
from collections.abc import Iterator, Sequence
from contextlib import contextmanager, nullcontext
from pathlib import Path
from typing import cast

type JsonValue = dict[str, JsonValue] | list[JsonValue] | str | int | float | bool | None
type JsonObject = dict[str, JsonValue]

MARKER_PLACEHOLDER = "{mark}"
MARKER_TEXT = "NIX MANAGED BLOCK"
ENCRYPTED_SUFFIXES = (".sops", ".sops.json", ".sops.yaml")
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


def _is_encrypted(path: Path) -> bool:
    return path.name.endswith(ENCRYPTED_SUFFIXES)


def _decrypt_source(path: Path, *, retry: bool, suppress_errors: bool) -> Path | None:
    command = ["sops-cached"]
    if retry:
        command.append("--retry")
    command.append(str(path))
    result = subprocess.run(  # noqa: S603
        command,
        check=not suppress_errors,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        return None

    output_lines = result.stdout.splitlines()
    if len(output_lines) != 1 or not output_lines[0]:
        msg = f"sops-cached returned an invalid decrypted path for {path}"
        raise MergeError(msg)
    decrypted = Path(output_lines[0])
    if not decrypted.is_file():
        msg = f"sops-cached returned a missing decrypted file for {path}: {decrypted}"
        raise MergeError(msg)
    return decrypted


def _resolve_sources(sources: Sequence[Path], *, retry: bool, suppress_errors: bool) -> list[Path]:
    resolved = []
    for source in sources:
        if not _is_encrypted(source):
            resolved.append(source)
            continue
        decrypted = _decrypt_source(source, retry=retry, suppress_errors=suppress_errors)
        if decrypted is not None:
            resolved.append(decrypted)
    return resolved


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


def _insert_source(source: str, target: str, pattern: re.Pattern[str] | None) -> str:
    source_lines = source.splitlines()
    if not source_lines:
        return target

    lines = target.splitlines(keepends=True)
    insertion_line = _insertion_line(lines, pattern, None)
    if insertion_line > 0 and not lines[insertion_line - 1].endswith("\n"):
        lines[insertion_line - 1] += "\n"
    lines[insertion_line:insertion_line] = [f"{line}\n" for line in source_lines]
    return "".join(lines)


def _merge_block_sources(sources: Sequence[Path], pattern: re.Pattern[str] | None) -> str:
    if not sources:
        return ""

    result = sources[-1].read_text(encoding="utf-8")
    for source in reversed(sources[:-1]):
        result = _insert_source(result, source.read_text(encoding="utf-8"), pattern)
    return result


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


@contextmanager
def _allow_readonly_write(path: Path) -> Iterator[None]:
    mode = stat.S_IMODE(path.stat().st_mode)
    path.chmod(mode | 0o200)
    try:
        yield
    finally:
        path.chmod(mode & 0o555)


def _write_target(path: Path, content: str, previous: str, *, private: bool, read_only: bool) -> None:
    target_perms = 0o644 if not path.exists() else stat.S_IMODE(path.stat().st_mode)

    if private:
        target_perms &= 0o700
    if read_only:
        target_perms &= 0o555

    if not path.exists():
        path.touch(target_perms)

    current_perms = stat.S_IMODE(path.stat().st_mode)

    if (target_perms & current_perms) != current_perms:
        path.chmod(target_perms)

    if content == previous:
        return

    manage_write = _allow_readonly_write(path) if read_only else nullcontext()
    with manage_write:
        path.write_text(content, encoding="utf-8")


def _run_json(sources: Sequence[Path], target: Path, *, private_target: bool, read_only_target: bool) -> None:
    target_text = target.read_text(encoding="utf-8") if target.exists() else ""
    result = _load_json_object(target_text, target) if target_text.strip() else {}
    for source in sources:
        source_object = _load_json_object(source.read_text(encoding="utf-8"), source)
        result = _merge_json_objects(result, source_object)
    _write_target(
        target,
        json.dumps(result, allow_nan=False, ensure_ascii=False, indent=2) + "\n",
        target_text,
        private=private_target,
        read_only=read_only_target,
    )


def _run_block(  # noqa: PLR0913
    sources: Sequence[Path],
    target: Path,
    marker: str | None,
    insert_after: str,
    *,
    private_target: bool,
    read_only_target: bool,
) -> None:
    try:
        pattern = re.compile(insert_after) if insert_after else None
    except re.error as error:
        msg = f"invalid --insert-after regular expression: {error}"
        raise MergeError(msg) from error

    source_text = _merge_block_sources(sources, pattern)
    target_text = target.read_text(encoding="utf-8") if target.exists() else ""
    result = _merge_block(source_text, target_text, target, marker, pattern)
    _write_target(target, result, target_text, private=private_target, read_only=read_only_target)


def _add_common_arguments(parser: argparse.ArgumentParser) -> None:
    parser.add_argument(
        "--read-only-target",
        action="store_true",
        help="Remove all target write permissions after merging.",
    )
    parser.add_argument("--retry-decrypt", action="store_true", help="Retry cached decryption failures.")
    parser.add_argument("--source", nargs="+", required=True, type=Path)
    parser.add_argument(
        "--suppress-decrypt-errors",
        action="store_true",
        help="Skip sources that fail to decrypt.",
    )
    parser.add_argument("--target", required=True, type=Path)


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Merge a managed source file into a mutable target file.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    json_parser = subparsers.add_parser("json", help="Recursively merge JSON objects.")
    _add_common_arguments(json_parser)

    block_parser = subparsers.add_parser("block", help="Insert or replace a marker-delimited text block.")
    block_parser.add_argument("--insert-after", default="", metavar="REGEX")
    block_parser.add_argument("--marker", metavar="TEMPLATE")
    _add_common_arguments(block_parser)
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    parser = _parser()
    arguments = parser.parse_args(argv)
    sources = cast("list[Path]", arguments.source)
    target = cast("Path", arguments.target)
    private_target = any(_is_encrypted(source) for source in sources)
    read_only_target = cast("bool", arguments.read_only_target)

    try:
        original_sources = sources
        sources = _resolve_sources(
            sources,
            retry=cast("bool", arguments.retry_decrypt),
            suppress_errors=cast("bool", arguments.suppress_decrypt_errors),
        )
        if target.exists() and any(source.samefile(target) for source in [*original_sources, *sources]):
            msg = "source and target must be different files"
            raise MergeError(msg)  # noqa: TRY301
        target.parent.mkdir(parents=True, exist_ok=True)
        if arguments.command == "json":
            _run_json(
                sources,
                target,
                private_target=private_target,
                read_only_target=read_only_target,
            )
        else:
            _run_block(
                sources,
                target,
                cast("str | None", arguments.marker),
                cast("str", arguments.insert_after),
                private_target=private_target,
                read_only_target=read_only_target,
            )
    except subprocess.CalledProcessError as error:
        detail = error.stderr.strip()
        sys.stderr.write(f"merge-config: {detail or error}\n")
        return 1
    except (MergeError, OSError, ValueError) as error:
        sys.stderr.write(f"merge-config: {error}\n")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
