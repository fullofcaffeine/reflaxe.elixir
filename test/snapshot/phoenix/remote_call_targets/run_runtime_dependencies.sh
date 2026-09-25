#!/usr/bin/env bash
set -euo pipefail

# Run after the minimal Phoenix example has compiled its locked dependencies.
# Reuse those real libraries; this fixture never supplies framework substitutes.
fixture_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
compiler_root="$(cd "$fixture_dir/../../../.." && pwd)"
beam_root="${1:-$compiler_root/examples/03-phoenix-app/_build/prod/lib}"
if [[ ! -d "$beam_root/phoenix/ebin" ]]; then
  echo "Compile examples/03-phoenix-app in MIX_ENV=prod before this runtime check." >&2
  exit 1
fi
export HAXE_NO_SERVER=1
export ERL_FLAGS="${ERL_FLAGS:-+S 2:2}"
beam_args=()
for directory in "$beam_root"/*/ebin; do
  beam_args+=(-pa "$directory")
done
for case_dir in "$fixture_dir" "$fixture_dir/../presence" "$fixture_dir/../presence_edge_cases" "$compiler_root/test/snapshot/regression/annotated_callback_retention"; do
  (
    cd "$case_dir"
    "$compiler_root/scripts/with-timeout.sh" --secs 120 -- "$compiler_root/node_modules/.bin/haxe" compile.hxml
    "$compiler_root/scripts/with-timeout.sh" --secs 60 -- elixir "${beam_args[@]}" runtime.exs out
  )
done
