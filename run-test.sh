#!/bin/bash
# Helper script to run individual tests properly
# Stays in project root to avoid relative path issues

if [ $# -eq 0 ]; then
    echo "Usage: $0 <test-path>"
    echo "Example: $0 test/snapshot/regression/binary_op_instance_method"
    exit 1
fi

TEST_PATH="$1"
TEST_NAME=$(basename "$TEST_PATH")

# Check if test exists
if [ ! -f "$TEST_PATH/compile.hxml" ]; then
    echo "Error: $TEST_PATH/compile.hxml not found"
    exit 1
fi

echo "Running test: $TEST_NAME"

# Read the original compile.hxml and modify it
# We need to prepend the test path to the classpath
haxe \
    -cp "$TEST_PATH" \
    -D elixir_output="$TEST_PATH/out" \
    -D reflaxe.dont_output_metadata_id \
    -lib reflaxe \
    -lib reflaxe.elixir \
    --no-output \
    -main Main

RESULT=$?

if [ $RESULT -eq 0 ]; then
    echo "✅ Compilation successful"
    if [ -d "$TEST_PATH/out" ]; then
        echo "Generated files:"
        ls -1 "$TEST_PATH/out/"*.ex 2>/dev/null | head -5
    fi
else
    echo "❌ Compilation failed"
    exit 1
fi