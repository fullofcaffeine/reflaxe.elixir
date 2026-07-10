#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REPO="${REPO:-fullofcaffeine/reflaxe.elixir}"
ATTEMPTS="${ATTEMPTS:-6}"
RETRY_DELAY="${RETRY_DELAY:-5}"

if ! command -v gh >/dev/null 2>&1; then
  echo "[release-verify] ERROR: gh is required" >&2
  exit 2
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "[release-verify] ERROR: jq is required" >&2
  exit 2
fi
if ! command -v unzip >/dev/null 2>&1; then
  echo "[release-verify] ERROR: unzip is required" >&2
  exit 2
fi

tag="${1:-}"
if [[ -z "$tag" ]]; then
  version="$(node -p "require('$ROOT_DIR/package.json').version")"
  tag="v$version"
else
  tag="${tag#refs/tags/}"
  [[ "$tag" == v* ]] || tag="v$tag"
  version="${tag#v}"
fi

asset_name="reflaxe.elixir-${version}.zip"
release_json=""
verified=0

for ((attempt = 1; attempt <= ATTEMPTS; attempt++)); do
  release_json="$(gh release view "$tag" --repo "$REPO" --json isDraft,isPrerelease,assets 2>/dev/null || true)"
  if [[ -n "$release_json" ]] && jq -e --arg asset "$asset_name" '
    .isDraft == false
    and .isPrerelease == false
    and ([.assets[] | select(.name == $asset and .state == "uploaded" and .size > 0)] | length) == 1
  ' <<< "$release_json" >/dev/null; then
    verified=1
    break
  fi

  if (( attempt < ATTEMPTS )); then
    echo "[release-verify] Waiting for $tag asset $asset_name ($attempt/$ATTEMPTS)"
    sleep "$RETRY_DELAY"
  fi
done

if [[ "$verified" -ne 1 ]]; then
  echo "[release-verify] ERROR: $tag must be a published release with exactly one non-empty $asset_name asset" >&2
  if [[ -n "$release_json" ]]; then
    jq '{isDraft, isPrerelease, assets: [.assets[] | {name, size, state}]}' <<< "$release_json" >&2
  fi
  exit 1
fi

tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/reflaxe-elixir-release-verify.XXXXXX")"
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

gh release download "$tag" --repo "$REPO" --pattern "$asset_name" --dir "$tmp_dir"
package_zip="$tmp_dir/$asset_name"
package_metadata="$tmp_dir/haxelib.json"
package_files="$tmp_dir/files.txt"

manifest_schema="$(git -C "$ROOT_DIR" show "$tag:release/manifest.json" 2>/dev/null \
  | jq -r '.schemaVersion // empty' 2>/dev/null || true)"
if [[ "$manifest_schema" == "2" ]]; then
  node "$ROOT_DIR/scripts/release/verify-release-state.js" tagged \
    --version "$version" \
    --tag "$tag" \
    --package "$package_zip"
elif [[ "${ALLOW_LEGACY_RELEASE:-0}" == "1" ]]; then
  echo "[release-verify] Legacy tag $tag predates release policy schema v2; checking package structure only"
elif [[ -n "$manifest_schema" ]]; then
  echo "[release-verify] ERROR: $tag uses unsupported release policy schema $manifest_schema" >&2
  exit 1
else
  echo "[release-verify] ERROR: $tag is missing a readable release/manifest.json" >&2
  exit 1
fi

unzip -p "$package_zip" haxelib.json > "$package_metadata"
unzip -Z1 "$package_zip" > "$package_files"

jq -e --arg version "$version" '.version == $version and .classPath == "src"' "$package_metadata" >/dev/null
grep -Fx 'src/haxe/Exception.cross.hx' "$package_files" >/dev/null
if grep -E '(^|/)std/elixir/_std/' "$package_files" >/dev/null; then
  echo "[release-verify] ERROR: published package contains the source-only _std tree" >&2
  exit 1
fi

echo "[release-verify] OK: $tag publishes verified $asset_name"
