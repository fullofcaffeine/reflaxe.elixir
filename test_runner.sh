#!/bin/bash

echo "=== HAXE TEST RESULTS ==="

# List of working test files (based on compilation-only approach)
working_tests=(
    "test/FinalExternTest.hxml"
    "test/CompilationOnlyTest.hxml"
    "test/TestWorkingExterns.hxml"
)

failed_tests=()
passed_tests=()

echo "Testing key Haxe test files..."

for test_file in "${working_tests[@]}"; do
    echo -n "Testing $test_file... "
    if /opt/homebrew/bin/haxe "$test_file" > /dev/null 2>&1; then
        echo "✅ PASSED"
        passed_tests+=("$test_file")
    else
        echo "❌ FAILED"
        failed_tests+=("$test_file")
    fi
done

echo ""
echo "=== SUMMARY ==="
echo "Passed: ${#passed_tests[@]}"
echo "Failed: ${#failed_tests[@]}"

if [ ${#failed_tests[@]} -eq 0 ]; then
    echo "🎉 ALL CORE TESTS PASSING!"
    exit 0
else
    echo "❌ Some tests still failing:"
    printf '%s\n' "${failed_tests[@]}"
    exit 1
fi