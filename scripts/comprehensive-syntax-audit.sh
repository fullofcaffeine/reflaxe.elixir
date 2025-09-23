#!/bin/bash

# Comprehensive syntax audit for all intended/*.ex files
# This script checks every file and logs errors for fixing

echo "=== Comprehensive Syntax Audit of All Intended Files ==="
echo "Starting at: $(date)"
echo ""

# Create temp directory for output
temp_dir=$(mktemp -d)
trap "rm -rf $temp_dir" EXIT

# Log files
error_log="$temp_dir/syntax_errors.log"
success_log="$temp_dir/syntax_success.log"
summary_log="$temp_dir/summary.log"

# Counters
total=0
success=0
errors=0

# Process each file
echo "Processing files..."
find test -name "*.ex" -path "*/intended/*" | sort | while read -r file; do
    total=$((total + 1))
    
    # Create a temp copy to avoid module conflicts
    temp_file="$temp_dir/test_$(basename $file)"
    cp "$file" "$temp_file"
    
    # Try to compile with elixirc
    if elixirc -o "$temp_dir" "$temp_file" 2>"$temp_dir/compile_error.txt"; then
        echo "$file" >> "$success_log"
        success=$((success + 1))
        echo -n "."
    else
        echo "$file" >> "$error_log"
        echo "ERROR in: $file" >> "$error_log"
        cat "$temp_dir/compile_error.txt" >> "$error_log"
        echo "---" >> "$error_log"
        errors=$((errors + 1))
        echo -n "E"
    fi
    
    # Clean up temp file
    rm -f "$temp_file"
    
    # Progress indicator every 100 files
    if [ $((total % 100)) -eq 0 ]; then
        echo " [$total processed]"
    fi
done

echo ""
echo ""
echo "=== Summary ==="
echo "Total files processed: $(find test -name "*.ex" -path "*/intended/*" | wc -l)"

if [ -f "$error_log" ]; then
    error_count=$(grep "^ERROR in:" "$error_log" 2>/dev/null | wc -l)
    echo "Files with syntax errors: $error_count"
    
    if [ $error_count -gt 0 ]; then
        echo ""
        echo "=== First 10 Files with Errors ==="
        grep "^ERROR in:" "$error_log" | head -10 | sed 's/ERROR in: /  - /'
        
        echo ""
        echo "=== Sample Error Details ==="
        # Show first error in detail
        head -30 "$error_log"
        
        # Save full error log
        cp "$error_log" /tmp/intended_syntax_errors_full.log
        echo ""
        echo "Full error log saved to: /tmp/intended_syntax_errors_full.log"
    fi
else
    echo "All files compiled successfully!"
fi

if [ -f "$success_log" ]; then
    success_count=$(wc -l < "$success_log")
    echo "Files compiled successfully: $success_count"
fi

# Check for specific problematic patterns
echo ""
echo "=== Pattern Analysis ==="

echo -n "Files with 'end.to_string()' pattern: "
find test -name "*.ex" -path "*/intended/*" -exec grep -l "end\.to_string()" {} \; 2>/dev/null | wc -l

echo -n "Files with 'end.method()' patterns: "
find test -name "*.ex" -path "*/intended/*" -exec grep -l "end\.[a-z_][a-z0-9_]*(" {} \; 2>/dev/null | wc -l

echo -n "Files with potential block expression issues: "
find test -name "*.ex" -path "*/intended/*" -exec grep -l "case.*end\." {} \; 2>/dev/null | wc -l

echo ""
echo "Completed at: $(date)"