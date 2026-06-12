#!/usr/bin/env bash
set -euo pipefail

# Compile Haxe-authored stdlib parity tests to ExUnit and run only that runtime
# semantics lane. This is the focused harness command; `npm run test:mix-fast`
# and `npm test` also run the same generated tests as part of the broader suite.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TIMEOUT="${ROOT_DIR}/scripts/with-timeout.sh"

if [[ ! -x "${TIMEOUT}" ]]; then
  echo "[haxe-exunit-stdlib] ERROR: missing timeout wrapper: ${TIMEOUT}" >&2
  exit 2
fi

export HAXE_NO_SERVER="${HAXE_NO_SERVER:-1}"
export MIX_ENV="${MIX_ENV:-test}"

HEX_TIMEOUT_SECS="${HEX_TIMEOUT_SECS:-120}"
DEPS_TIMEOUT_SECS="${DEPS_TIMEOUT_SECS:-240}"
TEST_TIMEOUT_SECS="${TEST_TIMEOUT_SECS:-300}"

run_bounded() {
  local seconds="$1"
  shift
  "${TIMEOUT}" --secs "${seconds}" --cwd "${ROOT_DIR}" --echo -- "$@"
}

run_bounded "${HEX_TIMEOUT_SECS}" mix local.hex --if-missing --force
run_bounded "${HEX_TIMEOUT_SECS}" mix local.rebar --if-missing --force
run_bounded "${DEPS_TIMEOUT_SECS}" mix deps.get
run_bounded "${DEPS_TIMEOUT_SECS}" mix deps.compile

mix_args=(
  test
  test/exunit/haxe_exunit_stdlib_runtime_test.exs
  --max-cases
  1
  --timeout
  60000
  --trace
)

run_bounded "${TEST_TIMEOUT_SECS}" mix "${mix_args[@]}" "$@"
