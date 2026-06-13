#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

echo "[guard:hxx-raw-heex] Checking Haxe-authored HXX templates for raw HEEx markers..."

# Keep this guard focused on Haxe source that authors templates. Generated .ex files
# and markdown docs may legitimately contain raw HEEx as output or explanatory text.
readonly DEFAULT_ROOTS=(
  "examples"
  "tools/fixtures"
)

roots=("$@")
if [[ "${#roots[@]}" -eq 0 ]]; then
  roots=("${DEFAULT_ROOTS[@]}")
fi

existing_roots=()
for root in "${roots[@]}"; do
  [[ -d "$root" ]] || continue
  existing_roots+=("$root")
done

if [[ "${#existing_roots[@]}" -eq 0 ]]; then
  echo "[guard:hxx-raw-heex] OK: no configured roots exist."
  exit 0
fi

fail=0

is_comment_line() {
  local line="$1"
  local trimmed="${line#"${line%%[![:space:]]*}"}"

  [[ "$trimmed" == "//"* || "$trimmed" == "/*"* || "$trimmed" == "*"* ]]
}

file_allows_raw_heex() {
  local file="$1"
  rg -q --fixed-strings "@:allow_heex" "$file"
}

while IFS= read -r -d '' file; do
  # Scope to example/generated Haxe source, not arbitrary docs or generated Elixir.
  case "$file" in
    examples/*/src_haxe/*.hx|examples/*/src_haxe/**/*.hx|tools/fixtures/*.hx|tools/fixtures/**/*.hx) ;;
    *) continue ;;
  esac

  if ! rg -q --fixed-strings "<%" "$file"; then
    continue
  fi

  if file_allows_raw_heex "$file"; then
    continue
  fi

  line_number=0
  while IFS= read -r line || [[ -n "$line" ]]; do
    line_number=$((line_number + 1))
    [[ "$line" == *"<%"* ]] || continue
    if is_comment_line "$line"; then
      continue
    fi

    echo "[guard:hxx-raw-heex] ERROR: raw HEEx marker in Haxe template source: ${file}:${line_number}" >&2
    echo "  ${line}" >&2
    fail=1
  done < "$file"
done < <(find "${existing_roots[@]}" -type f -name '*.hx' -print0)

if [[ "$fail" -ne 0 ]]; then
  echo '[guard:hxx-raw-heex] FAILED: use HXX constructs (${...}, <if>, <for>) or add @:allow_heex intentionally.' >&2
  exit 1
fi

echo "[guard:hxx-raw-heex] OK: no unannotated raw HEEx markers found in Haxe template sources."
