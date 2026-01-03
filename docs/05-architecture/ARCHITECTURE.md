# Architecture Overview (AST Pipeline)

Reflaxe.Elixir is a Haxe → Elixir compiler built on Reflaxe. As of **August 2025**, the compiler is **pure AST-based**: it builds an `ElixirAST` IR, runs deterministic transformation passes, then prints idiomatic Elixir.

This document is the canonical “how the compiler is structured today” overview. The previous pre-AST architecture writeup is kept in git history.

## Compilation Pipeline

1. **Haxe typing** produces `TypedExpr` trees.
2. **Builder** converts `TypedExpr` → `ElixirAST` (structural IR).
3. **Transformer** runs ordered passes over `ElixirAST` (normalize + rewrite + hygiene).
4. **Printer** turns `ElixirAST` → Elixir source code (formatting + surface syntax).
5. **Output** writes files (file-per-module/class, plus `_GeneratedFiles.json` build metadata).

## Key Source Locations

- `src/reflaxe/elixir/ElixirCompiler.hx`
  - Main `GenericCompiler<ElixirAST>` entrypoint (drives builder → transformer → printer → output).
- `src/reflaxe/elixir/ast/`
  - `ElixirASTBuilder.hx`: TypedExpr → ElixirAST lowering.
  - `ElixirASTTransformer.hx`: pass runner + orchestration.
  - `ElixirASTPrinter.hx`: ElixirAST → `.ex` text.
  - `ast/transformers/registry/`: pass registry + ordering (grouped, documented).

## Where to Implement Features (Rule of Thumb)

- **Builder**: when you need to *shape* raw Haxe constructs into a visible AST form (avoid `ERaw` when possible).
- **Transformer pass**: when you need to rewrite/normalize already-shaped AST (idiomatic Elixir, naming, hygiene, framework patterns).
- **Printer**: when you only need to change rendering of existing AST nodes (spacing, delimiters, surface syntax).

## Standard Library + Extern Boundary

This repo uses a layered approach:

- `std/*.cross.hx`: Haxe-facing APIs that compile to idiomatic Elixir when targeting Elixir (may use `__elixir__()` where justified).
- `std/elixir/**`: typed externs for existing Elixir/Erlang/Phoenix/Ecto modules (API-faithful; no invented functions).
- `std/_std/`: target-specific std overrides are injected **only when compiling to Elixir** (see `src/reflaxe/elixir/CompilerInit.hx`).

## Phoenix App Stubs vs Framework Implementations

Phoenix requires certain *application-namespaced* modules (e.g. `MyAppWeb.ErrorHTML`, `MyAppWeb.ErrorJSON`) that are referenced from endpoint configuration. These are Phoenix-specific as a concept, but they are **app-specific as modules** because the namespace (`MyAppWeb`) differs per project.

**Directive**
- Put the *generic implementation* in the framework layer (`std/phoenix/**`) as reusable helpers/modules.
- In apps/examples, keep only **thin stubs** under the app namespace that delegate to the shared implementation.

**Why**
- Avoid duplicating the same Phoenix boilerplate across examples/apps.
- Avoid app code using `__elixir__()` to reach Phoenix internals; that’s a smell and belongs in std/framework (if needed at all).
- Preserve portability: std/framework code stays Phoenix-specific; app code stays app-namespaced and minimal.

**Pattern**
- Framework provides: `phoenix.errors.DefaultErrorHTML` / `phoenix.errors.DefaultErrorJSON`.
- App provides (tiny stubs): `MyAppWeb.ErrorHTML` / `MyAppWeb.ErrorJSON` delegating to the framework modules.

## Migrations (Typed DSL)

Migrations are authored in Haxe via the typed DSL in `std/ecto/Migration.hx` and marked with `@:migration`.

- `src/reflaxe/elixir/macros/MigrationBuilder.hx` performs compile-time scanning/metadata injection.
- AST passes handle migration module shaping/nowarn/stubs where needed (see `src/reflaxe/elixir/ast/transformers/`).

## Further Reading

- `docs/05-architecture/AST_PIPELINE_MIGRATION.md` (migration rationale + ordering)
- `docs/03-compiler-development/COMPILATION_PIPELINE_ARCHITECTURE.md` (TypedExpr → AST details)
- `docs/05-architecture/HXML_ARCHITECTURE.md` (build configuration patterns)
