#!/usr/bin/env bash
set -euo pipefail

out="${1:-dist/reflaxe.elixir.zip}"

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
if [[ "$out" == /* ]]; then
  out_abs="$out"
else
  out_abs="$root_dir/$out"
fi

if ! command -v zip >/dev/null 2>&1; then
  echo "error: zip not found in PATH" >&2
  exit 2
fi

haxe_cmd="${HAXE_BIN:-haxe}"
if [[ "$haxe_cmd" == */* ]]; then
  if [[ ! -x "$haxe_cmd" ]]; then
    echo "error: HAXE_BIN is not executable: $haxe_cmd" >&2
    exit 2
  fi
elif ! command -v "$haxe_cmd" >/dev/null 2>&1; then
  echo "error: haxe not found in PATH; set HAXE_BIN to the real Haxe binary" >&2
  exit 2
fi

reflaxe_run="$root_dir/vendor/reflaxe/Run.hx"
if [[ ! -f "$reflaxe_run" ]]; then
  echo "error: vendored Reflaxe build runner missing: vendor/reflaxe/Run.hx" >&2
  exit 2
fi

mkdir -p "$(dirname "$out_abs")"
rm -f "$out_abs"

tmp="$(mktemp -d "${TMPDIR:-/tmp}/reflaxe.elixir-haxelib.XXXXXX")"
cleanup() { rm -rf "$tmp"; }
trap cleanup EXIT

work_dir="$tmp/work/reflaxe.elixir"
build_dir="$work_dir/_Build"
mkdir -p "$work_dir"

log() {
  echo "[package] $*"
}

strip_trailing_slashes() {
  local p="$1"
  while [[ "$p" != "/" && "$p" == */ ]]; do
    p="${p%/}"
  done
  printf '%s' "$p"
}

copy_tree_content() {
  local from_raw="$1"
  local to_raw="$2"
  local from to
  from="$(strip_trailing_slashes "$from_raw")"
  to="$(strip_trailing_slashes "$to_raw")"

  if [[ ! -d "$from" ]]; then
    echo "[package] error: source directory does not exist: $from" >&2
    exit 2
  fi

  mkdir -p "$to"

  while IFS= read -r -d '' dir; do
    local rel="${dir#"$from"/}"
    if [[ "$dir" == "$from" ]]; then
      continue
    fi
    mkdir -p "$to/$rel"
  done < <(find "$from" -type d -print0)

  while IFS= read -r -d '' file; do
    local rel="${file#"$from"/}"
    mkdir -p "$to/$(dirname "$rel")"
    cp "$file" "$to/$rel"
  done < <(find "$from" -type f -print0)
}

copy_file_required_to_work() {
  local rel="$1"
  local src="$root_dir/$rel"
  if [[ ! -f "$src" ]]; then
    echo "[package] error: required file missing: $rel" >&2
    exit 2
  fi
  mkdir -p "$work_dir/$(dirname "$rel")"
  cp "$src" "$work_dir/$rel"
  log "Copying file: $rel"
}

copy_file_optional_to_work() {
  local rel="$1"
  local src="$root_dir/$rel"
  if [[ ! -f "$src" ]]; then
    return
  fi
  mkdir -p "$work_dir/$(dirname "$rel")"
  cp "$src" "$work_dir/$rel"
  log "Copying file: $rel"
}

copy_dir_required_to_work() {
  local rel="$1"
  local src="$root_dir/$rel"
  if [[ ! -d "$src" ]]; then
    echo "[package] error: required directory missing: $rel" >&2
    exit 2
  fi
  copy_tree_content "$src" "$work_dir/$rel"
  log "Copying directory: $rel/"
}

copy_dir_required_to_build() {
  local rel="$1"
  local src="$root_dir/$rel"
  if [[ ! -d "$src" ]]; then
    echo "[package] error: required directory missing: $rel" >&2
    exit 2
  fi
  copy_tree_content "$src" "$build_dir/$rel"
  log "Copying directory: $rel/"
}

copy_dir_required_to_work "src"
copy_dir_required_to_work "std"
copy_file_required_to_work "haxelib.json"
copy_file_required_to_work "extraParams.hxml"
copy_file_required_to_work "LICENSE"
copy_file_required_to_work "README.md"
copy_file_optional_to_work "run.n"

(
  cd "$work_dir"
  log "Running Reflaxe build into _Build/"
  "$haxe_cmd" -cp "$root_dir/vendor/reflaxe" --run Run build _Build --deleteOldFolder "$work_dir"
)

# The generic Reflaxe build handles classPath/stdPaths flattening. These vendored
# sources remain package siblings because CompilerBootstrap injects them by path.
copy_dir_required_to_build "vendor"

(
  cd "$build_dir"
  zip -r -X "$out_abs" . >/dev/null
)

log "wrote: $out"
