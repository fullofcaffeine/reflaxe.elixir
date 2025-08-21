# TVar vs String Substitution in Variable Replacement

## Overview

This document explains the critical distinction between TVar-based and string-based variable substitution in the Reflaxe.Elixir compiler, particularly for lambda parameter replacement in array methods.

## The Problem That Led to This Solution

When compiling array methods like `filter`, `map`, etc., the compiler generates lambda expressions where the parameter variable needs to be substituted correctly:

```haxe
// Haxe source
items.filter(item -> !item.completed)

// Should generate
Enum.filter(items, fn item -> (!item.completed) end)

// NOT generate (undefined variable error)
Enum.filter(items, fn item -> (!v.completed) end)
```

## TVar-Based Substitution (✅ CORRECT APPROACH)

### What it is
TVar-based substitution uses Haxe's actual `TVar` objects to identify and replace variables based on their **unique object identity**, not their names.

### How it works
```haxe
// In compileExpressionWithTVarSubstitution()
case TLocal(v):
    trace('TVar substitution: Found TLocal ${v.name} (id: ${v.id}), looking for ${sourceTVar.name} (id: ${sourceTVar.id})');
    if (v == sourceTVar) {  // Object identity comparison
        trace('TVar substitution: Exact match! Replacing with ${targetVarName}');
        return targetVarName;
    }
```

### Key advantages
1. **Precise identification**: Uses object identity (`v == sourceTVar`), not name matching
2. **Scope-aware**: Correctly handles variable shadowing and nested scopes
3. **Reliable**: Immune to name collisions and variable reuse
4. **Type-safe**: Leverages Haxe's type system guarantees

### Implementation location
- `ElixirCompiler.compileExpressionWithTVarSubstitution()`
- Used by `generateEnumFilterPattern`, `generateEnumMapPattern`, etc.

## String-Based Substitution (❌ PROBLEMATIC APPROACH)

### What it is  
String-based substitution attempts to replace variables by matching their **names** as strings.

### How it worked (before fix)
```haxe
// In old string-based approach
function compileExpression(expr, substituteVar, replacementName) {
    // Convert to string, then do text replacement
    var result = basicCompile(expr);
    return result.replace(substituteVar, replacementName);  // Fragile!
}
```

### Why it fails
1. **Name ambiguity**: Multiple variables can have the same name in different scopes
2. **False positives**: Might replace unrelated variables with same name
3. **Context-blind**: No understanding of variable scope or binding
4. **Fragile**: Breaks with variable shadowing, closures, complex expressions

## Practical Example: The Fixed Code

### Before (String-based) - Generated broken code:
```elixir
Enum.filter(_this, fn item -> (!v.completed) end)  # ❌ Undefined variable v
```

### After (TVar-based) - Generates correct code:
```elixir
Enum.filter(_this, fn item -> (!item.completed) end)  # ✅ Correct variable item
```

## Technical Implementation Details

### TVar Object Structure
```haxe
// TVar represents a typed variable in Haxe's AST
class TVar {
    public var id: Int;          // Unique identifier
    public var name: String;     // Display name
    public var type: Type;       // Variable type
    // ... other fields
}
```

### Method Signature
```haxe
/**
 * Compile expression with TVar-based variable substitution
 * 
 * @param expr The expression to compile
 * @param sourceTVar The TVar object to replace
 * @param targetVarName The replacement variable name
 * @return Compiled expression string with substitutions
 */
function compileExpressionWithTVarSubstitution(
    expr: TypedExpr, 
    sourceTVar: TVar, 
    targetVarName: String
): String
```

### Helper Method for TVar Discovery
```haxe
/**
 * Find the first local variable TVar in an expression
 * 
 * @param expr Expression to search
 * @return TVar object or null if none found
 */
function findFirstLocalTVar(expr: TypedExpr): Null<TVar>
```

## Usage Pattern in Array Methods

### Standard Pattern
```haxe
case "filter":
    if (args.length > 0) {
        switch (args[0].expr) {
            case TFunction(func):
                // Use TVar-based substitution for lambda compilation
                var lambda = ExpressionCompiler.compileLambdaWithContext(this, func, "item");
                return 'Enum.filter(${objStr}, fn ${lambda.paramName} -> ${lambda.body} end)';
        }
    }
```

### Context Management
```haxe
// ExpressionCompiler manages context properly
public static function compileLambdaWithContext(
    compiler: Dynamic, 
    func: TFunc, 
    defaultParamName: String = "item"
): LambdaResult {
    var context = createCompilationContext(true);  // isInLoopContext = true
    var paramTVar = findFirstLocalTVar(func.expr);
    var paramName = defaultParamName;
    
    var body = withContext(compiler, context, () -> {
        return paramTVar != null ? 
            compiler.compileExpressionWithTVarSubstitution(func.expr, paramTVar, paramName) :
            compiler.compileExpression(func.expr);
    });
    
    return {paramName: paramName, body: body};
}
```

## Debugging and Verification

### Debug Traces
The TVar-based system includes comprehensive tracing:
```haxe
trace('TVar substitution: Found TLocal ${v.name} (id: ${v.id}), looking for ${sourceTVar.name} (id: ${sourceTVar.id})');
trace('TVar substitution: Exact match! Replacing with ${targetVarName}');
```

### Verification in Generated Code
Check that lambda parameters are correctly substituted:
```elixir
# ✅ CORRECT: item is the lambda parameter
Enum.filter(list, fn item -> item.active end)

# ❌ WRONG: undefined variable reference  
Enum.filter(list, fn item -> v.active end)
```

## Related Documentation

- [`documentation/CONTEXT_SENSITIVE_COMPILATION.md`](CONTEXT_SENSITIVE_COMPILATION.md) - Overall compilation context architecture
- [`documentation/helpers/EXPRESSION_COMPILER.md`](helpers/EXPRESSION_COMPILER.md) - ExpressionCompiler implementation details
- [`documentation/COMPILER_BEST_PRACTICES.md`](COMPILER_BEST_PRACTICES.md) - General compiler development practices

## Key Takeaways

1. **Always use TVar objects for variable identification** - they provide unique, scope-aware identity
2. **Never rely on string names for variable substitution** - names can be ambiguous and misleading
3. **Leverage Haxe's type system** - TVar objects carry complete type and scope information
4. **Test with complex expressions** - nested scopes, shadowing, and closures reveal substitution bugs
5. **Use proper debugging** - trace TVar IDs and object identity for precise debugging

## Implementation History

- **Original Issue**: Array filter operations generated `fn item -> (!v.completed) end` with undefined variable `v`
- **Root Cause**: String-based substitution in `generateEnumFilterPattern` and related methods
- **Solution**: Implemented TVar-based substitution using object identity comparison
- **Result**: Correct generation of `fn item -> (!item.completed) end` with proper variable scoping

This architectural improvement applies to all array methods and any future lambda compilation scenarios requiring variable substitution.