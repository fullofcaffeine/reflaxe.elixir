#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="$ROOT/test/upstream_unitstd/manifest.json"
REFERENCE_ROOT="${HAXE_ELIXIR_UNITSTD_REFERENCE:-${HAXE_ELIXIR_REFERENCE:-$ROOT/../haxe.compilerdev.reference/haxe/tests/unit/src/unitstd}}"

if [[ ! -d "$REFERENCE_ROOT" ]]; then
  cat >&2 <<MSG
Missing upstream unitstd reference: $REFERENCE_ROOT

Set HAXE_ELIXIR_UNITSTD_REFERENCE to a Haxe checkout's tests/unit/src/unitstd
directory, or keep ../haxe.compilerdev.reference checked out next to this repo.
MSG
  exit 1
fi

python3 - "$ROOT" "$MANIFEST" "$REFERENCE_ROOT" <<'PY'
import json
import shutil
import sys
from pathlib import Path

root = Path(sys.argv[1])
manifest_path = Path(sys.argv[2])
reference_root = Path(sys.argv[3])
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))

copied = 0
for entry in manifest["modules"]:
    if entry["status"] != "enabled":
        continue

    source = reference_root / entry["source"]
    fixture = root / entry["fixture"]
    if not source.exists():
        raise SystemExit(f"Missing upstream source for {entry['module']}: {source}")

    fixture.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(source, fixture)
    copied += 1
    print(f"synced {entry['module']}: {entry['source']} -> {entry['fixture']}")

print(f"synced {copied} upstream unitstd fixture(s)")
PY
