# Lambda Variable Substitution Architecture

## Problem Statement

When Haxe compiles array methods like `filter()` and `map()`, it internally transforms them into for-loops with temporary variables. This transformation can create variable scoping issues where the lambda parameter name doesn't match the variables referenced in the lambda body.

### Example Issue

**Haxe Source**:
```haxe
var todos = [{id: 1}, {id: 2}];
var id = 2;
var filtered = todos.filter(function(item) return item.id != id);
```

**Broken Elixir Output** (before fix):
```elixir
Enum.filter(todos, fn item -> (item.id != item) end)  # ❌ Wrong: item != item
```

**Correct Elixir Output** (after fix):
```elixir
Enum.filter(todos, fn item -> (item.id != id) end)   # ✅ Right: item != id
```

## Root Cause Analysis

### Haxe's Array Method Desugaring

Haxe transforms array methods through several stages:

1. **Original Code**: `todos.filter(function(item) return item.id != id)`
2. **Desugared Form**: TFor loop with temporary variables like `v`, `t`, etc.
3. **Variable Renaming**: Haxe may rename variables to avoid shadowing (`v` → `v2`)
4. **Our Compiler**: Must reverse this process and generate clean lambda code

### The Variable Mismatch Problem

The issue occurs because:
1. **Lambda Parameter**: We generate `fn item ->` (standardized parameter name)
2. **Lambda Body**: Contains references to Haxe's temporary variables (`v`, `t`, etc.)
3. **Result**: `fn item -> v.id != id` where `v` is undefined in lambda scope

## Architecture Solution

### Three-Path Variable Substitution System

The solution uses three different compilation paths with targeted variable substitution:

```haxe
// Path 1: TFor expressions (direct for-loops)
case TFor(tvar, iterExpr, blockExpr):
    compileForLoop(tvar, iterExpr, blockExpr);

// Path 2: TWhile expressions (optimized to for-in patterns)  
case TWhile(econd, ebody, normalWhile):
    var optimized = tryOptimizeForInPattern(econd, ebody);

// Path 3: TCall expressions (direct array method calls)
case TCall(e, el):
    compileMethodCall(e, el);
```

### Key Functions

#### 1. Variable Detection: `findFirstLocalVariable()`

Detects which variable in the lambda body should be substituted:

```haxe
private function findFirstLocalVariable(expr: TypedExpr): Null<String> {
    switch (expr.expr) {
        case TLocal(v):
            var varName = getOriginalVarName(v);
            if (!isSystemVariable(varName)) {
                return varName; // Found the loop variable
            }
        case TField(e, fa):
            return findFirstLocalVariable(e); // Check field access base
        case TBinop(op, e1, e2):
            // Check both operands, prefer left side
            var left = findFirstLocalVariable(e1);
            if (left != null) return left;
            return findFirstLocalVariable(e2);
        // ... handle other expression types
    }
    return null;
}
```

#### 2. Variable Substitution: `compileExpressionWithSubstitution()`

Recursively replaces variables in the lambda body:

```haxe
private function compileExpressionWithSubstitution(expr: TypedExpr, sourceVar: String, targetVar: String): String {
    switch (expr.expr) {
        case TLocal(v):
            var varName = getOriginalVarName(v);
            if (shouldSubstituteVariable(varName, sourceVar, false)) {
                // Variable substitution successful - replace with lambda parameter
                return targetVar;
            }
            // Not a match - compile normally
            return compileExpression(expr);
            
        case TBinop(op, e1, e2):
            // Handle assignment operations specially
            if (op == OpAssign) {
                // For assignments in ternary contexts, return just the right-hand side value
                return compileExpressionWithSubstitution(e2, sourceVar, targetVar);
            }
            // Recursively substitute in both operands
            var left = compileExpressionWithSubstitution(e1, sourceVar, targetVar);
            var right = compileExpressionWithSubstitution(e2, sourceVar, targetVar);
            return '${left} ${compileBinop(op)} ${right}';
            
        case TField(e, fa):
            // Substitute in the base expression
            var baseExpr = compileExpressionWithSubstitution(e, sourceVar, targetVar);
            return compileFieldAccessWithBase(baseExpr, fa);
            
        // ... handle all other expression types recursively
    }
}
```

#### 3. Pattern Generation Functions

Generate clean Enum operations with correct variable scoping:

```haxe
private function generateEnumFilterPattern(arrayExpr: String, loopVar: String, conditionExpr: TypedExpr): String {
    var targetVar = NamingHelper.toSnakeCase(loopVar);
    var referencedVar = findFirstLocalVariable(conditionExpr);
    
    var condition: String;
    if (referencedVar != null && referencedVar != targetVar) {
        // Apply substitution to fix variable references
        condition = compileExpressionWithSubstitution(conditionExpr, referencedVar, targetVar);
    } else {
        // No substitution needed
        condition = compileExpression(conditionExpr);
    }
    
    return 'Enum.filter(${arrayExpr}, fn ${targetVar} -> ${condition} end)';
}
```

