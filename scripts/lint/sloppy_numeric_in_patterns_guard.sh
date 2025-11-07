#!/usr/bin/env bash
set -euo pipefail

# Guard: Disallow numeric-suffixed binders in case/pattern matches across compiler sources
# Examples to forbid: mod2, func2, args2, name2, rhs2, a2, b3

TARGET_DIR='src/reflaxe/elixir'
echo "[guard:sloppy-pattern-numeric] Scanning ${TARGET_DIR} for numeric‑suffix binders in patterns..."

PATTERN='\b(mod|func|args|name|rhs|left|right|inner|outer|binder|pat|expr|cond|guard|body|value|field|tuple|list|map|struct|key|val|acc|res|tmp|node|module|function|call|var|arg|param|binder|pattern|expr|rhs|lhs)[0-9]\b'

found=0
if command -v rg >/dev/null 2>&1; then
  if rg -n --no-heading --hidden -S -e "$PATTERN" "$TARGET_DIR" --glob '!**/docs/**' --glob '!**/test/**' ; then
    found=1
  fi
else
  if grep -RInE "$PATTERN" "$TARGET_DIR" --exclude-dir=docs --exclude-dir=test ; then
    found=1
  fi
fi

if [[ "$found" -ne 0 ]]; then
  echo "[guard:sloppy-pattern-numeric] ERROR: Numeric‑suffixed identifiers found in patterns. Rename to descriptive names." >&2
  exit 1
fi

echo "[guard:sloppy-pattern-numeric] OK: No numeric‑suffix binders in patterns."

