#!/bin/bash

# Fix compile.hxml files to have correct relative paths from their own directory

echo "Fixing compile.hxml paths to work from test directory..."

find test/snapshot -name "compile.hxml" | while read -r file; do
    test_dir=$(dirname "$file")
    
    # Calculate how many levels deep we are from project root
    depth=$(echo "$test_dir" | tr '/' '\n' | grep -c .)
    
    # Build the relative path to go back to project root
    back_path=""
    for ((i=0; i<depth; i++)); do
        back_path="../$back_path"
    done
    
    # Remove trailing slash
    back_path=${back_path%/}
    
    # Create fixed version
    cat > "$file" << EOF
-cp .
-cp ${back_path}/src
-cp ${back_path}/std
-lib reflaxe
-D reflaxe_runtime
-D elixir_output=out
--macro reflaxe.elixir.CompilerInit.Start()
Main
EOF
done

echo "Done fixing compile.hxml paths"