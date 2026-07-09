#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/dev/configure-source-checkout-hxml.sh PROJECT_DIR CHECKOUT_DIR

Render this compiler checkout's canonical scoped HXML into an external project.
Run it after `lix dev reflaxe.elixir CHECKOUT_DIR` when testing an unbuilt source
checkout. Installed release packages do not need this step.
EOF
}

if [[ $# -ne 2 ]]; then
  usage >&2
  exit 2
fi

project_dir="$(cd "$1" && pwd -P)"
checkout_dir="$(cd "$2" && pwd -P)"
target_dir="$project_dir/haxe_libraries"
mkdir -p "$target_dir"

render_hxml() {
  local library="$1"
  local preserve_dependencies="${2:-0}"
  local source_hxml="$checkout_dir/haxe_libraries/$library.hxml"
  local target_hxml="$target_dir/$library.hxml"
  local dependency_lines=""

  if [[ ! -f "$source_hxml" ]]; then
    echo "[source-hxml] ERROR: missing canonical scoped HXML: $source_hxml" >&2
    exit 1
  fi

  if [[ "$preserve_dependencies" -eq 1 && -f "$target_hxml" ]]; then
    dependency_lines="$(grep -E '^-lib ' "$target_hxml" | grep -Ev '^-lib (reflaxe|reflaxe\.elixir)([[:space:]]|$)' || true)"
  fi

  local tmp_hxml
  tmp_hxml="$(mktemp "$target_hxml.tmp.XXXXXX")"
  {
    printf '# Generated from %s for source-checkout development.\n' "$source_hxml"
    if [[ -n "$dependency_lines" ]]; then
      printf '%s\n' "$dependency_lines"
    fi
    while IFS= read -r line || [[ -n "$line" ]]; do
      printf '%s\n' "${line//'${SCOPE_DIR}'/$checkout_dir}"
    done < "$source_hxml"
  } > "$tmp_hxml"

  mv "$tmp_hxml" "$target_hxml"
  echo "[source-hxml] Wrote: $target_hxml"
}

for dependency in tink_core tink_macro tink_parse; do
  render_hxml "$dependency" 0
done
render_hxml "reflaxe" 0
render_hxml "reflaxe.elixir" 1
