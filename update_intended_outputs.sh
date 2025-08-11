#!/bin/bash

# Update all intended directories with standard library files from function body compilation fix

echo "🔧 Updating intended outputs for snapshot tests after function body compilation fix..."

# Find all test directories with compile.hxml files
test_dirs=$(find test/tests -name "compile.hxml" -exec dirname {} \; | sort)

for test_dir in $test_dirs; do
    echo "Processing $test_dir..."
    
    # Check if this test has an intended directory
    intended_dir="$test_dir/intended"
    if [ -d "$intended_dir" ]; then
        echo "  📁 Found intended directory: $intended_dir"
        
        # Compile the test to generate current output
        cd "$test_dir"
        echo "  ⚙️ Compiling to generate standard library files..."
        npx haxe compile.hxml > /dev/null 2>&1
        
        # Find the output directory (usually 'out')
        out_dir=""
        if [ -d "out" ]; then
            out_dir="out"
        elif [ -d "advanced_queries_out" ]; then
            out_dir="advanced_queries_out"  
        elif [ -d "performance_out" ]; then
            out_dir="performance_out"
        elif [ -d "macro_out" ]; then
            out_dir="macro_out"
        fi
        
        if [ -n "$out_dir" ] && [ -d "$out_dir" ]; then
            echo "  📋 Found output directory: $out_dir"
            
            # Copy all .ex files and _GeneratedFiles.txt from output to intended
            echo "  📝 Copying generated files to intended..."
            cp "$out_dir"/*.ex "$intended_dir/" 2>/dev/null
            cp "$out_dir"/_GeneratedFiles.txt "$intended_dir/" 2>/dev/null
            
            echo "  ✅ Updated intended directory"
        else
            echo "  ⚠️ No output directory found, skipping"
        fi
        
        cd - > /dev/null
    else
        echo "  ⚠️ No intended directory found, skipping"
    fi
    echo ""
done

echo "🎉 Finished updating all intended outputs!"
echo "🧪 Run 'npm test' to verify all snapshot tests now pass"