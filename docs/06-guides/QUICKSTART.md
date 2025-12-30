# Quickstart (Phoenix-first)

Reflaxe.Elixir is currently **alpha** overall. This quickstart is focused on helping a Phoenix developer get productive quickly while we continue hardening the compiler, stdlib, and tooling.

If you’re new to Haxe and/or new to Phoenix, start here first:

- `docs/01-getting-started/START_HERE.md`

## Pick a Path

- New Phoenix app (greenfield): `docs/06-guides/PHOENIX_NEW_APP.md`
- Existing Phoenix app (gradual adoption): `docs/06-guides/PHOENIX_GRADUAL_ADOPTION.md`
- Learn by example: `examples/README.md` (start with `examples/03-phoenix-app/` or `examples/todo-app/`)

## Prerequisites

- Elixir 1.14+
- Node.js 16+ (for `lix` and JS toolchain)
- Haxe 4.3.7+ on your PATH

If you don’t have Haxe installed yet, start here: `docs/01-getting-started/installation.md`.

## One-Minute Smoke Test (using the repo’s todo-app)

```bash
cd examples/todo-app
mix setup
```

Recommended bounded smoke (from repo root, non-blocking):

```bash
npm run qa:sentinel
scripts/qa-logpeek.sh --run-id <RUN_ID> --until-done 600
```

Manual dev run (foreground server):

```bash
cd examples/todo-app
mix phx.server
```

Open `http://localhost:4000` (default dev port).

## Important Notes

- Prefer `haxe ...` (or `npx lix run haxe ...` if `haxe` isn’t on your PATH).
- Avoid `npx haxe ...` (the npm package) — it can pull a separate platform-specific Haxe binary and breaks on some systems (notably macOS arm64).
- Do not use `-D analyzer-optimize` for the Elixir target; it produces non-idiomatic output and can break functional shapes. See `docs/01-getting-started/compiler-flags-guide.md`.
