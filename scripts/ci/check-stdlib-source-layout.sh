#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

fail() {
  echo "[guard:stdlib-layout] ERROR: $*" >&2
  exit 1
}

existing_source_cross_files() {
  local root="$1"
  while IFS= read -r rel; do
    if [[ -f "$ROOT_DIR/$rel" ]]; then
      printf '%s\n' "$rel"
    fi
  done < <(git -C "$ROOT_DIR" ls-files --cached --others --exclude-standard "$root/**/*.cross.hx" "$root/*.cross.hx" 2>/dev/null || true)
}

source_std_cross="$(existing_source_cross_files std)"
if [[ -n "$source_std_cross" ]]; then
  {
    echo "checked-in std sources must not use .cross.hx; author upstream-colliding"
    echo "Elixir std overrides as std/elixir/_std/**/*.hx and let Reflaxe build"
    echo "generate packaged .cross.hx files. Found:"
    printf '%s\n' "$source_std_cross" | sed -n '1,80p'
  } >&2
  exit 1
fi

source_src_cross="$(existing_source_cross_files src)"
if [[ -n "$source_src_cross" ]]; then
  {
    echo "checked-in src/**/*.cross.hx files are generated-package artifacts, not"
    echo "source-layout inputs. Put upstream std replacements under"
    echo "std/elixir/_std/**/*.hx and let Reflaxe build generate packaged"
    echo ".cross.hx files. Found source-tree cross files:"
    printf '%s\n' "$source_src_cross" | sed -n '1,80p'
  } >&2
  exit 1
fi

if [[ ! -d "$ROOT_DIR/std/elixir/_std" ]]; then
  fail "missing std/elixir/_std source override root"
fi

if [[ ! -f "$ROOT_DIR/std/elixir/_std/haxe/Exception.hx" ]]; then
  fail "haxe.Exception must be authored at std/elixir/_std/haxe/Exception.hx"
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

unexpected_plain_sys_modules="$(
  python3 - "$ROOT_DIR" <<'PY'
from pathlib import Path
import sys

root = Path(sys.argv[1])
plain_sys_root = root / "std" / "sys"

if plain_sys_root.exists():
    for path in sorted(plain_sys_root.rglob("*.hx")):
        print(path.relative_to(root / "std").as_posix())
PY
)"
if [[ -n "$unexpected_plain_sys_modules" ]]; then
  {
    echo "plain std/sys/** files shadow Haxe host/eval sys modules in packaged"
    echo "Reflaxe builds. BEAM sys.* replacements must live under"
    echo "std/elixir/_std/sys/** so Reflaxe build packages them as .cross.hx files."
    echo "Found unexpected plain std/sys modules:"
    printf '%s\n' "$unexpected_plain_sys_modules" | sed -n '1,80p'
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

scoped_hxml_files="$(
  git -C "$ROOT_DIR" ls-files 'haxe_libraries/reflaxe.elixir.hxml' '*/haxe_libraries/reflaxe.elixir.hxml'
)"
if [[ -z "$scoped_hxml_files" ]]; then
  fail "missing scoped source-checkout HXML: haxe_libraries/reflaxe.elixir.hxml"
fi

while IFS= read -r rel; do
  [[ -n "$rel" ]] || continue
  dev_hxml="$ROOT_DIR/$rel"
  std_line="$(grep -nE '^-cp .*/std/?$' "$dev_hxml" | head -1 | cut -d: -f1 || true)"
  target_std_line="$(grep -nE '^-cp .*/std/elixir/_std/?$' "$dev_hxml" | head -1 | cut -d: -f1 || true)"
  if [[ -z "$std_line" || -z "$target_std_line" ]]; then
    fail "$rel must include std/ and std/elixir/_std/ source classpaths"
  fi
  if (( target_std_line <= std_line )); then
    fail "$rel must list std/elixir/_std after std so it has effective precedence"
  fi
done <<<"$scoped_hxml_files"

if grep -Eq '^[[:space:]]*-cp[[:space:]]+' "$ROOT_DIR/extraParams.hxml"; then
  fail "extraParams.hxml must remain cwd-agnostic; source classpaths belong in the scoped library HXML"
