# Legacy HXML configs (todo-app)

These HXML files are **not** part of the normal todo-app development flow. They exist for historical
perf/debug investigations (micro-pass builds, prewarm experiments, etc.) and were moved here to keep
`examples/todo-app/` focused on the canonical builds.

## Canonical builds

Use these files in `examples/todo-app/`:

- `build.hxml` – entry point (delegates to `build-server.hxml`)
- `build-server.hxml` – server (Haxe → Elixir)
- `build-client.hxml` – client (Haxe → JavaScript)
- `build-tests.hxml` – tests (Haxe → ExUnit)
- `build-all.hxml` – convenience wrapper (server + client)

## What lives here

- `build-server-pass*.hxml`, `build-server-multipass.hxml` – legacy “micro-pass” builds
- `build-server-fast.hxml` – legacy fast/partial build profile (QA-only)
- `build-prewarm*.hxml` – cache prewarm experiments
- `build-js.hxml` – legacy alias for the client build

## QA sentinel integration (optional)

The QA sentinel (`scripts/qa-sentinel.sh`) can optionally use these when configured:

- `QA_FORCE_FAST_BUILD=1` – uses `hxml/legacy/build-server-fast.hxml` (if present)
- `QA_USE_PASSES=1` – uses `hxml/legacy/build-server-pass*.hxml` (if present)

