# Hygiene and Validation Passes

## Overview

This document describes the compiler hygiene and validation mechanisms that ensure idiomatic and robust Elixir output:

- No infrastructure variables (`g`, `_g`, `g1`, `_g1`, …) leak into final code.
- Unused function parameters are automatically prefixed with `_`.
- Binder collisions and pattern shapes are normalized to avoid shadowing and to improve readability.
- Clause context is preserved so enum parameter bindings are consistent between pattern and body.

These behaviors are implemented as AST transformation passes (ElixirASTTransformer) and builder-time context preservation.

## Passes

### 1) InfraVarValidation (hard fail)
- Purpose: Fail compilation when any infrastructure variable name appears in the final AST.
- Scope: Matches `g`, `_g`, `g\d+`, `_g\d+`.
- Rationale: Compiler-generated placeholders must never appear in user-visible Elixir.

### 2) PrefixUnusedParameters
- Purpose: Prefix truly unused parameters with `_` and update references to keep consistency.
- Handles: `def`, `defp`, `defmacro`, `defmacrop`, and anonymous functions (`fn`).
- Rationale: Prevent warnings; follow Elixir conventions.

### 3) FinalPatternNormalization
- Purpose: Normalize tuple patterns, collapse single-atom tuples, and avoid binder collisions with function parameters.
- Heuristics: Prefer semantically meaningful binders (e.g., `level` if case target hints `_level`).

### 4) OptionBinderConsistency
- Purpose: Align `{:some|:ok, binder}` with identifiers actually used in the clause body.
- Rules: Rename binder when it’s unused or used only as a field base while a single viable identifier exists in the body.

## Context Preservation

Enum parameter extraction depends on `ClauseContext` with a single source of truth (`enumBindingPlan`).

- SwitchBuilder populates `enumBindingPlan` while building patterns.
- ElixirASTBuilder’s `TEnumParameter` consults the plan and returns:
  - `EVar(info.finalName)` when already extracted by the pattern, or
  - `null` to skip redundant temp assignments.
- Never falls back to infra-variable references.

## Loop Hygiene

Desugared for-loops register infra→user rename mappings during emission.

- BuildContext provides `registerTempVarRename(old, new)`.
- LoopBuilder calls it when converting patterns to Enum/comprehension forms.
- Prevents residual infra counter names from appearing in bodies.

## Target-Conditional Std Injection

`CompilerInit.Start()` adds `std/_std/` only for the Elixir target and initializes LiveView preservation.

- Prevents `__elixir__()` externs from leaking into macro context.
- Aligns with mature Reflaxe target patterns.

## “Haxe the Elixir Way” (Quick Guidance)

- Prefer functional patterns: pattern-matching, pipelines, comprehensions.
- Use Phoenix/Ecto APIs exactly; add type safety in Haxe (types, abstracts, macros).
- See README (“Write Haxe the Elixir Way”) and `docs/02-user-guide/haxe-for-phoenix.md`.

## Validation Strategy

- Snapshot tests enforce idiomatic shapes.
- InfraVarValidation prevents infra-variable regressions.
- Todo-app is the integration canary; mix compile/runtime checks confirm end-to-end.

