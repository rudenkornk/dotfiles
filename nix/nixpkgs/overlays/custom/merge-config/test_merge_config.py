# ruff: noqa: INP001, PT009, PT027

import json
import os
import runpy
import stat
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from textwrap import dedent
from unittest import mock

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

        self.run_merge("json", "--source", str(source), "--target", str(target))

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
            "json",
            "--source",
            str(source1),
            str(source2),
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

    def test_json_decrypts_supported_source_names_in_order(self) -> None:
        source1 = self.write("source1.json", '{"shared": "plain", "plain": true}')
        source2 = self.write("source2.sops.json", '{"shared": "infix", "infix": true}')
        source3 = self.write("source3.json.sops", '{"shared": "suffix", "suffix": true}')
        target = self.write("target.json", '{"shared": "target"}')
        target.chmod(0o640)

        self.run_merge(
            "json",
            "--source",
            str(source1),
            str(source2),
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
            "json",
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
            "json",
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

        result = self.run_merge("json", "--source", str(source), "--target", str(target), success=False)

        self.assertIn("fake decryption failure", result.stderr)
        self.assertEqual(target.read_bytes(), before)

    def test_json_suppresses_decryption_failure(self) -> None:
        failed = self.write("fail.sops.json", '{"failed": true}')
        source = self.write("source.sops.json", '{"managed": true}')
        target = self.write("target.json", '{"existing": true}')

        self.run_merge(
            "json",
            "--suppress-decrypt-errors",
            "--source",
            str(failed),
            str(source),
            "--target",
            str(target),
        )

        self.assertEqual(json.loads(target.read_text()), {"existing": True, "managed": True})

    def test_json_merges_empty_input_when_all_decryptions_fail(self) -> None:
        source = self.write("fail.sops.json", '{"failed": true}')
        target = self.directory / "target.json"

        self.run_merge(
            "json",
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

        self.run_merge("json", "--source", str(source), "--target", str(target))

        self.assertEqual(json.loads(target.read_text()), {"managed": True})

    def test_json_updates_read_only_target_and_preserves_mode(self) -> None:
        source = self.write("source.json", '{"managed": true}')
        target = self.write("target.json", '{"local": true}')
        target.chmod(0o454)

        self.run_merge(
            "json",
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

        self.run_merge("json", "--source", str(source), "--target", str(target), success=False)

        self.assertEqual(target.read_bytes(), before)
        self.assertEqual(stat.S_IMODE(target.stat().st_mode), 0o640)

    def test_json_rejects_target_used_as_any_source(self) -> None:
        source1 = self.write("source1.json", '{"first": true}\n')
        source2 = self.write("source2.json", '{"managed": true}\n')
        target = self.directory / "target.json"
        target.hardlink_to(source2)

        self.run_merge(
            "json",
            "--source",
            str(source1),
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

        self.run_merge("json", "--source", str(source), "--target", str(target))
        first_stat = target.stat()
        self.run_merge("json", "--source", str(source), "--target", str(target))

        self.assertEqual(target.stat().st_ino, first_stat.st_ino)
        self.assertEqual(target.stat().st_mtime_ns, first_stat.st_mtime_ns)
        self.assertEqual(stat.S_IMODE(target.stat().st_mode), 0o640)

    def test_json_read_only_target_removes_write_bits_from_unchanged_target(self) -> None:
        source = self.write("source.json", '{"managed": true}')
        target = self.write("target.json", '{"local": true}')
        self.run_merge("json", "--source", str(source), "--target", str(target))
        target.chmod(0o666)
        before = target.stat()

        self.run_merge(
            "json",
            "--read-only-target",
            "--source",
            str(source),
            "--target",
            str(target),
        )

        self.assertEqual(target.stat().st_ino, before.st_ino)
        self.assertEqual(target.stat().st_mtime_ns, before.st_mtime_ns)
        self.assertEqual(stat.S_IMODE(target.stat().st_mode), 0o444)

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
            str(source2),
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
            str(source2),
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
