#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

# Examples intentionally demonstrating legacy/balanced workflows.
readonly ALLOW_LEGACY_DEMOS=(
  "examples/05-heex-templates"
)

is_allowed_legacy_demo() {
  local candidate="$1"
  local demo
  for demo in "${ALLOW_LEGACY_DEMOS[@]}"; do
    if [[ "$candidate" == "$demo" ]]; then
      return 0
    fi
  done
  return 1
}

fail=0

echo "[guard:examples-hxx-mode] Checking example HXX mode policy..."

has_strict_hxx_mode() {
  local build_file="$1"

  if rg -q --fixed-strings -- "-D hxx_mode=tsx" "$build_file"; then
    return 0
  fi

  # Support thin alias entrypoints (for example build.hxml -> build-server.hxml).
  local build_dir
  build_dir="$(dirname "$build_file")"

  local next_ref
  while IFS= read -r next_ref; do
    [[ -n "$next_ref" ]] || continue

    local next_file
    if [[ "$next_ref" = /* ]]; then
      next_file="$next_ref"
    else
      next_file="${build_dir}/${next_ref}"
    fi

    if [[ -f "$next_file" ]] && rg -q --fixed-strings -- "-D hxx_mode=tsx" "$next_file"; then
      return 0
    fi
  done < <(awk '/^[[:space:]]*--next[[:space:]]+/ {print $2}' "$build_file")

  return 1
}

# 1) Build defaults: non-demo examples must opt into strict TSX mode.
for build_file in examples/*/build.hxml; do
  example_dir="$(dirname "$build_file")"

  if is_allowed_legacy_demo "$example_dir"; then
    continue
  fi

  if ! has_strict_hxx_mode "$build_file"; then
    echo "[guard:examples-hxx-mode] ERROR: Missing '-D hxx_mode=tsx' in ${build_file} (or its --next target)" >&2
    fail=1
  fi
done

# 2) Source policy: non-demo examples must not use legacy template markers.
# Match legacy template calls (hxx('...') / hxx("...")) and raw HEEx escapes.
legacy_pattern="\\bhxx\\s*\\(\\s*['\"]|HXX\\.hxx\\s*\\(|<%=?|@:allow_heex|hxx_allow_raw_heex"
for example_dir in examples/*; do
  [[ -d "$example_dir/src_haxe" ]] || continue

  if is_allowed_legacy_demo "$example_dir"; then
    continue
  fi

  if rg -n --glob '*.hx' "$legacy_pattern" "$example_dir/src_haxe"; then
    echo "[guard:examples-hxx-mode] ERROR: Legacy HXX/HEEx markers found in ${example_dir}/src_haxe" >&2
    fail=1
  fi
done

if [[ "$fail" -ne 0 ]]; then
  echo "[guard:examples-hxx-mode] FAILED: Non-demo examples must use strict TSX mode + inline markup." >&2
  exit 1
fi

echo "[guard:examples-hxx-mode] OK: Example HXX mode policy is satisfied."
