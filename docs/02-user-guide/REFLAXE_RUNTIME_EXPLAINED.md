# Reflaxe Runtime Flag Explained ⚠️ CRITICAL UNDERSTANDING

**MANDATORY READING** for understanding compilation contexts in Reflaxe.Elixir

## Overview

The `reflaxe_runtime` flag is one of the most misunderstood aspects of Reflaxe development. **Despite its name, it's NOT about runtime execution** - it's a compilation flag that controls when macro-time compiler classes are visible during test compilation.

## The Three Execution Contexts

### 1. **Macro-Time** (Normal Compilation)
```bash
haxe build.hxml -lib reflaxe.elixir
```

**What happens**: 
- ElixirCompiler runs as a macro during `Context.onAfterTyping`
- Transpiles Haxe AST → Elixir source code
- Compiler classes exist ONLY during compilation
- Generated `.ex` files contain no trace of compiler classes

**Context Pattern**:
```haxe
#if macro
class ElixirCompiler extends BaseCompiler {
    // This class ONLY exists while Haxe is compiling
    // Disappears after compilation completes
}
#end
```

### 2. **Test-Time** (With `-D reflaxe_runtime`)
```bash
haxe test.hxml -D reflaxe_runtime --interp
```

**What happens**:
- Compiler classes become visible in non-macro contexts
- Enables testing of compiler functionality
- Still NOT true runtime - it's "test compilation context"
- elixir.Syntax methods become available for validation

**Context Pattern**:
```haxe
#if (elixir || reflaxe_runtime)
class Syntax {
    // Available during Elixir compilation AND test compilation
    public static function code(code: String): Dynamic;
}
#end
```

### 3. **True Runtime** (BEAM VM Execution)
```bash
# In Elixir/BEAM after compilation
mix test
iex -S mix
```

**What happens**:
- Only generated Elixir code exists
- NO Haxe compiler classes present
- NO elixir.Syntax methods exist
- Pure Elixir/BEAM execution

## Common Misconceptions ❌

### ❌ Misconception: "reflaxe_runtime enables runtime execution"
**Reality**: It enables test-time compilation, not runtime execution

### ❌ Misconception: "elixir.Syntax.code() runs at runtime"
**Reality**: It should be processed at macro-time, never called at runtime

### ❌ Misconception: "reflaxe_runtime makes code available at runtime"
**Reality**: It makes compiler code available during test compilation only

## Correct Usage Patterns ✅

### Pattern 1: Macro-Only Classes
```haxe
#if macro
class CompilerHelper {
    // Only available during compilation
    public static function processAST(expr: TypedExpr): String;
}
#end
```

### Pattern 2: Cross-Context Classes (Standard Library)
```haxe
#if (elixir || reflaxe_runtime)
class Syntax {
    // Available in Elixir target AND for testing
    public static function code(code: String): Dynamic;
}
#end
```

### Pattern 3: Runtime-Only Classes
```haxe
// No conditional compilation
class Date {
    // Always available - compiles to target code
    public function getTime(): Float;
}
```

## Testing Implications

### Why We Need reflaxe_runtime for Tests

**Problem**: Standard library classes like `elixir.Syntax` need to be testable
**Solution**: `reflaxe_runtime` makes them visible during test compilation

```haxe
// std/Date.hx
#if (elixir || reflaxe_runtime)
import elixir.Syntax;
#end

abstract Date(Float) {
    public function new(year: Int, month: Int, day: Int) {
        // This needs to be testable, so elixir.Syntax must be visible
        var naiveDateTime = Syntax.code("NaiveDateTime.new!({0}, {1}, {2})", year, month, day);
    }
}
```

**Test Compilation**:
```bash
# Without reflaxe_runtime: ❌ "elixir.Syntax not found"
haxe -cp std -main Test --interp

# With reflaxe_runtime: ✅ Classes visible for testing
haxe -cp std -main Test --interp -D reflaxe_runtime
```

