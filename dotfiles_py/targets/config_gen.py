import io
import json
import re
import tomllib
from collections.abc import Callable, Collection, Iterable
from pathlib import Path
from typing import Any, cast

import json5
import tomli_w
from ruamel.yaml import YAML
from ruamel.yaml.constructor import SafeConstructor

from ..utils import run_shell

type Settings = dict[str, Any]
type Config = Settings | list[Settings]
type StringBinding = str | list[str]
type Keybindings = dict[str, dict[str, StringBinding]]
type Key = str | Settings
type Binding = Key | list[Key]
type OpenCodeBinding = bool | Binding

_RUSSIAN_KEYS = str.maketrans(
    "qwertyuiopüåasdfghjklöäzxcvbnmøæQWERTYUIOPÜÅASDFGHJKLÖÄZXCVBNMØÆ",
    "йцукенгшщзхъфывапролджэячсмитьбюЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮ",
)


def _russian_stroke(key: str) -> str:
    if len(key) == 1:
        return key.translate(_RUSSIAN_KEYS)
    if match := re.fullmatch(r"(.*[-+])(.)(>?)", key):
        return f"{match[1]}{match[2].translate(_RUSSIAN_KEYS)}{match[3]}"
    return key


def _russian_sequence(key: str) -> str:
    return " ".join(_russian_stroke(stroke) for stroke in key.split(" "))


def _as_list[T](binding: T | list[T]) -> list[T]:
    return binding if isinstance(binding, list) else [binding]


def _append_aliases[T](originals: list[T], aliases: Iterable[T], *, occupied: Collection[T] = ()) -> list[T]:
    result = list(originals)
    for alias in aliases:
        if alias not in result and alias not in occupied:
            result.append(alias)
    return result


def _add_russian_keys(binding: StringBinding, *, occupied: Collection[str] = ()) -> StringBinding:
    keys = _as_list(binding)
    result = _append_aliases(keys, map(_russian_stroke, keys), occupied=occupied)
    return result if result != keys else binding


def _overlay_path(config_path: Path) -> Path:
    return config_path.with_stem(f"{config_path.stem}-overlay")


def _load_config(text: str, suffix: str) -> Any:  # noqa: ANN401
    if suffix == ".toml":
        return tomllib.loads(text)
    if suffix in {".json", ".jsonc"}:
        return json5.loads(text)
    yaml = YAML(typ="safe")
    # LazyGit emits the `=` shortcut unquoted.
    yaml.constructor.add_constructor("tag:yaml.org,2002:value", SafeConstructor.construct_scalar)
    return yaml.load(text)


def _dump_config(settings: Config, config_path: Path) -> str:
    if config_path.suffix == ".toml":
        content = tomli_w.dumps(cast("Settings", settings))
    elif config_path.suffix in {".json", ".jsonc"}:
        content = json.dumps(settings, ensure_ascii=False, indent=2) + "\n"
    else:
        yaml = YAML(typ="safe")
        yaml.default_flow_style = False
        yaml.representer.add_representer(
            list,
            lambda representer, values: representer.represent_sequence(
                "tag:yaml.org,2002:seq", values, flow_style=True
            ),
        )
        stream = io.StringIO()
        yaml.dump(settings, stream)
        content = stream.getvalue()
    if config_path.suffix == ".json":
        return content
    comment = "//" if config_path.suffix == ".jsonc" else "#"
    return (
        f"{comment} This file is auto-generated. Edit {_overlay_path(config_path).name} and run\n"
        f"{comment} `nix run . -- configs` followed by `nix run . -- format`.\n" + content
    )


def _write_config(config_path: Path, expected: str, *, check: bool) -> None:
    current = config_path.read_text(encoding="utf-8") if config_path.exists() else None
    if current == expected:
        return
    if check:
        if current is not None and _load_config(current, config_path.suffix) == _load_config(
            expected, config_path.suffix
        ):
            return
        msg = f"{config_path} is missing or stale. Run `nix run . -- configs`."
        raise RuntimeError(msg)
    config_path.write_text(expected, encoding="utf-8")


