# TypedExpr Loop and Switch Pattern Analysis

## Analysis Date: January 2025
## Purpose: Document infrastructure variable patterns for elimination

## Key Findings from Debug Analysis

### 1. Switch Statement Pattern (TSwitch)

**Haxe Input:**
```haxe
var result = switch(msg.type) {
    case "test": msg.data;
    case _: "unknown";
};
```

**TypedExpr Structure:**
```
TBlock([
  TVar(_g, TField(msg, "type")),  // Infrastructure variable assignment
  TSwitch(
    TParenthesis(TLocal(_g)),      // Switch on infrastructure variable
    cases: [
      { values: [TConst("test")], expr: ... },
      { values: [TConst("ok")], expr: ... }
    ],
    default: TConst("unknown")
  )
])
```

**Current Output (with g variable):**
```elixir
result = g = msg_type
if (g == "test"), do: msg_data, else: "unknown"
```

**Desired Idiomatic Output:**
```elixir
result = case msg_type do
  "test" -> msg_data
  _ -> "unknown"
end
```

### 2. For Loop Pattern (Desugared to TWhile)

**Haxe Input:**
```haxe
for (i in 0...5) {
    trace(i);
}
```

**TypedExpr Structure (from DesugarredForDetector):**
```
TBlock([
  TVar(g, TConst(0)),         // Counter initialization
  TVar(g1, TConst(5)),        // Limit initialization  
  TWhile(
    TBinop(OpLt, TLocal(g), TLocal(g1)),  // g < g1
    TBlock([
      TVar(i, TLocal(g)),     // User variable assignment
      // ... loop body ...
      TVar(g, TBinop(OpAdd, TLocal(g), TConst(1)))  // Increment
    ])
  )
])
```

**Current Output (handled by LoopBuilder):**
```elixir
Enum.each(0..4, fn i ->
  Log.trace(i, ...)
end)
```

### 3. Array Map/Filter Pattern

**Haxe Input:**
```haxe
var evens = [for (n in numbers) if (n % 2 == 0) n];
```

**TypedExpr Structure:**
```
TBlock([
  TVar(result, TArrayDecl([])),
  TVar(_g, TConst(0)),
  TVar(_g1, TField(numbers, "length")),
  TWhile(
    TBinop(OpLt, TLocal(_g), TLocal(_g1)),
    TBlock([
      TVar(n, TArray(numbers, TLocal(_g))),
      TIf(
        TBinop(OpMod, TLocal(n), TConst(2)),
        TCall(TField(result, "push"), [TLocal(n)])
      ),
      TVar(_g, TBinop(OpAdd, TLocal(_g), TConst(1)))
    ])
  ),
  TLocal(result)
])
```

### 4. Map Iterator Pattern

**Haxe Input:**
```haxe
for (key => value in map) {
    result.push(key + ": " + value);
}
```

**TypedExpr Structure:**
```
TBlock([
  TVar(g, TCall(TField(map, "keyValueIterator"), [])),
  TWhile(
    TCall(TField(TLocal(g), "hasNext"), []),
    TBlock([
      TVar(g2, TCall(TField(TLocal(g), "next"), [])),
      TVar(key, TField(TLocal(g2), "key")),
      TVar(value, TField(TLocal(g2), "value")),
      // ... body ...
    ])
  )
])
```

## Infrastructure Variable Naming Patterns

### Pattern Recognition Rules
1. **Simple counters**: `g`, `g1`, `g2`, ...
2. **Underscore variants**: `_g`, `_g1`, `_g2`, ...
3. **Regex pattern**: `/^_?g[0-9]*$/`

### Common Usage Contexts
1. **Loop counters**: Index variables in for loops
2. **Loop limits**: End values for iteration
3. **Switch targets**: Temporary holders for switch expressions
4. **Iterator holders**: Storing iterator objects
5. **Tuple extractors**: Temporary for destructuring

## Transformation Strategy

### Phase 1: Detection (Already Implemented)
- `DesugarredForDetector` - Detects for loop patterns ✅
- `LoopBuilder` - Handles loop transformations ✅

### Phase 2: Missing Patterns (Need Implementation)

#### Switch Statement Transformation
**Location**: Need to detect in ElixirASTBuilder when building TBlock
**Pattern**: TVar(_g, init) followed by TSwitch(TLocal(_g), ...)
**Transform**: Direct case expression without temporary variable

#### Map Iterator Transformation  
**Location**: Already partially handled in LoopBuilder
**Pattern**: Iterator with hasNext/next calls
**Transform**: Enum operations or comprehensions

### Phase 3: Variable Elimination
**Approach**: When infrastructure variables are detected:
1. Skip the TVar declaration for infrastructure variables
2. Substitute the original expression directly in usage sites
3. Use metadata to track substitutions

## Implementation Priority

1. **HIGH**: Switch statements (most visible in output)
2. **MEDIUM**: Case expressions in other contexts
3. **LOW**: Iterator patterns (already mostly handled)

## Next Steps

1. Enhance ElixirASTBuilder to detect switch patterns in TBlock
2. Create substitution mechanism for infrastructure variables
3. Add metadata tracking for variable elimination
4. Test with comprehensive test suite
