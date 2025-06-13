import enum
import json
import logging
import sys
from itertools import chain
from pathlib import Path
from typing import Self

from .. import utils

_logger = logging.getLogger(__name__)


class _Style(enum.Enum):
    GSETTINGS = enum.auto()
    DCONF = enum.auto()


class DConfKey(Path):
    if sys.version_info < (3, 12):
        # pylint: disable-next=protected-access, no-member
        _flavour = type(Path())._flavour  # type: ignore[attr-defined] # noqa: SLF001

    def to_str(self, style: _Style = _Style.DCONF) -> str:
        if style == _Style.DCONF:
            return str(self)

        if style == _Style.GSETTINGS:
            dot_path = str(self.parent)
            dot_path = dot_path.removeprefix("/")
            dot_path = dot_path.replace("/", ".")
            return f"{dot_path} {self.name}"

        raise AssertionError

    @classmethod
    def parse(cls, str_path: str, line: str, style: _Style) -> tuple[Self, str]:
        if style == _Style.DCONF:
            path = Path(str_path)
            key, value = line.split(sep="=", maxsplit=1)
            return cls(path / key), value

        if style == _Style.GSETTINGS:
            str_path = str_path.replace(".", "/")
            str_path = "/" + str_path
            path = Path(str_path)
            key, value = line.split(maxsplit=1)
            return cls(path / key), value

        raise AssertionError

    @classmethod
    def parse_gsettings(cls, line: str) -> tuple[Self, str]:
        str_path, line = line.split(maxsplit=1)
        return cls.parse(str_path, line, _Style.GSETTINGS)

    @classmethod
    def parse_dconf(cls, path: Path, line: str) -> tuple[Self, str]:
        return cls.parse(str(path), line, _Style.DCONF)


class DConf(dict[DConfKey, str]):
    @classmethod
    def _generate_dconf(cls) -> Self:
        result_lines = utils.run_shell(["dconf", "dump", "/"], capture_output=True).stdout.splitlines()
        path = None

        result = cls()

        for line in result_lines:
            line = line.strip()  # noqa: PLW2901
            if not line:
                continue
            if line.startswith("["):
                path = Path("/" + line[1:-1])
                continue

            if path is None:
                msg = f"Could not parse path from line {line}"
                raise ValueError(msg)

            key, val = DConfKey.parse_dconf(path, line)
            result[key] = val

        return result

    @classmethod
    def _generate_default_gsettings(cls) -> Self:
        extra_env = {"XDG_CONFIG_HOME": "/dev/null"}
        result_lines = utils.run_shell(
            ["gsettings", "list-recursively"],
            extra_env=extra_env,
            capture_output=True,
        ).stdout.splitlines()
        result = cls()
        for line in result_lines:
            key, val = DConfKey.parse_gsettings(line)
            result[key] = val
        return result

    @classmethod
    def generate(cls, *, default: bool = False) -> Self:
        if default:
            return cls._generate_default_gsettings()
        return cls._generate_dconf()

    def dump(self, *, prefix: str = "") -> str:
        result_list = []
        for key, val in sorted(self.items()):
            key_str = json.dumps(str(key))
            result_list.append(f"{prefix}{key_str}: {json.dumps(val)}")
        return "\n".join(result_list)


class _DomainKind(enum.Enum):
    INCLUDED = enum.auto()
    EXCLUDED = enum.auto()
    UNKNOWN = enum.auto()

    def serialize(self) -> str:
        return self.name.lower()

    @classmethod
    def deserialize(cls, value: str) -> Self:
        return cls[value.upper()]


class _Domains:
    def __init__(self, domains: dict[str, _DomainKind] | None = None) -> None:
        self.domains = domains or {}

    def serialize(self) -> dict[str, str]:
        return {key: val.serialize() for key, val in self.domains.items()}

    @classmethod
    def deserialize(cls, value: dict[str, str]) -> Self:
        result = cls()
        for key, val in value.items():
            result.domains[key] = _DomainKind.deserialize(val)
        return result

    def __getitem__(self, domain: DConfKey) -> _DomainKind:
        return self.get(domain)

    def get(self, domain: DConfKey) -> _DomainKind:
        _, result = max(
            # Use (cheaper?) tuple `(("", _DomainKind.UNKNOWN),)` instead of
            # creating a full dict `{"": _DomainKind.UNKNOWN}.items()` for the default value
            chain((("", _DomainKind.UNKNOWN),), self.domains.items()),
            key=lambda item: (str(domain).startswith(item[0]), len(item[0])),
        )
        return result


def generate_ansible_vars(entries: DConf, vars_path: Path) -> None:
    ansible_vars, yaml = utils.yaml_read(vars_path)
    if not isinstance(ansible_vars, dict):
        msg = f"Expected a dictionary in {vars_path}, got {type(ansible_vars)}"
        raise TypeError(msg)
    ansible_vars["gnome_settings"] = {str(key): val for key, val in sorted(entries.items())}
    utils.yaml_write(vars_path, ansible_vars, yaml)


def gnome_config() -> None:
    defaults = DConf.generate(default=True)
    current = DConf.generate()

    diff = DConf(set(current.items()) - set(defaults.items()))

    domain_rules_path = utils.REPO_PATH / "roles" / "gnome" / "vars" / "rules.yaml"
    domain_rules, _ = utils.yaml_read(domain_rules_path)
    if not isinstance(domain_rules, dict):
        msg = f"Expected a dictionary in {domain_rules_path}, got {type(domain_rules)}"
        raise TypeError(msg)
    domains = _Domains.deserialize(domain_rules["gnome_rules"])

    cats: dict[_DomainKind, DConf] = {kind: DConf() for kind in _DomainKind}
    for key, val in diff.items():
        cats[domains[key]][key] = val

    vars_path = utils.REPO_PATH / "roles" / "gnome" / "vars" / "main.yaml"
    generate_ansible_vars(cats[_DomainKind.INCLUDED], vars_path)

    if cats[_DomainKind.EXCLUDED]:
        _logger.info(f"Explicitly excluded domains:\n{cats[_DomainKind.EXCLUDED].dump()}")
        _logger.info("")

    if cats[_DomainKind.UNKNOWN]:
        _logger.warning(f"UNKNOWN DOMAINS, IMPLICITLY EXCLUDED:\n{cats[_DomainKind.UNKNOWN].dump()}")
