#!/usr/bin/env bash
set -euo pipefail

# ----------------------------------------------------------------------------
# Haxelib Package Artifact Smoke
#
# WHAT
# - Validates the actual zip artifact we would submit to haxelib.org by:
#   1) creating a fresh npm+lix workspace,
#   2) installing the generated package zip into an isolated haxelib repo,
#   3) compiling a minimal `-lib reflaxe.elixir` program with no repo-local
#      classpaths,
#   4) checking direct target overrides and official stdlib fallback both work.
#
# WHY
# - Repo-local scoped libs and GitHub-tag Lix installs can pass while the
#   Reflaxe-flattened haxelib package layout is wrong. This smoke exercises the
#   installed package root.
#
# HOW
# - Uses a temp workspace under $TMPDIR.
# - Wraps all external steps with scripts/with-timeout.sh.
# - Does not start any long-running processes.
# ----------------------------------------------------------------------------

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TIMEOUT="$ROOT_DIR/scripts/with-timeout.sh"

HAXE_VERSION="${HAXE_VERSION:-4.3.7}"
KEEP_DIR=0
VERBOSE=0

usage() {
  cat <<EOF
Usage: $0 [options]

Options:
  --haxe VERSION      Haxe version to pin via lix (default: ${HAXE_VERSION})
  --keep-dir          Keep temp workspace (prints path)
  --verbose           Print extra package and compile details
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --haxe) HAXE_VERSION="$2"; shift 2 ;;
    --keep-dir) KEEP_DIR=1; shift 1 ;;
    --verbose) VERBOSE=1; shift 1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "[haxelib-package-smoke] ERROR: unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

if [[ ! -x "$TIMEOUT" ]]; then
  echo "[haxelib-package-smoke] ERROR: missing timeout wrapper: $TIMEOUT" >&2
  exit 2
fi

say() {
  echo "[haxelib-package-smoke] $*"
}

fail() {
  echo "[haxelib-package-smoke] ERROR: $*" >&2
  exit 1
}

run_step() {
  local desc="$1"; shift
  local secs="$1"; shift
  local cwd="$1"; shift
  echo ""
  say "$desc"
  "$TIMEOUT" --secs "$secs" --cwd "$cwd" -- bash -lc "$*"
}

require_file() {
  local path="$1"
  [[ -f "$path" ]] || fail "missing file: $path"
}

require_dir() {
  local path="$1"
  [[ -d "$path" ]] || fail "missing directory: $path"
}

require_contains() {
  local path="$1"
  local needle="$2"
  if ! grep -F "$needle" "$path" >/dev/null 2>&1; then
    fail "expected '$path' to contain: $needle"
  fi
}

require_tree_not_contains() {
  local path="$1"
  local needle="$2"
  if [[ -d "$path" ]]; then
    if grep -R -F "$needle" "$path" >/dev/null 2>&1; then
      fail "unexpected checkout-local path leaked into $path: $needle"
    fi
    return 0
  fi

  if grep -F "$needle" "$path" >/dev/null 2>&1; then
    fail "unexpected checkout-local path leaked into $path: $needle"
  fi
}

tmp_base="$(mktemp -d "${TMPDIR:-/tmp}/reflaxe-elixir-haxelib-package-smoke.XXXXXX")"
work_dir="$tmp_base/work"
package_zip="$tmp_base/reflaxe.elixir.zip"
mkdir -p "$work_dir/src"

cleanup() {
  if [[ "${KEEP_DIR:-0}" -eq 1 ]]; then
    say "Kept workspace: $tmp_base" >&2
    return 0
  fi
  rm -rf "$tmp_base" 2>/dev/null || true
}
trap cleanup EXIT

export HAXE_VERSION
export PACKAGE_ZIP="$package_zip"

say "Workspace: $tmp_base"
say "Haxe: $HAXE_VERSION"

