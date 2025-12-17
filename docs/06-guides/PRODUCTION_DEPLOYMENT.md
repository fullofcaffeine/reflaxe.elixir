# Production Deployment Guide

This guide covers deploying a Phoenix application that uses Reflaxe.Elixir.

## High-Level Model

- **Haxe is build-time tooling**: your runtime is normal Elixir/Phoenix code on BEAM.
- In production you typically:
  1. Install Node + Haxe + lix in the build environment
  2. Compile Haxe → Elixir (generating `.ex` files into your app)
  3. Build assets (Phoenix)
  4. Build a release (`mix release`)
  5. Deploy the release (no Haxe required at runtime)

## Compiler Flags (Production)

In your server `build.hxml`:

- ✅ Recommended:
  - `-dce full`
  - `-D no-traces` / `-D no_traces`
  - `-D reflaxe_runtime`
  - `-D elixir_output=...` (choose a stable output directory inside `lib/`)
- ❌ Do not use:
  - `-D analyzer-optimize` (it breaks functional/idiomatic Elixir shapes)

See: `docs/01-getting-started/compiler-flags-guide.md`.

## Mix Integration (Production Builds)

If you use the Mix compiler task (`mix compile.haxe` / `mix compile` with `compilers: [:haxe] ++ ...`):

- In CI, consider disabling the Haxe `--wait` server to avoid port conflicts:

```bash
HAXE_NO_SERVER=1 mix compile
```

- If you need to skip Haxe compilation for a specific step (e.g., when reusing already-generated output):

```bash
HAXE_NO_COMPILE=1 mix compile
```

## Suggested CI Steps (generic)

```bash
# Toolchain
npm ci
npx lix download

# Elixir deps
mix deps.get

# Compile (includes Haxe if configured in mix.exs)
MIX_ENV=prod HAXE_NO_SERVER=1 mix compile

# Build assets (Phoenix)
MIX_ENV=prod mix assets.deploy

# Release
MIX_ENV=prod mix release
```

## Docker (multi-stage)

Recommended approach:

1. **builder stage**: Node + Haxe + Elixir/OTP, runs `npx lix download`, `mix compile`, `mix assets.deploy`, `mix release`.
2. **runtime stage**: copy `_build/prod/rel/<app>` and run the release.

This keeps production images small and avoids shipping Haxe tooling.

## Verification

- Run your app’s test suite in CI (`mix test`).
- If your repo includes an end-to-end sentinel (like `examples/todo-app`), run it as a bounded smoke test in CI.

## Troubleshooting

- If you see non-deterministic output or broken idioms, confirm you did not enable `-D analyzer-optimize`.
- If CI intermittently fails with a “port in use” message during Haxe compilation, use `HAXE_NO_SERVER=1` to compile directly.
