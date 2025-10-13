# Elixir AST Transformer Overview (Human + Agent Guide)

This document explains why Reflaxe.Elixir ships many small, ordered AST transforms, what each group does, and how to extend them safely. It is intended for humans and agents working on the compiler.

## Why Many Passes?

Haxe is imperative/OOP; idiomatic Elixir is functional/pattern‑matching. Converting shapes cleanly requires progressive, single‑purpose rewrites rather than a monolith:

- Imperative → functional: loops/mutation → `Enum.reduce/each`, `map/filter`, `case`.
- OOP → modules/structs: `this`/fields → module functions and `%Struct{}` updates.
- Accumulators/aliasing: compiler and earlier lowerings can leave readable but non‑canonical aliasing that must be unified to the accumulator/binder parameters.
- Phoenix/Ecto idioms: output must look hand‑written and API‑faithful, never framework fakes.

Small, shape‑based passes are easier to reason about, test, and order. Late “Absolute/UltraFinal” passes harmonize residual shapes without app heuristics.

## Design Principles

- Shape‑based, name‑agnostic: Never key on app names. Match AST structure and well‑known APIs only.
- Idiomatic first: Prefer clean `Enum.*`, `case`, pipe‑friendly shapes.
- Hygiene = no warnings: Remove temps/sentinels/unused binders at the end.
- ERaw containment: Only touch ERaw when code is truly injected as string and we can match a safe structure (e.g., `Enum.reduce` bodies).

## Key Groups (selected)

### Reduce/Comprehension Canonicalization
- `ReduceAccAliasUnifyTransforms`: unify accumulator alias self‑append and binder aliasing to reducer params.
- `EFnAliasConcatToAccTransforms`: structural fix for self‑append in any two‑arg anonymous function.
- `ReduceAppendCanonicalizeTransforms`: canonicalize append inside reducer bodies; fallback rebuild to `acc = Enum.concat(acc, list)`.
- `AccAliasLateRewriteTransforms` (UltraFinal): last‑resort alias self‑append → `acc` in two‑arg EFns.
- `ReduceStrictSelfAppendRewriteTransforms` (UltraFinal): rebuild reduce body structurally (and ERaw/printed‑string fallback) when alias self‑append persists.
- `ReduceERawAliasCanonicalizeTransforms` (UltraFinal): canonicalize alias/binder inside ERaw reduce blocks.

### Hygiene & Warnings‑as‑Errors (WAE)
- `FunctionHygieneTransforms`:
  - `blockAssignChainSimplifyPass`: collapse nested `outer = inner = expr` (both EBinary/EMatch).
  - `functionTopLevelSentinelCleanupPass`: drop bare `1/0/0.0` at top level in def bodies.
  - `fnParamUnusedUnderscorePass`: underscore unused function params (scoped, not global by default).
- `AssignChainGenericSimplifyTransforms` (Final): generic chain collapse; also `outer = inner; inner = expr`.
- `LocalAssignUnderscoreLateTransforms` (UltraFinal): underscore throwaway locals; collapse nested inner assign when safe.
- `DropTempNilAssignTransforms` (UltraFinal): drop `thisN/_thisN = nil` sentinels in EBlock/EDo/EFn.
- `TrailingTempReturnSimplifyTransforms` (UltraFinal): replace trailing `var` with the RHS of its last assignment.
- `CaseBinderRebindUnderscoreTransforms` (UltraFinal): underscore case binders immediately rebound before first use.
- Enum/EFn numeric sentinel cleaners: multiple runs ensure stray `1/0/0.0` disappear after late rewrites.

### Ecto/Phoenix Idioms
- `ChangesetEnsureReturnTransforms` (UltraFinal): ensure functions that build/modify changesets return the last assigned changeset variable.
- Presence/LiveView passes (documented in PHOENIX_* docs) keep output idiomatic without name heuristics.

## Pass Ordering

Ordering matters. High‑level rules:
1. Structural canonicalization first (builders + early transforms).
2. Reducer canonicalization (acc/binder) after loop lowers.
3. Framework idioms (Phoenix/Ecto) after shapes stabilize.
4. Hygiene/cleanup runs in Final/Absolute/UltraFinal waves to remove artifacts.

New pass? Place it as late as possible to minimize interactions; prove with snapshots.

## Extending Safely

Use this checklist for new/modified passes:
- WHAT/WHY/HOW/EXAMPLES hxdoc block in the source
- Shape‑based only (no app names)
- Tests/snapshots linked in hxdoc
- Keep file < 2000 LOC; extract helpers if growing

## References

- See docs/05-architecture/AST_PIPELINE_MIGRATION.md for AST pipeline details.
- See docs/06-guides/troubleshooting.md for common issues.
