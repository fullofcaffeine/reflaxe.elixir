#!/bin/bash
# Compile individual Haxe modules for Mix project
# This approach compiles each module separately to ensure they work

set -e  # Exit on any error

echo "🔨 Compiling Haxe modules for Mix project..."

cd "$(dirname "$0")"

# Common compilation flags
COMMON_FLAGS="-cp src_haxe -cp ../../src -cp ../../std -cp ../../test -cp ../../../haxe.elixir.reference/reflaxe/src -D reflaxe_runtime --no-output"

echo ""
echo "1️⃣  Compiling UserService..."
if haxe $COMMON_FLAGS -main services.UserService; then
    echo "✅ UserService compiled successfully"
else
    echo "❌ UserService compilation failed"
    exit 1
fi

echo ""
echo "2️⃣  Compiling StringUtils..."
if haxe $COMMON_FLAGS -main utils.StringUtils; then
    echo "✅ StringUtils compiled successfully"
else
    echo "❌ StringUtils compilation failed"
    exit 1
fi

echo ""
echo "3️⃣  Compiling MathHelper..."
if haxe $COMMON_FLAGS -main utils.MathHelper; then
    echo "✅ MathHelper compiled successfully"
else
    echo "❌ MathHelper compilation failed"
    exit 1
fi

echo ""
echo "4️⃣  Compiling ValidationHelper..."
if haxe $COMMON_FLAGS -main utils.ValidationHelper; then
    echo "✅ ValidationHelper compiled successfully"
else
    echo "❌ ValidationHelper compilation failed"
    exit 1
fi

echo ""
echo "🎉 All Haxe modules compiled successfully!"
echo "✨ Modules are ready for use in the Mix project"