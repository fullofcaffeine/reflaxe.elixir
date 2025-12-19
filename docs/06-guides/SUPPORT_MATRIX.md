# Support Matrix

This page describes what toolchain versions Reflaxe.Elixir is **known to work with**.

## CI‑tested versions (source of truth)

Our GitHub Actions CI runs on **Ubuntu** and currently tests:

- Node.js: `20`
- Haxe: `4.3.7`
- Elixir: `1.18.3`
- Erlang/OTP: `27.2`

Phoenix coverage:

- `examples/todo-app` pins Phoenix `~> 1.7.0` and is exercised via the QA sentinel workflow (boot + Playwright smoke).

## Minimum versions (documented)

These are the minimum versions we **document** (not necessarily CI‑tested on every combination):

- Haxe `4.3.7+`
- Node `16+` (Node `20` recommended)
- Elixir `1.14+`

If you need support for a specific older version, open an issue and include your constraints.

## What is *not* tested (yet)

- Haxe `5.x`
- Windows/macOS runners in CI
- Phoenix `1.6.x` and earlier

If you run successfully on other versions, please report it so we can expand the matrix.

