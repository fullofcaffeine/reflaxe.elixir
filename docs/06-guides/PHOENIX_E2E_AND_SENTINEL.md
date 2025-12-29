# Phoenix E2E & QA Sentinel (non-blocking)

Reflaxe.Elixir has three practical QA layers:

1) **Compiler layer** (Haxe→Elixir codegen): snapshot tests under `test/snapshot/**`
2) **Integration layer** (compiler → Phoenix runtime): build + boot the todo-app and probe readiness
3) **Application layer** (real browser): Playwright smoke/regression tests against the running app

The **QA sentinel** is the recommended way to validate layers (2) and (3) locally and in CI, because it:
- Builds Haxe → Elixir
- Runs `mix deps.get` + `mix compile`
- Boots `mix phx.server` **in the background**
- Probes readiness with bounded timeouts
- Optionally runs Playwright
- Tears everything down cleanly (unless `--keep-alive`)

## Quick Start

From the repo root:

```bash
npm run qa:sentinel
```

This uses `scripts/qa-sentinel.sh` in **async mode** with a deadline, so it never hangs your terminal.

## Non-Blocking Workflow (async + bounded logs)

Run the sentinel:

```bash
scripts/qa-sentinel.sh --app examples/todo-app --port 4001 --async --deadline 600 --verbose
```

It prints:
- `QA_SENTINEL_PID=...` (background runner)
- `QA_SENTINEL_RUN_ID=...` (log ID)

Peek logs without blocking:

```bash
scripts/qa-logpeek.sh --run-id <RUN_ID> --last 200
scripts/qa-logpeek.sh --run-id <RUN_ID> --until-done 60
```

Stop the background run:

```bash
kill -TERM $QA_SENTINEL_PID
```

## Keep-Alive (manual browsing / debugging)

Start Phoenix and keep it running:

```bash
scripts/qa-sentinel.sh --app examples/todo-app --env e2e --port 4001 --keep-alive -v
```

The script prints `PHX_PID` and `PORT`.

Stop Phoenix when done:

```bash
kill -TERM $PHX_PID
```

## Playwright E2E

Run Playwright as part of the sentinel (recommended for CI-style verification):

```bash
scripts/qa-sentinel.sh --app examples/todo-app --env e2e --port 4001 \
  --playwright --e2e-spec "e2e/*.spec.ts" --async --deadline 900 --verbose
```

Notes:
- If you pass `--playwright` and leave `--env` as `dev`, the sentinel defaults to `e2e` for DB isolation.
- The sentinel sets `BASE_URL` automatically for Playwright.
- Use `--e2e-workers 1` (default) for determinism when debugging flakes.

To run Playwright manually against a keep-alive server:

```bash
BASE_URL=http://localhost:4001 npx -C examples/todo-app playwright test e2e/<spec>.ts
```

## Environments (todo-app)

The todo-app uses `--env` to pick a Mix environment:
- `dev`: fast iteration (PORT optional)
- `test`: SQL sandbox enabled; `todo_app_test` DB
- `e2e`: dedicated `todo_app_e2e` DB; `server: true`; PORT respected (recommended for Playwright)
- `prod`: strict runtime config in `config/runtime.exs` (requires `SECRET_KEY_BASE`/`PORT`)

## Common Flags

- `--reuse-db` (non-dev): skips DB drop; ensures create + migrate only
- `--seeds PATH`: runs seeds after migrations (example: `priv/repo/seeds.e2e.exs`)
- `--hxml FILE`: override the Haxe build file (defaults to `build-server.hxml`)
- `--deadline SECS`: hard cap watchdog for async runs (recommended even outside CI)

See `scripts/qa-sentinel.sh` for the full flag list.

## Troubleshooting

### Port already in use

If you see `EADDRINUSE`, something else is listening on the port (common ones):
- Phoenix: `4000` (default) / sentinel default: `4001`
- Haxe compilation server: `6116`
- Todo-app watcher wait port: `6001` (used by the asset watcher integration)

To identify a process:

```bash
lsof -nP -iTCP:4001 -sTCP:LISTEN || true
lsof -nP -iTCP:6001 -sTCP:LISTEN || true
```

Then stop it (example):

```bash
kill -TERM <PID>
```

### Commands must finish

If you run long steps manually, keep them bounded:

```bash
scripts/with-timeout.sh --secs 120 -- mix test
```

## Testing Strategy (trophy)

- Prefer **Haxe-authored ExUnit** for most coverage (ConnTest/LiveViewTest).
- Keep Playwright **thin** (smoke/regression). Use resilient selectors; `data-testid` only when necessary.

## Secrets

- `dev`/`test`/`e2e`: allow env overrides with safe fallbacks for local iteration.
- `prod`: required via `config/runtime.exs` (no fallbacks).
