#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
out="${1:-dist/reflaxe.elixir.zip}"
version="${2:-$(node -p "require('$root_dir/haxelib.json').version")}"
tag="${3:-development}"
source_sha="${4:-$(git -C "$root_dir" rev-parse HEAD^{commit})}"

if [[ "$out" == /* ]]; then
  out_abs="$out"
else
  out_abs="$root_dir/$out"
fi

haxe_cmd="${HAXE_BIN:-haxe}"
for command_name in node git tar; do
  command -v "$command_name" >/dev/null 2>&1 || {
    echo "error: $command_name not found in PATH" >&2
    exit 2
  }
done
if [[ "$haxe_cmd" == */* ]]; then
  [[ -x "$haxe_cmd" ]] || { echo "error: HAXE_BIN is not executable: $haxe_cmd" >&2; exit 2; }
else
  command -v "$haxe_cmd" >/dev/null 2>&1 || {
    echo "error: haxe not found in PATH; set HAXE_BIN to the real Haxe binary" >&2
    exit 2
  }
fi

resolved_source="$(git -C "$root_dir" rev-parse "$source_sha^{commit}")"
[[ "$resolved_source" =~ ^[0-9a-f]{40}$ ]] || { echo "error: invalid source commit" >&2; exit 2; }
source_sha="$resolved_source"

mkdir -p "$(dirname "$out_abs")"
rm -f "$out_abs"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/reflaxe.elixir-haxelib.XXXXXX")"
cleanup() { rm -rf "$tmp"; }
trap cleanup EXIT

source_root="$tmp/source"
work_dir="$tmp/work/reflaxe.elixir"
build_dir="$work_dir/_Build"
mkdir -p "$source_root" "$work_dir"

log() { echo "[package] $*"; }

log "Exporting tracked source commit $source_sha"
git -C "$root_dir" archive "$source_sha" | tar -x -C "$source_root"

copy_file_to_work() {
  local rel="$1"
  [[ -f "$source_root/$rel" ]] || { echo "[package] error: required file missing: $rel" >&2; exit 2; }
  mkdir -p "$work_dir/$(dirname "$rel")"
  cp "$source_root/$rel" "$work_dir/$rel"
}

copy_dir_to_work() {
  local rel="$1"
  [[ -d "$source_root/$rel" ]] || { echo "[package] error: required directory missing: $rel" >&2; exit 2; }
  mkdir -p "$work_dir/$rel"
  cp -R "$source_root/$rel/." "$work_dir/$rel/"
}

copy_dir_to_build() {
  local rel="$1"
  [[ -d "$source_root/$rel" ]] || { echo "[package] error: required directory missing: $rel" >&2; exit 2; }
  mkdir -p "$build_dir/$rel"
  cp -R "$source_root/$rel/." "$build_dir/$rel/"
}

copy_dir_to_work src
copy_dir_to_work std
for rel in haxelib.json extraParams.hxml LICENSE README.md; do copy_file_to_work "$rel"; done
if [[ -f "$source_root/run.n" ]]; then copy_file_to_work run.n; fi

reflaxe_run="$source_root/vendor/reflaxe/Run.hx"
[[ -f "$reflaxe_run" ]] || { echo "error: vendored Reflaxe build runner missing" >&2; exit 2; }
(
  cd "$work_dir"
  log "Running Reflaxe build into _Build/"
  "$haxe_cmd" -cp "$source_root/vendor/reflaxe" --run Run build _Build --deleteOldFolder "$work_dir"
)

node "$root_dir/scripts/release/prepare-package-metadata.js" \
  "$build_dir/haxelib.json" \
  "$build_dir/release-metadata.json" \
  "$version" \
  "$tag" \
  "$source_sha"

# CompilerBootstrap loads these package siblings by path; generic Reflaxe build owns src/_std flattening.
copy_dir_to_build vendor
# The source tree's contributor-instruction link is not package runtime content; prior copy logic
# also omitted symlinks, and release archives reject them explicitly.
rm -f "$build_dir/vendor/CLAUDE.md"

LC_ALL=C TZ=UTC node "$root_dir/scripts/release/deterministic-zip.js" "$build_dir" "$out_abs"
log "wrote: $out"
