#!/bin/bash

# Final comprehensive syntax audit script
# This properly handles subprocess variable counting

echo "=== Final Syntax Audit of All Intended Files ==="
echo "Date: $(date)"
echo ""

# Create temp directory
temp_dir=$(mktemp -d)
trap "rm -rf $temp_dir" EXIT

# Create result files
error_files="$temp_dir/errors.txt"
success_files="$temp_dir/success.txt"
all_files="$temp_dir/all_files.txt"

# Find all intended .ex files
find test/snapshot -name "*.ex" -path "*/intended/*" | sort > "$all_files"
total_count=$(wc -l < "$all_files")

echo "Found $total_count intended/*.ex files to audit"
echo ""

# Process each file
echo "Checking syntax of each file..."
file_num=0

while IFS= read -r file; do
    file_num=$((file_num + 1))
    
    # Show progress
    if [ $((file_num % 100)) -eq 0 ]; then
        echo "Progress: $file_num/$total_count"
    fi
    
    # Create temp module to avoid conflicts
    temp_file="$temp_dir/test_$(echo "$file" | md5).ex"
    cp "$file" "$temp_file"
    
    # Try to compile
    if elixirc -o "$temp_dir/beam" "$temp_file" >/dev/null 2>&1; then
        echo "$file" >> "$success_files"
    else
        echo "$file" >> "$error_files"
        # Capture error details
        echo "=== ERROR in $file ===" >> "$temp_dir/error_details.log"
        elixirc -o "$temp_dir/beam" "$temp_file" 2>&1 >> "$temp_dir/error_details.log"
        echo "" >> "$temp_dir/error_details.log"
    fi
    
    # Clean up
    rm -f "$temp_file"
    rm -rf "$temp_dir/beam"
done < "$all_files"

echo ""
echo "=== RESULTS ==="

# Count results
if [ -f "$success_files" ]; then
    success_count=$(wc -l < "$success_files")
else
    success_count=0
fi

if [ -f "$error_files" ]; then
    error_count=$(wc -l < "$error_files")
else
    error_count=0
fi

echo "Total files checked: $total_count"
echo "✅ Files with valid syntax: $success_count"
echo "❌ Files with syntax errors: $error_count"

# Show errors if any
if [ $error_count -gt 0 ]; then
    echo ""
    echo "=== Files with Syntax Errors ==="
    cat "$error_files" | head -20
    
    if [ $error_count -gt 20 ]; then
        echo "... and $((error_count - 20)) more"
    fi
    
    # Save detailed error log
    if [ -f "$temp_dir/error_details.log" ]; then
        cp "$temp_dir/error_details.log" /tmp/intended_syntax_errors.log
        echo ""
        echo "Detailed error log saved to: /tmp/intended_syntax_errors.log"
        echo ""
        echo "=== Sample Error ==="
        head -20 "$temp_dir/error_details.log"
    fi
else
    echo ""
    echo "🎉 ALL FILES HAVE VALID ELIXIR SYNTAX!"
fi

# Check for specific patterns that might cause issues
echo ""
echo "=== Pattern Search ==="

# These patterns might not cause syntax errors but are non-idiomatic
echo -n "Files with 'g_' variable names (generated vars): "
find test/snapshot -name "*.ex" -path "*/intended/*" -exec grep -l '\bg_[0-9]' {} \; 2>/dev/null | wc -l

echo -n "Files with 'elem(' calls (non-idiomatic pattern matching): "
find test/snapshot -name "*.ex" -path "*/intended/*" -exec grep -l 'elem(' {} \; 2>/dev/null | wc -l

echo -n "Files with reduce_while (often non-idiomatic): "
find test/snapshot -name "*.ex" -path "*/intended/*" -exec grep -l 'reduce_while' {} \; 2>/dev/null | wc -l

echo ""
echo "Audit completed at: $(date)"