### Testing Best Practices

1. **Unit Testing**: Use `reflaxe_runtime` to test individual standard library components
2. **Integration Testing**: Use actual Elixir compilation to test end-to-end
3. **Never Test Runtime Execution**: elixir.Syntax calls should throw if actually executed

## Compilation Flow Diagram

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Macro-Time    │    │    Test-Time     │    │  True Runtime   │
│                 │    │                  │    │                 │
│ ElixirCompiler  │───▶│ elixir.Syntax    │───▶│  Generated .ex  │
│ processes AST   │    │ available for    │    │  files execute  │
│                 │    │ testing only     │    │  in BEAM VM     │
└─────────────────┘    └──────────────────┘    └─────────────────┘
      haxe build.hxml       haxe test.hxml           mix test
                           -D reflaxe_runtime
```

## Flag Usage Guidelines

### When to Use `reflaxe_runtime`
- ✅ Testing standard library components
- ✅ Validating compiler functionality
- ✅ Snapshot test compilation
- ✅ Debugging injection mechanisms

### When NOT to Use `reflaxe_runtime`
- ❌ Production compilation
- ❌ Actual application building
- ❌ Runtime execution scenarios
- ❌ BEAM VM testing

## Real-World Examples

### Standard Library Pattern
```haxe
// std/elixir/Syntax.hx
#if (elixir || reflaxe_runtime)
class Syntax {
    public static function code(code: String, args: Rest<Dynamic>): Dynamic {
        // Should be processed by compiler, never executed
        return elixir.Injection.__elixir__(code, args);
    }
}
#end
```

### Test Configuration
```bash
# Correct: Test with reflaxe_runtime
haxe -cp std -main DateTest -D reflaxe_runtime --interp

# Correct: Build without reflaxe_runtime  
haxe -cp std -main App -lib reflaxe.elixir -D elixir_output=lib
```

### Error Scenarios

**Scenario 1**: Running without `reflaxe_runtime`
```bash
$ haxe -cp std -main Test --interp
Error: Class<elixir.Syntax> has no field code
```
**Fix**: Add `-D reflaxe_runtime`

**Scenario 2**: Runtime execution error
```bash
$ haxe -cp std -main Test --interp -D reflaxe_runtime
Error: INTERNAL ERROR: __elixir__ function should never be called at runtime
```
**Expected**: This proves the type-safe API is working - it blocks runtime execution

## Architecture Integration

### How Reflaxe Handles Context
```haxe
// In reflaxe core
Context.onAfterTyping(function(types: Array<ModuleType>) {
    #if macro
    // Compiler processes types here
    var compiler = new ElixirCompiler();
    compiler.transpile(types);
    #end
});
```

### How Standard Library Integrates
```haxe
// In std/ modules
#if (elixir || reflaxe_runtime)
// Available in Elixir target AND test context
using elixir.Syntax;
#end
```

## Debugging Guide

### Common Issues

1. **"Class not found" errors**: Missing `reflaxe_runtime` flag
2. **"Should never be called" errors**: Good! Injection system working correctly
3. **Empty generated code**: Compiler not processing elixir.Syntax calls yet

### Debugging Commands
```bash
# Test type checking only
haxe -cp std -main Test --no-output -D reflaxe_runtime

# Test full compilation
haxe -cp std -main Test -lib reflaxe.elixir -D reflaxe_runtime -D elixir_output=debug

# Test interpretation (expect runtime errors)
haxe -cp std -main Test --interp -D reflaxe_runtime
```

## Summary

**Key Takeaway**: `reflaxe_runtime` is a **test compilation flag**, not a runtime flag. It makes macro-time compiler classes visible during test compilation, enabling validation of standard library components that use injection mechanisms.

**Mental Model**: 
- Macro-time = Compilation happens
- Test-time = Validation happens  
- Runtime = Execution happens

**The three contexts are completely separate and serve different purposes in the Reflaxe architecture.**