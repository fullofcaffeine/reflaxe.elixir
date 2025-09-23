#!/bin/bash

echo "=== Simple Audit of Intended Files ==="
echo ""

# Count total files
total=$(find test -name "*.ex" -path "*/intended/*" | wc -l)
echo "Total intended files found: $total"
echo ""

# Check a sample of files for common syntax issues
echo "Checking for common syntax errors..."
echo ""

# Pattern 1: Method calls on block expressions (e.g., case...end.to_string())
echo "Files with potential .to_string() on block expressions:"
grep -l "end\.to_string()" test/snapshot/*/intended/*.ex test/snapshot/*/*/intended/*.ex 2>/dev/null | head -10

echo ""
echo "Files with case statements followed by method calls:"
grep -l "end\.[a-zA-Z_]" test/snapshot/*/intended/*.ex test/snapshot/*/*/intended/*.ex 2>/dev/null | head -10

# Check specific file we know has issues
echo ""
echo "=== Checking known problematic file ==="
if [ -f "test/snapshot/core/strings/intended/Main.ex" ]; then
    echo "test/snapshot/core/strings/intended/Main.ex exists"
    echo "First 20 lines:"
    head -20 test/snapshot/core/strings/intended/Main.ex
else
    echo "test/snapshot/core/strings/intended/Main.ex not found"
fi

# Try compiling a few files directly
echo ""
echo "=== Testing compilation of sample files ==="
sample_files=$(find test/snapshot -name "*.ex" -path "*/intended/*" | head -5)

for file in $sample_files; do
    echo -n "Testing $file... "
    # Create a temporary file to avoid module conflicts
    temp_file="/tmp/test_$(basename $file)"
    cp "$file" "$temp_file"
    
    # Try to compile
    if elixirc -o /tmp "$temp_file" 2>/dev/null; then
        echo "OK"
    else
        echo "SYNTAX ERROR"
        elixirc -o /tmp "$temp_file" 2>&1 | head -5 | sed 's/^/  /'
    fi
    rm -f "$temp_file"
done