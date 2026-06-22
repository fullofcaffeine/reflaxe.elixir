#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
HOOKS_DIR="$ROOT_DIR/.git/hooks"
SRC_PRE_COMMIT="$ROOT_DIR/scripts/hooks/pre-commit"
DEST_PRE_COMMIT="$HOOKS_DIR/pre-commit"
DEST_CHAINED_PRE_COMMIT="$HOOKS_DIR/pre-commit.old"
DEST_LEGACY_BD_PRE_COMMIT="$HOOKS_DIR/pre-commit.bd-legacy"
BEADS_MARKER_BEGIN="# --- BEGIN BEADS INTEGRATION"
BEADS_MARKER_END="# --- END BEADS INTEGRATION"

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

is_legacy_bd_sync_pre_commit() {
  local hook_path="$1"

  if [ ! -f "$hook_path" ]; then
    return 1
  fi

  grep -q "bd sync --flush-only" "$hook_path"
}

has_modern_bd_integration() {
  local hook_path="$1"

  if [ ! -f "$hook_path" ]; then
    return 1
  fi

  grep -q "$BEADS_MARKER_BEGIN" "$hook_path"
}

install_repo_pre_commit() {
  local destination="$1"

  cp "$SRC_PRE_COMMIT" "$destination"
  chmod +x "$destination"
}

install_repo_pre_commit_preserving_bd() {
  local destination="$1"
  local temp_hook
  temp_hook="$(mktemp)"

  cp "$SRC_PRE_COMMIT" "$temp_hook"
  printf "\n" >> "$temp_hook"
  awk -v begin="$BEADS_MARKER_BEGIN" -v end="$BEADS_MARKER_END" '
    index($0, begin) == 1 { in_beads = 1 }
    in_beads { print }
    index($0, end) == 1 { in_beads = 0 }
  ' "$destination" >> "$temp_hook"
  mv "$temp_hook" "$destination"
  chmod +x "$destination"
}

if [ ! -d "$ROOT_DIR/.git" ]; then
  echo "[hooks:install] ERROR: .git directory not found at $ROOT_DIR" >&2
  exit 1
fi

mkdir -p "$HOOKS_DIR"

if is_legacy_bd_sync_pre_commit "$DEST_PRE_COMMIT"; then
  cp "$DEST_PRE_COMMIT" "$DEST_LEGACY_BD_PRE_COMMIT"
  install_repo_pre_commit "$DEST_PRE_COMMIT"
  echo "[hooks:install] Replaced legacy bd pre-commit wrapper."
  echo "[hooks:install] Saved previous wrapper -> $DEST_LEGACY_BD_PRE_COMMIT"
  echo "[hooks:install] Installed pre-commit hook -> $DEST_PRE_COMMIT"
elif has_modern_bd_integration "$DEST_PRE_COMMIT"; then
  install_repo_pre_commit_preserving_bd "$DEST_PRE_COMMIT"
  install_repo_pre_commit "$DEST_CHAINED_PRE_COMMIT"
  echo "[hooks:install] Updated pre-commit hook while preserving modern bd integration."
  echo "[hooks:install] Updated chained repo pre-commit hook -> $DEST_CHAINED_PRE_COMMIT"
  echo "[hooks:install] Installed pre-commit hook -> $DEST_PRE_COMMIT"
elif is_bd_chained_pre_commit "$DEST_PRE_COMMIT"; then
  install_repo_pre_commit "$DEST_CHAINED_PRE_COMMIT"
  echo "[hooks:install] Detected bd chained pre-commit wrapper."
  echo "[hooks:install] Installed repo pre-commit hook -> $DEST_CHAINED_PRE_COMMIT"
else
  install_repo_pre_commit "$DEST_PRE_COMMIT"
  echo "[hooks:install] Installed pre-commit hook -> $DEST_PRE_COMMIT"
fi