def _default_text(name: str) -> str:
    return run_shell(["keymap-defaults", name], capture_output=True).stdout


def _read_overlay(config_path: Path) -> Settings:
    return cast("Settings", _load_config(_overlay_path(config_path).read_text(encoding="utf-8"), config_path.suffix))


def _render_yazi(defaults: Settings, overlay: Settings) -> Settings:
    settings = {}
    for context in sorted(defaults.keys() | overlay.keys()):
        layer = overlay.get(context, {})
        entries = [
            *layer.get("prepend_keymap", []),
            *layer.get("keymap", defaults.get(context, {}).get("keymap", [])),
            *layer.get("append_keymap", []),
        ]
        bindings: dict[tuple[tuple[str, ...], str | None], Settings] = {}
        for entry in entries:
            keys = tuple(_as_list(entry["on"]))
            bindings.setdefault((keys, entry.get("for")), {**entry, "on": list(keys)})
        for (keys, platform), entry in list(bindings.items()):
            translated = tuple(_russian_stroke(key) for key in keys)
            if translated != keys:
                bindings.setdefault((translated, platform), {**entry, "on": list(translated)})
        settings[context] = {"keymap": list(bindings.values())}
    return settings


def _build_yazi(config_path: Path) -> Settings:
    defaults = tomllib.loads(_default_text("yazi.toml"))
    return _render_yazi(defaults, _read_overlay(config_path))


def _opencode_defaults(source: str) -> dict[str, OpenCodeBinding]:
    leader = re.search(r'export const LeaderDefault = ("[^"]+")', source)
    if leader is None:
        msg = "OpenCode's leader default was not found."
        raise ValueError(msg)
    definitions = source.split("export const Definitions = {", 1)[1].split("} satisfies", 1)[0]
    defaults: dict[str, OpenCodeBinding] = {}
    for line in definitions.splitlines():
        if not line.strip() or line.lstrip().startswith("//"):
            continue
        match = re.fullmatch(r'\s*("[^"]+"|\w+): keybind\((.+), "[^"]*"\),?', line)
        if match is None:
            msg = f"Unrecognized OpenCode keybinding definition: {line}"
            raise ValueError(msg)
        name = match[1].strip('"')
        value = leader[1] if match[2] == "LeaderDefault" else match[2]
        defaults[name] = json5.loads(value)
    return defaults


_OPENCODE_KEY_PARTS = re.compile(
    r"<[^>]+>|(?:ctrl|control|shift|alt|meta|option|super|hyper)\+|"
    r"(?:escape|esc|return|enter|linefeed|backspace|delete|insert|home|end|"
    r"pageup|pagedown|pgup|pgdown|space|left|right|up|down|tab|none|f\d+)|.",
    re.IGNORECASE,
)


def _opencode_key_aliases(key: str, *, russian_leader: str) -> list[str]:
    alias = "".join(_russian_stroke(part[0]) for part in _OPENCODE_KEY_PARTS.finditer(key))
    chords = (
        [shortcut.replace("<leader>", russian_leader, 1) for shortcut in (key, alias)]
        if russian_leader and key.startswith("<leader>")
        else []
    )
    return [*chords, alias]


def _opencode_item_aliases(item: Key, *, russian_leader: str) -> list[Key]:
    if isinstance(item, str):
        return list(_opencode_key_aliases(item, russian_leader=russian_leader))
    stroke = item.get("key", item)
    aliases: list[Key]
    if isinstance(stroke, str):
        aliases = list(_opencode_key_aliases(stroke, russian_leader=russian_leader))
    else:
        aliases = [{**stroke, "name": _russian_stroke(stroke["name"])}]
    return [{**item, "key": alias} for alias in aliases] if "key" in item else aliases


def _opencode_aliases(binding: OpenCodeBinding, *, russian_leader: str = "") -> OpenCodeBinding:
    if isinstance(binding, bool):
        return binding
    originals: list[Key] = list(binding.split(",")) if isinstance(binding, str) else _as_list(binding)
    aliases = (alias for item in originals for alias in _opencode_item_aliases(item, russian_leader=russian_leader))
    result = _append_aliases(originals, aliases)
    return result if result != originals else binding


