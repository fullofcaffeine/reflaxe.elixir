#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
HOOKS_DIR="$ROOT_DIR/.git/hooks"
SRC_PRE_COMMIT="$ROOT_DIR/scripts/hooks/pre-commit"
DEST_PRE_COMMIT="$HOOKS_DIR/pre-commit"
DEST_CHAINED_PRE_COMMIT="$HOOKS_DIR/pre-commit.old"

is_bd_chained_pre_commit() {
  local hook_path="$1"

  if [ ! -f "$hook_path" ]; then
    return 1
  fi

  if ! grep -q "pre-commit.old" "$hook_path"; then
    return 1
  fi

  grep -Eq "bd sync --flush-only|bd hook pre-commit|beads pre-commit hook" "$hook_path"
}

if [ ! -d "$ROOT_DIR/.git" ]; then
  echo "[hooks:install] ERROR: .git directory not found at $ROOT_DIR" >&2
  exit 1
fi

mkdir -p "$HOOKS_DIR"

if is_bd_chained_pre_commit "$DEST_PRE_COMMIT"; then
  cp "$SRC_PRE_COMMIT" "$DEST_CHAINED_PRE_COMMIT"
  chmod +x "$DEST_CHAINED_PRE_COMMIT"
  echo "[hooks:install] Detected bd chained pre-commit wrapper."
  echo "[hooks:install] Installed repo pre-commit hook -> $DEST_CHAINED_PRE_COMMIT"
else
  cp "$SRC_PRE_COMMIT" "$DEST_PRE_COMMIT"
  chmod +x "$DEST_PRE_COMMIT"
  echo "[hooks:install] Installed pre-commit hook -> $DEST_PRE_COMMIT"
fi
