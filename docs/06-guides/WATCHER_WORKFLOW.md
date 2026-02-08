# Watcher Workflow (Mix + Phoenix)

This guide describes the common “edit → compile → reload” loop when using Reflaxe.Elixir with Phoenix.

> [!NOTE]
> This is a dev-workflow guide. It is not fully CI-smoked because port/watcher behavior depends on your local environment.
> For “new user” verified flows, see `bash scripts/ci/docs-smoke.sh` and `bash scripts/ci/readme-release-tag-smoke.sh`.

## Two Watch Loops You’ll See

1. **Server compilation (Haxe → Elixir)**
   - Driven by Mix tasks (e.g., `mix compile.haxe`, `mix haxe.watch`).
   - Uses a background Haxe compilation server when available.

2. **Client build/watch (Haxe → JS)**
   - Typically run via Phoenix endpoint watchers as `mix haxe.watch --hxml build-client.hxml ...`.
   - This keeps an incremental client compiler process alive during `mix phx.server`.
   - Recommended generator: **Genes** (ES modules) via `-lib genes` in `build-client.hxml`.

### Important: esbuild `--watch` + Haxe `-js` output races

Haxe deletes the `-js` output file at the start of compilation. If your esbuild entry imports that file
(for example `assets/js/app.js` contains `import "./hx_app.js"`), then in watch mode esbuild can see a
brief window where the module disappears and error with:

- `Could not resolve "./hx_app.js"`

**Recommended pattern (used by `examples/todo-app/`):**
- Have `build-client.hxml` write its `-js` output to a temp path (example: `assets/js/_hx_app_tmp.js`).
- After a successful compile, promote that temp file into the stable import path (example: `assets/js/hx_app.js`).
- Configure Phoenix watchers to use `mix haxe.watch --promote from:to` so promotion happens atomically.

If you want this wiring scaffolded automatically in a Phoenix app, run:

```bash
mix haxe.phoenix.scaffold
```

This task patches `config/dev.exs`, `mix.exs`, and `assets/js/app.js` using explicit marker blocks
(`BEGIN reflaxe_elixir ...` / `END reflaxe_elixir ...`) so reruns update only the block content.

### What gets created/changed (and why it stays stable)

- `assets/js/_hx_app_tmp.js` is the Genes entry output path (temp).
  - Haxe deletes this file at the start of each rebuild, so it is not safe to import directly from esbuild watch.
- `assets/js/hx_app.js` is the stable import path.
  - The scaffold writes a committed stub file (signature: `reflaxe_elixir:hx_app_stub:v1`).
  - The watcher promotes `_hx_app_tmp.js -> hx_app.js` after successful compiles so esbuild always has a file to import.
  - The scaffold only overwrites `hx_app.js` if it detects its own stub signature; user customizations are not clobbered.

## Recommended Workflow

- Run normal Phoenix dev:
  - `mix phx.server`
- Let the endpoint watchers handle the client build.
- Use `mix compile.haxe` / `mix haxe.watch` for server-side compilation flows.

## Common Environment Variables

- `HAXE_NO_SERVER=1` — disables the background Haxe server (forces direct compilation)
- `HAXE_SERVER_PORT=6116` — preferred server port. If that port is busy, Mix may attach to the prior compatible server recorded in `.reflaxe_elixir/haxe_server.json` (same project/toolchain), or relocate to a free port.
- `HAXE_SERVER_ALLOW_ATTACH=1` — allow attaching to an externally-started compatible server on the configured port (default: off)
- `HAXE_FAST_BOOT=1` — opt-in faster compilation profile (see `docs/06-guides/PERFORMANCE_GUIDE.md`)
- `HAXE_CLIENT_WAIT_PORT=6001` — overrides the Phoenix watcher wait port (client build)

## Troubleshooting

### `EADDRINUSE` on the client `--wait` port

This usually means a previous `haxe --wait` process is still running and holding the port.

- Prefer reusing/adjusting the wait port (some examples auto-pick a free port).
- If needed, terminate the orphaned process before retrying.

## Todo-App QA Note

When validating the example todo-app, use the repo’s QA sentinel scripts (non-blocking) instead of
running long-lived foreground servers during agent work. See root `AGENTS.md`.
