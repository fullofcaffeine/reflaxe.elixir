#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

say() { echo "[dead-code-audit] $*"; }

usage() {
  cat >&2 <<'EOF'
Usage: scripts/repo-dead-code-audit.sh [options]

Heuristic "dead code" audit helpers for this repo. This does NOT prove code is unused; it reports candidates.

Options:
  --scope DIR     Limit Haxe type scan to a subtree under src/ (default: src/)
  --limit N       Max candidates to print per section (default: 80)
  --verbose       Print extra context
EOF
  exit 2
}

SCOPE="src"
LIMIT=80
VERBOSE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --scope) SCOPE="$2"; shift 2 ;;
    --limit) LIMIT="$2"; shift 2 ;;
    --verbose) VERBOSE=1; shift 1 ;;
    -h|--help) usage ;;
    *) usage ;;
  esac
done

cd "$ROOT_DIR"

if ! command -v git >/dev/null 2>&1; then
  say "ERROR: git is required"
  exit 1
fi

if command -v rg >/dev/null 2>&1; then
  HAVE_RG=1
else
  HAVE_RG=0
fi

say "Repo: $ROOT_DIR"
say "Scope: $SCOPE"

say ""
say "== Candidate: commented-out trace/log lines =="
if [[ "$HAVE_RG" -eq 1 ]]; then
  rg -n '^\s*//\s*(trace|IO\.inspect|IO\.puts|console\.log)\b' "$SCOPE" | head -n "$LIMIT" || true
else
  grep -R -nE '^\s*//\s*(trace|IO\.inspect|IO\.puts|console\.log)\b' "$SCOPE" | head -n "$LIMIT" || true
fi

say ""
say "== Candidate: DEBUG ONLY markers (should not ship) =="
if [[ "$HAVE_RG" -eq 1 ]]; then
  rg -n 'DEBUG ONLY' "$SCOPE" | head -n "$LIMIT" || true
else
  grep -R -n 'DEBUG ONLY' "$SCOPE" | head -n "$LIMIT" || true
fi

say ""
say "== Candidate: unused Haxe types (heuristic, full-type-path search) =="
say "Rule: a file is a candidate if neither its full type-path nor its basename appears elsewhere under src/ (excluding itself)."

tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/reflaxe-dead-code-audit.XXXXXX")"
trap 'rm -rf "$tmp_dir" 2>/dev/null || true' EXIT

types_file="$tmp_dir/types.tsv"
candidates_file="$tmp_dir/candidates.txt"

git ls-files "$SCOPE" | awk '/\.hx$/ {print}' >"$tmp_dir/hx_files.txt"

# Build a list of "file<TAB>typePath" for likely Haxe types.
while IFS= read -r file; do
  [[ -f "$file" ]] || continue
  base="$(basename "$file" .hx)"

  # Extract `package ...;` from the first ~40 lines (skip blank/comment-only lines).
  pkg="$(awk '
    NR>60 { exit }
    /^[[:space:]]*package[[:space:]]/ {
      gsub(/^[[:space:]]*package[[:space:]]+/, "", $0)
      sub(/;[[:space:]]*$/, "", $0)
      print $0
      exit
    }
  ' "$file" 2>/dev/null || true)"

  type_path="$base"
  if [[ -n "$pkg" && "$pkg" != "package" ]]; then
    # `package;` results in empty pkg after stripping; treat as root.
    pkg_trimmed="$(echo "$pkg" | tr -d '[:space:]')"
    if [[ -n "$pkg_trimmed" ]]; then
      type_path="${pkg_trimmed}.${base}"
    fi
  fi

  printf "%s\t%s\n" "$file" "$type_path" >>"$types_file"
done <"$tmp_dir/hx_files.txt"

printed=0
while IFS=$'\t' read -r file type_path; do
  [[ -n "$file" && -n "$type_path" ]] || continue

  # Search across src/ (not just the scope); exclude the defining file itself.
  if [[ "$HAVE_RG" -eq 1 ]]; then
    if rg -q --fixed-strings "$type_path" src --glob '*.hx' --glob "!$file"; then
      continue
    fi
    if rg -q --fixed-strings "$(basename "$file" .hx)" src --glob '*.hx' --glob "!$file"; then
      continue
    fi
  else
    if grep -R -n -F "$type_path" src --include='*.hx' 2>/dev/null | grep -v -F "$file:" >/dev/null 2>&1; then
      continue
    fi
    if grep -R -n -F "$(basename "$file" .hx)" src --include='*.hx' 2>/dev/null | grep -v -F "$file:" >/dev/null 2>&1; then
      continue
    fi
  fi

  echo "$file ($type_path)" >>"$candidates_file"
  printed=$((printed + 1))
  if [[ "$printed" -ge "$LIMIT" ]]; then
    break
  fi
done <"$types_file"

if [[ -f "$candidates_file" ]]; then
  sed "s/^/  - /" "$candidates_file"
else
  say "No candidates found in scope: $SCOPE"
fi

if [[ "$VERBOSE" -eq 1 ]]; then
  say ""
  say "Notes:"
  say "- This is heuristic: macros, reflection, @:native, and plugin discovery can hide references."
  say "- Before removing anything, confirm with a targeted search + a full test run."
fi

say ""
say "Done."
