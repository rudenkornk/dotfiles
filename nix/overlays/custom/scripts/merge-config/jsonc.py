# ruff: noqa: INP001

import json
import re
from collections.abc import Iterator, Mapping, MutableMapping
from dataclasses import dataclass
from typing import Self, cast

from lark import Lark, Token, Tree, UnexpectedInput

_PARSER = Lark(
    r"""
    ?start: value
    ?value: object | array | STRING -> string
          | NUMBER -> number
          | "true" -> true
          | "false" -> false
          | "null" -> null
    object: "{" [pair ("," pair)* [","]] "}"
    pair: STRING ":" value
    array: "[" [value ("," value)* [","]] "]"
    STRING: /"(?:[^"\\\x00-\x1f]|\\(?:["\\\/bfnrt]|u[0-9a-fA-F]{4}))*"/
    NUMBER: /-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)?/
    %ignore /[ \t\r\n]+/
    %ignore /\/\/[^\r\n]*/
    %ignore /\/\*(?s:.*?)\*\//
    """,
    parser="lalr",
    propagate_positions=True,
    maybe_placeholders=False,
)


class ParseError(ValueError):
    pass


class _JsoncString(str):
    __slots__ = ("key_prefix", "text")

    key_prefix: str
    text: str

    def __new__(cls, text: str, *, key_prefix: str = "") -> Self:
        value = super().__new__(cls, json.loads(text))
        value.key_prefix = key_prefix
        value.text = text
        return value

    def __getnewargs__(self) -> tuple[str]:
        return (self.text,)


@dataclass(frozen=True)
class _JsoncNumber:
    # Number values retain their literal spelling, without Python's numeric conversion limits.
    text: str


class _JsoncObject(MutableMapping[str, object]):
    def __init__(self, text: str, node: Tree[Token], *, root: bool = False) -> None:
        self._text = text
        self._node = node
        self._root = root
        self._values: dict[str, object] = {}
        self.update(
            (key, _jsonc_value(text, cast("Tree[Token]", pair.children[1])))
            for key, pair in _jsonc_properties(text, node).items()
        )

    def __getitem__(self, key: str) -> object:
        return self._values[key]

    def __iter__(self) -> Iterator[str]:
        return iter(self._values)

    def __len__(self) -> int:
        return len(self._values)

    def __setitem__(self, key: str, value: object) -> None:
        if not isinstance(key, str):
            msg = "JSONC must use string dictionary keys"
            raise TypeError(msg)
        if key in self:
            current = dumps(self[key], nested=True)
            replacement = dumps(value, nested=True)
            # A later no-op must retain the current value's trivia, not the original document's trivia.
            if _PARSER.parse(current) == _PARSER.parse(replacement):
                return
        if isinstance(value, (Mapping, list)) and not isinstance(value, (_JsoncObject, _JsoncArray)):
            text = dumps(value, nested=True)
            value = _jsonc_value(text, _PARSER.parse(text))
        self._values[key] = value

    def __delitem__(self, key: str) -> None:
        del self._values[key]
        self._text = self.dumps()
        self._node = _PARSER.parse(self._text)

    def __ior__(self, other: Mapping[str, object]) -> Self:
        self.update(other)
        return self

    def dumps(self, *, nested: bool = False) -> str:
        text, node = self._text, self._node
        edits: list[tuple[int, int, str]] = []
        properties = _jsonc_properties(text, node)
        pairs = list(properties.values())
        end = node.meta.end_pos - 1
        last = None
        trailing_comma = False
        for index, (key, pair) in enumerate(properties.items()):
            following = pairs[index + 1].meta.start_pos if index + 1 < len(pairs) else end
            comma = next(_PARSER.lex(text[pair.meta.end_pos : following]), None)
            if key in self:
                value = cast("Tree[Token]", pair.children[1])
                replacement = dumps(self[key], nested=True)
                if replacement != text[value.meta.start_pos : value.meta.end_pos]:
                    edits.append((value.meta.start_pos, value.meta.end_pos, replacement))
                last, trailing_comma = pair, comma is not None
            else:
                edits.append((pair.meta.start_pos, pair.meta.end_pos, ""))
                if comma is not None:
                    start = pair.meta.end_pos + cast("int", comma.start_pos)
                    edits.append((start, start + 1, ""))

        added = []
        for key, item in self.items():
            if key not in properties:
                prefix = key.key_prefix if isinstance(key, _JsoncString) else ""
                added.append((prefix or f"{dumps(key)}: ") + dumps(item, nested=True))
        if added:
            if last is not None and not trailing_comma:
                edits.append((last.meta.end_pos, last.meta.end_pos, ","))
            first = next(iter(properties.values()), node)
            line_prefix = text[text.rfind("\n", 0, first.meta.start_pos) + 1 : first.meta.start_pos]
            indent = (
                line_prefix
                if properties and not line_prefix.strip()
                else re.split(r"[^ \t]", line_prefix, maxsplit=1)[0] + "  "
            )
            insertion = len(text[:end].rstrip(" \t"))
            prefix = "" if text[insertion - 1] == "\n" else "\n"
            content = prefix + ",\n".join(indent + value for value in added) + ("," if trailing_comma else "") + "\n"
            edits.append((insertion, insertion, content))

        content = _jsonc_edits(text, node, edits)
        if self._root and not nested:
            content = text[: node.meta.start_pos] + content + text[node.meta.end_pos :]
        return content


