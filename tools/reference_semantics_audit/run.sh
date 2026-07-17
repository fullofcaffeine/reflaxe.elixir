#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TIMEOUT="$ROOT/scripts/with-timeout.sh"
PROBE_CP="$ROOT/tools/reference_semantics_audit"

if [[ "$(haxe --version)" != "4.3.7" ]]; then
  echo "reference-semantics audit requires Haxe 4.3.7" >&2
  exit 1
fi

TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/reflaxe-elixir-reference-semantics.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT

"$TIMEOUT" --secs 60 -- haxe -cp "$PROBE_CP" -main Main --interp
"$TIMEOUT" --secs 60 -- haxe -cp "$PROBE_CP" -main Main -js "$TMP_DIR/probe.js"
"$TIMEOUT" --secs 60 -- node "$TMP_DIR/probe.js"
