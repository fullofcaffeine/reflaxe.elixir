#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOL_DIR="$ROOT_DIR/tooling/phoenix_scaffold"
RAW_MODULE="$TOOL_DIR/generated/raw/haxe_phoenix_scaffold/genes_contract.ex"
STAGED_MODULE="$TOOL_DIR/generated/formatted/genes_contract.ex"
STAGED_MANIFEST="$TOOL_DIR/generated/formatted/genes_contract.generated.json"
TARGET_MODULE="$ROOT_DIR/lib/haxe_phoenix_scaffold/genes_contract.ex"
TARGET_MANIFEST="$ROOT_DIR/lib/haxe_phoenix_scaffold/genes_contract.generated.json"
MODE="${1:---write}"

case "$MODE" in
  --write | --check) ;;
  *)
    echo "usage: scripts/generate-phoenix-scaffold-core.sh [--write|--check]" >&2
    exit 64
    ;;
esac

# BOOTSTRAP BOUNDARY: this bounded driver must exist before the checked-in
# Haxe-authored scaffold module can be regenerated. It invokes Haxe and the
# canonical formatter, but owns no dependency identity or rendered content.
mkdir -p "$(dirname "$STAGED_MODULE")"
(
  cd "$TOOL_DIR"
  HAXE_NO_SERVER=1 haxe build.hxml
)
cp "$RAW_MODULE" "$STAGED_MODULE"
mix format "$STAGED_MODULE"

node -e '
  const crypto = require("node:crypto")
  const fs = require("node:fs")
  const [build, source, generated, output] = process.argv.slice(1)
  const sha256 = path => crypto.createHash("sha256").update(fs.readFileSync(path)).digest("hex")
  const manifest = {
    schema: "reflaxe-elixir/checked-in-haxe-tooling@4",
    build: "tooling/phoenix_scaffold/build.hxml",
    buildSha256: sha256(build),
    artifacts: [{
      source: "tooling/phoenix_scaffold/src_haxe/phoenix_scaffold_tooling/GenesContract.hx",
      generated: "lib/haxe_phoenix_scaffold/genes_contract.ex",
      sourceSha256: sha256(source),
      generatedSha256: sha256(generated)
    }],
    sharedInputs: []
  }
  fs.writeFileSync(output, JSON.stringify(manifest, null, 2) + "\n")
' "$TOOL_DIR/build.hxml" \
  "$TOOL_DIR/src_haxe/phoenix_scaffold_tooling/GenesContract.hx" \
  "$STAGED_MODULE" \
  "$STAGED_MANIFEST"

if [[ "$MODE" == "--check" ]]; then
  status=0
  if [[ ! -f "$TARGET_MODULE" ]] || ! cmp -s "$STAGED_MODULE" "$TARGET_MODULE"; then
    echo "generated Phoenix scaffold Genes contract drifted; run npm run generate:phoenix-scaffold-core" >&2
    if [[ -f "$TARGET_MODULE" ]]; then diff -u "$TARGET_MODULE" "$STAGED_MODULE" || true; fi
    status=1
  fi
  if [[ ! -f "$TARGET_MANIFEST" ]] || ! cmp -s "$STAGED_MANIFEST" "$TARGET_MANIFEST"; then
    echo "generated Phoenix scaffold manifest drifted; run npm run generate:phoenix-scaffold-core" >&2
    if [[ -f "$TARGET_MANIFEST" ]]; then diff -u "$TARGET_MANIFEST" "$STAGED_MANIFEST" || true; fi
    status=1
  fi
  exit "$status"
fi

mkdir -p "$(dirname "$TARGET_MODULE")"
cp "$STAGED_MODULE" "$TARGET_MODULE"
cp "$STAGED_MANIFEST" "$TARGET_MANIFEST"
echo "generated $TARGET_MODULE"
echo "generated $TARGET_MANIFEST"
