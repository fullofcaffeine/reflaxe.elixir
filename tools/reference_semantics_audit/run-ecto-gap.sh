#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FIXTURE="$ROOT/examples/06-user-management"
PROBE="$ROOT/tools/reference_semantics_audit/ecto_schema_constructor_gap.exs"

cd "$FIXTURE"
"$ROOT/scripts/with-timeout.sh" --secs 120 -- \
  env HAXE_NO_COMPILE=1 MIX_ENV=test mix run --no-start --no-compile "$PROBE"
