#!/bin/bash

# Script to update all stdlib files (string_tools.ex, balanced_tree.ex, log.ex) in framework tests

# Source files (our idiomatic references)
STRING_TOOLS="test/snapshot/core/arrays/intended/string_tools.ex"
BALANCED_TREE="test/snapshot/core/arrays/intended/haxe/ds/balanced_tree.ex"
LOG="test/snapshot/core/arrays/intended/haxe/log.ex"

echo "=== Updating Standard Library Files in Framework Tests ==="
echo ""

# Counters
string_tools_updated=0
balanced_tree_updated=0
log_updated=0

# Update string_tools.ex files
if [ -f "$STRING_TOOLS" ]; then
    echo "📝 Updating string_tools.ex files..."
    for file in $(find test/snapshot/{phoenix,ecto,otp,stdlib} -name "string_tools.ex" -path "*/intended/*" 2>/dev/null); do
        echo "  → $file"
        cp "$STRING_TOOLS" "$file"
        ((string_tools_updated++))
    done
    echo "  ✅ Updated $string_tools_updated string_tools.ex files"
else
    echo "  ⚠️  Idiomatic string_tools.ex not found at $STRING_TOOLS"
fi

echo ""

# Update balanced_tree.ex files
if [ -f "$BALANCED_TREE" ]; then
    echo "🌳 Updating balanced_tree.ex files..."
    for file in $(find test/snapshot/{phoenix,ecto,otp,stdlib} -path "*/intended/haxe/ds/balanced_tree.ex" 2>/dev/null); do
        echo "  → $file"
        cp "$BALANCED_TREE" "$file"
        ((balanced_tree_updated++))
    done
    echo "  ✅ Updated $balanced_tree_updated balanced_tree.ex files"
else
    echo "  ⚠️  Idiomatic balanced_tree.ex not found at $BALANCED_TREE"
fi

echo ""

# Update log.ex files
if [ -f "$LOG" ]; then
    echo "📋 Updating log.ex files..."
    for file in $(find test/snapshot/{phoenix,ecto,otp,stdlib} -path "*/intended/haxe/log.ex" 2>/dev/null); do
        echo "  → $file"
        cp "$LOG" "$file"
        ((log_updated++))
    done
    echo "  ✅ Updated $log_updated log.ex files"
else
    echo "  ⚠️  Idiomatic log.ex not found at $LOG"
fi

echo ""
echo "=== Summary ==="
echo "✅ string_tools.ex: $string_tools_updated files updated"
echo "✅ balanced_tree.ex: $balanced_tree_updated files updated"
echo "✅ log.ex: $log_updated files updated"
echo ""
total=$((string_tools_updated + balanced_tree_updated + log_updated))
echo "📊 Total: $total stdlib files updated with idiomatic patterns"