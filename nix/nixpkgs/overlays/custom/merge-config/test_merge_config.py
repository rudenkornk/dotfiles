# ruff: noqa: INP001, PT009

import json
import stat
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

PROGRAM = Path(__file__).with_name("merge-config.py")


class MergeConfigTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary_directory.cleanup)
        self.directory = Path(self.temporary_directory.name)

    def run_merge(self, *arguments: str, success: bool = True) -> subprocess.CompletedProcess[str]:
        result = subprocess.run(  # noqa: S603
            [sys.executable, PROGRAM, *arguments],
            check=False,
            capture_output=True,
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

    def test_json_creates_missing_target(self) -> None:
        source = self.write("source.json", '{"managed": true}')
        target = self.directory / "missing" / "target.json"

        self.run_merge("json", "--source", str(source), "--target", str(target))

        self.assertEqual(json.loads(target.read_text()), {"managed": True})

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

    def test_block_appends_with_inferred_marker(self) -> None:
        source = self.write("source", "managed=true\n")
        target = self.write("target.conf", "local=true\n")

        self.run_merge("block", "--source", str(source), "--target", str(target))

        self.assertEqual(
            target.read_text(),
            "local=true\n# BEGIN NIX MANAGED BLOCK\nmanaged=true\n# END NIX MANAGED BLOCK\n",
        )

    def test_block_concatenates_multiple_sources_with_newlines(self) -> None:
        source1 = self.write("source1", "first")
        source2 = self.write("source2", "second\n")
        source3 = self.write("source3", "third")
        target = self.write("target.conf", "local=true\n")

        self.run_merge(
            "block",
            "--source",
            str(source1),
            str(source2),
            str(source3),
            "--target",
            str(target),
        )

        self.assertEqual(
            target.read_text(),
            "local=true\n# BEGIN NIX MANAGED BLOCK\nfirst\nsecond\n\nthird\n# END NIX MANAGED BLOCK\n",
        )

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


if __name__ == "__main__":
    unittest.main()
