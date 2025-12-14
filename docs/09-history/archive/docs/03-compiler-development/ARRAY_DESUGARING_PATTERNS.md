# Array Desugaring Patterns in Haxe→Elixir Compilation

## Overview

This document captures critical learnings about how Haxe desugars array operations and how Reflaxe.Elixir can detect and optimize these patterns to generate idiomatic Elixir code.

## The Problem

Haxe's standard library methods like `array.filter()` and `array.map()` are desugared into imperative while loops during the typed AST phase, BEFORE Reflaxe gets control. This results in non-idiomatic Elixir code with Y combinator patterns instead of clean `Enum.filter/map` calls.

### Example Input (Haxe)
```haxe
var items = ["apple", "banana", "cherry"];
var target_item = "banana";
var result = items.filter(item -> item != target_item);
```

### Generated Output (Before Fix)
```elixir
# Non-idiomatic Y combinator pattern
items = ["apple", "banana", "cherry"]
target_item = "banana"
temp_array = nil
(
    g_array = []
    (
    g_counter = 0
    loop_helper = fn loop_fn, {v, g1} ->
        if ((g_counter < items.length)) do
            v = Enum.at(items, g_counter)
            g1 = g1 + 1
            if ((v != target_item)) do
                g_counter ++ [v]
            end
            loop_fn.(loop_fn, {v, g1})
        else
            {v, g1}
        end
    end

    {v, g1} = loop_helper.(loop_helper, {v, g1})
    )
    temp_array = g_counter
)
```

### Desired Output (After Fix)
```elixir
# Idiomatic Elixir
items = ["apple", "banana", "cherry"]
target_item = "banana"
result = Enum.filter(items, fn item -> item != target_item end)
```

## Key Discovery: Haxe Desugaring Happens Before Reflaxe

### Critical Understanding
**Haxe desugaring occurs during the typed AST phase, BEFORE any Reflaxe preprocessors or transformations run.** This means:

1. ❌ **Preprocessors cannot prevent desugaring** - They run too late
2. ❌ **ExpressionPreprocessor approach fails** - Desugaring already happened  
3. ✅ **Pattern detection must work on desugared AST** - Detect and reverse the transformation
4. ✅ **TBlock level analysis required** - Variables are split across nested structures

### Compilation Timeline
```
Haxe Source (.hx) 
    ↓
Haxe Parser (creates untyped AST)
    ↓ 
Haxe Typer (creates TypedExpr AST)
    ↓ [DESUGARING HAPPENS HERE]
Haxe Array Operations → While Loops
    ↓
Reflaxe.Elixir Gets Control (TypedExpr with desugared loops)
    ↓ [OUR PATTERN DETECTION HERE]  
ElixirCompiler.compileExpression()
    ↓
Generated Elixir Code
```

## Exact AST Pattern Discovery

Through extensive debug tracing, we discovered the exact TBlock structure that Haxe generates:

### TBlock Structure
```
TBlock with 3 expressions:
[0] TVar _g = [] (accumulator initialization)
[1] TBlock containing:
    - TVar _g1 = 0 (index initialization)  
    - TWhile(condition, body)
[2] TBinop(OpAssign, temp_array, TLocal(_g)) (assignment back)
```

### TWhile Structure Inside [1]
```
TWhile(
    condition: TBinop(OpLt, TLocal(_g1), TField(TLocal(items), "length")),
    body: TBlock with operations:
        - TVar v = Enum.at(items, _g1) (element extraction)
        - TUnop(OpIncrement, TLocal(_g1)) (index increment)
        - Conditional logic (filter/map operation)
        - Array operation (_g ++ [result] for accumulation)
)
```

### Critical Variables
- **Source array**: Not stored as separate TVar, embedded in TWhile condition
- **Accumulator (_g)**: Starts as `[]`, collects results  
- **Index (_g1)**: Loop counter, starts at 0
- **Element (v)**: Current array element in loop body

## Pattern Detection Strategy

### Detection Location
**Pattern detection must occur at TBlock level in ControlFlowCompiler**, not at TWhile level, because:

1. The accumulator `_g` is defined outside the TWhile
2. The final assignment back to temp variable is outside TWhile
3. TWhile alone doesn't contain complete pattern context

### Implementation Approach
```haxe
private function detectDesugarredArrayOperation(el: Array<TypedExpr>): Null<{type: String, code: String}> {
    // Must have exactly 3 expressions for the pattern
    if (el.length != 3) return null;
    
    // [0] Must be TVar with empty array initialization  
    var accumulatorVar = detectAccumulatorInit(el[0]);
    if (accumulatorVar == null) return null;
    
    // [1] Must be TBlock with index + TWhile
    var loopInfo = analyzeLoopBlock(el[1]);
    if (loopInfo == null) return null;
    
    // [2] Must be assignment back to temp variable
    var finalAssignment = detectFinalAssignment(el[2], accumulatorVar);
    if (finalAssignment == null) return null;
    
    // Extract source array from TWhile condition
    var sourceArray = extractSourceArray(loopInfo.whileCondition);
    
    // Detect operation type from loop body
    var operationType = analyzeOperationType(loopInfo.whileBody);
    
    // Generate idiomatic Elixir
    return generateEnumOperation(sourceArray, operationType, loopInfo);
}
```

