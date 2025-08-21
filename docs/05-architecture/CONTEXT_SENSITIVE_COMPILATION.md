# Context-Sensitive Expression Compilation Guidelines

**Core Compiler Development Principle for Reflaxe.Elixir**

## Overview

Context-Sensitive Expression Compilation is a fundamental architectural principle for the Reflaxe.Elixir compiler that ensures proper handling of expressions that change the compilation context, such as lambda functions, loops, closures, and pattern matching.

## The Problem

When compiling expressions that establish new scopes or change variable resolution context, naive compilation approaches can lead to:

- **Variable substitution failures** - Lambda parameters not correctly substituted in function bodies
- **Scope bleeding** - Context from one compilation phase affecting another
- **Inconsistent behavior** - Different expression types handling context differently
- **Maintenance overhead** - Duplicated context management logic across methods

### Real-World Example: Lambda Variable Substitution Bug

**Haxe Source:**
```haxe
var pending = todos.filter(function(t) return !t.completed);
```

**Incorrect Generated Elixir:**
```elixir
# ERROR: Variable "v" is undefined
Enum.filter(todos, fn item -> (!v.completed) end)
```

**Correct Generated Elixir:**
```elixir
# CORRECT: Variable properly substituted
Enum.filter(todos, fn item -> (!item.completed) end)
```

## The Core Principle

**When compiling expressions that change the compilation context, implement proper context management that:**

1. **Preserves outer scope context** - Save current compilation state before changes
2. **Establishes inner scope context** - Set up the new compilation environment properly  
3. **Restores context after compilation** - Return to previous state cleanly and safely
4. **Is reusable across expression types** - Avoid duplicating context management logic

## Architectural Solution

### 1. Centralized Context Management

Use the `ExpressionCompiler` helper class for all context-sensitive compilation:

```haxe
// ✅ CORRECT: Using centralized context management
var lambda = ExpressionCompiler.compileLambdaWithContext(this, func, "item");
return 'Enum.filter(${objStr}, fn ${lambda.paramName} -> ${lambda.body} end)';

// ❌ INCORRECT: Manual context management (prone to errors)
var previousContext = isInLoopContext;
isInLoopContext = true;
var body = compileExpressionWithTVarSubstitution(func.expr, paramTVar, paramName);
isInLoopContext = previousContext; // Easy to forget or miss in error cases
```

### 2. Context State Management

The `CompilationContext` class manages all context-related state:

```haxe
private static class CompilationContext {
    public var isInLoopContext: Bool;           // For variable substitution
    public var currentParameterMap: Map<String, String>; // For parameter mapping
    // Add more context state as needed
}
```

### 3. Safe Context Restoration

Use try-catch blocks to ensure context is always restored:

```haxe
public static function withContext<T>(compiler, context, compilationFn): T {
    // Save current state
    var previousLoopContext = compiler.isInLoopContext;
    
    // Establish new context
    compiler.isInLoopContext = context.isInLoopContext;
    
    try {
        return compilationFn();
    } catch (e: Dynamic) {
        // Ensure context is restored even if compilation fails
        compiler.isInLoopContext = previousLoopContext;
        throw e;
    }
}
```

## Implementation Guidelines

### When to Apply This Pattern

Apply context-sensitive compilation for ANY expression that:

- **Changes variable scope** - Lambda functions, closures, nested functions
- **Establishes new binding context** - Pattern matching, destructuring assignments  
- **Modifies compilation behavior** - Loop bodies, conditional compilation blocks
- **Affects variable resolution** - Import statements, namespace changes

### Expression Types Requiring Context Management

#### ✅ Lambda Expressions
```haxe
// Array methods: filter, map, find, reduce, etc.
array.filter(item -> item.isValid)
array.map(item -> transform(item))
```

#### ✅ Loop Body Compilation
```haxe
// For loops, while loops, iterator patterns
for (item in items) {
    processItem(item);
}
```

#### ✅ Pattern Matching
```haxe
// Switch expressions with complex patterns
switch (value) {
    case Some(inner): handleInner(inner);
    case None: handleNone();
}
```

#### ✅ Closure Compilation
```haxe
// Functions that capture outer scope variables
function createHandler(config) {
    return function(event) {
        handleEvent(event, config); // Captures 'config'
    };
}
```

### Code Organization Pattern

#### Main Compiler Method
```haxe
case "filter":
    if (args.length > 0) {
        switch (args[0].expr) {
            case TFunction(func):
                // Use centralized context management
                var lambda = ExpressionCompiler.compileLambdaWithContext(this, func, "item");
                return 'Enum.filter(${objStr}, fn ${lambda.paramName} -> ${lambda.body} end)';
            case _:
                return 'Enum.filter(${objStr}, ${compiledArgs[0]})';
        }
    }
```

