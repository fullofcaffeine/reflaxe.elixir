# Phoenix (New App) — Greenfield Setup

This guide shows how to start a brand-new Phoenix project where you can author **selected modules in Haxe** and compile them to idiomatic Elixir.

If you already have an existing Phoenix app, use `docs/06-guides/PHOENIX_GRADUAL_ADOPTION.md`.

## Goal

- Keep Phoenix conventions and tooling (Mix, releases, Ecto, LiveView).
- Add Haxe **incrementally**: start with one module, then expand.
- Generate Elixir code that looks hand-written.

## Output And Deployment Mental Model

The generated project is still a Phoenix app. Haxe source files are build inputs;
Phoenix deploys the generated Elixir app the same way it would deploy a vanilla
Phoenix app.

```text
src_haxe/**      # Haxe source you edit
src_shared/**    # shared Haxe contracts, when used
lib/**           # generated and/or handwritten Elixir that Mix compiles
assets/**        # Phoenix assets pipeline, including generated JS imports
priv/**          # migrations, static files, seeds
```

Before release/deploy, make sure the Haxe server and client builds have run,
then use normal Phoenix commands such as `mix assets.deploy`, `mix compile`, and
`mix release`. See the
[Phoenix Output Model](../05-architecture/PHOENIX_OUTPUT_MODEL.md) for the
full in-place vs materialized layout comparison.

## Option A (recommended): scaffold via the project generator

If you have Haxe + Node installed, you can generate a ready-to-run Phoenix+Haxe project in one go:

```bash
# From an empty directory where you want the project folder created:
npm init -y
npm install --save-dev lix
npx lix scope create

# Install the Reflaxe-built package from the latest GitHub release
# If this fails (no `curl` / GitHub rate limit), pick a tag from the Releases page and set it manually.
REFLAXE_ELIXIR_TAG="$(curl -fsSL https://api.github.com/repos/fullofcaffeine/reflaxe.elixir/releases/latest | sed -n 's/.*\"tag_name\":[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p' | head -n 1)"
REFLAXE_ELIXIR_VERSION="${REFLAXE_ELIXIR_TAG#v}"
npx lix install "https://www.github.com/fullofcaffeine/reflaxe.elixir/releases/download/${REFLAXE_ELIXIR_TAG}/reflaxe.elixir-${REFLAXE_ELIXIR_VERSION}.zip"

# Generate a Phoenix app
# (Use `haxe --run Run` here because some lix/haxelib shim versions rely on an internal
# `run-dir` command which is not reliable across environments.)
REFLAXE_ELIXIR_SRC="$(./node_modules/.bin/haxelib path reflaxe.elixir | tr -d '\r' | grep -E 'reflaxe\.elixir/.*/src/?$' | head -n 1)"
./node_modules/.bin/haxe -cp "$REFLAXE_ELIXIR_SRC" --run Run create my_app --type phoenix --no-interactive

cd my_app
mix setup
mix phx.server
```

What you get from the generator (Phoenix types):

- Server Haxe integration (`build.hxml`, `src_haxe/**`, `mix.exs` compiler wiring)
- Client Haxe integration for LiveView hooks:
  - `build-client.hxml` outputs to `assets/js/_hx_app_tmp.js`
  - A stable import path `assets/js/hx_app.js` (published via promotion after successful compiles)
  - `assets/js/app.js` imports `./hx_app.js` and merges hooks from `window.Hooks`
  - A dev watcher that runs `mix haxe.watch --hxml build-client.hxml --promote ...`
  - `.gitignore` entries for `assets/js/_hx_app_tmp.js*` and `assets/js/hx_app.js*` (client build artifacts)

The temp output + promotion pattern is important because Haxe deletes its `-js` output at the start of compilation; in
watch mode that can race esbuild and cause transient `Could not resolve "./hx_app.js"` errors unless the imported path
is stable.

If you pass `--skip-install` (or installs fail), run the installs manually:

```bash
cd my_app
npm install
npx lix scope create
# If this fails (no `curl` / GitHub rate limit), pick a tag from the Releases page and set it manually.
REFLAXE_ELIXIR_TAG="$(curl -fsSL https://api.github.com/repos/fullofcaffeine/reflaxe.elixir/releases/latest | sed -n 's/.*\"tag_name\":[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p' | head -n 1)"
REFLAXE_ELIXIR_VERSION="${REFLAXE_ELIXIR_TAG#v}"
npx lix install "https://www.github.com/fullofcaffeine/reflaxe.elixir/releases/download/${REFLAXE_ELIXIR_TAG}/reflaxe.elixir-${REFLAXE_ELIXIR_VERSION}.zip"
npx lix download
mix setup
mix haxe.phoenix.scaffold
mix phx.server
```

## Option B: create a Phoenix app (normal Phoenix) + add Haxe (gradual adoption)

Use Phoenix as you normally would:

```bash
mix phx.new my_app
cd my_app
```

Confirm the baseline app runs:

```bash
mix setup
mix phx.server
```

## 2) Add Reflaxe.Elixir (follow the gradual adoption guide)

From here, greenfield and “add to existing” are the same workflow.

Continue with:

- `docs/06-guides/PHOENIX_GRADUAL_ADOPTION.md`
  - For a concrete end-to-end walkthrough, see `docs/06-guides/PHOENIX_CHAT_TUTORIAL.md`.

## Recommended Template Starting Points

If you prefer a ready-made example to copy:

- `examples/03-phoenix-app/` — minimal Phoenix app authored in Haxe
- `examples/13-elixir-first-liveview/` — minimal typed Elixir-first LiveView workflow in Haxe
- `examples/12-phoenix-chat/` — Presence + PubSub + LiveView in Haxe (hybrid adoption tutorial)
- `examples/15-phoenix-chat-haxe-first/` — Presence + PubSub + LiveView with app/router also authored in Haxe
- `examples/todo-app/` — end-to-end Phoenix LiveView + Ecto + Playwright E2E
