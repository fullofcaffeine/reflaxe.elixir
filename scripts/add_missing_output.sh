#!/bin/bash

# Add missing elixir_output directive to test compile.hxml files

echo "Adding missing elixir_output directives..."

# Find all compile.hxml files missing the output directive
find test/snapshot -name "compile.hxml" | while read -r file; do
    if ! grep -q "elixir_output" "$file"; then
        # Get the relative path from project root to the test directory
        test_dir=$(dirname "$file")
        rel_path="${test_dir#./}"  # Remove leading ./
        
        echo "Fixing: $file"
        
        # Find where to insert the directive (after --macro line or after -lib reflaxe)
        if grep -q "^--macro reflaxe.elixir.CompilerInit.Start()" "$file"; then
            # Insert after the macro line
            sed -i.bak '/^--macro reflaxe.elixir.CompilerInit.Start()/a\
-D elixir_output='"$rel_path"'/out' "$file"
        elif grep -q "^-lib reflaxe" "$file"; then
            # Insert after -lib reflaxe
            sed -i.bak '/^-lib reflaxe$/a\
-D elixir_output='"$rel_path"'/out' "$file"
        else
            # Append at the end if neither found
            echo "-D elixir_output=$rel_path/out" >> "$file"
        fi
        
        # Remove backup file
        rm -f "${file}.bak"
    fi
done

echo "Done adding missing output directives."