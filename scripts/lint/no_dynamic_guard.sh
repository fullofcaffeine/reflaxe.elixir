#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR" || exit 1

if ! command -v rg >/dev/null 2>&1; then
  echo "[guard:no-dynamic] ERROR: ripgrep (rg) is required." >&2
  exit 1
fi

echo "[guard:no-dynamic] Checking for disallowed Dynamic/Any/untyped usage..."

# We intentionally check for *type* usage patterns (not plain word matches) to avoid
# false positives from documentation comments.
#
# Allowed boundaries:
# - `elixir.types.Term` (in std/, not scanned here)
# - `reflaxe.js.Unknown` (explicit JS interop boundary; excluded below)
#
# Allowed exceptions:
# - Macro-only compiler internals may use `untyped __elixir__()` (in src/, but we do not
#   enforce `untyped` bans there; this guard focuses on app-facing source).
TYPE_PATTERN='(:[[:space:]]*Dynamic\b|<[[:space:]]*Dynamic[[:space:]]*>|\bExprOf[[:space:]]*<[[:space:]]*Dynamic[[:space:]]*>|\bArray[[:space:]]*<[[:space:]]*Dynamic[[:space:]]*>|catch[[:space:]]*\([[:space:]]*[A-Za-z_][A-Za-z0-9_]*[[:space:]]*:[[:space:]]*Dynamic\b|:[[:space:]]*Any\b|<[[:space:]]*Any[[:space:]]*>|\bExprOf[[:space:]]*<[[:space:]]*Any[[:space:]]*>|\bArray[[:space:]]*<[[:space:]]*Any[[:space:]]*>|catch[[:space:]]*\([[:space:]]*[A-Za-z_][A-Za-z0-9_]*[[:space:]]*:[[:space:]]*Any\b)'

bad=0

scan_tree() {
  local label="$1"
  shift
  echo "[guard:no-dynamic] Scanning ${label}..."
  # Filter out comment-only matches to avoid false positives from hxdoc (e.g. "WHY: Dynamic ...").
  local matches
  matches="$(rg -n -S --glob '*.hx' "$TYPE_PATTERN" "$@" || true)"
  if [[ -z "$matches" ]]; then
    return 0
  fi

  local filtered
  filtered="$(printf "%s\n" "$matches" | grep -vE '^[^:]+:[0-9]+:[[:space:]]*(//|\\*|/\\*)' || true)"
  if [[ -n "$filtered" ]]; then
    printf "%s\n" "$filtered"
    bad=1
  fi
}

# Compiler + tooling sources (exclude explicit boundary type)
scan_tree "src/" \
  src \
  --glob '!src/reflaxe/js/Unknown.hx'

# Standard library sources: we enforce the same No-Dynamic/No-Any policy for
# app-facing std modules, while allowing known/required exceptions.
scan_tree "std/ (excluding macro/cross/boundaries)" \
  std \
  --glob '!**/*.cross.hx' \
  --glob '!std/elixir/types/Term.hx' \
  --glob '!std/reflaxe/js/Unknown.hx' \
  --glob '!std/haxe/macro/**'

# Application/example sources (exclude generated outputs)
scan_tree "examples/" \
  examples \
  --glob '!**/lib/**' \
  --glob '!**/out/**' \
  --glob '!**/_build/**' \
  --glob '!**/deps/**' \
  --glob '!**/node_modules/**' \
  --glob '!**/priv/static/**'

# App code must not use `untyped` (macro escape hatch). Keep apps pure Haxe→Elixir.
if rg -n -S --glob '*.hx' '\\buntyped\\b' examples \
  --glob '!**/lib/**' \
  --glob '!**/out/**' \
  --glob '!**/_build/**' \
  --glob '!**/deps/**' \
  --glob '!**/node_modules/**' \
  --glob '!**/priv/static/**'
then
  echo "[guard:no-dynamic] ERROR: 'untyped' is not allowed in example/app Haxe sources." >&2
  bad=1
fi

# App/example code must not use __elixir__() injections; keep apps pure Haxe→Elixir.
elixir_injection_matches="$(rg -n -S --glob '*.hx' '\\b__elixir__\\b' examples \
  --glob '!**/lib/**' \
  --glob '!**/out/**' \
  --glob '!**/_build/**' \
  --glob '!**/deps/**' \
  --glob '!**/node_modules/**' \
  --glob '!**/priv/static/**' || true)"
if [[ -n "$elixir_injection_matches" ]]; then
  filtered_injections="$(printf "%s\n" "$elixir_injection_matches" | grep -vE '^[^:]+:[0-9]+:[[:space:]]*(//|\\*|/\\*)' || true)"
  if [[ -n "$filtered_injections" ]]; then
    echo "$filtered_injections"
    echo "[guard:no-dynamic] ERROR: '__elixir__' is not allowed in example/app Haxe sources." >&2
    bad=1
  fi
fi

if [[ "$bad" -ne 0 ]]; then
  echo "[guard:no-dynamic] ❌ Violations found. Prefer typed boundaries (Term / reflaxe.js.Unknown) and explicit externs." >&2
  exit 1
fi

echo "[guard:no-dynamic] OK: No disallowed Dynamic/Any/untyped usage found."
