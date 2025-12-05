#!/bin/bash
cd "$(dirname "$0")/snapshot" || exit 1

# Update all categories
for category in core stdlib phoenix regression ecto otp exunit loops infrastructure_audit debug bootstrap_external loop_desugaring; do
  if [ -d "./$category" ]; then
    find "./$category" -type d -name "out" 2>/dev/null | while read -r outdir; do
      parent=$(dirname "$outdir")
      if [ -d "$outdir" ]; then
        rm -rf "$parent/intended" 2>/dev/null
        cp -r "$outdir" "$parent/intended"
        echo "Updated: $parent"
      fi
    done
  fi
done
