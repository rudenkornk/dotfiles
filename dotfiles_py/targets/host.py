import hashlib
import json
import logging
import re
import uuid
from collections.abc import Mapping, Sequence
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Self

import typer
from rich.console import Console
from rich.table import Table
from rich.text import Text

from ..utils import run_shell, sudo_cat, sudo_shell

_logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class Host:
    name: str
    path: Path
    smbios_uuid_hash: str | None
    disk_device: str

    @property
    def facter_path(self) -> Path:
        return self.path.with_suffix("") / "facter.json"

    @property
    def niri_monitors_path(self) -> Path:
        return self.facter_path.parent / "niri_monitors.nix"

    @property
    def noctalia_monitors_path(self) -> Path:
        return self.facter_path.parent / "noctalia_monitors.nix"

    def render(self, template_path: Path) -> str:
        facter_report_path = self.facter_path.relative_to(self.path.parent)
        replacements = {
            "__hostname__": self.name,
            "__host_directory__": facter_report_path.parent.as_posix(),
            "__smbios_uuid_hash__": self.smbios_uuid_hash or "",
            "__disk_device__": self.disk_device,
            "__facter_report_path__": facter_report_path.as_posix(),
        }
        rendered = template_path.read_text()
        for marker, value in replacements.items():
            rendered = rendered.replace(marker, _nixify_str(value))
        return rendered

    @classmethod
    def parse(cls, path: Path) -> Self:
        output = run_shell(
            [
                "nix-instantiate",
                "--eval",
                path,
                "--arg",
                "pkgs",
                "{}",
                "--readonly-mode",
            ],
            capture_output=True,
        ).stdout
        json_text = (
            output.strip()
            .replace("{ ", '{"', 1)
            .replace(" = ", '": ')
            .replace("; }", "}")
            .replace("; ", ', "')
            .replace("<CODE>", "null")
        )
        definition = json.loads(json_text)
        hostname = definition["name"]
        if path.stem != hostname:
            msg = f"Host filename {path.name!r} does not match hostname {hostname!r}."
            raise AssertionError(msg)

        return cls(
            name=hostname,
            path=path,
            smbios_uuid_hash=definition.get("smbiosUUIDHash"),
            disk_device=definition["disk_device"],
        )


@dataclass(frozen=True)
class Disk:
    name: str
    path: str
    by_path: str | None
    size_bytes: int
    model: str
    transport: str | None
    kind: str
    fstype: str | None
    partlabel: str | None
    read_only: bool
    children: tuple["Disk", ...]

    @property
    def device_path(self) -> str:
        return self.by_path or self.path

    def contents(self) -> str:
        return "\n".join(child.summary() for child in self.children) or "No contents reported"

    def summary(self) -> str:
        details = [self.kind]
        if self.fstype:
            details.append(self.fstype)
        if self.partlabel:
            details.append(self.partlabel)
        return f"{self.name} ({', '.join(details)})"

    @classmethod
    def parse(cls, device: Mapping[str, Any], by_path_devices: Mapping[Path, str]) -> Self:
        path = device["path"]
        return cls(
            name=device["name"],
            path=path,
            by_path=by_path_devices.get(Path(path).resolve()),
            size_bytes=device["size"],
            model=device["model"] or "Unknown model",
            transport=device["tran"],
            kind=device["type"],
            fstype=device["fstype"],
            partlabel=device["partlabel"],
            read_only=device["ro"],
            children=tuple(cls.parse(child, by_path_devices) for child in device.get("children", ())),
        )


def bootstrap_host(*, repo_path: Path, templates_path: Path, force: bool) -> None:
    hosts_path = repo_path / "nix/hosts"
    smbios_uuid = _read_smbios_uuid()
    smbios_uuid_hash = hashlib.sha256(smbios_uuid.encode("ascii")).hexdigest()[:40]
    existing_hosts = _existing_hosts(hosts_path)
    matched_host = _matched_host(existing_hosts, smbios_uuid_hash)

    if matched_host is not None and not force:
        _logger.info(f"Host {matched_host.name} is already registered.")
        _logger.info("Use `--force` to regenerate it.")
        return

    report = _facter_report()

    if matched_host is None:
        hostname = _prompt_new_hostname(default=_infer_hostname(report))
        host_path = hosts_path / f"{hostname}.nix"
    else:
        hostname = matched_host.name
        host_path = matched_host.path

    for existing in existing_hosts:
        if existing == matched_host:
            continue
        if existing.path.resolve() == host_path.resolve():
            msg = f"Refusing to overwrite existing host files in {existing.path}"
            raise RuntimeError(msg)

    selected_disk = _prompt_disk(_lsblk(), matched_host)
    host = Host(
        name=hostname,
        path=host_path,
        smbios_uuid_hash=smbios_uuid_hash,
        disk_device=selected_disk.device_path,
    )
    host_text = host.render(templates_path / "host.nix")

    host.facter_path.parent.mkdir(exist_ok=True)
    host.path.write_text(host_text)
    host.facter_path.write_text(f"{json.dumps(report, indent=2)}\n")
    host.niri_monitors_path.write_text("{ }\n")
    host.noctalia_monitors_path.write_text("{ }\n")

    _commit_generated_host(repo_path=repo_path, host=host)

    _logger.info(f"\nGenerated host definition {host.path.relative_to(repo_path)}")


