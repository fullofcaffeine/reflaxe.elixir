# ~~Haxe Optimizer Bug~~ Transpiler AST Building Issue: Lost Variable Declarations

**UPDATE (December 2025)**: After thorough investigation, this is **NOT a Haxe optimizer bug** but rather a **bug in our transpiler's AST building phase**.

## Problem Description

Variable declarations inside nested if statements within loops are lost during the AST building phase, resulting in generated Elixir code with undefined variables.

## Example

### Haxe Source Code
```haxe
if (item > 2) {
    var doubled = item * 2;  // Declaration
    if (doubled > 6) {       // Reference
        results.push(doubled); // Reference
    }
}
```

### Expected TypedExpr
```
TIf(
    TBinop(OpGt, TLocal(item), TConst(2)),
    TBlock([
        TVar(doubled, TBinop(OpMult, TLocal(item), TConst(2))),  // Declaration present
        TIf(
            TBinop(OpGt, TLocal(doubled), TConst(6)),           // Reference
            TCall(push, [TLocal(doubled)])                      // Reference
        )
    ])
)
```

### Actual TypedExpr (After Haxe Optimization)
```
TIf(
    TBinop(OpGt, TLocal(item), TConst(2)),
    TIf(
        TBinop(OpGt, TLocal(doubled), TConst(6)),  // Reference without declaration!
        TCall(push, [TBinop(OpMult, TLocal(item), TConst(2))])  // Inlined here
    )
)
```

## Generated Elixir (Invalid)
```elixir
if (item > 2) do
    if (doubled > 6) do      # ERROR: undefined variable "doubled"
        results = results ++ [(item * 2)]
    end
end
```

## Impact

This affects:
1. **Phoenix.Presence code** - `meta` variable undefined in `get_users_editing_todo`
2. **Loop body transformations** - Variables in nested if statements
3. **Any code with simple variable declarations** that Haxe decides to inline

## Root Cause

**INVESTIGATION FINDINGS (December 2025)**: The issue is in our ElixirASTBuilder, not Haxe:

1. **Debug output shows** the body BEFORE transformation already has the bug
2. **The TVar node** for `doubled = item * 2` is missing from the AST being built
3. **The problem occurs** during initial AST building from TypedExpr, not during transformation
4. **Specific location**: When TIf processes its then-branch containing TVar nodes

The transformVariableReferences function is NOT the problem - the variable declaration is already missing before any transformations are applied.

## Attempted Solutions

### 1. Detect and Recreate Declarations (Complex)
- Would need to analyze the AST to find undefined variables
- Would need to infer their initialization expressions
- Very complex and error-prone

### 2. Disable Optimization (Not Possible)
- Haxe doesn't provide fine-grained control over optimizer
- Can't disable specific optimizations from our compiler

### 3. Force Variable Usage (Workaround)
- Users can add dummy usage to prevent inlining
- Not a real solution, just a workaround

## Current Status

This is a **bug in our ElixirASTBuilder** that needs to be fixed. The issue is in how we process TIf statements containing TBlock with TVar nodes.

## Investigation Evidence

```bash
# Debug output shows the problem occurs BEFORE transformation:
npx haxe compile.hxml -D debug_state_threading 2>&1 | grep -A10 "items"

# Output shows body BEFORE transformation already missing 'doubled' declaration:
# Body BEFORE transformation:
# item = items[i]
# i = i + 1
# if (item > 2) do
#   if (doubled > 6) do      # ERROR: doubled never declared!
#     results = results ++ [(item * 2)]
#   end
# end
```

## Solution Approach

Fix the ElixirASTBuilder to properly handle TVar nodes inside TIf then-branches:
1. Locate where TIf processes its body in ElixirASTBuilder.hx
2. Ensure TVar nodes inside TBlock are converted to EMatch nodes
3. Test with all scenarios in LoopNestedVariableDeclaration test