def _render_opencode(defaults: dict[str, OpenCodeBinding], overlay: Settings) -> Settings:
    bindings: dict[str, OpenCodeBinding] = defaults | overlay.get("keybinds", {})
    leader = bindings["leader"]
    translated_leader = _russian_stroke(leader) if isinstance(leader, str) else ""
    russian_leader = translated_leader if translated_leader != leader else ""
    # OpenCode registers only the first leader binding; emit explicit chords for the Russian leader.
    keybinds = {
        action: binding if action == "leader" else _opencode_aliases(binding, russian_leader=russian_leader)
        for action, binding in bindings.items()
    }
    return {**overlay, "keybinds": keybinds}


def _build_opencode(config_path: Path) -> Settings:
    defaults = _opencode_defaults(_default_text("opencode.ts"))
    return _render_opencode(defaults, _read_overlay(config_path))


def _gemini_defaults(source: str) -> list[Settings]:
    # Gemini generates these reference tables from `defaultKeyBindingConfig`.
    tables = source.split("<!-- KEYBINDINGS-AUTOGEN:START -->", 1)[1].split("<!-- KEYBINDINGS-AUTOGEN:END -->", 1)[0]
    bindings = []
    for line in tables.splitlines():
        if match := re.fullmatch(r"\|\s*`([^`]+)`\s*\|.*\|\s*([^|]+)\|", line):
            for key in re.findall(r"`([^`]+)`", match[2]):
                shortcut = key.lower().replace("cmd/win", "cmd").replace(" ", "")
                bindings.append({"command": match[1], "key": shortcut})
    if not bindings:
        msg = "Gemini's default keybindings were not found."
        raise ValueError(msg)
    return bindings


def _render_gemini(defaults: list[Settings], overlay: list[Settings]) -> list[Settings]:
    bindings = {(entry["command"], entry["key"]): entry for entry in defaults}
    for entry in overlay:
        command, key = entry["command"], entry["key"]
        if command.startswith("-"):
            bindings.pop((command[1:], key), None)
        else:
            bindings[command, key] = entry
    settings = list(overlay)
    explicit_keys = {entry["key"] for entry in overlay}
    for entry in bindings.values():
        key = entry["key"]
        translated = _russian_stroke(key)
        alias = {**entry, "key": translated}
        if translated != key and translated not in explicit_keys and alias not in settings:
            settings.append(alias)
    return settings


def _build_gemini(config_path: Path) -> list[Settings]:
    defaults = _gemini_defaults(_default_text("gemini.md"))
    overlay = cast("list[Settings]", _load_config(_overlay_path(config_path).read_text(encoding="utf-8"), ".json"))
    return _render_gemini(defaults, overlay)


def _add_russian_key_entries[T](bindings: dict[str, T]) -> dict[str, T]:
    result = dict(bindings)
    for key, binding in bindings.items():
        result.setdefault(_russian_sequence(key), binding)
    return result


def _build_claude(config_path: Path) -> Settings:
    overlay = _read_overlay(config_path)
    return {
        **overlay,
        "bindings": [
            {**block, "bindings": _add_russian_key_entries(block["bindings"])} for block in overlay["bindings"]
        ],
    }


def _render_atuin(defaults: Settings, overlay: Settings) -> Settings:
    defaults = {mode: dict(bindings) for mode, bindings in defaults.items()}
    defaults["vim-insert"] = dict(defaults["emacs"])
    invert = overlay.get("invert", False)
    for key, action, exits in (("j", "select-next", not invert), ("k", "select-previous", invert)):
        defaults["vim-normal"][key] = (
            [{"when": "list-at-start", "action": "exit"}, {"action": action}] if exits else action
        )
    if overlay.get("keymap_mode") in {"vim-normal", "vim-insert"}:
        defaults["inspector"].update(j="inspect-next", k="inspect-previous")
    for mode, bindings in overlay.get("keymap", {}).items():
        defaults.setdefault(mode, {}).update(bindings)
    return {**overlay, "keymap": {mode: _add_russian_key_entries(bindings) for mode, bindings in defaults.items()}}


