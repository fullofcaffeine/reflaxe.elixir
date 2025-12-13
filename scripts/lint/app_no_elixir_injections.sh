#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)

matches="$(
  { rg -n "__elixir__\\(" "${ROOT_DIR}/examples/todo-app/src_haxe" || true; }
)"
violations=$(printf "%s" "$matches" | wc -l | tr -d ' ')
if [ "$violations" -gt 0 ]; then
  echo "ERROR: __elixir__() found in app Haxe sources (disallowed)." >&2
  printf "%s\n" "$matches" >&2
  exit 1
fi
echo "OK: No __elixir__() injections in app Haxe sources."
