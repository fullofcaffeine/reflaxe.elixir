#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)

# Disallow timing suffixes like (Final), (UltraFinal...), (AbsoluteFinal...)
echo "[Lint] Checking pass names for timing suffixes (Final/UltraFinal/AbsoluteFinal)"
if rg -n "name: \"[^\"]*\((?:Final|UltraFinal|AbsoluteFinal)[^\)]*\)\"" "$ROOT_DIR/src/reflaxe/elixir/ast/transformers/registry/ElixirASTPassRegistry.hx" >/dev/null; then
  echo "[Lint] ❌ Found timing suffixes in pass names. Please remove (Final/UltraFinal/AbsoluteFinal) from names." >&2
  rg -n "name: \"[^\"]*\((?:Final|UltraFinal|AbsoluteFinal)[^\)]*\)\"" "$ROOT_DIR/src/reflaxe/elixir/ast/transformers/registry/ElixirASTPassRegistry.hx" | sed -n '1,120p'
  exit 1
fi
echo "[Lint] OK: no timing suffixes found"

