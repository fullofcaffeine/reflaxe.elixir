#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
FIXTURE_DIR="$ROOT_DIR/test/snapshot/negative/shared_array_alias_length_after_push"
LOG_FILE="$(mktemp "${TMPDIR:-/tmp}/reflaxe-reference-diagnostic.XXXXXX")"

cleanup() {
  rm -f "$LOG_FILE"
  rm -rf "$FIXTURE_DIR/out"
}
trap cleanup EXIT

EXPECTED_LINE="$(cat "$FIXTURE_DIR/expected_stderr.txt")"

run_case() {
  local label="$1"
  shift
  : >"$LOG_FILE"

  if "$ROOT_DIR/scripts/with-timeout.sh" --secs 120 --cwd "$FIXTURE_DIR" -- \
    haxe "$@" compile.hxml >"$LOG_FILE" 2>&1; then
    echo "[reference-diagnostic] expected the stale Array alias fixture to fail in $label" >&2
    exit 1
  fi

  if ! grep -Fqx "$EXPECTED_LINE" "$LOG_FILE"; then
    echo "[reference-diagnostic] compiler did not report the exact expected source diagnostic in $label" >&2
    tail -n 80 "$LOG_FILE" >&2
    exit 1
  fi
}

run_case "the default compiler profile"
run_case "strict mode" -D reflaxe_elixir_strict
run_case "the full-prepasses profile" -D full_prepasses

echo "[reference-diagnostic] exact shared Array alias diagnostic observed in all compiler profiles"
