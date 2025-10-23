import enum
import logging
from itertools import chain
from pathlib import Path, PurePath
from tempfile import NamedTemporaryFile
from typing import Self

from ..utils import run_shell, yaml_read, yaml_write

_logger = logging.getLogger(__name__)


class DConfKey(PurePath):
    def to_gsettings(self, prefix: PurePath) -> str:
        dot_path = str(self.parent.relative_to(prefix)).replace("/", ".")
        return f"{dot_path} {self.name}"

    def to_dconf(self, prefix: PurePath) -> tuple[str, str]:
        dot_path = f"[{self.parent.relative_to(prefix)}]"
        return dot_path, self.name

    @classmethod
    def parse_gsettings(cls, line: str) -> tuple[Self, str]:
        str_path, key, value = line.split(maxsplit=2)
        str_path = str_path.replace(".", "/")
        path = PurePath(str_path) / key
        return cls(path), value

    @classmethod
    def parse_dconf(cls, path: PurePath, line: str) -> tuple[Self, str]:
        key, value = line.split(sep="=", maxsplit=1)
        return cls(path / key), value


class DConf(dict[DConfKey, str]):
    @classmethod
    def _generate_dconf(cls) -> Self:
        prefix = PurePath("/")
        result_lines = run_shell(["dconf", "dump", str(prefix)], capture_output=True).stdout.splitlines()
        path = None

        result = cls()

        for line in result_lines:
            line = line.strip()  # noqa: PLW2901
            if not line:
                continue
            if line.startswith("["):
                path = prefix / line[1:-1]
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
        result_lines = run_shell(
            ["gsettings", "list-recursively"],
            extra_env=extra_env,
            capture_output=True,
        ).stdout.splitlines()
        result = cls()
        for line in result_lines:
            key, val = DConfKey.parse_gsettings("." + line)
            result[key] = val
        return result

    @classmethod
    def generate(cls, *, default: bool = False) -> Self:
        if default:
            return cls._generate_default_gsettings()
        return cls._generate_dconf()

    _root_prefix = PurePath("/")

    def dump_gsettings(self, *, prefix: PurePath = _root_prefix) -> str:
        result_list = []
        for key, val in sorted(self.items()):
            result_list.append(f"{key.to_gsettings(prefix)} {val}")
        return "\n".join(result_list)

    def dump_dconf(self, *, prefix: PurePath = _root_prefix) -> str:
        result_list = []
        current_path: str | None = None
        for full_key, val in sorted(self.items()):
            path, key = full_key.to_dconf(prefix)
            if path != current_path:
                result_list.append("")
                result_list.append(path)
                current_path = path
            result_list.append(f"{key}={val}")

        # dconf2nix is strict about leading/trailing blank lines.
        result_list.pop(0)  # Remove leading blank line.
        result_list.append("")  # Add trailing blank line.
        return "\n".join(result_list)


class DomainRuleKind(enum.Enum):
    INCLUDED = enum.auto()
    EXCLUDED = enum.auto()
    UNKNOWN = enum.auto()

    def serialize(self) -> str:
        return self.name.lower()

    @classmethod
    def deserialize(cls, value: str) -> Self:
        return cls[value.upper()]


class DomainRules:
    def __init__(self, domains: dict[str, DomainRuleKind] | None = None) -> None:
        self.domains = domains or {}

    def serialize(self) -> dict[str, str]:
        return {key: val.serialize() for key, val in self.domains.items()}

    @classmethod
    def deserialize(cls, value: dict[str, str]) -> Self:
        result = cls()
        for key, val in value.items():
            result.domains[key] = DomainRuleKind.deserialize(val)
        return result

    @classmethod
    def load(cls, path: Path) -> Self:
        raw_domains, _ = yaml_read(path)
        if not isinstance(raw_domains, dict):
            msg = f"Expected a dictionary in {path}, got {type(raw_domains)}"
            raise TypeError(msg)
        return cls.deserialize(raw_domains["gnome_rules"])

    def __getitem__(self, domain: DConfKey) -> DomainRuleKind:
        """Return the most relevant rule for the given domain."""
        return self.get(domain)

    def get(self, domain: DConfKey) -> DomainRuleKind:
        _, result = max(
            # Use (cheaper?) tuple `(("", _DomainKind.UNKNOWN),)` instead of
            # creating a full dict `{"": _DomainKind.UNKNOWN}.items()` for the default value
            chain((("", DomainRuleKind.UNKNOWN),), self.domains.items()),
            key=lambda item: (str(domain).startswith(item[0]), len(item[0])),
        )
        return result


def _generate_ansible_vars(entries: DConf, vars_path: Path) -> None:
    ansible_vars, yaml = yaml_read(vars_path)
    if not isinstance(ansible_vars, dict):
        msg = f"Expected a dictionary in {vars_path}, got {type(ansible_vars)}"
        raise TypeError(msg)
    ansible_vars["gnome_settings"] = {str(key): val for key, val in sorted(entries.items())}
    yaml_write(vars_path, ansible_vars, yaml)


def _generate_nix_settings(entries: DConf, nix_path: Path) -> None:
    with NamedTemporaryFile(delete=False) as temp_file:
        Path(temp_file.name).write_text(entries.dump_dconf())
        run_shell(["dconf2nix", "--input", temp_file.name, "--output", nix_path, "--emoji"])


def gnome_config(*, rules: DomainRules, nix_path: Path) -> None:
    defaults = DConf.generate(default=True)
    current = DConf.generate()

    diff = DConf(set(current.items()) - set(defaults.items()))

    cats: dict[DomainRuleKind, DConf] = {kind: DConf() for kind in DomainRuleKind}
    for key, val in diff.items():
        cats[rules[key]][key] = val

    _generate_nix_settings(cats[DomainRuleKind.INCLUDED], nix_path)

    if cats[DomainRuleKind.EXCLUDED]:
        _logger.info(f"Explicitly excluded {len(cats[DomainRuleKind.EXCLUDED])} domains")
        _logger.debug(f"Explicitly excluded domains:\n{cats[DomainRuleKind.EXCLUDED].dump_gsettings()}")
        _logger.info("")

    if cats[DomainRuleKind.UNKNOWN]:
        _logger.warning(f"UNKNOWN DOMAINS, IMPLICITLY EXCLUDED:\n{cats[DomainRuleKind.UNKNOWN].dump_gsettings()}")
