# Infrastructure Variable Elimination: Architectural Analysis & Recommendations

**Date**: January 1, 2025
**Expert**: Haxe-Reflaxe Compiler Specialist
**Issue**: Infrastructure variable elimination failure with intervening control flow statements

---

## 1. Problem Analysis: Root Cause

### What's Actually Happening

When Haxe compiles `switch(msg.type)`, it generates:

```haxe
// TypedExpr (Haxe's internal representation)
TBlock([
  TVar(_g, msg.type),          // Infrastructure variable creation
  TSwitch(TLocal(_g), cases)   // Switch uses the infrastructure variable
])
```

**TypedExprPreprocessor's Current Logic**:
1. Detects `TVar(_g, init)` followed immediately by `TSwitch(TLocal(_g))`
2. Eliminates the `TVar` node entirely
3. Stores mapping: `_g` → `msg.type`
4. Returns transformed switch with inlined expression

**The Bug**:
```haxe
// With intervening statement
TBlock([
  TIf(validation, TReturn(None)),  // Intervening statement
  TVar(_g, msg.type),               // Preprocessor eliminates this
  TReturn(TSwitch(TLocal(_g)))      // But _g is still referenced!
])
```

The preprocessor's pattern detection **only looks for adjacent expressions**. When statements intervene:
- `TVar(_g)` is still eliminated
- Substitution is registered
- But the `TReturn` wrapper prevents substitution from being applied
- Result: `_g` undefined at runtime

---

## 2. Research Findings: How Reflaxe Solves This

### Key Discovery: Reflaxe Uses Different Architecture

After examining `$HAXE_ELIXIR_REFERENCE_PATH/reflaxe/` (optional local checkout), I found:

#### RemoveTemporaryVariablesImpl Pattern

```haxe
// From reflaxe/src/reflaxe/preprocessors/implementations/RemoveTemporaryVariablesImpl.hx
class RemoveTemporaryVariablesImpl {
    var tvarMap: Map<Int, TypedExpr> = [];  // Maps variable ID → expression

    public function fixTemporaries(): TypedExpr {
        function mapTypedExpr(mappedExpr, noReplacements): TypedExpr {
            switch(mappedExpr.expr) {
                case TLocal(v) if(!noReplacements): {
                    final e = findReplacement(v.id);  // Uses variable ID, not name!
                    if(e != null) return e.wrapParenthesisIfOrderSensitive();
                }
                case TBlock(_): {
                    // Creates new instance for nested scope
                    final tvr = new RemoveTemporaryVariablesImpl(mode, mappedExpr, varUsageCount);
                    tvr.parent = this;  // Inherits parent substitutions
                    return tvr.fixTemporaries();
                }
            }
            return haxe.macro.TypedExprTools.map(mappedExpr, e -> mapTypedExpr(e, noReplacements));
        }

        // Process each expression
        for(i in 0...exprList.length) {
            if(shouldRemoveVariable(tvar, maybeExpr)) {
                tvarMap.set(tvar.id, mapTypedExpr(maybeExpr.trustMe(), false));
                continue;  // Skip the TVar in output
            }
            result.push(mapTypedExpr(exprList[i], parent == null && !hasOverload));
        }
    }
}
```

**Critical Differences from TypedExprPreprocessor**:

1. **Uses TVar.id (unique identifier) instead of string names**
   - Prevents name collision issues
   - Handles scope shadowing correctly

2. **Processes entire block sequentially, not pattern-matching pairs**
   - Doesn't require adjacent expressions
   - Handles intervening statements naturally

3. **Parent/child scoping for nested blocks**
   - Each nested block creates new instance
   - Inherits parent substitutions
   - Prevents scope leakage

4. **Applies substitutions during AST traversal, not after**
   - Uses `TypedExprTools.map()` to recursively transform
   - Substitutes at every TLocal site immediately
   - No "store then apply later" approach

---

## 3. Architectural Recommendation: Use Reflaxe's Pattern

### Why TypedExprPreprocessor's Approach is Flawed

