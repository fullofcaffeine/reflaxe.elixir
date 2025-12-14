# Enum Pattern Variable Extraction Debug Findings

## Problem Statement
Pattern variables in enum switch cases (like `config` in `case Repo(config):`) are incorrectly being assigned from `g_array` instead of the extracted enum parameter `g_param_0`.

## Debug Session Findings

### 1. Integer Case Detection Works
- Successfully detecting integer-based enum cases (cases 8, 9, 10, 12, 13, 34, 92)
- These correspond to enum constructors in TypeSafeChildSpec

### 2. Critical Discovery: Case Body Structure
**The case body is NOT a TBlock, it's a TBinop!**

```
Found integer case: 9
Case body type: TBinop  // <-- NOT TBlock!
Case body is not TBlock, type is: TBinop
EXIT - Returning 0 pattern variables
```

This explains why our extraction function isn't finding the pattern variables - we're only looking inside TBlock expressions, but the case body is a TBinop (binary operation).

### 3. AST Structure Analysis - UPDATED
The actual AST structure is:
```
case 9 -> TBinop(OpAssignOp,
    TLocal(temp_result),
    TConst(nil)
)
```

The case body starts with assignment operations (OpAssignOp), NOT with the enum parameter extraction!

### 3a. Critical Finding
The TEnumParameter extraction and pattern variable assignment are NOT at the top level of the case body. They must be nested deeper within the AST structure, possibly after the initial temp_result assignments.

### 4. Why This Happens
When Haxe compiles enum pattern matching to integer-based switches:
1. It extracts enum parameters using TEnumParameter
2. It assigns them to temporary variables (_g)
3. It assigns pattern variables from the temporaries
4. It uses **comma operators** to sequence these operations in expression contexts

### 5. The Fix Required
We need to:
1. Handle TBinop(OpComma, ...) in addition to TBlock
2. Recursively traverse the comma-separated expressions
3. Extract TVar nodes from within the binary operation tree

## Next Steps
1. Update `extractPatternVariablesFromIntegerCase` to handle TBinop structures
2. Add recursive traversal for comma operators
3. Test with todo-app to verify the fix works