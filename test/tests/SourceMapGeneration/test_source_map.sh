#!/bin/bash
# Test script to validate source map generation

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "Testing source map generation..."

# Run the Haxe compilation
haxe compile.hxml

# Check if .ex files were generated
if [ ! -f "out/Main.ex" ]; then
    echo -e "${RED}✗ No .ex files generated${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Elixir files generated${NC}"

# Check if .ex.map files were generated
if [ ! -f "out/Main.ex.map" ]; then
    echo -e "${RED}✗ No source map files generated${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Source map files generated${NC}"

# Validate JSON structure
if command -v jq &> /dev/null; then
    # Check if the source map is valid JSON
    if ! jq . out/Main.ex.map > /dev/null 2>&1; then
        echo -e "${RED}✗ Invalid JSON in source map${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ Valid JSON structure${NC}"
    
    # Check Source Map v3 fields
    VERSION=$(jq '.version' out/Main.ex.map)
    if [ "$VERSION" != "3" ]; then
        echo -e "${RED}✗ Wrong source map version: $VERSION${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ Source Map v3 format${NC}"
    
    # Check if mappings exist (will be empty until fixed)
    MAPPINGS=$(jq -r '.mappings' out/Main.ex.map)
    if [ -z "$MAPPINGS" ]; then
        echo -e "${YELLOW}⚠ Empty mappings (expected until post-1.0 implementation)${NC}"
    else
        echo -e "${GREEN}✓ Mappings present: ${MAPPINGS:0:50}...${NC}"
    fi
    
    # Check sources array
    SOURCES=$(jq -r '.sources | length' out/Main.ex.map)
    if [ "$SOURCES" -eq "0" ]; then
        echo -e "${YELLOW}⚠ No source files listed (expected until implementation complete)${NC}"
    else
        echo -e "${GREEN}✓ Source files listed: $SOURCES files${NC}"
        jq '.sources[]' out/Main.ex.map
    fi
else
    echo -e "${YELLOW}⚠ jq not installed, skipping detailed validation${NC}"
fi

echo ""
echo "Source map test complete!"