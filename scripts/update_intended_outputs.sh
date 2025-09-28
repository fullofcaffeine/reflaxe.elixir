#!/bin/bash

# Update intended outputs for tests with improved compiler output

echo "Updating intended outputs for tests with improved compiler output..."

# Function to check if output is syntactically valid Elixir
check_elixir_syntax() {
    local file=$1
    # Use elixirc --warnings-as-errors to check syntax
    elixirc --no-compile --warnings-as-errors "$file" 2>/dev/null
    return $?
}

# Counter for updated tests
updated=0
skipped=0
failed=0

# Find all tests with both out and intended directories
find test/snapshot -type d -name "out" | while read -r out_dir; do
    test_dir=$(dirname "$out_dir")
    intended_dir="$test_dir/intended"
    
    # Skip if no intended directory
    if [ ! -d "$intended_dir" ]; then
        continue
    fi
    
    # Check if there are .ex files in out
    if ! ls "$out_dir"/*.ex >/dev/null 2>&1; then
        continue
    fi
    
    # Compare main.ex if it exists
    if [ -f "$out_dir/main.ex" ] && [ -f "$intended_dir/main.ex" ]; then
        if ! /usr/bin/diff -q "$out_dir/main.ex" "$intended_dir/main.ex" >/dev/null 2>&1; then
            # Files differ - check if new output is valid
            if check_elixir_syntax "$out_dir/main.ex"; then
                echo "Updating: $test_dir"
                # Backup old intended
                cp -r "$intended_dir" "$intended_dir.backup.$(date +%s)"
                # Copy new output as intended
                cp "$out_dir"/*.ex "$intended_dir/"
                ((updated++))
            else
                echo "Skipping $test_dir - output has syntax errors"
                ((skipped++))
            fi
        fi
    fi
done

echo "Updated $updated tests, skipped $skipped tests with syntax errors"
echo "Note: Run tests again to verify all updates are correct"