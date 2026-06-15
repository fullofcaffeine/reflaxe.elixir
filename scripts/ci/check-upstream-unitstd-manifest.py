#!/usr/bin/env python3
"""Validate upstream unitstd runtime-conformance decisions.

The stdlib support matrix is the user-facing list of modules this target
implements or overrides. Every module in that core list must have an explicit
entry in test/upstream_unitstd/manifest.json so runtime-conformance coverage
does not silently drift behind stdlib work.
"""

import json
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
MATRIX = ROOT / "docs/04-api-reference/STDLIB_SUPPORT_MATRIX.md"
MANIFEST = ROOT / "test/upstream_unitstd/manifest.json"


def core_matrix_modules() -> list[str]:
    modules: list[str] = []
    in_core_set = False

    for line in MATRIX.read_text(encoding="utf-8").splitlines():
        if line.startswith("## Implemented/overridden by Reflaxe.Elixir"):
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


def fail(message: str) -> None:
    print(f"upstream-unitstd manifest guard failed: {message}", file=sys.stderr)
    sys.exit(1)


def main() -> None:
    if not MATRIX.exists():
        fail(f"support matrix not found: {MATRIX.relative_to(ROOT)}")
    if not MANIFEST.exists():
        fail(f"manifest not found: {MANIFEST.relative_to(ROOT)}")

    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    allowed_statuses = set(manifest.get("statusValues", []))
    if not allowed_statuses:
        fail("manifest.statusValues must not be empty")

    entries = manifest.get("modules", [])
    if not isinstance(entries, list):
        fail("manifest.modules must be a list")

    by_module: dict[str, dict] = {}
    duplicates: list[str] = []
    for entry in entries:
        module = entry.get("module")
        if not module:
            fail(f"manifest entry is missing module: {entry}")
        if module in by_module:
            duplicates.append(module)
        by_module[module] = entry

        status = entry.get("status")
        if status not in allowed_statuses:
            fail(f"{module} has invalid status {status!r}")

        if status in {"enabled", "adapted"}:
            fixture = entry.get("fixture")
            if not fixture:
                fail(f"{module} is {status} but has no fixture path")
            if not (ROOT / fixture).exists():
                fail(f"{module} fixture does not exist: {fixture}")
            if not entry.get("source"):
                fail(f"{module} is {status} but has no upstream source path")
        elif not entry.get("reason"):
            fail(f"{module} is {status} but has no reason")

    if duplicates:
        fail("duplicate module entries: " + ", ".join(sorted(duplicates)))

    matrix_modules = core_matrix_modules()
    missing = sorted(set(matrix_modules) - set(by_module))
    stale = sorted(set(by_module) - set(matrix_modules))

    if missing:
        fail("modules missing manifest decisions: " + ", ".join(missing))
    if stale:
        fail("manifest entries not present in support matrix core set: " + ", ".join(stale))

    print(f"upstream-unitstd manifest guard passed ({len(matrix_modules)} modules)")


if __name__ == "__main__":
    main()
