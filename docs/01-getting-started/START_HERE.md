# Start Here (Beginner Quickstart)

This guide is for **complete beginners**:

- New to **Haxe**
- New to **Elixir/Phoenix**
- Or both

Goal: run a real Phoenix LiveView app written in Haxe and understand the “mental model” in under ~15 minutes.

> [!NOTE]
> Reflaxe.Elixir `v1.1.x` is considered **non‑alpha** for the documented subset.
> Experimental/opt‑in features remain clearly labeled; see `docs/06-guides/PRODUCTION_READINESS.md` for the hardening checklist.

## 0) Install prerequisites (one-time)

You need these tools installed on your machine:

- **Git** (clone repos)
- **Node.js 16+** (for `lix`, the Haxe toolchain manager)
- **Elixir 1.14+** (includes Erlang/OTP; runs Phoenix)
- **PostgreSQL** (required for the todo-app example; most Phoenix apps use it)

Quick verification:

```bash
git --version
node --version
elixir --version
mix --version
psql --version
```

If you don’t want to install Postgres globally, you can run it via Docker (optional):

```bash
docker run --name reflaxe_pg -e POSTGRES_PASSWORD=postgres -p 5432:5432 -d postgres:16
```

The repo examples default to `username=postgres`, `password=postgres`, `host=localhost`.

## 1) Easiest “try it now”: run the repo todo-app

This is the fastest way to see Reflaxe.Elixir working end-to-end without creating a new project.

```bash
git clone https://github.com/fullofcaffeine/reflaxe.elixir.git
cd reflaxe.elixir

# installs lix + downloads pinned Haxe deps
npm install

# builds todo-app, boots Phoenix in the background, probes readiness, then shuts down
npm run qa:sentinel
```

Even easier (and keeps the app running so you can click around):

```bash
npm run demo:todo
```

That command runs async and prints a `RUN_ID`. View the final status:

```bash
scripts/qa-logpeek.sh --run-id <RUN_ID> --until-done 600
```

If you want the server to stay up for manual browsing:

```bash
scripts/qa-sentinel.sh --app examples/todo-app --port 4001 --keep-alive -v
```

If you want a quick browser E2E smoke (Playwright), run:

```bash
scripts/qa-sentinel.sh --app examples/todo-app --port 4001 --playwright --e2e-spec "e2e/*.spec.ts" --async --deadline 900 --verbose
```

## 2) Generate your own Phoenix app (recommended next step)

If you want a fresh app scaffold with the Haxe+Phoenix wiring already set up:

```bash
mkdir reflaxe_demo && cd reflaxe_demo
npm init -y
npm install --save-dev lix
npx lix scope create

# Install the generator (pin a tag for reproducibility)
npx lix install github:fullofcaffeine/reflaxe.elixir#v1.1.3

# Generate a Phoenix app
npx lix run reflaxe.elixir create my_app --type phoenix --no-interactive

cd my_app
mix deps.get
mix phx.server
```

Then open `http://localhost:4000`.

More details: `docs/06-guides/PHOENIX_NEW_APP.md`.

## 3) The mental model (Haxe → Elixir → Phoenix)

You don’t need to master either ecosystem up front—just remember:

- You write **Haxe** in `src_haxe/**/*.hx`.
- Reflaxe.Elixir compiles it into **Elixir** modules under `lib/**/*.ex`.
- Phoenix (Mix) runs like a normal Phoenix app; Reflaxe.Elixir just generates part of the `lib/` tree.

Haxe compilation is configured with `*.hxml` files (think “a build command written as flags”).
In a typical project you’ll see a server build (Elixir output) and often a client build (JS output).

## 4) Common first-time issues

### `haxe: command not found`

This repo uses `lix` to manage the Haxe toolchain. If `haxe` isn’t on your PATH:

```bash
npx lix run haxe --version
```

### Database connection failures

- Ensure Postgres is running locally and accepting connections.
- Ensure credentials match the example config (defaults: `postgres/postgres`).

### Port conflicts (Phoenix or Haxe watcher)

- Phoenix port: run with `PORT=4001 mix phx.server`
- Haxe watcher port (client build): set `HAXE_CLIENT_WAIT_PORT=6002` (todo-app), or stop the stale process holding the port.

### “Where do I learn Haxe / Phoenix basics?”

- Haxe basics: `docs/02-user-guide/HAXE_LANGUAGE_FUNDAMENTALS.md`
- Phoenix integration overview: `docs/02-user-guide/PHOENIX_INTEGRATION.md`
- Quickstart (Phoenix-first): `docs/06-guides/QUICKSTART.md`

## Glossary (quick definitions)

- **Haxe**: A typed language (TypeScript-like feel) designed for building compilers/generators and targeting multiple platforms.
- **HXML**: A “build file” for Haxe (it’s basically a set of `haxe` command-line flags in a file).
- **Reflaxe**: A compiler framework for writing Haxe→X targets (Reflaxe.Elixir is one target).
- **Elixir**: A dynamic language running on the BEAM VM (Erlang ecosystem).
- **BEAM / OTP**: The Erlang runtime + standard libraries for concurrency, supervision, and fault-tolerance.
- **Phoenix**: The main Elixir web framework.
- **LiveView**: Phoenix’s server-rendered real-time UI layer (no custom SPA required).
- **Ecto**: Elixir’s database layer (schemas, queries, migrations).
- **Mix**: Elixir’s build tool/package manager (think `npm`, but for Elixir).
- **HEEx**: Phoenix’s HTML-aware template format.
- **HXX**: Reflaxe.Elixir’s typed JSX-like syntax that compiles into HEEx/Elixir (see `docs/02-user-guide/HXX_SYNTAX_AND_COMPARISON.md`).
- **Externs**: Typed Haxe declarations for existing Elixir APIs (used to keep your Haxe code type-safe).
- **`__elixir__()`**: An escape hatch to inject raw Elixir into generated output. Allowed, but not meant to be the “happy path” for app code.