## Operation Type Detection

### Filter Pattern
```haxe
// Loop body contains conditional accumulation
if (condition) {
    accumulator ++ [element]
}
```

### Map Pattern  
```haxe
// Loop body contains unconditional transformation
accumulator ++ [transformation(element)]
```

### Detection Logic
1. **Analyze TWhile body** for accumulation pattern
2. **Check for conditional vs unconditional** accumulation
3. **Extract condition/transformation** expression
4. **Map to appropriate Enum operation**

## Code Generation Strategy

### Variable Substitution
The loop variable names must be substituted to generate clean lambda expressions:

```haxe
// Original desugared pattern uses generated names
v = Enum.at(items, g_counter)
if (v != target_item) { ... }

// Generated Enum.filter should use clean parameter
Enum.filter(items, fn item -> item != target_item end)
```

### Substitution Implementation
```haxe
function substituteVariable(expr: TypedExpr, oldVar: TVar, newName: String): TypedExpr {
    return switch(expr.expr) {
        case TLocal(v) if (v == oldVar): 
            // Replace with new parameter name
            { expr | expr: TLocal({...v, name: newName}) }
        case _:
            // Recursively process nested expressions
            transformTypedExpr(expr, e -> substituteVariable(e, oldVar, newName));
    }
}
```

## Attempted Solutions & Why They Failed

### 1. ArrayOperationPreprocessor Approach ❌
```haxe
// Tried to intercept before desugaring
class ArrayOperationPreprocessor extends BasePreprocessor {
    public function process(data: ClassFuncData, compiler: BaseCompiler): Void {
        // FAILED: Desugaring already happened
    }
}
```

**Why it failed**: Preprocessors run after desugaring is complete.

### 2. Metadata Tagging Approach ❌  
```haxe
// Tried to tag array operations with metadata
@:elixir_enum_filter
someExpression; 
```

**Why it failed**: No way to inject metadata during Haxe's desugaring process.

### 3. TWhile Level Detection ❌
```haxe
// Tried to detect pattern inside compileWhileLoop
private function tryOptimizeForInPattern(econd: TypedExpr, ebody: TypedExpr)
```

**Why it failed**: Accumulator variables are defined outside TWhile scope.

## Successful Solution: TBlock Pattern Recognition ✅

### Final Implementation Strategy
1. **Detect at TBlock level** where all variables are visible
2. **Extract source array** from TWhile condition analysis  
3. **Analyze operation type** from TWhile body patterns
4. **Generate idiomatic Enum calls** with proper variable substitution
5. **Handle complex expressions** through recursive AST processing

### Generated Code Quality
The goal is to produce Elixir that looks hand-written by experts:

```elixir
# Generated by Reflaxe.Elixir - looks completely natural
items
|> Enum.filter(fn item -> item != "banana" end)
|> Enum.map(fn item -> String.upcase(item) end)
```

## Implementation Status

### Completed ✅
- [x] Pattern structure analysis and documentation
- [x] TBlock level detection framework  
- [x] Debug tracing to understand exact AST patterns
- [x] Removed all untyped usage that violated type safety

### In Progress 🔄
- [ ] Complete source array extraction from TWhile condition
- [ ] Implement operation type detection (filter vs map)
- [ ] Generate clean Enum calls with variable substitution

### Planned 📋
- [ ] Support for nested array operations
- [ ] Chain optimization (filter + map → single pipeline)
- [ ] Performance benchmarks vs Y combinator patterns

## Testing Strategy

### Test Cases Required
1. **Simple filter** - Single condition, outer variable capture
2. **Simple map** - Single transformation, outer variable capture  
3. **Nested operations** - Array of arrays with multi-level processing
4. **Multiple variables** - Complex conditions with multiple captures
5. **Chain operations** - Sequential filter + map transformations

### Validation Approach  
1. **Snapshot tests** - Verify generated Elixir syntax
2. **Runtime tests** - Ensure semantic equivalence
3. **Performance tests** - Compare Enum vs Y combinator performance
4. **Integration tests** - Test with Phoenix app compilation

## Related Documentation
- [/docs/03-compiler-development/COMPILER_BEST_PRACTICES.md](./COMPILER_BEST_PRACTICES.md) - General development practices
- [/docs/03-compiler-development/DEBUG_XRAY_SYSTEM.md](./DEBUG_XRAY_SYSTEM.md) - Debug tracing patterns used
- [/docs/03-compiler-development/TYPE_SAFETY_REQUIREMENTS.md](./TYPE_SAFETY_REQUIREMENTS.md) - Untyped usage prohibition

---

**Key Takeaway**: Understanding Haxe's desugaring timeline is critical for successful pattern optimization. What appears as a simple array operation becomes complex nested AST structures that require sophisticated pattern recognition to reverse into idiomatic target language constructs.