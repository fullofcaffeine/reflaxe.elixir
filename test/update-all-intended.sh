#!/bin/bash
cd "$(dirname "$0")/snapshot" || exit 1

# Update all categories under snapshot/*, excluding archived and negative suites.
for category_dir in ./*/; do
  category="$(basename "${category_dir%/}")"
  case "$category" in
    _archive|negative) continue ;;
  esac

  find "./$category" -type d -name "out" 2>/dev/null | while read -r outdir; do
    parent=$(dirname "$outdir")
    if [ -d "$outdir" ]; then
      rm -rf "$parent/intended" 2>/dev/null
      cp -r "$outdir" "$parent/intended"
      echo "Updated: $parent"
    fi
  done
done
