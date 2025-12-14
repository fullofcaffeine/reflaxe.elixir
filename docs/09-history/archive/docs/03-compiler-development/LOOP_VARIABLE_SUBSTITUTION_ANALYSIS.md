# Loop Variable Substitution Analysis

## Problem Statement

When Haxe's `-D analyzer-optimize` flag is enabled, loop variables in string concatenations are replaced with literal values before our compiler processes them. This results in non-idiomatic Elixir output with hardcoded values instead of variables.

### Example Issue

**Haxe Input:**
```haxe
for (i in 0...2) {
    for (j in 0...2) {
        trace('Cell (' + i + ',' + j + ')');
    }
}
```

**Current Output:**
```elixir
Enum.each(0..1, fn i -> 
  Enum.each(0..1, fn j -> 
    Log.trace("Cell (#{0},#{1})", ...)  # WRONG: Literal values!
  end) 
end)
```

**Expected Output:**
```elixir
Enum.each(0..1, fn i -> 
  Enum.each(0..1, fn j -> 
    Log.trace("Cell (#{i},#{j})", ...)  # RIGHT: Variable names!
  end) 
end)
```

## Root Cause Analysis

### 1. Haxe Optimizer Behavior
The Haxe optimizer with `-D analyzer-optimize` performs constant folding and loop unrolling optimizations:
- In nested loops, it replaces variable references with their compile-time known values
- Simple loops may be completely unrolled into sequential statements
- String concatenations with loop variables become concatenations with literal values

### 2. AST Transformation Pipeline Issue

The current transformation pass ordering in `ElixirASTTransformer.hx`:

```haxe
// Line 329-343
passes.push({
    name: "StringInterpolation",
    description: "Convert string concatenation to idiomatic string interpolation",
    enabled: true,
    pass: stringInterpolationPass
});

// Loop variable restoration pass (must run after string interpolation)
passes.push({
    name: "LoopVariableRestore", 
    description: "Restore loop variables in string interpolations (fixes Haxe optimizer issue)",
    enabled: true,
    pass: LoopVariableRestorer.restoreLoopVariablesPass
});
```

**The Problem**: 
1. StringInterpolation pass runs FIRST (line 334)
2. It converts string concatenations to ERaw nodes with interpolated strings
3. By this point, the literal values (0, 1, 2) are already baked into the strings
4. LoopVariableRestore runs AFTER (line 342)
5. It finds the interpolated strings but has "No loop context available"
6. The Enum.each structure exists but isn't detected because LoopVariableRestorer looks for specific patterns that don't match

### 3. Debug Output Analysis

From debug traces:
```
[LoopVariableRestorer] Found ERaw with interpolation: "Cell (#{0},#{1})"
[LoopVariableRestorer]   No loop context available
```

This confirms that:
- The restorer IS finding the interpolated strings
- But it cannot establish loop context because it's not detecting the Enum.each structure
- The pattern matching in LoopVariableRestorer is looking for specific AST patterns that don't match the actual generated AST

## Solution Approaches

### Option A: Reorder Transformation Passes
**Approach**: Run LoopVariableRestore BEFORE StringInterpolation

**Pros**:
- LoopVariableRestorer could work with the original concatenation AST
- Could detect loop context from the original structure

**Cons**:
- Would need to handle string concatenation patterns differently
- May break other transformations that depend on current ordering

### Option B: Enhance LoopVariableRestorer
**Approach**: Improve pattern detection to work with already-interpolated strings

**Implementation**:
1. Detect Enum.each patterns more broadly
2. Track loop variables from function parameters (fn i -> ...)
3. Replace literal values in ERaw strings within loop bodies

**Pros**:
- Works with existing pass ordering
- More robust pattern detection
- Handles both nested and simple loops

**Cons**:
- More complex implementation
- Need to carefully match literals to loop ranges

### Option C: Metadata Preservation Strategy
**Approach**: Preserve loop context metadata through transformations

**Implementation**:
1. ElixirASTBuilder adds loop metadata when building loop nodes
2. Metadata includes loop variable names and ranges
3. StringInterpolation pass preserves this metadata
4. LoopVariableRestorer uses metadata instead of pattern detection

**Pros**:
- Most robust solution
- Works regardless of transformation ordering
- Metadata can be used by other passes

**Cons**:
- Requires changes to multiple components
- Need to ensure metadata flows through all transformations

## Recommended Solution

**Option C (Metadata Preservation)** is the most architecturally sound approach:

1. **Phase 1**: Add loop metadata in ElixirASTBuilder
   - When building Enum.each nodes, attach metadata with loop variable info
   - Include variable name, range bounds, nesting level

2. **Phase 2**: Preserve metadata through transformations
   - Ensure all transformation passes preserve metadata
   - StringInterpolation pass copies metadata to transformed nodes

3. **Phase 3**: Use metadata in LoopVariableRestorer
   - Check for loop metadata on nodes
   - Use metadata to determine variable substitutions
   - Apply substitutions to ERaw strings

## Additional Issues

### Loop Unrolling
Simple loops are being completely unrolled:
```elixir
# Instead of: Enum.each(0..2, fn k -> Log.trace("Index: #{k}", ...) end)
Log.trace("Index: #{0}", ...)
Log.trace("Index: #{1}", ...)
Log.trace("Index: #{2}", ...)
```

This requires detection of sequential statements that originated from loops and reconstructing the loop structure.

## Implementation Plan

1. **Analyze AST structure** - Document exact AST patterns generated for loops
2. **Implement metadata system** - Add loop context metadata to AST nodes
3. **Update StringInterpolation** - Preserve metadata through transformation
4. **Enhance LoopVariableRestorer** - Use metadata for restoration
5. **Handle loop unrolling** - Detect and reconstruct unrolled loops
6. **Test thoroughly** - Ensure all loop patterns work correctly

## Testing Strategy

Create comprehensive tests for:
- Nested loops with string concatenation
- Simple loops with various expressions
- Loops with complex bodies
- Edge cases (empty loops, single iteration, etc.)

Each test should have idiomatic Elixir as the intended output.