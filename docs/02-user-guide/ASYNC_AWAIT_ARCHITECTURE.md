# Async/Await Architecture and Implementation

## Overview

This document provides a comprehensive understanding of the async/await macro system implementation in Reflaxe.js, covering the architecture, macro patterns, and key learnings from building support for @:async anonymous functions.

## Table of Contents

1. [Core Architecture](#core-architecture)
2. [Macro Transformation Pipeline](#macro-transformation-pipeline)
3. [Anonymous Function Challenge](#anonymous-function-challenge)
4. [Promise Type Detection](#promise-type-detection)
5. [Key Implementation Patterns](#key-implementation-patterns)
6. [Generated JavaScript](#generated-javascript)
7. [Lessons Learned](#lessons-learned)
8. [Testing Strategy](#testing-strategy)

## Core Architecture

### Build Macro System

The async/await implementation uses Haxe's build macro system to transform code at compile time:

```haxe
/**
 * Initialization function called automatically to register build macros.
 * Processes classes with @:async functions and transforms them.
 * Also processes anonymous functions with @:async metadata.
 */
public static function init(): Void {
    Compiler.addGlobalMetadata("", "@:build(reflaxe.js.Async.build())", true, true, false);
}
```

**Key Points:**
- **Global Application**: The build macro is applied to ALL classes through `Compiler.addGlobalMetadata`
- **Universal Processing**: Every class gets processed, allowing detection of @:async metadata anywhere
- **Compile-Time Only**: The entire system exists only during compilation and disappears afterward

### Two-Phase Transformation

The system handles two different contexts:

1. **Class Methods**: Functions defined as class members with @:async metadata
2. **Anonymous Functions**: Function expressions with @:async metadata in variable assignments or expressions

## Macro Transformation Pipeline

### 1. Build Macro Entry Point

```haxe
public static function build(): Array<Field> {
    var fields = Context.getBuildFields();
    var transformedFields: Array<Field> = [];
    
    for (field in fields) {
        switch (field.kind) {
            case FFun(func):
                if (hasAsyncMeta(field.meta)) {
                    // Transform async class method
                    var transformedField = transformAsyncFunction(field, func);
                    // Process any anonymous functions in the body
                    transformedField = processExpression(transformedField);
                } else {
                    // Process anonymous functions even in non-async methods
                    field = processExpression(field);
                }
                transformedFields.push(field);
            // ... handle other field types
        }
    }
    
    return transformedFields;
}
```

**Key Insights:**
- **Recursive Processing**: Both class methods AND their bodies are processed for nested anonymous functions
- **Non-Async Methods**: Even non-async methods are processed to find anonymous async functions
- **Field Transformation**: The build macro works at the field level, transforming entire function definitions

### 2. Expression Tree Traversal

```haxe
static function processExpression(expr: Expr): Expr {
    return switch (expr.expr) {
        // Handle @:async metadata on anonymous functions
        case EMeta(meta, funcExpr) if (isAsyncMeta(meta.name)):
            switch (funcExpr.expr) {
                case EFunction(kind, func):
                    // Transform anonymous async function
                    transformAnonymousAsync(funcExpr, func, meta, expr.pos);
                case _:
                    // Not a function, just process recursively
                    expr.map(processExpression);
            }
            
        // Recursively process all other expressions
        case _:
            expr.map(processExpression);
    }
}
```

**Key Patterns:**
- **AST Pattern Matching**: Uses pattern matching to identify specific expression structures
- **Recursive Traversal**: Uses `expr.map(processExpression)` to recursively process nested expressions
- **Metadata Detection**: Specifically looks for `EMeta` nodes containing async metadata

## Anonymous Function Challenge

### The Problem

Anonymous functions present unique challenges compared to class methods:

1. **Different AST Structure**: Anonymous functions are expressions, not field declarations
2. **Variable Assignment Context**: They appear in variable assignments, not function declarations
3. **Type Inference**: Return types are often inferred rather than explicitly declared
4. **Transformation Scope**: Need different handling for function body transformation

### The Solution: Specialized Transformation

```haxe
static function transformAnonymousAsync(funcExpr: Expr, func: Function, meta: MetadataEntry, pos: Position): Expr {
    // Transform return type from T to Promise<T>
    var newReturnType = transformReturnType(func.ret, pos);
    
    // For anonymous functions, transform the body to ensure it returns a Promise
    var transformedBody = if (func.expr != null) {
        transformAnonymousFunctionBody(func.expr, pos);
    } else {
        // Empty function should return resolved Promise
        macro @:pos(pos) return js.lib.Promise.resolve(null);
    };
    
    // Create new function with transformed properties
    var newFunc: Function = {
        args: func.args,
        ret: newReturnType,
        expr: transformedBody,
        params: func.params
    };
    
    // Create function with :jsAsync metadata (don't wrap in another EMeta)
    var transformedFunction = {
        expr: EFunction(kind, newFunc),
        pos: funcExpr.pos
    };
    
    // Add the :jsAsync metadata to mark it for JavaScript generation
    return {
        expr: EMeta({
            name: ":jsAsync",
            params: [],
            pos: pos
        }, transformedFunction),
        pos: pos
    };
}
```

### Anonymous Function Body Transformation

Unlike class methods, anonymous functions need direct Promise wrapping:

```haxe
static function transformAnonymousFunctionBody(expr: Expr, pos: Position): Expr {
    // Process await calls in the expression
    var processedExpr = processAwaitInExpr(expr);
    
    // For anonymous functions, we need to ensure the body returns a Promise
    return switch (processedExpr.expr) {
        case EReturn(returnExpr):
            // Already has a return statement, ensure it returns a Promise
            if (returnExpr != null) {
                {
                    expr: EReturn(macro @:pos(pos) js.lib.Promise.resolve($returnExpr)),
                    pos: pos
                };
            } else {
                {
                    expr: EReturn(macro @:pos(pos) js.lib.Promise.resolve(null)),
                    pos: pos
                };
            }
        // ... handle other cases
    };
}
```

**Key Differences from Class Methods:**
- **Direct Promise Wrapping**: No IIFE (Immediately Invoked Function Expression) wrapper
- **Simple Return Transformation**: Directly wraps return values in `Promise.resolve()`
- **Implicit Returns**: Handles cases where there's no explicit return statement

## Promise Type Detection

### The Critical Bug: Empty Pack Arrays

One of the most challenging issues was Promise type detection. When users write:

```haxe
var simple = @:async function(): Promise<String> {
    return "hello";
};
```

The AST structure shows:
```haxe
TPath({name: Promise, params: [TPType(...)], pack: []})  // Empty pack!
```

**The Problem**: When `js.lib.Promise` is imported, Haxe resolves `Promise<String>` references to a simplified form where the package information is stripped to an empty array `[]`.

### The Solution: Robust Pattern Matching

```haxe
static function transformReturnType(returnType: Null<ComplexType>, pos: Position): ComplexType {
    // Check if already a Promise type (handles both imported and fully qualified)
    switch (returnType) {
        case TPath(p) if (p.name == "Promise" && (p.pack.length == 0 || (p.pack.length == 2 && p.pack[0] == "js" && p.pack[1] == "lib"))):
            // Already a Promise type (either imported as Promise or fully qualified js.lib.Promise)
            return returnType;
        case _:
            // Not a Promise type, wrap in Promise<T>
            return TPath({
                name: "Promise",
                pack: ["js", "lib"],
                params: [TPType(returnType)]
            });
    }
}
```

**Key Insights:**
- **Import Resolution**: Haxe's import system affects AST structure at compile time
- **Flexible Matching**: Must handle both empty packs (imported) and full packs (qualified)
- **Double-Wrapping Prevention**: Critical to avoid `Promise<Promise<T>>` errors

## Key Implementation Patterns

### 1. AST Preservation

**Pattern**: Keep AST nodes (TypedExpr/Expr) as long as possible before converting to strings.

**Why**: AST provides structural information for proper transformations.

**Example**:
```haxe
// Good: Work with AST
var transformedBody = processAwaitInExpr(func.expr);

// Bad: Convert to string too early
var stringBody = func.expr.toString();
```

### 2. Recursive Expression Processing

**Pattern**: Use `expr.map()` for recursive traversal of expression trees.

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

### 3. Metadata Preservation and Transformation

**Pattern**: Remove original metadata and add new metadata for downstream processing.

**Example**:
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

### 4. Context-Aware Transformation

**Pattern**: Use different transformation strategies based on context.

**Class Methods vs Anonymous Functions**:
```haxe
// Class methods: Wrap in async IIFE
return macro @:pos(pos) {
    return js.Syntax.code("(async function() {0})()", ${wrapInAsyncFunction(transformedBody, pos)});
};

// Anonymous functions: Direct Promise wrapping
return macro @:pos(pos) return js.lib.Promise.resolve($processedExpr);
```

## Generated JavaScript

### Anonymous Function Result

**Haxe Input**:
```haxe
var simple = @:async function() {
    trace("hello");
};
```

**Generated JavaScript**:
```javascript
var simple = function() {
    console.log("MainMinimal.hx:12:","hello");
    return Promise.resolve(null);
};
```

**Key Characteristics**:
- **Clean Output**: No IIFE wrapper, just a function that returns a Promise
- **Proper Resolution**: Uses `Promise.resolve()` for consistent Promise wrapping
- **Source Maps**: Preserves source location information for debugging

### Class Method Result (Conceptual)

**Haxe Input**:
```haxe
@:async
public static function getData(): String {
    return "data";
}
```

**Generated JavaScript**:
```javascript
static getData() {
    return (async function() {
        return "data";
    })();
}
```

## Lessons Learned

### 1. Import Systems Affect AST Structure

**Lesson**: Haxe's import resolution changes how types appear in the AST.

**Impact**: Type detection logic must account for both qualified and imported forms.

**Solution**: Use flexible pattern matching that handles multiple pack formats.

### 2. Anonymous Functions Need Different Handling

**Lesson**: Anonymous functions and class methods have fundamentally different transformation requirements.

**Impact**: Cannot use the same transformation pipeline for both.

**Solution**: Separate transformation functions with context-specific logic.

### 3. Debugging Macro Transformations

**Lesson**: Macro debugging requires strategic trace statements to understand AST structure.

**Tools Used**:
```haxe
trace("transformReturnType received: " + returnType);
trace("New return type: " + newReturnType);
```

**Best Practice**: Add temporary debug traces during development, remove in production.

### 4. Build Macro Scope

**Lesson**: Build macros are applied globally but process each class individually.

**Impact**: Cannot share state between classes, must process each independently.

**Solution**: Design stateless transformation functions.

## Testing Strategy

### Compiler-Level Testing

**Approach**: Test transformations at the Haxe compilation level, not runtime.

**Test Structure**:
```
test/tests/AsyncAnonymousFunctions/
├── compile.hxml          # Compilation configuration
├── MainMinimal.hx        # Simple test case
├── MainSimple.hx        # Complex test case
└── out/main.js          # Generated JavaScript output
```

**Key Tests**:
1. **Basic Transformation**: Anonymous function compiles without errors
2. **Promise Wrapping**: Generated code returns `Promise.resolve()`
3. **Type Safety**: No double-wrapping errors
4. **JavaScript Output**: Verify clean, expected JavaScript generation

### Test Verification Process

1. **Compilation Success**: `haxe compile.hxml` completes without errors
2. **Output Inspection**: Generated JavaScript contains expected Promise patterns
3. **Type Checking**: No Promise<Promise<T>> type errors
4. **Runtime Verification**: Generated code executes correctly in JavaScript environment

## Future Enhancements

### 1. Await Expression Support

**Goal**: Support `Async.await()` calls inside anonymous functions.

**Example**:
```haxe
var fetchData = @:async function() {
    var response = Async.await(fetch("https://api.example.com"));
    return response.text();
};
```

### 2. Error Handling

**Goal**: Proper error propagation in async anonymous functions.

**Implementation**: Transform try/catch blocks to Promise.catch() patterns.

### 3. Performance Optimization

**Goal**: Minimize generated code size and improve execution performance.

**Approach**: More intelligent transformation based on function complexity.

## Conclusion

The async/await implementation demonstrates sophisticated macro programming techniques:

- **Multi-Context Processing**: Handling both class methods and anonymous functions
- **AST Manipulation**: Deep understanding of Haxe's expression tree structure
- **Type System Integration**: Working with Haxe's type resolution and import systems
- **JavaScript Generation**: Producing clean, efficient target code

The key to success was understanding that **anonymous functions require fundamentally different transformation logic** from class methods, and that **import resolution affects AST structure** in ways that impact type detection.

This implementation provides a solid foundation for extending async/await support throughout the Haxe→JavaScript compilation pipeline.