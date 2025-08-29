# Compilation Data Flow Documentation

## Overview

This document comprehensively traces the data flow of the Haxe→Elixir compiler, including the single-instance architecture that enables context tracking for features like return context and pattern usage.

## Complete Compilation Flow

### 1. Single Instance Architecture

**CRITICAL: ElixirCompiler is a SINGLE INSTANCE that processes the entire AST recursively.**

```haxe
// CompilerInit.hx - ONE instance created for entire compilation
ReflectCompiler.AddCompiler(new ElixirCompiler(), {
    fileOutputExtension: ".ex",
    // ... configuration
});
```

This single-instance architecture enables:
- **Context tracking**: Instance variables persist across AST traversal
- **State management**: Maintain compilation state throughout session
- **Pattern detection**: Track patterns across multiple nodes
- **Recursive processing**: Depth-first traversal with context preservation

### 2. Entry Point: ElixirCompiler.hx

```
Context.onAfterTyping() → ElixirCompiler.compile(module: ModuleType)
```

The compiler starts when Haxe's macro system calls the `onAfterTyping` callback.

### 2. Module Type Dispatch

```haxe
// ElixirCompiler.hx (line ~800-900)
switch(module) {
    case TClassDecl(classRef):
        var classType = classRef.get();
        compileClassImpl(classType, pos);
        
    case TEnumDecl(enumRef):
        var enumType = enumRef.get();
        compileEnumImpl(enumType, pos);
        
    case TAbstract(abstractRef):
        var abstractType = abstractRef.get();
        compileAbstractImpl(abstractType, pos);
}
```

### 3. Class Compilation Path

```
ElixirCompiler.compileClassImpl()
    ↓
ClassCompiler.compileClass()
    ↓
ClassCompiler.generateFunctions() or generateModuleFunctions()
    ↓
ClassCompiler.generateFunction()
    ↓
ClassCompiler.compileExpressionForFunction()
    ↓
compiler.compileExpression() // Back to ElixirCompiler
```

## The Critical Architectural Issue

### Problem: Two Separate Function Compilation Paths

#### Path 1: FunctionCompiler (Used by some classes)
- **Location**: helpers/FunctionCompiler.hx
- **Features**: 
  - Comprehensive parameter usage detection
  - Proper parameter mapping for underscore prefixing
  - Handles Reflaxe's `-reflaxe.unused` metadata
- **When used**: Only for specific class types (not consistently)

#### Path 2: ClassCompiler.generateFunction() (Used by TypeSafeChildSpecTools)
- **Location**: helpers/ClassCompiler.hx
- **Features**:
  - Has its own detectUsedParameters() method
  - Detects unused parameters and prefixes with underscore
  - BUT: Doesn't properly map parameters in function body
- **When used**: For all regular classes with static/instance methods

### Why TypeSafeChildSpecTools Functions Fail

1. **TypeSafeChildSpecTools** is a utility class with static methods
2. It gets compiled through **ClassCompiler.generateFunctions()**
3. ClassCompiler detects that `spec` parameter is unused (due to switch pattern)
4. ClassCompiler prefixes parameter with underscore: `_spec`
5. ClassCompiler calls `compiler.compileExpression()` for the function body
6. The function body still references `spec` (not `_spec`)
7. **Result**: `def to_legacy(_spec, app_name) do ... elem(spec, 0) ...` → ERROR

### The Missing Link

ClassCompiler.generateFunction() does this:
```haxe
// Line 652-655: Detect unused parameters
var usedParams = detectUsedParameters(funcField.expr, funcField.args);

// Line 675-678: Prefix unused parameters with underscore
var paramName = isUsed ? name : '_${name}';

// Line 760: Compile body WITHOUT parameter mapping
var compiledBody = compileExpressionForFunction(funcField.expr, funcField.args);
```

But `compileExpressionForFunction()` doesn't map the original parameter names to the prefixed versions!

## The Architectural Flaw (NOW FIXED)

### Previous State (WAS BROKEN - Before Fix)
```
detectUsedParameters() → Prefix with _ → compileExpression() 
                                            ↑
                                    Body still uses original names
```

### Current State (FIXED - After Architectural Refactoring)
```
ALL Functions → ClassCompiler.generateFunction() → FunctionCompiler.compileFunction()
                     (delegates)                        (single implementation)
                                                              ↓
                                            Proper parameter detection & mapping
```

