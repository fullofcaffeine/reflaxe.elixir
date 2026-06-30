# File Generation (Haxe → Elixir Output)

This document explains how Reflaxe.Elixir decides **which files to write** and **where they go**.

## Output Directory

Your `.hxml` sets the target output directory via:

```hxml
-D elixir_output=lib
```

Reflaxe.Elixir will emit one Elixir source file per compiled module under that directory, using
package/module naming rules (snake_case paths, Phoenix conventions when applicable).

For Phoenix applications, `lib` is a normal in-place output root. The important
question is not whether generated app code lives under `lib`, but whether the
target modules and paths look like a handwritten Phoenix app. App-facing modules
should generally be `MyApp.*` / `MyAppWeb.*` under `lib/my_app/**` and
`lib/my_app_web/**`; source roots such as `src_shared` should not automatically
become `lib/shared/**`.

See the [Phoenix Output Model](../05-architecture/PHOENIX_OUTPUT_MODEL.md) for
the in-place and materialized Phoenix app modes.

## Pipeline Context

File writing happens after the AST pipeline finishes:

- `TypedExpr` → `ElixirASTBuilder` → `ElixirASTTransformer` → `ElixirASTPrinter`
- `ElixirOutputIterator` converts each module AST into a string and yields it to Reflaxe’s output manager.

See:
- `docs/05-architecture/COMPILATION_FLOW.md`
- `docs/05-architecture/FILE_NAMING_ARCHITECTURE.md`

## Special Modes

- **Ecto migration emission**: opt‑in `.exs` output via `-D ecto_migrations_exs` (see the migrations docs/examples).
- **Compile‑time‑only helpers**: structurally empty modules can be suppressed from emission to avoid generating useless `.ex` stubs.
