# Context Preservation Pattern in AST Builders

**Date**: January 2025 (Completed: October 2025)
**Status**: ✅ **COMPLETE** - All builders refactored
**Impact**: Affects all AST builders that compile nested expressions

## 🚨 The Problem: Context Isolation Bug

### Symptom
Pattern-bound variables in switch cases were being assigned `nil` instead of being used directly from the pattern:

```elixir
# BUGGY OUTPUT (before fix):
case result do
  {:ok, value} ->
    value = nil          # ❌ Incorrect nil assignment
    "Success: #{value}"  # Uses nil instead of pattern value
end

# CORRECT OUTPUT (after fix):
case result do
  {:ok, value} ->
    "Success: #{value}"  # ✅ Uses pattern value directly
end
```

### Root Cause
Multiple AST builders were calling `context.compiler.compileExpressionImpl()` which creates a **NEW compilation context**, losing important metadata like:
- `ClauseContext.localToName` - Maps pattern variables to prevent re-declaration
- `tempVarRenameMap` - Maps infrastructure variables to their correct names
- Other context-specific state

### The Architecture Chain
```
TypedExpr
  ↓
SwitchBuilder.buildCaseClause()
  - Registers pattern variables in ClauseContext.localToName
  - map.set(tvarId, "value")
  ↓
Body is TBlock → delegates to BlockBuilder
  ↓
BlockBuilder.build()
  - Calls compiler.compileExpressionImpl() ❌ CREATES NEW CONTEXT!
  - ClauseContext registrations LOST
  ↓
TVar handler runs in NEW context
  - Doesn't see localToName registrations
  - Generates "value = nil" ❌ WRONG!
```

## ✅ The Solution: Direct ElixirASTBuilder Calls

### Pattern: Preserve Context Through Pipeline

**WRONG** (Creates new context):
```haxe
// In any builder
var result = context.compiler.compileExpressionImpl(expr, false);
```

**RIGHT** (Preserves context):
```haxe
// In any builder
var result = reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(expr, context);
```

### Why This Works

`ElixirASTBuilder.buildFromTypedExpr()` uses the **SAME** context passed to it:
1. Receives context with ClauseContext registered
2. Compiles expression using that SAME context
3. Passes SAME context to nested builders
4. TVar handler sees ClauseContext.localToName
5. Correctly skips pattern-bound variables

`compiler.compileExpressionImpl()` creates a **NEW** context:
1. Creates fresh CompilationContext (line 1042 in ElixirCompiler.hx)
2. Loses ClauseContext registrations
3. Nested compilation runs in isolated context
4. TVar handler doesn't see pattern variables
5. Incorrectly generates nil assignments

## 📋 Builders Fixed (January 2025 - Completed October 2025)

### ✅ **ALL BUILDERS COMPLETE** - 36 Total Instances Fixed

**ObjectBuilder.hx** (13/13 instances fixed):
- Lines 154, 289, 303, 313, 379-380, 412-413, 503, 527, 556: Field value compilation
- **Why critical**: Compiles object/tuple/map field expressions in case bodies

**BlockBuilder.hx** (10/10 instances fixed):
- Lines 98, 243, 276-278, 297, 365-366, 412-413, 503, 513, 532, 566: Block expression handling
- **Why critical**: Most expression types delegate through BlockBuilder

**SwitchBuilder.hx** (2/2 instances fixed):
- Lines 139, 187: Switch target and default case compilation
- **Why critical**: Compiles switch case bodies where pattern variables are used

**ExceptionBuilder.hx** (3/3 instances fixed):
- Lines 75, 98, 141: Try body, catch body, and throw expressions
- **Why critical**: Preserves context in exception handling

**FieldAccessBuilder.hx** (3/3 instances fixed):
- Lines 214, 251, 283: Static, instance, and dynamic field access
- **Why critical**: Maintains context when accessing fields in patterns

**ReturnBuilder.hx** (3/3 instances fixed):
- Lines 86, 270, 279: Normal returns and switch returns
- **Why critical**: Preserves context for return value expressions

**FunctionBuilder.hx** (1/1 instance fixed):
- Line 115: Function body compilation
- **Why critical**: Maintains context for function parameter scope

**Verification**: `grep -r "compiler\.compileExpressionImpl" src/reflaxe/elixir/ast/builders/` returns zero instances

## 🎯 When This Pattern Matters

### Critical Scenarios

1. **Switch case bodies with pattern variables**:
   ```haxe
   switch(result) {
     case Ok(value):
       useValue(value);  // 'value' from pattern
   }
   ```

