#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FIXTURE_DIR="$ROOT_DIR/test/fixtures/genes_ts_live_react"
EXAMPLE_DIR="$ROOT_DIR/examples/12-phoenix-chat"
GENERATED_DIR="$FIXTURE_DIR/generated"
EXPECTED_CONTRACT="$FIXTURE_DIR/expected/status-panel-events.generated.ts"

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

EVENT_CONTRACT_RELATIVE="test/fixtures/genes_ts_live_react/generated/src-gen/status-panel-events.generated.ts"
EVENT_MACRO_ARGS=(
  -cp "$ROOT_DIR/std"
  -cp "$ROOT_DIR/vendor/phoenix_shared/src"
  -cp "$FIXTURE_DIR/src"
)

run_event_macro() {
  HAXE_NO_SERVER=1 haxe "${EVENT_MACRO_ARGS[@]}" --macro "$1" --no-output
}

run_event_macro \
  "phoenix.live_react.LiveReactEventProtocol.exportTypeScript(\"StatusPanelEvent\", \"$EVENT_CONTRACT_RELATIVE\")"

# Generated event contracts are drift-checked independently from TypeScript so
# an application can use the same read-only gate before Vite compilation.
run_event_macro \
  "phoenix.live_react.LiveReactEventProtocol.checkTypeScript(\"StatusPanelEvent\", \"$EVENT_CONTRACT_RELATIVE\")"

diff -u \
  "$EXPECTED_CONTRACT" \
  "$GENERATED_DIR/src-gen/status-panel-events.generated.ts"

contract_path="$GENERATED_DIR/src-gen/status-panel-events.generated.ts"
unowned_path="$GENERATED_DIR/src-gen/unowned.generated.ts"
ownership_log="$GENERATED_DIR/event-contract-ownership.log"
printf '%s\n' '// hand-owned TypeScript' >"$unowned_path"
if run_event_macro \
  'phoenix.live_react.LiveReactEventProtocol.exportTypeScript("StatusPanelEvent", "test/fixtures/genes_ts_live_react/generated/src-gen/unowned.generated.ts")' \
  >"$ownership_log" 2>&1; then
  echo "LiveReact event exporter overwrote an unowned TypeScript file" >&2
  exit 1
fi
if ! grep -Fq "Refusing to overwrite unowned LiveReact event contract" "$ownership_log"; then
  echo "LiveReact event exporter rejected an unowned file without the expected diagnostic" >&2
  sed -n '1,120p' "$ownership_log" >&2
  exit 1
fi
rm -f "$unowned_path"

drift_log="$GENERATED_DIR/event-contract-drift.log"
printf '%s\n' '// intentional drift' >>"$contract_path"
if run_event_macro \
  "phoenix.live_react.LiveReactEventProtocol.checkTypeScript(\"StatusPanelEvent\", \"$EVENT_CONTRACT_RELATIVE\")" \
  >"$drift_log" 2>&1; then
  echo "LiveReact event contract check accepted generated-file drift" >&2
  exit 1
fi
if ! grep -Fq "LiveReact event contract drift detected" "$drift_log" ||
   ! grep -Fq "intentional drift" "$contract_path"; then
  echo "LiveReact event contract check did not fail read-only with the expected diagnostic" >&2
  sed -n '1,120p' "$drift_log" >&2
  exit 1
fi

run_event_macro \
  "phoenix.live_react.LiveReactEventProtocol.exportTypeScript(\"StatusPanelEvent\", \"$EVENT_CONTRACT_RELATIVE\")"
diff -u "$EXPECTED_CONTRACT" "$contract_path"

assert_event_projection_rejected() {
  local protocol_type="$1"
  local expected="$2"
  local log="$GENERATED_DIR/${protocol_type}.negative.log"

  if run_event_macro \
    "phoenix.live_react.LiveReactEventProtocol.exportTypeScript(\"$protocol_type\", \"test/fixtures/genes_ts_live_react/generated/src-gen/rejected.generated.ts\")" \
    >"$log" 2>&1; then
    echo "LiveReact event projection unexpectedly accepted $protocol_type" >&2
    exit 1
  fi

  if ! grep -Fq "$expected" "$log"; then
    echo "LiveReact event projection rejected $protocol_type without the expected diagnostic" >&2
    sed -n '1,120p' "$log" >&2
    exit 1
  fi
}

assert_event_projection_rejected \
  "CustomStatusPanelEvent" \
  "requires an application-owned TypeScript adapter"
assert_event_projection_rejected \
  "OpenStatusPanelEvent" \
  "raw/open payloads require an application-owned TypeScript validator"
assert_event_projection_rejected \
  "TemplateStatusPanelEvent" \
  "supports hook-origin events only"

negative_log="$GENERATED_DIR/negative-hxx.log"
if HAXE_NO_SERVER=1 haxe "$FIXTURE_DIR/build-negative.hxml" >"$negative_log" 2>&1; then
  echo "genes-ts accepted an invalid Haxe-authored React prop" >&2
  exit 1
fi

if ! grep -Eq 'GTS-HXX-PROP-002.*property `title` expects `String` but received `Int`' "$negative_log"; then
  echo "genes-ts rejected the invalid prop without the expected typed diagnostic" >&2
  sed -n '1,120p' "$negative_log" >&2
  exit 1
fi

# Compiler diagnostics legitimately contain the local source path. They are
# transient test evidence, not generated application artifacts, so remove them
# before the tracked-output path-hygiene scan below.
rm -f "$GENERATED_DIR"/*.log

"$EXAMPLE_DIR/node_modules/.bin/tsc" --project "$FIXTURE_DIR/tsconfig.json"
"$EXAMPLE_DIR/node_modules/.bin/tsc" --project "$FIXTURE_DIR/tsconfig-contract.json"

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
if grep -ERn "$local_path_pattern" "$GENERATED_DIR"; then
  echo "genes-ts integration emitted a machine-local path" >&2
  exit 1
fi

printf 'genes-ts TSX/classic parity: %s\n' "$tsx_output"
