#!/usr/bin/env bash
# test-runtime-smoke.sh — compile + execute a small deterministic runtime subset
#
# Purpose:
# - Snapshot tests validate generated Elixir output shapes.
# - This script additionally executes a few key fixtures to catch runtime regressions
#   (exception dispatch, Process ports, etc.) without running the full suite.
#
# Bounded execution:
# - Each compile + run step is wrapped in scripts/util/with-timeout.sh.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
WITH_TIMEOUT="$ROOT_DIR/scripts/util/with-timeout.sh"

HAXE_BIN="${HAXE_BIN:-haxe}"
COMPILE_TIMEOUT_SECS="${COMPILE_TIMEOUT_SECS:-120}"
RUNTIME_TIMEOUT_SECS="${RUNTIME_TIMEOUT_SECS:-20}"

TEST_DIRS=(
  "test/snapshot/core/try_catch"
  "test/snapshot/stdlib/sys_io_process/basic"
  "test/runtime/fast_boot/string_tools_rebinding"
  "test/snapshot/regression/non_void_tail_values"
  "test/snapshot/regression/function_result_invariants"
  "test/snapshot/regression/tuple_elem_access"
  "test/snapshot/stdlib/uint_32bit_semantics"
)

echo "[runtime-smoke] compile-timeout=${COMPILE_TIMEOUT_SECS}s runtime-timeout=${RUNTIME_TIMEOUT_SECS}s"

run_one() {
  local test_dir="$1"
  local abs_test_dir="$ROOT_DIR/$test_dir"

  if [[ ! -f "$abs_test_dir/compile.hxml" ]]; then
    echo "[runtime-smoke] ❌ missing compile.hxml: $test_dir" >&2
    return 1
  fi

  echo "[runtime-smoke] → compile: $test_dir"
  (cd "$abs_test_dir" && "$WITH_TIMEOUT" "$COMPILE_TIMEOUT_SECS" \
    "$HAXE_BIN" --no-traces -D no_traces -D elixir_output=out -D reflaxe.dont_output_metadata_id compile.hxml >/dev/null 2>&1)

  local outdir="$abs_test_dir/out"
  if [[ ! -d "$outdir" ]]; then
    echo "[runtime-smoke] ❌ missing out/: $test_dir" >&2
    return 1
  fi

  local entry=""
  if [[ -f "$outdir/main.ex" ]]; then
    entry="main.ex"
  elif [[ -f "$outdir/Main.ex" ]]; then
    entry="Main.ex"
  else
    echo "[runtime-smoke] ❌ no main entry (.ex) found in: $test_dir/out" >&2
    return 1
  fi

  local requires=()
  # Ensure core runtime exception structs are loaded before compiling other modules.
  [[ -f "$outdir/reflaxe/exception.ex" ]] && requires+=("-r" "reflaxe/exception.ex")
  [[ -f "$outdir/reflaxe/elixir/haxe_throw.ex" ]] && requires+=("-r" "reflaxe/elixir/haxe_throw.ex")

  ex_files="$(cd "$outdir" && find . -type f -name "*.ex" -print | sed 's|^\./||' | LC_ALL=C sort)"
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    [[ "$f" == "$entry" ]] && continue
    [[ "$f" == "reflaxe/exception.ex" ]] && continue
    [[ "$f" == "reflaxe/elixir/haxe_throw.ex" ]] && continue
    requires+=("-r" "$f")
  done <<< "$ex_files"
  requires+=("-r" "$entry")

  echo "[runtime-smoke] → run: $test_dir ($entry)"
  (cd "$outdir" && "$WITH_TIMEOUT" "$RUNTIME_TIMEOUT_SECS" \
    elixir "${requires[@]}" -e '
      unless function_exported?(Main, :main, 0), do: raise("Missing Main.main/0")
      Main.main()
    ' >/dev/null)
}

for test_dir in "${TEST_DIRS[@]}"; do
  run_one "$test_dir"
done

echo "[runtime-smoke] All runtime smoke tests passed ✅"
