# Haxe Loop Desugaring Patterns Documentation

## Overview
Haxe desugars high-level loop constructs into lower-level TypedExpr patterns before reaching the Reflaxe compiler. Understanding these patterns is crucial for generating correct and idiomatic Elixir code.

## Pattern 1: For-in-Range Loop

### Haxe Source
```haxe
for (i in 0...5) {
    trace(i);
}
```

### Desugared TypedExpr Structure
```
TBlock([
    TVar(_g, TConst(TInt(0))),      // Start bound variable
    TVar(_g1, TConst(TInt(5))),     // End bound variable  
    TWhile(
        TBinop(OpLt, TLocal(_g), TLocal(_g1)),  // Condition: _g < _g1
        TBlock([
            TVar(i, TLocal(_g)),         // User variable assignment
            _g = _g + 1,                 // Increment infrastructure var
            trace(i)                     // User code body
        ])
    )
])
```

### Infrastructure Variables
- `_g`: Loop counter (start value)
- `_g1`: Loop bound (end value)
- These are compiler-generated and should not appear in output

## Pattern 2: For-in-Range with Variable Bounds

### Haxe Source
```haxe
var start = 0;
var end = s.length;
for (i in start...end) {
    // body
}
```

### Desugared TypedExpr Structure
```
TBlock([
    TVar(_g, TLocal(start)),         // Start from variable
    TVar(_g1, TField(s, length)),    // End from field access
    TWhile(
        TBinop(OpLt, TLocal(_g), TLocal(_g1)),
        TBlock([
            TVar(i, TLocal(_g)),
            _g = _g + 1,
            // body
        ])
    )
])
```

## Pattern 3: For-in-Array

### Haxe Source
```haxe
var arr = [1, 2, 3];
for (item in arr) {
    trace(item);
}
```

### Desugared TypedExpr Structure
```
TBlock([
    TVar(_g, TConst(TInt(0))),           // Index counter
    TVar(_g1, TField(arr, length)),      // Array length
    TWhile(
        TBinop(OpLt, TLocal(_g), TLocal(_g1)),
        TBlock([
            TVar(item, TArrayAccess(arr, _g)),  // Get array element
            _g = _g + 1,
            trace(item)
        ])
    )
])
```

## Pattern 4: While Loop with Mutations

### Haxe Source
```haxe
var i = 0;
while (i < 10) {
    trace(i);
    i++;
}
```

### Desugared TypedExpr Structure
```
TWhile(
    TBinop(OpLt, TLocal(i), TConst(TInt(10))),
    TBlock([
        trace(i),
        TBinop(OpAssign, TLocal(i), TBinop(OpAdd, TLocal(i), TConst(TInt(1))))
    ])
)
```

Note: No infrastructure variables for pure while loops.

## Key Insights for Compiler Implementation

### 1. Infrastructure vs User Variables
- **Infrastructure**: `_g`, `_g1`, `_g2` etc. (compiler-generated loop mechanics)
- **User**: Named variables from source code
- Infrastructure variables should be transparent in output

### 2. Variable Initialization
When generating reduce_while patterns:
- Infrastructure variables MUST be initialized before use
- Their initial values come from the TVar expressions in the TBlock
- They should not appear as undefined references in the accumulator

### 3. Mutation Detection
The MutabilityDetector sees infrastructure variables as "mutated" because:
- `_g` is incremented in the loop body
- This triggers state threading logic
- But these are not user mutations - they're loop mechanics

## Recommendations for Idiomatic Elixir Generation

### Simple Range Loops
```haxe
for (i in 0...5) { trace(i); }
```
Should generate:
```elixir
Enum.each(0..4, fn i -> IO.inspect(i) end)
```

### Array Iteration
```haxe
for (item in arr) { process(item); }
```
Should generate:
```elixir
Enum.each(arr, fn item -> process(item) end)
```

### Collecting Results
```haxe
var result = [];
for (i in 0...5) {
    result.push(i * 2);
}
```
Should generate:
```elixir
result = for i <- 0..4, do: i * 2
```

### Complex Stateful Loops
Only use reduce_while for loops with:
- Multiple state variables being mutated
- Complex control flow (break/continue)
- Conditional accumulation

## Compiler Fix Strategy

1. **Detect infrastructure variables** by pattern (`_g`, `_g1`, etc.)
2. **Extract initialization values** from TVar expressions
3. **Initialize before reduce_while** if using that pattern
4. **Better: Generate idiomatic Elixir** for simple loops
5. **Reserve reduce_while** for truly complex cases