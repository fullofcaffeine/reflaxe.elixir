#!/bin/bash
#!/bin/bash
# Helper script to run an individual snapshot test using its own compile.hxml
# Mirrors the Makefile invocation to avoid hangs or missing flags.

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

# Run the test exactly like Makefile does
pushd "$TEST_PATH" >/dev/null

# Pick a Haxe command that exists
if command -v haxe >/dev/null 2>&1; then
  HAXE_CMD=(haxe)
elif command -v npx >/dev/null 2>&1; then
  HAXE_CMD=(npx -y haxe)
else
  echo "Error: could not find haxe or npx in PATH" >&2
  exit 2
fi

# Use timeout if available to prevent hangs
if command -v timeout >/dev/null 2>&1; then
  TIMEOUT=(timeout 120s)
else
  TIMEOUT=()
fi

echo "Invoking: ${TIMEOUT[@]} ${HAXE_CMD[@]} -D elixir_output=out -D reflaxe.dont_output_metadata_id compile.hxml"
if "${TIMEOUT[@]}" "${HAXE_CMD[@]}" -D elixir_output=out -D reflaxe.dont_output_metadata_id compile.hxml; then
  echo "✅ Compilation successful"
  if [ -d out ]; then
    echo "Generated files:"
    ls -1 out/*.ex 2>/dev/null | head -5
  fi
else
  rc=$?
  if [ "$rc" -eq 124 ]; then
    echo "❌ Compilation timed out"
  else
    echo "❌ Compilation failed (rc=$rc)"
  fi
  popd >/dev/null
  exit 1
fi

popd >/dev/null
