#!/bin/bash

# Setup script to create local haxe_libraries overrides for examples
# This allows examples to work with paths relative to their subdirectories

echo "Setting up example haxe_libraries overrides..."

EXAMPLES=(
  "01-simple-modules"
  "02-mix-project" 
  "03-phoenix-app"
  "04-ecto-migrations"
  "05-heex-templates"
  "06-user-management"
  "07-protocols"
  "08-behaviors"
  "09-phoenix-router"
  "lix-installation"
  "test-integration"
)

for dir in "${EXAMPLES[@]}"; do
  example_dir="examples/$dir"
  if [ -d "$example_dir" ]; then
    echo "Setting up $example_dir"
    
    # Create haxe_libraries directory
    mkdir -p "$example_dir/haxe_libraries"
    
    # Create override reflaxe.elixir.hxml with correct paths
    cat > "$example_dir/haxe_libraries/reflaxe.elixir.hxml" << 'EOF'
# Reflaxe.Elixir Library Configuration for Examples
# Path relative to examples/XX-name/ directory
-cp ../../src/
-cp ../../std/
-lib reflaxe
-D reflaxe.elixir=0.1.0
--macro reflaxe.elixir.CompilerInit.Start()
EOF
    
    # Copy other required library files (but preserve the override)
    for lib_file in haxe_libraries/*.hxml; do
      lib_name=$(basename "$lib_file")
      if [ "$lib_name" != "reflaxe.elixir.hxml" ]; then
        cp "$lib_file" "$example_dir/haxe_libraries/"
      fi
    done
    
    echo "✅ Setup complete for $example_dir"
  else
    echo "⚠️  Directory $example_dir not found, skipping"
  fi
done

echo "🚀 All examples set up with local haxe_libraries overrides"