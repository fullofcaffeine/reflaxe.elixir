#!/usr/bin/env python3
"""Validate the official Haxe unitstd source records and runtime decisions."""

from __future__ import annotations

import hashlib
import json
import re
import sys
from pathlib import Path, PurePosixPath


ROOT = Path(__file__).resolve().parents[2]
SHA256 = re.compile(r"^[0-9a-f]{64}$")
COMMIT = re.compile(r"^[0-9a-f]{40}$")
UPSTREAM_SPEC_VALUES = {"available", "absent"}
DISPOSITION_VALUES = {"applicable", "pending-review", "unsupported", "not-applicable"}
EXECUTION_VALUES = {"runtime-suite", "not-run"}
FIXTURE_KIND_VALUES = {"unchanged", "adapted"}


class ManifestError(ValueError):
	"""A source record or runtime decision is incomplete or inconsistent."""


def sha256(path: Path) -> str:
	return hashlib.sha256(path.read_bytes()).hexdigest()


def safe_relative(value: object, *, field: str) -> PurePosixPath:
	if not isinstance(value, str) or not value:
		raise ManifestError(f"{field} must be a non-empty repository-relative path")
	path = PurePosixPath(value)
	if path.is_absolute() or ".." in path.parts or str(path) != value:
		raise ManifestError(f"{field} must be a normalized repository-relative path: {value!r}")
	return path


def contained_file(root: Path, relative: PurePosixPath, allowed_root: Path, *, field: str) -> Path:
	path = root.joinpath(*relative.parts)
	current = root
	for part in relative.parts:
		current /= part
		if current.is_symlink():
			raise ManifestError(f"{field} cannot use a symbolic link: {relative}")
	try:
		path.resolve().relative_to(allowed_root.resolve())
	except ValueError as error:
		raise ManifestError(f"{field} leaves its required directory: {relative}") from error
	return path


def require_hash(value: object, *, field: str) -> str:
	if not isinstance(value, str) or SHA256.fullmatch(value) is None:
		raise ManifestError(f"{field} must be a lowercase SHA-256 value")
	return value


def core_matrix_modules(root: Path) -> list[str]:
	matrix = root / "docs/04-api-reference/STDLIB_SUPPORT_MATRIX.md"
	if not matrix.exists():
		raise ManifestError(f"support matrix not found: {matrix.relative_to(root)}")

	modules: list[str] = []
	in_core_set = False
	for line in matrix.read_text(encoding="utf-8").splitlines():
		if line.startswith("## Current classified core set"):
			in_core_set = True
			continue
		if in_core_set and line.strip() == "Notes:":
			break
		if not in_core_set:
			continue
		match = re.match(r"^- `([^`]+)`", line)
		if match:
			modules.append(match.group(1))
	return modules


def require_declared_values(manifest: dict, field: str, expected: set[str]) -> None:
	actual = manifest.get(field)
	if not isinstance(actual, list) or set(actual) != expected or len(actual) != len(expected):
		raise ManifestError(f"manifest.{field} must declare exactly: {', '.join(sorted(expected))}")


