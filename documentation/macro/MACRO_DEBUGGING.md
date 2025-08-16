# Macro Debugging Strategies for Reflaxe.Elixir

## 🎯 Overview

This document provides comprehensive debugging strategies for Haxe macros in Reflaxe.Elixir, covering tools, techniques, and methodologies for troubleshooting macro transformations, AST processing, and compilation issues.

## Table of Contents

1. [Debugging Philosophy](#debugging-philosophy)
2. [Development-Time Debugging](#development-time-debugging)
3. [AST Structure Investigation](#ast-structure-investigation)
4. [Type System Debugging](#type-system-debugging)
5. [Compilation Error Analysis](#compilation-error-analysis)
6. [Testing and Validation](#testing-and-validation)
7. [Performance Debugging](#performance-debugging)
8. [Common Issues and Solutions](#common-issues-and-solutions)

## Debugging Philosophy

### 1. Systematic Approach

**Principle**: Debug methodically from simple to complex cases.

**Process**:
1. **Isolate the problem** - Create minimal reproduction case
2. **Understand the input** - Inspect AST structure and types
3. **Trace transformation** - Follow macro execution step by step
4. **Verify output** - Check generated code matches expectations
5. **Test edge cases** - Ensure robustness across scenarios

### 2. Evidence-Based Debugging

**Principle**: Use concrete evidence (traces, output) rather than assumptions.

**Tools**:
- Strategic trace statements
- AST structure inspection
- Generated code comparison
- Compilation error analysis

### 3. Incremental Development

**Principle**: Build and test incrementally to catch issues early.

**Process**:
1. Start with simplest possible transformation
2. Add one feature at a time
3. Test thoroughly at each step
4. Document unexpected behaviors

## Development-Time Debugging

### 1. Strategic Trace Placement

**Pattern**: Use trace statements to understand macro execution flow.

```haxe
static function transformAsyncFunction(field: Field, func: Function): Field {
    trace("=== transformAsyncFunction START ===");
    trace("Field name: " + field.name);
    trace("Field kind: " + field.kind);
    trace("Function args: " + func.args.length);
    trace("Return type: " + func.ret);
    
    var result = performTransformation(field, func);
    
    trace("=== transformAsyncFunction END ===");
    trace("Result: " + result.name);
    
    return result;
}
```

**Best Practices**:
- Use clear delimiters (`===`) for easy identification
- Include context (function name, current step)
- Show both input and output states
- Remove traces before production commit

### 2. AST Inspection Helpers

**Pattern**: Helper functions to visualize AST structures.

```haxe
static function traceExpr(expr: Expr, label: String): Void {
    trace(label + " Expression:");
    trace("  Type: " + expr.expr);
    trace("  Position: " + expr.pos);
    trace("  String: " + expr.toString());
}

static function traceField(field: Field, label: String): Void {
    trace(label + " Field:");
    trace("  Name: " + field.name);
    trace("  Access: " + field.access);
    trace("  Kind: " + field.kind);
    trace("  Meta: " + field.meta);
}

static function traceComplexType(type: ComplexType, label: String): Void {
    trace(label + " ComplexType:");
    trace("  Structure: " + type);
    trace("  String: " + type.toString());
}
```

### 3. Conditional Debugging

**Pattern**: Enable/disable debugging based on conditions.

```haxe
#if macro
static var DEBUG_ENABLED = #if debug_macros true #else false #end;

static function debugTrace(message: String): Void {
    if (DEBUG_ENABLED) {
        trace("[MACRO DEBUG] " + message);
    }
}
#end
```

**Usage**: Add `-D debug_macros` to build.hxml during development.

### 4. Context Information Gathering

**Pattern**: Collect context information for better debugging.

```haxe
static function getDebugContext(): String {
    var context = "Debug Context:\n";
    context += "  Local Class: " + Context.getLocalClass() + "\n";
    context += "  Local Method: " + Context.getLocalMethod() + "\n";
    context += "  Current Pos: " + Context.currentPos() + "\n";
    context += "  Build Fields: " + Context.getBuildFields().length + " fields\n";
    return context;
}
```

## AST Structure Investigation

### 1. AST Explorer Pattern

**Pattern**: Systematic exploration of AST node structure.

```haxe
static function exploreExpr(expr: Expr, depth: Int = 0): Void {
    var indent = StringTools.rpad("", " ", depth * 2);
    trace(indent + "Expr: " + expr.expr);
    
    switch (expr.expr) {
        case EMeta(meta, innerExpr):
            trace(indent + "  Meta: " + meta.name);
            trace(indent + "  Params: " + meta.params);
            exploreExpr(innerExpr, depth + 1);
            
        case EFunction(kind, func):
            trace(indent + "  Kind: " + kind);
            trace(indent + "  Args: " + func.args.length);
            trace(indent + "  Return: " + func.ret);
            if (func.expr != null) {
                exploreExpr(func.expr, depth + 1);
            }
            
        case EBlock(exprs):
            trace(indent + "  Block with " + exprs.length + " expressions");
            for (i => e in exprs) {
                trace(indent + "  [" + i + "]:");
                exploreExpr(e, depth + 1);
            }
            
        case ECall(e, params):
            trace(indent + "  Call with " + params.length + " params");
            trace(indent + "  Target:");
            exploreExpr(e, depth + 1);
            for (i => p in params) {
                trace(indent + "  Param[" + i + "]:");
                exploreExpr(p, depth + 1);
            }
            
        case _:
            trace(indent + "  (leaf node)");
    }
}
```

### 2. Type Structure Analysis

**Pattern**: Understand ComplexType structures and their variants.

```haxe
static function analyzeComplexType(type: ComplexType, label: String): Void {
    trace("=== " + label + " Type Analysis ===");
    
    switch (type) {
        case TPath(p):
            trace("TPath:");
            trace("  name: " + p.name);
            trace("  pack: [" + p.pack.join(", ") + "]");
            trace("  params: " + p.params.length);
            for (i => param in p.params) {
                trace("  param[" + i + "]: " + param);
            }
            
        case TFunction(args, ret):
            trace("TFunction:");
            trace("  args: " + args.length);
            trace("  return: " + ret);
            
        case TAnonymous(fields):
            trace("TAnonymous with " + fields.length + " fields");
            
        case TParent(t):
            trace("TParent:");
            analyzeComplexType(t, "Wrapped");
            
        case TOptional(t):
            trace("TOptional:");
            analyzeComplexType(t, "Optional");
            
        case _:
            trace("Other type: " + type);
    }
}
```

### 3. Metadata Structure Investigation

**Pattern**: Understand metadata structure and content.

```haxe
static function analyzeMetadata(meta: Metadata, label: String): Void {
    trace("=== " + label + " Metadata Analysis ===");
    
    if (meta == null) {
        trace("No metadata");
        return;
    }
    
    trace("Metadata entries: " + meta.length);
    for (i => entry in meta) {
        trace("Entry[" + i + "]:");
        trace("  name: " + entry.name);
        trace("  pos: " + entry.pos);
        trace("  params: " + (entry.params != null ? entry.params.length : 0));
        
        if (entry.params != null) {
            for (j => param in entry.params) {
                trace("    param[" + j + "]: " + param.toString());
            }
        }
    }
}
```

## Type System Debugging

### 1. Type Resolution Investigation

**Pattern**: Debug how Haxe resolves types in different contexts.

```haxe
static function investigateTypeResolution(expr: Expr): Void {
    try {
        var type = Context.typeof(expr);
        trace("Type resolution successful:");
        trace("  Expression: " + expr.toString());
        trace("  Resolved type: " + type);
        trace("  Type string: " + type.toString());
        
        // Further analysis
        switch (type) {
            case TInst(t, params):
                var cls = t.get();
                trace("  Instance of: " + cls.name);
                trace("  Package: " + cls.pack.join("."));
                trace("  Type params: " + params.length);
                
            case TType(t, params):
                var typedef = t.get();
                trace("  Typedef: " + typedef.name);
                trace("  Package: " + typedef.pack.join("."));
                
            case _:
                trace("  Other type variant: " + type);
        }
        
    } catch (e: Dynamic) {
        trace("Type resolution failed:");
        trace("  Expression: " + expr.toString());
        trace("  Error: " + e);
    }
}
```

### 2. Import Impact Analysis

**Pattern**: Understand how imports affect type representation.

```haxe
static function analyzeImportImpact(): Void {
    trace("=== Import Impact Analysis ===");
    
    // Test with different import scenarios
    var promiseImported = macro: Promise<String>;  // After import js.lib.Promise
    var promiseQualified = macro: js.lib.Promise<String>;  // Fully qualified
    
    trace("Imported form:");
    analyzeComplexType(promiseImported, "Promise<String> (imported)");
    
    trace("Qualified form:");
    analyzeComplexType(promiseQualified, "js.lib.Promise<String> (qualified)");
    
    // Compare AST structures
    switch ([promiseImported, promiseQualified]) {
        case [TPath(imported), TPath(qualified)]:
            trace("Comparison:");
            trace("  Imported pack: [" + imported.pack.join(", ") + "]");
            trace("  Qualified pack: [" + qualified.pack.join(", ") + "]");
            trace("  Names equal: " + (imported.name == qualified.name));
            trace("  Packs equal: " + (imported.pack.join(".") == qualified.pack.join(".")));
        case _:
    }
}
```

### 3. Type Compatibility Testing

**Pattern**: Test type relationships and compatibility.

```haxe
static function testTypeCompatibility(type1: ComplexType, type2: ComplexType): Void {
    trace("=== Type Compatibility Test ===");
    trace("Type 1: " + type1);
    trace("Type 2: " + type2);
    
    try {
        var unified = Context.getType(type1.toString());
        trace("Type 1 resolves to: " + unified);
    } catch (e: Dynamic) {
        trace("Type 1 resolution failed: " + e);
    }
    
    try {
        var unified = Context.getType(type2.toString());
        trace("Type 2 resolves to: " + unified);
    } catch (e: Dynamic) {
        trace("Type 2 resolution failed: " + e);
    }
    
    // Test structural equality
    var structurallyEqual = type1.toString() == type2.toString();
    trace("Structurally equal: " + structurallyEqual);
}
```

## Compilation Error Analysis

### 1. Error Context Extraction

**Pattern**: Extract maximum context from compilation errors.

```haxe
static function analyzeCompilationError(expr: Expr, operation: String): Void {
    trace("=== Compilation Error Analysis ===");
    trace("Operation: " + operation);
    trace("Expression: " + expr.toString());
    trace("Position: " + expr.pos);
    
    // Try to get more context
    try {
        var type = Context.typeof(expr);
        trace("Expression type: " + type);
    } catch (e: Dynamic) {
        trace("Cannot determine expression type: " + e);
    }
    
    // Analyze expression structure
    exploreExpr(expr, 0);
}
```

### 2. Progressive Compilation Testing

**Pattern**: Test compilation in stages to isolate issues.

```haxe
static function testCompilationStages(originalExpr: Expr): Expr {
    trace("=== Progressive Compilation Test ===");
    
    // Stage 1: Test if original expression compiles
    try {
        Context.typeof(originalExpr);
        trace("Stage 1: Original expression compiles");
    } catch (e: Dynamic) {
        trace("Stage 1: Original expression fails: " + e);
        return originalExpr; // Return as-is if original fails
    }
    
    // Stage 2: Test basic transformation
    var basicTransform = performBasicTransform(originalExpr);
    try {
        Context.typeof(basicTransform);
        trace("Stage 2: Basic transform compiles");
    } catch (e: Dynamic) {
        trace("Stage 2: Basic transform fails: " + e);
        return originalExpr; // Fallback to original
    }
    
    // Stage 3: Test full transformation
    var fullTransform = performFullTransform(basicTransform);
    try {
        Context.typeof(fullTransform);
        trace("Stage 3: Full transform compiles");
        return fullTransform;
    } catch (e: Dynamic) {
        trace("Stage 3: Full transform fails: " + e);
        return basicTransform; // Fallback to basic
    }
}
```

### 3. Error Message Enhancement

**Pattern**: Provide detailed error messages for macro failures.

```haxe
static function enhancedError(message: String, expr: Expr, context: String): Void {
    var errorReport = "Enhanced Error Report:\n";
    errorReport += "  Context: " + context + "\n";
    errorReport += "  Message: " + message + "\n";
    errorReport += "  Expression: " + expr.toString() + "\n";
    errorReport += "  Position: " + expr.pos + "\n";
    
    // Add AST information
    errorReport += "  AST Type: " + expr.expr + "\n";
    
    // Add type information if available
    try {
        var type = Context.typeof(expr);
        errorReport += "  Resolved Type: " + type + "\n";
    } catch (e: Dynamic) {
        errorReport += "  Type Resolution Failed: " + e + "\n";
    }
    
    // Add context information
    errorReport += getDebugContext();
    
    Context.error(errorReport, expr.pos);
}
```

## Testing and Validation

### 1. Incremental Test Development

**Pattern**: Build tests incrementally to catch issues early.

```haxe
// Test progression:
// 1. Minimal case
static function testMinimal(): Void {
    var simple = @:async function() {
        trace("hello");
    };
}

// 2. Basic functionality
static function testBasic(): Void {
    var withReturn = @:async function() {
        return "result";
    };
}

// 3. Type annotations
static function testTyped(): Void {
    var typed = @:async function(): Promise<String> {
        return "typed result";
    };
}

// 4. Complex scenarios
static function testComplex(): Void {
    var complex = @:async function() {
        var data = Async.await(loadData());
        return processData(data);
    };
}
```

### 2. Output Verification Strategies

**Pattern**: Multiple levels of output verification.

```bash
# Level 1: Compilation success
haxe compile.hxml
echo "Exit code: $?"

# Level 2: Output file generation
ls -la out/main.js
echo "File size: $(wc -c < out/main.js) bytes"

# Level 3: Content verification
grep -n "Promise.resolve" out/main.js
grep -n "async function" out/main.js

# Level 4: Full comparison
diff intended/main.js out/main.js
```

### 3. Regression Testing

**Pattern**: Ensure changes don't break existing functionality.

```haxe
class RegressionTests {
    public static function main(): Void {
        // Test all previously working cases
        testCase1(); // Original functionality
        testCase2(); // Previous bug fix
        testCase3(); // Edge case handling
        testCase4(); // New functionality
    }
    
    static function testCase1(): Void {
        // Reproduce exact case from previous implementation
        // Ensure it still works
    }
}
```

## Performance Debugging

### 1. Compilation Time Measurement

**Pattern**: Measure macro execution time.

```haxe
static var startTime: Float;

static function startTiming(operation: String): Void {
    startTime = Sys.time();
    trace("Starting: " + operation);
}

static function endTiming(operation: String): Void {
    var elapsed = Sys.time() - startTime;
    trace("Completed: " + operation + " in " + elapsed + "s");
}

// Usage
static function build(): Array<Field> {
    startTiming("build macro");
    
    var result = performBuild();
    
    endTiming("build macro");
    return result;
}
```

### 2. Memory Usage Analysis

**Pattern**: Monitor memory usage during macro execution.

```haxe
static function checkMemoryUsage(label: String): Void {
    #if cpp
    var used = cpp.vm.Gc.memInfo().currentUsage;
    trace(label + " - Memory: " + used + " bytes");
    #else
    trace(label + " - Memory tracking not available");
    #end
}
```

### 3. Optimization Identification

**Pattern**: Identify performance bottlenecks.

```haxe
static function profileTransformation(): Void {
    var operations = [
        "metadata detection",
        "AST traversal", 
        "type transformation",
        "expression building",
        "validation"
    ];
    
    for (op in operations) {
        startTiming(op);
        // Perform operation
        endTiming(op);
    }
}
```

## Common Issues and Solutions

### 1. Empty Pack Arrays (Import Resolution)

**Issue**: Imported types show empty pack arrays in AST.

**Example**:
```haxe
// User writes: Promise<String>
// AST shows: TPath({name: Promise, pack: []})
// Expected: TPath({name: Promise, pack: ["js", "lib"]})
```

**Solution**: Handle both forms in pattern matching.
```haxe
case TPath(p) if (p.name == "Promise" && (p.pack.length == 0 || p.pack.join(".") == "js.lib")):
```

### 2. Double-Wrapping Types

**Issue**: Applying transformation multiple times.

**Symptoms**: `Promise<Promise<T>>` errors.

**Solution**: Check if already transformed.
```haxe
if (isAlreadyWrapped(returnType)) {
    return returnType; // Don't double-wrap
}
```

### 3. AST Structure Assumptions

**Issue**: Assuming specific AST structures that may vary.

**Problem**: Code like this breaks on edge cases:
```haxe
// Assumes EBlock always has expressions
case EBlock(exprs):
    var lastExpr = exprs[exprs.length - 1]; // May crash if empty
```

**Solution**: Defensive programming:
```haxe
case EBlock(exprs):
    if (exprs.length > 0) {
        var lastExpr = exprs[exprs.length - 1];
        // Process safely
    }
```

### 4. Context Loss in Transformations

**Issue**: Losing important context during transformation.

**Example**: Position information gets lost, making debugging harder.

**Solution**: Always preserve position:
```haxe
{
    expr: transformedExpr,
    pos: originalExpr.pos  // Preserve original position
}
```

### 5. Metadata Processing Order

**Issue**: Processing metadata in wrong order causes conflicts.

**Solution**: Process in logical order:
```haxe
// 1. Detect and validate metadata
// 2. Transform based on metadata
// 3. Remove old metadata
// 4. Add new metadata for downstream processing
```

## Debugging Checklist

Before investigating a macro issue:

- [ ] Can you reproduce with minimal test case?
- [ ] Have you added strategic trace statements?
- [ ] Do you understand the input AST structure?
- [ ] Have you verified type resolution works?
- [ ] Are you handling import resolution correctly?
- [ ] Have you tested edge cases (null, empty, malformed)?
- [ ] Are you preserving position information?
- [ ] Is the generated code syntactically correct?
- [ ] Does the transformation preserve semantics?
- [ ] Have you tested both development and production builds?

## Conclusion

Effective macro debugging requires systematic investigation, appropriate tooling, and understanding of Haxe's compilation process. The key is to gather evidence through traces and testing rather than making assumptions about how the system works.

**Remember**:
- Start simple and build complexity gradually
- Use concrete evidence (traces, output) over assumptions
- Test edge cases thoroughly
- Document unexpected behaviors for future reference
- Remove debug traces before production commits

These debugging strategies will help you develop robust, reliable macros for Reflaxe.Elixir.