def _commit_generated_host(*, repo_path: Path, host: Host) -> None:
    generated_paths = (host.path, host.facter_path, host.niri_monitors_path, host.noctalia_monitors_path)
    relative_paths = [str(path.relative_to(repo_path)) for path in generated_paths]
    run_shell(["git", "add", "--", *relative_paths], cwd=repo_path)
    run_shell(["git", "commit", "--message", f"feat(hosts): add {host.name} host"], cwd=repo_path)


def _read_smbios_uuid() -> str:
    product_uuid_path = Path("/sys/class/dmi/id/product_uuid")
    uuid_raw = sudo_cat(product_uuid_path)
    parsed = uuid.UUID(uuid_raw.strip())
    if parsed.int in {0, (1 << 128) - 1}:
        msg = f"{product_uuid_path} contains a placeholder UUID and cannot identify this machine."
        raise RuntimeError(msg)
    return str(parsed)


def _facter_report() -> dict[str, Any]:
    report = json.loads(sudo_shell(["nixos-facter"], capture_output=True).stdout)
    return _filter_facter_report(report)


def _filter_facter_report(report: dict[str, Any]) -> dict[str, Any]:
    sensitive_patterns = (
        re.compile(r"/by-(?:id|uuid|partuuid|partlabel|label)/.+", re.IGNORECASE),
        re.compile(r"\b(?:[0-9a-f]{2}:){5}[0-9a-f]{2}\b", re.IGNORECASE),
        re.compile(r"\b[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}\b", re.IGNORECASE),
    )
    removed = object()
    filtered_report = _filter_facter_value(
        report,
        sensitive_patterns=sensitive_patterns,
        removed=removed,
    )
    if not isinstance(filtered_report, dict):
        msg = "Filtered Facter report is empty."
        raise TypeError(msg)
    return filtered_report


def _filter_facter_value(
    value: object,
    *,
    sensitive_patterns: Sequence[re.Pattern[str]],
    removed: object,
) -> object:
    def is_sensitive(text: str) -> bool:
        return any(pattern.search(text) is not None for pattern in sensitive_patterns)

    if isinstance(value, str):
        return removed if is_sensitive(value) else value
    if isinstance(value, list):
        filtered_items = (
            _filter_facter_value(
                item,
                sensitive_patterns=sensitive_patterns,
                removed=removed,
            )
            for item in value
        )
        return [item for item in filtered_items if item is not removed]
    if isinstance(value, dict):
        filtered_dict: dict[str, object] = {}
        for key, item in value.items():
            if not isinstance(key, str) or key.casefold() == "serial" or is_sensitive(key):
                continue
            filtered_item = _filter_facter_value(
                item,
                sensitive_patterns=sensitive_patterns,
                removed=removed,
            )
            if filtered_item is not removed:
                filtered_dict[key] = filtered_item
        return filtered_dict
    return value


def _existing_hosts(hosts_path: Path) -> tuple[Host, ...]:
    host_paths = sorted(hosts_path.glob("*.nix"))
    return tuple(Host.parse(path) for path in host_paths)


def _matched_host(hosts: Sequence[Host], smbios_uuid_hash: str) -> Host | None:
    return next((host for host in hosts if host.smbios_uuid_hash == smbios_uuid_hash), None)


def _infer_hostname(report: Mapping[str, Any]) -> str | None:
    smbios_placeholders = {
        "none",
        "not applicable",
        "not specified",
        "system product name",
        "to be filled by o.e.m.",
        "unknown",
    }
    system = report["smbios"]["system"]
    for field in ("version", "product"):
        value = str(system[field]).strip()
        if not value or value.casefold() in smbios_placeholders:
            continue
        if hostname := _hostname_slug(value):
            return hostname
    return None


