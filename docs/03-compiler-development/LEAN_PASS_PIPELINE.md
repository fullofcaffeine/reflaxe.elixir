# Lean Pass Pipeline (Contributor Guide)

Reflaxe.Elixir’s AST transformer stack is intentionally **ordered**: each pass assumes certain
shapes are already normalized by earlier passes. This document explains:

- where pass ordering lives,
- how to inspect the effective order,
- and which fixtures guard LiveView correctness without relying on the todo-app.

## Where ordering lives

- Registry (source of truth):
  - `src/reflaxe/elixir/ast/transformers/registry/ElixirASTPassRegistry.hx`
- Registry groups (keep the registry readable):
  - `src/reflaxe/elixir/ast/transformers/registry/groups/`
- Runner (applies passes in order, skipping `enabled: false`):
  - `src/reflaxe/elixir/ast/ElixirASTTransformer.hx`

## Inspect the effective pass order

The repository maintains a generated, deterministic pass ordering doc:

- `docs/05-architecture/TRANSFORM_PASS_REGISTRY_ORDER.md`

Regenerate it (pure Haxe `--interp`, no Node required):

```bash
haxe --interp tools/RegistryOrderDoc.hx
```

## LiveView “golden” fixture

The todo-app is a great integration test, but it’s too large and app-specific for a stable
regression signal. Use the focused LiveView fixture snapshot instead:

- `test/snapshot/liveview/golden_liveview_fixture`

What it covers:
- runnable callback names/shapes: `mount/3`, `handle_event/3`, `handle_info/2`, `render/1`
- event parameter extraction from `params` (shape-only, no domain heuristics)
- typed assigns updates via `LiveSocket` macros

Run it:

```bash
make -C test single TEST=liveview/golden_liveview_fixture
```

Update its intended output (when a change is intentional):

```bash
make -C test update-intended TEST=liveview/golden_liveview_fixture
```

## Design guardrails (reminders)

- Prefer **shape-based** transforms over name-based heuristics.
- Avoid ERaw-dependent rewrites (passes can’t “see” inside raw strings).
- Fix root causes in builder/transformer; keep the printer as a pretty-printer only.

