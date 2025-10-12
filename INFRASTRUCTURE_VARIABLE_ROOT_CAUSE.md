# Infrastructure Variable Substitution - Root Cause Analysis

## Executive Summary

**Root Cause Identified**: The preprocessor successfully substitutes infrastructure variables at the TypedExpr level, but SwitchBuilder **re-compiles the switch target expression** through `compileExpressionImpl()`, which processes the ORIGINAL TypedExpr that hasn't been through the preprocessor's substitution map.

**Impact**: Infrastructure variables like `_g` appear in generated Elixir code even though preprocessor claims to eliminate them.

**Fix Required**: Architecture change - preprocessor substitutions must be applied to TypedExpr BEFORE it reaches AST building, OR AST builders must use the preprocessed TypedExpr consistently.

---

## Problem Statement

### Symptom
```haxe
// Haxe code
var result = switch(TestPubSub.subscribe("notifications")) {
    case Error(reason): "Failed: " + reason;
    case Ok(value): "Success: " + value;
}
```

**Expected Elixir**:
```elixir
result = case (TestPubSub.subscribe("notifications")) do
  {:error, reason} -> "Failed: " <> reason
  {:ok, value} -> "Success: " <> value
end
```

**Actual Generated**:
```elixir
result = case _g do  # ← Infrastructure variable still present!
  {:ok, _value} ->
    value = elem(_g, 1)  # ← Using _g instead of direct pattern match
    "Success: #{value}"
  {:error, _reason} ->
    reason = elem(_g, 1)
    "Failed: #{reason}"
end
```

### Debug Evidence
Preprocessor debug output shows successful substitution:
```
[applySubstitutionsRecursively] ✓ Substituting _g (ID: 57730)
[applySubstitutionsRecursively] ✓ Substituting _g (ID: 57732)
```

But the substituted expression doesn't reach the final output.

---

## Architecture Analysis

### Current Compilation Pipeline

```
1. TypedExpr from Haxe Parser
   ↓
2. TypedExprPreprocessor.preprocess()
   - Creates Map<Int, TypedExpr> for infrastructure variables
   - Uses TypedExprTools.map() to recursively substitute TLocal nodes
   - DEBUG: "✓ Substituting _g" messages appear here ✅
   ↓
3. ElixirASTBuilder.buildFromTypedExpr(preprocessedExpr, context)
   - SwitchBuilder.build() called for TSwitch expressions
   ↓
4. SwitchBuilder.build() - LINE 136 IS THE PROBLEM:
   ```haxe
   var targetAST = if (context.compiler != null) {
       // ❌ BUG: Re-compiles the ORIGINAL expression, not preprocessed one
       var result = context.compiler.compileExpressionImpl(actualSwitchExpr, false);
       result;
   }
   ```
   ↓
5. compileExpressionImpl() processes the ORIGINAL TypedExpr
   - This TypedExpr still contains TLocal(_g) references
   - Preprocessor's substitution map is NOT consulted
   - VariableBuilder.buildVariableReference() sees TLocal(_g)
   ↓
6. ElixirASTPrinter generates: case _g do
```

---

## Root Cause: Architecture Mismatch

### The Problem: Two Separate Compilation Paths

1. **Preprocessor Path** (ID-based substitution):
   ```haxe
   // TypedExprPreprocessor.hx:249-301
   static function applySubstitutionsRecursively(expr: TypedExpr, subs: Map<Int, TypedExpr>): TypedExpr {
       return switch(expr.expr) {
           case TLocal(v):
               if (subs.exists(v.id)) {
                   subs.get(v.id);  // ✅ Substitution happens here
               } else {
                   expr;
               }
           // ...
       }
   }
   ```

2. **AST Builder Path** (recompiles original):
   ```haxe
   // SwitchBuilder.hx:136-148
   var targetAST = if (context.compiler != null) {
       // ❌ This calls compileExpressionImpl with ORIGINAL expr
       context.compiler.compileExpressionImpl(actualSwitchExpr, false);
   }
   ```

### Why This Fails

**The preprocessor modifies a COPY of the TypedExpr tree**, creating a new tree with substitutions applied. However:

1. `SwitchBuilder` receives the preprocessed `TSwitch` expression
2. But it extracts the SWITCH TARGET expression (`actualSwitchExpr`)
3. This target is a **reference to the ORIGINAL un-preprocessed TypedExpr node**
4. When `compileExpressionImpl` is called on this node, it sees `TLocal(_g)`
5. The substitution map doesn't exist in this compilation context

