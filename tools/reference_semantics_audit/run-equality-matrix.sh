#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TIMEOUT="$ROOT/scripts/with-timeout.sh"
PROBE_CP="$ROOT/tools/reference_semantics_audit"

if [[ "$(haxe --version)" != "4.3.7" ]]; then
  echo "reference-semantics audit requires Haxe 4.3.7" >&2
  exit 1
fi

TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/reflaxe-elixir-equality-matrix.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "Haxe 4.3.7 interpreter:"
"$TIMEOUT" --secs 60 -- haxe -cp "$PROBE_CP" -main EqualityMatrix --interp

echo "Haxe 4.3.7 JavaScript target:"
"$TIMEOUT" --secs 60 -- haxe -cp "$PROBE_CP" -main EqualityMatrix -js "$TMP_DIR/equality.js"
"$TIMEOUT" --secs 60 -- node "$TMP_DIR/equality.js"

echo "Haxe 4.3.7 enum-argument equality diagnostic:"
set +e
"$TIMEOUT" --secs 60 -- haxe -cp "$PROBE_CP" -main EnumArgumentEqualityRejected --interp \
  >"$TMP_DIR/enum-argument-equality.txt" 2>&1
status=$?
set -e

if [[ $status -eq 0 ]]; then
  echo "expected enum argument equality to be rejected" >&2
  exit 1
fi

if ! grep -Fq 'You cannot directly compare enums with arguments' \
  "$TMP_DIR/enum-argument-equality.txt"; then
  cat "$TMP_DIR/enum-argument-equality.txt" >&2
  echo "enum argument equality failed with an unexpected diagnostic" >&2
  exit 1
fi

echo "confirmed: enum values with arguments require switch, match, or Type.enumEq"
