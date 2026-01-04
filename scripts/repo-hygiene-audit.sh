#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

say() { echo "[hygiene-audit] $*"; }

usage() {
  cat >&2 <<'EOF'
Usage: scripts/repo-hygiene-audit.sh [--apply]

Audits a few low-risk "repo hygiene" candidates (debug helpers, obvious leftovers).

--apply   Performs git rm on the suggested candidates (non-interactive).
EOF
  exit 2
}

APPLY=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply) APPLY=1; shift;;
    -h|--help) usage;;
    *) usage;;
  esac
done

cd "$ROOT_DIR"

if ! command -v git >/dev/null 2>&1; then
  say "ERROR: git is required"
  exit 1
fi

if command -v rg >/dev/null 2>&1; then
  FILTER_CMD=(rg -n)
  SEARCH_FILES=(rg -l --fixed-string)
else
  FILTER_CMD=(grep -nE)
  SEARCH_FILES=(grep -R -l -F)
fi

say "Repo: $ROOT_DIR"

if git diff --quiet && git diff --cached --quiet; then
  say "Git status: clean"
else
  say "Git status: dirty (uncommitted changes present)"
  git status --porcelain=v1 || true
fi

say ""
say "== Candidate set: tracked debug helpers under test/ (not referenced) =="

debug_candidates=()
while IFS= read -r line; do
  [[ -n "$line" ]] || continue
  debug_candidates+=("$line")
done < <(git ls-files | "${FILTER_CMD[@]}" '^(test/(Debug|debug_).*)$' | cut -d: -f2- | sort -u || true)

unused_debug=()
for file in "${debug_candidates[@]:-}"; do
  [[ -f "$file" ]] || continue
  # Prefer searching for the full repo-relative path, which is how it's typically referenced.
  if "${SEARCH_FILES[@]}" "$file" . >/dev/null 2>&1; then
    say "KEEP (referenced): $file"
  else
    say "CANDIDATE (unreferenced): $file"
    unused_debug+=("$file")
  fi
done

if [[ ${#unused_debug[@]} -eq 0 ]]; then
  say "No unreferenced tracked debug helpers found."
else
  say ""
  say "Suggested removals:"
  for file in "${unused_debug[@]}"; do
    say "  - $file"
  done
fi

if [[ "$APPLY" -eq 1 ]]; then
  if [[ ${#unused_debug[@]} -eq 0 ]]; then
    say "--apply: nothing to remove."
  else
    say "--apply: removing ${#unused_debug[@]} file(s) via git rm..."
    git rm "${unused_debug[@]}"
    say "Done. Review with: git status"
  fi
fi

say ""
say "Done."
