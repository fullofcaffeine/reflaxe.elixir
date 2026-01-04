#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

say() { echo "[unused-scripts] $*"; }

if ! command -v git >/dev/null 2>&1; then
  say "error: git is required"
  exit 1
fi

cd "$ROOT_DIR"

HAS_RG=0
if command -v rg >/dev/null 2>&1; then
  HAS_RG=1
fi

say "Repo: ${ROOT_DIR}"

script_paths="$(
  git ls-files scripts \
    | { if [[ "$HAS_RG" == "1" ]]; then rg "\\.(sh|js|ts)$"; else grep -E "\\.(sh|js|ts)$"; fi; } \
    || true
)"

if [[ -z "$script_paths" ]]; then
  say "OK: no tracked scripts found under scripts/"
  exit 0
fi

say ""
say "== Candidate unused scripts (heuristic) =="
say "Search roots: package.json, .github/, docs/, scripts/, test/"

unused=()
total=0

while IFS= read -r path; do
  [[ -n "$path" ]] || continue
  total=$((total + 1))

  # Look for literal references to the script path (excluding the script itself).
  if [[ "$HAS_RG" == "1" ]]; then
    if rg -n -F "$path" package.json .github docs scripts test -g "!${path}" >/dev/null 2>&1; then
      continue
    fi
  else
    if grep -R -n -F "$path" package.json .github docs scripts test 2>/dev/null \
      | awk -F: -v p="$path" '$1 != p { found=1; exit } END { exit found ? 0 : 1 }'; then
      continue
    fi
  fi

  unused+=("$path")
done <<< "$script_paths"

if [[ "${#unused[@]}" -eq 0 ]]; then
  say "OK: all ${total} scripts appear referenced"
  exit 0
fi

say "Found ${#unused[@]} / ${total} scripts with no references:"
for path in "${unused[@]}"; do
  echo "  - ${path}"
done

say ""
say "NOTE: This is a heuristic. Some scripts are intended to be run manually."