def _build_atuin(config_path: Path) -> Settings:
    defaults = tomllib.loads(config_path.with_name("keymap-defaults.toml").read_text(encoding="utf-8"))
    return _render_atuin(defaults, _read_overlay(config_path))


def _wiki_aliases(binding: Binding, *, occupied: Collection[Key]) -> Binding:
    originals: list[Key] = _as_list(binding)
    aliases = (
        {**item, "code": _russian_stroke(item["code"])} if isinstance(item, dict) else _russian_stroke(item)
        for item in originals
    )
    result = _append_aliases(originals, aliases, occupied=occupied)
    return result if result != originals else binding


def _render_wiki(defaults: Settings, overlay: Settings) -> Settings:
    defaults = {context: dict(bindings) for context, bindings in defaults.items()}
    for context, bindings in overlay.get("bindings", {}).items():
        defaults.setdefault(context, {}).update(bindings)
    contexts = {}
    for context, bindings in defaults.items():
        occupied = [item for binding in bindings.values() for item in _as_list(binding)]
        contexts[context] = {action: _wiki_aliases(binding, occupied=occupied) for action, binding in bindings.items()}
    return {**overlay, "bindings": contexts}


def _build_wiki(config_path: Path) -> Settings:
    defaults = tomllib.loads(config_path.with_name("keymap-defaults.toml").read_text(encoding="utf-8"))
    return _render_wiki(defaults, _read_overlay(config_path))


def _render_dua(defaults: dict[str, bool | StringBinding], overlay: Settings) -> Settings:
    bindings: dict[str, bool | StringBinding] = defaults | overlay.get("keys", {})
    occupied = {key for binding in bindings.values() if isinstance(binding, (str, list)) for key in _as_list(binding)}
    keys = {
        action: _add_russian_keys(binding, occupied=occupied) if isinstance(binding, (str, list)) else binding
        for action, binding in bindings.items()
    }
    return {**overlay, "keys": keys}


def _build_dua(config_path: Path) -> Settings:
    template = run_shell(["dua", "config", "show-default"], capture_output=True).stdout
    defaults = tomllib.loads(re.sub(r"(?m)^# (\w+\s*=)", r"\1", template))["keys"]
    return _render_dua(defaults, _read_overlay(config_path))


def _render_lazygit(defaults: Keybindings, overlay: Settings) -> Settings:
    defaults = {context: dict(bindings) for context, bindings in defaults.items()}
    for context, bindings in overlay.get("keybinding", {}).items():
        defaults[context].update(bindings)
    keybinding = {}
    for context, bindings in defaults.items():
        occupied = {key for binding in bindings.values() for key in _as_list(binding)}
        keybinding[context] = {
            action: _add_russian_keys(binding, occupied=occupied) for action, binding in bindings.items()
        }
    return {**overlay, "keybinding": keybinding}


def _build_lazygit(config_path: Path) -> Settings:
    text = run_shell(["lazygit", "--config"], capture_output=True).stdout
    defaults = cast("Keybindings", _load_config(text, ".yml")["keybinding"])
    return _render_lazygit(defaults, _read_overlay(config_path))


def generate_configs(*, repo_path: Path, check: bool) -> None:
    configs: list[tuple[str, Callable[[Path], Config]]] = [
        ("vcs/configs/.config/lazygit/config.yml", _build_lazygit),
        ("fs-navigation/configs/.config/yazi/keymap.toml", _build_yazi),
        ("ai/configs/.config/opencode/cli.json", _build_opencode),
        ("ai/configs/.gemini/keybindings.json", _build_gemini),
        ("ai/configs/.claude/keybindings.json", _build_claude),
        ("shell/configs/.config/atuin/config.toml", _build_atuin),
        ("other/configs/.config/wiki-tui/config.toml", _build_wiki),
        ("fs-navigation/configs/.config/dua-cli/config.toml", _build_dua),
    ]
    for relative_path, build in configs:
        config_path = repo_path / "nix/home-manager" / relative_path
        settings = build(config_path)
        _write_config(config_path, _dump_config(settings, config_path), check=check)
