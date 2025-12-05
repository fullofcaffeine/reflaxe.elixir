#!/bin/bash
# Update all intended outputs from out directories
cd "$(dirname "$0")/snapshot" || exit 1

find . -type d -name "out" | while read -r outdir; do
  parent=$(dirname "$outdir")
  if [ -f "$parent/compile.hxml" ]; then
    rm -rf "$parent/intended" 2>/dev/null
    cp -r "$outdir" "$parent/intended"
    echo "Updated: $parent"
  fi
done
