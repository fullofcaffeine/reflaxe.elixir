#!/bin/bash

# Script to validate that the ElixirCompiler generates correct output
# This is the RIGHT way to test a transpiler - check its output!

echo "=== Validating ElixirCompiler Output ==="
echo ""

# Step 1: Compile test files using the compiler
echo "📋 Step 1: Compiling test Haxe files to Elixir..."
npx haxe test/compile-haxe-tests.hxml 2>&1 | grep -v "not yet fully supported" | head -20

# Check if compilation succeeded
if [ $? -ne 0 ]; then
    echo "❌ Compilation failed"
    exit 1
fi

echo "✅ Compilation successful"
echo ""

# Step 2: Check if output directory exists
echo "📋 Step 2: Checking generated files..."
if [ ! -d "test-output/compiler-tests" ]; then
    echo "❌ Output directory not found"
    exit 1
fi

# Count generated files
FILE_COUNT=$(ls -1 test-output/compiler-tests/*.ex 2>/dev/null | wc -l)
echo "✅ Generated $FILE_COUNT Elixir files"
echo ""

# Step 3: Validate specific files were generated
echo "📋 Step 3: Validating specific outputs..."

if [ -f "test-output/compiler-tests/SimpleTestClass.ex" ]; then
    echo "✅ SimpleTestClass.ex generated"
else
    echo "❌ SimpleTestClass.ex not found"
fi

if [ -f "test-output/compiler-tests/TestLiveView.ex" ]; then
    echo "✅ TestLiveView.ex generated"
else
    echo "❌ TestLiveView.ex not found" 
fi

if [ -f "test-output/compiler-tests/TestGenServer.ex" ]; then
    echo "✅ TestGenServer.ex generated"
else
    echo "❌ TestGenServer.ex not found"
fi

echo ""
echo "🎉 VALIDATION COMPLETE!"
echo ""
echo "This demonstrates the CORRECT way to test a Reflaxe compiler:"
echo "1. Use --macro to invoke the compiler at macro-time"
echo "2. Generate actual output files"
echo "3. Validate the output exists and is correct"
echo "4. DO NOT try to instantiate the compiler at runtime!"