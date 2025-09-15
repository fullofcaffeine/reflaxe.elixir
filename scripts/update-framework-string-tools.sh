#!/bin/bash

# Script to update all string_tools.ex files in framework tests with idiomatic version

# Get the idiomatic string_tools.ex from core/arrays (our reference)
IDIOMATIC_FILE="test/snapshot/core/arrays/intended/string_tools.ex"

if [ ! -f "$IDIOMATIC_FILE" ]; then
    echo "Error: Idiomatic string_tools.ex not found at $IDIOMATIC_FILE"
    exit 1
fi

echo "Using idiomatic string_tools.ex from: $IDIOMATIC_FILE"
echo ""

# Find all string_tools.ex files in framework tests
echo "Finding all string_tools.ex files in framework tests..."

# Counter for updated files
updated=0

# Update Phoenix tests
for file in $(find test/snapshot/phoenix -name "string_tools.ex" -path "*/intended/*"); do
    echo "Updating: $file"
    cp "$IDIOMATIC_FILE" "$file"
    ((updated++))
done

# Update Ecto tests
for file in $(find test/snapshot/ecto -name "string_tools.ex" -path "*/intended/*"); do
    echo "Updating: $file"
    cp "$IDIOMATIC_FILE" "$file"
    ((updated++))
done

# Update OTP tests
for file in $(find test/snapshot/otp -name "string_tools.ex" -path "*/intended/*"); do
    echo "Updating: $file"
    cp "$IDIOMATIC_FILE" "$file"
    ((updated++))
done

# Update stdlib tests (if any need updating)
for file in $(find test/snapshot/stdlib -name "string_tools.ex" -path "*/intended/*"); do
    echo "Updating: $file"
    cp "$IDIOMATIC_FILE" "$file"
    ((updated++))
done

echo ""
echo "✅ Updated $updated string_tools.ex files with idiomatic patterns"