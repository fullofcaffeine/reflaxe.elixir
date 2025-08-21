# Macro Development Principles for Reflaxe.Elixir

## 🎯 Overview

This document establishes core principles for developing Haxe macros in the Reflaxe.Elixir project, based on lessons learned from implementing features like async/await, build macros, and AST transformations.

## Table of Contents

1. [Core Principles](#core-principles)
2. [AST Manipulation Best Practices](#ast-manipulation-best-practices)
3. [Build Macro Architecture](#build-macro-architecture)
4. [Type System Integration](#type-system-integration)
5. [Error Handling](#error-handling)
6. [Testing Strategy](#testing-strategy)
7. [Performance Considerations](#performance-considerations)

## Core Principles

### 1. AST Preservation Over String Manipulation

**Principle**: Keep AST nodes (TypedExpr/Expr) as long as possible before converting to strings.

**Why**: AST provides structural information for proper transformations.

**Good**:
```haxe
// Work with AST structures
var transformedBody = processAwaitInExpr(func.expr);
var newExpr = transformAnonymousFunctionBody(transformedBody, pos);
```

**Bad**:
```haxe
// Convert to string too early
var stringBody = func.expr.toString();
var processed = stringBody.replace("await", "js.Syntax.code(\"await\")");
```

### 2. Stateless Transformation Functions

**Principle**: Design transformation functions to be stateless and independent.

**Why**: Build macros process each class individually and cannot share state.

**Implementation**:
```haxe
// Good: Stateless function
static function transformAsyncFunction(field: Field, func: Function): Field {
    // All data comes from parameters
    // No static variables or shared state
}

// Bad: Stateful transformation
static var processedFunctions: Array<String> = [];
static function transformAsyncFunction(field: Field, func: Function): Field {
    processedFunctions.push(field.name); // State that doesn't work across classes
}
```

### 3. Context-Aware Transformation

**Principle**: Use different transformation strategies based on context.

**Example from async/await**:
```haxe
// Class methods: Wrap in async IIFE
static function transformFunctionBody(expr: Expr, pos: Position): Expr {
    return macro @:pos(pos) {
        return js.Syntax.code("(async function() {0})()", ${wrapInAsyncFunction(transformedBody, pos)});
    };
}

// Anonymous functions: Direct Promise wrapping
static function transformAnonymousFunctionBody(expr: Expr, pos: Position): Expr {
    return macro @:pos(pos) return js.lib.Promise.resolve($processedExpr);
}
```

### 4. Robust Pattern Matching

**Principle**: Use flexible pattern matching that handles edge cases and different AST structures.

**Example**: Promise type detection that handles both imported and qualified forms:
```haxe
switch (returnType) {
    case TPath(p) if (p.name == "Promise" && (p.pack.length == 0 || (p.pack.length == 2 && p.pack[0] == "js" && p.pack[1] == "lib"))):
        // Handles both Promise<T> (imported) and js.lib.Promise<T> (qualified)
        return returnType;
    case _:
        // Wrap in Promise<T>
        return TPath({name: "Promise", pack: ["js", "lib"], params: [TPType(returnType)]});
}
```

### 5. Recursive Expression Processing

**Principle**: Use `expr.map()` for recursive traversal of expression trees.

**Implementation**:
```haxe
static function processExpression(expr: Expr): Expr {
    return switch (expr.expr) {
        case EMeta(meta, funcExpr) if (isAsyncMeta(meta.name)):
            // Handle specific case
            transformAnonymousAsync(funcExpr, func, meta, expr.pos);
        case _:
            // Recursively process all child expressions
            expr.map(processExpression);
    }
}
```

## AST Manipulation Best Practices

### 1. Metadata Preservation and Transformation

**Pattern**: Remove original metadata and add new metadata for downstream processing.

```haxe
// Remove @:async metadata
var newMeta = removeAsyncMeta(field.meta);

// Add :jsAsync metadata for JavaScript generator
newMeta.push({
    name: ":jsAsync",
    params: [],
    pos: field.pos
});
```

### 2. Position Preservation

**Principle**: Always preserve source positions for debugging and error reporting.

```haxe
// Good: Preserve positions
return {
    expr: EReturn(macro @:pos(pos) js.lib.Promise.resolve($returnExpr)),
    pos: pos
};

// Bad: Lose position information
return {
    expr: EReturn(macro js.lib.Promise.resolve($returnExpr)),
    pos: Context.currentPos() // Wrong position
};
```

### 3. Type Safety in Transformations

**Principle**: Maintain type safety throughout transformation pipeline.

```haxe
// Good: Explicit type annotation
static function transformReturnType(returnType: Null<ComplexType>, pos: Position): ComplexType {
    // Clear return type contract
}

// Bad: Lose type information
static function transformReturnType(returnType: Dynamic, pos: Dynamic): Dynamic {
    // Unclear contracts, harder to debug
}
```

## Build Macro Architecture

### 1. Global Registration Pattern

**Principle**: Use `Compiler.addGlobalMetadata` for comprehensive processing.

```haxe
public static function init(): Void {
    Compiler.addGlobalMetadata("", "@:build(reflaxe.js.Async.build())", true, true, false);
}
```

**Benefits**:
- Processes ALL classes automatically
- Finds metadata anywhere in the codebase
- No manual application required

### 2. Two-Phase Processing

**Pattern**: Handle different contexts in separate phases.

```haxe
public static function build(): Array<Field> {
    var fields = Context.getBuildFields();
    var transformedFields: Array<Field> = [];
    
    for (field in fields) {
        switch (field.kind) {
            case FFun(func):
                if (hasAsyncMeta(field.meta)) {
                    // Phase 1: Transform class methods
                    var transformedField = transformAsyncFunction(field, func);
                    // Phase 2: Process nested expressions
                    transformedField = processExpression(transformedField);
                } else {
                    // Phase 2: Process expressions even in non-async methods
                    field = processExpression(field);
                }
            // Handle other field types...
        }
    }
    
    return transformedFields;
}
```

### 3. Metadata Detection Strategy

**Pattern**: Use guards and helper functions for clear metadata detection.

```haxe
static function hasAsyncMeta(meta: Metadata): Bool {
    if (meta == null) return false;
    
    for (entry in meta) {
        if (entry.name == ":async" || entry.name == "async") {
            return true;
        }
    }
    return false;
}

// Use in pattern matching
switch (expr.expr) {
    case EMeta(meta, funcExpr) if (isAsyncMeta(meta.name)):
        // Clear intent
}
```

## Type System Integration

### 1. Import Resolution Awareness

**Principle**: Account for how Haxe's import system affects AST structure.

**Key Insight**: When `js.lib.Promise` is imported, references appear with empty pack arrays:
```haxe
// User writes: Promise<String>
// AST shows: TPath({name: Promise, pack: []})  // Empty pack!
// Not: TPath({name: Promise, pack: ["js", "lib"]})
```

**Solution**: Flexible matching for both forms:
```haxe
case TPath(p) if (p.name == "Promise" && (p.pack.length == 0 || p.pack.join(".") == "js.lib")):
```

### 2. Type Transformation Patterns

**Pattern**: Transform types consistently while preserving semantics.

```haxe
static function transformReturnType(returnType: Null<ComplexType>, pos: Position): ComplexType {
    if (returnType == null) {
        // Default case
        return TPath({name: "Promise", pack: ["js", "lib"], params: [TPType(macro: Dynamic)]});
    }
    
    // Check if already transformed
    switch (returnType) {
        case TPath(p) if (isPromiseType(p)):
            return returnType; // Don't double-wrap
        case _:
            return wrapInPromise(returnType); // Transform
    }
}
```

### 3. ComplexType Construction

**Pattern**: Build ComplexType structures properly for reliable compilation.

```haxe
// Good: Proper structure
return TPath({
    name: "Promise",
    pack: ["js", "lib"],
    params: [TPType(innerType)]
});

// Bad: Incomplete structure
return TPath({
    name: "Promise"
    // Missing pack and params
});
```

## Error Handling

### 1. Graceful Degradation

**Principle**: Provide fallbacks when transformation cannot proceed.

```haxe
static function transformAnonymousFunctionBody(expr: Expr, pos: Position): Expr {
    if (expr == null) {
        // Graceful fallback
        return macro @:pos(pos) return js.lib.Promise.resolve(null);
    }
    
    // Normal processing
    var processedExpr = processAwaitInExpr(expr);
    // ...
}
```

### 2. Meaningful Error Messages

**Principle**: Provide context and location information in errors.

```haxe
// Good: Contextual error
Context.error("@:async functions must return Promise<T>, got: " + returnType, pos);

// Bad: Generic error
Context.error("Invalid type", pos);
```

### 3. Validation Before Transformation

**Principle**: Validate input before attempting transformation.

```haxe
static function validateAsyncFunction(func: Function, pos: Position): Void {
    if (func.ret == null) {
        Context.warning("@:async function without return type will default to Promise<Dynamic>", pos);
    }
    
    // Additional validations...
}
```

## Testing Strategy

### 1. Compiler-Level Testing

**Principle**: Test transformations at the Haxe compilation level, not runtime.

**Approach**: Snapshot testing with expected output comparison:
```bash
# Test structure
test/tests/AsyncAnonymousFunctions/
├── compile.hxml          # Compilation configuration
├── MainMinimal.hx        # Test cases
└── out/main.js          # Generated output to verify
```

### 2. Transformation Validation

**Tests should verify**:
1. **Compilation Success**: No compilation errors
2. **Type Safety**: No type mismatch errors  
3. **Output Correctness**: Generated code matches expectations
4. **Edge Cases**: Handle null/empty inputs gracefully

### 3. Debug Traces During Development

**Pattern**: Strategic trace statements for understanding AST structure.

```haxe
// Development traces (remove in production)
trace("transformReturnType received: " + returnType);
trace("AST structure: " + expr.expr);

// Use during development, remove before commit
```

## Performance Considerations

### 1. Minimal AST Traversal

**Principle**: Avoid unnecessary recursive processing.

```haxe
// Good: Early return for irrelevant cases
static function processExpression(expr: Expr): Expr {
    if (expr == null) return null;
    
    switch (expr.expr) {
        case EMeta(meta, _) if (!isRelevantMeta(meta.name)):
            return expr; // Skip processing
        case _:
            return expr.map(processExpression); // Only process when needed
    }
}
```

### 2. Efficient Pattern Matching

**Principle**: Order pattern matching by frequency and early exits.

```haxe
// Good: Most common cases first
switch (expr.expr) {
    case EBlock(_): // Most common
        // Handle efficiently
    case EMeta(meta, _) if (isAsyncMeta(meta.name)): // Specific case
        // Handle async metadata
    case _: // Fallback
        expr.map(processExpression);
}
```

### 3. Avoid Redundant Transformations

**Principle**: Check if transformation is needed before applying.

```haxe
// Good: Check before transforming
if (hasAsyncMeta(field.meta)) {
    return transformAsyncFunction(field, func);
} else {
    return field; // No transformation needed
}

// Bad: Always transform
return transformAsyncFunction(field, func); // Even when not needed
```

## Development Workflow

### 1. Iterative Development

1. **Start Simple**: Basic transformation first
2. **Add Edge Cases**: Handle null, empty, malformed inputs
3. **Optimize**: Improve performance and error handling
4. **Document**: Capture learnings and patterns

### 2. Testing-Driven Approach

1. **Create Test Case**: Minimal example of desired behavior
2. **Implement Transformation**: Make test pass
3. **Add Edge Cases**: Handle variations and errors
4. **Refactor**: Clean up and optimize

### 3. Documentation as Development

1. **Document Decisions**: Why certain approaches were chosen
2. **Capture Insights**: Unexpected behaviors and solutions
3. **Share Patterns**: Reusable solutions for future work
4. **Maintain Examples**: Working code that demonstrates principles

## Conclusion

These principles form the foundation for reliable, maintainable macro development in Reflaxe.Elixir. They are based on real-world experience implementing complex features like async/await anonymous function support.

Key takeaways:
- **AST preservation** over string manipulation
- **Context-aware** transformation strategies
- **Robust pattern matching** for edge cases
- **Stateless design** for scalability
- **Comprehensive testing** at the compiler level

Future macro development should build on these principles while capturing new learnings in this documentation framework.