### Architecture Flaw

**The preprocessor operates on the WRONG level**:
- It modifies TypedExpr tree structure (line 249-301 in TypedExprPreprocessor.hx)
- But AST builders extract sub-expressions and re-compile them independently
- The substitution context is LOST during this extraction

---

## Why Reflaxe Reference Implementation Works

Examining `/haxe.elixir.reference/reflaxe/src/reflaxe/preprocessors/implementations/RemoveTemporaryVariablesImpl.hx`:

```haxe
// Line 157-171
function mapTypedExpr(mappedExpr, noReplacements): TypedExpr {
    switch(mappedExpr.expr) {
        case TLocal(v) if(!noReplacements): {
            final e = findReplacement(v.id);
            if(e != null) return e.wrapParenthesisIfOrderSensitive();
        }
        case TBlock(_): {
            final tvr = new RemoveTemporaryVariablesImpl(mode, mappedExpr, varUsageCount);
            tvr.parent = this;
            return tvr.fixTemporaries();  // ✅ Recursively processes
        }
        // ...
    }
    return haxe.macro.TypedExprTools.map(mappedExpr, e -> mapTypedExpr(e, noReplacements));
}
```

**Key Difference**: Reflaxe's RemoveTemporaryVariablesImpl:
1. Modifies the ACTUAL TypedExpr tree structure
2. Uses TypedExprTools.map() to transform in place
3. Returns a NEW TypedExpr with ALL references updated
4. The modified tree is what gets passed to compileExpressionImpl

**Our preprocessor does the same**, but the problem is:
- Sub-expressions extracted by builders are POINTERS to original nodes
- When builders re-compile these pointers, they bypass the preprocessed tree

---

## Comparison with Other Reflaxe Compilers

### Reflaxe.CSharp Pattern
```haxe
// From reference: reflaxe.cs doesn't have this issue because:
// 1. It uses Reflaxe's built-in preprocessors (MarkUnusedVariablesImpl)
// 2. It doesn't re-compile sub-expressions in builders
// 3. Builders work with already-built AST nodes, not TypedExpr
```

### Our Deviation
```haxe
// ElixirASTBuilder.hx - We recursively build from TypedExpr
public static function buildFromTypedExpr(expr: TypedExpr, context: CompilationContext): Null<ElixirAST> {
    return switch(expr.expr) {
        case TSwitch(e, cases, edef):
            // ❌ Extracts 'e' and passes to SwitchBuilder
            SwitchBuilder.build(e, cases, edef, context);
        // ...
    }
}
```

---

## Solutions Analyzed

### Solution 1: Stop Re-compiling in Builders ✅ RECOMMENDED
**Pattern**: Builders should receive ALREADY-BUILT AST nodes, not TypedExpr

```haxe
// Current (WRONG):
public static function build(e: TypedExpr, cases: Array<...>, context: CompilationContext): Null<ElixirASTDef> {
    var targetAST = context.compiler.compileExpressionImpl(e, false);  // ❌ Re-compiles
}

// Fixed (RIGHT):
public static function build(targetAST: ElixirAST, cases: Array<...>, context: CompilationContext): Null<ElixirASTDef> {
    // ✅ Uses already-built and preprocessed AST
}
```

**Benefits**:
- Preserves preprocessor transformations
- Matches Reflaxe architecture patterns
- Prevents bypassing the compilation pipeline

**Challenges**:
- Requires refactoring all builders that currently take TypedExpr
- Need to pass pre-built AST nodes through the builder chain

---

### Solution 2: Pass Substitution Map to Builders ⚠️ WORKAROUND
**Pattern**: Store substitution map in CompilationContext

```haxe
// In CompilationContext:
var infraVarSubstitutions: Map<Int, TypedExpr> = new Map();

// In Preprocessor:
context.infraVarSubstitutions = substitutions;

// In SwitchBuilder:
var targetExpr = actualSwitchExpr;
// Check if this is a TLocal that needs substitution
switch(targetExpr.expr) {
    case TLocal(v):
        if (context.infraVarSubstitutions.exists(v.id)) {
            targetExpr = context.infraVarSubstitutions.get(v.id);
        }
}
var targetAST = context.compiler.compileExpressionImpl(targetExpr, false);
```

**Benefits**:
- Minimal changes to existing architecture
- Quick fix for immediate problem

