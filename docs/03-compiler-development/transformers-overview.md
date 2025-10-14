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

### Filter Predicate Normalization and Query Handling
- `FilterPredicateNormalizeTransforms`: enforces `EFn` predicate for all `Enum.filter/2` call shapes (remote/method/RHS match). Avoids ERaw in predicate content and wraps captures/vars as `fn elem -> f.(elem) end`.
- `FilterQueryConsolidateTransforms`: single, shape‑based pass that guarantees `query` availability in `Enum.filter` predicates:
  - Prefer promotion of `_ = String.downcase(search_query)` → `query = String.downcase(search_query)` when adjacent
  - Otherwise insert `query = String.downcase(search_query)` from the nearest prior downcase
  - Otherwise inline `String.downcase(search_query)` into the predicate body when `search_query` is in scope

These two passes replace multiple late “UltraFinal” guards and make filter predicate handling deterministic. Place them before late hygiene and after early Enum/loop normalizations.

### Enum.each Hygiene and Binder Integrity
- `MapAndCollectionTransforms.enumEachHeadExtractionPass`: replaces `list[0]` head extraction aliases with the closure binder and drops stray numeric sentinels in bodies.
- `MapAndCollectionTransforms.enumEachBinderIntegrityPass`: promotes wildcard binders to named binders when the element is referenced (including ERaw-aware token checks) and normalizes body references.
- `MapAndCollectionTransforms.enumEachSentinelCleanupPass`: late sweep removing bare `1/0/0.0` statements in `Enum.each` anonymous functions.

Place these after loop normalization and before late hygiene passes to avoid reintroduction of unused binders or literals.

### Printer De‑Semanticization (Policy)
The printer (`ElixirASTPrinter`) is now strictly a pretty‑printer. It no longer injects runtime semantics such as `alias ... Repo`, `alias Phoenix.SafePubSub`, `require Ecto.Query`, or `@compile` attributes. All such semantics are handled by dedicated transforms. This preserves the single‑responsibility of the printer and keeps semantics testable in passes.

### Debugging Aids
- `-D debug_pass_metrics`: emits concise per‑pass mutation markers during transformation (`#[PassMetrics] Changed by: <pass>`).
- `-D debug_ast_snapshots`: writes focused snapshots for selected nodes (e.g., `filter_todos/3` then‑branch) under `tmp/ast_flow/`, enabling verification of AbsoluteFinal shapes.

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
 - See AGENTS.md for the “NEVER EDIT GENERATED FILES” policy and `npm run clean:generated` workflow.
