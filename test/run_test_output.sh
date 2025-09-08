#!/bin/bash
# Run the generated output of a specific test
# Usage: ./run_test_output.sh <test_path> [file_to_run]
# Example: ./run_test_output.sh snapshot/stdlib/array_cross_operations

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ -z "$1" ]; then
    echo "Usage: $0 <test_path> [file_to_run]"
    echo "Example: $0 snapshot/stdlib/array_cross_operations"
    exit 1
fi

TEST_PATH="$1"
FILE_TO_RUN="${2:-main.ex}"
OUTPUT_DIR="$TEST_PATH/out"

if [ ! -d "$OUTPUT_DIR" ]; then
    echo -e "${RED}❌ No output directory found at $OUTPUT_DIR${NC}"
    echo "Run the test first to generate output"
    exit 1
fi

if [ ! -f "$OUTPUT_DIR/$FILE_TO_RUN" ]; then
    echo -e "${RED}❌ File not found: $OUTPUT_DIR/$FILE_TO_RUN${NC}"
    echo "Available files:"
    ls -la "$OUTPUT_DIR"/*.ex 2>/dev/null || echo "No .ex files found"
    exit 1
fi

echo -e "${YELLOW}Running $OUTPUT_DIR/$FILE_TO_RUN...${NC}"
cd "$OUTPUT_DIR"

# Load dependencies if they exist
DEPS=""
[ -f "std.ex" ] && DEPS="$DEPS -r std.ex"
[ -f "haxe/log.ex" ] && DEPS="$DEPS -r haxe/log.ex"

# Run the file and try to call main() if it exists
if [ -n "$DEPS" ]; then
    elixir $DEPS -r "$FILE_TO_RUN" -e "
        if function_exported?(Main, :main, 0) do
            Main.main()
        else
            IO.puts('No main/0 function found in Main module')
        end
    "
else
    elixir -r "$FILE_TO_RUN" -e "
        if function_exported?(Main, :main, 0) do
            Main.main()
        else
            IO.puts('No main/0 function found in Main module')
        end
    "
fi

echo -e "${GREEN}✓ Execution complete${NC}"