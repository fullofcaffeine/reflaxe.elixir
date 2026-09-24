#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
contract_tmp="$(mktemp -d "${TMPDIR:-/tmp}/migration-diagnostic-contract.XXXXXX")"
trap 'rm -rf "$contract_tmp"' EXIT

# This double tests the observer, not Haxe's migration behavior.
cat >"$contract_tmp/haxe" <<'FAKE_HAXE'
#!/usr/bin/env bash
set -euo pipefail
case "${PWD##*/}" in
  migration_constraint_empty_table|migration_constraint_empty_name)
    message='Constraint table and name must be non-empty string literals.' ;;
  migration_constraint_dynamic_check)
    message='addCheckConstraint expects string literal name and expression.' ;;
  migration_execute_dynamic|migration_execute_concat)
    message='Migration execute expects one SQL string literal in ecto_migrations_exs builds.' ;;
  *) exit 99 ;;
esac
case "$DIAGNOSTIC_CONTRACT_MODE" in
  wrong-message) message='Unrelated compiler error' ;;
  emitted-script)
    for argument in "$@"; do
      case "$argument" in
        elixir_output=*)
          output="${argument#elixir_output=}"
          mkdir -p "$output"
          printf 'defmodule UnexpectedMigration do\nend\n' >"$output/unexpected.exs" ;;
      esac
    done ;;
esac
printf '%s\n' "$message" >&2
case "$DIAGNOSTIC_CONTRACT_MODE" in
  success) exit 0 ;;
  timeout) exit 124 ;;
  crash) exit 137 ;;
  missing-command) exit 127 ;;
  *) exit 1 ;;
esac
FAKE_HAXE
chmod +x "$contract_tmp/haxe"

for mode in expected wrong-message success timeout crash missing-command emitted-script; do
  status=0
  HAXE_BIN="$contract_tmp/haxe" DIAGNOSTIC_CONTRACT_MODE="$mode" \
    bash "$ROOT_DIR/scripts/ci/migration-constraint-diagnostics.sh" >"$contract_tmp/$mode.log" 2>&1 || status=$?
  if [[ "$mode" == expected ]]; then
    if [[ "$status" != 0 ]] || [[ "$(grep -c 'rejected with the expected diagnostic' "$contract_tmp/$mode.log")" != 5 ]]; then
      cat "$contract_tmp/$mode.log" >&2
      echo "Diagnostic observer rejected its valid control" >&2
      exit 1
    fi
  elif [[ "$status" != 1 ]]; then
    cat "$contract_tmp/$mode.log" >&2
    echo "Diagnostic observer did not reject $mode with status 1" >&2
    exit 1
  fi
done
echo '[migration-diagnostics-contract] valid control and six false-pass cases verified'
