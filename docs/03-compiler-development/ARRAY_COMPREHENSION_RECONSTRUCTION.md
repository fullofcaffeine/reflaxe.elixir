# Array Comprehension Reconstruction in Reflaxe.Elixir

## Overview

This document explains how the Haxe→Elixir compiler detects and reconstructs array comprehensions from Haxe's desugared imperative code, generating idiomatic Elixir `for` comprehensions.

## The Problem

Haxe desugars array comprehensions before they reach our compiler. What starts as clean, functional code:

```haxe
// Haxe source - what the developer writes
var squares = [for (i in 0...5) i * i];
var nested = [for (i in 0...3) [for (j in 0...3) i * 3 + j]];
```

Gets transformed by Haxe into imperative code:

```haxe
// What our compiler receives (simplified TypedExpr representation)
var _g = [];
for (i in 0...5) _g.push(i * i);
var squares = _g;

// Nested case becomes even more complex
var _g = [];
for (i in 0...3) {
    var _g1 = [];
    for (j in 0...3) _g1.push(i * 3 + j);
    _g.push(_g1);
}
var nested = _g;
```

### The Unrolling Problem with Constant Ranges

When Haxe sees constant ranges (like `0...2`), it completely unrolls the loops:

```haxe
// Original: [for (i in 0...2) [for (j in 0...2) j]]

// Haxe unrolls this to:
var g = [];
g = g ++ [
    g = []     // Assignment inside array literal!
    g ++ [0]   // Bare concatenation - not a valid statement!
    g ++ [1]
    g
];
g = g ++ [
    g = []
    g ++ [0]
    g ++ [1]  
    g
];
```

This creates **invalid Elixir** with:
1. Assignments inside list literals (`g = []` inside `[...]`)
2. Bare concatenation expressions (`g ++ [0]`) that aren't valid statements

## The Solution

We implement a multi-layered approach to detect and reconstruct comprehensions:

### 1. Detection at TArrayDecl Level

