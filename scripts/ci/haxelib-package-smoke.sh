#!/usr/bin/env bash
set -euo pipefail

# ----------------------------------------------------------------------------
# GitHub Release Package Artifact Smoke
#
# WHAT
# - Validates the Haxelib-compatible ZIP distributed through GitHub Releases by:
#   1) creating a fresh npm+lix workspace,
#   2) installing the generated package zip into an isolated haxelib repo,
#   3) checking the installed `Run` CLI entrypoint used by haxelib metadata,
#   4) compiling one fixture from the explicitly wired source checkout,
#   5) compiling the same fixture through installed `-lib reflaxe.elixir`,
#   6) comparing canonical Mix-formatted generated Elixir from both layouts,
#   7) comparing path-independent structural quality reports,
#   8) checking target overrides plus official stdlib fallback both work,
#   9) loading the public LiveReact tasks from the installed archive only,
#  10) exercising setup/check/component/remove in a clean Phoenix-shaped fixture.
#
# WHY
# - Repo-local scoped libs can pass while the Reflaxe-flattened release package
#   layout is wrong. This smoke exercises the
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

require_not_contains() {
  local path="$1"
  local needle="$2"
  if grep -F "$needle" "$path" >/dev/null 2>&1; then
    fail "expected '$path' not to contain: $needle"
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
if [[ "${PACKAGE_SMOKE_USE_EXISTING:-0}" == "1" ]]; then
  package_zip_rel="${PACKAGE_ZIP_REL:-dist/reflaxe.elixir.zip}"
  if [[ "$package_zip_rel" == /* ]]; then
    package_zip="$package_zip_rel"
  else
    package_zip="$ROOT_DIR/$package_zip_rel"
  fi
  require_file "$package_zip"
else
  package_zip="$tmp_base/reflaxe.elixir.zip"
fi
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
if [[ "${PACKAGE_SMOKE_USE_EXISTING:-0}" == "1" ]]; then
  say "Using existing package artifact: $package_zip"
else
  run_step "build haxelib package zip" 180 "$ROOT_DIR" \
    'HAXE_BIN="$HAXE_BIN" bash scripts/release/package-haxelib.sh "$PACKAGE_ZIP"'
fi
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

if find "$installed_root" -path '*managed_reference_spike*' -print -quit | grep -q .; then
  fail "experimental managed-reference spike leaked into the installed release package"
fi

canonical_root="$(cd "$ROOT_DIR" && pwd -P)"
canonical_installed="$(cd "$installed_root" && pwd -P)"
say "Installed root: $canonical_installed"
if [[ "$canonical_installed" == "$canonical_root" ]]; then
  fail "installed package resolved to repo checkout instead of isolated haxelib repo"
fi

require_file "$installed_root/haxelib.json"
require_file "$installed_root/release-metadata.json"
require_file "$installed_root/extraParams.hxml"
require_file "$installed_root/mix.exs"
require_file "$installed_root/lib/haxe_phoenix_live_react.ex"
require_file "$installed_root/lib/haxe_phoenix_live_react/core.ex"
require_file "$installed_root/lib/haxe_phoenix_live_react/core.generated.json"
require_file "$installed_root/lib/mix/tasks/haxe.gen.live_react.ex"
require_file "$installed_root/lib/mix/tasks/haxe.phoenix.live_react.ex"
require_file "$installed_root/lib/mix/tasks/templates/agents.md.tpl"
require_file "$installed_root/priv/templates/phoenix_scaffold/build-client.hxml"
require_file "$installed_root/priv/templates/phoenix_scaffold/haxe_libraries/genes-ts.hxml"
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
require_file "$installed_root/src/elixir/Keyword.hx"
require_file "$installed_root/src/elixir/OptionParser.hx"
require_file "$installed_root/src/elixir/Tuple.hx"
require_file "$installed_root/src/elixir/types/KeywordEntry.hx"
require_file "$installed_root/src/elixir/types/Tuple2.hx"
require_file "$installed_root/src/elixir/types/Tuple3.hx"
require_file "$installed_root/src/elixir/types/Tuple4.hx"
require_file "$installed_root/src/elixir/types/Tuple5.hx"
require_file "$installed_root/src/reflaxe/elixir/generator/templates/agents.md.tpl"
require_dir "$installed_root/vendor/reflaxe/src"
require_dir "$installed_root/vendor/phoenix_shared/src"
require_file "$installed_root/vendor/phoenix_shared/src/phoenix/live_react/LiveReactEventProtocol.hx"
require_file "$installed_root/vendor/phoenix_shared/src/phoenix/live_react/macros/LiveReactEventProtocolTypeScript.hx"

require_absent "$installed_root/std"
require_absent "$installed_root/src/elixir/_std"
require_absent "$installed_root/src/Std.hx"
require_absent "$installed_root/src/String.hx"
require_absent "$installed_root/src/StringBuf.hx"
require_absent "$installed_root/src/haxe/Exception.hx"
require_absent "$installed_root/src/haxe/crypto/Sha256.hx"
require_absent "$installed_root/src/sys/FileSystem.hx"
require_absent "$installed_root/src/sys/io/File.hx"
require_absent "$installed_root/assets"
require_absent "$installed_root/deps"
require_absent "$installed_root/node_modules"
require_absent "$installed_root/lib/live_react.ex"
require_absent "$installed_root/lib/live_react"
require_absent "$installed_root/lib/third_party"
require_absent "$installed_root/priv/static"
require_absent "$installed_root/priv/live_react"
require_absent "$installed_root/vendor/live_react"
require_absent "$installed_root/vendor/genes"
require_absent "$installed_root/vendor/phoenix_js"

metadata_field() {
  python3 - "$installed_root/release-metadata.json" "$1" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    print(json.load(handle)[sys.argv[2]])
PY
}

export EXPECTED_PACKAGE_VERSION PACKAGE_TAG PACKAGE_SOURCE_SHA PACKAGE_VERIFICATION_LOG
EXPECTED_PACKAGE_VERSION="$(metadata_field version)"
PACKAGE_TAG="$(metadata_field tag)"
PACKAGE_SOURCE_SHA="$(metadata_field sourceCommit)"
PACKAGE_VERIFICATION_LOG="$work_dir/package-verification.json"
run_step "verify actual release-package archive" 60 "$ROOT_DIR" \
  'node scripts/release/verify-release-artifact.js --zip "$PACKAGE_ZIP" --version "$EXPECTED_PACKAGE_VERSION" --tag "$PACKAGE_TAG" --source-sha "$PACKAGE_SOURCE_SHA" > "$PACKAGE_VERIFICATION_LOG"'

if ! python3 - "$installed_root/haxelib.json" "$installed_root/release-metadata.json" "$installed_root/mix.exs" <<'PY'
import json
import re
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)
with open(sys.argv[2], encoding="utf-8") as handle:
    metadata = json.load(handle)
with open(sys.argv[3], encoding="utf-8") as handle:
    mix_exs = handle.read()

if "reflaxe" in data:
    raise SystemExit("installed haxelib.json still contains source-only reflaxe metadata")

if data.get("main") != "Run":
    raise SystemExit(f"installed haxelib.json must keep main=Run, found {data.get('main')!r}")

if metadata.get("schemaVersion") != 1 or metadata.get("version") != data.get("version"):
    raise SystemExit("release-metadata.json does not match staged haxelib metadata")
if not re.fullmatch(r"[0-9a-f]{40}", metadata.get("sourceCommit", "")):
    raise SystemExit("release-metadata.json does not contain a full source commit")
mix_version = f'version: "{data.get("version")}"'
if mix_exs.count(mix_version) != 1:
    raise SystemExit("packaged mix.exs does not use the staged haxelib version")
if 'version: "0.0.0-development"' in mix_exs:
    raise SystemExit("packaged mix.exs still contains the development version")
PY
then
  fail "installed Haxelib and Mix package metadata do not agree"
fi

cat > "$work_dir/check-installed-mix-version.exs" <<'EX'
Mix.start()
package_root = System.fetch_env!("REFLAXE_ELIXIR_PACKAGE_ROOT")
Code.require_file(Path.join(package_root, "mix.exs"))
expected = System.fetch_env!("EXPECTED_PACKAGE_VERSION")
actual = ReflaxeElixir.MixProject.project()[:version]

if actual != expected do
  raise "loaded Mix project version #{inspect(actual)} does not match #{inspect(expected)}"
end

IO.puts("Loaded installed Mix project version: #{actual}")
EX

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

# Prove the installed release archive is also the complete Mix dependency used
# by a PhoenixHx consumer. The fixture owns only ordinary Phoenix-shaped source
# and tiny dependency stubs; it does not point back to this repository.
live_react_consumer="$tmp_base/live_react_consumer"
mkdir -p \
  "$live_react_consumer/assets/js" \
  "$live_react_consumer/config" \
  "$live_react_consumer/lib/package_live_react_consumer_web/components/layouts" \
  "$live_react_consumer/vendor/live_react" \
  "$live_react_consumer/vendor/phoenix" \
  "$live_react_consumer/vendor/phoenix_html" \
  "$live_react_consumer/vendor/phoenix_live_view"

cat > "$live_react_consumer/mix.exs" <<'EX'
defmodule PackageLiveReactConsumer.MixProject do
  use Mix.Project

  def project do
    [
      app: :package_live_react_consumer,
      version: "0.1.0",
      deps: deps(),
      aliases: aliases()
    ]
  end

  def application, do: [extra_applications: [:logger]]

  defp deps do
    [
      {:jason, "~> 1.4"},
      {:reflaxe_elixir, path: System.fetch_env!("REFLAXE_ELIXIR_PACKAGE_ROOT")},
      {:live_react, path: "vendor/live_react"},
      {:phoenix, path: "vendor/phoenix", override: true},
      {:phoenix_html, path: "vendor/phoenix_html", override: true},
      {:phoenix_live_view, path: "vendor/phoenix_live_view", override: true}
    ]
  end

  defp aliases do
    [
      "assets.setup": ["esbuild.install --if-missing"],
      "assets.build": ["esbuild package_live_react_consumer"],
      "assets.deploy": ["esbuild package_live_react_consumer --minify", "phx.digest"]
    ]
  end
end
EX

cat > "$live_react_consumer/config/config.exs" <<'EX'
import Config

config :package_live_react_consumer, ecto_repos: []
EX

cat > "$live_react_consumer/config/dev.exs" <<'EX'
import Config

config :package_live_react_consumer, PackageLiveReactConsumerWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:package_live_react_consumer, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:package_live_react_consumer, ~w(--watch)]}
  ]
EX

cat > "$live_react_consumer/assets/js/app.js" <<'JS'
import "phoenix_html"
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import {hooks as colocatedHooks} from "phoenix-colocated/package_live_react_consumer"

const liveSocket = new LiveSocket("/live", Socket, {
  params: {_csrf_token: "package-smoke"},
  hooks: {...colocatedHooks},
})

liveSocket.connect()
JS

cat > "$live_react_consumer/assets/package.json" <<'JSON'
{
  "name": "package-live-react-consumer-assets",
  "private": true
}
JSON

cat > "$live_react_consumer/lib/package_live_react_consumer_web/components/layouts/root.html.heex" <<'HEEX'
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <script defer phx-track-static type="text/javascript" src={~p"/assets/app.js"}></script>
  </head>
  <body>{@inner_content}</body>
</html>
HEEX

cat > "$live_react_consumer/vendor/live_react/package.json" <<'JSON'
{"name":"live_react","version":"0.1.0"}
JSON

cat > "$live_react_consumer/vendor/live_react/mix.exs" <<'EX'
defmodule LiveReact.MixProject do
  use Mix.Project
  def project, do: [app: :live_react, version: "0.1.0"]
end
EX

cat > "$live_react_consumer/vendor/phoenix/mix.exs" <<'EX'
defmodule FixturePhoenix.MixProject do
  use Mix.Project
  def project, do: [app: :phoenix, version: "1.8.9"]
end
EX
cat > "$live_react_consumer/vendor/phoenix/package.json" <<'JSON'
{"name":"phoenix","version":"1.8.9"}
JSON

cat > "$live_react_consumer/vendor/phoenix_html/mix.exs" <<'EX'
defmodule FixturePhoenixHtml.MixProject do
  use Mix.Project
  def project, do: [app: :phoenix_html, version: "4.3.0"]
end
EX
cat > "$live_react_consumer/vendor/phoenix_html/package.json" <<'JSON'
{"name":"phoenix_html","version":"4.3.0"}
JSON

cat > "$live_react_consumer/vendor/phoenix_live_view/mix.exs" <<'EX'
defmodule FixturePhoenixLiveView.MixProject do
  use Mix.Project
  def project, do: [app: :phoenix_live_view, version: "1.2.9"]
end
EX
cat > "$live_react_consumer/vendor/phoenix_live_view/package.json" <<'JSON'
{"name":"phoenix_live_view","version":"1.2.9"}
JSON

mkdir -p "$live_react_consumer/original"
for rel in \
  mix.exs \
  config/config.exs \
  config/dev.exs \
  assets/js/app.js \
  assets/package.json \
  lib/package_live_react_consumer_web/components/layouts/root.html.heex; do
  mkdir -p "$live_react_consumer/original/$(dirname "$rel")"
  cp "$live_react_consumer/$rel" "$live_react_consumer/original/$rel"
done

export REFLAXE_ELIXIR_PACKAGE_ROOT="$canonical_installed"
run_step "load installed Mix project identity" 60 "$work_dir" \
  'elixir check-installed-mix-version.exs > mix-project-version.log 2>&1 || { cat mix-project-version.log; exit 1; }'
require_contains "$work_dir/mix-project-version.log" "Loaded installed Mix project version: $EXPECTED_PACKAGE_VERSION"
run_step "fetch clean installed-package consumer dependencies" 300 "$live_react_consumer" \
  'MIX_ENV=prod mix deps.get > deps-get.log 2>&1 || { tail -200 deps-get.log; exit 1; }'
run_step "compile installed Mix package and fixture dependencies" 300 "$live_react_consumer" \
  'MIX_ENV=prod mix deps.compile > deps-compile.log 2>&1 || { tail -200 deps-compile.log; exit 1; }'
run_step "prove installed LiveReact task help is available" 60 "$live_react_consumer" \
  'MIX_ENV=prod mix help haxe.phoenix.live_react > lifecycle-help.log && MIX_ENV=prod mix help haxe.gen.live_react > component-help.log'
require_contains "$live_react_consumer/lifecycle-help.log" "mix haxe.phoenix.live_react --check"
require_contains "$live_react_consumer/component-help.log" "mix haxe.gen.live_react PreferenceStudio"

if "$TIMEOUT" --secs 60 --cwd "$live_react_consumer" -- env MIX_ENV=prod mix haxe.phoenix.live_react --check >"$live_react_consumer/pre-setup-check.log" 2>&1; then
  fail "LiveReact check unexpectedly passed before the integration was enabled"
fi
require_absent "$live_react_consumer/phoenixhx-live-react.json"
require_absent "$live_react_consumer/assets/vite.config.mjs"
require_absent "$live_react_consumer/assets/js/live-react-hooks.js"
require_not_contains "$live_react_consumer/assets/package.json" '"react"'

run_step "apply LiveReact from installed package" 120 "$live_react_consumer" \
  'MIX_ENV=prod mix haxe.phoenix.live_react --package-root assets --yes > lifecycle-apply.log 2>&1 || { tail -200 lifecycle-apply.log; exit 1; }'
require_contains "$live_react_consumer/lifecycle-apply.log" "path:vendor/live_react@0.1.0"
require_file "$live_react_consumer/phoenixhx-live-react.json"
require_contains "$live_react_consumer/phoenixhx-live-react.json" '"clientMode": "plain-js"'
require_contains "$live_react_consumer/phoenixhx-live-react.json" '"packageRoot": "assets"'
require_file "$live_react_consumer/assets/vite.config.mjs"
require_file "$live_react_consumer/assets/js/live-react-hooks.js"
require_file "$live_react_consumer/assets/react-components/registry.generated.ts"
require_contains "$live_react_consumer/assets/package.json" '"live_react": "file:../vendor/live_react"'
require_contains "$live_react_consumer/assets/package.json" '"react": "19.1.0"'
require_contains "$live_react_consumer/assets/package.json" '"vite": "7.2.7"'

run_step "check installed-package LiveReact wiring" 60 "$live_react_consumer" \
  'MIX_ENV=prod mix haxe.phoenix.live_react --check > lifecycle-check.log 2>&1 || { cat lifecycle-check.log; exit 1; }'
require_contains "$live_react_consumer/lifecycle-check.log" "check passed; no writes occurred"

run_step "generate a component from installed package" 60 "$live_react_consumer" \
  'MIX_ENV=prod mix haxe.gen.live_react PackagePanel --package-root assets --yes > component-add.log 2>&1 || { cat component-add.log; exit 1; }'
require_file "$live_react_consumer/src_haxe/package_live_react_consumer_hx/components/live_react/PackagePanelIsland.hx"
require_file "$live_react_consumer/assets/react-components/package-panel-boundary.tsx"
require_file "$live_react_consumer/assets/react-components/package-panel.tsx"
require_contains "$live_react_consumer/assets/react-components/registry.generated.ts" "PackagePanel"

run_step "remove the installed-package component registration" 60 "$live_react_consumer" \
  'MIX_ENV=prod mix haxe.gen.live_react PackagePanel --remove --package-root assets --yes > component-remove.log 2>&1 || { cat component-remove.log; exit 1; }'
require_file "$live_react_consumer/src_haxe/package_live_react_consumer_hx/components/live_react/PackagePanelIsland.hx"
require_file "$live_react_consumer/assets/react-components/package-panel-boundary.tsx"
require_file "$live_react_consumer/assets/react-components/package-panel.tsx"
require_not_contains "$live_react_consumer/assets/react-components/registry.generated.ts" "PackagePanel"

run_step "remove LiveReact wiring from installed package" 120 "$live_react_consumer" \
  'MIX_ENV=prod mix haxe.phoenix.live_react --remove --yes > lifecycle-remove.log 2>&1 || { tail -200 lifecycle-remove.log; exit 1; }'
require_absent "$live_react_consumer/phoenixhx-live-react.json"
require_absent "$live_react_consumer/assets/vite.config.mjs"
require_absent "$live_react_consumer/assets/js/live-react-hooks.js"
require_absent "$live_react_consumer/assets/react-components/registry.generated.ts"
for rel in \
  mix.exs \
  config/config.exs \
  config/dev.exs \
  assets/js/app.js \
  assets/package.json \
  lib/package_live_react_consumer_web/components/layouts/root.html.heex; do
  if ! cmp -s "$live_react_consumer/original/$rel" "$live_react_consumer/$rel"; then
    diff -u "$live_react_consumer/original/$rel" "$live_react_consumer/$rel" || true
    fail "installed-package removal did not restore $rel"
  fi
done
require_tree_not_contains "$live_react_consumer" "$canonical_root"
say "Installed-package LiveReact lifecycle and non-enabled isolation: OK"

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
import elixir.Keyword;
import elixir.OptionParser;
import elixir.OptionParser.OptionSwitch;
import elixir.OptionParser.OptionSwitchTypes;
import elixir.Tuple;
import elixir.types.KeywordList;
import elixir.types.Term;
import elixir.types.Tuple2;
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
    var tupleValue = packageTuple();
    if (tupleValue._1 != "tuple" || tupleValue._2 != 4)
      throw "installed package tuple lowering failed";
    var nativePair:Tuple2<String, Int> = Tuple.of2("native", 2);
    if (nativePair._0 != "native" || nativePair._1 != 2)
      throw "installed package Tuple.of2 lowering failed";
    var parsed = OptionParser.parse([], parserOptions());
    parsed._0 = [];
    var appOptions = complexOptions(value);
    var projected = project([1, 2, 3]);
    if (projected.join(",") != "2,4,6")
      throw "installed package projection lowering failed";

    trace(payloadValue);
    trace(Sha256.encode(value));
    trace(value.split("i").join("|"));
    trace([mime, (customMime:String), scheme, (customScheme:String)].join("|"));
    trace([Std.string(floats[0]), Std.string(sharedBytes.get(0))].join("|"));
    trace([Std.string(parsed.argv.length), Std.string(appOptions.length)].join("|"));
    trace(projected.join("|"));
  }

  static function packageTuple():{_1:String, _2:Int} {
    return {_1: "tuple", _2: 4};
  }

  static function parserOptions():KeywordList<Term> {
    var switches:Array<OptionSwitch> = [
      Keyword.entry("verbose", OptionSwitchTypes.BOOLEAN),
      Keyword.entry("source", OptionSwitchTypes.STRING)
    ];

    return [Keyword.entry("strict", switches)];
  }

  static function complexOptions(value:Null<String>):KeywordList<Term> {
    return [Keyword.entry("app_name", value == null ? null : value.toUpperCase())];
  }

  static function project(values:Array<Int>):Array<Int> {
    var projected = [];
    for (value in values)
      projected.push(value * 2);
    return projected;
  }
}
HX

cat > "$work_dir/build.hxml" <<'HXML'
-lib reflaxe.elixir
-cp src
-D elixir_output=out
-D reflaxe_elixir_format=write
-D no-utf16
-main Main
-v
HXML

cat > "$work_dir/build-source.hxml" <<'HXML'
-lib reflaxe.elixir
-cp src
-D elixir_output=out_source
-D reflaxe_elixir_format=write
-D no-utf16
-main Main
-v
HXML

cat > "$work_dir/mix.exs" <<'EX'
defmodule ReflaxeElixirFormatterParity.MixProject do
  use Mix.Project

  def project do
    [app: :reflaxe_elixir_formatter_parity, version: "0.0.0", elixir: "~> 1.14", deps: []]
  end
end
EX

cat > "$work_dir/.formatter.exs" <<'EX'
[inputs: ["{out,out_source}/**/*.{ex,exs}"]]
EX

run_step "register source checkout with lix" 120 "$work_dir" \
  "npx lix dev reflaxe.elixir '$ROOT_DIR'"
run_step "render source-checkout scoped HXML" 60 "$ROOT_DIR" \
  "scripts/dev/configure-source-checkout-hxml.sh '$work_dir' '$ROOT_DIR'"
run_step "download source-checkout dependencies" 600 "$work_dir" "npx lix download"
run_step "compile fixture through source checkout" 300 "$work_dir" \
  '"$PWD/node_modules/.bin/haxe" build-source.hxml > compile-source.log 2>&1 || { tail -200 compile-source.log; exit 1; }'

run_step "compile fixture through installed package" 300 "$work_dir" \
  'PATH="$HAXELIB_WRAPPER_DIR:$(dirname "$HAXE_BIN"):$PATH" "$HAXE_BIN" build.hxml > compile.log 2>&1 || { tail -200 compile.log; exit 1; }'

mkdir -p "$work_dir/live_react_probe"
cat > "$work_dir/live_react_probe/ProbeMain.hx" <<'HX'
class ProbeMain {
  static function main() {}
}
HX

cat > "$work_dir/live_react_probe/ReactProbe.hx" <<'HX'
import phoenix.live_react.LiveReact;
import phoenix.types.Assigns;

private typedef ReactProbeAssigns = {
  var id:String;
  var title:String;
}

@:native("PackageProbeWeb.ReactProbe")
@:component
class ReactProbe {
  @:component
  public static function render(assigns:Assigns<ReactProbeAssigns>):String {
    return <LiveReact.react
      id=${assigns.id}
      name="PackagePanel"
      title=${assigns.title}
      ssr=${false}
    />;
  }
}
HX

cat > "$work_dir/live-react-probe-source.hxml" <<'HXML'
-lib reflaxe.elixir
-cp live_react_probe
-D elixir_output=live_react_probe_out_source
-D reflaxe_elixir_format=write
-D app_name=PackageProbe
-main ProbeMain
--macro include("ReactProbe")
HXML

cat > "$work_dir/live-react-probe-package.hxml" <<'HXML'
-lib reflaxe.elixir
-cp live_react_probe
-D elixir_output=live_react_probe_out_package
-D reflaxe_elixir_format=write
-D app_name=PackageProbe
-main ProbeMain
--macro include("ReactProbe")
HXML

run_step "compile LiveReact HXX through source checkout" 180 "$work_dir" \
  '"$PWD/node_modules/.bin/haxe" live-react-probe-source.hxml > live-react-probe-source.log 2>&1 || { tail -200 live-react-probe-source.log; exit 1; }'
run_step "compile LiveReact HXX through installed package" 180 "$work_dir" \
  'PATH="$HAXELIB_WRAPPER_DIR:$(dirname "$HAXE_BIN"):$PATH" "$HAXE_BIN" live-react-probe-package.hxml > live-react-probe-package.log 2>&1 || { tail -200 live-react-probe-package.log; exit 1; }'
for rel in package_probe_web/react_probe.ex probe_main.ex; do
  if ! cmp -s "$work_dir/live_react_probe_out_source/$rel" "$work_dir/live_react_probe_out_package/$rel"; then
    diff -u "$work_dir/live_react_probe_out_source/$rel" "$work_dir/live_react_probe_out_package/$rel" || true
    fail "source and package modes emitted different LiveReact probe output: $rel"
  fi
done
compare_generated_elixir "$work_dir/live_react_probe_out_source" "$work_dir/live_react_probe_out_package"
require_contains "$work_dir/live_react_probe_out_package/package_probe_web/react_probe.ex" "LiveReact.react"
require_contains "$work_dir/live_react_probe_out_package/package_probe_web/react_probe.ex" "use Phoenix.Component"
require_tree_not_contains "$work_dir/live_react_probe_out_package" "$canonical_root"
say "Source/package LiveReact HXX parity: OK"

require_file "$work_dir/out/_GeneratedFiles.json"
require_file "$work_dir/out/main.ex"
require_file "$work_dir/out/string_buf.ex"
require_file "$work_dir/out/string_tools.ex"
require_file "$work_dir/out/haxe/crypto/sha256.ex"
require_file "$work_dir/out/phoenix/channels/wire_payload.ex"
require_file "$work_dir/out/haxe/io/array_buffer_view_impl.ex"
require_file "$work_dir/out/haxe/io/_u_int8_array/u_int8_array_impl_.ex"
require_file "$work_dir/out_source/_GeneratedFiles.json"
require_file "$work_dir/out_source/string_tools.ex"
require_file "$work_dir/out_source/haxe/io/array_buffer_view_impl.ex"
require_file "$work_dir/out_source/haxe/io/_u_int8_array/u_int8_array_impl_.ex"
require_contains "$work_dir/out/_GeneratedFiles.json" '"protocol": "reflaxe-elixir/generated-output"'
require_contains "$work_dir/out/_GeneratedFiles.json" '"version": 2'
require_contains "$work_dir/out/_GeneratedFiles.json" '"ownedFiles"'
require_contains "$work_dir/out_source/_GeneratedFiles.json" '"protocol": "reflaxe-elixir/generated-output"'
if ! cmp -s "$work_dir/out_source/_GeneratedFiles.json" "$work_dir/out/_GeneratedFiles.json"; then
  diff -u "$work_dir/out_source/_GeneratedFiles.json" "$work_dir/out/_GeneratedFiles.json" || true
  fail "source and package modes produced different generated-output ownership manifests"
fi
say "Source/package generated-output ownership parity: OK"
require_contains "$work_dir/out/main.ex" "elem(tuple_value, 0)"
require_contains "$work_dir/out/main.ex" "elem(tuple_value, 1)"
require_contains "$work_dir/out/main.ex" '{:verbose, :boolean}'
require_contains "$work_dir/out/main.ex" '{:source, :string}'
require_contains "$work_dir/out/main.ex" '{:app_name,'
require_contains "$work_dir/out/main.ex" 'parsed = put_elem(parsed, 0, [])'
require_contains "$work_dir/out/main.ex" 'elem(parsed, 1)'
require_not_contains "$work_dir/out/main.ex" 'Keyword.entry'
require_not_contains "$work_dir/out/main.ex" 'Tuple.of2('
require_not_contains "$work_dir/out/main.ex" 'OptionParseResult_Impl_'
require_contains "$work_dir/out/main.ex" "Enum.map"
require_contains "$work_dir/out_source/main.ex" "Enum.map"
require_absent "$work_dir/out/haxe/io/mime.ex"
require_absent "$work_dir/out/haxe/io/scheme.ex"
require_absent "$work_dir/out_source/haxe/io/mime.ex"
require_absent "$work_dir/out_source/haxe/io/scheme.ex"

compare_generated_elixir "$work_dir/out_source" "$work_dir/out"
say "Source/package generated Elixir parity: OK"
source_quality_report="$work_dir/source-quality.json"
package_quality_report="$work_dir/package-quality.json"
run_step "inspect source-checkout structural output" 60 "$ROOT_DIR" \
  "node '$ROOT_DIR/scripts/ci/generated-output-quality.js' --project package-parity --output '$work_dir/out_source' --application main.ex --quality-file main.ex > '$source_quality_report'"
run_step "inspect installed-package structural output" 60 "$ROOT_DIR" \
  "node '$ROOT_DIR/scripts/ci/generated-output-quality.js' --project package-parity --output '$work_dir/out' --application main.ex --quality-file main.ex > '$package_quality_report'"
if ! cmp -s "$source_quality_report" "$package_quality_report"; then
  diff -u "$source_quality_report" "$package_quality_report" || true
  fail "source and package modes produced different structural quality reports"
fi
say "Source/package structural quality parity: OK"
run_step "check source-checkout output uses canonical Mix formatting" 120 "$work_dir" \
  'mix format --force --check-formatted "out_source/**/*.ex"'
run_step "check installed-package output uses canonical Mix formatting" 120 "$work_dir" \
  'mix format --force --check-formatted "out/**/*.ex"'

mix_project="$work_dir/package_mix"
mkdir -p "$mix_project/lib"
cp -R "$work_dir/out/." "$mix_project/lib/"
cat > "$mix_project/mix.exs" <<'EX'
defmodule ReflaxeElixirPackageSmoke.MixProject do
  use Mix.Project

  def project do
    [app: :reflaxe_elixir_package_smoke, version: "0.0.0", elixir: "~> 1.14", deps: []]
  end
end
EX
run_step "compile installed-package Phoenix fixture with Mix" 180 "$mix_project" \
  'mix compile > mix-compile.log 2>&1 || { tail -200 mix-compile.log; exit 1; }'
require_file "$mix_project/_build/dev/lib/reflaxe_elixir_package_smoke/ebin/Elixir.Phoenix.Channels.WirePayload.beam"

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
require_not_contains "$work_dir/compile.log" "Function information not found."
require_not_contains "$work_dir/compile-source.log" "Function information not found."
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
say "OK (source/package parity + installed LiveReact lifecycle + exact-ZIP Mix/Phoenix compile)"
