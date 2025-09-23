#!/bin/bash

# Script to find and report all syntax errors in intended/*.ex files
# This helps identify and fix any invalid Elixir code

echo "=== Finding All Syntax Errors in Intended Files ==="
echo ""

# Create temp directory
temp_dir=$(mktemp -d)
trap "rm -rf $temp_dir" EXIT

# Results file
results_file="/tmp/syntax_errors_report.txt"
> "$results_file"

# Stats
total=0
errors=0
fixed=0

echo "Scanning all intended/*.ex files for syntax errors..."
echo ""

# Process each file
find test/snapshot -name "*.ex" -path "*/intended/*" | sort | while read -r file; do
    total=$((total + 1))
    
    # Show progress
    if [ $((total % 100)) -eq 0 ]; then
        echo "Checked $total files..."
    fi
    
    # Create a unique temp file to avoid module conflicts
    basename=$(basename "$file" .ex)
    temp_file="$temp_dir/${basename}_$$.ex"
    cp "$file" "$temp_file"
    
    # Try to compile
    error_output=$(elixirc -o "$temp_dir" "$temp_file" 2>&1)
    exit_code=$?
    
    if [ $exit_code -ne 0 ]; then
        # Filter out just warnings about module redefinition
        if echo "$error_output" | grep -q "warning: redefining module" && \
           ! echo "$error_output" | grep -q "Compilation error\|SyntaxError\|CompileError"; then
            # Just a warning, not an actual error
            :
        else
            errors=$((errors + 1))
            echo "❌ ERROR in: $file" | tee -a "$results_file"
            echo "$error_output" | head -20 | tee -a "$results_file"
            echo "---" | tee -a "$results_file"
            
            # Check for common fixable patterns
            if echo "$error_output" | grep -q "invalid syntax.*:281:1"; then
                echo "  → Detected duplicate 'end' statement" | tee -a "$results_file"
            fi
            if echo "$error_output" | grep -q "\.to_string()"; then
                echo "  → Detected method call on block expression" | tee -a "$results_file"
            fi
        fi
    fi
    
    # Clean up
    rm -f "$temp_file"
done

echo ""
echo "=== SUMMARY ==="
echo "Total files scanned: $(find test/snapshot -name "*.ex" -path "*/intended/*" | wc -l)"
echo "Files with syntax errors: $errors"

if [ $errors -gt 0 ]; then
    echo ""
    echo "Error report saved to: $results_file"
    echo ""
    echo "=== Common Patterns Found ==="
    
    # Check for specific patterns
    echo -n "Files with duplicate 'end' statements: "
    find test/snapshot -name "*.ex" -path "*/intended/*" -exec grep -l "^end$" {} \; | \
        xargs -I {} sh -c 'if [ $(grep -c "^end$" {} ) -gt 1 ]; then echo {}; fi' | wc -l
    
    echo -n "Files with .to_string() on blocks: "
    find test/snapshot -name "*.ex" -path "*/intended/*" -exec grep -l "end\.to_string()" {} \; 2>/dev/null | wc -l
    
    echo ""
    echo "To fix these errors:"
    echo "1. Review the error report at $results_file"
    echo "2. Fix the syntax errors in the intended files"
    echo "3. Re-run this script to verify all errors are fixed"
else
    echo ""
    echo "✅ All intended files have valid Elixir syntax!"
fi