def _hostname_slug(value: str) -> str:
    unsupported_hostname_pattern = re.compile(r"[^a-z0-9-]+")
    repeated_hyphen_pattern = re.compile(r"-+")
    hostname = unsupported_hostname_pattern.sub("-", value.casefold())
    hostname = repeated_hyphen_pattern.sub("-", hostname).strip("-")
    return hostname[:63].rstrip("-")


def _prompt_new_hostname(*, default: str | None) -> str:
    while True:
        hostname = str(typer.prompt("Hostname", default=default) if default else typer.prompt("Hostname")).strip()
        if problem := _hostname_problem(hostname):
            _logger.warning(problem)
            continue
        return hostname


def _hostname_problem(hostname: str) -> str | None:
    hostname_pattern = re.compile(r"[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?")
    if hostname_pattern.fullmatch(hostname) is None:
        return "Hostname must be a lowercase DNS label of at most 63 characters."
    return None


def _lsblk() -> tuple[Disk, ...]:
    lsblk_columns = "NAME,PATH,SIZE,MODEL,TRAN,TYPE,FSTYPE,PARTLABEL,RO"
    output = run_shell(
        [
            "lsblk",
            "--json",
            "--bytes",
            "--tree",
            "--output",
            lsblk_columns,
        ],
        capture_output=True,
    ).stdout
    by_path_devices: dict[Path, str] = {}
    for by_path in sorted(Path("/dev/disk/by-path").glob("*")):
        by_path_devices.setdefault(by_path.resolve(), str(by_path))
    return tuple(
        Disk.parse(device, by_path_devices) for device in json.loads(output)["blockdevices"] if device["type"] == "disk"
    )


def _prompt_disk(candidates: Sequence[Disk], matched_host: Host | None) -> Disk:
    preferred_path = Path(matched_host.disk_device).resolve() if matched_host is not None else None

    candidates = sorted(
        candidates,
        key=lambda disk: (
            preferred_path is not None and Path(disk.path).resolve() != preferred_path,
            disk.read_only,
            disk.transport == "usb",
            not bool(disk.by_path),
            -disk.size_bytes,
        ),
    )
    table = Table(title="Installation disks")
    table.add_column("#", justify="right")
    table.add_column("Size", justify="right")
    table.add_column("Model")
    table.add_column("Name")
    table.add_column("Transport")
    table.add_column("RW", justify="center")
    table.add_column("Stable ID", justify="center")
    table.add_column("Existing contents")

    selections: dict[str, Disk] = {}
    for position, candidate in enumerate(candidates):
        display_index = str(len(selections) + 1)
        selections[display_index] = candidate
        table.add_row(
            Text(display_index),
            Text(_human_size(candidate.size_bytes)),
            Text(candidate.model),
            Text(candidate.name),
            Text(candidate.transport or "unknown"),
            Text("✗" if candidate.read_only else "✓"),
            Text("✓" if candidate.by_path is not None else "✗"),
            Text(candidate.contents()),
        )
        if position < len(candidates) - 1:
            table.add_row()
    Console().print(table)

    while True:
        selection = str(typer.prompt("Disk number for NixOS installation", default="1")).strip()
        selected_candidate = selections.get(selection)
        if selected_candidate is None:
            _logger.warning(f"Choose a disk number from 1 to {len(selections)}.")
            continue

        problems = []
        if selected_candidate.read_only:
            problems.append("is read-only")
        if selected_candidate.by_path is None:
            problems.append("has no stable by-path identifier; its kernel path will be used")
        if problems:
            _logger.warning(f"Selected disk {selected_candidate.path} {' and '.join(problems)}.")
            if not typer.confirm("Continue?", default=False):
                continue
        return selected_candidate


def _human_size(size_bytes: int) -> str:
    for divisor, unit in ((1024**3, "GiB"), (1024**2, "MiB"), (1024, "KiB")):
        if size_bytes >= divisor:
            return f"{size_bytes / divisor:.1f} {unit}"
    return f"{size_bytes} B"


def _nixify_str(value: str) -> str:
    return (
        value.replace("\\", "\\\\")
        .replace('"', '\\"')
        .replace("${", "\\${")
        .replace("\n", "\\n")
        .replace("\r", "\\r")
        .replace("\t", "\\t")
    )
