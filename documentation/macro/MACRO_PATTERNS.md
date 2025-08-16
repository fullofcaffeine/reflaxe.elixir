# Macro Development Patterns for Reflaxe.Elixir

## 🎯 Overview

This document provides reusable patterns and code templates for common macro development tasks in Reflaxe.Elixir, based on proven implementations from features like async/await, build macros, and expression transformations.

## Table of Contents

1. [Build Macro Patterns](#build-macro-patterns)
2. [Expression Transformation Patterns](#expression-transformation-patterns)
3. [Type Manipulation Patterns](#type-manipulation-patterns)
4. [AST Processing Patterns](#ast-processing-patterns)
5. [Metadata Handling Patterns](#metadata-handling-patterns)
6. [Error Handling Patterns](#error-handling-patterns)
7. [Testing Patterns](#testing-patterns)

## Build Macro Patterns

### 1. Global Build Macro Registration

**Pattern**: Register build macro to process all classes automatically.

```haxe
public static function init(): Void {
    Compiler.addGlobalMetadata("", "@:build(your.package.YourMacro.build())", true, true, false);
}
```

**Usage**: Call from `--macro` directive in build.hxml:
```hxml
--macro your.package.YourMacro.init()
```

### 2. Field Processing Template

**Pattern**: Process different field types with proper error handling.

```haxe
public static function build(): Array<Field> {
    var fields = Context.getBuildFields();
    var transformedFields: Array<Field> = [];
    
    for (field in fields) {
        switch (field.kind) {
            case FFun(func):
                if (hasTargetMeta(field.meta)) {
                    // Transform function with metadata
                    var transformedField = transformFunction(field, func);
                    transformedFields.push(transformedField);
                } else {
                    // Process nested expressions even in non-target functions
                    var processedField = processFieldExpressions(field);
                    transformedFields.push(processedField);
                }
                
            case FVar(t, e) | FProp(_, _, t, e):
                // Process variable/property initializers
                if (e != null) {
                    var newExpr = processExpression(e);
                    switch (field.kind) {
                        case FVar(t, _):
                            field.kind = FVar(t, newExpr);
                        case FProp(get, set, t, _):
                            field.kind = FProp(get, set, t, newExpr);
                        case _:
                    }
                }
                transformedFields.push(field);
                
            case _:
                transformedFields.push(field);
        }
    }
    
    return transformedFields;
}
```

### 3. Two-Phase Processing Pattern

**Pattern**: Handle class-level and expression-level transformations separately.

```haxe
static function transformFunction(field: Field, func: Function): Field {
    // Phase 1: Transform function signature and metadata
    var transformedField = transformFunctionSignature(field, func);
    
    // Phase 2: Process function body expressions
    switch (transformedField.kind) {
        case FFun(f):
            if (f.expr != null) {
                f.expr = processExpression(f.expr);
            }
        case _:
    }
    
    return transformedField;
}
```

## Expression Transformation Patterns

### 1. Recursive Expression Processing

**Pattern**: Traverse expression trees while handling specific cases.

```haxe
static function processExpression(expr: Expr): Expr {
    if (expr == null) return null;
    
    return switch (expr.expr) {
        // Handle specific metadata patterns
        case EMeta(meta, innerExpr) if (isTargetMeta(meta.name)):
            transformSpecificExpression(innerExpr, meta, expr.pos);
            
        // Handle variable declarations with potential target expressions
        case EVars(vars):
            var newVars = vars.map(function(v) {
                return {
                    name: v.name,
                    namePos: v.namePos,
                    type: v.type,
                    expr: v.expr != null ? processExpression(v.expr) : null,
                    isFinal: v.isFinal,
                    isStatic: v.isStatic,
                    meta: v.meta
                };
            });
            {expr: EVars(newVars), pos: expr.pos};
            
        // Recursively process all other expressions
        case _:
            expr.map(processExpression);
    }
}
```

### 2. Context-Specific Transformation

**Pattern**: Apply different transformations based on expression context.

```haxe
static function transformByContext(expr: Expr, context: TransformContext): Expr {
    return switch (context) {
        case ClassMethod:
            // Transform for class method context
            transformForClassMethod(expr);
            
        case AnonymousFunction:
            // Transform for anonymous function context
            transformForAnonymousFunction(expr);
            
        case VariableInitializer:
            // Transform for variable initialization
            transformForVariable(expr);
            
        case _:
            // Default transformation
            expr;
    }
}

enum TransformContext {
    ClassMethod;
    AnonymousFunction;
    VariableInitializer;
    Other;
}
```

### 3. Expression Body Transformation

**Pattern**: Transform function bodies while preserving structure.

```haxe
static function transformFunctionBody(expr: Expr, pos: Position): Expr {
    if (expr == null) {
        // Provide default implementation
        return macro @:pos(pos) {
            // Default behavior
        };
    }
    
    // Process the expression to transform specific patterns
    var transformedBody = processTargetPatterns(expr);
    
    return switch (transformedBody.expr) {
        case EReturn(returnExpr):
            // Already has return, transform it
            if (returnExpr != null) {
                {
                    expr: EReturn(transformReturnValue(returnExpr, pos)),
                    pos: pos
                };
            } else {
                transformedBody;
            }
            
        case EBlock(exprs):
            // Block expression - check if last expression needs return
            var lastExpr = exprs[exprs.length - 1];
            if (needsImplicitReturn(lastExpr)) {
                var newExprs = exprs.copy();
                newExprs[newExprs.length - 1] = addImplicitReturn(lastExpr, pos);
                {
                    expr: EBlock(newExprs),
                    pos: pos
                };
            } else {
                transformedBody;
            }
            
        case _:
            // Single expression, may need wrapping
            transformSingleExpression(transformedBody, pos);
    };
}
```

## Type Manipulation Patterns

### 1. Robust Type Detection

**Pattern**: Handle imported and qualified type forms.

```haxe
static function isTargetType(complexType: ComplexType, targetName: String, targetPack: Array<String>): Bool {
    return switch (complexType) {
        case TPath(p) if (p.name == targetName && 
                         (p.pack.length == 0 || // Imported form
                          arraysEqual(p.pack, targetPack))): // Qualified form
            true;
        case _:
            false;
    };
}

static function arraysEqual<T>(a: Array<T>, b: Array<T>): Bool {
    if (a.length != b.length) return false;
    for (i in 0...a.length) {
        if (a[i] != b[i]) return false;
    }
    return true;
}
```

### 2. Type Wrapping Pattern

**Pattern**: Wrap types while avoiding double-wrapping.

```haxe
static function wrapInTargetType(originalType: Null<ComplexType>, wrapperName: String, wrapperPack: Array<String>, pos: Position): ComplexType {
    if (originalType == null) {
        // Default case
        return TPath({
            name: wrapperName,
            pack: wrapperPack,
            params: [TPType(macro: Dynamic)]
        });
    }
    
    // Check if already wrapped
    if (isTargetType(originalType, wrapperName, wrapperPack)) {
        return originalType; // Don't double-wrap
    }
    
    // Wrap in target type
    return TPath({
        name: wrapperName,
        pack: wrapperPack,
        params: [TPType(originalType)]
    });
}
```

### 3. ComplexType Construction

**Pattern**: Build ComplexType structures with proper parameter handling.

```haxe
static function createParameterizedType(name: String, pack: Array<String>, params: Array<ComplexType>): ComplexType {
    var typeParams = params.map(function(p) return TPType(p));
    
    return TPath({
        name: name,
        pack: pack,
        params: typeParams
    });
}

// Usage examples
var promiseString = createParameterizedType("Promise", ["js", "lib"], [macro: String]);
var arrayInt = createParameterizedType("Array", [], [macro: Int]);
```

## AST Processing Patterns

### 1. Safe AST Navigation

**Pattern**: Navigate AST structures with null checks and fallbacks.

```haxe
static function extractFromAST<T>(expr: Expr, extractor: Expr -> Null<T>, fallback: T): T {
    if (expr == null) return fallback;
    
    var result = extractor(expr);
    return result != null ? result : fallback;
}

// Usage
var variableName = extractFromAST(expr, function(e) {
    return switch (e.expr) {
        case EConst(CIdent(name)): name;
        case _: null;
    };
}, "defaultName");
```

### 2. AST Pattern Matching Utilities

**Pattern**: Reusable functions for common AST patterns.

```haxe
static function isMethodCall(expr: Expr, methodName: String): Bool {
    return switch (expr.expr) {
        case ECall({expr: EField(_, field)}, _) if (field == methodName):
            true;
        case _:
            false;
    };
}

static function isFunctionExpression(expr: Expr): Bool {
    return switch (expr.expr) {
        case EFunction(_, _):
            true;
        case _:
            false;
    };
}

static function isVariableAccess(expr: Expr, varName: String): Bool {
    return switch (expr.expr) {
        case EConst(CIdent(name)) if (name == varName):
            true;
        case _:
            false;
    };
}
```

### 3. Expression Construction Helpers

**Pattern**: Helper functions for building common expression types.

```haxe
static function createMethodCall(object: Expr, methodName: String, args: Array<Expr>, pos: Position): Expr {
    return {
        expr: ECall({
            expr: EField(object, methodName),
            pos: pos
        }, args),
        pos: pos
    };
}

static function createVariableAssignment(varName: String, value: Expr, pos: Position): Expr {
    return {
        expr: EBinop(OpAssign, {
            expr: EConst(CIdent(varName)),
            pos: pos
        }, value),
        pos: pos
    };
}

static function createReturnStatement(value: Expr, pos: Position): Expr {
    return {
        expr: EReturn(value),
        pos: pos
    };
}
```

## Metadata Handling Patterns

### 1. Metadata Detection and Filtering

**Pattern**: Detect and filter metadata entries reliably.

```haxe
static function hasMetadata(meta: Metadata, names: Array<String>): Bool {
    if (meta == null) return false;
    
    for (entry in meta) {
        for (name in names) {
            if (entry.name == name || entry.name == ":" + name) {
                return true;
            }
        }
    }
    return false;
}

static function getMetadataEntry(meta: Metadata, name: String): Null<MetadataEntry> {
    if (meta == null) return null;
    
    for (entry in meta) {
        if (entry.name == name || entry.name == ":" + name) {
            return entry;
        }
    }
    return null;
}

static function removeMetadata(meta: Metadata, namesToRemove: Array<String>): Metadata {
    if (meta == null) return null;
    
    return meta.filter(function(entry) {
        for (name in namesToRemove) {
            if (entry.name == name || entry.name == ":" + name) {
                return false;
            }
        }
        return true;
    });
}
```

### 2. Metadata Transformation

**Pattern**: Replace metadata while preserving other entries.

```haxe
static function transformMetadata(originalMeta: Metadata, oldNames: Array<String>, newEntry: MetadataEntry): Metadata {
    var filteredMeta = removeMetadata(originalMeta, oldNames);
    
    if (filteredMeta == null) {
        filteredMeta = [];
    }
    
    filteredMeta.push(newEntry);
    return filteredMeta;
}

// Usage
var newMeta = transformMetadata(field.meta, ["async"], {
    name: ":jsAsync",
    params: [],
    pos: field.pos
});
```

### 3. Metadata Parameter Extraction

**Pattern**: Extract and validate metadata parameters.

```haxe
static function extractStringParam(entry: MetadataEntry, index: Int, defaultValue: String): String {
    if (entry.params == null || index >= entry.params.length) {
        return defaultValue;
    }
    
    return switch (entry.params[index].expr) {
        case EConst(CString(s)): s;
        case _: defaultValue;
    };
}

static function extractBoolParam(entry: MetadataEntry, index: Int, defaultValue: Bool): Bool {
    if (entry.params == null || index >= entry.params.length) {
        return defaultValue;
    }
    
    return switch (entry.params[index].expr) {
        case EConst(CIdent("true")): true;
        case EConst(CIdent("false")): false;
        case _: defaultValue;
    };
}
```

## Error Handling Patterns

### 1. Graceful Degradation

**Pattern**: Provide fallbacks when transformation cannot proceed.

```haxe
static function safeTransform<T>(input: T, transformer: T -> T, fallback: T): T {
    try {
        return transformer(input);
    } catch (e: Dynamic) {
        // Log error for debugging
        trace("Transformation failed: " + e);
        return fallback;
    }
}

// Usage
var transformedExpr = safeTransform(expr, function(e) {
    return complexTransformation(e);
}, expr); // Fallback to original
```

### 2. Context-Rich Error Messages

**Pattern**: Provide detailed error context for debugging.

```haxe
static function reportError(message: String, expr: Expr, context: String): Void {
    var fullMessage = context + ": " + message;
    
    if (expr != null) {
        fullMessage += "\nExpression: " + expr.toString();
        fullMessage += "\nAt: " + expr.pos;
    }
    
    Context.error(fullMessage, expr != null ? expr.pos : Context.currentPos());
}

// Usage
reportError("Invalid async function structure", expr, "transformAsyncFunction");
```

### 3. Validation Patterns

**Pattern**: Validate inputs before transformation.

```haxe
static function validateFunction(func: Function, pos: Position): Bool {
    var isValid = true;
    
    if (func == null) {
        Context.error("Function cannot be null", pos);
        return false;
    }
    
    if (func.ret == null) {
        Context.warning("Function without return type will default to Dynamic", pos);
    }
    
    if (func.expr == null) {
        Context.warning("Function has no body", pos);
    }
    
    return isValid;
}
```

## Testing Patterns

### 1. Compilation Test Setup

**Pattern**: Structure for compiler-level testing.

```
test/tests/YourFeature/
├── compile.hxml          # Test compilation configuration
├── Main.hx              # Test cases
├── intended/            # Expected output (for snapshot testing)
│   └── Main.js          # Expected JavaScript output
└── out/                 # Generated output directory
    └── main.js          # Actual output (compared with intended)
```

**compile.hxml template**:
```hxml
-cp ../../../src
-cp ../../../std
-main Main
-lib reflaxe
--macro your.package.YourMacro.init()
--js out/main.js
```

### 2. Test Case Patterns

**Pattern**: Structure test cases to validate different scenarios.

```haxe
class Main {
    public static function main(): Void {
        // Test 1: Basic functionality
        testBasicTransformation();
        
        // Test 2: Edge cases
        testEdgeCases();
        
        // Test 3: Error conditions
        testErrorHandling();
    }
    
    static function testBasicTransformation(): Void {
        // Simple case that should work
        var basic = @:yourMetadata function() {
            return "basic";
        };
    }
    
    static function testEdgeCases(): Void {
        // Edge cases like null, empty, malformed
        var nullCase = @:yourMetadata function() {
            // Empty function
        };
        
        var explicitType = @:yourMetadata function(): String {
            return "typed";
        };
    }
    
    static function testErrorHandling(): Void {
        // Cases that should generate warnings or errors
        // (Test that they don't crash the compiler)
    }
}
```

### 3. Output Verification

**Pattern**: Verify generated code matches expectations.

```bash
# Run test
haxe test/tests/YourFeature/compile.hxml

# Compare output
diff test/tests/YourFeature/intended/main.js test/tests/YourFeature/out/main.js

# Update expected output when implementation changes
cp test/tests/YourFeature/out/main.js test/tests/YourFeature/intended/main.js
```

## Macro Development Workflow

### 1. Template Macro Structure

**Pattern**: Standard structure for new macro implementations.

```haxe
package your.package;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Compiler;
using haxe.macro.ExprTools;
using haxe.macro.TypeTools;
using haxe.macro.ComplexTypeTools;
#end

class YourMacro {
    
    #if macro
    
    /**
     * Initialize the macro system.
     */
    public static function init(): Void {
        Compiler.addGlobalMetadata("", "@:build(your.package.YourMacro.build())", true, true, false);
    }
    
    /**
     * Build macro that processes classes.
     */
    public static function build(): Array<Field> {
        var fields = Context.getBuildFields();
        var transformedFields: Array<Field> = [];
        
        for (field in fields) {
            var transformedField = processField(field);
            transformedFields.push(transformedField);
        }
        
        return transformedFields;
    }
    
    /**
     * Process individual fields.
     */
    static function processField(field: Field): Field {
        // Implementation
        return field;
    }
    
    #end
    
    /**
     * Expression macro for user-facing functionality.
     */
    public static macro function yourMacroFunction(expr: Expr): Expr {
        #if macro
        // Implementation
        return expr;
        #else
        return null;
        #end
    }
}
```

### 2. Development Testing Loop

1. **Create minimal test case**
2. **Implement basic transformation**
3. **Run test and check output**
4. **Iterate on edge cases**
5. **Add error handling**
6. **Document patterns and learnings**

### 3. Integration with Existing Systems

**Pattern**: Integrate new macros with existing Reflaxe.Elixir infrastructure.

```haxe
// Follow existing patterns for metadata names
// Use :yourFeature convention
// Add to annotation system if appropriate
// Update FEATURES.md when complete
// Add to test suite
// Document in macro/ directory
```

## Conclusion

These patterns provide a foundation for consistent, reliable macro development in Reflaxe.Elixir. They are based on proven implementations and real-world usage.

**Key Pattern Categories**:
- **Build Macros**: Global registration and field processing
- **Expression Transformation**: Recursive processing and context-aware transformation
- **Type Manipulation**: Robust type detection and wrapping
- **AST Processing**: Safe navigation and pattern matching
- **Metadata Handling**: Detection, filtering, and transformation
- **Error Handling**: Graceful degradation and rich error messages
- **Testing**: Compiler-level testing and output verification

Use these patterns as starting points and adapt them to your specific needs while maintaining consistency with the established architectural principles.