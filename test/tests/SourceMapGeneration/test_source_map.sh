#!/bin/bash
# Test script to validate source map generation

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${BLUE}     Source Map Generation Test Suite${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo ""

# Clean previous output
echo "🧹 Cleaning previous output..."
rm -rf out/

# Run the Haxe compilation with source maps enabled
echo "🔨 Compiling Haxe to Elixir with source maps..."
if ! haxe compile.hxml 2>&1; then
    echo -e "${RED}✗ Compilation failed${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}── File Generation Checks ──${NC}"

# Check if .ex files were generated
if [ ! -f "out/Main.ex" ]; then
    echo -e "${RED}✗ No .ex files generated${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Elixir file generated: out/Main.ex${NC}"

# Check file size
EX_SIZE=$(wc -c < "out/Main.ex")
echo -e "${GREEN}✓ Elixir file size: ${EX_SIZE} bytes${NC}"

# Check if .ex.map files were generated
if [ ! -f "out/Main.ex.map" ]; then
    echo -e "${RED}✗ No source map file generated${NC}"
    echo -e "${RED}  Expected: out/Main.ex.map${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Source map file generated: out/Main.ex.map${NC}"

# Check source map file size
MAP_SIZE=$(wc -c < "out/Main.ex.map")
echo -e "${GREEN}✓ Source map file size: ${MAP_SIZE} bytes${NC}"

echo ""
echo -e "${BLUE}── Source Map Validation ──${NC}"

# Validate JSON structure
if command -v jq &> /dev/null; then
    # Check if the source map is valid JSON
    if ! jq . out/Main.ex.map > /dev/null 2>&1; then
        echo -e "${RED}✗ Invalid JSON in source map${NC}"
        echo "  First 100 chars of file:"
        head -c 100 out/Main.ex.map
        exit 1
    fi
    echo -e "${GREEN}✓ Valid JSON structure${NC}"
    
    # Check Source Map v3 required fields
    echo ""
    echo -e "${BLUE}── Source Map v3 Specification Compliance ──${NC}"
    
    # Version field
    VERSION=$(jq '.version' out/Main.ex.map)
    if [ "$VERSION" = "3" ]; then
        echo -e "${GREEN}✓ Version field: ${VERSION}${NC}"
    else
        echo -e "${RED}✗ Wrong source map version: ${VERSION} (expected: 3)${NC}"
        exit 1
    fi
    
    # File field (generated file)
    FILE=$(jq -r '.file' out/Main.ex.map)
    if [ "$FILE" = "Main.ex" ]; then
        echo -e "${GREEN}✓ File field: ${FILE}${NC}"
    else
        echo -e "${YELLOW}⚠ File field: ${FILE} (expected: Main.ex)${NC}"
    fi
    
    # Sources array
    SOURCES=$(jq -r '.sources | length' out/Main.ex.map)
    if [ "$SOURCES" -gt "0" ]; then
        echo -e "${GREEN}✓ Sources array: ${SOURCES} file(s)${NC}"
        echo -n "  Files: "
        jq -r '.sources[]' out/Main.ex.map | tr '\n' ' '
        echo ""
    else
        echo -e "${YELLOW}⚠ Sources array empty (will be populated when position tracking is added)${NC}"
    fi
    
    # SourcesContent array
    if jq -e '.sourcesContent' out/Main.ex.map > /dev/null 2>&1; then
        CONTENT_COUNT=$(jq '.sourcesContent | length' out/Main.ex.map)
        echo -e "${GREEN}✓ SourcesContent array present: ${CONTENT_COUNT} entries${NC}"
    else
        echo -e "${YELLOW}⚠ SourcesContent field missing (optional in spec)${NC}"
    fi
    
    # Names array
    if jq -e '.names' out/Main.ex.map > /dev/null 2>&1; then
        NAMES_COUNT=$(jq '.names | length' out/Main.ex.map)
        echo -e "${GREEN}✓ Names array present: ${NAMES_COUNT} entries${NC}"
    else
        echo -e "${YELLOW}⚠ Names field missing (will be populated with identifiers)${NC}"
    fi
    
    # Mappings field
    echo ""
    echo -e "${BLUE}── Mappings Analysis ──${NC}"
    MAPPINGS=$(jq -r '.mappings' out/Main.ex.map)
    if [ -z "$MAPPINGS" ] || [ "$MAPPINGS" = "null" ]; then
        echo -e "${YELLOW}⚠ Mappings field empty${NC}"
        echo -e "${YELLOW}  This is expected until position tracking is implemented${NC}"
        echo -e "${YELLOW}  Next step: Implement mapPosition() calls in compiler${NC}"
    else
        MAPPING_LENGTH=${#MAPPINGS}
        echo -e "${GREEN}✓ Mappings present (length: ${MAPPING_LENGTH} chars)${NC}"
        echo -e "  Preview: ${MAPPINGS:0:100}..."
        
        # Count semicolons (line separators in VLQ)
        LINES=$(echo "$MAPPINGS" | tr -cd ';' | wc -c)
        echo -e "${GREEN}✓ Mapped lines: ${LINES}${NC}"
    fi
    
    # Check for sourceMap comment in .ex file
    echo ""
    echo -e "${BLUE}── Source Map Reference Check ──${NC}"
    if grep -q "//# sourceMappingURL=Main.ex.map" out/Main.ex; then
        echo -e "${GREEN}✓ Source map reference found in Main.ex${NC}"
    else
        echo -e "${YELLOW}⚠ No source map reference in Main.ex${NC}"
        echo -e "${YELLOW}  Add: //# sourceMappingURL=Main.ex.map at end of file${NC}"
    fi
    
else
    echo -e "${YELLOW}⚠ jq not installed, skipping detailed validation${NC}"
    echo -e "${YELLOW}  Install with: brew install jq (macOS) or apt-get install jq (Linux)${NC}"
fi

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Source Map Generation Test Complete!${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"