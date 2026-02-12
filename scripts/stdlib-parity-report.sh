#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

JSON=0
MARKDOWN=0
REFERENCE_PATH=""

say() {
  if [[ "$JSON" -eq 1 || "$MARKDOWN" -eq 1 ]]; then
    echo "[stdlib-parity] $*" >&2
  else
    echo "[stdlib-parity] $*"
  fi
}

usage() {
  cat >&2 <<'EOF'
Usage: scripts/stdlib-parity-report.sh --reference PATH [--json|--markdown]

Compares this repo's stdlib overrides (Elixir-target Haxe std) against a reference Haxe stdlib.

The report focuses on the Haxe standard library namespaces:
  - top-level modules (e.g. Array, Date, EReg, Sys, Type, ...)
  - haxe/** modules
  - sys/** modules

Options:
  --reference PATH   Path to a reference stdlib. Accepts:
                     - /path/to/haxe/std
                     - /path/to/haxe-repo (containing haxe/std)
                     - /path/to/haxe (containing std/)
                     If omitted, falls back to env vars:
                     - HAXE_ELIXIR_REFERENCE
                     - HAXE_ELIXIR_REFERENCE_PATH (legacy)
  --json             Emit machine-readable JSON to stdout (default: human-readable text)
  --markdown         Emit markdown summary to stdout (for docs)
  -h, --help         Show this help

Examples:
  export HAXE_ELIXIR_REFERENCE=/path/to/haxe.elixir.reference
  scripts/stdlib-parity-report.sh --json
  scripts/stdlib-parity-report.sh --markdown
  scripts/stdlib-parity-report.sh --reference /path/to/haxe.elixir.reference/haxe/std
EOF
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --reference) REFERENCE_PATH="$2"; shift 2 ;;
    --json) JSON=1; shift 1 ;;
    --markdown) MARKDOWN=1; shift 1 ;;
    -h|--help) usage ;;
    *) usage ;;
  esac
done

if [[ -z "$REFERENCE_PATH" ]]; then
  REFERENCE_PATH="${HAXE_ELIXIR_REFERENCE:-${HAXE_ELIXIR_REFERENCE_PATH:-}}"
fi

if [[ -z "$REFERENCE_PATH" ]]; then
  echo "ERROR: Missing reference path." >&2
  echo "Set HAXE_ELIXIR_REFERENCE or pass --reference PATH." >&2
  usage
fi

if [[ "$JSON" -eq 1 && "$MARKDOWN" -eq 1 ]]; then
  echo "ERROR: --json and --markdown are mutually exclusive" >&2
  usage
fi

cd "$ROOT_DIR"

say "Repo: $ROOT_DIR"
say "Reference input: $REFERENCE_PATH"

python3 - "$ROOT_DIR" "$REFERENCE_PATH" "$JSON" "$MARKDOWN" <<'PY'
import json
import os
import sys
import datetime
from pathlib import Path
from typing import Dict, List, Set

root_dir = Path(sys.argv[1])
reference_input = Path(sys.argv[2])
json_mode = int(sys.argv[3]) == 1
markdown_mode = int(sys.argv[4]) == 1

def resolve_reference_std(path: Path) -> Path:
  candidates = []
  candidates.append(path)
  candidates.append(path / "std")
  candidates.append(path / "haxe" / "std")
  # If user pointed at ".../haxe", try its std/ directly.
  if path.name == "haxe":
    candidates.append(path / "std")

  for candidate in candidates:
    if (candidate / "Std.hx").exists() or (candidate / "Array.hx").exists():
      return candidate
  raise SystemExit(
    "ERROR: Could not locate reference stdlib. Expected Std.hx under one of: "
    f"{', '.join(str(c) for c in candidates)}"
  )

def module_id_from_relpath(rel: Path) -> str:
  # Normalize .cross.hx -> .hx module id.
  name = rel.as_posix()
  if name.endswith(".cross.hx"):
    name = name[: -len(".cross.hx")]
  elif name.endswith(".hx"):
    name = name[: -len(".hx")]
  else:
    raise ValueError(f"Unexpected path (not .hx/.cross.hx): {rel}")
  return name.replace("/", ".")

def collect_std_modules(std_root: Path, allow_cross: bool) -> Set[str]:
  modules: Set[str] = set()
  suffixes = [".hx"] + ([".cross.hx"] if allow_cross else [])

  for file in std_root.rglob("*"):
    if not file.is_file():
      continue
    if not any(str(file).endswith(suf) for suf in suffixes):
      continue

    rel = file.relative_to(std_root)
    # Only consider Haxe std namespaces: top-level, haxe/**, sys/**.
    if rel.parts[0] not in ("haxe", "sys") and len(rel.parts) != 1:
      continue
    modules.add(module_id_from_relpath(rel))

  return modules

def collect_prefixed_modules(prefix: str, root: Path, allow_cross: bool) -> Set[str]:
  """
  Collect modules from a subtree that is *not* laid out like std/ itself.

  Example:
    root_dir/src/haxe/Exception.cross.hx should be reported as `haxe.Exception`.

  This is needed because consumer installs always have the library `src/` classpath
  immediately, while `std/` is injected later via bootstrap macros.
  """
  modules: Set[str] = set()
  if not root.exists():
    return modules

  suffixes = [".hx"] + ([".cross.hx"] if allow_cross else [])
  for file in root.rglob("*"):
    if not file.is_file():
      continue
    if not any(str(file).endswith(suf) for suf in suffixes):
      continue
    rel = file.relative_to(root)
    modules.add(prefix + "." + module_id_from_relpath(rel))
  return modules

reference_std = resolve_reference_std(reference_input)

reference_modules = collect_std_modules(reference_std, allow_cross=False)

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

# Focus “coverage” on modules that are actually part of the reference stdlib, plus
# any haxe.* / sys.* modules we ship (useful for parity planning).
local_std_modules = set()
local_nonstdlib_modules = set()
for module in local_candidates:
  if module in reference_modules or module.startswith("haxe.") or module.startswith("sys."):
    local_std_modules.add(module)
  else:
    local_nonstdlib_modules.add(module)

runtime_overrides_declared = {
  # Implemented via compiler-emitted native runtime shims (not Haxe std override files).
  # See: src/reflaxe/elixir/ast/transformers/StdHaxeRuntimeOverrideTransforms.hx
  "EReg",
  "haxe.exceptions.PosException",
  "haxe.iterators.ArrayIterator",
}
runtime_overrides_present = sorted([m for m in runtime_overrides_declared if m in reference_modules])
for module in runtime_overrides_present:
  local_std_modules.add(module)

intersection = sorted(reference_modules & local_std_modules)
reference_only = sorted(reference_modules - local_std_modules)
local_only = sorted(local_std_modules - reference_modules)

def group_by_prefix(modules: List[str]) -> Dict[str, int]:
  counts: Dict[str, int] = {"<top-level>": 0, "haxe": 0, "sys": 0}
  for module in modules:
    if "." not in module:
      counts["<top-level>"] += 1
    elif module.startswith("haxe."):
      counts["haxe"] += 1
    elif module.startswith("sys."):
      counts["sys"] += 1
    else:
      counts.setdefault("other", 0)
      counts["other"] += 1
  return counts

report = {
  "reference": {
    "std_root": "$HAXE_ELIXIR_REFERENCE/haxe/std",
    "total_modules": len(reference_modules),
    "counts_by_prefix": group_by_prefix(list(reference_modules)),
  },
  "local": {
    "stdlib_roots_considered": [
      rel
      for rel, path in [
        ("std", local_std_root),
        ("std/_std", local_std_shadow_root),
        ("src/haxe", local_src_haxe_root),
        ("src/sys", local_src_sys_root),
      ]
      if path.exists()
    ],
    "total_candidates": len(local_candidates),
    "total_std_modules": len(local_std_modules),
    "counts_by_prefix": group_by_prefix(list(local_std_modules)),
    "nonstdlib_modules_under_std_dir": sorted(local_nonstdlib_modules),
    "runtime_overrides": {
      "declared": sorted(runtime_overrides_declared),
      "counted_as_present": runtime_overrides_present,
    },
  },
  "diff": {
    "intersection": {"count": len(intersection), "modules": intersection},
    "reference_only": {"count": len(reference_only), "modules": reference_only},
    "local_only": {"count": len(local_only), "modules": local_only},
  },
}

if json_mode:
  print(json.dumps(report, indent=2, sort_keys=True))
elif markdown_mode:
  print("# Stdlib Parity Gap Report (Module-Level)")
  print("")
  print(f"Generated: {datetime.date.today().isoformat()}")
  print("")
  print("This report compares this repo’s Elixir-target stdlib overrides against the reference repository.")
  print("")
  print("Local roots considered:")
  for root in report["local"]["stdlib_roots_considered"]:
    print(f"- `{root}`")
  print("")
  print("To regenerate:")
  print("")
  print("```bash")
  print("export HAXE_ELIXIR_REFERENCE=/path/to/haxe.elixir.reference")
  print("scripts/stdlib-parity-report.sh --json > docs/08-roadmap/stdlib-parity/gap-report.json")
  print("scripts/stdlib-parity-report.sh --markdown > docs/08-roadmap/stdlib-parity/gap-report.md")
  print("```")
  print("")
  print("## Summary")
  print("")
  print(f"- Reference std modules: **{report['reference']['total_modules']}**")
  print(f"- Local std modules present: **{report['local']['total_std_modules']}** (candidates scanned: {report['local']['total_candidates']})")
  print(f"- Intersection (local provides): **{report['diff']['intersection']['count']}**")
  print(f"- Missing locally (reference-only): **{report['diff']['reference_only']['count']}**")
  print(f"- Local-only: **{report['diff']['local_only']['count']}**")
  print("")
  print("## Missing modules (high-level)")
  missing = report['diff']['reference_only']['modules']
  top = [m for m in missing if '.' not in m]
  haxe_mods = [m for m in missing if m.startswith('haxe.')]
  sys_mods = [m for m in missing if m.startswith('sys.')]

  def highlight(modules: List[str], candidates: List[str]) -> List[str]:
    return [m for m in candidates if m in modules]
  if top:
    print(f"Top-level ({len(top)}): `" + "`, `".join(top) + "`")
    print("")
  haxe_high = highlight(haxe_mods, [
    "haxe.CallStack",
    "haxe.Http",
    "haxe.Int64",
    "haxe.Serializer",
    "haxe.Template",
  ])
  sys_high = highlight(sys_mods, [
    "sys.io.Process",
    "sys.net.Socket",
    "sys.net.UdpSocket",
    "sys.ssl.Socket",
  ])

  haxe_hint = (" including `" + "`, `".join(haxe_high) + "`") if haxe_high else ""
  sys_hint = (" including `" + "`, `".join(sys_high) + "`") if sys_high else ""
  print(f"`haxe.*` ({len(haxe_mods)}): heavy gaps{haxe_hint}.")
  print(f"`sys.*` ({len(sys_mods)}): gaps across IO/process/network/threading{sys_hint}.")
  print("")
  if report['local']['runtime_overrides']['counted_as_present']:
    print("Note: This report counts the compiler-emitted runtime overrides as “present”: `" + "`, `".join(report['local']['runtime_overrides']['counted_as_present']) + "`.")
else:
  def header(title: str) -> None:
    print("")
    print(f"== {title} ==")

  print(f"[stdlib-parity] Reference std root: {report['reference']['std_root']}")
  print(f"[stdlib-parity] Reference modules: {report['reference']['total_modules']}")
  print(f"[stdlib-parity] Local std modules: {report['local']['total_std_modules']} (candidates scanned: {report['local']['total_candidates']})")

  header("Counts by prefix (reference)")
  for key, value in report["reference"]["counts_by_prefix"].items():
    print(f"- {key}: {value}")

  header("Counts by prefix (local std modules)")
  for key, value in report["local"]["counts_by_prefix"].items():
    print(f"- {key}: {value}")

  header("Coverage summary")
  print(f"- Intersection (local provides): {report['diff']['intersection']['count']}")
  print(f"- Reference-only (missing locally): {report['diff']['reference_only']['count']}")
  print(f"- Local-only (not in reference): {report['diff']['local_only']['count']}")

  header("Next steps suggestion")
  print("- Start with sys.* gaps (ports/files/network) and haxe.io gaps (BytesBuffer/Input/Output).")
  print("- Use this report as an input to a bd epic for stdlib parity work.")
PY