def validate_upstream(manifest: dict, root: Path) -> dict:
	if manifest.get("schemaVersion") != 2:
		raise ManifestError("manifest.schemaVersion must be 2")

	upstream = manifest.get("upstream")
	if not isinstance(upstream, dict):
		raise ManifestError("manifest.upstream must be an object")
	if upstream.get("repository") != "https://github.com/HaxeFoundation/haxe":
		raise ManifestError("manifest.upstream.repository must name the official Haxe repository")
	if COMMIT.fullmatch(str(upstream.get("commit", ""))) is None:
		raise ManifestError("manifest.upstream.commit must be a lowercase 40-character Git commit")

	haxerc = json.loads((root / ".haxerc").read_text(encoding="utf-8"))
	if upstream.get("tag") != haxerc.get("version"):
		raise ManifestError("manifest.upstream.tag must match the Haxe version in .haxerc")
	if upstream.get("referenceRoot") != "tests/unit/src/unitstd":
		raise ManifestError("manifest.upstream.referenceRoot must be tests/unit/src/unitstd")
	if upstream.get("updateCommand") != "HAXE_ELIXIR_REFERENCE=<haxe-checkout> scripts/sync-upstream-unitstd-specs.sh":
		raise ManifestError("manifest.upstream.updateCommand must name the reviewed sync command")

	license_record = upstream.get("license")
	if not isinstance(license_record, dict):
		raise ManifestError("manifest.upstream.license must be an object")
	if license_record.get("name") != "Haxe Standard Library MIT License" or license_record.get("spdx") != "MIT":
		raise ManifestError("manifest.upstream.license must identify the Haxe Standard Library MIT License")
	if license_record.get("path") != "extra/LICENSE.txt":
		raise ManifestError("manifest.upstream.license.path must be extra/LICENSE.txt")
	require_hash(license_record.get("sha256"), field="manifest.upstream.license.sha256")
	return upstream