#### Helper Class Implementation
```haxe
public static function compileLambdaWithContext(compiler, func, defaultParamName): LambdaResult {
    // 1. Extract parameter information
    var paramName = extractParameterName(func, defaultParamName);
    var paramTVar = extractParameterTVar(func);
    
    // 2. Create appropriate context
    var context = new CompilationContext(true); // Enable loop context
    
    // 3. Compile with managed context
    var body = withContext(compiler, context, () -> {
        return compiler.compileExpressionWithTVarSubstitution(func.expr, paramTVar, paramName);
    });
    
    return {paramName: paramName, body: body};
}
```

## Testing Strategy

### 1. Snapshot Tests for Context Behavior
```haxe
// test/tests/ContextSensitiveCompilation/
// - LambdaVariableSubstitution.hx
// - NestedLoopCompilation.hx  
// - PatternMatchingScope.hx
```

### 2. Integration Tests
```haxe
// Verify real-world usage in examples/todo-app
// Ensure complex expressions compile correctly
```

### 3. Error Handling Tests
```haxe
// Verify context is restored even when compilation fails
// Test exception safety in context management
```

## Benefits of This Architecture

### 1. **Correctness**
- Eliminates variable substitution bugs
- Ensures consistent scope handling
- Prevents context bleeding between expressions

### 2. **Maintainability**  
- Single point of context management
- Consistent API across all expression types
- Easy to add new context-sensitive features

### 3. **Testability**
- Can unit test context management separately
- Clear separation of concerns
- Predictable behavior in all scenarios

### 4. **Developer Experience**
- Clear guidelines for adding new expression types
- Reduced cognitive load when working with context
- Self-documenting code through helper functions

## Anti-Patterns to Avoid

### ❌ Manual Context Management
```haxe
// Don't do this - error-prone and duplicated logic
var previousContext = isInLoopContext;
isInLoopContext = true;
var result = compileExpression(expr);
isInLoopContext = previousContext; // Can be forgotten
```

### ❌ Context State in Global Variables
```haxe
// Don't do this - creates hidden dependencies
static var globalLoopContext = false;
function compileLoop() {
    globalLoopContext = true; // Affects other compilation
    // ...
}
```

### ❌ Implicit Context Changes
```haxe
// Don't do this - context changes should be explicit
function compileExpression(expr) {
    isInLoopContext = true; // Implicit side effect
    return doCompilation(expr);
}
```

## Future Considerations

### Extensibility
The context management system should be designed to easily accommodate:
- New context types (compilation modes, target-specific behavior)
- Additional context state (debugging information, optimization flags)
- Context inheritance (child contexts inheriting from parents)

### Performance
- Context creation should be lightweight
- Avoid unnecessary context copying
- Consider context pooling for high-frequency operations

### Debugging
- Context state should be easily inspectable
- Clear error messages when context management fails
- Logging capabilities for context transitions

## Implementation Checklist

When implementing new context-sensitive expressions:

- [ ] **Identify context requirements** - What compilation state needs to change?
- [ ] **Use ExpressionCompiler helpers** - Don't implement context management manually
- [ ] **Create appropriate context** - Use `createLoopContext()`, `createFunctionContext()`, etc.
- [ ] **Test context restoration** - Verify context is restored in error cases
- [ ] **Add snapshot tests** - Ensure expected output with proper context
- [ ] **Document context behavior** - Explain what context changes and why

## Examples in the Codebase

### Array Method Compilation
```haxe
// src/reflaxe/elixir/ElixirCompiler.hx - compileArrayMethod()
case "filter":
    var lambda = ExpressionCompiler.compileLambdaWithContext(this, func, "item");
    return 'Enum.filter(${objStr}, fn ${lambda.paramName} -> ${lambda.body} end)';
```

### Loop Compilation  
```haxe
// For loops that need variable substitution
var context = ExpressionCompiler.createLoopContext();
var body = ExpressionCompiler.withContext(this, context, () -> {
    return compileLoopBody(bodyExpr);
});
```

### Pattern Matching
```haxe
// Future implementation for complex pattern matching
var context = ExpressionCompiler.createPatternContext(patternBindings);
var result = ExpressionCompiler.withContext(this, context, () -> {
    return compilePatternBody(expr);
});
```

---

## Summary

Context-Sensitive Expression Compilation is a fundamental architectural principle that ensures reliable, maintainable, and correct compilation of complex expressions in Reflaxe.Elixir. By centralizing context management in the `ExpressionCompiler` helper class and following these guidelines, we can:

1. **Eliminate context-related bugs** like variable substitution failures
2. **Maintain consistent behavior** across all expression types  
3. **Simplify future development** with clear patterns and helpers
4. **Improve code quality** through better separation of concerns

This principle should guide all future compiler development work involving expressions that change compilation context.