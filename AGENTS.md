# Agent personality

I need you to explain concepts explained in more detail, reflect before each action and explain to me your thought process (what you did, why you did and how).

# Agent Guide: Layered API, Bootstrap Strategies, and Date Handling

This repo uses a layered API approach, explicit bootstrapping strategies, and some careful stdlib glue to generate idiomatic Elixir while keeping strong typing on the Haxe side. This guide is for contributors and tools (agents) to understand the intended patterns.

## Layered API Policy

- Low-level externs mirror Elixir types directly under `std/elixir/` (e.g., `elixir.Date`, `elixir.DateTime`, `elixir.NaiveDateTime`). These provide a 1:1 mapping to native modules and functions for developers who want direct Elixir semantics.
- High-level Haxe stdlib wrappers (e.g., `std/Date.hx`) expose cross‑platform APIs and internally target the externs on Elixir.
- Conversion helpers (e.g., `std/DateConverter.hx`) bridge Haxe types and Elixir extern types in both directions.
- Users can choose:
  - Haxe stdlib for portability and familiarity.
  - Elixir externs for idiomatic, fully-typed Elixir code.

## Date.hx Design Notes

- `Date.now()` returns a proper Haxe `Date` wrapper whose private field `datetime` points to an Elixir `DateTime` value.
- Why: returning a bare `DateTime` causes broken expansions (e.g., `Date.now().getTime()` emitting stray `this` references). The wrapper keeps instance methods like `getTime()` correct and idiomatic.
- `@:privateAccess` is used intentionally when initializing `datetime`:
  - We avoid exposing public mutators while constructing a correct wrapper around the Elixir value (or stashing macro-time values).
  - This keeps the type encapsulated without widening visibility.

## Bootstrap Strategies

We support two entrypoint modes and multiple bootstrap strategies:

- Entrypoint modes

  - Main: a class has static `main()`; treated as a standalone script.
  - OTP: a class annotated `@:application`; bootstrapping is skipped in favor of OTP `start/2`.
  - None: normal library/module; no bootstrap.

- Strategies (select with `-D bootstrap_strategy=...`)

  - `external` (default): generate `<module>.exs` script(s) that require transitive deps (topological order), require `<module>.ex`, then call `<Module>.main()`.
  - `inline_deterministic`: inject deterministic requires + `<Module>.main()` into `<module>.ex` after compilation using the full dependency graph.
  - `inline` (legacy/simple): inject requires + main inline during module build (not deterministic across modules).

- Optional override: `-D entrypoint=main|none|otp` for classes with static `main()`.

See `docs/06-guides/BOOTSTRAP_AND_ENTRYPOINTS.md` for details and examples.

## Dependency Tracking and Ordering

- Dependencies are recorded during AST building when `ERemoteCall` nodes are generated; built-in Elixir modules are excluded.
- Tracking keys are the final module names (after `@:native` renaming) to align with output paths.
- Require ordering uses transitive closure + global topological order for determinism. Inline deterministic and external strategies both leverage this.

## Tests and Validation

- Snapshot tests cover both bootstrap strategies:
  - External runner: `test/snapshot/bootstrap_external/basic` (emits `main.exs`).
  - Inline deterministic: `test/snapshot/bootstrap_inline/basic` (injects requires + `main()` inline).
- Date coverage exists (static/instance methods), but contributors should add tests for:
  - `Date.now().getTime()` inside map literals (single-line expansion, no stray `this`).
  - `DateConverter` round-trips between Haxe `Date` and `elixir.Date*` externs.
  - Month/day offsets and day-of-week mapping.
  - Unix time units (`:millisecond` vs `:second`) correctness.
- Validator (`test/validate_elixir.sh`) uses parse-only checks (Code.string_to_quoted) per test folder to avoid executing top-level code.

## Running and DX Tips

- Run tests: `make -C test -j4 all`
- Update intended outputs: `make -C test -j8 update-intended`
- Validate Elixir syntax: `make -C test validate-elixir`
- Prefer `.exs` runners when present: `make -C test run TEST=path/to/test`
- For examples/todo-app:
  - Phoenix OTP modules (`@:application`) do not emit bootstrap; start with `mix phx.server` or releases.
  - If you add a `Main.main/0`, external strategy will emit a `main.exs` runner.

## Contribution Notes

- Keep Elixir externs minimal and typed; prefer exposing precise signatures and atoms.
- High-level Haxe wrappers should use inline injections for small idiomatic snippets, but avoid multi-line injections that can split expressions.
- When fixing expansions, prefer adjusting the stdlib wrapper (like `Date.now()`) over adding generic “transformers”, to minimize risk and keep intent local.
- Add hxdoc comments when using `@:privateAccess` or other special metadata to document intent.