**Fundamental Issues**:

1. **Pattern-Based Detection is Brittle**
   - Assumes specific expression ordering (TVar + TSwitch)
   - Breaks with intervening statements
   - Doesn't handle complex control flow

2. **String-Based Mapping is Fragile**
   - Stores `varName` → `expression`
   - Must handle stripped/unstripped names separately
   - Scope shadowing causes collisions

3. **Two-Phase Processing is Error-Prone**
   - Phase 1: Detect patterns, store substitutions
   - Phase 2: Apply substitutions
   - Gap between detection and application allows bugs

### Recommended Architecture: Scope-Aware Substitution

```haxe
class InfrastructureVariableEliminator {
    // Use TVar.id (unique), not name (can shadow)
    var substitutions: Map<Int, TypedExpr>;
    var parent: Null<InfrastructureVariableEliminator>;

    public function eliminate(expr: TypedExpr): TypedExpr {
        return switch(expr.expr) {
            // Detect infrastructure variable declarations
            case TVar(v, init) if (isInfrastructureVar(v.name) && shouldEliminate(v, init)):
                // Store substitution
                substitutions.set(v.id, init);
                // Return empty block to skip this declaration
                {expr: TBlock([]), pos: expr.pos, t: expr.t};

            // Apply substitutions at TLocal sites
            case TLocal(v):
                if (substitutions.exists(v.id)) {
                    substitutions.get(v.id);  // Replace with original expression
                } else if (parent != null) {
                    parent.findSubstitution(v.id);  // Check parent scope
                } else {
                    expr;  // No substitution found
                }

            // Create nested scope for blocks
            case TBlock(exprs):
                var child = new InfrastructureVariableEliminator();
                child.parent = this;
                var transformed = exprs.map(e -> child.eliminate(e));
                {expr: TBlock(transformed), pos: expr.pos, t: expr.t};

            // Recursively process all other expressions
            default:
                haxe.macro.TypedExprTools.map(expr, e -> eliminate(e));
        };
    }

    function shouldEliminate(v: TVar, init: TypedExpr): Bool {
        // Only eliminate if:
        // 1. Single use (checked via usage analysis)
        // 2. Simple expression (not control flow)
        // 3. No side effects
        return isSingleUse(v) && isSimpleExpr(init) && !hasSideEffects(init);
    }
}
```

---

## 4. Implementation Strategy

### Phase 1: Fix Current Preprocessor (Short-Term)

**Goal**: Make TypedExprPreprocessor handle intervening statements

```haxe
// In processBlock(), change from:
if (i < exprs.length - 1) {
    switch(current.expr) {
        case TVar(v, init) if (isInfrastructureVar(v.name)):
            var next = exprs[i + 1];  // ❌ Only checks immediate next

// To:
if (containsInfrastructureVar(current)) {
    switch(current.expr) {
        case TVar(v, init) if (isInfrastructureVar(v.name)):
            // ✅ Register substitution immediately
            substitutions.set(v.name, init);
            // Let recursive processing handle all usages
            i++;
            continue;
```

**Key Changes**:
1. Don't require adjacent expressions
2. Register substitutions when TVar is found
3. Apply substitutions recursively via `processExpr()`
4. Remove pattern-matching assumption

### Phase 2: Migrate to Reflaxe Pattern (Long-Term)

**Goal**: Replace with scope-aware, ID-based approach

**Steps**:

1. **Create new implementation following Reflaxe pattern**
   ```haxe
   // src/reflaxe/elixir/preprocessor/InfrastructureVariableEliminator.hx
   class InfrastructureVariableEliminator {
       // Use architecture from RemoveTemporaryVariablesImpl
   }
   ```

2. **Add usage analysis first**
   ```haxe
   // Count how many times each variable is used
   var usageCount = countVariableUsages(expr);

   // Only eliminate single-use infrastructure variables
   if (usageCount.get(v.id) == 1) {
       substitutions.set(v.id, init);
   }
   ```

