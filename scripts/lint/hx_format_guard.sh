#!/usr/bin/env bash
set -euo pipefail

if ! command -v haxelib >/dev/null 2>&1; then
  echo "[guard:hx-format] ERROR: haxelib is required." >&2
  exit 1
fi

if ! haxelib run formatter --help >/dev/null 2>&1; then
  echo "[guard:hx-format] ERROR: formatter haxelib is not installed." >&2
  echo "[guard:hx-format] Install it with: haxelib install formatter" >&2
  exit 1
fi

echo "[guard:hx-format] Checking Haxe formatting..."
test_sources=()
while IFS= read -r source; do
  test_sources+=("-s" "$source")
done < <(find test -name '*.hx' -not -path 'test/upstream_unitstd/upstream/*' | sort)

haxelib run formatter -s src -s std -s examples -s tooling "${test_sources[@]}" --check
echo "[guard:hx-format] OK: Haxe formatting is clean."
