#!/usr/bin/env bash
set -euo pipefail

example_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$example_dir/../.." && pwd)
mix_bin=${MIX_BIN:-mix}
haxe_bin=${HAXE_BIN:-haxe}
qa_workspace=
qa_migrations_dir=
ownership_marker=
database_suffix_override=${QA_DATABASE_SUFFIX:-}

if [[ -n "$database_suffix_override" ]] \
  && { [[ ! "$database_suffix_override" =~ ^[a-zA-Z0-9_]+$ ]] \
    || (( ${#database_suffix_override} + 27 > 63 )); }; then
  echo "[ecto-migrations-qa] Refusing unsafe database suffix: $database_suffix_override" >&2
  exit 64
fi

qa_workspace=$(mktemp -d "${TMPDIR:-/tmp}/ecto-migrations-qa.XXXXXX")
workspace_suffix=${qa_workspace##*.}
database_suffix=${database_suffix_override:-"${GITHUB_RUN_ID:-local}_${GITHUB_RUN_ATTEMPT:-1}_${workspace_suffix}"}
database_name="ecto_migrations_example_qa_${database_suffix}"
ownership_marker="$qa_workspace/database-owned"

if [[ ! "$database_name" =~ ^ecto_migrations_example_qa_[a-zA-Z0-9_]+$ ]] || (( ${#database_name} > 63 )); then
  echo "[ecto-migrations-qa] Refusing unsafe database name: $database_name" >&2
  exit 64
fi

qa_migrations_dir="$qa_workspace/priv/repo/migrations"
export ECTO_MIGRATIONS_DATABASE=$database_name
export ECTO_MIGRATIONS_PATH=$qa_migrations_dir
export ECTO_MIGRATIONS_OWNERSHIP_MARKER=$ownership_marker
export HAXE_NO_SERVER=${HAXE_NO_SERVER:-1}
if [[ -z "${HAXELIB_PATH:-}" || ! -f "$HAXELIB_PATH/reflaxe.elixir.hxml" ]]; then
  export HAXELIB_PATH="$repo_root/haxe_libraries"
fi

cleanup() {
  local status=$?
  local cleanup_status=0
  trap - EXIT INT TERM
  set +e
  if [[ -f "$ownership_marker" ]] && [[ $(<"$ownership_marker") == "$database_name" ]]; then
    MIX_ENV=test "$mix_bin" do app.start, ecto.drop --quiet
    cleanup_status=$?
  fi
  rm -rf -- "$qa_workspace"
  local migration_cleanup_status=$?
  if (( cleanup_status == 0 && migration_cleanup_status != 0 )); then
    cleanup_status=$migration_cleanup_status
  fi
  if (( status == 0 && cleanup_status != 0 )); then
    status=$cleanup_status
  fi
  exit "$status"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

cd "$example_dir"
echo "[ecto-migrations-qa] Preparing isolated database $database_name"
"$mix_bin" deps.get
cp -R "$example_dir/src_haxe" "$qa_workspace/src_haxe"
cp "$example_dir/build-migrations.hxml" "$qa_workspace/build-migrations.hxml"
(
  cd "$repo_root"
  "$haxe_bin" --cwd "$qa_workspace" build-migrations.hxml
)
if [[ ! -f "$qa_migrations_dir/20240101120000_create_users.exs" \
   || ! -f "$qa_migrations_dir/20240102120000_create_posts.exs" ]]; then
  echo "[ecto-migrations-qa] Fresh timestamped migrations were not generated" >&2
  exit 1
fi
"$haxe_bin" build-tests.hxml
MIX_ENV=test "$mix_bin" compile
MIX_ENV=test "$mix_bin" compile --force --warnings-as-errors --no-deps-check
MIX_ENV=test "$mix_bin" run --no-start --no-compile qa/strict_compile_migrations.exs
MIX_ENV=test "$mix_bin" run --no-start --no-compile qa/create_owned_database.exs
MIX_ENV=test "$mix_bin" do app.start, ecto.migrate --quiet --migrations-path "$qa_migrations_dir"
MIX_ENV=test "$mix_bin" test --no-compile
