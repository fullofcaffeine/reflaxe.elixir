#!/usr/bin/env bash
set -euo pipefail

# Fast Mix test entrypoint used by CI smoke jobs.
#
# This repo supports a minimum toolchain CI lane (OTP 25 / Elixir 1.14).
# `mix test --stale` was introduced after that baseline, so we must feature-detect
# it instead of unconditionally passing the flag.

export HAXE_NO_SERVER="${HAXE_NO_SERVER:-1}"
export MIX_ENV="${MIX_ENV:-test}"

mix local.hex --force
mix local.rebar --force

mix deps.get
mix deps.compile

supports_stale=0
help_file="$(mktemp "${TMPDIR:-/tmp}/mix-help-test.XXXXXX")"
cleanup() { rm -f "$help_file" 2>/dev/null || true; }
trap cleanup EXIT

if mix help test >"$help_file" 2>/dev/null; then
  if grep -Fq -- "--stale" "$help_file"; then
    supports_stale=1
  fi
fi

args=(--max-cases 1 --timeout 60000)
if [[ "$supports_stale" -eq 1 ]]; then
  args=(--stale "${args[@]}")
fi

mix test "${args[@]}"

