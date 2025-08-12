#!/bin/bash

# Clean fix for all example build.hxml files
# Properly formats the files to use direct source paths

echo "Clean fixing all example build.hxml files..."

# Template for a proper build.hxml
create_build_hxml() {
  local build_file="$1"
  local main_class="$2"
  
  cat > "$build_file" << EOF
# Example build configuration for Reflaxe.Elixir
# This shows the minimal setup needed to compile Haxe to Elixir

# Include Reflaxe.Elixir source directly (for examples running from subdirectories)
-cp ../../src
-cp ../../std
-lib reflaxe

# Source directory containing your .hx files
-cp src_haxe

# Output directory for generated .ex files
-D elixir_output=lib

# Required for Reflaxe targets
-D reflaxe_runtime

# Define library version and initialize compiler
-D reflaxe.elixir=0.1.0
--macro reflaxe.elixir.CompilerInit.Start()

# Main class to compile (entry point)
$main_class
EOF
}

# Fix specific examples
create_build_hxml "examples/02-mix-project/build.hxml" "Main"
create_build_hxml "examples/03-phoenix-app/build.hxml" "phoenix.Application"
create_build_hxml "examples/04-ecto-migrations/build.hxml" "Main"
create_build_hxml "examples/05-heex-templates/build.hxml" "HXX"
create_build_hxml "examples/06-user-management/build.hxml" "HXX"
create_build_hxml "examples/07-protocols/build.hxml" "Main"
create_build_hxml "examples/08-behaviors/build.hxml" "Main"
create_build_hxml "examples/09-phoenix-router/build.hxml" "AppRouter"
create_build_hxml "examples/lix-installation/build.hxml" "Main"
create_build_hxml "examples/test-integration/build.hxml" "test.integration.TestModule"

echo "🚀 All example build.hxml files clean fixed"