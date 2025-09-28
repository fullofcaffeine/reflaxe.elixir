#!/bin/bash

# Fix compile.hxml files to reference the correct main class

echo "Fixing main class references in compile.hxml files..."

fixed=0
already_correct=0

find test/snapshot -name "compile.hxml" | while read -r file; do
    test_dir=$(dirname "$file")
    
    # Get the current main class from compile.hxml
    current_main=$(tail -1 "$file" | tr -d '\r\n')
    
    # Check if Main.hx exists
    if [ -f "$test_dir/Main.hx" ]; then
        if [ "$current_main" != "Main" ]; then
            sed -i.bak '$s/.*/Main/' "$file"
            rm "$file.bak"
            echo "Fixed $file: $current_main -> Main"
            ((fixed++))
        else
            ((already_correct++))
        fi
    else
        # Find the first .hx file that likely is the main file
        main_file=$(find "$test_dir" -maxdepth 1 -name "*.hx" -type f | head -1)
        
        if [ -n "$main_file" ]; then
            # Extract class name from filename
            main_class=$(basename "$main_file" .hx)
            
            if [ "$current_main" != "$main_class" ]; then
                sed -i.bak '$s/.*/'"$main_class"'/' "$file"
                rm "$file.bak"
                echo "Fixed $file: $current_main -> $main_class"
                ((fixed++))
            else
                ((already_correct++))
            fi
        else
            echo "Warning: No .hx files found in $test_dir"
        fi
    fi
done

echo "Fixed $fixed files, $already_correct were already correct"