# Compiler Feature Flags (User-Facing)

Reflaxe.Elixir has a single semantics-preserving compilation pipeline (TypedExpr -> ElixirAST -> passes -> printer).
Some parts of the pipeline have **user-facing feature flags** that allow you to enable/disable specific
codegen strategies.

These flags are primarily for:

- gradual rollout of new codegen shapes
- debugging and bisecting regressions
- opting into newer/experimental idioms when desired

They are **not** intended as "performance optimizations". In particular, do **not** use Haxe's
`-D analyzer-optimize` for the Elixir target (it can destroy functional/idiomatic shapes). See
`docs/01-getting-started/compiler-flags-guide.md`.

## How to Set a Feature Flag

Feature flags are set via Haxe defines in your `.hxml`:

```hxml
-D elixir.feature.loop_builder_enabled=false
-D elixir.feature.pattern_extraction=true
```

If a flag is omitted, the compiler uses its default.

## Supported Flags

These are the user-facing flags wired by the compiler (see `src/reflaxe/elixir/ElixirCompiler.hx`).

| Define | Default | What it changes |
| --- | --- | --- |
| `-D elixir.feature.loop_builder_enabled=<bool>` | `true` | Enables the LoopBuilder lowering for loop constructs (more robust idiomatic loop emission with safety guards). |
| `-D elixir.feature.pattern_extraction=<bool>` | `false` | Enables newer pattern-variable extraction strategies (helps match/case ergonomics and reduces temporary bindings where safe). |
| `-D elixir.feature.new_module_builder=<bool>` | `false` | Routes more compilation through newer module-building infrastructure (primarily for compiler development and migration). |
| `-D elixir.feature.experimental=<bool>` | `false` | Enables all the above experimental flags at once. Use for testing only; prefer enabling flags individually when bisecting. |

### Retired no-op define

`-D elixir.feature.idiomatic_comprehensions` was documented experimentally but
never selected a code-generation path. It has been retired. Remove it from
project HXML files: proven fresh-array projections now emit `Enum.map`
automatically, while loops that need accumulator, control-flow, iterator, or
receiver state keep their semantic reducer lowering. There is no separate
"idiomatic" backend to enable.

## When to Use Flags

- If you hit a codegen regression, re-run with the relevant flag toggled to narrow scope.
- If you want "more Elixir-like" output for a specific project, enable flags intentionally and keep them
  pinned in version control so builds remain reproducible.

## What Feature Flags Are Not

- They are not a second "mode" of compilation (there is no separate "portable/unidiomatic backend").
- They are not application authoring profiles. Use the `portable` vs `Elixir-first` guidance for that decision.
- They are not a substitute for writing BEAM-idiomatic Haxe when the semantics gap is real.
  See `docs/02-user-guide/IMPERATIVE_TO_FUNCTIONAL_LOWERING.md`.

## Related Docs

- Codegen mental model: `docs/02-user-guide/IMPERATIVE_TO_FUNCTIONAL_LOWERING.md`
- Authoring profiles (portable vs Elixir-first): `docs/02-user-guide/AUTHORING_STYLES_PORTABLE_VS_ELIXIR_FIRST.md`
- "Portable stdlib" vs "BEAM-first externs": `docs/04-api-reference/STANDARD_LIBRARY_HANDLING.md`
- Calling Elixir from Haxe (typed externs): `docs/02-user-guide/ESCAPE_HATCHES.md`
- Opt-in "Gleam-like discipline": `docs/06-guides/STRICT_MODE.md`
