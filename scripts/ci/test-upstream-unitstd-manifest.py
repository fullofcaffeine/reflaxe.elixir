#!/usr/bin/env python3
"""Focused mutation tests for the official unitstd source-record guard."""

from __future__ import annotations

import importlib.util
import json
import shutil
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
CHECKER = ROOT / "scripts/ci/check-upstream-unitstd-manifest.py"
sys.dont_write_bytecode = True
SPEC = importlib.util.spec_from_file_location("check_upstream_unitstd_manifest", CHECKER)
if SPEC is None or SPEC.loader is None:
	raise RuntimeError(f"could not load {CHECKER}")
checker = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(checker)


class UpstreamUnitstdManifestTest(unittest.TestCase):
	def setUp(self) -> None:
		self.temp = tempfile.TemporaryDirectory()
		self.root = Path(self.temp.name)
		(self.root / "docs/04-api-reference").mkdir(parents=True)
		shutil.copy2(ROOT / ".haxerc", self.root / ".haxerc")
		shutil.copy2(
			ROOT / "docs/04-api-reference/STDLIB_SUPPORT_MATRIX.md",
			self.root / "docs/04-api-reference/STDLIB_SUPPORT_MATRIX.md",
		)
		shutil.copytree(ROOT / "test/upstream_unitstd", self.root / "test/upstream_unitstd")
		self.manifest_path = self.root / "test/upstream_unitstd/manifest.json"

	def tearDown(self) -> None:
		self.temp.cleanup()

	def manifest(self) -> dict:
		return json.loads(self.manifest_path.read_text(encoding="utf-8"))

	def write_manifest(self, manifest: dict) -> None:
		self.manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")

	def entry(self, manifest: dict, module: str) -> dict:
		return next(entry for entry in manifest["modules"] if entry["module"] == module)

	def assert_guard_error(self, text: str) -> None:
		with self.assertRaisesRegex(checker.ManifestError, text):
			checker.validate_manifest(self.root)

	def test_current_manifest_is_complete(self) -> None:
		self.assertEqual(
			checker.validate_manifest(self.root),
			{
				"modules": 120,
				"runtimeEntries": 33,
				"uniqueFixtures": 32,
				"adaptedEntries": 9,
				"adaptationPatches": 8,
			},
		)

	def test_changed_fixture_fails_closed(self) -> None:
		fixture = self.root / "test/upstream_unitstd/upstream/Date.unit.hx"
		fixture.write_text(fixture.read_text(encoding="utf-8") + "// drift\n", encoding="utf-8")
		self.assert_guard_error("Date fixture hash changed")

	def test_changed_adaptation_patch_fails_closed(self) -> None:
		patch = self.root / "test/upstream_unitstd/adaptations/String.unit.hx.patch"
		patch.write_text(patch.read_text(encoding="utf-8") + "# drift\n", encoding="utf-8")
		self.assert_guard_error("String adaptation patch hash changed")

	def test_unclassified_fixture_fails_closed(self) -> None:
		fixture = self.root / "test/upstream_unitstd/upstream/New.unit.hx"
		fixture.write_text("1 == 1;\n", encoding="utf-8")
		self.assert_guard_error("unclassified fixtures: test/upstream_unitstd/upstream/New.unit.hx")

	def test_fixture_symbolic_link_fails_closed(self) -> None:
		link = self.root / "test/upstream_unitstd/upstream/New.unit.hx"
		link.symlink_to(self.root / "test/upstream_unitstd/upstream/Date.unit.hx")
		self.assert_guard_error("symbolic links are not allowed in upstream fixtures")

	def test_patch_symbolic_link_fails_closed(self) -> None:
		link = self.root / "test/upstream_unitstd/adaptations/New.unit.hx.patch"
		link.symlink_to(self.root / "test/upstream_unitstd/adaptations/String.unit.hx.patch")
		self.assert_guard_error("symbolic links are not allowed in adaptation patches")

	def test_runtime_execution_requires_an_applicable_test(self) -> None:
		manifest = self.manifest()
		self.entry(manifest, "Date")["disposition"] = "pending-review"
		self.write_manifest(manifest)
		self.assert_guard_error("Date can run only when its official test is available and applicable")

	def test_unchanged_fixture_requires_equal_source_and_local_hashes(self) -> None:
		manifest = self.manifest()
		self.entry(manifest, "Date")["sourceSha256"] = "0" * 64
		self.write_manifest(manifest)
		self.assert_guard_error("Date is unchanged but its source and fixture hashes differ")

	def test_fixture_paths_cannot_leave_the_repository(self) -> None:
		manifest = self.manifest()
		self.entry(manifest, "Date")["fixture"] = "../Date.unit.hx"
		self.write_manifest(manifest)
		self.assert_guard_error("Date.fixture must be a normalized repository-relative path")

	def test_shared_fixture_records_must_match(self) -> None:
		manifest = self.manifest()
		self.entry(manifest, "haxe.ds.List")["sourceSha256"] = "0" * 64
		self.write_manifest(manifest)
		self.assert_guard_error("haxe.ds.List shares a fixture but has different source or adaptation records")

	def test_ssl_omission_cannot_disappear(self) -> None:
		manifest = self.manifest()
		manifest["omittedUpstreamFixtures"] = []
		self.write_manifest(manifest)
		self.assert_guard_error("must contain the reviewed Ssl.unit.hx omission")

	def test_ssl_omission_cannot_count_as_beam_evidence(self) -> None:
		manifest = self.manifest()
		manifest["omittedUpstreamFixtures"][0]["disposition"] = "applicable"
		manifest["omittedUpstreamFixtures"][0]["execution"] = "runtime-suite"
		self.write_manifest(manifest)
		self.assert_guard_error("Ssl.unit.hx must remain available, not applicable, and outside the runtime suite")


if __name__ == "__main__":
	unittest.main()
