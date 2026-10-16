# ruff: noqa: INP001

import json
import re
import shlex
import subprocess
import sys
from dataclasses import asdict, dataclass

_RUSSIAN_KEYS = str.maketrans(
    "qwertyuiopüåasdfghjklöäzxcvbnmøæQWERTYUIOPÜÅASDFGHJKLÖÄZXCVBNMØÆ",
    "йцукенгшщзхъфывапролджэячсмитьбюЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮ",
)
_STATE_OPTION = "@russian-keymap-aliases"


@dataclass(frozen=True)
class Binding:
    table: str
    key: str
    command: str
    repeat: bool

    def render(self) -> str:
        repeat = "-r " if self.repeat else ""
        return f"bind-key {repeat}-T {shlex.quote(self.table)} {shlex.quote(self.key)} {self.command}"


def parse_bindings(text: str) -> dict[tuple[str, str], Binding]:
    bindings = {}
    for line in text.splitlines():
        match = re.fullmatch(r"bind-key\s+(-r\s+)?-T\s+(\S+)\s+(\S+)\s+(.*)", line)
        if match is None:
            msg = f"Unrecognized tmux binding: {line}"
            raise ValueError(msg)
        binding = Binding(match[2], shlex.split(match[3])[0], match[4], bool(match[1]))
        bindings[binding.table, binding.key] = binding
    return bindings


def russian_key(key: str) -> str:
    if match := re.fullmatch(r"((?:[CMS]-)*)(.)", key):
        return match[1] + match[2].translate(_RUSSIAN_KEYS)
    return key


def refresh(socket: str) -> None:
    def tmux(*args: str, input_text: str | None = None) -> str:
        return subprocess.run(  # noqa: S603
            ["tmux", "-S", socket, *args],  # noqa: S607
            input=input_text,
            capture_output=True,
            text=True,
            check=True,
        ).stdout

    bindings = parse_bindings(tmux("list-keys"))
    previous = json.loads(tmux("show-options", "-gqv", _STATE_OPTION) or "[]")
    commands = []
    for entry in previous:
        binding = Binding(**entry)
        identity = binding.table, binding.key
        # An explicit Russian binding loaded since the last refresh takes precedence.
        if bindings.get(identity) == binding:
            del bindings[identity]
            commands.append(f"unbind-key -T {shlex.quote(binding.table)} {shlex.quote(binding.key)}")

    aliases = []
    for binding in list(bindings.values()):
        key = russian_key(binding.key)
        identity = binding.table, key
        if key != binding.key and identity not in bindings:
            alias = Binding(binding.table, key, binding.command, binding.repeat)
            bindings[identity] = alias
            aliases.append(asdict(alias))
            commands.append(alias.render())
    if commands:
        tmux("source-file", "-", input_text="\n".join(commands) + "\n")
    tmux("set-option", "-g", _STATE_OPTION, json.dumps(aliases, ensure_ascii=False))


if __name__ == "__main__":
    refresh(sys.argv[1])
