# Dogfooding (External Phoenix App)

Production readiness requires validating the **real user workflow**:

- install a tagged compiler release
- generate a Phoenix app
- compile Haxe → Elixir
- boot `mix phx.server` and verify runtime
- upgrade to a newer compiler release and confirm the app still builds/runs

This repo keeps that workflow executable as a single, bounded script.

## Script

From repo root:

```bash
scripts/dogfood-phoenix.sh
```

What it does:

1) Creates a temporary workspace under `$TMPDIR`
2) Installs `lix`
3) Generates a Phoenix project
   - `--mode github`: installs `reflaxe.elixir` at `--from-tag` and runs `npx lix run reflaxe.elixir create ...`
   - `--mode local`: uses the current repo generator (to-tag) to scaffold, then validates the app across tags via Mix + lix path/dev deps
4) Installs app deps + Haxe libs (`npm install`, `npx lix download`, `mix deps.get`)
5) Ensures the dev database exists (`mix ecto.create`, `mix ecto.migrate`)
6) Runs the repo QA sentinel against the generated app (`--hxml build.hxml`) for the baseline tag
7) Upgrades `reflaxe.elixir` to `--to-tag` (both Mix dep + lix dev/path)
8) Runs the QA sentinel again

## Options

```bash
# Use local tag archives + Mix path deps (works even before the repo is public)
scripts/dogfood-phoenix.sh --mode local

# Use GitHub tags for both lix + Mix deps (requires public repo access)
scripts/dogfood-phoenix.sh --mode github

# Override upgrade path
# (pick any two tags you care about)
scripts/dogfood-phoenix.sh --from-tag v1.0.7 --to-tag v1.1.6

# Keep the generated app for inspection
scripts/dogfood-phoenix.sh --keep-dir
```

## Requirements

- Elixir + Mix on PATH
- Phoenix generator available (`mix phx.new`)
  - The script installs `phx_new` automatically if needed.
- Node.js + npm
- Haxe toolchain (recommended) or lix-managed Haxe

## Notes

- The script uses the repo QA sentinel in **async** mode with a deadline, then checks the final
  `[QA] DONE status=` line in the sentinel log.
- Generated Phoenix apps use `build.hxml` (not `build-server.hxml`), so the sentinel run uses `--hxml build.hxml`.
