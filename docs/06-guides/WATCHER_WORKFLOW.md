# Watcher Workflow (Mix + Phoenix)

This guide describes the common “edit → compile → reload” loop when using Reflaxe.Elixir with Phoenix.

## Two Watch Loops You’ll See

1. **Server compilation (Haxe → Elixir)**
   - Driven by Mix tasks (e.g., `mix compile.haxe`, `mix haxe.watch`).
   - Uses a background Haxe compilation server when available.

2. **Client build/watch (Haxe → JS)**
   - Typically run via Phoenix endpoint watchers as `haxe build-client.hxml --wait <port>`.
   - This keeps an incremental JS compiler process alive during `mix phx.server`.
   - Recommended generator: **Genes** (ES modules) via `-lib genes` in `build-client.hxml`.

## Recommended Workflow

- Run normal Phoenix dev:
  - `mix phx.server`
- Let the endpoint watchers handle the client build.
- Use `mix compile.haxe` / `mix haxe.watch` for server-side compilation flows.

## Common Environment Variables

- `HAXE_NO_SERVER=1` — disables the background Haxe server (forces direct compilation)
- `HAXE_SERVER_PORT=6116` — sets the server port
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
