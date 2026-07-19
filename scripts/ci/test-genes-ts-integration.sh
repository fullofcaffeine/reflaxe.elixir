#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FIXTURE_DIR="$ROOT_DIR/test/fixtures/genes_ts_live_react"
EXAMPLE_DIR="$ROOT_DIR/examples/12-phoenix-chat"
GENERATED_DIR="$FIXTURE_DIR/generated"

if [[ ! -x "$EXAMPLE_DIR/node_modules/.bin/tsc" ]]; then
  "$ROOT_DIR/scripts/with-timeout.sh" --secs 300 -- \
    npm -C "$EXAMPLE_DIR" ci --prefer-offline --no-audit --no-fund
fi

rm -rf "$GENERATED_DIR"
mkdir -p "$GENERATED_DIR"

# TEST HOST BOUNDARY: React, ReactDOM, and TypeScript are the real npm tools
# being consumed, so this bounded shell driver supplies their installed modules.
# All component, registry, prop, callback, and runtime behavior is Haxe-authored.
ln -s "$EXAMPLE_DIR/node_modules" "$FIXTURE_DIR/node_modules"
cleanup() {
  rm -f "$FIXTURE_DIR/node_modules"
}
trap cleanup EXIT

cd "$ROOT_DIR"
HAXE_NO_SERVER=1 haxe "$FIXTURE_DIR/build-tsx.hxml"
HAXE_NO_SERVER=1 haxe "$FIXTURE_DIR/build-classic.hxml"

negative_log="$GENERATED_DIR/negative-hxx.log"
if HAXE_NO_SERVER=1 haxe "$FIXTURE_DIR/build-negative.hxml" >"$negative_log" 2>&1; then
  echo "genes-ts accepted an invalid Haxe-authored React prop" >&2
  exit 1
fi

if ! rg -q 'GTS-HXX-PROP-002.*property `title` expects `String` but received `Int`' "$negative_log"; then
  echo "genes-ts rejected the invalid prop without the expected typed diagnostic" >&2
  sed -n '1,120p' "$negative_log" >&2
  exit 1
fi

"$EXAMPLE_DIR/node_modules/.bin/tsc" --project "$FIXTURE_DIR/tsconfig.json"

tsx_output="$(node --enable-source-maps "$GENERATED_DIR/dist/index.js")"
classic_output="$(node --enable-source-maps "$GENERATED_DIR/classic/index.js")"

if [[ "$tsx_output" != "$classic_output" ]]; then
  echo "genes-ts TSX/classic runtime mismatch" >&2
  diff -u <(printf '%s\n' "$classic_output") <(printf '%s\n' "$tsx_output") || true
  exit 1
fi

if [[ ! -f "$GENERATED_DIR/src-gen/LiveReactIslandFixture.tsx.map" ]] ||
   [[ ! -f "$GENERATED_DIR/classic/LiveReactIslandFixture.js.map" ]]; then
  echo "genes-ts integration did not emit both source maps" >&2
  exit 1
fi

node - \
  "$GENERATED_DIR/src-gen/LiveReactIslandFixture.tsx.map" \
  "$GENERATED_DIR/classic/LiveReactIslandFixture.js.map" <<'NODE'
const fs = require("fs")

for (const path of process.argv.slice(2)) {
  const map = JSON.parse(fs.readFileSync(path, "utf8"))
  const sources = map.sources ?? []

  if (!sources.includes("../../src/LiveReactIslandFixture.hx")) {
    throw new Error(`${path}: project source is not a stable relative path`)
  }

  if (!sources.includes("haxe://classpath/genes/Register.hx")) {
    throw new Error(`${path}: Genes source is not a stable virtual classpath identity`)
  }

  const leakedCacheSource = sources.find(source =>
    source.includes("/haxe_libraries/") || source.includes("/haxe/versions/")
  )
  if (leakedCacheSource) {
    throw new Error(`${path}: package-cache source leaked into map: ${leakedCacheSource}`)
  }
}
NODE

local_path_pattern='/U[s]ers/|/var/fol[d]ers/|[A-Za-z]:\\\\U[s]ers\\\\'
if rg -n "$local_path_pattern" "$GENERATED_DIR"; then
  echo "genes-ts integration emitted a machine-local path" >&2
  exit 1
fi

printf 'genes-ts TSX/classic parity: %s\n' "$tsx_output"
