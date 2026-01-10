#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

JSON=0
say() {
  if [[ "$JSON" -eq 1 ]]; then
    echo "[dead-code-audit] $*" >&2
  else
    echo "[dead-code-audit] $*"
  fi
}

usage() {
  cat >&2 <<'EOF'
Usage: scripts/repo-dead-code-audit.sh [options]

Heuristic "dead code" audit helpers for this repo. This does NOT prove code is unused; it reports candidates.

Options:
  --scope DIR     Limit Haxe type scan to a subtree under src/ (default: src/)
  --limit N       Max candidates to print per section (default: 80)
  --verbose       Print extra context
  --json          Emit a machine-readable JSON report to stdout
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
    --json) JSON=1; shift 1 ;;
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

tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/reflaxe-dead-code-audit.XXXXXX")"
trap 'rm -rf "$tmp_dir" 2>/dev/null || true' EXIT

commented_file="$tmp_dir/commented_traces.txt"
debug_only_file="$tmp_dir/debug_only.txt"
types_file="$tmp_dir/types.tsv"
candidates_file="$tmp_dir/candidates.txt"

say ""
say "== Candidate: commented-out trace/log lines =="
if [[ "$HAVE_RG" -eq 1 ]]; then
  rg -n '^\s*//\s*(trace|IO\.inspect|IO\.puts|console\.log)\b' "$SCOPE" | head -n "$LIMIT" >"$commented_file" || true
else
  grep -R -nE '^\s*//\s*(trace|IO\.inspect|IO\.puts|console\.log)\b' "$SCOPE" | head -n "$LIMIT" >"$commented_file" || true
fi
if [[ "$JSON" -eq 0 ]]; then
  cat "$commented_file" || true
fi

say ""
say "== Candidate: DEBUG ONLY markers (should not ship) =="
if [[ "$HAVE_RG" -eq 1 ]]; then
  rg -n 'DEBUG ONLY' "$SCOPE" | head -n "$LIMIT" >"$debug_only_file" || true
else
  grep -R -n 'DEBUG ONLY' "$SCOPE" | head -n "$LIMIT" >"$debug_only_file" || true
fi
if [[ "$JSON" -eq 0 ]]; then
  cat "$debug_only_file" || true
fi

say ""
say "== Candidate: unused Haxe types (heuristic, full-type-path search) =="
say "Rule: a file is a candidate if neither its full type-path nor its basename appears elsewhere under src/ (excluding itself)."

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

if [[ "$JSON" -eq 1 ]]; then
  git_head="$(git rev-parse HEAD 2>/dev/null || true)"
  python3 - "$ROOT_DIR" "$SCOPE" "$LIMIT" "$git_head" "$commented_file" "$debug_only_file" "$candidates_file" <<'PY'
import json, os, re, sys
from datetime import datetime, timezone

root_dir, scope, limit, git_head, commented_path, debug_only_path, candidates_path = sys.argv[1:8]
limit = int(limit)

def read_lines(path):
  if not os.path.exists(path):
    return []
  with open(path, "r", encoding="utf-8", errors="replace") as f:
    return [line.rstrip("\n") for line in f]

def parse_grep_lines(lines):
  out = []
  for line in lines:
    if not line:
      continue
    parts = line.split(":", 2)
    if len(parts) < 3:
      continue
    file, line_no, text = parts
    try:
      line_no = int(line_no)
    except ValueError:
      continue
    out.append({"file": file, "line": line_no, "text": text})
  return out

def parse_candidates(lines):
  out = []
  for line in lines:
    if not line:
      continue
    m = re.match(r"^(.*)\\s+\\((.*)\\)\\s*$", line)
    if not m:
      continue
    out.append({"file": m.group(1), "type_path": m.group(2)})
  return out

commented = parse_grep_lines(read_lines(commented_path))[:limit]
debug_only = parse_grep_lines(read_lines(debug_only_path))[:limit]
unused_types = parse_candidates(read_lines(candidates_path))[:limit]

report = {
  "meta": {
    "root_dir": root_dir,
    "scope": scope,
    "limit": limit,
    "git_head": git_head or None,
    "generated_at": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
  },
  "commented_out_trace": commented,
  "debug_only_markers": debug_only,
  "unused_haxe_types": unused_types,
  "counts": {
    "commented_out_trace": len(commented),
    "debug_only_markers": len(debug_only),
    "unused_haxe_types": len(unused_types),
  },
}

json.dump(report, sys.stdout, indent=2, sort_keys=True)
sys.stdout.write("\n")
PY
  exit 0
fi

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
