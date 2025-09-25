# Loop Variable Transformation Pipeline Investigation

## Summary of Findings

The loop variable transformation bug occurs due to multiple interacting issues in the Haxe→Elixir compiler:

## 1. Where PVar('i') is Created

**Location**: `src/reflaxe/elixir/ast/builders/LoopBuilder.hx`
- Line 201, 207: `PVar(snakeVar)` correctly created for `EnumEachRange` transform
- Line 249: `PVar(snakeVar)` correctly created for `EnumEachCollection` transform
- **BUG**: Line 627: Hardcoded `PVar("_")` in fallback case of `buildWithFullContext`

## 2. Transformation Pipeline

### Stage 1: Haxe Desugaring (Before Our Compiler)
```haxe
// Original Haxe code:
for (i in 0...arr.length) { items.push(writeValue(arr[i])); }

// Haxe desugars to:
var g = 0;
var g1 = arr.length;
while (g < g1) {
    var i = g;
    items.push(writeValue(arr[i]));
    g++;
}
```

### Stage 2: ElixirASTBuilder Processing
- `TBlock` contains the desugared pattern
- `DesugarredForDetector` (line 52) detects the pattern and identifies:
  - Counter variable: "g" 
  - Limit variable: "g1"
  - Loop body with user variable "i"

### Stage 3: LoopBuilder Transformation
- `buildWithFullContext` is called with counterVar="g"
- `analyzeForLoopBody` tries to extract user variable from loop body
- **PROBLEM**: When analysis fails, fallback uses hardcoded underscore (line 627)

## 3. Where It Becomes PVar('_')

**Primary Location**: `src/reflaxe/elixir/ast/builders/LoopBuilder.hx:627`
```haxe
// BUG: Hardcoded underscore when analysis fails
args: [PVar("_")]  
```

This happens when `analyzeForLoopBody` returns null, causing the fallback path to use underscore instead of extracting the actual loop variable.

## 4. Origin of 'g' Variable

The 'g' variable comes from Haxe's internal desugaring process:
- Haxe transforms `for (i in 0...n)` into a while loop with infrastructure variables
- Variables like `g`, `g1`, `_g`, `_g1` are created by Haxe (not our compiler)
- Pattern documented in `DesugarredForDetector.hx`

**The Bug**: The generated output `i = g = g + 1` appears because:
1. The loop variable 'i' assignment from 'g' is being preserved
2. But 'g' is never initialized in the Elixir output
3. The increment `g++` is being transformed incorrectly

## 5. Complete Trace from Source to Output

1. **Haxe Source**: `for (i in 0...arr.length)`
2. **Haxe Desugars**: Creates TBlock with `var g=0; var g1=arr.length; while(g<g1)`
3. **ElixirASTBuilder**: Receives TBlock, detects desugared pattern
4. **LoopBuilder.buildWithFullContext**: Called with counterVar="g"
5. **analyzeForLoopBody**: Attempts to extract "i" from loop body
6. **Fallback Path**: Analysis fails, uses hardcoded `PVar("_")`
7. **ElixirASTPrinter**: Prints the underscore as-is
8. **Final Output**: `Enum.each(0..arr.length, fn _ -> ...`

## Root Causes

1. **Hardcoded underscore**: Line 627 in LoopBuilder.hx uses `PVar("_")` instead of detecting variable
2. **Failed analysis**: `analyzeForLoopBody` doesn't properly extract the user variable in all cases
3. **Missing initialization**: The 'g' variable appears in expressions but isn't initialized
4. **No variable preservation**: Loop variables aren't protected from transformation passes

## Recommended Fixes

1. **Immediate**: Fix line 627 to use detected variable name instead of underscore
2. **Improve analysis**: Make `analyzeForLoopBody` more robust
3. **Add metadata**: Preserve loop variable names through all passes
4. **Initialize accumulators**: Detect and initialize variables like 'items' before loops
5. **Remove 'g' references**: Clean up infrastructure variable references in loop bodies