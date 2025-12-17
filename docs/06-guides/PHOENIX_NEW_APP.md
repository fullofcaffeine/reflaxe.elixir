# Phoenix (New App) — Greenfield Setup

This guide shows how to start a brand-new Phoenix project where you can author **selected modules in Haxe** and compile them to idiomatic Elixir.

If you already have an existing Phoenix app, use `docs/06-guides/PHOENIX_GRADUAL_ADOPTION.md`.

## Goal

- Keep Phoenix conventions and tooling (Mix, releases, Ecto, LiveView).
- Add Haxe **incrementally**: start with one module, then expand.
- Generate Elixir code that looks hand-written.

## 1) Create a Phoenix App (normal Phoenix)

Use Phoenix as you normally would:

```bash
mix phx.new my_app
cd my_app
mix deps.get
```

Confirm the baseline app runs:

```bash
mix phx.server
```

## 2) Add Reflaxe.Elixir (follow the gradual adoption guide)

From here, greenfield and “add to existing” are the same workflow.

Continue with:

- `docs/06-guides/PHOENIX_GRADUAL_ADOPTION.md`

## Recommended Template Starting Points

If you prefer a ready-made example to copy:

- `examples/03-phoenix-app/` — minimal Phoenix app authored in Haxe
- `examples/todo-app/` — end-to-end Phoenix LiveView + Ecto + Playwright E2E