fi

source_hxml_helper="$ROOT_DIR/scripts/dev/configure-source-checkout-hxml.sh"
if [[ ! -x "$source_hxml_helper" ]]; then
  fail "missing executable source-checkout HXML configurator"
fi

helper_tmp="$(mktemp -d "${TMPDIR:-/tmp}/reflaxe-elixir-source-hxml.XXXXXX")"
cleanup_helper_tmp() {
  rm -rf "$helper_tmp"
}
trap cleanup_helper_tmp EXIT
mkdir -p "$helper_tmp/haxe_libraries"
printf '%s\n' '-lib tink_macro' '-lib tink_parse' > "$helper_tmp/haxe_libraries/reflaxe.elixir.hxml"
"$source_hxml_helper" "$helper_tmp" "$ROOT_DIR" >/dev/null

rendered_target="$helper_tmp/haxe_libraries/reflaxe.elixir.hxml"
rendered_reflaxe="$helper_tmp/haxe_libraries/reflaxe.hxml"
grep -Fx -- "-cp $ROOT_DIR/std/" "$rendered_target" >/dev/null \
  || fail "source-HXML helper did not render the target std root"
grep -Fx -- "-cp $ROOT_DIR/std/elixir/_std/" "$rendered_target" >/dev/null \
  || fail "source-HXML helper did not render the target _std root"
grep -Fx -- '-lib tink_macro' "$rendered_target" >/dev/null \
  || fail "source-HXML helper did not preserve Lix dependency lines"
grep -Fx -- "-cp $ROOT_DIR/vendor/reflaxe/src/" "$rendered_reflaxe" >/dev/null \
  || fail "source-HXML helper did not render vendored Reflaxe"
for dependency in tink_core tink_macro tink_parse; do
  [[ -f "$helper_tmp/haxe_libraries/$dependency.hxml" ]] \
    || fail "source-HXML helper did not render pinned $dependency configuration"
done
if grep -F '${SCOPE_DIR}' "$rendered_target" "$rendered_reflaxe" >/dev/null; then
  fail "source-HXML helper left unresolved SCOPE_DIR placeholders"
fi
cleanup_helper_tmp
trap - EXIT

for source_consumer in scripts/dogfood-phoenix.sh scripts/ci/docs-smoke.sh; do
  grep -F 'configure-source-checkout-hxml.sh' "$ROOT_DIR/$source_consumer" >/dev/null \
    || fail "$source_consumer must render the canonical scoped HXML after lix dev"
done

if git -C "$ROOT_DIR" grep -nE 'lix install .*github:fullofcaffeine/reflaxe\.elixir' -- README.md docs examples src lib scripts \
  | grep -vE 'scripts/ci/check-stdlib-source-layout\.sh' >/dev/null; then
  fail "consumer Lix installs must use the Reflaxe-built release zip, not raw GitHub source"
fi

if ! python3 - "$ROOT_DIR/package.json" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)

plugins = data.get("release", {}).get("plugins", [])
prepare = ""
assets = []
for plugin in plugins:
    if isinstance(plugin, list) and plugin:
        name = plugin[0]
        config = plugin[1] if len(plugin) > 1 and isinstance(plugin[1], dict) else {}
        if name == "@semantic-release/exec":
            prepare = config.get("prepareCmd", "")
        if name == "@semantic-release/github":
            assets = config.get("assets", [])

expected = "dist/reflaxe.elixir-${nextRelease.version}.zip"
if "scripts/release/package-haxelib.sh" not in prepare or expected not in prepare:
    raise SystemExit("semantic-release prepareCmd does not build the versioned Reflaxe package")
if not any(isinstance(asset, dict) and asset.get("path") == expected for asset in assets):
    raise SystemExit("semantic-release does not upload the versioned Reflaxe package")
PY
then
  fail "release configuration does not publish the Reflaxe-built package artifact"
fi

grep -F 'HAXE_BIN=' "$ROOT_DIR/.github/workflows/release.yml" >/dev/null \
  || fail "release workflow must provide HAXE_BIN for Reflaxe package construction"

echo "[guard:stdlib-layout] OK: std overrides use Reflaxe _std source layout"
