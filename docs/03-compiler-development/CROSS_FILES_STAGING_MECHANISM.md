# Cross Files: `.cross.hx` Resolution + Target-Gated Stdlib Paths

This document is the **mechanical** (compiler-contributor) companion to the beginner guide
in `docs/01-getting-started/cross-hx.md`.

It answers two questions:

1) How does Haxe resolve modules from `*.cross.hx` files?
2) How does Reflaxe.Elixir ensure Elixir-only overrides/shims don’t leak into macros or other targets?

## 1) How `.cross.hx` participates in module resolution

Haxe supports **platform-specific file suffixes** for module resolution.

When compiling for a platform named `X`, the compiler can resolve a module `Foo` from:

- `Foo.X.hx` (platform-specific implementation)
- `Foo.hx` (fallback implementation)

Reflaxe targets on **Haxe 4** compile in the `cross` platform mode:

- `target.name = cross`
- the `cross` define is set

That means:

- `Std` can be provided by `Std.cross.hx`
- `haxe.Log` can be provided by `haxe/Log.cross.hx`
- `String` can be provided by `String.cross.hx`

This repo places these files under `std/` so they can shadow upstream Haxe stdlib modules by
**classpath precedence** when (and only when) the Elixir target is active.

### How to verify which file was selected

Run a compile with verbose output and inspect `Parsed ...` lines:

```bash
npx haxe -v --no-output <your.hxml>
```

In an Elixir build, you should see things like:

- `Parsed .../std/Std.cross.hx`
- `Parsed .../std/StringTools.cross.hx` (and other `.cross.hx` overrides that apply)
- `Parsed .../src/haxe/Exception.cross.hx` (early-resolved override needed before bootstrap can inject `std/`)

Note: some upstream Haxe stdlib modules may still appear as `Parsed .../std/<module>.hx` before
bootstrap runs. If a module must be overridden *that* early for correctness, it should live on the
library `src/` classpath (consumer installs always have `src/` immediately).

Macro typing uses a different platform (eval), so it will *not* select `.cross.hx` files.

## 2) What `std/_std` is for (and why it exists)

Not every target-only helper is a good fit for `.cross.hx` overrides.

We keep a small set of **Elixir-only** `.hx` modules under `std/_std/` for cases like:

- runtime shims that must exist as real Elixir modules (e.g. wrapper exceptions)
- “short name” bridge modules via `@:native(...)` (e.g. `Changeset` delegating to `Ecto.Changeset`)
- target-only helpers that must never be visible in macro-only or non-Elixir builds

These are injected onto the classpath only for Elixir builds, so they can contain `__elixir__()`
without breaking macro evaluation or JS/genes builds.

## 3) Target-conditional classpath injection (the real “staging”)

This repo’s “staging” mechanism is **classpath gating**, not file copying:

- In consumer projects, `extraParams.hxml` (loaded via `-lib reflaxe.elixir`) invokes:
  - `reflaxe.elixir.CompilerBootstrap.Start()`
  - `reflaxe.elixir.CompilerInit.Start()`
- Those macros detect an Elixir build (Haxe 4: `-D elixir_output=...`; Haxe 5: custom target)
  and then add:
  - `std/` (externs + `.cross.hx` overrides)
  - `std/_std/` (Elixir-only shims)

### Why `elixir_output` shows up inside some `.cross.hx` files

Most target-specific code is hidden from other contexts by classpath gating (macros only add `std/` and
`std/_std/` for Elixir builds). However, a small set of overrides must live on the library `src/` classpath
so consumer installs resolve them *before* bootstrap macros run (example: `src/haxe/Exception.cross.hx`).

Because `src/` is visible in more situations (tools, JS/genes builds, etc.), those early overrides often use:

- `#if elixir_output ... #else extern ... #end`

This ensures they only emit Elixir-specific implementations (including `__elixir__()` injections) when the
Elixir backend is actually active, while remaining harmless type surfaces elsewhere.

Implementation:

- `src/reflaxe/elixir/CompilerBootstrap.hx`
- `src/reflaxe/elixir/CompilerInit.hx`

More context: `docs/05-architecture/TARGET_CONDITIONAL_STDLIB_GATING.md`.

## 4) Practical guidance (when adding/adjusting stdlib)

- Prefer `std/**/*.cross.hx` when you are replacing a well-known Haxe API with an idiomatic Elixir mapping.
- Use `std/_std/**/*.hx` sparingly for Elixir-only bridge modules and shims that must not leak into other contexts.
- Do not add repo-level classpaths like `../../std` to JS/genes builds; use `-lib` and library-provided hxml instead.
