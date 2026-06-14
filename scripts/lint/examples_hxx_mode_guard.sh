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

# 1) Build defaults: non-demo examples inherit strict TSX mode from the compiler.
for build_file in examples/*/build.hxml; do
	example_dir="$(dirname "$build_file")"

	if is_allowed_legacy_demo "$example_dir"; then
		continue
	fi

	if rg -q --fixed-strings -- "-D hxx_mode=tsx" "$build_file"; then
		echo "[guard:examples-hxx-mode] ERROR: Redundant '-D hxx_mode=tsx' in ${build_file}; TSX is the compiler default." >&2
		fail=1
	fi
done

# 2) Source policy: non-demo examples must not use legacy template markers or redundant TSX metadata.
# Match legacy template calls (hxx('...') / hxx("...")) and raw HEEx escapes.
legacy_pattern="\\bhxx\\s*\\(\\s*['\"]|HXX\\.hxx\\s*\\(|<%=?|@:allow_heex|hxx_allow_raw_heex|@:hxx_mode\\(\"tsx\"\\)"
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
	echo "[guard:examples-hxx-mode] FAILED: Non-demo examples must inherit default TSX mode and use inline markup." >&2
	exit 1
fi

echo "[guard:examples-hxx-mode] OK: Example HXX mode policy is satisfied."