3. **Use TVar.id instead of names**
   ```haxe
   // ✅ RIGHT: Unique identifier
   substitutions.set(tvar.id, expr);

   // ❌ WRONG: Name can shadow
   substitutions.set(tvar.name, expr);
   ```

4. **Test incrementally**
   - Keep both implementations during migration
   - Use feature flag to switch between them
   - Validate all tests pass with new implementation
   - Remove old code only when confident

### Phase 3: AST-Level Alternative (Optional)

**When preprocessing isn't enough**, move to AST transformation:

```haxe
// In ElixirASTTransformer.hx
function infrastructureVariableEliminationPass(ast: ElixirAST): ElixirAST {
    return switch(ast.def) {
        // Detect pattern at AST level
        case EBlock(exprs):
            var cleaned = [];
            var infVars = new Map<String, ElixirAST>();

            for (expr in exprs) {
                switch(expr.def) {
                    case EMatch(EVar(name), value) if (isInfrastructureVar(name)):
                        // Store for substitution
                        infVars.set(name, value);
                        // Don't add to output
                    default:
                        // Substitute uses and add to output
                        cleaned.push(substituteInfVars(expr, infVars));
                }
            }

            makeAST(EBlock(cleaned));

        default:
            transformNode(ast, infrastructureVariableEliminationPass);
    };
}
```

**Advantages**:
- Works on ElixirAST (already Elixir-structured)
- Can use metadata from builder phase
- More control over Elixir-specific patterns

**Disadvantages**:
- Haxe semantic information is lost
- TypedExpr is closer to source intent
- AST transformations are harder to debug

---

## 5. Comparison: TypedExpr Preprocessing vs AST Transformation

| Aspect | TypedExpr Preprocessing | AST Transformation |
|--------|------------------------|-------------------|
| **Timing** | Before AST building | After AST building |
| **Input** | Haxe TypedExpr | ElixirAST |
| **Type Info** | Full Haxe types | Metadata only |
| **Complexity** | Lower (Haxe patterns) | Higher (Elixir patterns) |
| **Debugging** | Easier (closer to source) | Harder (intermediate form) |
| **Control** | Limited (Haxe semantics) | Full (Elixir idioms) |
| **Precedent** | Reflaxe standard | Less common |

**Recommendation**: **Stay with TypedExpr preprocessing** but adopt Reflaxe's architecture.

**Why**:
- Reflaxe's RemoveTemporaryVariablesImpl proves it works
- Preserves type information for better decisions
- Easier to debug (closer to Haxe source)
- AST transformation should be reserved for Elixir-specific idioms

---

## 6. Scope-Aware Pattern Detection

### The Problem with Current Pattern Detection

```haxe
// Current: Assumes adjacent expressions
if (i < exprs.length - 1) {
    switch(current.expr) {
        case TVar(v, init):
            var next = exprs[i + 1];  // ❌ Only checks next
            switch(next.expr) {
                case TSwitch(e, _) if (usesVariable(e, v.name)):
                    // Pattern detected
```

**Issues**:
- Breaks with any intervening statement
- Can't handle:
  - Logging: `TVar(_g, expr); trace("debug"); TSwitch(TLocal(_g))`
  - Validation: `TVar(_g, expr); TIf(check); TSwitch(TLocal(_g))`
  - Multiple vars: `TVar(_g, e1); TVar(_g1, e2); TSwitch(TLocal(_g))`

### Correct Approach: Scope-Aware Substitution

```haxe
// Process each expression sequentially
for (expr in exprs) {
    switch(expr.expr) {
        case TVar(v, init) if (isInfrastructureVar(v.name)):
            // Analyze usage first
            if (isSingleUse(v) && isSimpleExpr(init)) {
                substitutions.set(v.id, init);  // Store for later
                continue;  // Skip in output
            }

        default:
            // Apply substitutions recursively
            processed.push(applySubstitutions(expr, substitutions));
    }
}
```

**Benefits**:
- Doesn't depend on expression order
- Handles any intervening statements
- Uses variable ID (unique, scope-safe)
- Applies substitutions at every TLocal site

