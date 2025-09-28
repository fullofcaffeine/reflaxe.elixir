#!/bin/bash

# Fix test compile.hxml files to have correct paths when run from project root

echo "Fixing test compile.hxml paths..."

# Find all compile.hxml files in test directories
find test/snapshot -name "compile.hxml" | while read -r file; do
    # Get the relative path from project root to the test directory
    test_dir=$(dirname "$file")
    rel_path="${test_dir#./}"  # Remove leading ./
    
    # Check if file has incorrect relative paths (../../../../ or ../../../)
    if grep -q "../../../../" "$file" || grep -q "../../../" "$file"; then
        echo "Fixing: $file"
        
        # Create temporary file with corrected paths
        cat "$file" | sed \
            -e 's|^-cp ../../../../std$|-cp std|' \
            -e 's|^-cp ../../../../src$|-cp src|' \
            -e 's|^-cp ../../../std$|-cp std|' \
            -e 's|^-cp ../../../src$|-cp src|' \
            -e 's|^-cp \.$|-cp '"$rel_path"'|' \
            -e 's|^-D elixir_output=out$|-D elixir_output='"$rel_path"'/out|' \
            -e 's|^-D elixir_output=intended$|-D elixir_output='"$rel_path"'/intended|' \
            > "${file}.tmp"
        
        # Replace original file
        mv "${file}.tmp" "$file"
    fi
done

echo "Done fixing test paths."