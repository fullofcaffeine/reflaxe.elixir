#!/usr/bin/env bash
set -euo pipefail

# ----------------------------------------------------------------------------
# Haxelib Package Artifact Smoke
#
# WHAT
# - Validates the actual zip artifact we would submit to haxelib.org by:
#   1) creating a fresh npm+lix workspace,
#   2) installing the generated package zip into an isolated haxelib repo,
#   3) checking the installed `Run` CLI entrypoint used by haxelib metadata,
#   4) compiling one fixture from the explicitly wired source checkout,
#   5) compiling the same fixture through installed `-lib reflaxe.elixir`,
#   6) comparing generated Elixir and checking target overrides plus official
#      stdlib fallback both work.
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

require_absent() {
  local path="$1"
  [[ ! -e "$path" ]] || fail "unexpected path exists: $path"
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

compare_generated_elixir() {
  local source_dir="$1"
  local package_dir="$2"
  local source_list package_list
  source_list="$(cd "$source_dir" && find . -type f -name '*.ex' | sort)"
  package_list="$(cd "$package_dir" && find . -type f -name '*.ex' | sort)"

  if [[ "$source_list" != "$package_list" ]]; then
    diff -u <(printf '%s\n' "$source_list") <(printf '%s\n' "$package_list") || true
    fail "source and package modes emitted different Elixir file sets"
  fi

  while IFS= read -r rel; do
    [[ -n "$rel" ]] || continue
    if ! cmp -s "$source_dir/$rel" "$package_dir/$rel"; then
      diff -u "$source_dir/$rel" "$package_dir/$rel" || true
      fail "source and package modes emitted different Elixir: $rel"
    fi
  done <<< "$source_list"
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
require_file "$installed_root/src/Run.hx"
require_file "$installed_root/src/reflaxe/elixir/CompilerBootstrap.hx"
require_file "$installed_root/src/Std.cross.hx"
require_file "$installed_root/src/String.cross.hx"
require_file "$installed_root/src/StringBuf.cross.hx"
require_file "$installed_root/src/haxe/Exception.cross.hx"
require_file "$installed_root/src/haxe/crypto/Sha256.cross.hx"
require_file "$installed_root/src/sys/FileSystem.cross.hx"
require_file "$installed_root/src/sys/io/File.cross.hx"
require_file "$installed_root/src/elixir/DateTime.hx"
require_dir "$installed_root/vendor/reflaxe/src"
require_dir "$installed_root/vendor/phoenix_shared/src"

require_absent "$installed_root/std"
require_absent "$installed_root/src/elixir/_std"
require_absent "$installed_root/src/Std.hx"
require_absent "$installed_root/src/String.hx"
require_absent "$installed_root/src/StringBuf.hx"
require_absent "$installed_root/src/haxe/Exception.hx"
require_absent "$installed_root/src/haxe/crypto/Sha256.hx"
require_absent "$installed_root/src/sys/FileSystem.hx"
require_absent "$installed_root/src/sys/io/File.hx"

if ! python3 - "$installed_root/haxelib.json" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)

if "reflaxe" in data:
    raise SystemExit("installed haxelib.json still contains source-only reflaxe metadata")

if data.get("main") != "Run":
    raise SystemExit(f"installed haxelib.json must keep main=Run, found {data.get('main')!r}")
PY
then
  fail "installed package haxelib.json does not match runnable package metadata"
fi

export INSTALLED_ROOT="$installed_root"
run_step "run installed CLI entrypoint" 120 "$work_dir" \
  '"$HAXE_BIN" -cp "$INSTALLED_ROOT/src" --run Run version > cli.log 2>&1 || { cat cli.log; exit 1; }'
require_contains "$work_dir/cli.log" "Reflaxe.Elixir v"

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
import haxe.io.Bytes;
import haxe.io.Float32Array;
import haxe.io.Mime;
import haxe.io.Scheme;
import haxe.io.UInt8Array;
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
    var mime:String = Mime.ApplicationJson;
    var customMime:Mime = "application/vnd.example+json";
    var scheme:String = Scheme.Https;
    var customScheme:Scheme = "web+demo";
    var floats = new Float32Array(2);
    floats[0] = 1.25;
    var sharedBytes = Bytes.alloc(2);
    var octets = UInt8Array.fromBytes(sharedBytes);
    octets[0] = 55;

    trace(payloadValue);
    trace(Sha256.encode(value));
    trace([mime, (customMime:String), scheme, (customScheme:String)].join("|"));
    trace([Std.string(floats[0]), Std.string(sharedBytes.get(0))].join("|"));
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

cat > "$work_dir/build-source.hxml" <<'HXML'
-lib reflaxe.elixir
-cp src
-D elixir_output=out_source
-D reflaxe_runtime
-D no-utf16
-main Main
-v
HXML

run_step "register source checkout with lix" 120 "$work_dir" \
  "npx lix dev reflaxe.elixir '$ROOT_DIR'"
run_step "render source-checkout scoped HXML" 60 "$ROOT_DIR" \
  "scripts/dev/configure-source-checkout-hxml.sh '$work_dir' '$ROOT_DIR'"
run_step "download source-checkout dependencies" 600 "$work_dir" "npx lix download"
run_step "compile fixture through source checkout" 300 "$work_dir" \
  '"$PWD/node_modules/.bin/haxe" build-source.hxml > compile-source.log 2>&1 || { tail -200 compile-source.log; exit 1; }'

run_step "compile fixture through installed package" 300 "$work_dir" \
  'PATH="$HAXELIB_WRAPPER_DIR:$(dirname "$HAXE_BIN"):$PATH" "$HAXE_BIN" build.hxml > compile.log 2>&1 || { tail -200 compile.log; exit 1; }'

require_file "$work_dir/out/_GeneratedFiles.json"
require_file "$work_dir/out/main.ex"
require_file "$work_dir/out/string_buf.ex"
require_file "$work_dir/out/haxe/crypto/sha256.ex"
require_file "$work_dir/out/phoenix/channels/wire_payload.ex"
require_file "$work_dir/out/haxe/io/array_buffer_view_impl.ex"
require_file "$work_dir/out/haxe/io/_u_int8_array/u_int8_array_impl_.ex"
require_file "$work_dir/out_source/_GeneratedFiles.json"
require_file "$work_dir/out_source/haxe/io/array_buffer_view_impl.ex"
require_file "$work_dir/out_source/haxe/io/_u_int8_array/u_int8_array_impl_.ex"
require_absent "$work_dir/out/haxe/io/mime.ex"
require_absent "$work_dir/out/haxe/io/scheme.ex"
require_absent "$work_dir/out_source/haxe/io/mime.ex"
require_absent "$work_dir/out_source/haxe/io/scheme.ex"

compare_generated_elixir "$work_dir/out_source" "$work_dir/out"
say "Source/package generated Elixir parity: OK"

require_contains "$work_dir/out/haxe/crypto/sha256.ex" ":crypto.hash(:sha256"
require_contains "$work_dir/compile.log" "src/StringBuf.cross.hx"
require_contains "$work_dir/compile.log" "src/haxe/crypto/Sha256.cross.hx"
require_contains "$work_dir/compile.log" "std/haxe/ds/Either.hx"
require_contains "$work_dir/compile.log" "std/haxe/io/Mime.hx"
require_contains "$work_dir/compile.log" "std/haxe/io/Scheme.hx"
require_contains "$work_dir/compile.log" "std/haxe/io/ArrayBufferView.hx"
require_contains "$work_dir/compile.log" "std/haxe/io/Float32Array.hx"
require_contains "$work_dir/compile.log" "std/haxe/io/UInt8Array.hx"
require_contains "$work_dir/compile.log" "vendor/phoenix_shared/src/phoenix/channels/WirePayload.hx"
require_contains "$work_dir/compile-source.log" "std/elixir/_std/StringBuf.hx"
require_contains "$work_dir/compile-source.log" "std/elixir/_std/haxe/crypto/Sha256.hx"
require_contains "$work_dir/compile-source.log" "std/haxe/io/Mime.hx"
require_contains "$work_dir/compile-source.log" "std/haxe/io/Scheme.hx"
require_contains "$work_dir/compile-source.log" "std/haxe/io/ArrayBufferView.hx"
require_contains "$work_dir/compile-source.log" "std/haxe/io/Float32Array.hx"
require_contains "$work_dir/compile-source.log" "std/haxe/io/UInt8Array.hx"
require_tree_not_contains "$work_dir/compile.log" "$canonical_root"
require_tree_not_contains "$work_dir/out" "$canonical_root"

if [[ "$VERBOSE" -eq 1 ]]; then
  say "Generated files:"
  find "$work_dir/out" -type f | sort
  say "Fallback proof:"
  grep -n -F "std/haxe/ds/Either.hx" "$work_dir/compile.log" | sed -n '1,5p'
  grep -n -F "std/haxe/io/Mime.hx" "$work_dir/compile.log" | sed -n '1,5p'
  grep -n -F "std/haxe/io/Scheme.hx" "$work_dir/compile.log" | sed -n '1,5p'
  grep -n -F "std/haxe/io/ArrayBufferView.hx" "$work_dir/compile.log" | sed -n '1,5p'
  grep -n -F "std/haxe/io/Float32Array.hx" "$work_dir/compile.log" | sed -n '1,5p'
  grep -n -F "std/haxe/io/UInt8Array.hx" "$work_dir/compile.log" | sed -n '1,5p'
fi

echo ""
say "OK (source + installed haxelib package parity)"
