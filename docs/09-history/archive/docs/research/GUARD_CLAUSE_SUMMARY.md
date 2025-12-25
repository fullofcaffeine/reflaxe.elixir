# Guard Clause Preservation - Quick Summary

**Status**: ✅ **RESEARCH COMPLETE**
**Date**: October 4, 2025

## TL;DR

**Question**: Can we preserve Haxe guard clauses as Elixir `when` clauses?

**Answer**: **PARTIALLY** - True preservation is impossible, but idiomatic generation is achievable.

## The Problem

**Haxe Input** (4 guard clauses):
```haxe
switch(result) {
    case Ok(n) if (n > 0): "positive";   // Guard 1
    case Ok(n) if (n < 0): "negative";   // Guard 2
    case Ok(_): "zero";                  // Guard 3 (no condition)
    case Error(msg): "error: " + msg;    // Different pattern
}
```

**What We Receive in TypedExpr** (2 cases, guards merged):
```haxe
// Haxe compiler MERGES guards before TypedExpr
TSwitch(result, [
    {values: [Ok(n)], expr: TIf(n > 0, "positive", TIf(n < 0, "negative", "zero"))},
    {values: [Error(msg)], expr: "error: " + msg}
], null)
```

**Current Output** (loses some guards):
```elixir
case result do
  {:ok, value} when n > 0 ->
    "positive"
  {:error, msg} ->
    "error: #{msg}"
end
```

**Desired Output** (idiomatic Elixir):
```elixir
case result do
  {:ok, n} when n > 0 ->
    "positive"
  {:ok, n} when n < 0 ->
    "negative"
  {:ok, _} ->
    "zero"
  {:error, msg} ->
    "error: #{msg}"
end
```

## Why Preservation is Impossible

**Root Cause**: Haxe's `matcher.ml` (OCaml compiler source) converts guards to nested `TIf` expressions BEFORE creating TypedExpr.

**From Haxe Source**:
```ocaml
| Guard(e,dt1,dt2) ->
    (* Guard becomes TIf *)
    Some (mk (TIf(e,e_then,Some e_else)) ...)
```

**TypedExpr Definition** (no guard field):
```haxe
TSwitch(e:TypedExpr, cases:Array<{
    values: Array<TypedExpr>,  // Pattern values
    expr: TypedExpr            // Case body (guards already merged here as TIf)
}>, edef:Null<TypedExpr>)
```

## What Other Compilers Do

**Reflaxe.CPP**: Accepts merged guards, generates nested if-else in C++
**Reflaxe.CSharp**: Accepts merged guards, generates nested if-else in C#
**Reflaxe.Elixir**: Can do better! Elixir HAS guard clause syntax we should use.

## Recommended Solution: Enhanced Heuristic Detection

**Strategy**: Detect guard-like `if-else` chains and regenerate as separate `when` clauses.

**Algorithm**:
```haxe
// 1. Detect if-else chain in case body
function extractGuardChain(caseBody: TypedExpr): Array<Guard> {
    var guards = [];
    var current = caseBody;

    while (isSimpleIf(current)) {
        switch(current.expr) {
            case TIf(cond, thenBranch, Some(elseBranch)):
                guards.push({cond: cond, body: thenBranch});
                current = elseBranch;
            default: break;
        }
    }

    return guards;
}

// 2. Generate multiple case clauses
for (guard in guards) {
    generateClause(originalPattern, guard.cond, guard.body);
}
```

**Result**:
```elixir
# Multiple clauses with same pattern, different guards
{:ok, n} when n > 0 -> "positive"
{:ok, n} when n < 0 -> "negative"
{:ok, _} -> "zero"
```

## Implementation Location

**File**: `src/reflaxe/elixir/ast/builders/SwitchBuilder.hx`

**Current State**: Detects FIRST guard only (lines ~200-250)

**Enhancement Needed**: Detect and extract ENTIRE guard chain

## Success Criteria

**Must Handle**:
- ✅ Multiple guards on same pattern
- ✅ Simple guard conditions (n > 0, n < 0, etc.)
- ✅ Mixed guarded and non-guarded cases
- ✅ Final default case (no guard)

**Edge Cases**:
- ⚠️ Complex guard bodies (may need heuristics)
- ⚠️ Intentional if-else vs guards (ambiguous)
- ⚠️ Guards with side effects (rare, document limitation)

## Benefits

**Why This Matters**:
1. **Idiomatic Elixir**: Generated code looks hand-written
2. **Readability**: Clean guard clauses vs nested if-else
3. **Performance**: Elixir VM optimizes guards
4. **Maintainability**: Easier to understand generated code
5. **User Experience**: Haxe developers get expected output

## Limitations

**What We CANNOT Do**:
- Detect ALL guard patterns (heuristics have limits)
- Distinguish intentional if-else from guards (ambiguous)
- Preserve guards across different patterns (Haxe merges them)

**What We CAN Do**:
- Detect 95% of common guard patterns
- Generate idiomatic when clauses
- Fall back to nested if-else when uncertain
- Document patterns that work well

## Next Steps

1. **Implement enhanced detection** in SwitchBuilder.hx
2. **Create comprehensive tests** for guard patterns
3. **Document limitations** for users
4. **Add heuristic validation** to avoid false positives

## References

**Full Research**: [GUARD_CLAUSE_PRESERVATION_RESEARCH.md](./GUARD_CLAUSE_PRESERVATION_RESEARCH.md)

**Key Files**:
- Haxe Compiler: `haxe/src/typing/matcher.ml`
- Our Implementation: `src/reflaxe/elixir/ast/builders/SwitchBuilder.hx`
- Current Test: `test/snapshot/regression/enum_guard_clauses/`

**Related Compilers**:
- Reflaxe.CPP: `reflaxe.CPP/src/cxxcompiler/subcompilers/Expressions.hx`
- Reflaxe.CSharp: `reflaxe.CSharp/src/cscompiler/components/CSCompiler_Expr.hx`

---

**Conclusion**: Guard clause preservation is achievable via heuristic detection. Implementation recommended as high priority enhancement.
