#!/usr/bin/env bash
set -euo pipefail

# Guard: Disallow numeric-suffixed binders in case/pattern matches across compiler sources
# Examples to forbid: mod2, func2, args2, name2, rhs2, a2, b3

TARGET_DIR='src/reflaxe/elixir'
FULL_SCAN=0
if [[ "${SLOPPY_PATTERN_NUMERIC_GUARD_FULL_SCAN:-}" == "1" ]]; then
  FULL_SCAN=1
fi

for arg in "$@"; do
  case "$arg" in
    --full|--full-scan) FULL_SCAN=1 ;;
    *) ;;
  esac
done

echo "[guard:sloppy-pattern-numeric] Checking ${TARGET_DIR} for numeric‑suffix binders in patterns..."

PATTERN='\b(mod|func|args|name|rhs|left|right|inner|outer|binder|pat|expr|cond|guard|body|value|field|tuple|list|map|struct|key|val|acc|res|tmp|node|module|function|call|var|arg|param|binder|pattern|expr|rhs|lhs)[0-9]\b'

found=0

if [[ "$FULL_SCAN" -eq 0 ]] && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  # Diff-based scan (default): only fail when *new* numeric-suffixed "sloppy" binders are introduced.
  #
  # WHY: The codebase predates this guard; enforcing it repo-wide requires a large refactor.
  #      CI should prevent *new* additions without blocking unrelated work.
  #
  # Override: run with `--full-scan` or `SLOPPY_PATTERN_NUMERIC_GUARD_FULL_SCAN=1`.

  base_ref="${SLOPPY_PATTERN_NUMERIC_GUARD_BASE:-}"
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
    echo "[guard:sloppy-pattern-numeric] Diff scan base: ${base_ref} (merge-base ${base_rev})"
  elif git rev-parse --verify --quiet HEAD^ >/dev/null; then
    range_args=("HEAD^...HEAD")
    echo "[guard:sloppy-pattern-numeric] Diff scan base: HEAD^ (no remote base found)"
  else
    echo "[guard:sloppy-pattern-numeric] Diff scan base: none (initial commit); falling back to full scan"
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
            $pat = qr/\b(?:mod|func|args|name|rhs|left|right|inner|outer|binder|pat|expr|cond|guard|body|value|field|tuple|list|map|struct|key|val|acc|res|tmp|node|module|function|call|var|arg|param|pattern|lhs)\d\b/;
            $found = 0;
            $file = undef;
          }
          if (/^\+\+\+ b\/(\S+)/) { $file = $1; next; }
          next if !defined($file) || $file !~ /\.hx$/;
          if (/^\+[^+]/) {
            my $line = substr($_, 1);
            if ($line =~ $pat) {
              print "[guard:sloppy-pattern-numeric] $file: $line";
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
  echo "[guard:sloppy-pattern-numeric] Full scan enabled; scanning entire ${TARGET_DIR} tree..."
  if command -v rg >/dev/null 2>&1; then
    if rg -n --no-heading --hidden -S -e "$PATTERN" "$TARGET_DIR" --glob '*.hx' ; then
      found=1
    fi
  else
    if grep -RInE "$PATTERN" "$TARGET_DIR" --include='*.hx' ; then
      found=1
    fi
  fi
fi

if [[ "$found" -ne 0 ]]; then
  echo "[guard:sloppy-pattern-numeric] ERROR: Numeric‑suffixed identifiers found in patterns. Rename to descriptive names." >&2
  echo "[guard:sloppy-pattern-numeric] Note: Run with --full-scan to report existing legacy offenders." >&2
  exit 1
fi

echo "[guard:sloppy-pattern-numeric] OK: No numeric‑suffix binders in patterns."
