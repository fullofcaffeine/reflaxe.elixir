# Support Matrix

This page describes what toolchain versions Reflaxe.Elixir is **known to work with**.

## CI‑tested versions (source of truth)

Our GitHub Actions CI runs primarily on **Ubuntu**, plus macOS and Windows smoke jobs. CI currently tests:

- Full suite (primary toolchain, Ubuntu):
  - Node.js: `20`
  - Haxe: `4.3.7`
  - Elixir: `1.18.3`
  - Erlang/OTP: `27.2`

- Minimum toolchain smoke (compat check, Ubuntu):
  - Elixir: `1.14.x`
  - Erlang/OTP: `25.x`
  - Runs a bounded subset (`npm run test:quick` + `npm run test:mix-fast`)

- macOS smoke (bounded):
  - Node.js: `20`
  - Haxe: `4.3.7`
  - Elixir: `1.18.3`
  - Erlang/OTP: `27.2`
  - Runs a bounded subset (`npm run test:quick` + `npm run test:mix-fast`)

- Windows smoke (bounded):
  - Node.js: `20`
  - Haxe: `4.3.7`
  - Runs a bounded subset (`npm run test:quick` in an MSYS2 environment)

- Haxe 5 preview smoke (Ubuntu, **non‑gating**):
  - Uses Haxe `nightly` (preview)
  - Runs a bounded subset (`npm run test:quick` + `npm run test:mix-fast`)
  - This job is **allowed to fail** while Haxe 5 support is still being evaluated.

Phoenix coverage:

- `examples/todo-app` pins Phoenix `~> 1.7.0` and is exercised via the QA sentinel workflow (boot + Playwright smoke).

## Minimum versions (documented)

These are the minimum versions we **document**:

- Haxe `4.3.7+`
- Node `16+` (Node `20` recommended)
- Elixir `1.14+`

If you need support for a specific older version, open an issue and include your constraints.

## What is *not* tested (yet)

- Phoenix `1.6.x` and earlier

If you run successfully on other versions, please report it so we can expand the matrix.
