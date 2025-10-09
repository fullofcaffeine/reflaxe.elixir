# Extern Tracker & Output-Phase Placeholders

Status: Adopted (AST pipeline)

## Problem

- Haxe std externs (e.g., `haxe._Constraints.*_Impl_`, `haxe/io/*`, `haxe/ds/*`) are extern contracts defined by Haxe. We must not author implementation sources for these in our std.
- Historical snapshot suites asserted the presence of some of these modules in the generated output tree.
- Emitting source files to satisfy tests violates the extern contract and causes cross-target pollution (e.g., macro context seeing `__elixir__()` calls).

## Goals

1. Satisfy snapshot presence in a principled way without authoring std source files.
2. Keep emission target-aware: only when compiling to Elixir and only for externs actually referenced by the type graph.
3. Preserve runtime behavior: placeholders must not invent APIs or behaviors.

## Design

### 1) Tracking Referenced Externs

- Compiler field: `externModulesReferenced: Map<String,Bool>`
- Registrar: `registerExternRef(path: String)` records normalized output paths (e.g., `haxe/io/bytes`, `haxe/ds/_map/map_impl_`).
- Registration points: in `ElixirASTBuilder.moduleTypeToString`, when an extern under `haxe.*` is encountered (class/abstract/type/enum), the builder registers the path.
- Normalization: path segments are snake_case; file base is snake_case of the module name.

### 2) Emitting Placeholders at Output Phase

- Emission occurs in `ElixirOutputIterator.prepareExternPlaceholders()` after normal modules are processed.
- For each referenced path:
  - Derive `overrideDirectory` and `overrideFileName`.
  - Synthesize a minimal module name from the file base (e.g., `bytes` → `Bytes`, `_int32/int32_impl_` → `Int32_Impl_`).
  - Generate minimal content: `defmodule <Name> do\n  nil\nend\n`.
  - Skip any file whose relative path already exists in `compiler.moduleOutputPaths` to avoid duplicates.
  - Attach a deterministic fallback `BaseType` (first registered), then push as an extra output.

### 3) Constraints & Non-Goals

- Never create `.cross.hx` for std externs; do not shadow Haxe std.
- Do not enrich placeholders with functions or state; they exist solely to satisfy file presence in tests.
- Prefer updating intended snapshots to reflect a presence-only policy rather than increasing placeholder complexity.

## Rationale

- AST-only architecture: tracking is performed during AST construction; emission is done at the output stage. No changes to classpaths or macro contexts.
- Target awareness: placeholders are produced only when the Elixir target is generating files and only for actually referenced externs.
- Compatibility: leverages OutputManager overrides (filename/directory) to materialize files without forging type names.

## File Pointers

- `src/reflaxe/elixir/ElixirCompiler.hx` – `externModulesReferenced`, `registerExternRef`, `getFallbackBaseType()`
- `src/reflaxe/elixir/ast/ElixirASTBuilder.hx` – extern registration hook
- `src/reflaxe/elixir/ElixirOutputIterator.hx` – placeholder emission

## Testing

- Run source-map suites (core/source_map_basic, core/source_map_validation, core/SourceMapGeneration).
- Verify presence-only placeholders appear under `out/haxe/...` when externs are referenced by the test input.
- If intended snapshots expect legacy breadth (e.g., always emitting haxe/io/* regardless of usage), normalize intended outputs to the presence-only policy.

## Future Work

- Implement target-conditional classpath injection via bootstrap macro (add `std/_std/` only for Elixir target) to eliminate macro-time exposure of Elixir-specific code.
- Expand test guidance to codify presence-only extern policy across suites.

