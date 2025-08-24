# Reflaxe Preprocessor Integration Patterns

> **Warning**: NEVER integrate preprocessors manually! This document explains the correct patterns to follow.

## ⚠️ CRITICAL: The Wrong Way (What NOT To Do)

### ❌ Manual Preprocessor Calls
```haxe
// FunctionCompiler.hx
// ❌ WRONG: Manual call to preprocessor
if (funcField.expr != null) {
    var expressions = funcField.expr.unwrapBlock();
    var processed = RemoveOrphanedEnumParametersImpl.remove(expressions);
    funcField.setExprList(processed);
}
```

**Why this is wrong:**
- Bypasses Reflaxe's preprocessor system
- Doesn't integrate with other preprocessors
- Breaks the established pipeline order
- Creates maintenance issues

### ❌ Direct Integration in Expression Compilation
```haxe
// ElixirCompiler.hx
// ❌ WRONG: Manual integration in compileExpression
public override function compileExpression(expr: TypedExpr, topLevel: Bool = false): Null<String> {
    // Apply custom preprocessing before compilation
    var processed = MyCustomPreprocessor.process([expr]);
    expr = processed[0];
    
    return super.compileExpression(expr, topLevel);
}
```

**Why this is wrong:**
- Violates Reflaxe's architecture
- Doesn't work with ClassFuncData.applyPreprocessors()
- Bypasses established metadata system

## ✅ The Correct Way: Using Reflaxe's Architecture

### Standard Reflaxe Preprocessor Pattern
All standard preprocessors follow this pattern:

```haxe
class MyPreprocessorImpl {
    public static function process(list: Array<TypedExpr>): Array<TypedExpr> {
        final processor = new MyPreprocessorImpl(list);
        return processor.processExpressions();
    }
    
    public function new(list: Array<TypedExpr>) {
        exprList = list;
    }
    
    public function processExpressions(): Array<TypedExpr> {
        // Process expressions
        // Mark with metadata like -reflaxe.unused
        return exprList;
    }
}
```

### Integration via ExpressionPreprocessor Pipeline
Preprocessors are integrated through the `ExpressionPreprocessor` system:

```haxe
// ElixirCompiler.hx constructor
options.expressionPreprocessors = [
    SanitizeEverythingIsExpression({}),
    RemoveTemporaryVariables(RemoveTemporaryVariablesMode.AllVariables),
    PreventRepeatVariables({}),
    // ... other standard preprocessors
    MarkUnusedVariables,  // This handles -reflaxe.unused metadata
];
```

**How it works:**
1. Each function gets processed by `ClassFuncData.applyPreprocessors()`
2. Preprocessors run in order and can mark variables with metadata
3. `VariableCompiler` respects the `-reflaxe.unused` metadata during compilation

### Custom Preprocessor Integration Options

#### Option 1: Add to Standard Pipeline (If Possible)
The cleanest approach would be adding to the ExpressionPreprocessor enum, but this requires modifying Reflaxe core:

```haxe
// In ExpressionPreprocessor.hx (Reflaxe core - we can't modify this)
enum ExpressionPreprocessor {
    // ... existing preprocessors
    RemoveOrphanedEnumParameters;  // Would need core modification
}
```

#### Option 2: Use Custom() Variant (Complex)
```haxe
// Create BasePreprocessor implementation
class OrphanedEnumParametersPreprocessor extends BasePreprocessor {
    public override function process(data: ClassFuncData, compiler: BaseCompiler): Void {
        if (data.expr != null) {
            var expressions = data.expr.unwrapBlock();
            var processed = RemoveOrphanedEnumParametersImpl.remove(expressions);
            data.setExprList(processed);
        }
    }
}

// Add to pipeline
options.expressionPreprocessors = [
    // ... standard preprocessors
    Custom(new OrphanedEnumParametersPreprocessor()),
];
```

#### Option 3: Enhanced MarkUnusedVariables (Preferred)
Instead of creating a new preprocessor, enhance the existing `MarkUnusedVariables` to handle our specific case:

```haxe
// Modify MarkUnusedVariablesImpl to detect orphaned enum parameters
// This integrates with existing architecture
```

## 🎯 The Actual Issue: Orphaned Enum Parameters

### Problem Pattern
```elixir
:set_priority -> (
    elem(action, 1)  // TEnumParameter extraction
    g_array          // Orphaned TLocal reference  
    temp_result = "set_priority"
)
```

### Root Cause Analysis
1. Haxe generates `TVar(g, TEnumParameter(...))` for enum destructuring
2. VariableMappingManager transforms `g` → `g_array` due to array context
3. MarkUnusedVariables should detect that `g_array` is never used
4. But the TLocal reference is still being generated

### Correct Fix Strategy
1. **Use existing MarkUnusedVariables** - Don't reinvent the wheel
2. **Ensure proper metadata handling** - The `-reflaxe.unused` system works
3. **Fix the root cause** - Why are orphaned TLocal references being generated?
4. **Architectural alignment** - Work with Reflaxe's established patterns

## 📋 Lessons Learned

### ⚠️ Critical Mistakes to Avoid
1. **NEVER integrate preprocessors manually** - Use the established pipeline
2. **NEVER bypass ClassFuncData.applyPreprocessors()** - This is the official API
3. **NEVER call preprocessors directly in compilation functions** - Wrong architecture
4. **NEVER create ad-hoc fixes** - Find and fix the root cause

### ✅ Correct Development Process
1. **Understand existing architecture** - Study how other preprocessors work
2. **Use established patterns** - Follow MarkUnusedVariables, RemoveConstantBoolIfs, etc.
3. **Work with the metadata system** - Use `-reflaxe.unused` and other established metadata
4. **Test with the complete pipeline** - Ensure integration with other preprocessors

### 🔍 Debugging Approach
1. **Add XRay debug traces** - Understand what's happening in the AST
2. **Check metadata** - Is `-reflaxe.unused` being set correctly?
3. **Trace variable compilation** - Why are unused variables still being generated?
4. **Verify preprocessor order** - Are preprocessors running in the right sequence?

## 🏆 Final Architecture Decision

**For the orphaned enum parameters issue:**
- **Don't create a new preprocessor** 
- **Fix the root cause in VariableCompiler or MarkUnusedVariables**
- **Work with existing `-reflaxe.unused` metadata system**
- **Follow established Reflaxe patterns**

This ensures our fix is architecturally sound, maintainable, and doesn't introduce complexity.