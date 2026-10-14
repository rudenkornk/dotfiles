import io
import json
import re
import tomllib
from pathlib import Path
from typing import TYPE_CHECKING, Any, cast

import json5
import tomli_w
from ruamel.yaml import YAML
from ruamel.yaml.constructor import SafeConstructor

from ..utils import run_shell

if TYPE_CHECKING:
    from collections.abc import Callable

type Settings = dict[str, Any]
type Config = Settings | list[Settings]
type StringBinding = str | list[str]
type Keybindings = dict[str, dict[str, StringBinding]]

_RUSSIAN_KEYS = str.maketrans(
    "qwertyuiopüåasdfghjklöäzxcvbnmøæQWERTYUIOPÜÅASDFGHJKLÖÄZXCVBNMØÆ",
    "йцукенгшщзхъфывапролджэячсмитьбюЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮ",
)


def _russian_stroke(key: str) -> str:
    if len(key) == 1:
        return key.translate(_RUSSIAN_KEYS)
    if match := re.fullmatch(r"(<.*[-+])(.)(>)", key):
        return f"{match[1]}{match[2].translate(_RUSSIAN_KEYS)}>"
    return key


def _as_list[T](binding: T | list[T]) -> list[T]:
    return binding if isinstance(binding, list) else [binding]


def _add_russian_keys(binding: StringBinding) -> StringBinding:
    keys = _as_list(binding)
    aliases = [alias for key in keys if (alias := _russian_stroke(key)) != key]
    return list(dict.fromkeys([*keys, *aliases])) if aliases else binding


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


def _read_overlay(config_path: Path) -> Settings:
    return cast("Settings", _load_config(_overlay_path(config_path).read_text(encoding="utf-8"), config_path.suffix))


def _render_lazygit(defaults: Keybindings, overlay: Settings) -> Settings:
    defaults = {context: dict(bindings) for context, bindings in defaults.items()}
    for context, bindings in overlay.get("keybinding", {}).items():
        defaults[context].update(bindings)
    keybinding = {
        context: {action: _add_russian_keys(binding) for action, binding in bindings.items()}
        for context, bindings in defaults.items()
    }
    return {**overlay, "keybinding": keybinding}


def _build_lazygit(config_path: Path) -> Settings:
    text = run_shell(["lazygit", "--config"], capture_output=True).stdout
    defaults = cast("Keybindings", _load_config(text, ".yml")["keybinding"])
    return _render_lazygit(defaults, _read_overlay(config_path))


def generate_configs(*, repo_path: Path, check: bool) -> None:
    configs: list[tuple[str, Callable[[Path], Config]]] = [
        ("vcs/configs/.config/lazygit/config.yml", _build_lazygit),
    ]
    for relative_path, build in configs:
        config_path = repo_path / "nix/home-manager" / relative_path
        settings = build(config_path)
        _write_config(config_path, _dump_config(settings, config_path), check=check)
