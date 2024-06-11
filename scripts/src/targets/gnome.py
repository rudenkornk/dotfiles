import enum as _enum
import json as _json
import logging as _logging
import re as _re
from pathlib import Path as _Path

from typing_extensions import Self as _Self

from .. import utils as _utils
from .bootstrap import bootstrap as _bootstrap

_logger = _logging.getLogger(__name__)


def excluded_domains() -> set[str]:
    return {
        "/ca/desrt",
        "/com/github/wwmm/easyeffects",
        "/org/gnome/boxes",
        "/org/gnome/control-center",
        "/org/gnome/desktop/app-folders",
        "/org/gnome/desktop/notifications",
        "/org/gnome/Evince/Default",
        "/org/gnome/evince/default",
        "/org/gnome/evolution-data-server",
        "/org/gnome/nautilus",
        "/org/gnome/nm-applet/eap",
        "/org/gnome/portal/filechooser",
        "/org/gnome/Settings",
        "/org/gnome/shell/command-history",
        "/org/gnome/shell/welcome-dialog-last-shown-version",
        "/org/gnome/software",
        "/org/virt-manager",
    }


def included_domains() -> set[str]:
    return {
        "/org/gnome/calculator",
        "/org/gnome/desktop/calendar",
        "/org/gnome/desktop/input-sources",
        "/org/gnome/desktop/interface",
        "/org/gnome/desktop/peripherals",
        "/org/gnome/desktop/privacy",
        "/org/gnome/desktop/search-providers",
        "/org/gnome/desktop/session",
        "/org/gnome/desktop/sound",
        "/org/gnome/desktop/wm",
        "/org/gnome/gnome-system-monitor",
        "/org/gnome/mutter",
        "/org/gnome/settings-daemon/plugins/media-keys",
        "/org/gnome/settings-daemon/plugins/power",
        "/org/gnome/shell/favorite-apps",
        "/org/gnome/shell/keybindings",
        "/org/gnome/system/locale",
        "/org/gtk/gtk4/settings/file-chooser",
        "/org/gtk/gtk4/Settings/FileChooser",
        "/org/gtk/settings/file-chooser",
        "/org/gtk/Settings/FileChooser",
        "/system/locale",
    }


class _Style(_enum.Enum):
    GSETTINGS = _enum.auto()
    DCONF = _enum.auto()


class DConfKey(_Path):
    def to_str(self, style: _Style = _Style.DCONF) -> str:
        if style == _Style.DCONF:
            return str(self)

        if style == _Style.GSETTINGS:
            dot_path = str(self.parent)
            dot_path = dot_path.removeprefix("/")
            dot_path = dot_path.replace("/", ".")
            return f"{dot_path} {self.name}"

        assert False

    @classmethod
    def parse(cls, str_path: str, line: str, style: _Style) -> tuple[_Self, str]:
        if style == _Style.DCONF:
            path = _Path(str_path)
            key, value = line.split(sep="=", maxsplit=1)
            return cls(path / key), value

        if style == _Style.GSETTINGS:
            str_path = str_path.replace(".", "/")
            str_path = "/" + str_path
            path = _Path(str_path)
            key, value = line.split(maxsplit=1)
            return cls(path / key), value

        assert False

    @classmethod
    def parse_gsettings(cls, line: str) -> tuple[_Self, str]:
        str_path, line = line.split(maxsplit=1)
        return cls.parse(str_path, line, _Style.GSETTINGS)

    @classmethod
    def parse_dconf(cls, path: _Path, line: str) -> tuple[_Self, str]:
        return cls.parse(str(path), line, _Style.DCONF)


class DConf(dict[DConfKey, str]):
    @classmethod
    def _generate_dconf(cls) -> _Self:
        result_lines = _utils.run_shell(["dconf", "dump", "/"], capture_output=True).stdout.splitlines()
        path = None

        result = cls()

        for line in result_lines:
            line = line.strip()
            if not line:
                continue
            if line.startswith("["):
                path = _Path("/" + line[1:-1])
                continue

            assert path is not None
            key, val = DConfKey.parse_dconf(path, line)
            result[key] = val

        return result

    @classmethod
    def _generate_default_gsettings(cls) -> _Self:
        extra_env = {"XDG_CONFIG_HOME": "/dev/null"}
        result_lines = _utils.run_shell(
            ["gsettings", "list-recursively"], extra_env=extra_env, capture_output=True
        ).stdout.splitlines()
        result = cls()
        for line in result_lines:
            key, val = DConfKey.parse_gsettings(line)
            result[key] = val
        return result

    @classmethod
    def generate(cls, default: bool = False) -> _Self:
        if default:
            return cls._generate_default_gsettings()
        return cls._generate_dconf()

    def dump(self, prefix: str = "") -> str:
        result_list = []
        for key, val in sorted(self.items()):
            key_str = _json.dumps(str(key))
            val = _json.dumps(val)
            result_list.append(f"{prefix}{key_str}: {val}")
        result = "\n".join(result_list)
        return result


def generate_ansible_vars(entries: DConf, vars_path: _Path) -> str:
    ansible_vars = vars_path.read_text(encoding="utf-8")
    begin_match = _re.search(r"^(\s+)# GNOME_SETTINGS_BEGIN", ansible_vars, flags=_re.MULTILINE)
    end_match = _re.search(r"^(\s+)# GNOME_SETTINGS_END", ansible_vars, flags=_re.MULTILINE)
    assert begin_match is not None
    assert end_match is not None

    spaces = begin_match.group(1)
    entries_str = entries.dump(spaces)

    ansible_vars = ansible_vars[: begin_match.end() + 1] + entries_str + ansible_vars[end_match.start() - 1 :]
    return ansible_vars


def gnome_config() -> None:
    _bootstrap()

    defaults = DConf.generate(default=True)
    current = DConf.generate()

    diff = DConf(set(current.items()) - set(defaults.items()))

    excluded_domains_ = excluded_domains()
    included_domains_ = included_domains()

    included = DConf()
    for key, val in diff.copy().items():
        if str(key).startswith(tuple(included_domains_)):
            included[key] = val
            diff.pop(key)

    excluded = DConf()
    for key, val in diff.copy().items():
        if str(key).startswith(tuple(excluded_domains_)):
            excluded[key] = val
            diff.pop(key)

    unknown = diff

    vars_path = _utils.REPO_PATH / "roles" / "gnome" / "vars" / "main.yaml"
    script = generate_ansible_vars(included, vars_path)
    vars_path.write_text(script, encoding="utf-8")

    if excluded:
        _logger.info(f"Explicitly excluded domains:\n{excluded.dump()}")
        _logger.info("")

    if unknown:
        _logger.warning(f"UNKNOWN DOMAINS, IMPLICITLY EXCLUDED:\n{unknown.dump()}")
