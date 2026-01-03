#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

say() { echo "[cleanup-audit] $*"; }

if command -v rg >/dev/null 2>&1; then
  SEARCH_CMD=(rg -n)
else
  SEARCH_CMD=(grep -R -n)
fi

say "Repo: ${ROOT_DIR}"

if command -v git >/dev/null 2>&1; then
  if git -C "$ROOT_DIR" diff --quiet && git -C "$ROOT_DIR" diff --cached --quiet; then
    say "Git status: clean"
  else
    say "Git status: dirty (uncommitted changes present)"
    git -C "$ROOT_DIR" status --porcelain=v1 || true
  fi
fi

say ""
say "== History/Archive directories =="
if [[ -d "$ROOT_DIR/docs/09-history" ]]; then
  if command -v du >/dev/null 2>&1; then
    du -sh "$ROOT_DIR/docs/09-history" 2>/dev/null || true
  fi
  find "$ROOT_DIR/docs/09-history" -maxdepth 2 -type d | sed -n '1,80p' || true
else
  say "docs/09-history: (missing)"
fi

say ""
say "== References to docs/09-history/archive =="
(
  cd "$ROOT_DIR"
  "${SEARCH_CMD[@]}" "docs/09-history/archive" docs examples src lib README.md 2>/dev/null || true
)

say ""
say "== Legacy stub docs (H1 contains '(Legacy)') =="
(
  cd "$ROOT_DIR"
  "${SEARCH_CMD[@]}" "^# .*\\(Legacy\\)\\s*$" docs 2>/dev/null || true
)

say ""
say "== Potential archive-like dirs (name=archive|legacy) =="
(
  cd "$ROOT_DIR"
  find docs -maxdepth 4 -type d \( -name archive -o -name legacy \) 2>/dev/null | sort || true
)

say ""
say "Done."

