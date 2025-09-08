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
TEST_DIR="${1:-snapshot}"
VALIDATION_LOG="elixir_validation.log"
FAILED_TESTS=""
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_COUNT=0

echo "=== Elixir Syntax Validation ===" | tee "$VALIDATION_LOG"
echo "Validating generated Elixir code in $TEST_DIR" | tee -a "$VALIDATION_LOG"
echo "" | tee -a "$VALIDATION_LOG"

# Function to validate a single Elixir file
validate_elixir_file() {
    local file="$1"
    local test_name="$2"
    
    # Skip files that are known to have dependencies
    if [[ "$file" == *"_GeneratedFiles.json"* ]]; then
        return 0
    fi
    
    # Create a temporary test file that loads and validates the syntax
    local temp_test="/tmp/elixir_test_$$.exs"
    
    cat > "$temp_test" << 'EOF'
# Stub modules that generated code might depend on
defmodule Std do
  def string(v), do: inspect(v)
end

defmodule Log do
  def trace(msg, _metadata), do: :ok
end

defmodule StringTools do
  def ltrim(s), do: String.trim_leading(s)
  def rtrim(s), do: String.trim_trailing(s)
  def replace(s, from, to), do: String.replace(s, from, to)
end

defmodule StringBuf do
  defstruct iolist: []
end

defmodule Type do
  def get_class(_), do: nil
  def get_enum(_), do: nil
end

defmodule Reflect do
  def fields(_), do: []
  def get_property(_, _), do: nil
  def set_property(_, _, _), do: :ok
  def has_field(_, _), do: false
end

# Now try to compile the generated file
EOF
    
    echo "Code.compile_file(\"$file\")" >> "$temp_test"
    
    # Try to validate the Elixir syntax
    if timeout 5s elixir "$temp_test" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${RESET} $test_name: $(basename "$file")"
        rm -f "$temp_test"
        return 0
    else
        # Capture the actual error for debugging
        local error_output=$(timeout 5s elixir "$temp_test" 2>&1 || true)
        echo -e "${RED}✗${RESET} $test_name: $(basename "$file")" | tee -a "$VALIDATION_LOG"
        echo "  Error: $error_output" | head -5 | tee -a "$VALIDATION_LOG"
        rm -f "$temp_test"
        return 1
    fi
}

# Function to validate all .ex files in a test directory
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
    local ex_files=$(find "$test_dir/out" -name "*.ex" -type f 2>/dev/null)
    
    if [ -z "$ex_files" ]; then
        # No Elixir files, might be a JavaScript test
        return 0
    fi
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    local test_passed=true
    for file in $ex_files; do
        if ! validate_elixir_file "$file" "$test_name"; then
            test_passed=false
            break
        fi
    done
    
    if $test_passed; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        FAILED_COUNT=$((FAILED_COUNT + 1))
        FAILED_TESTS="$FAILED_TESTS\n  - $test_name"
    fi
}

# Find all test directories with compile.hxml
for test_dir in $(find "$TEST_DIR" -name compile.hxml -exec dirname {} \; | sort); do
    validate_test_directory "$test_dir"
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