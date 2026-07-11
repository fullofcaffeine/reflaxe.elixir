#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REPO="${REPO:-fullofcaffeine/reflaxe.elixir}"
ATTEMPTS="${ATTEMPTS:-6}"
RETRY_DELAY="${RETRY_DELAY:-5}"

for command_name in gh jq node; do
  command -v "$command_name" >/dev/null 2>&1 || {
    echo "[release-verify] ERROR: $command_name is required" >&2
    exit 2
  }
done

tag="${1:-}"
[[ -n "$tag" ]] || { echo "[release-verify] ERROR: an explicit release tag is required" >&2; exit 2; }
tag="${tag#refs/tags/}"
[[ "$tag" == v* ]] || tag="v$tag"
version="${tag#v}"
asset_name="reflaxe.elixir-${version}.zip"
checksum_name="${asset_name}.sha256"
release_json=""
verified=0

for ((attempt = 1; attempt <= ATTEMPTS; attempt++)); do
  release_json="$(gh release view "$tag" --repo "$REPO" --json tagName,isDraft,isImmutable,isPrerelease,assets 2>/dev/null || true)"
  if [[ -n "$release_json" ]] && jq -e --arg tag "$tag" --arg asset "$asset_name" --arg checksum "$checksum_name" '
    .tagName == $tag
    and .isDraft == false
    and .isImmutable == true
    and .isPrerelease == false
    and ([.assets[].name] | sort) == ([$asset, $checksum] | sort)
    and ([.assets[] | select(.name == $asset and .state == "uploaded" and .size > 0 and (.digest | startswith("sha256:")))] | length) == 1
    and ([.assets[] | select(.name == $checksum and .state == "uploaded" and .size > 0 and (.digest | startswith("sha256:")))] | length) == 1
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
  echo "[release-verify] ERROR: $tag must be immutable with exactly the approved ZIP and checksum assets" >&2
  exit 1
fi

tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/reflaxe-elixir-release-verify.XXXXXX")"
trap 'rm -rf "$tmp_dir"' EXIT
gh release download "$tag" --repo "$REPO" --pattern "$asset_name" --dir "$tmp_dir"
package_zip="$tmp_dir/$asset_name"

gh release download "$tag" --repo "$REPO" --pattern "$checksum_name" --dir "$tmp_dir"
source_sha="$(git -C "$ROOT_DIR" rev-parse "refs/tags/$tag^{commit}")"
node "$ROOT_DIR/scripts/release/verify-release-artifact.js" \
  --zip "$package_zip" \
  --version "$version" \
  --tag "$tag" \
  --source-sha "$source_sha" >/dev/null
checksum_line="$(cat "$tmp_dir/$checksum_name")"
if [[ ! "$checksum_line" =~ ^([0-9a-f]{64})[[:space:]][[:space:]](.+)$ ]] \
  || [[ "${BASH_REMATCH[2]:-}" != "$asset_name" ]]; then
  echo "[release-verify] ERROR: malformed checksum sidecar" >&2
  exit 1
fi
expected="${BASH_REMATCH[1]}"
actual="$(node -e "const c=require('crypto'),f=require('fs');process.stdout.write(c.createHash('sha256').update(f.readFileSync(process.argv[1])).digest('hex'))" "$package_zip")"
[[ "$actual" == "$expected" ]] || { echo "[release-verify] ERROR: checksum mismatch" >&2; exit 1; }

attested=0
for ((attempt = 1; attempt <= ATTEMPTS; attempt++)); do
  if gh release verify "$tag" --repo "$REPO" >/dev/null 2>&1 \
    && gh release verify-asset "$tag" "$package_zip" --repo "$REPO" >/dev/null 2>&1 \
    && gh release verify-asset "$tag" "$tmp_dir/$checksum_name" --repo "$REPO" >/dev/null 2>&1; then
    attested=1
    break
  fi
  if (( attempt < ATTEMPTS )); then
    echo "[release-verify] Waiting for immutable release attestation ($attempt/$ATTEMPTS)"
    sleep "$RETRY_DELAY"
  fi
done
[[ "$attested" -eq 1 ]] || { echo "[release-verify] ERROR: immutable release attestation verification failed" >&2; exit 1; }

echo "[release-verify] OK: $tag publishes attested $asset_name"
