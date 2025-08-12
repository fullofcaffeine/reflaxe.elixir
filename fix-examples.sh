#!/bin/bash

# Fix all example build.hxml files to use direct source paths
# This avoids the library resolution issue that prevents examples from working

echo "Fixing example build.hxml files to use direct source paths..."

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
  build_file="examples/$dir/build.hxml"
  if [ -f "$build_file" ]; then
    echo "Fixing $build_file"
    
    # Replace -lib reflaxe.elixir with direct source paths
    sed -i.backup 's/-lib reflaxe\.elixir/-cp ..\/..\/src\n-cp ..\/..\/std\n-lib reflaxe/' "$build_file"
    
    # Add macro initialization if not present
    if ! grep -q "reflaxe.elixir.CompilerInit.Start" "$build_file"; then
      echo "--macro reflaxe.elixir.CompilerInit.Start()" >> "$build_file"
    fi
    
    # Add version define if not present  
    if ! grep -q "reflaxe.elixir=" "$build_file"; then
      echo "-D reflaxe.elixir=0.1.0" >> "$build_file"
    fi
    
    rm -f "$build_file.backup"
    echo "✅ Fixed $build_file"
  else
    echo "⚠️  File $build_file not found, skipping"
  fi
done

# Remove failed local haxe_libraries directories
echo "Removing failed local haxe_libraries overrides..."
for dir in "${EXAMPLES[@]}"; do
  if [ -d "examples/$dir/haxe_libraries" ]; then
    rm -rf "examples/$dir/haxe_libraries"
    echo "✅ Removed examples/$dir/haxe_libraries"
  fi
done

echo "🚀 All examples fixed to use direct source paths"