def validate_manifest(root: Path = ROOT) -> dict[str, int]:
	root = root.resolve()
	manifest_path = root / "test/upstream_unitstd/manifest.json"
	if not manifest_path.exists():
		raise ManifestError(f"manifest not found: {manifest_path.relative_to(root)}")
	manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
	if not isinstance(manifest, dict):
		raise ManifestError("manifest root must be an object")

	validate_upstream(manifest, root)
	require_declared_values(manifest, "upstreamSpecValues", UPSTREAM_SPEC_VALUES)
	require_declared_values(manifest, "dispositionValues", DISPOSITION_VALUES)
	require_declared_values(manifest, "executionValues", EXECUTION_VALUES)
	require_declared_values(manifest, "fixtureKindValues", FIXTURE_KIND_VALUES)

	entries = manifest.get("modules")
	if not isinstance(entries, list):
		raise ManifestError("manifest.modules must be a list")
	by_module: dict[str, dict] = {}
	expected_fixtures: set[Path] = set()
	expected_patches: set[Path] = set()
	shared_fixtures: dict[Path, tuple[object, ...]] = {}
	runtime_entries = 0
	adapted_entries = 0

	for entry in entries:
		if not isinstance(entry, dict):
			raise ManifestError("each manifest.modules entry must be an object")
		module = entry.get("module")
		if not isinstance(module, str) or not module:
			raise ManifestError(f"manifest entry is missing module: {entry}")
		if module in by_module:
			raise ManifestError(f"duplicate module entry: {module}")
		by_module[module] = entry

		upstream_spec = entry.get("upstreamSpec")
		disposition = entry.get("disposition")
		execution = entry.get("execution")
		if upstream_spec not in UPSTREAM_SPEC_VALUES:
			raise ManifestError(f"{module} has invalid upstreamSpec {upstream_spec!r}")
		if disposition not in DISPOSITION_VALUES:
			raise ManifestError(f"{module} has invalid disposition {disposition!r}")
		if execution not in EXECUTION_VALUES:
			raise ManifestError(f"{module} has invalid execution {execution!r}")

		if upstream_spec == "available":
			safe_relative(entry.get("source"), field=f"{module}.source")
		elif "source" in entry or "sourceSha256" in entry:
			raise ManifestError(f"{module} cannot record a source when upstreamSpec is absent")

		if execution == "runtime-suite":
			runtime_entries += 1
			if disposition != "applicable" or upstream_spec != "available":
				raise ManifestError(f"{module} can run only when its official test is available and applicable")
			fixture_kind = entry.get("fixtureKind")
			if fixture_kind not in FIXTURE_KIND_VALUES:
				raise ManifestError(f"{module} has invalid fixtureKind {fixture_kind!r}")
			fixture_rel = safe_relative(entry.get("fixture"), field=f"{module}.fixture")
			fixture = contained_file(
				root,
				fixture_rel,
				root / "test/upstream_unitstd/upstream",
				field=f"{module}.fixture",
			)
			if not fixture.is_file():
				raise ManifestError(f"{module} fixture does not exist: {fixture_rel}")
			expected_fixtures.add(fixture)
			source_hash = require_hash(entry.get("sourceSha256"), field=f"{module}.sourceSha256")
			fixture_hash = require_hash(entry.get("fixtureSha256"), field=f"{module}.fixtureSha256")
			if sha256(fixture) != fixture_hash:
				raise ManifestError(f"{module} fixture hash changed: {fixture_rel}")

			if fixture_kind == "unchanged":
				if source_hash != fixture_hash:
					raise ManifestError(f"{module} is unchanged but its source and fixture hashes differ")
				if any(field in entry for field in ("adaptationPatch", "adaptationPatchSha256", "adaptationPatchRedactions")):
					raise ManifestError(f"{module} is unchanged but records an adaptation patch")
			else:
				adapted_entries += 1
				if source_hash == fixture_hash:
					raise ManifestError(f"{module} is adapted but its source and fixture hashes match")
				patch_rel = safe_relative(entry.get("adaptationPatch"), field=f"{module}.adaptationPatch")
				patch = contained_file(
					root,
					patch_rel,
					root / "test/upstream_unitstd/adaptations",
					field=f"{module}.adaptationPatch",
				)
				if not patch.is_file():
					raise ManifestError(f"{module} adaptation patch does not exist: {patch_rel}")
				expected_patches.add(patch)
				patch_hash = require_hash(entry.get("adaptationPatchSha256"), field=f"{module}.adaptationPatchSha256")
				if sha256(patch) != patch_hash:
					raise ManifestError(f"{module} adaptation patch hash changed: {patch_rel}")
				patch_text = patch.read_text(encoding="utf-8")
				expected_from = f"--- a/tests/unit/src/unitstd/{entry['source']}"
				expected_to = f"+++ b/{entry['fixture']}"
				if expected_from not in patch_text.splitlines()[:2] or expected_to not in patch_text.splitlines()[:2]:
					raise ManifestError(f"{module} adaptation patch has incorrect source labels")
				redactions = entry.get("adaptationPatchRedactions", [])
				if redactions:
					if redactions != ["machine-local-user-path"] or entry["source"] != "haxe/io/Path.unit.hx":
						raise ManifestError(f"{module} has an unsupported adaptation patch redaction")
					if '<machine-local-user-path>' not in patch_text:
						raise ManifestError(f"{module} adaptation patch does not contain its declared redaction")

			shared_record = (
				entry.get("source"),
				entry.get("sourceSha256"),
				entry.get("fixtureKind"),
				entry.get("fixtureSha256"),
				entry.get("adaptationPatch"),
				entry.get("adaptationPatchSha256"),
				tuple(entry.get("adaptationPatchRedactions", [])),
			)
			fixture_key = fixture.resolve()
			previous_record = shared_fixtures.get(fixture_key)
			if previous_record is not None and previous_record != shared_record:
				raise ManifestError(f"{module} shares a fixture but has different source or adaptation records")
			shared_fixtures[fixture_key] = shared_record
		else:
			if not entry.get("reason"):
				raise ManifestError(f"{module} is not in the runtime suite but has no reason")
			for field in ("fixture", "fixtureKind", "fixtureSha256", "adaptationPatch", "adaptationPatchSha256", "adaptationPatchRedactions"):
				if field in entry:
					raise ManifestError(f"{module} is not in the runtime suite but records {field}")

	matrix_modules = core_matrix_modules(root)
	missing = sorted(set(matrix_modules) - set(by_module))
	stale = sorted(set(by_module) - set(matrix_modules))
	if missing:
		raise ManifestError("modules missing manifest decisions: " + ", ".join(missing))
	if stale:
		raise ManifestError("manifest entries not present in support matrix core set: " + ", ".join(stale))

	fixture_root = root / "test/upstream_unitstd/upstream"
	fixture_symlinks = sorted(path for path in fixture_root.rglob("*") if path.is_symlink())
	if fixture_symlinks:
		raise ManifestError(
			"symbolic links are not allowed in upstream fixtures: "
			+ ", ".join(path.relative_to(root).as_posix() for path in fixture_symlinks)
		)
	actual_fixtures = {path for path in fixture_root.rglob("*.hx") if path.is_file()}
	if actual_fixtures != expected_fixtures:
		untracked = sorted(path.relative_to(root).as_posix() for path in actual_fixtures - expected_fixtures)
		missing_files = sorted(path.relative_to(root).as_posix() for path in expected_fixtures - actual_fixtures)
		details = []
		if untracked:
			details.append("unclassified fixtures: " + ", ".join(untracked))
		if missing_files:
			details.append("missing fixtures: " + ", ".join(missing_files))
		raise ManifestError("; ".join(details))

	patch_root = root / "test/upstream_unitstd/adaptations"
	patch_symlinks = sorted(path for path in patch_root.rglob("*") if path.is_symlink()) if patch_root.exists() else []
	if patch_symlinks:
		raise ManifestError(
			"symbolic links are not allowed in adaptation patches: "
			+ ", ".join(path.relative_to(root).as_posix() for path in patch_symlinks)
		)
	actual_patches = {path for path in patch_root.rglob("*.patch") if path.is_file()} if patch_root.exists() else set()
	if actual_patches != expected_patches:
		untracked = sorted(path.relative_to(root).as_posix() for path in actual_patches - expected_patches)
		missing_files = sorted(path.relative_to(root).as_posix() for path in expected_patches - actual_patches)
		details = []
		if untracked:
			details.append("unclassified adaptation patches: " + ", ".join(untracked))
		if missing_files:
			details.append("missing adaptation patches: " + ", ".join(missing_files))
		raise ManifestError("; ".join(details))

	omissions = manifest.get("omittedUpstreamFixtures")
	if not isinstance(omissions, list) or len(omissions) != 1:
		raise ManifestError("manifest.omittedUpstreamFixtures must contain the reviewed Ssl.unit.hx omission")
	ssl = omissions[0]
	if not isinstance(ssl, dict) or ssl.get("source") != "Ssl.unit.hx":
		raise ManifestError("the reviewed omitted upstream fixture must be Ssl.unit.hx")
	if ssl.get("upstreamSpec") != "available" or ssl.get("disposition") != "not-applicable" or ssl.get("execution") != "not-run":
		raise ManifestError("Ssl.unit.hx must remain available, not applicable, and outside the runtime suite")
	require_hash(ssl.get("sourceSha256"), field="Ssl.unit.hx.sourceSha256")
	if "cpp or Neko" not in str(ssl.get("reason", "")) or "no BEAM SSL evidence" not in str(ssl.get("reason", "")):
		raise ManifestError("Ssl.unit.hx must explain its target condition and lack of BEAM SSL evidence")

	return {
		"modules": len(entries),
		"runtimeEntries": runtime_entries,
		"uniqueFixtures": len(expected_fixtures),
		"adaptedEntries": adapted_entries,
		"adaptationPatches": len(expected_patches),
	}


def main() -> None:
	try:
		summary = validate_manifest()
	except (ManifestError, json.JSONDecodeError, OSError) as error:
		print(f"upstream-unitstd manifest guard failed: {error}", file=sys.stderr)
		sys.exit(1)
	print(
		"upstream-unitstd manifest guard passed "
		f"({summary['modules']} modules, {summary['runtimeEntries']} runtime entries, "
		f"{summary['uniqueFixtures']} files, {summary['adaptationPatches']} adaptation patches)"
	)


if __name__ == "__main__":
	main()
