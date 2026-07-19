#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOL_DIR="$ROOT_DIR/tooling/live_react"
RAW_DIR="$TOOL_DIR/generated/raw"
FORMATTED_DIR="$TOOL_DIR/generated/formatted"
RAW_LIFECYCLE="$RAW_DIR/haxe_phoenix_live_react.ex"
RAW_CORE="$RAW_DIR/haxe_phoenix_live_react/core.ex"
RAW_HOST="$RAW_DIR/haxe_phoenix_live_react/host.ex"
RAW_SOURCE_PATCHER="$RAW_DIR/haxe_phoenix_live_react/source_patcher.ex"
RAW_DEPENDENCY="$RAW_DIR/haxe_phoenix_live_react/dependency.ex"
RAW_DEPENDENCY_WORKER="$RAW_DIR/haxe_phoenix_live_react/dependency_worker.ex"
RAW_PACKAGE="$RAW_DIR/haxe_phoenix_live_react/package.ex"
RAW_REGISTRY="$RAW_DIR/haxe_phoenix_live_react/registry.ex"
RAW_TASK="$RAW_DIR/mix/tasks/haxe/phoenix/live_react.ex"
RAW_COMPONENT_TASK="$RAW_DIR/mix/tasks/haxe/gen/live_react.ex"
RAW_PATCH="$RAW_DIR/haxe_project_patch.ex"
RAW_PATCH_PLAN="$RAW_DIR/haxe_project_patch/plan.ex"
RAW_PATCH_OPERATION="$RAW_DIR/haxe_project_patch/operation.ex"
STAGED_LIFECYCLE="$FORMATTED_DIR/haxe_phoenix_live_react.ex"
STAGED_CORE="$FORMATTED_DIR/core.ex"
STAGED_HOST="$FORMATTED_DIR/host.ex"
STAGED_SOURCE_PATCHER="$FORMATTED_DIR/source_patcher.ex"
STAGED_DEPENDENCY="$FORMATTED_DIR/dependency.ex"
STAGED_DEPENDENCY_WORKER="$FORMATTED_DIR/dependency_worker.ex"
STAGED_PACKAGE="$FORMATTED_DIR/package.ex"
STAGED_REGISTRY="$FORMATTED_DIR/registry.ex"
STAGED_TASK="$FORMATTED_DIR/haxe.phoenix.live_react.ex"
STAGED_COMPONENT_TASK="$FORMATTED_DIR/haxe.gen.live_react.ex"
STAGED_PATCH="$FORMATTED_DIR/haxe_project_patch.ex"
STAGED_PATCH_PLAN="$FORMATTED_DIR/haxe_project_patch.plan.ex"
STAGED_PATCH_OPERATION="$FORMATTED_DIR/haxe_project_patch.operation.ex"
STAGED_MANIFEST="$FORMATTED_DIR/core.generated.json"
TARGET_LIFECYCLE="$ROOT_DIR/lib/haxe_phoenix_live_react.ex"
TARGET_CORE="$ROOT_DIR/lib/haxe_phoenix_live_react/core.ex"
TARGET_HOST="$ROOT_DIR/lib/haxe_phoenix_live_react/host.ex"
TARGET_SOURCE_PATCHER="$ROOT_DIR/lib/haxe_phoenix_live_react/source_patcher.ex"
TARGET_DEPENDENCY="$ROOT_DIR/lib/haxe_phoenix_live_react/dependency.ex"
TARGET_DEPENDENCY_WORKER="$ROOT_DIR/lib/haxe_phoenix_live_react/dependency_worker.ex"
TARGET_PACKAGE="$ROOT_DIR/lib/haxe_phoenix_live_react/package.ex"
TARGET_REGISTRY="$ROOT_DIR/lib/haxe_phoenix_live_react/registry.ex"
TARGET_TASK="$ROOT_DIR/lib/mix/tasks/haxe.phoenix.live_react.ex"
TARGET_COMPONENT_TASK="$ROOT_DIR/lib/mix/tasks/haxe.gen.live_react.ex"
TARGET_PATCH="$ROOT_DIR/lib/haxe_project_patch.ex"
TARGET_PATCH_PLAN="$ROOT_DIR/lib/haxe_project_patch/plan.ex"
TARGET_PATCH_OPERATION="$ROOT_DIR/lib/haxe_project_patch/operation.ex"
TARGET_MANIFEST="$ROOT_DIR/lib/haxe_phoenix_live_react/core.generated.json"
MODE="${1:---write}"

case "$MODE" in
  --write | --check) ;;
  *)
    echo "usage: scripts/generate-live-react-core.sh [--write|--check]" >&2
    exit 64
    ;;
esac

# BOOTSTRAP BOUNDARY: this bounded driver must exist before the Haxe-authored tooling artifacts
# can be regenerated, and it must be usable even when those checked-in Elixir artifacts are
# missing or stale. It therefore invokes Haxe and the canonical Elixir formatter directly, but
# owns no lifecycle policy or host behavior; all such behavior lives in typed Haxe below.
rm -rf "$RAW_DIR" "$FORMATTED_DIR"
mkdir -p "$FORMATTED_DIR"