### Variable Name Preservation

#### Original Name Recovery

Haxe renames variables to avoid shadowing, but preserves original names in metadata:

```haxe
private function getOriginalVarName(v: TVar): String {
    // TVar has both name and meta properties, so we can use the helper
    return v.getNameOrMeta(":realPath");
}
```

This ensures we work with the developer's intended variable names, not Haxe's internal renamed versions.

#### System Variable Filtering

```haxe
private function isSystemVariable(varName: String): Bool {
    // Filter out Haxe-generated variables
    return switch (varName) {
        case "_g" | "_this" | "temp_array" | "temp_result": true;
        case name if (name.startsWith("_g")): true;  
        case name if (name.startsWith("temp_")): true;
        case _: false;
    };
}
```

## Implementation Patterns

### Safe Substitution Logic

```haxe
private function shouldSubstituteVariable(varName: String, sourceVar: String, aggressive: Bool): Bool {
    // 1. Exact name match (most reliable)
    if (varName == sourceVar && varName != null) {
        return true;
    }
    
    // 2. Common loop variable patterns (when aggressive)
    if (aggressive && (varName == "t" || varName == "v" || varName == "item")) {
        // Safety check: don't substitute critical variables
        return !isExcludedVariable(varName);
    }
    
    return false;
}
```

### Integration Points

#### Array Method Compilation

```haxe
case TCall(e, el) if (isArrayMethodCall(e)):
    switch (getMethodName(e)) {
        case "filter":
            return compileArrayMethod(e, el, "filter");
        case "map":
            return compileArrayMethod(e, el, "map");
        // ... other methods
    }
```

#### For-Loop Optimization

```haxe
case TFor(tvar, iterExpr, blockExpr):
    var varName = getOriginalVarName(tvar);
    trace('Processing TFor: tvar=${varName}');
    return compileForLoop(tvar, iterExpr, blockExpr);
```

## Test Coverage

### Lambda Variable Substitution Test

**Location**: `test/tests/LambdaVariableScope/`

**Key Test Cases**:
1. **Filter with outer variable**: `items.filter(item -> item != targetItem)`
2. **Map with outer variable**: `numbers.map(n -> n * multiplier)`  
3. **Field access patterns**: `todos.filter(item -> item.id != id)`
4. **Nested operations**: Complex lambda expressions with multiple scopes
5. **Multiple outer variables**: References to several outer scope variables

**Critical Lines to Verify**:
- Line 24: `Enum.filter(items, fn item -> (item != target_item) end)`
- Line 31: `Enum.filter(todos, fn item -> (item.id != id) end)`
- Line 86: `Enum.filter(items, fn item -> (item != exclude_item) end)`

If these lines show `item != item`, the lambda substitution has regressed.

## Debugging and Troubleshooting

### Common Issues

**Issue**: Lambda shows `item != item` instead of `item != outerVar`
**Cause**: Variable substitution not detecting outer scope variables
**Fix**: Check `findFirstLocalVariable()` is finding the right variables

**Issue**: Variables not being substituted at all  
**Cause**: `shouldSubstituteVariable()` not matching variable names
**Fix**: Verify original name recovery and pattern matching logic

**Issue**: Over-substitution replacing wrong variables
**Cause**: Aggressive substitution without proper safety checks
**Fix**: Enhance `isExcludedVariable()` and tighten substitution rules

### Debug Commands

```bash
# Test lambda variable substitution specifically
haxe test/Test.hxml test=LambdaVariableScope

# Check for regressions in generated code
haxe test/Test.hxml test=LambdaVariableScope show-output

# Compile todo-app to test real-world usage
cd examples/todo-app && npx haxe build.hxml
```

### Verification Points

After any changes to variable substitution logic, verify:

1. **LambdaVariableScope test passes**: Validates core substitution logic
2. **Todo-app compiles cleanly**: Real-world usage works  
3. **Generated lambda code correct**: Manual inspection of key functions
4. **No debug traces**: Clean compilation output

## Future Enhancements

### Potential Improvements

1. **Better Variable Detection**: Use type information to improve variable matching
2. **Context-Aware Substitution**: Consider expression context for smarter substitution
3. **Performance Optimization**: Cache variable analysis results
4. **Enhanced Safety**: More sophisticated checks for variable safety

### Maintenance Notes

- **Keep substitution logic simple**: Avoid over-engineering complex detection
- **Test thoroughly**: Lambda scoping is easy to break, hard to debug
- **Document changes**: Variable substitution logic is subtle and hard to understand
- **Monitor regressions**: Use LambdaVariableScope test as early warning system

## Related Documentation

- **[TESTING_PRINCIPLES.md](TESTING_PRINCIPLES.md)** - How to test variable substitution changes
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Overall compiler architecture
- **[HAXE_MACRO_APIS.md](HAXE_MACRO_APIS.md)** - Haxe macro API usage patterns
- **[FUNCTIONAL_PATTERNS.md](FUNCTIONAL_PATTERNS.md)** - Functional programming transformations