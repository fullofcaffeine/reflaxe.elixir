#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
FIXTURE_DIR="$ROOT_DIR/test/snapshot/negative/result_contract_invariant"
LOG_FILE="$(mktemp "${TMPDIR:-/tmp}/reflaxe-result-invariant.XXXXXX")"

cleanup() {
  rm -f "$LOG_FILE"
  rm -rf "$FIXTURE_DIR/out"
}
trap cleanup EXIT

if "$ROOT_DIR/scripts/with-timeout.sh" --secs 120 --cwd "$FIXTURE_DIR" -- \
  haxe compile.hxml >"$LOG_FILE" 2>&1; then
  echo "[result-invariant] expected the mutation fixture to fail compilation" >&2
  exit 1
fi

EXPECTED_PHASE='phase "LocalAssignUnusedUnderscore_Scoped_Final"'
EXPECTED_FUNCTION='Main.invariant_target/0'

if ! grep -Fq "$EXPECTED_PHASE" "$LOG_FILE"; then
  echo "[result-invariant] diagnostic did not name the responsible phase" >&2
  tail -n 80 "$LOG_FILE" >&2
  exit 1
fi

if ! grep -Fq "$EXPECTED_FUNCTION" "$LOG_FILE"; then
  echo "[result-invariant] diagnostic did not name the affected function" >&2
  tail -n 80 "$LOG_FILE" >&2
  exit 1
fi

echo "[result-invariant] mutation caught with phase and function diagnostics"
