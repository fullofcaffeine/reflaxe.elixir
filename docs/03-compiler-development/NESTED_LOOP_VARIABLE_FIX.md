# Nested Loop Variable Substitution Fix

**Date**: September 24, 2025  
**Issue**: Loop variables in string interpolations are replaced with literal values

## Problem Analysis

### Root Cause
Haxe's analyzer optimization (`-D analyzer-optimize`) is replacing loop variables with their initial values before our compiler processes them:

```haxe
// Original Haxe source
for (i in 0...2) {
    for (j in 0...2) {
        trace('Cell (' + i + ',' + j + ')');
    }
}

// After Haxe optimization (what our compiler receives)
// The variables i and j have been replaced with literals 0 and 1
```

### Compilation Flow
1. **Haxe Optimizer**: Replaces `i` and `j` with `0` and `1` in string concatenation
2. **ElixirASTBuilder**: Creates `EBinary(StringConcat, ...)` with literal values
3. **stringInterpolationPass**: Converts to `"Cell (#{0},#{1})"` 
4. **Result**: Wrong variable names in generated code

## Solution Approach

### Option 1: Detect Loop Context in stringInterpolationPass
Enhance the stringInterpolationPass to:
1. Track when we're inside loop bodies (via metadata or context)
2. Detect when interpolated values are suspicious constants (0, 1, 2...)
3. Replace with actual loop variable names from context

### Option 2: Preserve Variable Names Through Metadata
During AST building:
1. Detect loop variable usage in string concatenations
2. Add metadata indicating original variable names
3. Use metadata in stringInterpolationPass to restore names

### Option 3: Disable Specific Optimizations
Add compiler flag to disable loop variable optimization:
```hxml
-D no-loop-var-optimization
```

## Recommended Implementation

### Enhanced stringInterpolationPass

```haxe
static function stringInterpolationPass(ast: ElixirAST, context: LoopContext = null): ElixirAST {
    // Track loop context
    var currentContext = context;
    
    function transform(node: ElixirAST): ElixirAST {
        // Update context when entering loops
        switch(node.def) {
            case ECall(_, "each", [range, EAnonymousFunction(params, body)]):
                var loopVar = params[0]; // e.g., "i" or "j"
                var newContext = {
                    variable: loopVar,
                    parent: currentContext
                };
                // Process body with loop context
                return processWithContext(body, newContext);
                
            case EBinary(StringConcat, _, _):
                // When processing string concatenation...
                if (currentContext != null) {
                    // Check for literal values that match loop patterns
                    // Replace with loop variable names
                }
        }
    }
}
```

### Pattern Detection Logic

```haxe
function shouldReplaceWithLoopVar(value: ElixirAST, context: LoopContext): Bool {
    switch(value.def) {
        case EInteger(n) if (n >= 0 && n < 10):
            // Suspicious constant in loop context
            // Check if it matches expected loop index pattern
            return true;
        default:
            return false;
    }
}
```

## Alternative: Metadata-Based Solution

### During AST Building

```haxe
// In ElixirASTBuilder when processing TBinop(OpAdd) for strings
case TBinop(OpAdd, e1, e2) if (isStringType(e1) || isStringType(e2)):
    var leftAST = buildExpression(e1);
    var rightAST = buildExpression(e2);
    
    // Check if either side references a loop variable
    if (isLoopVariable(e1)) {
        leftAST.metadata.originalVarName = extractVarName(e1);
    }
    if (isLoopVariable(e2)) {
        rightAST.metadata.originalVarName = extractVarName(e2);
    }
    
    return makeAST(EBinary(StringConcat, leftAST, rightAST));
```

### In stringInterpolationPass

```haxe
// When creating interpolation
var exprToInterpolate = transformedExpr;

// Check for metadata indicating original variable name
if (exprToInterpolate.metadata?.originalVarName != null) {
    // Use the original variable name instead of the literal
    result += '#{' + exprToInterpolate.metadata.originalVarName + '}';
} else {
    var exprStr = ElixirASTPrinter.printAST(exprToInterpolate);
    result += '#{' + exprStr + '}';
}
```

## Testing Strategy

### Test Case
```haxe
// test/snapshot/regression/nested_loop_interpolation/Main.hx
class Main {
    static function main() {
        for (i in 0...3) {
            for (j in 0...3) {
                trace('Position: (' + i + ',' + j + ')');
                trace('Cell ${i}-${j}');  // Also test Haxe interpolation
            }
        }
    }
}
```

### Expected Output
```elixir
Enum.each(0..2, fn i ->
  Enum.each(0..2, fn j ->
    Log.trace("Position: (#{i},#{j})", ...)
    Log.trace("Cell #{i}-#{j}", ...)
  end)
end)
```

## Implementation Steps

1. **Add Loop Context Tracking**
   - Modify ElixirASTTransformer to maintain loop variable context
   - Pass context through transformation passes

2. **Enhance Pattern Detection**
   - Detect when literal values should be loop variables
   - Use heuristics based on value ranges and context

3. **Update stringInterpolationPass**
   - Check loop context when creating interpolations
   - Replace suspicious literals with loop variable names

4. **Add Debug Traces**
   - Add XRay debug output for loop variable substitution
   - Help diagnose when substitution occurs

5. **Comprehensive Testing**
   - Test nested loops with various depths
   - Test different string concatenation patterns
   - Verify no regressions in non-loop contexts

## Long-Term Considerations

1. **Optimizer Control**: Consider adding fine-grained control over Haxe's optimizations
2. **General Pattern**: This solution could apply to other variable preservation needs
3. **Performance**: Ensure the pattern detection doesn't slow compilation significantly
4. **Documentation**: Document this as a known Haxe→Elixir compilation quirk

## Status

Currently investigating the best approach. The metadata-based solution seems most robust as it preserves information through the entire pipeline rather than trying to reconstruct it later.