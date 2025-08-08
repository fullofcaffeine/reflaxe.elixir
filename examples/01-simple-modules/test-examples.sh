#!/bin/bash
# Test script for simple module examples
# Verifies that all examples compile successfully

set -e  # Exit on any error

echo "🧪 Testing Simple Module Examples"
echo "================================"

# Change to examples directory
cd "$(dirname "$0")"

echo ""
echo "📁 Current directory: $(pwd)"
echo "📋 Files present:"
ls -la

echo ""
echo "🔨 Compiling all examples..."

# Test individual compilations first
echo ""
echo "1️⃣  Compiling BasicModule..."
if haxe BasicModule.hxml; then
    echo "✅ BasicModule compilation successful"
else
    echo "❌ BasicModule compilation failed"
    exit 1
fi

echo ""
echo "2️⃣  Compiling MathHelper..."
if haxe MathHelper.hxml; then
    echo "✅ MathHelper compilation successful"
else
    echo "❌ MathHelper compilation failed"
    exit 1
fi

echo ""
echo "3️⃣  Compiling UserUtil..."
if haxe UserUtil.hxml; then
    echo "✅ UserUtil compilation successful"
else
    echo "❌ UserUtil compilation failed"
    exit 1
fi

echo ""
echo "🎯 Testing batch compilation..."
if haxe compile-all.hxml; then
    echo "✅ Batch compilation successful"
else
    echo "❌ Batch compilation failed"
    exit 1
fi

echo ""
echo "📂 Checking output files..."
if [ -d "output" ]; then
    echo "Output directory exists:"
    ls -la output/
else
    echo "⚠️  No output directory found (expected for --no-output flag)"
fi

echo ""
echo "🎉 All simple module examples compiled successfully!"
echo ""
echo "💡 Next steps:"
echo "   • Review the generated output (if any)"
echo "   • Compare with expected/ directory"
echo "   • Try modifying the examples and recompiling"
echo "   • Move on to ../02-mix-project/ for more advanced examples"