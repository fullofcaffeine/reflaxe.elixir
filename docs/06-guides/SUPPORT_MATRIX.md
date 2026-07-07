# Support Matrix

This page describes what toolchain versions Reflaxe.Elixir is **known to work with**.

## CI‑tested versions (source of truth)

Our GitHub Actions CI runs primarily on **Ubuntu**, plus a macOS smoke job. CI currently tests:

- Full suite (primary toolchain, Ubuntu):
  - Node.js: `20`
  - Haxe: `4.3.7`
  - Elixir: `1.18.3`
  - Erlang/OTP: `27.2`

- Minimum toolchain smoke (compat check, Ubuntu):
  - Elixir: `1.14.x`
  - Erlang/OTP: `25.x`
  - Runs a bounded subset (`npm run test:quick` + `npm run test:mix-fast`)
  - Note: `npm run test:mix-fast` feature-detects newer Mix flags (e.g. `--stale`) to stay compatible with Elixir `1.14`.

- macOS smoke (bounded):
  - Node.js: `20`
  - Haxe: `4.3.7`
  - Elixir: `1.18.3`
  - Erlang/OTP: `27.2`
  - Runs a bounded subset (`npm run test:quick` + `npm run test:mix-fast`)

Additionally, the **QA Sentinel Smoke** workflow boots the todo-app on Ubuntu (Postgres + Phoenix) and runs a small Playwright suite.

Phoenix coverage:

- `examples/todo-app` pins Phoenix `~> 1.7.0` and is exercised via the QA sentinel workflow (boot + Playwright smoke).

## Haxe 5 preview strategy

Haxe `5.x` is treated as a preview toolchain for this repository. The CI source of truth remains Haxe `4.3.7`; Haxe 5 is available through a local smoke command:

```bash
npm run test:haxe5
```

That smoke switches Lix to `HAXE5_VERSION` (default: `nightly`), restores the previous `.haxerc` afterward, then runs:

- snapshot compilation with `COMPARE_INTENDED=0`
- generated Elixir syntax validation
- `npm run test:mix-fast`

Snapshot intended-output diffs are intentionally disabled for Haxe 5. Haxe 5 can produce different typed AST / `TypedExpr` shapes for equivalent source programs, and those differences can cascade into harmless generated-output ordering or helper-shape drift. Until Haxe 5 becomes part of the supported CI matrix, this repo should not maintain a separate Haxe 5 `intended/` baseline or normalize Haxe 5-only diffs in the compiler pipeline.

The policy is:

- Haxe `4.3.7` snapshots are the golden generated-output contract.
- Haxe 5 preview validation proves the compiler still accepts the suite and emits parseable Elixir.
- If a Haxe 5 run exposes a semantic bug, fix the shared compiler behavior and cover it with the normal Haxe `4.3.7` snapshot/runtime suites when possible.
- Revisit separate Haxe 5 baselines only when Haxe 5 is stable enough to become a CI-supported toolchain.

## Minimum versions (documented)

These are the minimum versions we **document**:

- Haxe `4.3.7+`
- Node `16+` (Node `20` recommended)
- Elixir `1.14+`

If you need support for a specific older version, open an issue and include your constraints.

## What is *not* tested (yet)

- Phoenix `1.6.x` and earlier
- Haxe `5.x` in CI (local preview smoke only; see the Haxe 5 preview strategy above)

If you run successfully on other versions, please report it so we can expand the matrix.