When processing `TArrayDecl` (array literals), we check if it contains a single element that is either:
- A `TFor` expression (direct comprehension that wasn't desugared)
- A `TBlock` containing a comprehension pattern

```haxe
case TArrayDecl(el):
    if (el.length == 1) {
        switch(el[0].expr) {
            case TFor(_):
                // Direct comprehension - return as EFor
                buildFromTypedExpr(el[0], variableUsageMap).def;
            case TBlock(stmts):
                // Try to reconstruct from desugared pattern
                var comprehension = tryBuildArrayComprehensionFromBlock(stmts, variableUsageMap);
                if (comprehension != null && comprehension.def.match(EFor(_))) {
                    comprehension.def;  // Return the reconstructed comprehension
                }
        }
    }
```

### 2. Pattern Recognition in Blocks

The `tryBuildArrayComprehensionFromBlock` function detects two main desugaring patterns:

#### Pattern 1: Loop with Push
```haxe
var _g = [];
for (i in 0...5) _g.push(i * i);
_g;
```

#### Pattern 2: Unrolled Concatenation
```haxe
var _g = [];
_g = _g ++ [value1];
_g = _g ++ [value2];
_g = _g ++ [value3];
_g;
```

### 3. Handling Bare Concatenations in Blocks

The `looksLikeListBuildingBlock` function detects blocks that build lists through concatenations:

```haxe
static function looksLikeListBuildingBlock(stmts: Array<TypedExpr>): Bool {
    // Check for: g = []; g ++ [val1]; g ++ [val2]; ...; g
    // OR: g = []; g = g ++ [val1]; g = g ++ [val2]; ...; g
    
    // First statement must initialize empty array
    // Middle statements must be concatenations (with or without assignment)
    // Last statement must return the temp variable
}
```

### 4. Recursive Handling for Nested Comprehensions

When the yield expression itself is a block, we recursively check if it's a comprehension:

```haxe
// In extractYieldExpression
if (yieldExpr.expr.match(TBlock(_))) {
    var nested = tryBuildArrayComprehensionFromBlock(stmts, variableUsageMap);
    if (nested != null) {
        return nested;  // Use the nested comprehension as the body
    }
}
```

### 5. Expression Recovery Fallback

For blocks that appear in expression positions but aren't comprehensions, we wrap them in immediately-invoked anonymous functions:

```haxe
// Create (fn -> ...block... end).()
var fnClause:EFnClause = {
    args: [],
    guard: null,
    body: blockAst
};
var wrappedBlock = makeAST(ECall(makeAST(EParen(makeAST(EFn([fnClause])))), "", []));
```

## Implementation Details

### Key Components

1. **`unwrapMetaParens()`**: Strips TMeta and TParenthesis wrappers that Haxe may add
2. **`tryBuildArrayComprehensionFromBlock()`**: Main pattern detection logic
3. **`looksLikeListBuildingBlock()`**: Detects blocks with bare concatenations
4. **`extractListElements()`**: Extracts elements from list-building blocks
5. **`extractYieldExpression()`**: Extracts the expression being collected in loops

### AST Transformation Flow

```
TypedExpr (from Haxe)
    ↓
ElixirASTBuilder (detection & reconstruction)
    ├─ tryBuildArrayComprehensionFromBlock() → EFor nodes
    ├─ looksLikeListBuildingBlock() → EList nodes
    └─ Expression recovery → Wrapped blocks
    ↓
ElixirAST with proper nodes
    ↓
ElixirASTPrinter
    ↓
Idiomatic Elixir: for i <- 0..4, do: i * i
```

### Handling Different Initialization Patterns

Haxe may generate different initialization patterns:

```haxe
// Pattern A: TVar
case TVar(v, {expr: TArrayDecl([])}):
    tempVarName = v.name;

// Pattern B: TBinop assignment
case TBinop(OpAssign, {expr: TLocal(v)}, {expr: TArrayDecl([])}):
    tempVarName = v.name;
```

Both patterns are detected and handled.

## Expected Output

With these transformations, we generate clean, idiomatic Elixir:

```elixir
# Simple comprehension
squares = for i <- 0..4, do: i * i

# Nested comprehension
grid = for i <- 0..2, do: for j <- 0..2, do: i * 3 + j

# With conditions
evens = for i <- 0..9, i |> rem(2) == 0, do: i * i
```

## Testing Scenarios

### Comprehensive Test Coverage

The `test/snapshot/core/array_comprehension_nested/Main.hx` test validates:

#### 1. Simple Nested Comprehensions (2 levels)
```haxe
var grid = [for (i in 0...3) [for (j in 0...3) i * 3 + j]];
// Should generate: for i <- 0..2, do: for j <- 0..2, do: i * 3 + j
```

#### 2. Constant Range Unrolled Comprehensions
```haxe
var unrolled = [for (i in 0...2) [for (j in 0...2) j]];
// Tests detection of completely unrolled blocks with bare concatenations
```

#### 3. Deeply Nested Comprehensions (3+ levels)
```haxe
var cube = [for (i in 0...2) [for (j in 0...2) [for (k in 0...2) i * 4 + j * 2 + k]]];
// Tests recursive reconstruction depth
```

#### 4. Four-Level Nesting (Stress Test)
```haxe
var hypercube = [for (a in 0...2) [for (b in 0...2) [for (c in 0...2) [for (d in 0...2) a * 8 + b * 4 + c * 2 + d]]]];
// Tests maximum recursion handling
```

#### 5. Comprehensions with Conditions
```haxe
var filtered = [for (i in 0...4) [for (j in 0...4) if ((i + j) % 2 == 0) i * 4 + j]];
// Should preserve filter conditions in output
```

#### 6. Mixed Constant/Variable Ranges
```haxe
var n = 3;
var mixed = [for (i in 0...n) [for (j in 0...2) i + j]];
// Tests combination of runtime and compile-time ranges
```

#### 7. Comprehensions with Complex Expressions
```haxe
var table = [for (row in 0...3) [for (col in 0...3) 'R${row}C${col}']];
// Tests string interpolation in comprehension bodies
```

#### 8. Comprehensions with Block Bodies
```haxe
var computed = [for (i in 0...3) [for (j in 0...3) {
    var temp = i * j;
    temp + (i + j);
}]];
// Tests multi-statement block handling
```

#### 9. Comprehensions with Metadata/Parenthesis Wrappers
```haxe
@:keep var wrapped = ([for (i in 0...2) ([for (j in 0...2) (i * 2 + j)])]);
// Tests unwrapping of TMeta and TParenthesis nodes
```

#### 10. Mixed Comprehensions and Literals
```haxe
var mixed = [
    [for (i in 0...3) i * 2],
    [10, 20, 30],
    [for (j in 0...3) j + 100]
];
// Tests mixing of comprehensions with literal arrays
```

#### 11. Comprehensions from Iterables
```haxe
var source = [1, 2, 3];
var fromArray = [for (x in source) [for (y in source) x * y]];
// Tests non-range iterators
```

#### 12. Edge Cases
```haxe
// Empty ranges
var empty = [for (i in 0...0) [for (j in 0...3) i + j]];

// Single element
var single = [for (i in 0...1) [for (j in 0...1) i + j]];
```

### Test Execution

```bash
# Run the nested comprehension test
make -C test test-core/array_comprehension_nested

# Update expected output if improvements are made
make -C test update-intended TEST=core/array_comprehension_nested

# Run all array-related tests
make -C test test-core/arrays
```

## Edge Cases and Limitations

1. **Constant range unrolling**: When Haxe unrolls small constant ranges, we try to detect the pattern but may generate regular lists instead of comprehensions
2. **Complex transformations**: Some complex comprehensions with multiple generators may not be fully reconstructed
3. **Side effects**: Comprehensions with side effects in the yield expression need careful handling
4. **Performance**: Deeply nested unrolled comprehensions can generate large ASTs

## Implementation Status

✅ **Completed:**
- Detection of loop-based comprehensions
- Detection of unrolled list-building blocks  
- Handling of bare concatenations
- Support for nested comprehensions
- Comprehensive test suite with 14+ test scenarios
- Recursive reconstruction for arbitrary nesting depth

⚠️ **Known Issues:**
- Bare concatenations in deeply nested blocks may still generate invalid Elixir in some edge cases
- Performance of unrolled comprehensions could be improved by generating list literals directly

## Future Improvements

1. **Pre-typing macro**: Tag comprehensions before Haxe's desugaring phase
2. **More patterns**: Detect additional desugaring patterns as they're discovered
3. **Optimization**: Generate `Enum.map` for simple transformations when appropriate
4. **Direct list literals**: For fully unrolled comprehensions, generate `[0, 1, 2]` instead of reconstructing `for`
5. **Multiple generators**: Support `for x in xs, y in ys` patterns

## Related Documentation

- [AST Pipeline Architecture](../05-architecture/AST_PIPELINE_MIGRATION.md)
- [Compiler Development Guide](./COMPILER_DEVELOPMENT_GUIDE.md)
- [Testing Infrastructure](./testing-infrastructure.md)
- [AST Processing](./ast-processing.md)