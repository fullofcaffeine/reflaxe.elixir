#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

fail() {
  echo "[guard:stdlib-layout] ERROR: $*" >&2
  exit 1
}

tracked_std_cross="$(
  git -C "$ROOT_DIR" ls-files 'std/**/*.cross.hx' 'std/*.cross.hx' 2>/dev/null || true
)"
if [[ -n "$tracked_std_cross" ]]; then
  {
    echo "checked-in std sources must not use .cross.hx; author upstream-colliding"
    echo "Elixir std overrides as std/elixir/_std/**/*.hx and let Reflaxe build"
    echo "generate packaged .cross.hx files. Found:"
    printf '%s\n' "$tracked_std_cross" | sed -n '1,80p'
  } >&2
  exit 1
fi

tracked_src_cross="$(
  git -C "$ROOT_DIR" ls-files 'src/**/*.cross.hx' 'src/*.cross.hx' 2>/dev/null || true
)"
if [[ -n "$tracked_src_cross" ]]; then
  unexpected_src_cross="$(
    printf '%s\n' "$tracked_src_cross" | grep -Fxv 'src/haxe/Exception.cross.hx' || true
  )"
  if [[ -n "$unexpected_src_cross" ]]; then
    {
      echo "checked-in src/**/*.cross.hx files must not grow beyond the documented"
      echo "early haxe.Exception override. Put ordinary std replacements under"
      echo "std/elixir/_std/**/*.hx and let Reflaxe build generate packaged"
      echo ".cross.hx files. Found unexpected source-tree cross files:"
      printf '%s\n' "$unexpected_src_cross" | sed -n '1,80p'
    } >&2
    exit 1
  fi
fi

if [[ ! -d "$ROOT_DIR/std/elixir/_std" ]]; then
  fail "missing std/elixir/_std source override root"
fi

duplicate_modules="$(
  python3 - "$ROOT_DIR" <<'PY'
from pathlib import Path
import sys

root = Path(sys.argv[1])
std = root / "std"
target_std = std / "elixir" / "_std"

plain_modules = set()
for path in std.rglob("*.hx"):
    if target_std in path.parents:
        continue
    plain_modules.add(path.relative_to(std).as_posix())

target_modules = {
    path.relative_to(target_std).as_posix()
    for path in target_std.rglob("*.hx")
}

for module in sorted(plain_modules & target_modules):
    print(module)
PY
)"
if [[ -n "$duplicate_modules" ]]; then
  {
    echo "std/elixir/_std modules must not also exist under the plain std root;"
    echo "the plain std root is earlier in raw source checkouts and can shadow"
    echo "target-specific overrides before macros run. Found duplicates:"
    printf '%s\n' "$duplicate_modules" | sed -n '1,80p'
  } >&2
  exit 1
fi

unexpected_plain_haxe_modules="$(
  python3 - "$ROOT_DIR" <<'PY'
from pathlib import Path
import sys

root = Path(sys.argv[1])
plain_haxe_root = root / "std" / "haxe"
allowed = {
    "haxe/ds/OptionTools.hx",
    "haxe/functional/Result.hx",
    "haxe/functional/ResultTools.hx",
    "haxe/test/Assert.hx",
    "haxe/test/ExUnit.hx",
    "haxe/validation/Email.hx",
    "haxe/validation/NonEmptyString.hx",
    "haxe/validation/PositiveInt.hx",
    "haxe/validation/UserId.hx",
}

if plain_haxe_root.exists():
    for path in sorted(plain_haxe_root.rglob("*.hx")):
        module = path.relative_to(root / "std").as_posix()
        if module not in allowed:
            print(module)
PY
)"
if [[ -n "$unexpected_plain_haxe_modules" ]]; then
  {
    echo "plain std/haxe/** files are reserved for documented target-owned support"
    echo "surfaces. Upstream Haxe stdlib replacements must live under"
    echo "std/elixir/_std/** so Reflaxe build can package them as .cross.hx files."
    echo "Found unexpected plain std/haxe modules:"
    printf '%s\n' "$unexpected_plain_haxe_modules" | sed -n '1,80p'
  } >&2
  exit 1
fi

if ! python3 - "$ROOT_DIR/haxelib.json" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)

paths = data.get("reflaxe", {}).get("stdPaths", [])
expected = ["std", "std/elixir/_std"]
if paths != expected:
    raise SystemExit(f"expected reflaxe.stdPaths {expected!r}, found {paths!r}")
PY
then
  fail "haxelib.json reflaxe.stdPaths does not match the source-layout convention"
fi

echo "[guard:stdlib-layout] OK: std overrides use std/elixir/_std source layout and source cross-file convention"
