#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REPORT_JSON="${ROOT_DIR}/docs/08-roadmap/stdlib-parity/gap-report.json"
REPORT_MD="${ROOT_DIR}/docs/08-roadmap/stdlib-parity/gap-report.md"

if [[ ! -f "${REPORT_JSON}" ]]; then
  echo "[guard:stdlib-parity] ERROR: Missing report JSON: ${REPORT_JSON}" >&2
  exit 1
fi

if [[ ! -f "${REPORT_MD}" ]]; then
  echo "[guard:stdlib-parity] ERROR: Missing report markdown: ${REPORT_MD}" >&2
  exit 1
fi

python3 - "$ROOT_DIR" "$REPORT_JSON" "$REPORT_MD" <<'PY'
import json
import re
import sys
from pathlib import Path

root_dir = Path(sys.argv[1])
report_json_path = Path(sys.argv[2])
report_md_path = Path(sys.argv[3])


def module_id_from_relpath(rel: Path) -> str:
    name = rel.as_posix()
    if name.endswith(".cross.hx"):
        name = name[: -len(".cross.hx")]
    elif name.endswith(".hx"):
        name = name[: -len(".hx")]
    else:
        raise ValueError(f"Unexpected path suffix: {rel}")
    return name.replace("/", ".")


def collect_std_modules(std_root: Path, allow_cross: bool):
    modules = set()
    suffixes = [".hx"] + ([".cross.hx"] if allow_cross else [])

    for file in std_root.rglob("*"):
        if not file.is_file():
            continue
        if not any(str(file).endswith(suffix) for suffix in suffixes):
            continue

        rel = file.relative_to(std_root)
        if rel.parts[0] not in ("haxe", "sys") and len(rel.parts) != 1:
            continue
        modules.add(module_id_from_relpath(rel))

    return modules


def collect_prefixed_modules(prefix: str, source_root: Path, allow_cross: bool):
    modules = set()
    if not source_root.exists():
        return modules

    suffixes = [".hx"] + ([".cross.hx"] if allow_cross else [])
    for file in source_root.rglob("*"):
        if not file.is_file():
            continue
        if not any(str(file).endswith(suffix) for suffix in suffixes):
            continue
        modules.add(prefix + "." + module_id_from_relpath(file.relative_to(source_root)))

    return modules


def group_by_prefix(modules):
    counts = {"<top-level>": 0, "haxe": 0, "sys": 0}
    for module in modules:
        if "." not in module:
            counts["<top-level>"] += 1
        elif module.startswith("haxe."):
            counts["haxe"] += 1
        elif module.startswith("sys."):
            counts["sys"] += 1
        else:
            counts["other"] = counts.get("other", 0) + 1
    return counts


def extract_md_int(markdown: str, pattern: str):
    match = re.search(pattern, markdown)
    if not match:
        return None
    return int(match.group(1))


report = json.loads(report_json_path.read_text(encoding="utf-8"))
markdown = report_md_path.read_text(encoding="utf-8")

expected_intersection = sorted(report["diff"]["intersection"]["modules"])
expected_reference_only = sorted(report["diff"]["reference_only"]["modules"])
expected_local_only = sorted(report["diff"]["local_only"]["modules"])
reference_modules = set(expected_intersection) | set(expected_reference_only)

local_std_root = root_dir / "std"
local_std_shadow_root = root_dir / "std" / "_std"
local_src_haxe_root = root_dir / "src" / "haxe"
local_src_sys_root = root_dir / "src" / "sys"

local_candidates = set()
if local_std_root.exists():
    local_candidates |= collect_std_modules(local_std_root, allow_cross=True)
if local_std_shadow_root.exists():
    local_candidates |= collect_std_modules(local_std_shadow_root, allow_cross=False)
local_candidates |= collect_prefixed_modules("haxe", local_src_haxe_root, allow_cross=True)
local_candidates |= collect_prefixed_modules("sys", local_src_sys_root, allow_cross=True)

local_std_modules = set()
local_nonstdlib_modules = set()
for module in local_candidates:
    if module in reference_modules or module.startswith("haxe.") or module.startswith("sys."):
        local_std_modules.add(module)
    else:
        local_nonstdlib_modules.add(module)

runtime_declared = set(report.get("local", {}).get("runtime_overrides", {}).get("declared", []))
runtime_present = sorted(runtime_declared & reference_modules)
for module in runtime_present:
    local_std_modules.add(module)

intersection = sorted(reference_modules & local_std_modules)
reference_only = sorted(reference_modules - local_std_modules)
local_only = sorted(local_std_modules - reference_modules)

errors = []

if intersection != expected_intersection:
    errors.append("`diff.intersection.modules` is stale.")
if reference_only != expected_reference_only:
    errors.append("`diff.reference_only.modules` is stale.")
if local_only != expected_local_only:
    errors.append("`diff.local_only.modules` is stale.")

if report["reference"]["total_modules"] != len(reference_modules):
    errors.append("`reference.total_modules` does not match module lists.")
if report["reference"]["counts_by_prefix"] != group_by_prefix(reference_modules):
    errors.append("`reference.counts_by_prefix` does not match module lists.")
if report["local"]["total_candidates"] != len(local_candidates):
    errors.append("`local.total_candidates` is stale.")
if report["local"]["total_std_modules"] != len(local_std_modules):
    errors.append("`local.total_std_modules` is stale.")
if report["local"]["counts_by_prefix"] != group_by_prefix(local_std_modules):
    errors.append("`local.counts_by_prefix` is stale.")
if sorted(report["local"].get("nonstdlib_modules_under_std_dir", [])) != sorted(local_nonstdlib_modules):
    errors.append("`local.nonstdlib_modules_under_std_dir` is stale.")
if sorted(report["local"]["runtime_overrides"].get("counted_as_present", [])) != runtime_present:
    errors.append("`local.runtime_overrides.counted_as_present` is stale.")

md_expectations = {
    "Reference std modules": (
        r"Reference std modules:\s+\*\*(\d+)\*\*",
        len(reference_modules),
    ),
    "Local std modules present": (
        r"Local std modules present:\s+\*\*(\d+)\*\*",
        len(local_std_modules),
    ),
    "Candidates scanned": (
        r"candidates scanned:\s+(\d+)",
        len(local_candidates),
    ),
    "Intersection": (
        r"Intersection \(local provides\):\s+\*\*(\d+)\*\*",
        len(intersection),
    ),
    "Missing locally": (
        r"Missing locally\s+\(reference-only\):\s+\*\*(\d+)\*\*",
        len(reference_only),
    ),
    "Local-only": (
        r"Local-only:\s+\*\*(\d+)\*\*",
        len(local_only),
    ),
}

for label, (pattern, expected_value) in md_expectations.items():
    value = extract_md_int(markdown, pattern)
    if value is None:
        errors.append(f"`gap-report.md` missing summary field: {label}.")
    elif value != expected_value:
        errors.append(f"`gap-report.md` has stale value for {label}: {value} (expected {expected_value}).")

if errors:
    print("[guard:stdlib-parity] FAILED:")
    for error in errors:
        print(f"  - {error}")
    print("")
    print("[guard:stdlib-parity] To regenerate (with local reference checkout):")
    print("  scripts/stdlib-parity-report.sh --reference ../haxe.elixir.reference --json > docs/08-roadmap/stdlib-parity/gap-report.json")
    print("  scripts/stdlib-parity-report.sh --reference ../haxe.elixir.reference --markdown > docs/08-roadmap/stdlib-parity/gap-report.md")
    sys.exit(1)

print("[guard:stdlib-parity] OK: gap-report.{json,md} are consistent with current local stdlib state.")
PY
