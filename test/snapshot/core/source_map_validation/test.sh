#!/bin/bash

# Source Map Validation Test
# Follows Reflaxe testing pattern

echo "=== Source Map Structure Validation Test ==="
echo ""

# Compile the test
echo "Compiling test..."
npx haxe compile.hxml 2>&1 | grep -v "not yet fully supported" || true

# Check if source maps were generated
echo ""
echo "Checking source map generation..."

MAP_COUNT=$(ls -1 out/*.ex.map 2>/dev/null | wc -l)
if [ "$MAP_COUNT" -eq 0 ]; then
    echo "❌ FAIL: No source maps generated"
    exit 1
fi

echo "✅ Generated $MAP_COUNT source map files"

# Validate main test file source map
MAIN_MAP="out/SourceMapValidationTest.ex.map"
if [ ! -f "$MAIN_MAP" ]; then
    echo "❌ FAIL: Main test source map not found"
    exit 1
fi

echo ""
echo "Validating main source map structure..."

# Check for required fields
ERRORS=0

# Check version
if ! grep -q '"version": 3' "$MAIN_MAP"; then
    echo "❌ Missing or invalid version field"
    ERRORS=$((ERRORS + 1))
else
    echo "✅ Version field valid (v3)"
fi

# Check file field
if ! grep -q '"file": "SourceMapValidationTest.ex"' "$MAIN_MAP"; then
    echo "❌ Missing or invalid file field"
    ERRORS=$((ERRORS + 1))
else
    echo "✅ File field valid"
fi

# Check sources array references .hx file
if ! grep -q '"SourceMapValidationTest.hx"' "$MAIN_MAP"; then
    echo "❌ Sources array doesn't reference Haxe source"
    ERRORS=$((ERRORS + 1))
else
    echo "✅ Sources array references Haxe file"
fi

# Check mappings exist and are non-empty
MAPPINGS=$(grep '"mappings":' "$MAIN_MAP" | sed 's/.*"mappings": "\(.*\)".*/\1/')
if [ -z "$MAPPINGS" ] || [ "$MAPPINGS" = '""' ]; then
    echo "❌ Mappings field is empty"
    ERRORS=$((ERRORS + 1))
else
    MAPPING_LENGTH=${#MAPPINGS}
    echo "✅ Mappings field contains VLQ data ($MAPPING_LENGTH characters)"
fi

# Check sourceRoot field exists
if ! grep -q '"sourceRoot":' "$MAIN_MAP"; then
    echo "❌ Missing sourceRoot field"
    ERRORS=$((ERRORS + 1))
else
    echo "✅ SourceRoot field present"
fi

# Check names array exists  
if ! grep -q '"names":' "$MAIN_MAP"; then
    echo "❌ Missing names array"
    ERRORS=$((ERRORS + 1))
else
    echo "✅ Names array present"
fi

echo ""
echo "=== Test Summary ==="

if [ $ERRORS -eq 0 ]; then
    echo "🎉 All validations passed!"
    echo ""
    echo "Source map statistics:"
    echo "- Total maps generated: $MAP_COUNT"
    echo "- Main map size: $(wc -c < "$MAIN_MAP") bytes"
    echo "- Mappings length: $MAPPING_LENGTH characters"
    echo ""
    echo "✅ Source map generation is working correctly"
    exit 0
else
    echo "❌ $ERRORS validation(s) failed"
    echo ""
    echo "Source maps are being generated but have structural issues."
    echo "See errors above for details."
    exit 1
fi