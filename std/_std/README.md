# `std/_std` (Elixir-Only Staged Stdlib Shims)

This folder is part of the Reflaxe.Elixir standard-library strategy.

If you are new to the project, the short version is:

- `std/_std` contains **Elixir-only stdlib shims/overrides**.
- These files are added to the classpath **only for Elixir builds**.
- They are kept separate so they do not leak into macro/eval or other targets.

## Why this folder exists

Haxe projects in this ecosystem often use a target-specific `_std` folder for stdlib overrides.
In Reflaxe.Elixir, we use `std/_std` for modules that must behave as Elixir-target surfaces and should not be universally visible.

This helps us:

- keep Elixir output idiomatic and warning-clean,
- avoid breaking non-Elixir/macro contexts,
- keep target-specific behavior clearly isolated.

## What goes here

Put files here when they are:

- Elixir-target-only stdlib shims/bridges, and
- not appropriate as general cross-target overrides.

Current examples in this folder are `haxe.ds` map surfaces:

- `std/_std/haxe/ds/Map.hx`
- `std/_std/haxe/ds/IntMap.hx`
- `std/_std/haxe/ds/StringMap.hx`
- `std/_std/haxe/ds/ObjectMap.hx`

## How it is loaded

`std/_std` is injected by bootstrap macros for Elixir builds (see `CompilerBootstrap` docs/code), not as an always-on classpath.

That means:

- Elixir target: sees these modules.
- Macro/eval and other targets: do not see these modules unless explicitly staged there.

## `.cross.hx` vs `std/_std`

Use `.cross.hx` when:

- you are overriding an existing std module in a cross-target style.

Use `std/_std` when:

- the module is an Elixir-only shim/bridge and should be classpath-gated to Elixir builds.

## Important editing rule

These files are source-of-truth. Do not patch generated `.ex` output to change behavior.
Fix behavior in Haxe sources (`std/_std`, `std/*.cross.hx`, or AST pipeline) and regenerate/update tests.

## See also

- `docs/05-architecture/TARGET_CONDITIONAL_STDLIB_GATING.md`
- `docs/03-compiler-development/CROSS_FILES_STAGING_MECHANISM.md`
- `docs/04-api-reference/STANDARD_LIBRARY_HANDLING.md`