run_step "npm init -y" 60 "$work_dir" "npm init -y"
run_step "npm install lix" 300 "$work_dir" "npm install --save-dev lix --no-audit --no-fund"
run_step "lix scope create" 60 "$work_dir" "npx lix scope create"
run_step "lix download haxe ${HAXE_VERSION}" 600 "$work_dir" 'npx lix download haxe "$HAXE_VERSION"'
run_step "lix use haxe ${HAXE_VERSION}" 60 "$work_dir" 'npx lix use haxe "$HAXE_VERSION"'

export HAXE_BIN="${HAXE_BIN:-$HOME/haxe/versions/$HAXE_VERSION/haxe}"
export HAXELIB_SHIM="$work_dir/node_modules/.bin/haxelib"
[[ -x "$HAXE_BIN" ]] || fail "missing real Haxe binary: $HAXE_BIN"
[[ -x "$HAXELIB_SHIM" ]] || fail "missing haxelib shim: $HAXELIB_SHIM"

run_step "haxe --version (real binary)" 60 "$work_dir" '"$HAXE_BIN" -version'
run_step "build haxelib package zip" 180 "$ROOT_DIR" \
  'HAXE_BIN="$HAXE_BIN" bash scripts/release/package-haxelib.sh "$PACKAGE_ZIP"'
run_step "haxelib newrepo (isolated)" 60 "$work_dir" '"$HAXELIB_SHIM" newrepo'
run_step "haxelib install package zip" 600 "$work_dir" \
  '"$HAXELIB_SHIM" install "$PACKAGE_ZIP" --always'

say "resolve installed package root"
haxelib_repo="$work_dir/.haxelib"
require_dir "$haxelib_repo"
installed_root=""
while IFS= read -r manifest; do
  if grep -E '"name"[[:space:]]*:[[:space:]]*"reflaxe\.elixir"' "$manifest" >/dev/null 2>&1; then
    installed_root="$(dirname "$manifest")"
    break
  fi
done < <(find "$haxelib_repo" -maxdepth 4 -name haxelib.json -type f | sort)
[[ -n "$installed_root" ]] || fail "could not find installed reflaxe.elixir package under $haxelib_repo"

canonical_root="$(cd "$ROOT_DIR" && pwd -P)"
canonical_installed="$(cd "$installed_root" && pwd -P)"
say "Installed root: $canonical_installed"
if [[ "$canonical_installed" == "$canonical_root" ]]; then
  fail "installed package resolved to repo checkout instead of isolated haxelib repo"
fi

require_file "$installed_root/haxelib.json"
require_file "$installed_root/extraParams.hxml"
require_file "$installed_root/src/reflaxe/elixir/CompilerBootstrap.hx"
require_file "$installed_root/src/StringBuf.cross.hx"
require_file "$installed_root/src/haxe/crypto/Sha256.cross.hx"
require_file "$installed_root/src/elixir/DateTime.hx"
require_dir "$installed_root/vendor/reflaxe/src"
require_dir "$installed_root/vendor/phoenix_shared/src"

if [[ -d "$installed_root/std" ]]; then
  fail "installed package must not contain top-level std/; Reflaxe build should flatten stdPaths into src/"
fi

if python3 - "$installed_root/haxelib.json" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)

raise SystemExit(0 if "reflaxe" in data else 1)
PY
then
  fail "installed package haxelib.json still contains source-only reflaxe metadata"
fi

if [[ "$VERBOSE" -eq 1 ]]; then
  say "Installed top-level files:"
  find "$installed_root" -maxdepth 2 -type f | sort | sed -n '1,80p'
fi

haxelib_wrapper_dir="$work_dir/bin"
mkdir -p "$haxelib_wrapper_dir"
cat > "$haxelib_wrapper_dir/haxelib" <<'SH'
#!/usr/bin/env bash
set -euo pipefail

repo="${HAXELIB_PACKAGE_REPO:?}"
cmd="${1:-}"
lib="${2:-}"

find_lib_root() {
  local name="$1"
  local manifest
  while IFS= read -r manifest; do
    if grep -E '"name"[[:space:]]*:[[:space:]]*"'"${name//./\\.}"'"' "$manifest" >/dev/null 2>&1; then
      dirname "$manifest"
      return 0
    fi
  done < <(find "$repo" -maxdepth 4 -name haxelib.json -type f | sort)
  return 1
}

