#!/bin/bash
# Elixir Syntax Validation Script for Test Output
# This script validates that generated Elixir code is syntactically correct
# and can be executed by the BEAM VM

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
RESET='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
WITH_TIMEOUT="${ROOT_DIR}/scripts/util/with-timeout.sh"

# Accept one or more roots to search for `compile.hxml` tests.
# Examples:
#   ./validate_elixir.sh snapshot
#   ./validate_elixir.sh snapshot/core snapshot/stdlib
TEST_DIRS=("$@")
if [ ${#TEST_DIRS[@]} -eq 0 ]; then
    TEST_DIRS=("snapshot")
fi

if [ -n "${ELIXIR_PARSE_TIMEOUT_SECS:-}" ]; then
    PARSE_TIMEOUT_SECS="${ELIXIR_PARSE_TIMEOUT_SECS}"
elif [ -n "${CI:-}" ]; then
    PARSE_TIMEOUT_SECS=60
else
    PARSE_TIMEOUT_SECS=20
fi

VALIDATION_LOG="elixir_validation.log"
FAILED_TESTS=""
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_COUNT=0

is_windows_shell() {
    # MSYS2/Git-Bash environments report MINGW/MSYS/CYGWIN here.
    # We only need to detect this to convert POSIX paths to Windows paths
    # for Windows-native `elixir`/`erl` binaries.
    uname -s 2>/dev/null | grep -qiE 'mingw|msys|cygwin'
}

echo "=== Elixir Syntax Validation ===" | tee "$VALIDATION_LOG"
echo "Validating generated Elixir code in:" | tee -a "$VALIDATION_LOG"
for dir in "${TEST_DIRS[@]}"; do
    echo "  - $dir" | tee -a "$VALIDATION_LOG"
done
echo "Per-test parse timeout: ${PARSE_TIMEOUT_SECS}s" | tee -a "$VALIDATION_LOG"
echo "" | tee -a "$VALIDATION_LOG"

# Validate all .ex files in a test directory by parsing (no execution)
validate_test_directory() {
    local test_dir="$1"
    local test_name=$(basename "$test_dir")
    local parent_name=$(basename $(dirname "$test_dir"))
    
    if [[ "$parent_name" != "snapshot" ]]; then
        test_name="$parent_name/$test_name"
    fi
    
    # Skip if no out directory (test might not have run yet)
    if [ ! -d "$test_dir/out" ]; then
        return 0
    fi
    
    # Find all .ex files in the out directory
    local ex_files=$(find "$test_dir/out" -name "*.ex" -type f 2>/dev/null | sort)
    
    if [ -z "$ex_files" ]; then
        # No Elixir files, might be a JavaScript test
        return 0
    fi
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    # Build one Elixir command to parse all files without executing them
    # Using Code.string_to_quoted/2 avoids running top-level code in files
    local parse_cmd='files = System.argv(); ok = Enum.all?(files, fn f -> case File.read(f) do {:ok, s} -> case Code.string_to_quoted(s, file: f) do {:ok, _} -> true; {:error, reason} -> IO.puts("Syntax error in #{f}: #{inspect(reason)}"); false end; {:error, r} -> IO.puts("Read error in #{f}: #{inspect(r)}"); false end end); if ok, do: :ok, else: System.halt(1)'
    local test_passed=true
    if [ -n "$ex_files" ]; then
        # On Windows runners, `elixir` is a Windows-native executable.
        # Convert MSYS2/Git-Bash POSIX paths to Windows paths explicitly to avoid
        # sporadic "file not found" failures under CI.
        local files=()
        while IFS= read -r f; do
            [ -n "$f" ] || continue
            if is_windows_shell && command -v cygpath >/dev/null 2>&1; then
                if [[ "$f" == /* ]]; then
                    files+=("$(cygpath -w "$f")")
                else
                    files+=("$(cygpath -w "${ROOT_DIR}/${f}")")
                fi
            else
                files+=("$f")
            fi
        done <<< "$ex_files"

        if ! "$WITH_TIMEOUT" "$PARSE_TIMEOUT_SECS" elixir -e "$parse_cmd" "${files[@]}" > /dev/null 2>>"$VALIDATION_LOG"; then
            test_passed=false
        fi
    fi
    
    if $test_passed; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        FAILED_COUNT=$((FAILED_COUNT + 1))
        FAILED_TESTS="$FAILED_TESTS\n  - $test_name"
    fi
}

# Find all test directories with compile.hxml
for root in "${TEST_DIRS[@]}"; do
    for test_dir in $(find "$root" -name compile.hxml -exec dirname {} \; | sort); do
        validate_test_directory "$test_dir"
    done
done

# Summary
echo "" | tee -a "$VALIDATION_LOG"
echo "=== Validation Summary ===" | tee -a "$VALIDATION_LOG"
echo "Total tests validated: $TOTAL_TESTS" | tee -a "$VALIDATION_LOG"
echo -e "${GREEN}Passed: $PASSED_TESTS${RESET}" | tee -a "$VALIDATION_LOG"
echo -e "${RED}Failed: $FAILED_COUNT${RESET}" | tee -a "$VALIDATION_LOG"

if [ $FAILED_COUNT -gt 0 ]; then
    echo -e "\n${RED}Failed tests:${RESET}" | tee -a "$VALIDATION_LOG"
    echo -e "$FAILED_TESTS" | tee -a "$VALIDATION_LOG"
    exit 1
else
    echo -e "\n${GREEN}All Elixir syntax validation passed!${RESET}" | tee -a "$VALIDATION_LOG"
    exit 0
fi
