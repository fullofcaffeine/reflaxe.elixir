#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="$ROOT/test/upstream_unitstd/manifest.json"
REFERENCE_CHECKOUT="${HAXE_ELIXIR_REFERENCE:-$ROOT/../haxe.compilerdev.reference/haxe}"

if [[ ! -d "$REFERENCE_CHECKOUT/.git" ]]; then
	cat >&2 <<MSG
Missing official Haxe checkout: $REFERENCE_CHECKOUT

Set HAXE_ELIXIR_REFERENCE to a Git checkout of Haxe.
The checkout must use the exact commit in test/upstream_unitstd/manifest.json.
MSG
	exit 1
fi

python3 "$ROOT/scripts/ci/check-upstream-unitstd-manifest.py"

python3 - "$ROOT" "$MANIFEST" "$REFERENCE_CHECKOUT" <<'PY'
import hashlib
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

root = Path(sys.argv[1])
manifest_path = Path(sys.argv[2])
checkout = Path(sys.argv[3]).resolve()
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
upstream = manifest["upstream"]


def fail(message: str) -> None:
    raise SystemExit(f"upstream unitstd sync failed: {message}")


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def git_output(*arguments: str) -> str:
    result = subprocess.run(
        ["git", "-C", str(checkout), *arguments],
        text=True,
        capture_output=True,
        check=False,
    )
    if result.returncode != 0:
        fail(result.stderr.strip() or f"git {' '.join(arguments)} failed")
    return result.stdout.strip()


def adaptation_diff(source: Path, fixture: Path, fromfile: str, tofile: str) -> str:
    result = subprocess.run(
        ["git", "diff", "--no-index", "--no-ext-diff", "--no-color", "--", str(source), str(fixture)],
        text=True,
        capture_output=True,
        check=False,
    )
    if result.returncode not in (0, 1):
        fail(result.stderr.strip() or f"could not compare {source} and {fixture}")
    if result.returncode == 0:
        return ""

    lines = result.stdout.splitlines(keepends=True)
    try:
        header = next(index for index, line in enumerate(lines) if line.startswith("--- "))
    except StopIteration:
        fail(f"Git did not produce a unified patch for {source} and {fixture}")
    if header + 1 >= len(lines) or not lines[header + 1].startswith("+++ "):
        fail(f"Git produced incomplete patch labels for {source} and {fixture}")
    lines = lines[header:]
    lines[0] = f"--- {fromfile}\n"
    lines[1] = f"+++ {tofile}\n"
    for index, line in enumerate(lines[2:], start=2):
        if line.startswith("@@ "):
            section_end = line.find("@@", 3)
            if section_end >= 0:
                lines[index] = line[: section_end + 2] + "\n"
    return "".join(lines)


def apply_patch_redactions(entry: dict, patch_text: str) -> str:
    redactions = entry.get("adaptationPatchRedactions", [])
    if not redactions:
        return patch_text
    if redactions != ["machine-local-user-path"] or entry["source"] != "haxe/io/Path.unit.hx":
        fail(f"unsupported adaptation patch redaction for {entry['module']}")

    output = []
    replaced = False
    for line in patch_text.splitlines(keepends=True):
        if line.startswith('-haxe.io.Path.normalize("') and "\\\\Users/" in line:
            output.append('-haxe.io.Path.normalize("<machine-local-user-path>") == "<machine-local-user-path>";\n')
            replaced = True
        else:
            output.append(line)
    if not replaced:
        fail(f"machine-local path redaction did not match {entry['source']}")
    return "".join(output)


commit = git_output("rev-parse", "HEAD^{commit}")
if commit != upstream["commit"]:
    fail(f"checkout commit {commit} does not match manifest commit {upstream['commit']}")
if git_output("status", "--porcelain"):
    fail("official Haxe checkout has local changes")

license_path = checkout / upstream["license"]["path"]
if not license_path.is_file():
    fail(f"license file is missing: {upstream['license']['path']}")
if sha256(license_path) != upstream["license"]["sha256"]:
    fail(f"license hash changed: {upstream['license']['path']}")

reference_root = checkout / upstream["referenceRoot"]
if not reference_root.is_dir():
    fail(f"unitstd source directory is missing: {upstream['referenceRoot']}")
