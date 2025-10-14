#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

missing=()

pattern_has_hxdoc() {
  local file="$1"
  # Require a doc block with WHAT/WHY/HOW/EXAMPLES keywords
  if grep -q "/\*\*" "$file" && \
     grep -qi "WHAT" "$file" && \
     grep -qi "WHY" "$file" && \
     grep -qi "HOW" "$file" && \
     grep -qi "EXAMPLES" "$file"; then
    return 0
  fi
  return 1
}

# Optional scope narrowing: if HXDOC_ONLY is provided, check only those space-separated files.
if [[ -n "${HXDOC_ONLY:-}" ]]; then
  for f in $HXDOC_ONLY; do
    # Normalize to absolute
    file="$ROOT_DIR/${f#./}"
    if [[ -f "$file" ]]; then
      if ! pattern_has_hxdoc "$file"; then missing+=("$file"); fi
    fi
  done
else
  while IFS= read -r -d '' f; do
    # Only check actual transformer modules (skip AGENTS/docs)
    if [[ "$f" == *"AGENTS.md"* ]]; then continue; fi
    if ! pattern_has_hxdoc "$f"; then
      missing+=("$f")
    fi
  done < <(find "$ROOT_DIR/src/reflaxe/elixir/ast/transformers" -type f -name "*.hx" -print0)
fi

if ((${#missing[@]})); then
  echo "Missing hxdoc (WHAT/WHY/HOW/EXAMPLES) in transformer files:" >&2
  for m in "${missing[@]}"; do echo "  - $m" >&2; done
  exit 1
fi

echo "✓ All transformer passes contain hxdoc (WHAT/WHY/HOW/EXAMPLES)."
