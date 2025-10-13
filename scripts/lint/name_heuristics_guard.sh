#!/usr/bin/env bash
set -euo pipefail

# Disallowed app-specific identifiers in compiler sources
PATTERN='(updated_todos|current_assigns|complete_assigns|load_todos|priority_color|checkmark|completed_class|text_decoration)'
TARGET_DIR='src/reflaxe/elixir'

echo "[guard:names] Scanning ${TARGET_DIR} for disallowed identifiers..."

if command -v rg >/dev/null 2>&1; then
  if rg -n -e "${PATTERN}" "${TARGET_DIR}" --no-heading --hidden --glob '!**/docs/**' --glob '!**/test/**' ; then
    echo "[guard:names] ERROR: Disallowed identifiers found in compiler sources." >&2
    exit 1
  fi
else
  if grep -RInE "${PATTERN}" "${TARGET_DIR}" --exclude-dir=docs --exclude-dir=test ; then
    echo "[guard:names] ERROR: Disallowed identifiers found in compiler sources." >&2
    exit 1
  fi
fi

echo "[guard:names] OK: No app-specific identifiers found."
