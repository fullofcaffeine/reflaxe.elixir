#!/usr/bin/env bash
set -euo pipefail

# Guard: Disallow numeric-suffixed identifiers in compiler sources
# Rationale: Numeric suffixes (e.g., foo2, helper3) obscure intent and violate naming rules.

TARGET_DIR='src/reflaxe/elixir'

FULL_SCAN=0
if [[ "${NUMERIC_SUFFIX_GUARD_FULL_SCAN:-}" == "1" ]]; then
  FULL_SCAN=1
fi

for arg in "$@"; do
  case "$arg" in
    --full|--full-scan) FULL_SCAN=1 ;;
    *) ;;
  esac
done

echo "[guard:numeric] Checking ${TARGET_DIR} for numeric‑suffixed identifiers..."

# Build a combined regex to catch common declaration forms:
#  - var|final declarations
#  - function names
#  - function parameters (name: Type)
DECL_PATTERN='\b(var|final|function)\s+[A-Za-z_][A-Za-z0-9_]*[0-9]+\b'
PARAM_PATTERN='function[^\(]*\([^)]*[A-Za-z_][A-Za-z0-9_]*[0-9]+\s*:'

found=0

if [[ "$FULL_SCAN" -eq 0 ]] && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  # Diff-based scan (default): only fail when *new* numeric-suffixed identifiers are introduced.
  #
  # WHY: The compiler historically contains numeric-suffixed identifiers; public CI should
  #      prevent new ones without requiring a massive rename sweep in one PR.
  #
  # Override: run with `--full-scan` or `NUMERIC_SUFFIX_GUARD_FULL_SCAN=1`.

  base_ref="${NUMERIC_SUFFIX_GUARD_BASE:-}"
  if [[ -z "$base_ref" ]] && [[ -n "${GITHUB_BASE_REF:-}" ]]; then
    if git show-ref --verify --quiet "refs/remotes/origin/${GITHUB_BASE_REF}"; then
      base_ref="origin/${GITHUB_BASE_REF}"
    fi
  fi
  if [[ -z "$base_ref" ]] && git show-ref --verify --quiet "refs/remotes/origin/main"; then
    base_ref="origin/main"
  fi

  range_args=()
  if [[ -n "$base_ref" ]]; then
    base_rev="$(git merge-base HEAD "$base_ref")"
    range_args=("${base_rev}...HEAD")
    echo "[guard:numeric] Diff scan base: ${base_ref} (merge-base ${base_rev})"
  elif git rev-parse --verify --quiet HEAD^ >/dev/null; then
    range_args=("HEAD^...HEAD")
    echo "[guard:numeric] Diff scan base: HEAD^ (no remote base found)"
  else
    echo "[guard:numeric] Diff scan base: none (initial commit); falling back to full scan"
    FULL_SCAN=1
  fi

  if [[ "$FULL_SCAN" -eq 0 ]]; then
    if {
        git diff -U0 "${range_args[@]}" -- "${TARGET_DIR}";
        git diff -U0 --cached -- "${TARGET_DIR}";
        git diff -U0 -- "${TARGET_DIR}";
      } \
      | perl -ne '
          BEGIN {
            $decl = qr/\b(?:var|final|function)\s+[A-Za-z_][A-Za-z0-9_]*[0-9]+\b/;
            $param = qr/function[^\(]*\([^)]*[A-Za-z_][A-Za-z0-9_]*[0-9]+\s*:/;
            $found = 0;
            $file = undef;
          }
          if (/^\+\+\+ b\/(\S+)/) { $file = $1; next; }
          next if !defined($file) || $file !~ /\.hx$/;
          if (/^\+[^+]/) {
            my $line = substr($_, 1);
            if ($line =~ $decl || $line =~ $param) {
              print "[guard:numeric] $file: $line";
              $found = 1;
            }
          }
          END { exit($found ? 1 : 0); }
        '
    then
      : # OK
    else
      found=1
    fi
  fi
fi

if [[ "$FULL_SCAN" -ne 0 ]]; then
  echo "[guard:numeric] Full scan enabled; scanning entire ${TARGET_DIR} tree..."

  if command -v rg >/dev/null 2>&1; then
    if rg -n -e "${DECL_PATTERN}" -e "${PARAM_PATTERN}" "${TARGET_DIR}" --no-heading --hidden --glob '!**/docs/**' --glob '!**/test/**' ; then
      found=1
    fi
  else
    # Fallback to grep with basic recursion; may produce more false positives
    if grep -RInE "${DECL_PATTERN}|${PARAM_PATTERN}" "${TARGET_DIR}" --exclude-dir=docs --exclude-dir=test ; then
      found=1
    fi
  fi
fi

if [[ "$found" -ne 0 ]]; then
  echo "[guard:numeric] ERROR: Numeric‑suffixed identifiers found in compiler sources." >&2
  echo "[guard:numeric] Hint: Rename variables/functions/params to descriptive names without numeric suffixes." >&2
  echo "[guard:numeric] Note: Run with --full-scan to report existing legacy offenders." >&2
  exit 1
fi

echo "[guard:numeric] OK: No numeric‑suffixed identifiers found."