emit_lib_path() {
  local name="$1"
  local root version
  root="$(find_lib_root "$name")"
  if [[ -d "$root/src" ]]; then
    printf '%s/\n' "$root/src"
  else
    printf '%s/\n' "$root"
  fi
  version="$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$root/haxelib.json" | head -n 1)"
  if [[ -n "$version" ]]; then
    printf -- '-D %s=%s\n' "$name" "$version"
  fi
  if [[ -f "$root/extraParams.hxml" ]]; then
    cat "$root/extraParams.hxml"
  fi
}

case "$cmd" in
  config)
    printf '%s\n' "$repo"
    ;;
  libpath)
    find_lib_root "$lib"
    ;;
  path)
    if [[ "$lib" == "reflaxe.elixir" ]]; then
      emit_lib_path "tink_core"
      emit_lib_path "tink_macro"
      emit_lib_path "tink_parse"
      emit_lib_path "$lib"
    else
      emit_lib_path "$lib"
    fi
    ;;
  *)
    echo "unsupported haxelib command in package smoke wrapper: $cmd" >&2
    exit 1
    ;;
esac
SH
chmod +x "$haxelib_wrapper_dir/haxelib"
export HAXELIB_PACKAGE_REPO="$haxelib_repo"
export HAXELIB_WRAPPER_DIR="$haxelib_wrapper_dir"

cat > "$work_dir/src/Main.hx" <<'HX'
#if !phoenix_shared
#error "phoenix_shared define missing"
#end

import haxe.crypto.Sha256;
import haxe.ds.Either;
import phoenix.channels.WirePayload;

class Main {
  static function main() {
    var buf = new StringBuf();
    buf.add("package");
    buf.add("-");
    buf.add("smoke");

    var either:Either<String, Int> = Left(buf.toString());
    var value = switch either {
      case Left(v): v;
      case Right(v): Std.string(v);
    };

    var payload = WirePayload.putString(WirePayload.empty(), "value", value);
    var payloadValue = WirePayload.getString(payload, "value");

    trace(payloadValue);
    trace(Sha256.encode(value));
  }
}
HX

cat > "$work_dir/build.hxml" <<'HXML'
-lib reflaxe.elixir
-cp src
-D elixir_output=out
-D reflaxe_runtime
-D no-utf16
-main Main
-v
HXML

run_step "compile fixture through installed package" 300 "$work_dir" \
  'PATH="$HAXELIB_WRAPPER_DIR:$(dirname "$HAXE_BIN"):$PATH" "$HAXE_BIN" build.hxml > compile.log 2>&1 || { tail -200 compile.log; exit 1; }'

require_file "$work_dir/out/_GeneratedFiles.json"
require_file "$work_dir/out/main.ex"
require_file "$work_dir/out/string_buf.ex"
require_file "$work_dir/out/haxe/crypto/sha256.ex"
require_file "$work_dir/out/phoenix/channels/wire_payload.ex"

require_contains "$work_dir/out/haxe/crypto/sha256.ex" ":crypto.hash(:sha256"
require_contains "$work_dir/compile.log" "src/StringBuf.cross.hx"
require_contains "$work_dir/compile.log" "src/haxe/crypto/Sha256.cross.hx"
require_contains "$work_dir/compile.log" "std/haxe/ds/Either.hx"
require_contains "$work_dir/compile.log" "vendor/phoenix_shared/src/phoenix/channels/WirePayload.hx"
require_tree_not_contains "$work_dir/compile.log" "$canonical_root"
require_tree_not_contains "$work_dir/out" "$canonical_root"

if [[ "$VERBOSE" -eq 1 ]]; then
  say "Generated files:"
  find "$work_dir/out" -type f | sort
  say "Fallback proof:"
  grep -n -F "std/haxe/ds/Either.hx" "$work_dir/compile.log" | sed -n '1,5p'
fi

echo ""
say "OK (haxelib package artifact install + compile)"
