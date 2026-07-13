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
  ↓ validate authored function result contracts (test/opt-in builds)
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

## Non-Void Function Result Contracts

Haxe knows whether each authored function returns `Void` or a value. During AST construction,
Reflaxe.Elixir retains that fact as compiler-only metadata on the generated `EDef`/`EDefp` node.
When `-D reflaxe_elixir_validate_results` is enabled, the transformer records that contract after
each pass boundary and detects valid-to-invalid result transitions.

In practical terms, this catches a dangerous class of compiler bug early: a cleanup pass may turn
an `Int` function ending in `0` into an empty target block. Elixir accepts an empty function and
returns `nil`, so syntax validation alone cannot identify the lost Haxe value. The invariant reports
the Haxe function and the pass or lean pass bundle that first exposes the invalid result shape.

The check is intentionally an AST check, not a generated-text comparison. It understands scalar
tails, blocks, `if`, `case`, `cond`, `with`, `try`, `receive`, raise/throw termination, nullable
returns, and loop result carriers. It does not inspect the contents of `ERaw`; a non-empty raw target
expression is opaque and remains the responsibility of the target-injection boundary. Some upstream
stdlib modules begin with placeholder bodies that target semantic passes replace later, and a few
established transforms temporarily remove then restore an abstract identity body. The validator
therefore reports a degradation only if it remains unresolved at the pre-print boundary; its
diagnostic still names the first pass that degraded the previously valid carrier.

Normal users do not need this define. The small `Void`/value contract metadata also supports normal
abstract identity shaping, but transition tracking adds no generated Elixir and is disabled in
ordinary source and package builds. The snapshot harness enables it by default because compiler tests
benefit from checking every phase. For exact granular pass names during compiler debugging, combine it with
`-D hxx_granular_pass_registry`; otherwise diagnostics name the lean bundle boundary.

## Anonymous Tuple-Shaped Object Contract

Haxe does not have a single built-in tuple syntax, so typed surfaces commonly
model positional values with anonymous fields. Reflaxe.Elixir recognizes two
canonical layouts:

- `_1.._N` for portable, one-based Haxe tuple shapes.
- `_0.._N-1` for zero-based Elixir extern shapes.

The complete followed anonymous type must contain one of those contiguous field
sets. A mixed shape such as `{_1, label}` or a gapped shape such as `{_1, _3}`
is a map, not a tuple.

`AnonymousTupleShape` owns this decision for the build phase. `ObjectBuilder`
emits `ETuple`, `FieldAccessBuilder` emits zero-based `elem/2` reads, and
`AssignmentBuilder` emits `put_elem/3` followed by normal local rebinding.
Haxe object-pattern lowering also reaches the typed field-access path, so its
tests and binds use the same indices. For example:

```text
Haxe {_1: "ok", _2: 4}  -> Elixir {"ok", 4}
Haxe value._1            -> Elixir elem(value, 0)
Haxe value._2 = 5        -> Elixir value = put_elem(value, 1, 5)
```

This is a typed-AST representation rule, not a printed-text repair. A field
name alone is insufficient evidence: the builder must prove the receiver's
complete anonymous shape before emitting tuple access. The executable
`regression/tuple_elem_access` fixture covers zero- and one-based reads,
updates, nesting, object-pattern matching, and map-shaped negative cases;
`regression/non_void_tail_values` covers a function-returned tuple.

## Key Code Locations

- Compiler bootstrap and preprocessor registration:
  - `src/reflaxe/elixir/CompilerInit.hx`
- Compiler entrypoint (GenericCompiler orchestration + module scheduling):
  - `src/reflaxe/elixir/ElixirCompiler.hx`
- TypedExpr → ElixirAST build:
  - `src/reflaxe/elixir/ast/ElixirASTBuilder.hx`
  - `src/reflaxe/elixir/ast/builders/AnonymousTupleShape.hx`
- Pass registry + ordered transforms:
  - `src/reflaxe/elixir/ast/transformers/registry/ElixirASTPassRegistry.hx`
  - `src/reflaxe/elixir/ast/ElixirASTTransformer.hx`
  - `src/reflaxe/elixir/ast/PassApplicability.hx` (typed module capabilities)
  - `src/reflaxe/elixir/ast/transformers/registry/PassScopeManifest.hx` (exact pass ownership)
- ElixirAST pretty‑printing:
  - `src/reflaxe/elixir/ast/ElixirASTPrinter.hx`
- Final output bridging (AST → string per file):
  - `src/reflaxe/elixir/ElixirOutputIterator.hx`

## Debugging & Introspection

- `-D debug_pass_metrics` — prints which passes changed the AST.
- `-D debug_ast_pipeline` / `-D debug_ast_transformer` — focused traces for builder/transformer.
- `-D reflaxe_elixir_validate_results` — validate authored non-`Void` result carriers after AST pass boundaries.
- `npm run test:pass-scope-parity` — prove scoped and legacy all-pass execution emit byte-identical file trees for representative modules.
- `--times` / `-D macro-times` — Haxe macro timing breakdown.

## Related Documentation

- `docs/05-architecture/AST_PIPELINE_MIGRATION.md` — rationale and migration notes.
- `docs/05-architecture/UNIFIED_AST_PIPELINE.md` — conceptual overview of the AST pipeline.
- `docs/05-architecture/TRANSFORM_PASS_REGISTRY_ORDER.md` — pass ordering and safety rules.
- `docs/05-architecture/PASS_REGISTRY_INVENTORY.md` — effective phase contracts, ownership scopes, replay families, and bounded profiling baseline.
- `docs/03-compiler-development/COMPILATION_PIPELINE_ARCHITECTURE.md` — contributor‑level detail.
