#!/usr/bin/env bash
set -euo pipefail

# Guard: Disallow numeric-suffixed identifiers in compiler sources
# Rationale: Numeric suffixes (e.g., foo2, helper3) obscure intent and violate naming rules.

TARGET_DIR='src/reflaxe/elixir'

echo "[guard:numeric] Scanning ${TARGET_DIR} for numeric‑suffixed identifiers..."

# Build a combined regex to catch common declaration forms:
#  - var|final declarations
#  - function names
#  - function parameters (name: Type)
DECL_PATTERN='\b(var|final|function)\s+[A-Za-z_][A-Za-z0-9_]*[0-9]+\b'
PARAM_PATTERN='function[^\(]*\([^)]*[A-Za-z_][A-Za-z0-9_]*[0-9]+\s*:'

found=0

if command -v rg >/dev/null 2>&1; then
  if rg -n -e "${DECL_PATTERN}" -e "${PARAM_PATTERN}" "${TARGET_DIR}" --no-heading --hidden --glob '!**/docs/**' --glob '!**/test/**' ; then
    found=1
  fi
else
  # Fallback to grep with basic recursion; may produce more false positives
  if grep -RInE "${DECL_PATTERN}|${PARAM_PATTERN}" "${TARGET_DIR}" --exclude-dir=docs --exclude-dir=test ; then
    found=1
  fi
fi

if [[ "$found" -ne 0 ]]; then
  echo "[guard:numeric] ERROR: Numeric‑suffixed identifiers found in compiler sources." >&2
  echo "[guard:numeric] Hint: Rename variables/functions/params to descriptive names without numeric suffixes." >&2
  exit 1
fi

echo "[guard:numeric] OK: No numeric‑suffixed identifiers found."

