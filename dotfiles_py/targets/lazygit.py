import io
import re
from pathlib import Path
from typing import Any, cast

from ruamel.yaml import YAML
from ruamel.yaml.constructor import SafeConstructor

from ..utils import run_shell

type Keybindings = dict[str, dict[str, str | list[str]]]

_RUSSIAN_KEYS = str.maketrans(
    "qwertyuiopüåasdfghjklöäzxcvbnmøæQWERTYUIOPÜÅASDFGHJKLÖÄZXCVBNMØÆ",
    "йцукенгшщзхъфывапролджэячсмитьбюЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮ",
)


def _russian_key(key: str) -> str:
    if len(key) == 1:
        return key.translate(_RUSSIAN_KEYS)
    if match := re.fullmatch(r"(<.*[-+])(.)(>)", key):
        return f"{match[1]}{match[2].translate(_RUSSIAN_KEYS)}>"
    return key


def _add_russian_keys(binding: str | list[str]) -> str | list[str]:
    keys = [binding] if isinstance(binding, str) else binding
    aliases = [alias for key in keys if (alias := _russian_key(key)) != key]
    return list(dict.fromkeys([*keys, *aliases])) if aliases else binding


def _render_config(defaults_yaml: str, overlay_yaml: str) -> str:
    yaml = YAML(typ="safe")
    # LazyGit emits the `=` shortcut unquoted.
    yaml.constructor.add_constructor("tag:yaml.org,2002:value", SafeConstructor.construct_scalar)
    defaults = cast("Keybindings", yaml.load(defaults_yaml)["keybinding"])
    settings = cast("dict[str, Any]", yaml.load(overlay_yaml))
    for context, bindings in settings.get("keybinding", {}).items():
        defaults[context].update(bindings)
    settings["keybinding"] = {
        context: {action: _add_russian_keys(binding) for action, binding in bindings.items()}
        for context, bindings in defaults.items()
    }
    yaml.default_flow_style = False
    yaml.representer.add_representer(
        list,
        lambda representer, values: representer.represent_sequence("tag:yaml.org,2002:seq", values, flow_style=True),
    )
    stream = io.StringIO()
    yaml.dump(settings, stream)
    header = (
        "# This file is auto-generated. Edit config-overlay.yml and run "
        "`nix run . -- configs` followed by `nix run . -- format`.\n"
    )
    return header + stream.getvalue()


def lazygit_config(*, config_path: Path, check: bool) -> None:
    overlay_path = config_path.with_stem(f"{config_path.stem}-overlay")
    defaults = run_shell(["lazygit", "--config"], capture_output=True).stdout
    expected = _render_config(defaults, overlay_path.read_text(encoding="utf-8"))
    current = config_path.read_text(encoding="utf-8") if config_path.exists() else None
    if current == expected:
        return
    if check:
        yaml = YAML(typ="safe")
        if current is not None and yaml.load(current) == yaml.load(expected):
            return
        msg = f"{config_path} is missing or stale. Run `nix run . -- configs`."
        raise RuntimeError(msg)
    config_path.write_text(expected, encoding="utf-8")
