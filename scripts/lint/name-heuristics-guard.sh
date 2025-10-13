#!/usr/bin/env bash
set -euo pipefail

# Guardrail: prevent app-specific or name-based heuristics in transformers.
# Allowed: docs and examples; Target: src/ (compiler logic)

if git rev-parse --show-toplevel >/dev/null 2>&1; then
  ROOT_DIR=$(git rev-parse --show-toplevel)
else
  ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
fi
cd "$ROOT_DIR" || exit 1

fail() {
  echo "[Guardrails] ❌ $1" >&2
  exit 1
}

if ! command -v rg >/dev/null 2>&1; then
  fail "ripgrep (rg) not found. Install rg to run guardrails."
fi

# 1) Guard hard-coded binder literals and equality checks only (most dangerous form of coupling)

# 2) Hard-coded binder literal promotions (EVar("name") or name == "name")
# We restrict to suspicious binder names likely to couple logic if hard-coded.
BINDER_LITERALS=(
  'EVar\("updated_socket"\)'
  'EVar\("presence_socket"\)'
  'EVar\("live_socket"\)'
  'EVar\("todos"\)'
  'EVar\("now"\)'
  'EVar\("uid"\)'
  '==\s*"updated_socket"'
  '==\s*"presence_socket"'
  '==\s*"live_socket"'
  '==\s*"todos"'
  '==\s*"now"'
  '==\s*"uid"'
)

for pat in "${BINDER_LITERALS[@]}"; do
  if rg -n "$pat" src/reflaxe/elixir/ast/transformers -S --hidden; then
    fail "Found hard-coded binder literal in transformers: $pat"
  fi
done

echo "[Guardrails] ✅ Name heuristic checks passed"
