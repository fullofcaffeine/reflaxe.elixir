#!/bin/bash
#!/bin/bash
# Single-test runner (delegates to Makefile)
#
# WHY
# - Keep Make as the single source of truth for flags, timeouts, and syntax checks.
# - Provide a convenient wrapper so devs can run: `./run-test.sh test/snapshot/<path>`
#
# USAGE
#   ./run-test.sh test/snapshot/regression/ImplicitImports
#   ./run-test.sh regression/ImplicitImports
#
# Internally this calls: make -C test single TEST=<relative-path-under-snapshot>

if [ $# -eq 0 ]; then
    echo "Usage: $0 <test-path>"
    echo "Example: $0 test/snapshot/regression/binary_op_instance_method"
    exit 1
fi

TEST_ARG="$1"

# Normalize argument to a path under test/snapshot/
if [[ "$TEST_ARG" == test/snapshot/* ]]; then
  REL="${TEST_ARG#test/snapshot/}"
else
  REL="$TEST_ARG"
fi

TEST_PATH="test/snapshot/$REL"
TEST_NAME=$(basename "$REL")

# Check if test exists
if [ ! -f "$TEST_PATH/compile.hxml" ]; then
    echo "Error: $TEST_PATH/compile.hxml not found"
    exit 1
fi

echo "[run-test] Delegating to Make: regression path '$REL'"
echo "[run-test] -> make -C test single TEST=$REL"
make -C test single TEST="$REL"