(
  cd "$TOOL_DIR"
  HAXE_NO_SERVER=1 haxe build.hxml
)

cp "$RAW_LIFECYCLE" "$STAGED_LIFECYCLE"
cp "$RAW_CORE" "$STAGED_CORE"
cp "$RAW_HOST" "$STAGED_HOST"
cp "$RAW_SOURCE_PATCHER" "$STAGED_SOURCE_PATCHER"
cp "$RAW_DEPENDENCY" "$STAGED_DEPENDENCY"
cp "$RAW_DEPENDENCY_WORKER" "$STAGED_DEPENDENCY_WORKER"
cp "$RAW_PACKAGE" "$STAGED_PACKAGE"
cp "$RAW_REGISTRY" "$STAGED_REGISTRY"
cp "$RAW_TASK" "$STAGED_TASK"
cp "$RAW_COMPONENT_TASK" "$STAGED_COMPONENT_TASK"
cp "$RAW_PATCH" "$STAGED_PATCH"
cp "$RAW_PATCH_PLAN" "$STAGED_PATCH_PLAN"
cp "$RAW_PATCH_OPERATION" "$STAGED_PATCH_OPERATION"

GENERATED_MODULES=(
  "$STAGED_LIFECYCLE"
  "$STAGED_CORE"
  "$STAGED_HOST"
  "$STAGED_SOURCE_PATCHER"
  "$STAGED_DEPENDENCY"
  "$STAGED_DEPENDENCY_WORKER"
  "$STAGED_PACKAGE"
  "$STAGED_REGISTRY"
  "$STAGED_TASK"
  "$STAGED_COMPONENT_TASK"
  "$STAGED_PATCH"
  "$STAGED_PATCH_PLAN"
  "$STAGED_PATCH_OPERATION"
)

mix format "${GENERATED_MODULES[@]}"

if rg -n 'Reflaxe\.Elixir|ArrayIterator|ReduceWhileResult' \
  "${GENERATED_MODULES[@]}"; then
  echo "generated LiveReact tooling unexpectedly depends on compiler support modules" >&2
  exit 1
fi

# A single-line zero-argument IIFE is evidence that an expression-position safety
# wrapper survived after its body had already collapsed to one expression. The
# compiler must remove that obsolete scope generically; checked-in Haxe-authored
# tooling must not normalize the artifact by editing generated Elixir.
if rg -n '\(fn -> [^[:cntrl:]]+ end\)\.\(\)' "${GENERATED_MODULES[@]}"; then
  echo "generated LiveReact tooling contains a trivial IIFE; fix the Haxe-to-Elixir lowering before publishing" >&2
  exit 1
fi

