# ruff: noqa: INP001, PT009, PT027

import json
import os
import runpy
import stat
import subprocess
import sys
import tempfile
import tomllib
import unittest
from datetime import date
from pathlib import Path
from textwrap import dedent
from unittest import mock

from ruamel.yaml import YAML

PROGRAM = Path(__file__).with_name("merge-config.py")


class MergeConfigTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary_directory.cleanup)
        self.directory = Path(self.temporary_directory.name)
        self.bin_directory = self.directory / "bin"
        self.bin_directory.mkdir()
        self.decrypt_log = self.directory / "decrypt.log"
        sops_cached = self.bin_directory / "sops-cached"
        sops_cached.write_text(
            dedent(
                """\
                #!{python}
                import json
                import os
                import sys
                from pathlib import Path

                arguments = sys.argv[1:]
                source = Path(arguments[-1])
                with Path(os.environ["MERGE_CONFIG_DECRYPT_LOG"]).open("a", encoding="utf-8") as log:
                {spaces}log.write(json.dumps(arguments) + "\\n")
                if "fail" in source.name:
                {spaces}print("fake decryption failure", file=sys.stderr)
                {spaces}print("/dev/null")
                {spaces}sys.exit(19)
                name = source.name.replace(".sops.", ".", 1)
                if name.endswith(".sops"):
                {spaces}name = name.removesuffix(".sops")
                logical_path = Path(name)
                decrypted = source.with_name(logical_path.stem + "_decrypted" + logical_path.suffix)
                decrypted.write_bytes(source.read_bytes())
                print(decrypted)
                """
            ).format(python=sys.executable, spaces=" " * 4)
        )
        sops_cached.chmod(0o755)

    def run_merge(self, *arguments: str, success: bool = True) -> subprocess.CompletedProcess[str]:
        environment = os.environ.copy()
        environment["MERGE_CONFIG_DECRYPT_LOG"] = str(self.decrypt_log)
        environment["PATH"] = f"{self.bin_directory}:{environment['PATH']}"
        result = subprocess.run(  # noqa: S603
            [sys.executable, PROGRAM, *arguments],
            check=False,
            capture_output=True,
            env=environment,
            text=True,
        )
        if success:
            self.assertEqual(result.returncode, 0, result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0, result.stderr)
        return result

    def write(self, name: str, content: str) -> Path:
        path = self.directory / name
        path.write_text(content)
        return path

    def decrypt_invocations(self) -> list[list[str]]:
        if not self.decrypt_log.exists():
            return []
        return [json.loads(line) for line in self.decrypt_log.read_text().splitlines()]

    def test_cli_rejects_invalid_arguments_without_writing(self) -> None:
        source = self.write("source.json", '{"managed": true}')
        target = self.directory / "target.json"
        for arguments in (
            (),
            ("unknown", "--source", str(source), "--target", str(target)),
            ("dict", "--target", str(target)),
            ("dict", "--source", str(source)),
            ("dict", "--source", str(source), "--target", str(target), "--marker", "# {mark}"),
        ):
            with self.subTest(arguments=arguments):
                result = self.run_merge(*arguments, success=False)
                self.assertEqual(result.returncode, 2)
                self.assertFalse(target.exists())

    def test_cli_preserves_source_order_and_paths_with_spaces(self) -> None:
        source1 = self.write("first source", '{"first": true, "shared": 1}')
        source2 = self.write("second source", '{"second": true, "shared": 2}')
        source3 = self.write("last source", '{"shared": 3}')
        target = self.directory / "target.json"

        self.run_merge(
            "dict",
            "--source",
            str(source1),
            "--source",
            str(source2),
            "--target",
            str(target),
            f"--source={source3}",
        )

        self.assertEqual(json.loads(target.read_text()), {"first": True, "second": True, "shared": 3})

    def test_json_recursively_merges_objects_and_replaces_other_values(self) -> None:
        source = self.write(
            "source.json",
            json.dumps(
                {
                    "nested": {"replace": 3, "add": 4},
                    "list": ["managed"],
                    "scalar": {"now": "object"},
                    "null": None,
                }
            ),
        )
        target = self.write(
            "target.json",
            json.dumps(
                {
                    "targetOnly": True,
                    "nested": {"keep": 1, "replace": 2},
                    "list": ["local"],
                    "scalar": 1,
                    "null": {"keep": True},
                }
            ),
        )

        self.run_merge("dict", "--source", str(source), "--target", str(target))

        self.assertEqual(
            json.loads(target.read_text()),
            {
                "targetOnly": True,
                "nested": {"keep": 1, "replace": 3, "add": 4},
                "list": ["managed"],
                "scalar": {"now": "object"},
                "null": None,
            },
        )

    def test_json_merges_multiple_sources_in_order(self) -> None:
        source1 = self.write(
            "source1.json",
            json.dumps({"nested": {"one": 1, "shared": "one"}, "list": [1]}),
        )
        source2 = self.write(
            "source2.json",
            json.dumps({"nested": {"two": 2, "shared": "two"}, "list": [2]}),
        )
        source3 = self.write(
            "source3.json",
            json.dumps({"nested": {"three": 3, "shared": "three"}}),
        )
        target = self.write(
            "target.json",
            json.dumps({"targetOnly": True, "nested": {"target": 0, "shared": "target"}}),
        )

        self.run_merge(
            "dict",
            "--source",
            str(source1),
            "--source",
            str(source2),
            "--source",
            str(source3),
            "--target",
            str(target),
        )

        self.assertEqual(
            json.loads(target.read_text()),
            {
                "targetOnly": True,
                "nested": {"target": 0, "one": 1, "two": 2, "three": 3, "shared": "three"},
                "list": [2],
            },
        )

    def test_json_clear_target_ignores_existing_content(self) -> None:
        source = self.write("source.json", '{"managed": {"value": 1}}')
        target = self.write("target.json", "not JSON\n")
        target.chmod(0o640)

        self.run_merge(
            "dict",
            "--clear-target",
            "--source",
            str(source),
            "--target",
            str(target),
        )

        self.assertEqual(json.loads(target.read_text()), {"managed": {"value": 1}})
        self.assertEqual(stat.S_IMODE(target.stat().st_mode), 0o640)

    def test_json_decrypts_supported_source_names_in_order(self) -> None:
        source1 = self.write("source1.json", '{"shared": "plain", "plain": true}')
        source2 = self.write("source2.sops.json", '{"shared": "infix", "infix": true}')
        source3 = self.write("source3.json.sops", '{"shared": "suffix", "suffix": true}')
        target = self.write("target.json", '{"shared": "target"}')
        target.chmod(0o640)

        self.run_merge(
            "dict",
            "--source",
            str(source1),
            "--source",
            str(source2),
            "--source",
            str(source3),
            "--target",
            str(target),
        )

        self.assertEqual(
            json.loads(target.read_text()),
            {"shared": "suffix", "plain": True, "infix": True, "suffix": True},
        )
        self.assertEqual(self.decrypt_invocations(), [[str(source2)], [str(source3)]])
        self.assertEqual(stat.S_IMODE(target.stat().st_mode), 0o600)

    def test_json_forwards_retry_decrypt(self) -> None:
        source = self.write("source.sops.json", '{"managed": true}')
        target = self.directory / "target.json"

        self.run_merge(
            "dict",
            "--retry-decrypt",
            "--source",
            str(source),
            "--target",
            str(target),
        )

        self.assertEqual(self.decrypt_invocations(), [["--retry", str(source)]])
        self.assertEqual(stat.S_IMODE(target.stat().st_mode), 0o600)

    def test_json_creates_private_read_only_target(self) -> None:
        source = self.write("source.sops.json", '{"managed": true}')
        target = self.directory / "target.json"

        self.run_merge(
            "dict",
            "--read-only-target",
            "--source",
            str(source),
            "--target",
            str(target),
        )

        self.assertEqual(json.loads(target.read_text()), {"managed": True})
        self.assertEqual(stat.S_IMODE(target.stat().st_mode), 0o400)

    def test_json_decryption_failure_preserves_target(self) -> None:
        source = self.write("fail.sops.json", '{"managed": true}')
        target = self.write("target.json", '{"existing": true}\n')
        before = target.read_bytes()

        result = self.run_merge("dict", "--source", str(source), "--target", str(target), success=False)

        self.assertIn("fake decryption failure", result.stderr)
        self.assertEqual(target.read_bytes(), before)

    def test_json_suppresses_decryption_failure(self) -> None:
        failed = self.write("fail.sops.json", '{"failed": true}')
        source = self.write("source.sops.json", '{"managed": true}')
        target = self.write("target.json", '{"existing": true}')

        self.run_merge(
            "dict",
            "--suppress-decrypt-errors",
            "--source",
            str(failed),
            "--source",
            str(source),
            "--target",
            str(target),
        )

        self.assertEqual(json.loads(target.read_text()), {"existing": True, "managed": True})

    def test_json_merges_empty_input_when_all_decryptions_fail(self) -> None:
        source = self.write("fail.sops.json", '{"failed": true}')
        target = self.directory / "target.json"

        self.run_merge(
            "dict",
            "--suppress-decrypt-errors",
            "--source",
            str(source),
            "--target",
            str(target),
        )

        self.assertEqual(target.read_text(), "{}\n")
        self.assertEqual(stat.S_IMODE(target.stat().st_mode), 0o600)

    def test_json_creates_missing_target(self) -> None:
        source = self.write("source.json", '{"managed": true}')
        target = self.directory / "missing" / "target.json"

        self.run_merge("dict", "--source", str(source), "--target", str(target))

        self.assertEqual(json.loads(target.read_text()), {"managed": True})

    def test_json_updates_read_only_target_and_preserves_mode(self) -> None:
        source = self.write("source.json", '{"managed": true}')
        target = self.write("target.json", '{"local": true}')
        target.chmod(0o454)

        self.run_merge(
            "dict",
            "--read-only-target",
            "--source",
            str(source),
            "--target",
            str(target),
        )

        self.assertEqual(json.loads(target.read_text()), {"local": True, "managed": True})
        self.assertEqual(stat.S_IMODE(target.stat().st_mode), 0o454)

    def test_json_preserves_target_and_mode_on_failure(self) -> None:
        source = self.write("source.json", "not JSON")
        target = self.write("target.json", '{"existing": true}\n')
        target.chmod(0o640)
        before = target.read_bytes()

        self.run_merge("dict", "--source", str(source), "--target", str(target), success=False)

        self.assertEqual(target.read_bytes(), before)
        self.assertEqual(stat.S_IMODE(target.stat().st_mode), 0o640)

    def test_json_rejects_target_used_as_any_source(self) -> None:
        source1 = self.write("source1.json", '{"first": true}\n')
        source2 = self.write("source2.json", '{"managed": true}\n')
        target = self.directory / "target.json"
        target.hardlink_to(source2)

        self.run_merge(
            "dict",
            "--source",
            str(source1),
            "--source",
            str(source2),
            "--target",
            str(target),
            success=False,
        )

        self.assertEqual(source2.read_text(), '{"managed": true}\n')

    def test_json_is_idempotent_and_preserves_existing_mode(self) -> None:
        source = self.write("source.json", '{"managed": true}')
        target = self.write("target.json", '{"local": true}')
        target.chmod(0o640)

        self.run_merge("dict", "--source", str(source), "--target", str(target))
        first_stat = target.stat()
        self.run_merge("dict", "--source", str(source), "--target", str(target))

        self.assertEqual(target.stat().st_ino, first_stat.st_ino)
        self.assertEqual(target.stat().st_mtime_ns, first_stat.st_mtime_ns)
        self.assertEqual(stat.S_IMODE(target.stat().st_mode), 0o640)

    def test_json_read_only_target_removes_write_bits_from_unchanged_target(self) -> None:
        source = self.write("source.json", '{"managed": true}')
        target = self.write("target.json", '{"local": true}')
        self.run_merge("dict", "--source", str(source), "--target", str(target))
        target.chmod(0o666)
        before = target.stat()

        self.run_merge(
            "dict",
            "--read-only-target",
            "--source",
            str(source),
            "--target",
            str(target),
        )

        self.assertEqual(target.stat().st_ino, before.st_ino)
        self.assertEqual(target.stat().st_mtime_ns, before.st_mtime_ns)
        self.assertEqual(stat.S_IMODE(target.stat().st_mode), 0o444)

    def test_dict_formats_merge_in_order_and_preserve_style(self) -> None:
        fixtures = {
            "toml": (
                "# Target header.\nname = 'quoted' # Target inline.\n'literal.key' = 'literal'\n"
                "items = [1, 2]\npromote = 0\ndemote = { old = true }\ndate = 2020-01-01\n"
                "untouched = { keep = 1 }\n"
                "nested.keep = 1\nnested.shared = 'target'\n"
                "[[workers]]\nid = 1\nlocal = true\n[[workers]]\nid = 2\n",
                "items = [3]\npromote = { new = true }\ndemote = 'scalar'\ndate = 2026-09-06\n"
                "untouched = {}\n"
                "nested.shared = 'first'\nnested.add = 2\n[[workers]]\nid = 3\n",
                "nested.shared = 'last'\n",
            ),
            "yaml": (
                "# Target header.\nname: 'quoted' # Target inline.\n'literal.key': literal\n"
                "items: [1, 2]\npromote: 0\ndemote: {old: true}\ndate: 2020-01-01\n"
                "untouched: {keep: 1}\n"
                "nested: {keep: 1, shared: target}\nworkers: [{id: 1, local: true}, {id: 2}]\n",
                "items: [3]\npromote: {new: true}\ndemote: scalar\ndate: 2026-09-06\n"
                "untouched: {}\n"
                "nested: {shared: first, add: 2}\nworkers: [{id: 3}]\n",
                "nested: {shared: last}\n",
            ),
        }
        expected = {
            "name": "quoted",
            "literal.key": "literal",
            "items": [3],
            "promote": {"new": True},
            "demote": "scalar",
            "date": date(2026, 9, 6),
            "untouched": {"keep": 1},
            "nested": {"keep": 1, "shared": "last", "add": 2},
            "workers": [{"id": 3}],
        }
        for suffix in (".TOML", ".YAML", ".yml"):
            with self.subTest(suffix=suffix):
                original, first, last = fixtures["toml" if suffix == ".TOML" else "yaml"]
                target = self.write(f"target{suffix}", original)
                target.chmod(0o640)
                source1 = self.write("first source", first)
                source2 = self.write("last.sops.json", last)
                previous_decryptions = self.decrypt_invocations()
                arguments = (
                    "dict",
                    "--target",
                    str(target),
                    "--source",
                    str(source1),
                    "--source",
                    str(source2),
                    "--read-only-target",
                )

                self.run_merge(*arguments)

                text = target.read_text()
                parsed = tomllib.loads(text) if suffix == ".TOML" else YAML(typ="rt").load(text)
                self.assertEqual(parsed, expected)
                for preserved in ("# Target header.", "# Target inline.", "'quoted'"):
                    self.assertIn(preserved, text)
                self.assertEqual(self.decrypt_invocations(), [*previous_decryptions, [str(source2)]])
                self.assertEqual(stat.S_IMODE(target.stat().st_mode), 0o400)
                before = target.stat()
                self.run_merge(*arguments)
                self.assertEqual(target.read_text(), text)
                self.assertEqual(target.stat().st_ino, before.st_ino)
                self.assertEqual(target.stat().st_mtime_ns, before.st_mtime_ns)
                self.assertEqual(stat.S_IMODE(target.stat().st_mode), 0o400)

    def test_dict_formats_seed_missing_or_cleared_target_from_first_source(self) -> None:
        for suffix, first, second in (
            (".toml", "name = 'quoted' # Source inline.\n[section]\nfirst = 1\n", "section.second = 2\n"),
            (".yaml", "name: 'quoted' # Source inline.\nsection: {first: 1}\n", "section: {second: 2}\n"),
            (".yml", "name: 'quoted' # Source inline.\nsection: {first: 1}\n", "section: {second: 2}\n"),
        ):
            for clear_target in (False, True):
                with self.subTest(suffix=suffix, clear_target=clear_target):
                    source1 = self.write("first", "# Source header.\n" + first)
                    source2 = self.write("second", second)
                    target = self.directory / f"seed-{clear_target}{suffix}"
                    if clear_target:
                        target.write_text("invalid [ target\n")
                        target.chmod(0o640)
                    arguments = ["dict", "--target", str(target), "--source", str(source1), "--source", str(source2)]
                    if clear_target:
                        arguments.append("--clear-target")

                    self.run_merge(*arguments)

                    text = target.read_text()
                    parsed = tomllib.loads(text) if suffix == ".toml" else YAML(typ="rt").load(text)
                    self.assertEqual(parsed, {"name": "quoted", "section": {"first": 1, "second": 2}})
                    for preserved in ("# Source header.", "# Source inline.", "'quoted'"):
                        self.assertIn(preserved, text)
                    if clear_target:
                        self.assertEqual(stat.S_IMODE(target.stat().st_mode), 0o640)

    def test_toml_merges_tables_into_inline_tables(self) -> None:
        for source_text, expected in (
            ("[section.nested]\nmanaged = 2\n", {"keep": 1, "nested": {"managed": 2}}),
            ("[[section.workers]]\nid = 3\n", {"keep": 1, "workers": [{"id": 3}]}),
            (
                "[section.nested.first]\na = 1\n[other]\nvalue = true\n[section.nested]\nb = 2\n",
                {"keep": 1, "nested": {"first": {"a": 1}, "b": 2}},
            ),
        ):
            with self.subTest(source=source_text):
                target = self.write("inline.toml", "section = { keep = 1 } # Inline.\n")
                source = self.write("source", source_text)
                arguments = ("dict", "--source", str(source), "--target", str(target))

                self.run_merge(*arguments)

                content = target.read_text()
                self.assertEqual(tomllib.loads(content)["section"], expected)
                self.assertIn("# Inline.", content)
                self.run_merge(*arguments)
                self.assertEqual(target.read_text(), content)

    def test_dict_invalid_documents_preserve_target_bytes_and_mode(self) -> None:
        constructed = self.directory / "constructor-must-not-run"
        for suffix, valid, invalid_documents in (
            (".json", '{"keep": true}\n', ('{"key":', "[]", "null")),
            (".toml", "keep = true\n", ("key = [", "key = 1\nkey = 2\n", "date = 2026-99-99\n")),
            (
                ".yaml",
                "keep: true\n",
                (
                    "key: [",
                    "- item\n",
                    "scalar\n",
                    "null\n",
                    "1: value\n",
                    "nested: {1: value}\n",
                    "items: [{false: value}]\n",
                    "key: 1\nkey: 2\n",
                    "nested: {key: 1, key: 2}\n",
                    "first: 1\n---\nsecond: 2\n",
                    "key: &unused value\n",
                    "key: &shared {value: 1}\nother: *shared\n",
                    "key: *missing\n",
                    "key: !!str 1\n",
                    "!!map {key: 1}\n",
                    "key: !custom value\n",
                    f"key: !!python/object/apply:builtins.open [{json.dumps(str(constructed))}, 'w']\n",
                ),
            ),
        ):
            for invalid in invalid_documents:
                for invalid_target in (False, True):
                    with self.subTest(suffix=suffix, invalid=invalid, invalid_target=invalid_target):
                        source1 = self.write("first", valid)
                        source2 = self.write("second.sops.json", valid if invalid_target else invalid)
                        target = self.write(f"target{suffix}", invalid if invalid_target else valid)
                        target.chmod(0o640)
                        before = target.read_bytes()

                        self.run_merge(
                            "dict",
                            "--target",
                            str(target),
                            "--source",
                            str(source1),
                            "--source",
                            str(source2),
                            "--read-only-target",
                            success=False,
                        )

                        self.assertEqual(target.read_bytes(), before)
                        self.assertEqual(stat.S_IMODE(target.stat().st_mode), 0o640)
                        self.assertFalse(constructed.exists())

    def test_dict_rejects_unsupported_suffix_before_decryption_or_writes(self) -> None:
        source = self.write("source.sops.json", '{"managed": true}\n')
        for suffix in ("", ".conf", ".json.sops", ".yaml.bak"):
            for scenario in ("existing", "clear", "missing"):
                with self.subTest(suffix=suffix, scenario=scenario):
                    target = self.directory / f"target{suffix}"
                    if scenario == "missing":
                        target = self.directory / f"missing{suffix}" / f"target{suffix}"
                    else:
                        target.write_text('{"local": true}\n')
                        target.chmod(0o640)
                    arguments = ["dict", "--target", str(target), "--source", str(source)]
                    if scenario == "clear":
                        arguments.append("--clear-target")

                    self.run_merge(*arguments, success=False)

                    self.assertEqual(self.decrypt_invocations(), [])
                    if scenario == "missing":
                        self.assertFalse(target.parent.exists())
                    else:
                        self.assertEqual(target.read_bytes(), b'{"local": true}\n')
                        self.assertEqual(stat.S_IMODE(target.stat().st_mode), 0o640)

    def test_read_only_target_relocks_after_write_failure(self) -> None:
        target = self.write("target.json", "old")
        target.chmod(0o444)
        write_target = runpy.run_path(str(PROGRAM))["_write_target"]

        def fail_write(*_args: object, **_kwargs: object) -> None:
            self.assertNotEqual(target.stat().st_mode & stat.S_IWUSR, 0)
            msg = "write failed"
            raise OSError(msg)

        with (
            mock.patch.object(Path, "write_text", side_effect=fail_write),
            self.assertRaisesRegex(OSError, "write failed"),
        ):
            write_target(target, "new", "old", private=False, read_only=True)

        self.assertEqual(stat.S_IMODE(target.stat().st_mode), 0o444)

    def test_block_appends_with_inferred_marker(self) -> None:
        source = self.write("source", "managed=true\n")
        target = self.write("target.conf", "local=true\n")

        self.run_merge("block", "--source", str(source), "--target", str(target))

        self.assertEqual(
            target.read_text(),
            "local=true\n# BEGIN NIX MANAGED BLOCK\nmanaged=true\n# END NIX MANAGED BLOCK\n",
        )

    def test_block_inserts_later_sources_into_earlier_sources(self) -> None:
        source1 = self.write("source1", "first before\nanchor one\nfirst after\n")
        source2 = self.write("source2", "second before\nanchor two\nsecond after\n")
        source3 = self.write("source3", "third\n")
        target = self.write("target.conf", "target before\nanchor target\ntarget after\n")

        self.run_merge(
            "block",
            "--insert-after",
            "^anchor",
            "--source",
            str(source1),
            "--source",
            str(source2),
            "--source",
            str(source3),
            "--target",
            str(target),
        )

        self.assertEqual(
            target.read_text(),
            "target before\n"
            "anchor target\n"
            "# BEGIN NIX MANAGED BLOCK\n"
            "first before\n"
            "anchor one\n"
            "second before\n"
            "anchor two\n"
            "third\n"
            "second after\n"
            "first after\n"
            "# END NIX MANAGED BLOCK\n"
            "target after\n",
        )

    def test_block_clear_target_ignores_existing_content_and_is_idempotent(self) -> None:
        source = self.write("source", "managed\n")
        target = self.write("target.conf", "anchor\n# BEGIN NIX MANAGED BLOCK\nincomplete\n")

        arguments = (
            "block",
            "--clear-target",
            "--insert-after",
            "^anchor$",
            "--source",
            str(source),
            "--target",
            str(target),
        )
        self.run_merge(*arguments)
        first_stat = target.stat()
        self.run_merge(*arguments)

        self.assertEqual(
            target.read_text(),
            "# BEGIN NIX MANAGED BLOCK\nmanaged\n# END NIX MANAGED BLOCK\n",
        )
        self.assertEqual(target.stat().st_ino, first_stat.st_ino)
        self.assertEqual(target.stat().st_mtime_ns, first_stat.st_mtime_ns)

    def test_block_appends_later_sources_when_regex_does_not_match(self) -> None:
        source1 = self.write("source1", "first")
        source2 = self.write("source2", "second\n")
        source3 = self.write("source3", "third")
        target = self.write(
            "target.conf",
            "before\n# BEGIN NIX MANAGED BLOCK\nold\n# END NIX MANAGED BLOCK\nafter\n",
        )

        self.run_merge(
            "block",
            "--insert-after",
            "missing",
            "--source",
            str(source1),
            "--source",
            str(source2),
            "--source",
            str(source3),
            "--target",
            str(target),
        )

        self.assertEqual(
            target.read_text(),
            "before\n# BEGIN NIX MANAGED BLOCK\nfirst\nsecond\nthird\n# END NIX MANAGED BLOCK\nafter\n",
        )

    def test_block_decrypts_yaml_source(self) -> None:
        source = self.write("source.sops.yaml", "managed: true\n")
        target = self.write("target.yaml", "local: true\n")

        self.run_merge("block", "--source", str(source), "--target", str(target))

        self.assertEqual(
            target.read_text(),
            "local: true\n# BEGIN NIX MANAGED BLOCK\nmanaged: true\n# END NIX MANAGED BLOCK\n",
        )

    def test_block_merges_empty_input_when_all_decryptions_fail(self) -> None:
        source = self.write("fail.sops.yaml", "managed: true\n")
        target = self.write("target.yaml", "local: true\n")

        self.run_merge(
            "block",
            "--suppress-decrypt-errors",
            "--source",
            str(source),
            "--target",
            str(target),
        )

        self.assertEqual(
            target.read_text(),
            "local: true\n# BEGIN NIX MANAGED BLOCK\n# END NIX MANAGED BLOCK\n",
        )

    def test_block_treats_other_sops_suffixes_as_plaintext(self) -> None:
        source = self.write("source.sops.yml", "managed: true\n")
        target = self.write("target.yaml", "local: true\n")

        self.run_merge("block", "--source", str(source), "--target", str(target))

        self.assertEqual(self.decrypt_invocations(), [])
        self.assertIn("managed: true\n", target.read_text())

    def test_block_replaces_old_block_at_its_position_without_regex(self) -> None:
        source = self.write("source", "new\n")
        target = self.write(
            "target.conf",
            "before\n# BEGIN NIX MANAGED BLOCK\nold\n# END NIX MANAGED BLOCK\nafter\n",
        )

        self.run_merge("block", "--source", str(source), "--target", str(target))

        self.assertEqual(
            target.read_text(),
            "before\n# BEGIN NIX MANAGED BLOCK\nnew\n# END NIX MANAGED BLOCK\nafter\n",
        )

    def test_block_inserts_after_first_regex_match(self) -> None:
        source = self.write("source", "managed\n")
        target = self.write("target.conf", "anchor first\nmiddle\nanchor second\n")

        self.run_merge(
            "block",
            "--insert-after",
            "^anchor",
            "--source",
            str(source),
            "--target",
            str(target),
        )

        self.assertEqual(
            target.read_text(),
            "anchor first\n# BEGIN NIX MANAGED BLOCK\nmanaged\n# END NIX MANAGED BLOCK\nmiddle\nanchor second\n",
        )

    def test_block_is_idempotent(self) -> None:
        source = self.write("source", "managed\n")
        target = self.write("target.conf", "local=true\n")

        self.run_merge("block", "--source", str(source), "--target", str(target))
        first_stat = target.stat()
        self.run_merge("block", "--source", str(source), "--target", str(target))

        self.assertEqual(target.stat().st_ino, first_stat.st_ino)
        self.assertEqual(target.stat().st_mtime_ns, first_stat.st_mtime_ns)

    def test_block_keeps_old_position_when_regex_does_not_match(self) -> None:
        source = self.write("source", "new\n")
        target = self.write(
            "target.conf",
            "before\n# BEGIN NIX MANAGED BLOCK\nold\n# END NIX MANAGED BLOCK\nafter\n",
        )

        self.run_merge(
            "block",
            "--insert-after",
            "missing",
            "--source",
            str(source),
            "--target",
            str(target),
        )

        self.assertEqual(
            target.read_text(),
            "before\n# BEGIN NIX MANAGED BLOCK\nnew\n# END NIX MANAGED BLOCK\nafter\n",
        )

    def test_block_adjusts_regex_position_after_removing_earlier_block(self) -> None:
        source = self.write("source", "new\n")
        target = self.write(
            "target.conf",
            "# BEGIN NIX MANAGED BLOCK\nold\n# END NIX MANAGED BLOCK\nbefore\nanchor\nafter\n",
        )

        self.run_merge(
            "block",
            "--insert-after",
            "^anchor$",
            "--source",
            str(source),
            "--target",
            str(target),
        )

        self.assertEqual(
            target.read_text(),
            "before\nanchor\n# BEGIN NIX MANAGED BLOCK\nnew\n# END NIX MANAGED BLOCK\nafter\n",
        )

    def test_block_keeps_regex_position_before_old_block(self) -> None:
        source = self.write("source", "new\n")
        target = self.write(
            "target.conf",
            "anchor\nbefore\n# BEGIN NIX MANAGED BLOCK\nold\n# END NIX MANAGED BLOCK\nafter\n",
        )

        self.run_merge(
            "block",
            "--insert-after",
            "^anchor$",
            "--source",
            str(source),
            "--target",
            str(target),
        )

        self.assertEqual(
            target.read_text(),
            "anchor\n# BEGIN NIX MANAGED BLOCK\nnew\n# END NIX MANAGED BLOCK\nbefore\nafter\n",
        )

    def test_block_collapses_regex_position_inside_old_block(self) -> None:
        source = self.write("source", "new anchor\n")
        target = self.write(
            "target.conf",
            "before\n# BEGIN NIX MANAGED BLOCK\nold anchor\n# END NIX MANAGED BLOCK\nafter\n",
        )

        self.run_merge(
            "block",
            "--insert-after",
            "anchor",
            "--source",
            str(source),
            "--target",
            str(target),
        )

        self.assertEqual(
            target.read_text(),
            "before\n# BEGIN NIX MANAGED BLOCK\nnew anchor\n# END NIX MANAGED BLOCK\nafter\n",
        )

    def test_block_uses_explicit_wrapped_marker(self) -> None:
        source = self.write("source", "managed\n")
        target = self.write("target.unknown", "<body>\n")

        self.run_merge(
            "block",
            "--marker",
            "<!-- {mark} CUSTOM BLOCK -->",
            "--source",
            str(source),
            "--target",
            str(target),
        )

        self.assertEqual(
            target.read_text(),
            "<body>\n<!-- BEGIN CUSTOM BLOCK -->\nmanaged\n<!-- END CUSTOM BLOCK -->\n",
        )

    def test_block_infers_wrapped_marker(self) -> None:
        source = self.write("source", "managed\n")
        target = self.write("target.html", "<body>\n")

        self.run_merge("block", "--source", str(source), "--target", str(target))

        self.assertEqual(
            target.read_text(),
            "<body>\n<!-- BEGIN NIX MANAGED BLOCK -->\nmanaged\n<!-- END NIX MANAGED BLOCK -->\n",
        )

    def test_block_infers_shebang_marker(self) -> None:
        source = self.write("source", "managed\n")
        target = self.write("script", "#!/usr/bin/env bash\nlocal=true\n")

        self.run_merge("block", "--source", str(source), "--target", str(target))

        self.assertIn("# BEGIN NIX MANAGED BLOCK\nmanaged\n# END NIX MANAGED BLOCK\n", target.read_text())

    def test_block_inserts_empty_source(self) -> None:
        source = self.write("source", "")
        target = self.write("target.lua", "local value = true\n")

        self.run_merge("block", "--source", str(source), "--target", str(target))

        self.assertEqual(
            target.read_text(),
            "local value = true\n-- BEGIN NIX MANAGED BLOCK\n-- END NIX MANAGED BLOCK\n",
        )

    def test_block_rejects_invalid_regex_and_preserves_target(self) -> None:
        source = self.write("source", "managed\n")
        target = self.write("target.conf", "local=true\n")
        before = target.read_bytes()

        self.run_merge(
            "block",
            "--insert-after",
            "[",
            "--source",
            str(source),
            "--target",
            str(target),
            success=False,
        )

        self.assertEqual(target.read_bytes(), before)

    def test_block_rejects_multiline_marker_and_preserves_target(self) -> None:
        source = self.write("source", "managed\n")
        target = self.write("target.conf", "local=true\n")
        before = target.read_bytes()

        self.run_merge(
            "block",
            "--marker",
            "# {mark}\nBLOCK",
            "--source",
            str(source),
            "--target",
            str(target),
            success=False,
        )

        self.assertEqual(target.read_bytes(), before)

    def test_block_rejects_malformed_markers_and_preserves_target(self) -> None:
        source = self.write("source", "managed\n")
        target = self.write("target.conf", "# BEGIN NIX MANAGED BLOCK\nold\n")
        before = target.read_bytes()

        self.run_merge("block", "--source", str(source), "--target", str(target), success=False)

        self.assertEqual(target.read_bytes(), before)

    def test_block_follows_target_symlink(self) -> None:
        source = self.write("source", "managed\n")
        referent = self.write("referent.conf", "local=true\n")
        target = self.directory / "target.conf"
        target.symlink_to(referent)

        self.run_merge("block", "--source", str(source), "--target", str(target))

        self.assertTrue(target.is_symlink())
        self.assertIn("managed\n", referent.read_text())

    def test_block_read_only_target_relocks_symlink_referent(self) -> None:
        source = self.write("source", "managed\n")
        referent = self.write("referent.conf", "local=true\n")
        referent.chmod(0o444)
        target = self.directory / "target.conf"
        target.symlink_to(referent)

        self.run_merge(
            "block",
            "--read-only-target",
            "--source",
            str(source),
            "--target",
            str(target),
        )

        self.assertTrue(target.is_symlink())
        self.assertIn("managed\n", referent.read_text())
        self.assertEqual(stat.S_IMODE(referent.stat().st_mode), 0o444)


if __name__ == "__main__":
    unittest.main()
