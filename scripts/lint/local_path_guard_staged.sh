#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel)"
cd "$ROOT_DIR"

STAGED_ADDED_LINES="$(
  git diff --cached --unified=0 --no-color -- . \
    | awk '
      /^diff --git / { file = ""; next }
      /^\+\+\+ / {
        file = $2
        if (file == "/dev/null") {
          file = ""
        } else {
          sub(/^[a-z]\//, "", file)
        }
        next
      }
      /^\+/ && $0 !~ /^\+\+\+/ && file != "" {
        print file ":" substr($0, 2)
      }
    '
)"

if [[ -z "$STAGED_ADDED_LINES" ]]; then
  exit 0
fi

ABSOLUTE_LOCAL_PATTERN='(/Users/[^[:space:]'"'"'"`<>()\[\]{}]+|/home/[^[:space:]'"'"'"`<>()\[\]{}]+|/var/folders/[^[:space:]'"'"'"`<>()\[\]{}]+|/private/var/folders/[^[:space:]'"'"'"`<>()\[\]{}]+|[A-Za-z]:\\Users\\[^[:space:]'"'"'"`<>()\[\]{}]+)'
RELATIVE_PATH_PATTERN='(^|[^[:alnum:]_])(\./|\.\./)[^[:space:]'"'"'"`<>()\[\]{}]+'

ABSOLUTE_HITS="$(printf '%s\n' "$STAGED_ADDED_LINES" | rg -n -P "$ABSOLUTE_LOCAL_PATTERN" || true)"
if [[ -n "$ABSOLUTE_HITS" ]]; then
  echo "[guard:local-paths] ERROR: Absolute local filesystem paths detected in staged changes."
  echo "[guard:local-paths] Use repository-relative paths instead."
  echo ""
  echo "$ABSOLUTE_HITS"
  exit 1
fi

RELATIVE_HITS="$(printf '%s\n' "$STAGED_ADDED_LINES" | rg -n -P "$RELATIVE_PATH_PATTERN" || true)"
if [[ -z "$RELATIVE_HITS" ]]; then
  exit 0
fi

if [[ "${ALLOW_RELATIVE_PATH_REFERENCES:-0}" == "1" ]]; then
  echo "[guard:local-paths] ALLOW_RELATIVE_PATH_REFERENCES=1 set; skipping confirmation."
  exit 0
fi

if [[ ! -t 0 ]]; then
  echo "[guard:local-paths] ERROR: Relative path references found but no TTY available for confirmation."
  echo "[guard:local-paths] Re-run commit interactively or set ALLOW_RELATIVE_PATH_REFERENCES=1."
  echo ""
  echo "$RELATIVE_HITS"
  exit 1
fi

echo "[guard:local-paths] Relative path references detected in staged changes:"
echo "$RELATIVE_HITS"
printf "[guard:local-paths] Proceed with these relative paths? [y/N] "
read -r response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
  echo "[guard:local-paths] Commit aborted."
  exit 1
fi

echo "[guard:local-paths] Relative path references confirmed."