---

## 7. Preventing "TVar Eliminated But TLocal Still References" Bug

### Root Cause

**Current bug mechanism**:
1. Preprocessor finds `TVar(_g, init)`
2. Eliminates TVar (returns `TBlock([])`)
3. Stores substitution mapping
4. **BUT** substitution isn't applied everywhere:
   - Works: `TSwitch(TLocal(_g))` → substituted
   - Fails: `TReturn(TSwitch(TLocal(_g)))` → NOT substituted
   - Fails: `TIf(cond, TSwitch(TLocal(_g)))` → NOT substituted

### The Fix: Recursive Substitution

```haxe
function processExpr(expr: TypedExpr, subs: Map<Int, TypedExpr>): TypedExpr {
    return switch(expr.expr) {
        // 1. Apply substitution at EVERY TLocal site
        case TLocal(v):
            subs.exists(v.id) ? subs.get(v.id) : expr;

        // 2. Create nested scope for blocks
        case TBlock(exprs):
            var childSubs = createChildScope(subs);
            var transformed = exprs.map(e -> processExpr(e, childSubs));
            {expr: TBlock(transformed), pos: expr.pos, t: expr.t};

        // 3. Recursively process everything else
        default:
            haxe.macro.TypedExprTools.map(expr, e -> processExpr(e, subs));
    };
}
```

**Guarantees**:
- Every `TLocal` is checked for substitution
- Nested blocks create child scopes
- No "missed" references possible

---

## 8. Safe Elimination Criteria

### Not All Infrastructure Variables Should Be Eliminated

```haxe
function shouldEliminate(v: TVar, init: TypedExpr, usageCount: Int): Bool {
    // Safety checks
    if (!isInfrastructureVar(v.name)) return false;
    if (init == null) return false;

    // Only eliminate if:
    return usageCount == 1                    // Single use
        && !hasSideEffects(init)              // No side effects
        && !isComplexExpr(init)               // Simple expression
        && !isInSensitivePosition(init);      // Not order-sensitive
}

function hasSideEffects(expr: TypedExpr): Bool {
    return switch(expr.expr) {
        case TCall(_, _): true;               // Function call
        case TBinop(OpAssign | OpAssignOp(_), _, _): true;  // Assignment
        case TUnop(OpIncrement | OpDecrement, _, _): true;  // Mutation
        case TNew(_, _): true;                // Object creation
        default: false;
    };
}

function isComplexExpr(expr: TypedExpr): Bool {
    return switch(expr.expr) {
        case TIf(_, _, _): true;              // Conditional
        case TSwitch(_, _, _): true;          // Switch
        case TWhile(_, _, _): true;           // Loop
        case TFor(_, _, _): true;             // Loop
        default: false;
    };
}
```

---

## 9. Implementation Checklist

### Immediate Fix (TypedExprPreprocessor)

- [ ] Change from adjacency-based to sequential processing
- [ ] Store substitutions immediately when TVar found
- [ ] Use `TypedExprTools.map()` for recursive substitution
- [ ] Apply substitutions at EVERY `TLocal` site
- [ ] Add safety checks (usage count, side effects)
- [ ] Test with intervening statements

### Long-Term Migration (Reflaxe Pattern)

- [ ] Create `InfrastructureVariableEliminator` class
- [ ] Use `TVar.id` instead of `name` for substitutions
- [ ] Implement parent/child scoping
- [ ] Add usage count analysis
- [ ] Feature-flag both implementations
- [ ] Migrate incrementally with full test coverage
- [ ] Remove old preprocessor when confident

### Validation

