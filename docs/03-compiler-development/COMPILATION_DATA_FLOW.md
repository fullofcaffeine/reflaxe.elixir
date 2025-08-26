# Compilation Data Flow Documentation

## Overview

This document comprehensively traces the data flow of the Haxe→Elixir compiler to understand why certain functions bypass proper parameter handling, leading to the "unused parameter" compilation errors.

## Complete Compilation Flow

### 1. Entry Point: ElixirCompiler.hx

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

## The Architectural Flaw

### Current State (BROKEN)
```
detectUsedParameters() → Prefix with _ → compileExpression() 
                                            ↑
                                    Body still uses original names
```

### Required State (FIXED)
```
detectUsedParameters() → Prefix with _ → Map params → compileExpression()
                                            ↑
                                    Body uses mapped names
```

## Functions That Bypass FunctionCompiler

Based on the code analysis, these types of functions bypass FunctionCompiler:
1. **Static utility functions** (like TypeSafeChildSpecTools.toLegacy)
2. **Module functions** (with @:module annotation)
3. **Struct instance methods** (compiled via ClassCompiler)
4. **Regular class static methods** (compiled via ClassCompiler)

Only certain special cases seem to use FunctionCompiler directly.

## The Root Cause

The root cause is **architectural inconsistency**: 
- Some functions go through FunctionCompiler (with proper parameter handling)
- Most functions go through ClassCompiler.generateFunction() (with incomplete parameter handling)
- The two paths have different parameter handling logic
- ClassCompiler detects unused parameters but doesn't map them in the body

## Required Fix

### Option 1: Unify Under FunctionCompiler
Make ALL function compilation go through FunctionCompiler:
```haxe
// In ClassCompiler.generateFunction()
return functionCompiler.compileFunction(funcField, isInstance, isStructClass);
```

### Option 2: Fix ClassCompiler's Parameter Mapping
Add parameter mapping to ClassCompiler.compileExpressionForFunction():
```haxe
// Map original names to prefixed names before compilation
if (paramWasPrefixed) {
    compiler.setParameterMapping(originalName, prefixedName);
}
```

### Option 3: Disable Underscore Prefixing (Current Workaround)
Simply don't prefix unused parameters - generates warnings but compiles correctly.

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

The compiler has two separate function compilation paths with inconsistent parameter handling. TypeSafeChildSpecTools and similar utility classes use the ClassCompiler path, which detects unused parameters and prefixes them but doesn't update references in the function body. This architectural inconsistency must be resolved by either:
1. Unifying all function compilation through FunctionCompiler
2. Fixing ClassCompiler's parameter mapping
3. Removing underscore prefixing entirely (least ideal)

The proper solution is to ensure ALL functions go through the same compilation pipeline with consistent parameter handling.