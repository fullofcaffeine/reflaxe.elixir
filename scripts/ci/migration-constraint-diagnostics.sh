#!/usr/bin/env bash
set -euo pipefail

# A failed process alone does not prove rejection of an invalid migration.
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fixture_root="$ROOT_DIR/test/snapshot/negative/ecto"
diagnostic_tmp="$(mktemp -d "${TMPDIR:-/tmp}/migration-diagnostics.XXXXXX")"
trap 'rm -rf "$diagnostic_tmp"' EXIT
haxe_bin="${HAXE_BIN:-haxe}"

for name in migration_constraint_empty_table migration_constraint_empty_name migration_constraint_dynamic_check migration_execute_dynamic migration_execute_concat reference_wrong_default reference_duplicate_pair reference_dynamic_pair reference_empty_pairs reference_conflicting_type; do
  fixture="$fixture_root/$name"
  log="$diagnostic_tmp/$name.log"
  output="$diagnostic_tmp/$name-output"
  expected="$(cat "$fixture/expected_message.txt")"
  status=0
  "$ROOT_DIR/scripts/with-timeout.sh" --secs 300 --cwd "$fixture" -- \
    "$haxe_bin" compile.hxml -D "elixir_output=$output" >"$log" 2>&1 || status=$?

  # Haxe reports a compilation diagnostic with status 1. Timeout (124),
  # signal, missing executable, and successful compilation are not evidence.
  if [[ "$status" != 1 ]] || [[ -z "$expected" ]] || ! grep -Fq -- "$expected" "$log"; then
    echo "Expected migration diagnostic for $name; compiler status was $status" >&2
    tail -n 80 "$log" >&2
    exit 1
  fi
  if [[ -d "$output" ]] && [[ -n "$(find "$output" -type f -name '*.exs' -print -quit)" ]]; then
    echo "Rejected migration $name still emitted a migration script" >&2
    exit 1
  fi
  echo "[migration-diagnostics] $name rejected with the expected diagnostic"
done
