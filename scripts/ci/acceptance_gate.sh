#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_ROOT="$(cd "$ROOT_DIR/.." && pwd)"

pass_count=0
gate_count=5

msg() { printf "\n[Acceptance] %s\n" "$*"; }
fail() { echo "[Acceptance] ❌ $*" >&2; exit 1; }

# 1) Hxdoc coverage gate
msg "Hxdoc coverage gate (WHAT/WHY/HOW/EXAMPLES)"
if bash "$PROJECT_ROOT/scripts/lint/hxdoc_check.sh"; then
  pass_count=$((pass_count+1))
else
  echo "[Acceptance] Hxdoc coverage failed" >&2
fi

# Helper: find Elixir‑target HXML (those that clearly target Elixir)
find_elixir_hxml() {
  \
  find "$PROJECT_ROOT" -type f -name "*.hxml" \
    -not -path "*/node_modules/*" \
    -not -path "*/docs/*" \
    -print0 | \
  while IFS= read -r -d '' f; do
    if grep -qE "elixir_output|CompilerInit.Start\(\)" "$f"; then
      echo "$f"
    fi
  done
}

# 2) Guard: no -D analyzer-optimize in Elixir HXML
msg "Guard: verify no -D analyzer-optimize in Elixir HXML"
violations=()
while IFS= read -r f; do
  # Ignore comments and only match actual flags
  if awk '!/^[[:space:]]*#/' "$f" | grep -Eq -- "\\-D[[:space:]]+analyzer-optimize"; then
    violations+=("$f")
  fi
done < <(find_elixir_hxml)

if ((${#violations[@]}==0)); then
  pass_count=$((pass_count+1))
  echo "✓ No analyzer-optimize flags in Elixir HXML"
else
  echo "Found analyzer-optimize in Elixir HXML:" >&2
  for v in "${violations[@]}"; do echo "  - $v" >&2; done
fi

# 3) Guard: no legacy string pipeline in Elixir HXML
msg "Guard: verify no -D use_legacy_string_pipeline in Elixir HXML"
legacy_violations=()
while IFS= read -r f; do
  if awk '!/^[[:space:]]*#/' "$f" | grep -Eq -- "\\-D[[:space:]]+use_legacy_string_pipeline"; then
    legacy_violations+=("$f")
  fi
done < <(find_elixir_hxml)

if ((${#legacy_violations[@]}==0)); then
  pass_count=$((pass_count+1))
  echo "✓ No legacy string pipeline flags in Elixir HXML"
else
  echo "Found legacy string pipeline flags in Elixir HXML:" >&2
  for v in "${legacy_violations[@]}"; do echo "  - $v" >&2; done
fi

# 4) Category smoke subsets (non‑aggregate behavior must fail properly)
msg "Category smoke: core/stdlib/phoenix/ecto/otp (subset)"
smoke_failed=0
run_smoke_for_category() {
  local cat="$1"
  local limit="${2:-2}"
  local test_root="$PROJECT_ROOT/test/snapshot/$cat"
  if [ ! -d "$test_root" ]; then return 0; fi
  # Portable collection of a limited set of tests without relying on bash 4 mapfile
  tests=()
  while IFS= read -r line; do
    tests+=("$line")
  done < <(find "$test_root" -name compile.hxml -print0 | \
            xargs -0 -n1 dirname | \
            sed "s|$PROJECT_ROOT/test/snapshot/||" | \
            head -n "$limit")
  for t in "${tests[@]:-}"; do
    [ -n "$t" ] || continue
    local target="test-$(echo "$t" | sed 's|/|__|g')"
    echo "→ $cat smoke: $t"
    set +e
    # Run the test and then inspect test-results*.tmp to decide pass/fail
    rm -f "$PROJECT_ROOT/test"/test-results*.tmp 2>/dev/null || true
    make -C "$PROJECT_ROOT/test" -f Makefile -j1 "$target"
    local rc=$?
    set -e
    if [ $rc -ne 0 ]; then
      echo "  ✗ runner error ($t)"
      smoke_failed=1
    elif grep -q "❌" "$PROJECT_ROOT/test"/test-results*.tmp 2>/dev/null; then
      echo "  ✗ failed ($t)"
      smoke_failed=1
    else
      echo "  ✓ passed ($t)"
    fi
    rm -f "$PROJECT_ROOT/test"/test-results*.tmp 2>/dev/null || true
  done
}

run_smoke_for_category core 3
run_smoke_for_category stdlib 3
run_smoke_for_category phoenix 2 || true
run_smoke_for_category ecto 2 || true
run_smoke_for_category otp 2 || true

if [ $smoke_failed -eq 0 ]; then
  pass_count=$((pass_count+1))
  echo "✓ Smoke subsets passed"
else
  echo "Smoke subsets had failures" >&2
fi

# 5) Todo‑app runtime smoke (via QA sentinel)
msg "Todo‑app runtime smoke"
set +e
bash "$PROJECT_ROOT/scripts/qa-sentinel.sh" --app "$PROJECT_ROOT/examples/todo-app" --port 4000
runtime_rc=$?
set -e
if [ $runtime_rc -eq 0 ]; then
  pass_count=$((pass_count+1))
else
  echo "Todo‑app runtime gate failed" >&2
fi

# Progress computation
progress=$(( (pass_count*100)/gate_count ))
echo "\n[Acceptance] Progress: ${progress}% (${pass_count}/${gate_count} gates passed)"

# Exit non‑zero if any gates failed
if [ $pass_count -lt $gate_count ]; then
  exit 1
fi

echo "[Acceptance] ✅ All acceptance gates passed"
