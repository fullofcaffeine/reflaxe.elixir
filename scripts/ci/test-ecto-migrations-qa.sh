#!/usr/bin/env bash
set -euo pipefail

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/ecto-migrations-qa-contract.XXXXXX")
calls_file="$tmp_dir/calls"

cleanup() {
  rm -rf -- "$tmp_dir"
}
trap cleanup EXIT INT TERM

cat >"$tmp_dir/haxe" <<'FAKE_HAXE'
#!/usr/bin/env bash
set -euo pipefail
printf 'haxe %s\n' "$*" >>"$QA_FAKE_CALLS"
if [[ "${1:-}" == "build-migrations.hxml" ]]; then
  output_dir="$PWD/priv/repo/migrations"
  mkdir -p "$output_dir"
  : >"$output_dir/20240101120000_create_users.exs"
  : >"$output_dir/20240102120000_create_posts.exs"
fi
FAKE_HAXE

cat >"$tmp_dir/mix" <<'FAKE_MIX'
#!/usr/bin/env bash
set -euo pipefail
printf 'mix %s\n' "$*" >>"$QA_FAKE_CALLS"

if [[ "$*" == "run --no-start --no-compile qa/create_owned_database.exs" ]]; then
  if [[ "${QA_FAKE_MODE:-}" == "existing" ]]; then
    exit 66
  fi
  printf '%s\n' "$ECTO_MIGRATIONS_DATABASE" >"$ECTO_MIGRATIONS_OWNERSHIP_MARKER"
fi

if [[ "$*" == do\ app.start,\ ecto.migrate\ --quiet\ --migrations-path* ]]; then
  case "${QA_FAKE_MODE:-}" in
    migration_failure) exit 37 ;;
    wait_for_signal)
      trap 'exit 143' TERM
      trap 'exit 130' INT
      sleep 30 &
      wait $!
      ;;
  esac
fi

if [[ "$*" == "do app.start, ecto.drop --quiet" ]] \
  && [[ "${QA_FAKE_MODE:-}" == "cleanup_failure" ]]; then
  exit 41
fi
FAKE_MIX
chmod +x "$tmp_dir/haxe" "$tmp_dir/mix"

assert_drop_last() {
  if [[ $(tail -n 1 "$calls_file") != 'mix do app.start, ecto.drop --quiet' ]]; then
    echo "Database cleanup was not the final operation" >&2
    cat "$calls_file" >&2
    exit 1
  fi
}

run_direct() {
  local mode="$1"
  : >"$calls_file"
  set +e
  QA_FAKE_CALLS="$calls_file" \
    QA_FAKE_MODE="$mode" \
    QA_DATABASE_SUFFIX="contract_${mode}" \
    HAXE_BIN="$tmp_dir/haxe" \
    MIX_BIN="$tmp_dir/mix" \
    "$repo_root/examples/04-ecto-migrations/qa-runtime.sh"
  case_status=$?
  set -e
}

run_bounded() {
  local mode="$1"
  local seconds="$2"
  : >"$calls_file"
  set +e
  QA_FAKE_CALLS="$calls_file" \
    QA_FAKE_MODE="$mode" \
    QA_DATABASE_SUFFIX="contract_${mode}" \
    HAXE_BIN="$tmp_dir/haxe" \
    MIX_BIN="$tmp_dir/mix" \
    "$repo_root/scripts/with-timeout.sh" --secs "$seconds" --grace 10 -- \
      "$repo_root/examples/04-ecto-migrations/qa-runtime.sh"
  case_status=$?
  set -e
}

# The strict compiler must turn a warning in a freshly generated artifact into
# a failing check before any migration execution is attempted.
warning_dir="$tmp_dir/warning-migrations"
mkdir -p "$warning_dir"
cat >"$warning_dir/warning.exs" <<'WARNING_MIGRATION'
defmodule WarningMigration do
  def run do
    unused = :warning
    :ok
  end
end
WARNING_MIGRATION
set +e
ECTO_MIGRATIONS_PATH="$warning_dir" \
  elixir "$repo_root/examples/04-ecto-migrations/qa/strict_compile_migrations.exs" \
  >"$tmp_dir/warning.log" 2>&1
warning_status=$?
set -e
if (( warning_status == 0 )); then
  echo "Fresh migration warning unexpectedly passed strict compilation" >&2
  exit 1
fi

invalid_tmp="$tmp_dir/invalid-suffix-tmp"
mkdir -p "$invalid_tmp"
set +e
TMPDIR="$invalid_tmp" QA_DATABASE_SUFFIX='unsafe-suffix' \
  "$repo_root/examples/04-ecto-migrations/qa-runtime.sh" >/dev/null 2>&1
invalid_status=$?
set -e
if (( invalid_status != 64 )); then
  echo "Expected unsafe database suffix status 64, got $invalid_status" >&2
  exit 1
fi
if find "$invalid_tmp" -mindepth 1 -print -quit | grep -q .; then
  echo "Unsafe database suffix leaked a temporary workspace" >&2
  exit 1
fi

run_direct migration_failure
if (( case_status != 37 )); then
  echo "Expected migration failure status 37, got $case_status" >&2
  exit 1
fi
assert_drop_last

run_direct existing
if (( case_status != 66 )); then
  echo "Expected existing-storage status 66, got $case_status" >&2
  exit 1
fi
if grep -Fxq 'mix do app.start, ecto.drop --quiet' "$calls_file"; then
  echo "QA attempted to drop a database it did not create" >&2
  cat "$calls_file" >&2
  exit 1
fi

run_direct cleanup_failure
if (( case_status != 41 )); then
  echo "Expected cleanup failure status 41, got $case_status" >&2
  exit 1
fi
assert_drop_last

run_bounded wait_for_signal 1
if (( case_status != 124 )); then
  echo "Expected timeout status 124, got $case_status" >&2
  exit 1
fi
assert_drop_last

run_forwarded_signal() {
  local signal_name="$1"
  local expected_status="$2"
  : >"$calls_file"
  set +e
  QA_FAKE_CALLS="$calls_file" \
    QA_FAKE_MODE=wait_for_signal \
    QA_DATABASE_SUFFIX="contract_${signal_name}" \
    HAXE_BIN="$tmp_dir/haxe" \
    MIX_BIN="$tmp_dir/mix" \
    python3 -c \
      'import os,signal,sys; signal.signal(signal.SIGINT, signal.SIG_DFL); os.setpgrp(); os.execvp(sys.argv[1], sys.argv[1:])' \
      "$repo_root/scripts/with-timeout.sh" --secs 30 --grace 10 -- \
        "$repo_root/examples/04-ecto-migrations/qa-runtime.sh" &
  wrapper_pid=$!
  set -e

  for _ in $(seq 1 100); do
    if grep -q 'ecto.migrate' "$calls_file" 2>/dev/null; then
      break
    fi
    sleep 0.05
  done
  kill -s "$signal_name" "$wrapper_pid"
  set +e
  wait "$wrapper_pid"
  case_status=$?
  set -e

  if (( case_status != expected_status )); then
    echo "Expected $signal_name status $expected_status, got $case_status" >&2
    exit 1
  fi
  assert_drop_last
}

run_forwarded_signal TERM 143
run_forwarded_signal INT 130

echo "Ecto migration QA rejects warnings and unowned storage, preserves failures, and cleans up on failure, timeout, INT, and TERM."
