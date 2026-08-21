#!/usr/bin/env python3
"""Mutation tests for the official shared-language and issue source guard."""

from __future__ import annotations

import importlib.util
import json
import shutil
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
CHECKER = ROOT / "scripts/ci/check-upstream-haxe-smoke.py"
sys.dont_write_bytecode = True
SPEC = importlib.util.spec_from_file_location("check_upstream_haxe_smoke", CHECKER)
if SPEC is None or SPEC.loader is None:
	raise RuntimeError(f"could not load {CHECKER}")
checker = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(checker)


class UpstreamHaxeSmokeTest(unittest.TestCase):
	def setUp(self) -> None:
		self.temp = tempfile.TemporaryDirectory()
		self.root = Path(self.temp.name)
		shutil.copy2(ROOT / ".haxerc", self.root / ".haxerc")
		shutil.copytree(ROOT / "test/upstream_haxe_smoke", self.root / "test/upstream_haxe_smoke")
		self.manifest_path = self.root / "test/upstream_haxe_smoke/manifest.json"

	def tearDown(self) -> None:
		self.temp.cleanup()

	def assert_guard_error(self, text: str) -> None:
		with self.assertRaisesRegex(checker.ManifestError, text):
			checker.validate(self.root)

	def test_current_records_are_complete(self) -> None:
		self.assertEqual(checker.validate(self.root), 2)

	def test_changed_fixture_fails_closed(self) -> None:
		fixture = self.root / "test/upstream_haxe_smoke/upstream/unit/TestNumericSeparator.hx"
		fixture.write_text(fixture.read_text(encoding="utf-8") + "// drift\n", encoding="utf-8")
		self.assert_guard_error("fixture hash changed")

	def test_missing_fixture_fails_closed(self) -> None:
		fixture = self.root / "test/upstream_haxe_smoke/upstream/unit/issues/Issue10455.hx"
		fixture.unlink()
		self.assert_guard_error("fixture must be a regular file")

	def test_unclassified_fixture_fails_closed(self) -> None:
		fixture = self.root / "test/upstream_haxe_smoke/upstream/unit/NewTest.hx"
		fixture.write_text("package unit;\nclass NewTest {}\n", encoding="utf-8")
		self.assert_guard_error("unclassified fixtures")

	def test_unknown_family_fails_closed(self) -> None:
		manifest = json.loads(self.manifest_path.read_text(encoding="utf-8"))
		manifest["tests"][0]["family"] = "local-copy"
		self.manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
		self.assert_guard_error("invalid test family")


if __name__ == "__main__":
	unittest.main()
