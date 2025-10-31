#!/usr/bin/env bash
set -euo pipefail

MAX_LINES=${MAX_LINES:-2000}
TARGET_DIR=${1:-examples/todo-app/lib}

bad=0
while IFS= read -r -d '' file; do
  lines=$(wc -l < "$file" | tr -d ' ')
  if [ "$lines" -gt "$MAX_LINES" ]; then
    echo "ERROR: $file has $lines lines (> $MAX_LINES)." >&2
    bad=1
  fi
done < <(find "$TARGET_DIR" -type f -name "*.ex" -print0)

if [ "$bad" -eq 1 ]; then
  exit 1
fi
echo "OK: No generated .ex file exceeds $MAX_LINES lines in $TARGET_DIR."