if reference_root.is_symlink():
    fail(f"unitstd source directory cannot be a symbolic link: {upstream['referenceRoot']}")
try:
    reference_root.resolve().relative_to(checkout)
except ValueError:
    fail(f"unitstd source directory leaves the official checkout: {upstream['referenceRoot']}")

def official_source(relative: str, label: str) -> Path:
    source = reference_root / relative
    current = reference_root
    for part in Path(relative).parts:
        current /= part
        if current.is_symlink():
            fail(f"official source cannot use a symbolic link for {label}: {relative}")
    try:
        source.resolve().relative_to(reference_root.resolve())
    except ValueError:
        fail(f"official source leaves the unitstd directory for {label}: {relative}")
    if not source.is_file():
        fail(f"official source is missing for {label}: {relative}")
    return source


runtime_entries = [entry for entry in manifest["modules"] if entry["execution"] == "runtime-suite"]
for entry in manifest["modules"]:
    if entry["upstreamSpec"] == "available":
        official_source(entry["source"], entry["module"])
        continue
    expected_relative = entry["module"].replace(".", "/") + ".unit.hx"
    expected_source = reference_root / expected_relative
    if expected_source.is_file():
        fail(
            f"new official source requires classification for {entry['module']}: "
            f"{expected_relative}"
        )

reviewed = set()
unchanged = []
for entry in runtime_entries:
    source = official_source(entry["source"], entry["module"])
    fixture = root / entry["fixture"]
    if sha256(source) != entry["sourceSha256"]:
        fail(f"official source hash changed for {entry['module']}: {entry['source']}")

    if entry["fixtureKind"] == "unchanged":
        unchanged.append((entry, source, fixture))
        continue

    fixture_key = fixture.resolve()
    if fixture_key in reviewed:
        continue
    reviewed.add(fixture_key)
    if not fixture.is_file():
        fail(f"adapted fixture is missing for {entry['module']}: {entry['fixture']}")
    if sha256(fixture) != entry["fixtureSha256"]:
        fail(f"adapted fixture hash changed for {entry['module']}: {entry['fixture']}")
    patch = root / entry["adaptationPatch"]
    if not patch.is_file() or sha256(patch) != entry["adaptationPatchSha256"]:
        fail(f"adaptation patch hash changed for {entry['module']}: {entry['adaptationPatch']}")

    expected_patch = adaptation_diff(
        source,
        fixture,
        f"a/{upstream['referenceRoot']}/{entry['source']}",
        f"b/{entry['fixture']}",
    )
    expected_patch = apply_patch_redactions(entry, expected_patch)
    if expected_patch and not expected_patch.endswith("\n"):
        expected_patch += "\n"
    if patch.read_text(encoding="utf-8") != expected_patch:
        fail(f"adaptation patch does not reproduce {entry['fixture']}")
    print(f"reviewed adapted {entry['module']}: {entry['adaptationPatch']}")

for omission in manifest["omittedUpstreamFixtures"]:
    source = official_source(omission["source"], "reviewed omission")
    if sha256(source) != omission["sourceSha256"]:
        fail(f"classified omitted source hash changed: {omission['source']}")
    print(f"reviewed omitted source: {omission['source']} ({omission['disposition']})")

for entry, source, fixture in unchanged:
    fixture.parent.mkdir(parents=True, exist_ok=True)
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(dir=fixture.parent, prefix=f".{fixture.name}.", delete=False) as output:
            temporary = Path(output.name)
            with source.open("rb") as source_file:
                shutil.copyfileobj(source_file, output)
            output.flush()
            os.fsync(output.fileno())
        if sha256(temporary) != entry["fixtureSha256"]:
            fail(f"refreshed fixture hash differs for {entry['module']}: {entry['fixture']}")
        shutil.copymode(source, temporary)
        os.replace(temporary, fixture)
        temporary = None
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)
    print(f"synced unchanged {entry['module']}: {entry['source']} -> {entry['fixture']}")

print(f"synced {len(unchanged)} unchanged entries and reviewed {len(reviewed)} adapted files")
PY

python3 "$ROOT/scripts/ci/check-upstream-unitstd-manifest.py"
