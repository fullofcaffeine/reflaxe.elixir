# Scaffolding System (Phoenix + Mix + Haxe)

This guide explains how Reflaxe.Elixir scaffolding is structured, which commands are “blessed”, and why there are multiple entrypoints.

It is intentionally **user-story driven** and focuses on:

- What to run in each scenario
- What files get patched (and how reruns stay safe)
- The “fail fast” approach and the `--warn-only` escape hatch
- How the Phoenix esbuild watch race is avoided

For the detailed watcher workflow and environment variables, see `docs/06-guides/WATCHER_WORKFLOW.md`.

## The Canonical Commands

There are three layers that work together:

1. `mix haxe.gen.project`
   - Adds server-side plumbing to an existing Mix project: `build.hxml`, `src_haxe/**`, Mix compiler wiring.
   - With `--phoenix`, it also invokes the client scaffold (when the Phoenix shape is present).

2. `mix haxe.phoenix.scaffold`
   - Phoenix client scaffold: Genes client build + watcher wiring + `assets/js/app.js` integration.
   - This is the canonical “Phoenix client integration” command.

3. `haxe --run Run create <name> --type phoenix|liveview`
   - Greenfield generator.
   - It shells out to the canonical Phoenix generator (`mix phx.new`) to create a real Phoenix app, then layers the same Haxe/Mix scaffolding on top.
   - For Phoenix projects, it delegates to `mix haxe.phoenix.scaffold` inside the generated project.

Why both Mix and Haxe entrypoints exist:

- Mix tasks are the best UX for “modify the current project in place”.
- The Haxe generator is the best UX for “create a brand-new project directory”.
- Both converge on the same canonical behavior once a Phoenix project exists: `mix haxe.phoenix.scaffold`.

## Scenarios

### Existing Phoenix app (recommended)

Run from the Phoenix project root:

```bash
mix haxe.gen.project --phoenix --basic-modules --force
```

If you only want the client/watch wiring (and already have server plumbing), run:

```bash
mix haxe.phoenix.scaffold
```

### New Phoenix app (greenfield)

Use the Haxe generator so it can create the Phoenix project via `mix phx.new` first:

```bash
haxe --run Run create my_app --type phoenix
```

It installs deps (unless skipped) and then runs `mix haxe.phoenix.scaffold` within the generated app.

### Non-Phoenix Mix app

Use:

```bash
mix haxe.gen.project --force
```

Do not run `mix haxe.phoenix.scaffold` unless the app is a Phoenix project (it expects `assets/js/app.js` and `config/dev.exs`).

## “Fail Fast” vs `--warn-only`

`mix haxe.phoenix.scaffold` is strict by default:

- If it cannot find an expected Phoenix insertion point (template drift or heavy customization), it raises with a specific message.
- This avoids producing a “half wired” state that only fails later (typically when `mix phx.server` starts).

If your project is heavily customized and you want best-effort patching:

```bash
mix haxe.phoenix.scaffold --warn-only
```

This prints loud warnings and skips patches it cannot safely apply.

## Marker-Block Patching (Idempotent + Obvious Diffs)

Phoenix scaffolding patches files using explicit marker blocks, inserted once and then only updated in place on rerun:

- `assets/js/app.js`
  - `BEGIN reflaxe_elixir hx_app_import`
  - `BEGIN reflaxe_elixir hooks_after_decl` or `BEGIN reflaxe_elixir hooks_property`
- `config/dev.exs`
  - `BEGIN reflaxe_elixir haxe_client`
- `mix.exs`
  - `BEGIN reflaxe_elixir haxe_compile_client_alias`
  - `BEGIN reflaxe_elixir assets.build_task`
  - `BEGIN reflaxe_elixir assets.deploy_task`

Why marker blocks:

- Reruns replace only the block content; they do not re-run brittle “find `watchers: [`” heuristics when blocks already exist.
- Removal is straightforward and reviewable: delete the block(s).

## Phoenix Client Build: Avoiding esbuild `--watch` Races

Haxe deletes its `-js` output file at the start of compilation. If esbuild imports that file directly, `--watch` can race the deletion and error with:

- `Could not resolve "./hx_app.js"`

The scaffold prevents this via “temp output + promote”:

- `build-client.hxml` targets a temp file: `assets/js/_hx_app_tmp.js`
- Phoenix dev watchers run: `mix haxe.watch ... --promote assets/js/_hx_app_tmp.js:assets/js/hx_app.js,...`
- esbuild imports the stable path: `import "./hx_app.js";`

See `docs/06-guides/WATCHER_WORKFLOW.md` for the full rationale.

## `hx_app.js` Stub Safety

The scaffold creates `assets/js/hx_app.js` as a stub so esbuild can boot before the first successful Haxe client compile.

Safety rules:

- The stub includes a signature string so the scaffold can detect “our stub”.
- On rerun, the scaffold overwrites `hx_app.js` only if it still contains the stub signature.
- If you customize `hx_app.js`, it is treated as user-owned and is never clobbered.

## Project-Local `haxe_libraries/*.hxml` Stubs

`mix haxe.phoenix.scaffold` also creates project-local `haxe_libraries/*.hxml` stubs needed by `build-client.hxml`:

- `haxe_libraries/genes.hxml`
- `haxe_libraries/phoenix_js.hxml`
- `haxe_libraries/helder.set.hxml`

These are signature-managed:

- If a file contains the scaffold signature, reruns can update it safely.
- If you remove the signature line, the file becomes user-owned and will not be overwritten.

This makes client builds reproducible without relying on global haxelib state.