class _JsoncArray(list[object]):
    def __init__(self, text: str, node: Tree[Token]) -> None:
        self._text = text
        self._node = node
        super().__init__(_jsonc_value(text, child) for child in node.children if isinstance(child, Tree))

    def dumps(self) -> str:
        values = [dumps(value, nested=True) for value in self]
        children = [child for child in self._node.children if isinstance(child, Tree)]
        if len(values) != len(children):
            return "[" + ", ".join(values) + "]"
        edits = [
            (child.meta.start_pos, child.meta.end_pos, value)
            for child, value in zip(children, values, strict=True)
            if value != self._text[child.meta.start_pos : child.meta.end_pos]
        ]
        return _jsonc_edits(self._text, self._node, edits)


def _jsonc_properties(text: str, node: Tree[Token]) -> dict[str, Tree[Token]]:
    properties: dict[str, Tree[Token]] = {}
    for pair in node.children:
        if isinstance(pair, Tree):
            value = cast("Tree[Token]", pair.children[1])
            key = _JsoncString(
                cast("Token", pair.children[0]), key_prefix=text[pair.meta.start_pos : value.meta.start_pos]
            )
            properties[key] = pair
    return properties


def _jsonc_value(text: str, node: Tree[Token]) -> object:
    if node.data == "object":
        return _JsoncObject(text, node)
    if node.data == "array":
        return _JsoncArray(text, node)
    literal = text[node.meta.start_pos : node.meta.end_pos]
    if node.data == "number":
        return _JsoncNumber(literal)
    if node.data == "string":
        return _JsoncString(literal)
    value: object = json.loads(literal)
    return value


def loads(text: str) -> MutableMapping[str, object]:
    try:
        node = _PARSER.parse(text)
    except UnexpectedInput as error:
        raise ParseError(type(error).__name__) from error
    if node.data != "object":
        msg = "must contain a top-level dictionary"
        raise ParseError(msg)
    for obj in node.find_data("object"):
        if len(_jsonc_properties(text, obj)) != len(obj.children):
            msg = "duplicate JSONC keys are unsupported"
            raise ParseError(msg)
    return _JsoncObject(text, node, root=True)


def _jsonc_edits(text: str, node: Tree[Token], edits: list[tuple[int, int, str]]) -> str:
    offset = node.meta.start_pos
    text = text[offset : node.meta.end_pos]
    # Reverse insertion order too, so a comma at the same offset stays before the added properties.
    edits.sort(key=lambda edit: edit[0])
    for start, end, content in reversed(edits):
        text = text[: start - offset] + content + text[end - offset :]
    return text


def dumps(value: object, *, nested: bool = False) -> str:
    if isinstance(value, _JsoncObject):
        return value.dumps(nested=nested)
    if isinstance(value, _JsoncArray):
        return value.dumps()
    if isinstance(value, (_JsoncString, _JsoncNumber)):
        return value.text
    if isinstance(value, Mapping):
        if any(not isinstance(key, str) for key in value):
            msg = "JSONC must use string dictionary keys"
            raise TypeError(msg)
        pairs = (f"{dumps(key)}: {dumps(item, nested=True)}" for key, item in value.items())
        return "{" + ", ".join(pairs) + "}" + ("" if nested else "\n")
    if isinstance(value, list):
        return "[" + ", ".join(dumps(item, nested=True) for item in value) + "]"
    return json.dumps(value, allow_nan=False)
