#!/usr/bin/env bash
set -euo pipefail

# Fails if disabled debug code is checked in (e.g. commented-out trace lines).
# Keep debug instrumentation behind compile-time flags instead of “DISABLED:” comments.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

if ! command -v rg >/dev/null 2>&1; then
  echo "[guard:no-disabled-debug] ERROR: ripgrep (rg) is required" >&2
  exit 2
fi

pattern='^\s*//\s*DISABLED:\s*'

hits="$(rg -n --glob '*.hx' "$pattern" "$ROOT_DIR/src" "$ROOT_DIR/std" "$ROOT_DIR/tools" 2>/dev/null || true)"

if [[ -n "$hits" ]]; then
  echo "[guard:no-disabled-debug] FAILED: found disabled debug comments:" >&2
  echo "$hits" >&2
  exit 1
fi

echo "[guard:no-disabled-debug] OK: no disabled debug comments found."

