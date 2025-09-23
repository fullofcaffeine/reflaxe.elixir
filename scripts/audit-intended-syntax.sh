#!/bin/bash

# Script to audit all intended/*.ex files for Elixir syntax errors
# This helps identify invalid Elixir code in our test expectations

echo "=== Auditing all intended/*.ex files for syntax errors ==="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
total_files=0
error_files=0
success_files=0

# Create temp directory for compilation output
temp_dir=$(mktemp -d)
trap "rm -rf $temp_dir" EXIT

# Store files with errors
error_files_list=""

# Process files in parallel for speed
echo "Checking syntax of all intended files..."

# Find and process all files
find test -name "*.ex" -path "*/intended/*" | while read -r file; do
    total_files=$((total_files + 1))
    
    # Use timeout to prevent hanging
    if timeout 2 elixirc --no-compile --no-debug-info -o "$temp_dir" "$file" >/dev/null 2>&1; then
        echo -n "."
    else
        echo ""
        echo -e "${RED}✗ Syntax error in:${NC} $file"
        # Get the actual error
        error_output=$(timeout 2 elixirc --no-compile -o "$temp_dir" "$file" 2>&1 | head -10)
        echo "$error_output" | sed 's/^/  /'
        error_files_list="${error_files_list}${file}\n"
        error_files=$((error_files + 1))
    fi
    
    # Progress indicator every 100 files
    if [ $((total_files % 100)) -eq 0 ]; then
        echo " [$total_files files checked]"
    fi
done

echo ""
echo ""
echo "=== Summary ==="
echo "Total files to check: $(find test -name "*.ex" -path "*/intended/*" | wc -l)"

# If we found errors, list them
if [ -n "$error_files_list" ]; then
    echo ""
    echo -e "${RED}Files with syntax errors:${NC}"
    echo -e "$error_files_list"
    
    echo ""
    echo "Common patterns to fix:"
    echo "1. case...end.to_string() → (case...end) |> Kernel.to_string()"
    echo "2. if...end.to_string() → (if...end) |> Kernel.to_string()"
    echo "3. Block expressions as method targets need parentheses"
else
    echo -e "${GREEN}All intended outputs appear to have valid Elixir syntax!${NC}"
fi

# More detailed check on a subset for debugging
echo ""
echo "=== Detailed check on core tests ==="
for pattern in "strings" "array" "basic"; do
    echo "Checking $pattern tests..."
    find test -name "*.ex" -path "*/$pattern/intended/*" 2>/dev/null | head -5 | while read -r file; do
        if [ -f "$file" ]; then
            if elixirc --no-compile --no-debug-info -o "$temp_dir" "$file" >/dev/null 2>&1; then
                echo -e "  ${GREEN}✓${NC} $(basename $file)"
            else
                echo -e "  ${RED}✗${NC} $(basename $file)"
                elixirc --no-compile -o "$temp_dir" "$file" 2>&1 | head -5 | sed 's/^/    /'
            fi
        fi
    done
done