- [ ] Test: Infrastructure var with intervening TIf
- [ ] Test: Infrastructure var with intervening TReturn
- [ ] Test: Multiple infrastructure vars in same block
- [ ] Test: Nested blocks with shadowing
- [ ] Test: Infrastructure var with side effects (don't eliminate)
- [ ] Test: Infrastructure var with multiple uses (don't eliminate)

---

## 10. Final Recommendation

### Short-Term (This Week)

**Fix TypedExprPreprocessor** to handle intervening statements:

1. Remove adjacency requirement
2. Use recursive substitution with `TypedExprTools.map()`
3. Apply substitutions at every `TLocal` site
4. Add usage analysis to prevent multi-use elimination

**Estimated Effort**: 4-6 hours

### Long-Term (Next Month)

**Migrate to Reflaxe's pattern**:

1. Adopt ID-based substitution (not name-based)
2. Implement parent/child scoping
3. Add comprehensive safety checks
4. Feature-flag migration for gradual rollout

**Estimated Effort**: 2-3 days

### Why This Approach

**Advantages**:
- ✅ Proven architecture (Reflaxe uses it successfully)
- ✅ Handles complex control flow naturally
- ✅ Scope-safe (uses variable IDs)
- ✅ Incremental migration (feature-flagged)
- ✅ Preserves type information (TypedExpr level)

**Avoids**:
- ❌ AST-level complexity (save for Elixir-specific transforms)
- ❌ Brittle pattern matching (order-dependent)
- ❌ String-based naming (scope collisions)
- ❌ Two-phase processing (detection vs application gap)

---

## 11. Code Example: Complete Fix

```haxe
// src/reflaxe/elixir/preprocessor/TypedExprPreprocessor.hx

/**
 * FIXED: Scope-aware infrastructure variable elimination
 *
 * CHANGES FROM ORIGINAL:
 * 1. Uses TVar.id (unique) instead of name (can shadow)
 * 2. Applies substitutions recursively at every TLocal site
 * 3. No adjacency requirement - handles intervening statements
 * 4. Parent/child scoping for nested blocks
 */
class TypedExprPreprocessor {
    var substitutions: Map<Int, TypedExpr>;
    var parent: Null<TypedExprPreprocessor>;

    public static function preprocess(expr: TypedExpr): TypedExpr {
        var processor = new TypedExprPreprocessor();
        return processor.process(expr);
    }

    function new(?parent: TypedExprPreprocessor) {
        this.substitutions = new Map();
        this.parent = parent;
    }

    function process(expr: TypedExpr): TypedExpr {
        return switch(expr.expr) {
            // Eliminate infrastructure variable declarations
            case TVar(v, init) if (isInfrastructureVar(v.name) && shouldEliminate(v, init)):
                substitutions.set(v.id, init);  // Use ID, not name!
                {expr: TBlock([]), pos: expr.pos, t: expr.t};  // Skip in output

            // Apply substitutions at TLocal sites
            case TLocal(v):
                findSubstitution(v.id);  // Checks this + parent scopes

            // Create nested scope for blocks
            case TBlock(exprs):
                var child = new TypedExprPreprocessor(this);
                var transformed = exprs.map(e -> child.process(e));
                {expr: TBlock(transformed), pos: expr.pos, t: expr.t};

            // Recursively process all other expressions
            default:
                haxe.macro.TypedExprTools.map(expr, e -> process(e));
        };
    }

    function findSubstitution(varId: Int): TypedExpr {
        if (substitutions.exists(varId)) {
            return substitutions.get(varId);
        } else if (parent != null) {
            return parent.findSubstitution(varId);
        } else {
            return null;  // No substitution found
        }
    }

    function shouldEliminate(v: TVar, init: TypedExpr): Bool {
        // TODO: Add usage count analysis
        // For now, conservatively eliminate only simple expressions
        return isSimpleExpr(init) && !hasSideEffects(init);
    }
}
```

---

## Conclusion

The current TypedExprPreprocessor's adjacency-based pattern detection is **fundamentally flawed**. The fix is to adopt Reflaxe's proven scope-aware substitution architecture:

1. **Use variable IDs**, not names
2. **Apply substitutions recursively** at every TLocal site
3. **Don't require adjacency** - process sequentially
4. **Implement parent/child scoping** for nested blocks
5. **Add usage analysis** to prevent unsafe elimination

This architecture is proven (RemoveTemporaryVariablesImpl), maintainable, and correctly handles complex control flow.