2. **Nested blocks in switch cases**:
   ```haxe
   switch(result) {
     case Ok(value):
       {
         var processed = transform(value);
         processed;
       }
   }
   ```

3. **Infrastructure variable substitution**:
   ```haxe
   var result = switch(expr) { ... }
   // 'result' might be infrastructure var needing substitution
   ```

### Less Critical But Still Important

4. **Function parameters**:
   - tempVarRenameMap tracks parameter renamings
   - Losing context could cause incorrect parameter names

5. **Variable shadowing contexts**:
   - Context tracks variable scopes
   - Losing context could cause shadowing issues

## 🔍 How to Identify This Bug

### Code Smell Checklist

```haxe
// ❌ RED FLAG: Builder calling compiler.compileExpressionImpl
class SomeBuilder {
    static function build(expr: TypedExpr, context: CompilationContext) {
        var result = context.compiler.compileExpressionImpl(expr, false);
        // Context lost!
    }
}

// ✅ CORRECT: Builder calling buildFromTypedExpr directly
class SomeBuilder {
    static function build(expr: TypedExpr, context: CompilationContext) {
        var result = reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(expr, context);
        // Context preserved!
    }
}
```

### Grep Pattern to Find Issues
```bash
grep -r "compiler\.compileExpressionImpl" src/reflaxe/elixir/ast/builders/
```

## 🧪 Testing Pattern Fixes

### Create Focused Regression Test

```haxe
// test/snapshot/regression/pattern_variable_direct_use/Main.hx
enum Result<T, E> {
    Ok(value: T);
    Error(error: E);
}

class Main {
    public static function main() {
        var message = switch(Ok("success")) {
            case Ok(value):
                "Success: " + value;  // Should use pattern variable directly
            case Error(error):
                "Error: " + error;
        }
        trace(message);
    }
}
```

### Expected Generated Code
```elixir
defmodule Main do
  def main() do
    message = case {:ok, "success"} do
      {:ok, value} ->
        "Success: #{value}"  # ✅ Direct use, no nil assignment
      {:error, error} ->
        "Error: #{error}"
    end
  end
end
```

### Test Checklist
- [ ] Pattern variables used directly (no `value = nil` assignments)
- [ ] Infrastructure variables substituted correctly
- [ ] No context-dependent bugs (parameter naming, etc.)
- [ ] All existing tests still pass

## 📚 Architecture Principles

### 1. Context is Precious State
The CompilationContext carries critical information that must flow through the entire compilation pipeline:
- Variable mappings (pattern variables, infrastructure variables)
- Scope information (current function, current clause)
- Feature flags (new vs legacy behavior)
- Compiler reference (for utilities)

### 2. Builders Should Delegate, Not Isolate
When a builder needs to compile a sub-expression, it should **delegate** to ElixirASTBuilder while **preserving** the context, not create a new isolated context.

### 3. ElixirCompiler.compileExpressionImpl is an Entry Point
The `compileExpressionImpl` method is designed as a **top-level entry point** that creates a fresh context. It should ONLY be called from:
- The Reflaxe framework (external compilation requests)
- Top-level compilation (modules, classes, enums)

It should NEVER be called from within builders for nested expressions.

### 4. Single Source of Truth for Compilation
`ElixirASTBuilder.buildFromTypedExpr` is the single source of truth for compiling TypedExpr → ElixirAST with context preservation.

## 🔮 Future Work

### Systematic Refactoring Needed

1. **Audit all builders** for `compiler.compileExpressionImpl` usage
2. **Create helper utilities** to make context preservation obvious
3. **Add compile-time checks** to prevent future violations
4. **Document pattern** in all builder files

### Possible Helper Pattern
```haxe
// Utility to make context preservation explicit
class BuilderUtils {
    static inline function compileWithContext(
        expr: TypedExpr,
        context: CompilationContext
    ): ElixirAST {
        return reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(expr, context);
    }
}

// Usage in builders becomes obvious
var result = BuilderUtils.compileWithContext(expr, context);
```

## 📖 References

- **Original Bug Report**: infrastructure_variable_substitution test
- **Fix Commit**: [To be filled after commit]
- **Related Pattern**: TypedExpr Preprocessor (also preserves context)
- **See Also**: `/docs/03-compiler-development/CLAUDE.md` - Compiler development context

---

**Remember**: When in doubt, preserve context. Direct calls to `ElixirASTBuilder.buildFromTypedExpr` are almost always correct.