## Functions Now Using Unified Pipeline (FIXED)

After the architectural refactoring, ALL function types now go through FunctionCompiler:
1. **Static utility functions** ✅ (like TypeSafeChildSpecTools.toLegacy)
2. **Module functions** ✅ (with @:module annotation)
3. **Struct instance methods** ✅ (compiled via ClassCompiler delegation)
4. **Regular class static methods** ✅ (compiled via ClassCompiler delegation)

The dual-path architecture has been eliminated.

## The Root Cause (RESOLVED)

The root cause **was** architectural inconsistency: 
- Some functions went through FunctionCompiler (with proper parameter handling)
- Most functions went through ClassCompiler.generateFunction() (with incomplete parameter handling)
- The two paths had different parameter handling logic
- ClassCompiler detected unused parameters but didn't map them in the body

## The Implemented Fix

### ✅ Option 1: Unified Under FunctionCompiler (IMPLEMENTED)
We successfully unified ALL function compilation through FunctionCompiler:
```haxe
// In ClassCompiler.generateFunction() - NOW IMPLEMENTED
private function generateFunction(funcField: ClassFuncData, isInstance: Bool, isStructClass: Bool): String {
    // Delegates ALL function compilation to FunctionCompiler
    return compiler.functionCompiler.compileFunction(
        funcField,
        !isInstance,  // isStatic
        isInstance,
        isStructClass,
        currentClassName
    );
}
```

### Changes Made:
1. **Enhanced FunctionCompiler** to handle all function types
2. **Removed ~400 lines** of duplicate code from ClassCompiler
3. **Made functionCompiler public** in ElixirCompiler for delegation
4. **Deleted duplicate methods**: detectUsedParameters(), compileExpressionForFunction()
5. **Updated generateModuleFunctions()** to also delegate

## Validation

After implementing the fix, validate with:
```bash
# Clean and regenerate
rm -rf examples/todo-app/lib/*.ex
cd examples/todo-app
npx haxe build-server.hxml
mix compile --force

# Check TypeSafeChildSpecTools.ex
grep "def to_legacy" lib/elixir/otp/type_safe_child_spec_tools.ex
# Should show consistent parameter usage
```

## Conclusion

✅ **FIXED**: The compiler previously had two separate function compilation paths with inconsistent parameter handling. This architectural inconsistency has been resolved by unifying all function compilation through FunctionCompiler.

### What Was Fixed:
- **Eliminated dual compilation paths** - All functions now use one pipeline
- **Removed ~400 lines of duplicate code** from ClassCompiler  
- **Ensured consistent parameter handling** across all function types
- **Created single source of truth** for function compilation logic

### Remaining Work:
- **Parameter usage detection** in FunctionCompiler still needs enhancement for complex expressions like `elem(param, 0)`
- This is a detection logic issue, not an architectural problem

## Context Tracking Pattern

The single-instance architecture enables powerful context tracking through instance variables:

### Pattern: Set → Use → Clear

```haxe
// 1. Define context variable in ElixirCompiler
public var returnContext: Bool = false;
public var patternUsageContext: Map<String, Bool> = null;

// 2. SET context before compiling sub-expressions  
compiler.returnContext = true;

// 3. Sub-expressions USE the context
var result = compiler.compileExpression(expr);
// PatternMatchingCompiler checks: if (compiler.returnContext) ...

// 4. CLEAR context after compilation
compiler.returnContext = false;
```

### Examples of Context Variables

- **`patternUsageContext`**: Tracks which enum pattern variables are used
- **`returnContext`**: Indicates when compiling return expressions
- **`currentSwitchCaseBody`**: Current switch case being compiled
- **`currentFunctionParameterMap`**: Parameter name mappings
- **`isStateThreadingEnabled`**: Tracks mutable struct compilation

### Why Context Tracking Works

1. **Single-threaded compilation**: No race conditions
2. **Depth-first traversal**: Context flows parent → child naturally
3. **Explicit lifecycle**: Prevents context pollution
4. **Proven pattern**: Successfully used for enum patterns, return contexts, etc

The architectural refactoring ensures ALL functions go through the same compilation pipeline with consistent parameter handling, making the compiler more maintainable and reliable.