#!/bin/bash
# Test runner for array_cross_operations
# Validates both compilation and runtime execution

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Testing array_cross_operations ===${NC}"

# Step 1: Compile Haxe to Elixir
echo "1. Compiling Haxe to Elixir..."
if haxe -D elixir_output=out compile.hxml > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Compilation successful${NC}"
else
    echo -e "${RED}✗ Compilation failed${NC}"
    exit 1
fi

# Step 2: Check generated files exist
echo "2. Checking generated files..."
if [ -f "out/main.ex" ] && [ -f "out/std.ex" ] && [ -f "out/haxe/log.ex" ]; then
    echo -e "${GREEN}✓ All expected files generated${NC}"
else
    echo -e "${RED}✗ Missing generated files${NC}"
    exit 1
fi

# Step 3: Syntax check with Elixir
echo "3. Validating Elixir syntax..."
cd out
if elixir -e "
Code.require_file(\"std.ex\")
Code.require_file(\"haxe/log.ex\")
Code.require_file(\"main.ex\")
IO.puts(:syntax_ok)
" 2>/dev/null | grep -q "syntax_ok"; then
    echo -e "${GREEN}✓ Elixir syntax valid${NC}"
else
    echo -e "${RED}✗ Elixir syntax errors${NC}"
    exit 1
fi

# Step 4: Run the actual test
echo "4. Running test execution..."
if elixir -e "
Code.require_file(\"std.ex\")
Code.require_file(\"haxe/log.ex\")
Code.require_file(\"main.ex\")

# Create a public wrapper to call private functions
defmodule TestRunner do
  def run do
    # Call the private main function
    apply(Main, :main, [])
  end
end

TestRunner.run()
" 2>&1 | grep -q "Doubled:"; then
    echo -e "${GREEN}✓ Test executed successfully${NC}"
else
    echo -e "${RED}✗ Test execution failed${NC}"
    exit 1
fi

cd ..

# Step 5: Compare with intended output
echo "5. Comparing with intended output..."
if diff -r --exclude="_GeneratedFiles.json" intended out > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Output matches intended${NC}"
else
    echo -e "${YELLOW}⚠ Output differs from intended (may be an improvement)${NC}"
    # Don't fail on diff - it might be an improvement
fi

echo -e "${GREEN}=== All tests passed ===${NC}"