node -e '
  const crypto = require("node:crypto")
  const fs = require("node:fs")
  const args = process.argv.slice(1)
  const buildPath = args.shift()
  const outputPath = args.shift()
  const sharedSeparator = args.indexOf("--shared")
  if (sharedSeparator < 0 || sharedSeparator % 3 !== 0) {
    throw new Error("generated tooling manifest arguments are malformed")
  }
  const artifactArgs = args.slice(0, sharedSeparator)
  const sharedSources = args.slice(sharedSeparator + 1)
  const sha256 = path => crypto.createHash("sha256").update(fs.readFileSync(path)).digest("hex")
  const artifacts = []
  for (let index = 0; index < artifactArgs.length; index += 3) {
    const [generatedPath, sourcePath, generated] = artifactArgs.slice(index, index + 3)
    artifacts.push({
      source: sourcePath.replace(/^.*\/tooling\//, "tooling/"),
      generated,
      sourceSha256: sha256(sourcePath),
      generatedSha256: sha256(generatedPath)
    })
  }
  const manifest = {
    schema: "reflaxe-elixir/checked-in-haxe-tooling@4",
    build: "tooling/live_react/build.hxml",
    buildSha256: sha256(buildPath),
    artifacts,
    sharedInputs: sharedSources.map(sourcePath => ({
      source: sourcePath.replace(/^.*\/tooling\//, "tooling/"),
      sourceSha256: sha256(sourcePath)
    }))
  }
  fs.writeFileSync(outputPath, JSON.stringify(manifest, null, 2) + "\n")
' "$TOOL_DIR/build.hxml" \
  "$STAGED_MANIFEST" \
  "$STAGED_LIFECYCLE" "$TOOL_DIR/src_haxe/phoenix_live_react_tooling/LiveReactLifecycle.hx" "lib/haxe_phoenix_live_react.ex" \
  "$STAGED_CORE" "$TOOL_DIR/src_haxe/phoenix_live_react_tooling/IntegrationCore.hx" "lib/haxe_phoenix_live_react/core.ex" \
  "$STAGED_HOST" "$TOOL_DIR/src_haxe/phoenix_live_react_tooling/LiveReactHost.hx" "lib/haxe_phoenix_live_react/host.ex" \
  "$STAGED_SOURCE_PATCHER" "$TOOL_DIR/src_haxe/phoenix_live_react_tooling/LiveReactSourcePatcher.hx" "lib/haxe_phoenix_live_react/source_patcher.ex" \
  "$STAGED_DEPENDENCY" "$TOOL_DIR/src_haxe/phoenix_live_react_tooling/LiveReactDependency.hx" "lib/haxe_phoenix_live_react/dependency.ex" \
  "$STAGED_DEPENDENCY_WORKER" "$TOOL_DIR/src_haxe/phoenix_live_react_tooling/LiveReactDependencyWorker.hx" "lib/haxe_phoenix_live_react/dependency_worker.ex" \
  "$STAGED_PACKAGE" "$TOOL_DIR/src_haxe/phoenix_live_react_tooling/LiveReactPackage.hx" "lib/haxe_phoenix_live_react/package.ex" \
  "$STAGED_REGISTRY" "$TOOL_DIR/src_haxe/phoenix_live_react_tooling/LiveReactRegistry.hx" "lib/haxe_phoenix_live_react/registry.ex" \
  "$STAGED_TASK" "$TOOL_DIR/src_haxe/phoenix_live_react_tooling/LiveReactMixTask.hx" "lib/mix/tasks/haxe.phoenix.live_react.ex" \
  "$STAGED_COMPONENT_TASK" "$TOOL_DIR/src_haxe/phoenix_live_react_tooling/LiveReactComponentMixTask.hx" "lib/mix/tasks/haxe.gen.live_react.ex" \
  "$STAGED_PATCH" "$TOOL_DIR/src_haxe/phoenix_live_react_tooling/ProjectPatch.hx" "lib/haxe_project_patch.ex" \
  "$STAGED_PATCH_PLAN" "$TOOL_DIR/src_haxe/phoenix_live_react_tooling/PatchPlan.hx" "lib/haxe_project_patch/plan.ex" \
  "$STAGED_PATCH_OPERATION" "$TOOL_DIR/src_haxe/phoenix_live_react_tooling/PatchOperation.hx" "lib/haxe_project_patch/operation.ex" \
  --shared \
  "$TOOL_DIR/src_haxe/phoenix_live_react_tooling/LiveReactTypes.hx" \
  "$TOOL_DIR/src_haxe/phoenix_live_react_tooling/PatchTypes.hx"

ARTIFACTS=(
  "$STAGED_LIFECYCLE|$TARGET_LIFECYCLE|LiveReact lifecycle"
  "$STAGED_CORE|$TARGET_CORE|LiveReact deterministic core"
  "$STAGED_HOST|$TARGET_HOST|LiveReact host primitives"
  "$STAGED_SOURCE_PATCHER|$TARGET_SOURCE_PATCHER|LiveReact source patcher"
  "$STAGED_DEPENDENCY|$TARGET_DEPENDENCY|LiveReact dependency resolver"
  "$STAGED_DEPENDENCY_WORKER|$TARGET_DEPENDENCY_WORKER|LiveReact dependency resolver worker"
  "$STAGED_PACKAGE|$TARGET_PACKAGE|LiveReact package planner"
  "$STAGED_REGISTRY|$TARGET_REGISTRY|LiveReact static registry"
  "$STAGED_TASK|$TARGET_TASK|LiveReact Mix task"
  "$STAGED_COMPONENT_TASK|$TARGET_COMPONENT_TASK|LiveReact component Mix task"
  "$STAGED_PATCH|$TARGET_PATCH|Haxe project patch module"
  "$STAGED_PATCH_PLAN|$TARGET_PATCH_PLAN|Haxe project patch plan"
  "$STAGED_PATCH_OPERATION|$TARGET_PATCH_OPERATION|Haxe project patch operation"
)

if [[ "$MODE" == "--check" ]]; then
  status=0

  for artifact in "${ARTIFACTS[@]}"; do
    IFS='|' read -r staged target label <<< "$artifact"
    if [[ ! -f "$target" ]] || ! cmp -s "$staged" "$target"; then
      echo "generated $label drifted; run npm run generate:live-react-core" >&2
      if [[ -f "$target" ]]; then
        diff -u "$target" "$staged" || true
      fi
      status=1
    fi
  done

  if [[ ! -f "$TARGET_MANIFEST" ]] || ! cmp -s "$STAGED_MANIFEST" "$TARGET_MANIFEST"; then
    echo "generated LiveReact core manifest drifted; run npm run generate:live-react-core" >&2
    if [[ -f "$TARGET_MANIFEST" ]]; then
      diff -u "$TARGET_MANIFEST" "$STAGED_MANIFEST" || true
    fi
    status=1
  fi

  exit "$status"
fi

for artifact in "${ARTIFACTS[@]}"; do
  IFS='|' read -r staged target label <<< "$artifact"
  mkdir -p "$(dirname "$target")"
  cp "$staged" "$target"
  echo "generated $target"
done
mkdir -p "$(dirname "$TARGET_MANIFEST")"
cp "$STAGED_MANIFEST" "$TARGET_MANIFEST"

echo "generated $TARGET_MANIFEST"
