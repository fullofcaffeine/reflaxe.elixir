# Reflaxe.Elixir 1.0 Acceptance Gates

This document defines the formal acceptance criteria and CI gates for the 1.0 release. Gates focus on deterministic, idiomatic output, architectural integrity (pure AST pipeline + pretty-printer), and real‑world runtime validation with the Phoenix todo‑app.

## Acceptance Criteria

- Todo‑app server builds and runs cleanly
  - `npx haxe examples/todo-app/build-server.hxml` produces Elixir in `examples/todo-app/lib`
  - `mix compile --warnings-as-errors` completes without warnings or errors
  - HTTP GET `/` returns 200 with no warnings/errors in server logs
- Category suites are green (AST pipeline)
  - Core (essential subset for stabilization; full suite tracked separately)
  - Stdlib: Reflect/Date/StringBuf/Arrays (or documented waivers)
  - Phoenix, Ecto, OTP smoke subsets are green
  - Non‑aggregate runner modes fail correctly when failures occur
- Transformer documentation (hxdoc) coverage is complete
  - Every transformer pass under `src/reflaxe/elixir/ast/transformers` contains a hxdoc block with WHAT/WHY/HOW/EXAMPLES
- Pure Printer and AST Pipeline only
  - No use of legacy string pipeline flags in server builds/tests
  - Printer is used exclusively for final emission (no string concatenation pipelines)
- Optimization flag safety
  - No `-D analyzer-optimize` present in any Elixir server HXML (allowed for JS builds only)

## CI Gates

- `scripts/lint/hxdoc_check.sh`
  - Enforces hxdoc coverage for transformer passes
- Analyzer/Legacy guards (Elixir only)
  - Reject any HXML containing `-D analyzer-optimize` when also targeting Elixir (`-D elixir_output` or `CompilerInit.Start()` present)
  - Reject any HXML that enables `-D use_legacy_string_pipeline` for Elixir builds
- Category smoke
  - Run a small, representative subset per category using the Makefile test runner
  - Ensure non‑aggregate modes surface failures with non‑zero exit codes
- Todo‑app runtime smoke
  - Build todo‑app, boot server in the background, `curl /`, scan logs for warnings/errors, enforce warnings‑as‑errors

## Commands

- Run acceptance gates locally
  - `npm run ci:acceptance`
- Category runs (full suites)
  - `npm run test:core` / `npm run test:stdlib` / `npm run test:phoenix` / `npm run test:ecto` / `npm run test:otp`
- Hxdoc coverage gate
  - `npm run lint:hxdoc`

## Notes

- Do not add `-D analyzer-optimize` to any Elixir target HXML. It destroys functional patterns and harms readability.
- AST pipeline is the default and only supported compilation path; avoid any reintroduction of string concatenation generation.
- Fail fast: CI must exit non‑zero on any acceptance gate failure.

