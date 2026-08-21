#!/usr/bin/env python3
"""Validate source records for the official shared-language and issue smoke."""

from __future__ import annotations

import hashlib
import json
import re
import sys
from pathlib import Path, PurePosixPath


ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "test/upstream_haxe_smoke/manifest.json"
FIXTURE_ROOT = ROOT / "test/upstream_haxe_smoke/upstream"
SHA256 = re.compile(r"^[0-9a-f]{64}$")
COMMIT = re.compile(r"^[0-9a-f]{40}$")
FAMILIES = {"shared-language", "issue"}


class ManifestError(ValueError):
	"""The source records do not describe the checked-in official tests."""


def fail(message: str) -> None:
	print(f"[upstream-haxe-smoke] ERROR: {message}", file=sys.stderr)
	raise SystemExit(1)


def safe_path(value: object, field: str) -> PurePosixPath:
	if not isinstance(value, str) or not value:
		raise ManifestError(f"{field} must be a non-empty repository-relative path")
	path = PurePosixPath(value)
	if path.is_absolute() or ".." in path.parts or str(path) != value:
		raise ManifestError(f"{field} must be a normalized repository-relative path: {value!r}")
	return path


def digest(path: Path) -> str:
	return hashlib.sha256(path.read_bytes()).hexdigest()


def validate(root: Path = ROOT) -> int:
	manifest_path = root / MANIFEST.relative_to(ROOT)
	fixture_root = root / FIXTURE_ROOT.relative_to(ROOT)
	data = json.loads(manifest_path.read_text(encoding="utf-8"))
	if data.get("schemaVersion") != 1:
		raise ManifestError("manifest.schemaVersion must be 1")
	upstream = data.get("upstream")
	if not isinstance(upstream, dict):
		raise ManifestError("manifest.upstream must be an object")
	if upstream.get("repository") != "https://github.com/HaxeFoundation/haxe":
		raise ManifestError("manifest.upstream.repository must name the official Haxe repository")
	if COMMIT.fullmatch(str(upstream.get("commit", ""))) is None:
		raise ManifestError("manifest.upstream.commit must be a full lowercase Git commit")
	haxerc = json.loads((root / ".haxerc").read_text(encoding="utf-8"))
	if upstream.get("tag") != haxerc.get("version"):
		raise ManifestError("manifest.upstream.tag must match .haxerc")
	license_record = upstream.get("license")
	if (
		not isinstance(license_record, dict)
		or license_record.get("name") != "Haxe Standard Library MIT License"
		or license_record.get("spdx") != "MIT"
		or license_record.get("path") != "extra/LICENSE.txt"
	):
		raise ManifestError("manifest.upstream.license must record the official MIT license")
	if license_record.get("sha256") != "f84691d619932ebfd4fa3568f8311f87ed4bf12e747e9aaa619a92cb1d2d359d":
		raise ManifestError("manifest.upstream.license.sha256 must match Haxe 4.3.7")

	tests = data.get("tests")
	if not isinstance(tests, list) or not tests:
		raise ManifestError("manifest.tests must be a non-empty list")
	seen_types: set[str] = set()
	expected_files: set[Path] = set()
	seen_families: set[str] = set()
	for record in tests:
		if not isinstance(record, dict):
			raise ManifestError("each manifest.tests record must be an object")
		family = record.get("family")
		if family not in FAMILIES:
			raise ManifestError(f"invalid test family: {family!r}")
		seen_families.add(family)
		type_name = record.get("type")
		if not isinstance(type_name, str) or not type_name or type_name in seen_types:
			raise ManifestError(f"test type must be unique and non-empty: {type_name!r}")
		seen_types.add(type_name)
		source = safe_path(record.get("source"), f"{type_name}.source")
		fixture = safe_path(record.get("fixture"), f"{type_name}.fixture")
		if not str(source).startswith("tests/unit/src/unit/"):
			raise ManifestError(f"{type_name}.source is outside the official unit tree")
		fixture_path = root.joinpath(*fixture.parts)
		if fixture_path.is_symlink() or not fixture_path.is_file():
			raise ManifestError(f"fixture must be a regular file: {fixture}")
		try:
			fixture_path.resolve().relative_to(fixture_root.resolve())
		except ValueError as error:
			raise ManifestError(f"fixture leaves {fixture_root.relative_to(root)}: {fixture}") from error
		recorded_hash = record.get("sha256")
		if SHA256.fullmatch(str(recorded_hash or "")) is None:
			raise ManifestError(f"{type_name}.sha256 must be a lowercase SHA-256 value")
		if digest(fixture_path) != recorded_hash:
			raise ManifestError(f"fixture hash changed: {fixture}")
		expected_files.add(fixture_path)

	if seen_families != FAMILIES:
		raise ManifestError("manifest must include shared-language and issue tests")
	actual_files = {path for path in fixture_root.rglob("*.hx") if path.is_file()}
	if actual_files != expected_files:
		extra = sorted(path.relative_to(root).as_posix() for path in actual_files - expected_files)
		missing = sorted(path.relative_to(root).as_posix() for path in expected_files - actual_files)
		parts = []
		if extra:
			parts.append("unclassified fixtures: " + ", ".join(extra))
		if missing:
			parts.append("missing fixtures: " + ", ".join(missing))
		raise ManifestError("; ".join(parts))
	return len(tests)


if __name__ == "__main__":
	try:
		count = validate()
	except (ManifestError, json.JSONDecodeError, OSError) as error:
		fail(str(error))
	print(f"[upstream-haxe-smoke] OK: {count} official source records")
