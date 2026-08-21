#!/usr/bin/env bash
set -euo pipefail

# Fast Mix test entrypoint used by CI smoke jobs.
#
# This repo supports a minimum toolchain CI lane (OTP 25 / Elixir 1.14).
# `mix test --stale` was introduced after that baseline, so we must feature-detect
# it instead of unconditionally passing the flag.

export HAXE_NO_SERVER="${HAXE_NO_SERVER:-1}"
export MIX_ENV="${MIX_ENV:-test}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GENERATED_DIR="${HAXE_EXUNIT_GENERATED_DIR:-${ROOT_DIR}/test/fixtures/_generated_haxe_exunit}"

prepare=1
run_tests=1
if (( $# > 1 )); then
  echo "Usage: scripts/test-mix-fast.sh [--prepare-only|--test-only]" >&2
  exit 2
fi
case "${1:-}" in
  "") ;;
  --prepare-only) run_tests=0 ;;
  --test-only) prepare=0 ;;
  *)
    echo "Usage: scripts/test-mix-fast.sh [--prepare-only|--test-only]" >&2
    exit 2
    ;;
esac

if (( prepare == 1 )); then
  mix local.hex --if-missing --force
  mix local.rebar --if-missing --force
  mix deps.get
  mix deps.compile
fi

if (( run_tests == 0 )); then
  exit 0
fi

mix compile --warnings-as-errors --no-deps-check

supports_stale=0
help_file="$(mktemp "${TMPDIR:-/tmp}/mix-help-test.XXXXXX")"
cleanup() { rm -f "$help_file" 2>/dev/null || true; }
trap cleanup EXIT

if mix help test >"$help_file" 2>/dev/null; then
  if grep -Fq -- "--stale" "$help_file"; then
    supports_stale=1
  fi
fi

args=(--warnings-as-errors --max-cases 1 --timeout 60000)
if [[ "$supports_stale" -eq 1 ]]; then
  args=(--stale "${args[@]}")
fi

mix test "${args[@]}"
bash "${ROOT_DIR}/scripts/ci/validate-generated-elixir-warnings.sh" "${GENERATED_DIR}"
