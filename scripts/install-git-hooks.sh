#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
HOOKS_DIR="$ROOT_DIR/.git/hooks"
SRC_PRE_COMMIT="$ROOT_DIR/scripts/hooks/pre-commit"
DEST_PRE_COMMIT="$HOOKS_DIR/pre-commit"

if [ ! -d "$ROOT_DIR/.git" ]; then
  echo "[hooks:install] ERROR: .git directory not found at $ROOT_DIR" >&2
  exit 1
fi

mkdir -p "$HOOKS_DIR"
cp "$SRC_PRE_COMMIT" "$DEST_PRE_COMMIT"
chmod +x "$DEST_PRE_COMMIT"

echo "[hooks:install] Installed pre-commit hook -> $DEST_PRE_COMMIT"

