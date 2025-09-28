#!/bin/bash

# Standardize all compile.hxml files to use consistent format

echo "Standardizing compile.hxml files..."

find test/snapshot -name "compile.hxml" | while read -r file; do
    test_dir=$(dirname "$file")
    rel_path="${test_dir#./}"
    
    # Check if file is missing critical components
    if ! grep -q "^--macro reflaxe.elixir.CompilerInit.Start()" "$file"; then
        echo "Fixing: $file"
        
        # Get the main class (usually last line or Main)
        main_class=$(grep -E "^[A-Z][A-Za-z0-9_]*$" "$file" | tail -1)
        if [ -z "$main_class" ]; then
            main_class="Main"
        fi
        
        # Create standardized version
        cat > "$file" << EOF
-cp $rel_path
-cp src
-cp std
-lib reflaxe
-D reflaxe_runtime
-D elixir_output=$rel_path/out
--macro reflaxe.elixir.CompilerInit.Start()
$main_class
EOF
    fi
done

echo "Done standardizing compile.hxml files"