**Drawbacks**:
- Band-aid fix, doesn't solve root architectural issue
- Every builder must remember to check substitution map
- Violates single responsibility principle

---

### Solution 3: Haxe Compiler-Level Preprocessing ❌ NOT FEASIBLE
**Pattern**: Use Haxe's built-in optimization to eliminate infrastructure vars

**Why Not Viable**:
- We don't control Haxe's internal desugaring
- Infrastructure variables are created AFTER typing, before we see the AST
- Can't prevent their creation at Haxe level

---

## Recommended Fix: Solution 1 with Phased Implementation

### Phase 1: Immediate Fix (Band-aid for testing)
Use Solution 2 to unblock development:
1. Add `infraVarSubstitutions` to CompilationContext
2. Populate in ElixirCompiler when calling preprocessor
3. Check in SwitchBuilder before compiling target expression
4. **Mark with TODO for proper fix**

### Phase 2: Architecture Refactoring (Proper fix)
Implement Solution 1 properly:
1. Change builder signatures to accept ElixirAST instead of TypedExpr
2. Build AST at ElixirASTBuilder level ONCE
3. Pass built AST nodes to specialized builders
4. Builders transform AST → AST, never TypedExpr → AST

### Phase 3: Use Reflaxe Standard Preprocessors
Replace custom TypedExprPreprocessor with Reflaxe's built-in:
1. Use `RemoveTemporaryVariablesImpl` with `AllOneUseVariables` mode
2. Use `MarkUnusedVariablesImpl` for underscore prefixing
3. Register preprocessors in ElixirCompiler.initializePreprocessors()

---

## Test-Driven Verification

### Test Case: infrastructure_variable_substitution
**Location**: `test/snapshot/regression/infrastructure_variable_substitution/`

**Haxe Input**:
```haxe
var result = switch(TestPubSub.subscribe("notifications")) {
    case Error(reason): "Failed: " + reason;
    case Ok(value): "Success: " + value;
}
```

**Intended Output** (idiomatic):
```elixir
result = case (TestPubSub.subscribe("notifications")) do
  {:error, reason} -> "Failed: " <> reason
  {:ok, value} -> "Success: " <> value
end
```

**Success Criteria**:
1. No `_g` variable in generated code
2. Direct pattern matching with `{:error, reason}` and `{:ok, value}`
3. No `elem(_g, 1)` extraction
4. Switch target is the actual function call expression

---

## Files Requiring Changes

### Immediate Fix (Phase 1)
1. **CompilationContext.hx**: Add `infraVarSubstitutions` field
2. **ElixirCompiler.hx**: Populate substitutions after preprocessor
3. **SwitchBuilder.hx**: Check substitutions before compiling target
4. **VariableBuilder.hx**: Check substitutions for TLocal references

### Proper Fix (Phase 2)
1. **ElixirASTBuilder.hx**: Build complete AST before passing to builders
2. **SwitchBuilder.hx**: Change signature to accept `targetAST: ElixirAST`
3. **LoopBuilder.hx**: Similar refactoring
4. **All specialized builders**: Accept AST, not TypedExpr

---

## Implementation Priority

1. ✅ **CRITICAL**: Add test validation - test exists, confirms failure
2. ⚠️ **HIGH**: Implement Phase 1 band-aid fix - unblock development
3. 📋 **MEDIUM**: Document architecture decision in AGENTS.md
4. 🔄 **LONG-TERM**: Implement Phase 2 proper fix - align with Reflaxe patterns

---

## References

- **Reflaxe RemoveTemporaryVariablesImpl**: `/haxe.elixir.reference/reflaxe/src/reflaxe/preprocessors/implementations/RemoveTemporaryVariablesImpl.hx`
- **TypedExprPreprocessor**: `src/reflaxe/elixir/preprocessor/TypedExprPreprocessor.hx`
- **SwitchBuilder**: `src/reflaxe/elixir/ast/builders/SwitchBuilder.hx`
- **Test Case**: `test/snapshot/regression/infrastructure_variable_substitution/`

---

## Conclusion

The infrastructure variable substitution failure is a **fundamental architecture issue**, not a simple bug. The preprocessor works correctly, but the AST building process bypasses its transformations by re-compiling original TypedExpr nodes.

**The fix requires either**:
1. Passing substitution context through the compilation pipeline (band-aid)
2. Refactoring builders to work with pre-built AST (proper solution)

**Recommendation**: Implement both - band-aid for immediate unblocking, proper fix for long-term maintainability.
