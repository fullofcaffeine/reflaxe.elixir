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

1. `haxe --run Run create <name> --type basic|phoenix|liveview|add-to-existing`
   - Haxe-side generator for **new project directories** (greenfield).
   - For Phoenix/LiveView, it creates the app via `mix phx.new`, then runs the same Mix scaffolding inside that app.
   - Supports `--client-mode genes|plain-js` (default: `genes`) for Phoenix client wiring.

2. `mix haxe.gen.project`
   - Mix-side generator for **existing project directories** (gradual adoption).
   - Adds server-side plumbing: `build.hxml`, `src_haxe/**`, Mix compiler wiring.
   - With `--phoenix`, it also invokes `mix haxe.phoenix.scaffold`.
   - Supports `--client-mode genes|plain-js` when `--phoenix` is used (default: `genes`).

3. `mix haxe.phoenix.scaffold`
   - Canonical Phoenix client integration task.
   - `--client-mode genes` (default): typed Haxe/Genes client build + watcher promotion + `app.js` hook merge.
   - `--client-mode plain-js`: removes scaffold-managed Genes wiring and converges back to plain Phoenix JS.
   - Use `--yes` for non-interactive plain-js convergence (CI/generator flows).

Why both Mix and Haxe entrypoints exist:

- Mix tasks are the best UX for “modify the current project in place”.
- The Haxe generator is the best UX for “create a brand-new project directory”.
- Both converge on the same canonical Phoenix client behavior through `mix haxe.phoenix.scaffold`.

## Why This Split Exists (Not Redundant)

This split is intentional and architectural, not duplication:

1. Project creation and project mutation are different operations.
   - `haxe --run Run create ...` owns **directory creation** and “new app” flows.
   - Mix tasks own **in-place patching** of an existing Mix/Phoenix tree.

2. Mix tasks are the canonical patching surface.
   - Phoenix wiring is centralized in `mix haxe.phoenix.scaffold`.
   - Both greenfield and gradual-adoption flows call the same task, so behavior stays aligned.

3. This avoids drift between templates.
   - One Phoenix wiring implementation means fewer divergent code paths and easier maintenance.

Decision matrix:

- New app directory: `haxe --run Run create <name> --type phoenix|liveview`
- Existing app, add Haxe server plumbing: `mix haxe.gen.project`
- Existing app, apply/remove Phoenix JS client wiring only: `mix haxe.phoenix.scaffold --client-mode genes|plain-js`

## Scenarios

### Existing Phoenix app (recommended)

Run from the Phoenix project root:

```bash
mix haxe.gen.project --phoenix --client-mode genes --basic-modules --force
```

If you only want the client/watch wiring (and already have server plumbing), run:

```bash
mix haxe.phoenix.scaffold --client-mode genes
# or converge back to plain Phoenix JS:
mix haxe.phoenix.scaffold --client-mode plain-js --yes
```

### New Phoenix app (greenfield)

Use the Haxe generator so it can create the Phoenix project via `mix phx.new` first:

```bash
haxe --run Run create my_app --type phoenix --client-mode genes
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
- If it finds an existing scaffold entry (like `haxe_client:` or `"haxe.compile.client":`) that is **not** marker-managed, it raises to avoid silently skipping an update and leaving the project in a half-wired drifted state.
- This avoids producing a “half wired” state that only fails later (typically when `mix phx.server` starts).

If your project is heavily customized and you want best-effort patching:

```bash
mix haxe.phoenix.scaffold --warn-only
```

This prints loud warnings and skips patches it cannot safely apply.

For plain-js convergence (`--client-mode plain-js`), the task asks for confirmation before removing scaffold-managed files.
Use `--yes` to skip the prompt (recommended in automation).

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
