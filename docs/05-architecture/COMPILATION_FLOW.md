# Reflaxe.Elixir Compilation Flow (AST Pipeline)

This document describes the current (post‑August 2025) compilation flow for Reflaxe.Elixir.

Reflaxe.Elixir is a **macro‑time compiler**: it runs during the Haxe compile, converts Haxe’s
typed AST (`TypedExpr`) into a target AST (`ElixirAST`), applies ordered transformation passes,
then prints idiomatic Elixir source.

## High‑Level Flow

```
Haxe source (.hx)
  ↓ parse + type
TypedExpr (Haxe typed AST; already desugared by Haxe)
  ↓ Context.onAfterTyping (via CompilerInit.Start())
ElixirCompiler (GenericCompiler<ElixirAST>)
  ↓ build
ElixirASTBuilder (TypedExpr → ElixirAST)
  ↓ transform
ElixirASTTransformer (ordered, shape‑based passes)
  ↓ print
ElixirASTPrinter (ElixirAST → Elixir source text)
  ↓ output
ElixirOutputIterator + Reflaxe output manager
  ↓
Generated `.ex` / `.exs` files
```

## Where “Desugaring” and “Re‑Sugaring” Happen

- **Haxe desugars** high‑level syntax during typing (e.g., `for`/`switch` conveniences into
  lower‑level shapes).
- Reflaxe.Elixir **re‑sugars** those shapes inside **transformer passes** to recover idiomatic,
  Elixir‑native patterns (e.g., `Enum.*`, pipes, comprehensions, Phoenix‑friendly shapes).
- The **printer is formatting‑only**; semantic decisions belong in builder/transformer.

## Key Code Locations

- Compiler bootstrap and preprocessor registration:
  - `src/reflaxe/elixir/CompilerInit.hx`
- Compiler entrypoint (GenericCompiler orchestration + module scheduling):
  - `src/reflaxe/elixir/ElixirCompiler.hx`
- TypedExpr → ElixirAST build:
  - `src/reflaxe/elixir/ast/ElixirASTBuilder.hx`
- Pass registry + ordered transforms:
  - `src/reflaxe/elixir/ast/transformers/registry/ElixirASTPassRegistry.hx`
  - `src/reflaxe/elixir/ast/ElixirASTTransformer.hx`
- ElixirAST pretty‑printing:
  - `src/reflaxe/elixir/ast/ElixirASTPrinter.hx`
- Final output bridging (AST → string per file):
  - `src/reflaxe/elixir/ElixirOutputIterator.hx`

## Debugging & Introspection

- `-D debug_pass_metrics` — prints which passes changed the AST.
- `-D debug_ast_pipeline` / `-D debug_ast_transformer` — focused traces for builder/transformer.
- `--times` / `-D macro-times` — Haxe macro timing breakdown.

## Related Documentation

- `docs/05-architecture/AST_PIPELINE_MIGRATION.md` — rationale and migration notes.
- `docs/05-architecture/UNIFIED_AST_PIPELINE.md` — conceptual overview of the AST pipeline.
- `docs/05-architecture/TRANSFORM_PASS_REGISTRY_ORDER.md` — pass ordering and safety rules.
- `docs/03-compiler-development/COMPILATION_PIPELINE_ARCHITECTURE.md` — contributor‑level detail.

