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
EXPECTED_MESSAGE="$(cat "$FIXTURE_DIR/expected_message.txt")"

run_case() {
  local label="$1"
  shift
  : >"$LOG_FILE"

  if "$ROOT_DIR/scripts/with-timeout.sh" --secs 120 --cwd "$FIXTURE_DIR" -- \
    haxe "$@" compile.hxml >"$LOG_FILE" 2>&1; then
    echo "[reference-diagnostic] expected the stale Array alias fixture to fail in $label" >&2
    exit 1
  fi

	local message_count
	message_count="$(grep -Fc "$EXPECTED_MESSAGE" "$LOG_FILE" || true)"
	if [[ "$message_count" -ne 1 ]]; then
		echo "[reference-diagnostic] expected one shared Array alias diagnostic in $label, found $message_count" >&2
		tail -n 80 "$LOG_FILE" >&2
		exit 1
	fi

	if [[ "$label" == "the default compiler profile" ]] && ! grep -Fqx "$EXPECTED_LINE" "$LOG_FILE"; then
		echo "[reference-diagnostic] compiler did not report the exact expected source diagnostic in $label" >&2
		tail -n 80 "$LOG_FILE" >&2
		exit 1
  fi
}

run_case "the default compiler profile"
run_case "strict mode" -D reflaxe_elixir_strict
run_case "the full-prepasses profile" -D full_prepasses
run_case "a constructor" -D constructor_case
run_case "class initialization" -D init_case
run_case "a consumed push result" -D used_push_result_case
run_case "an assigned push result" -D assigned_push_result_case
run_case "an independently scanned local function" -D nested_function_case
run_case "push through the alias" -D reverse_case
run_case "owned source below an exclusion-looking path" -D source_scope_case

echo "[reference-diagnostic] one exact shared Array alias diagnostic observed in all compiler profiles and source shapes"
