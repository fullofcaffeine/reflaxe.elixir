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
ELIXIR_COMPILE_TIMEOUT_SECS="${ELIXIR_COMPILE_TIMEOUT_SECS:-60}"
RUNTIME_TIMEOUT_SECS="${RUNTIME_TIMEOUT_SECS:-20}"

TEST_DIRS=(
  "test/snapshot/core/try_catch"
  "test/snapshot/stdlib/sys_io_process/basic"
  "test/snapshot/stdlib/haxe_io_bytes_streams"
  "test/runtime/loop_control_accumulators"
  "test/snapshot/regression/numeric_control_flow_concat"
  "test/snapshot/regression/emitted_module_identity"
  "test/snapshot/regression/reducer_loop_return_semantics"
  "test/snapshot/regression/assigned_switch_return"
  "test/snapshot/core/nested_early_return"
  "test/runtime/switch_case_body"
  "test/runtime/array_pattern_bindings"
  "test/runtime/nested_enum_bindings"
  "test/snapshot/phoenix/controller_value_preservation"
  "test/runtime/dynamic_length"
  "test/runtime/inline_optional_default"
  "test/runtime/inline_abstract_nested_result"
  "test/snapshot/core/advanced_patterns"
  "test/snapshot/core/enhanced_pattern_matching"
  "test/snapshot/core/enhanced_patterns"
  "test/runtime/nested_dynamic_comprehensions"
  "test/runtime/fast_boot/string_tools_rebinding"
  "test/snapshot/regression/non_void_tail_values"
  "test/snapshot/regression/function_result_invariants"
  "test/snapshot/regression/abstract_identity_values"
  "test/snapshot/regression/negated_block_operands"
  "test/snapshot/regression/authorized_private_calls"
  "test/snapshot/regression/captured_callback_invocation"
  "test/snapshot/regression/builtin_array_constructor"
  "test/snapshot/regression/result_switch_lambda_binders"
  "test/snapshot/regression/tuple_elem_access"
  "test/snapshot/regression/temporary_single_evaluation"
  "test/snapshot/regression/reserved_keyword_params"
  "test/snapshot/regression/SwitchOnFieldAccess"
  "test/snapshot/regression/enum_pattern_names"
  "test/snapshot/regression/underscore_prefix_consistency"
  "test/snapshot/regression/enum_snake_case_patterns"
  "test/snapshot/regression/enum_variable_rebinding"
  "test/snapshot/regression/enum_extraction_usage"
  "test/snapshot/regression/OrphanedEnumParameters"
  "test/snapshot/regression/troubleshooting_patterns"
  "test/snapshot/stdlib/uint_32bit_semantics"
)

echo "[runtime-smoke] compile-timeout=${COMPILE_TIMEOUT_SECS}s elixir-compile-timeout=${ELIXIR_COMPILE_TIMEOUT_SECS}s runtime-timeout=${RUNTIME_TIMEOUT_SECS}s"

run_one() (
  local test_dir="$1"
  local abs_test_dir="$ROOT_DIR/$test_dir"

  if [[ ! -f "$abs_test_dir/compile.hxml" ]]; then
    echo "[runtime-smoke] ❌ missing compile.hxml: $test_dir" >&2
    return 1
  fi

  echo "[runtime-smoke] → compile: $test_dir"
  # Keep trace arguments: Haxe's no-traces option removes their evaluation,
  # including original fixture calls that runtime acceptance must exercise.
  if (cd "$abs_test_dir" && "$WITH_TIMEOUT" "$COMPILE_TIMEOUT_SECS" \
    "$HAXE_BIN" -D elixir_output=out -D reflaxe.dont_output_metadata_id compile.hxml); then
    :
  else
    local compile_status=$?
    echo "[runtime-smoke] compile failed: $test_dir (exit=$compile_status, limit=${COMPILE_TIMEOUT_SECS}s)" >&2
    return "$compile_status"
  fi

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

  local beam_dir
  beam_dir="$(mktemp -d "${TMPDIR:-/tmp}/reflaxe-runtime-smoke.XXXXXX")"
  trap 'rm -rf -- "$beam_dir"' EXIT
  local generated_files=()
  while IFS= read -r generated_file; do
    generated_files+=("$generated_file")
  done < <(cd "$outdir" && find . -type f -name '*.ex' -print | LC_ALL=C sort)
  # A fixture may need a native macro supplied by its host. Keep that small
  # bootstrap separate from generated code and compile both with the same gate.
  if [[ -d "$abs_test_dir/native" ]]; then
    while IFS= read -r native_file; do
      generated_files+=("$native_file")
    done < <(find "$abs_test_dir/native" -type f -name '*.ex' -print | LC_ALL=C sort)
  fi

  # As in the OTP smoke owner, compile the complete dependency set together.
  # Sequential -r loading reports false missing-module warnings and charges
  # compilation against the runtime budget. Reuse the explicit diagnostic-list
  # gate: native warning flags alone can print a warning and still return zero.
  echo "[runtime-smoke] → strict Elixir compile: $test_dir"
  (cd "$outdir" && "$WITH_TIMEOUT" "$ELIXIR_COMPILE_TIMEOUT_SECS" \
    elixir "$ROOT_DIR/scripts/ci/validate-generated-elixir-warnings.exs" "$beam_dir" "${generated_files[@]}")

  echo "[runtime-smoke] → run: $test_dir ($entry)"
  (cd "$outdir" && "$WITH_TIMEOUT" "$RUNTIME_TIMEOUT_SECS" \
    elixir -pa "$beam_dir" -e '
      Code.ensure_loaded!(Main)
      unless function_exported?(Main, :main, 0), do: raise("Missing Main.main/0")
      Main.main()
    ' >"$beam_dir/stdout")
  # Some contracts observe effects rather than a returned value. Keep their
  # independently authored output expectations beside the Haxe fixture.
  if [[ -f "$abs_test_dir/expected.stdout" ]]; then
    diff -u "$abs_test_dir/expected.stdout" "$beam_dir/stdout"
  fi
)

for test_dir in "${TEST_DIRS[@]}"; do
  run_one "$test_dir"
done

bash "$ROOT_DIR/scripts/ci/runtime-smoke-otp-core.sh"

echo "[runtime-smoke] All runtime smoke tests passed ✅"
