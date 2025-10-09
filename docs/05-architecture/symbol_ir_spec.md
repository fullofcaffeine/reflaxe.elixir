# Symbol IR and Hygiene Architecture (1.0)

## Goals

- Eliminate name drift between pattern binders and body references.
- Provide deterministic, conflict-free final naming with reserved-word handling and unused detection.
- Preserve idiomatic, readable Elixir while keeping transforms modular and testable.

## Scope and Strategy

- Introduce a symbol-aware IR overlay for naming and hygiene. Two integration options:
  - A) Standalone Symbol IR lowered to ElixirAST late.
  - B) Symbol IDs attached to ElixirAST with a late name-application pass.
- Start with option B (lower risk). Option A remains a future refactor path.

## Core Types

```
Symbol { id: Int, suggestedName: String, scope: ScopeId, used: Bool, origin: Origin }
Scope  { id: Int, parent: Null<ScopeId>, kind: Module|Function|Case|Fn|Block }

IR (overlay for naming):
- IRModule(name, defs)
- IRDef(name, params: Array<Symbol>, body)
- IRCase(expr, clauses: Array<IRClause>)
- IRClause(pattern: IRPattern, guard: IRExpr?, body: IRExpr)
- IRMatch(pattern: IRPattern, expr: IRExpr)
- IRVar(symbol: Symbol)
- IRCall(target?, name, args)
- IRRemoteCall(module, name, args)
- IRBinary(op, left, right)
- IRUnary(op, expr)
- IRBlock(exprs)
- IRCond(clauses: Array<{condition: IRExpr, body: IRExpr}>)
```

IRPattern mirrors Elixir patterns but binds Symbols instead of raw strings:

```
IRPattern =
  PVar(symbol: Symbol)
| PLiteral(value)
| PTuple(elements: Array<IRPattern>)
| PList(elements)
| PCons(head, tail)
| PMap(pairs: Array<{key: IRExpr, value: IRPattern}>)
| PStruct(module: String, fields: Array<{key: String, value: IRPattern}>)
| PPin(inner: IRPattern)
| PWildcard
| PAlias(symbol: Symbol, inner: IRPattern)
```

## Def-Use and Scoping Rules

- Pattern constructs (case/receive/with/fn args) define Symbols in the current scope.
- Let-binding (match) defines or rebinds a Symbol in the current scope.
- Body references must point to the same Symbol (unique id), not string names.
- Nested scopes: functions, anonymous fns, case clauses, and blocks.
- Shadowing: allowed; symbols in inner scopes receive distinct IDs. Hygiene resolves names.

## Hygiene Pass (Final Naming)

Input: IR overlay with Symbols and scopes.
Output: Map<Symbol, FinalName> with deterministic, readable names.

Algorithm (high-level):
1) Collect candidates per scope: user-suggestedName (from source), or synthesized snake_case.
2) Mark usage (def-use) per Symbol. Unused become underscored ("_name").
3) Reserved-word handling: if final candidate is reserved in Elixir (e.g., "do", "end"), append trailing underscore.
4) Conflict resolution per scope: stable tiebreak (insertion order, then numeric suffixes _1, _2...).
5) Shadowing: ensure distinct final names across nested scopes where both are used; reuse base with suffix when needed.
6) Output Symbol→FinalName map.

Policy details:
- Preserve user names where safe; prefer binder names for readability.
- Generated temps use clear prefixes (e.g., tmp_, acc_, iter_) rather than single letters.
- Unused: prefix with underscore only at the very end; never during earlier transforms.

## Integration Plan (Option B: Overlay on ElixirAST)

1) Builder: Walk ElixirAST, create Symbols for all binders and locals; attach Symbol IDs in metadata.
2) Hygiene: Run after pattern/binder transforms and before underscore cleanup; compute final names.
3) Apply Names: Late pass replaces EVar string names using the Symbol→FinalName map; pattern binders updated consistently.
4) Remove string-based renaming/suffix-stripping where replaced by symbol-aware logic (guard grouping, binder normalization).
5) Flag-gated rollout: `-D enable_symbol_ir` initially; default ON after stabilization.

## Mapping Examples

### TypedExpr → ElixirAST → Symbol Overlay

Haxe:
```
switch (color) {
  case RGB(r, g, b) if (r > 200): "high red";
  case RGB(r, g, b): "normal";
}
```

ElixirAST (simplified):
```
case color do
  {:rgb, r, g, b} ->
    cond do
      r > 200 -> "high red"
      true -> "normal"
    end
end
```

Symbol overlay:
- PVar(r#1), PVar(g#2), PVar(b#3) in the pattern.
- Body refs IRVar(r#1), IRVar(g#2), IRVar(b#3).
- Hygiene produces: r, g, b → unchanged; conflicts resolved if needed.

### IR → Final Names → Applied

- Map: { #1→"r", #2→"g", #3→"b" }
- ApplyNames rewrites all EVar occurrences and pattern binders consistently.
- No r2/g3 artifacts; cond bodies remain aligned with merged binders.

## Reserved Words and Atoms

- Reserved identifiers (e.g., when, do, end, fn, true, false, nil): add trailing underscore.
- Atoms are separate; only identifier names (variables) get hygiene treatment.

## Migration

- Phase 0 (flag off): Spec + unit tests; no code path changes.
- Phase 1 (flag on): Build overlay + compute names + apply late names; run snapshots; reconcile idiomatic-only.
- Phase 2: Remove string-based binder/suffix hacks replaced by symbols.
- Phase 3: Default ON; clean redundant passes.

## Testing (TDD)

- Unit tests for symbol creation, scoping, hygiene final names, conflicts, shadowing, reserved words.
- Snapshot gates: core/stdlib/regression and guard-grouping tests.
- E2E: todo-app zero warnings build; runtime smoke.

## Flags

- `-D enable_symbol_ir` to enable overlay, hygiene, and ApplyNames pass.
- `-D hygiene_trace` for debugging (development only).

## Notes

- This architecture complements the existing AST pipeline; it does not replace it.
- Option A (full IR lowering) remains possible after 1.0 for further simplification.

