# File Generation (Haxe → Elixir Output)

This document explains how Reflaxe.Elixir decides **which files to write** and **where they go**.

## Output Directory

Your `.hxml` sets the target output directory via:

```hxml
-D elixir_output=lib
```

Reflaxe.Elixir will emit one Elixir source file per compiled module under that directory, using
package/module naming rules (snake_case paths, Phoenix conventions when applicable).

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
