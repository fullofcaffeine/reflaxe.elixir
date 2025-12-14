# Target Code Injection: __elixir__() Implementation Guide

## Overview

Target code injection allows developers to directly inject raw Elixir code into the compiled output using `untyped __elixir__("raw elixir code")`. This feature is essential for:

- **Emergency escape hatches** when the compiler doesn't support specific Elixir patterns
- **Complex Elixir expressions** that don't map cleanly to Haxe constructs  
- **Native Elixir API usage** that requires precise syntax control
- **Performance-critical code** that needs direct Elixir implementation

## How Target Code Injection Works

### The Architecture

```
Haxe Source Code:
untyped __elixir__('IO.puts("Hello!")')

Haxe Parser & TypedExpr:
TCall(TIdent("__elixir__"), [TConst(TString("IO.puts(\"Hello!\")"))]) 

DirectToStringCompiler.compileExpression:
- Checks if targetCodeInjectionName == "__elixir__"
- Calls TargetCodeInjection.checkTargetCodeInjection
- Returns raw string directly: "IO.puts(\"Hello!\")"

Generated Elixir:
IO.puts("Hello!")  # Direct injection, no function call
```

### Critical Implementation Requirements

**1. Parent Call Requirement**
ElixirCompiler MUST call `super.compileExpression()` first to enable injection processing:

```haxe
// ✅ CORRECT: Enables __elixir__() injection
public override function compileExpression(expr: TypedExpr, topLevel: Bool = false): Null<String> {
    // CRITICAL: Call parent to handle target code injection
    var parentResult = super.compileExpression(expr, topLevel);
    if (parentResult != null) {
        return parentResult;  // Injection found, return directly
    }
    
    // No injection, proceed with custom logic
    return compileExpressionImpl(expr, topLevel);
}

// ❌ WRONG: Bypasses injection processing  
public override function compileExpression(expr: TypedExpr, topLevel: Bool = false): Null<String> {
    return compileExpressionImpl(expr, topLevel);  // Skips parent!
}
```

**2. Configuration Setup**
The compiler must be registered with `targetCodeInjectionName`:

```haxe
// In CompilerInit.hx
ReflectCompiler.AddCompiler(new ElixirCompiler(), {
    targetCodeInjectionName: "__elixir__",  // Enables injection detection
    // ... other options
});
```

### Usage Patterns

#### Basic Injection
```haxe
// Haxe code
static function main() {
    untyped __elixir__('IO.puts("Hello from Elixir!")');
}
```

Generates:
```elixir
def main() do
    IO.puts("Hello from Elixir!")  # Direct injection
end
```

#### Complex Elixir Expressions
```haxe
// Pipe operators and Elixir-specific syntax
var result = untyped __elixir__('[1, 2, 3] |> Enum.map(&(&1 * 2))');

// Multi-line Elixir blocks
var computation = untyped __elixir__('
    x = 10
    y = 20
    x + y
');
```

#### Within Functions
```haxe
class Logger {
    public static function logInfo(message: String): Void {
        untyped __elixir__('Logger.info("${message}")');
    }
}
```

## Testing Target Code Injection

### Test Structure
```
test/tests/ElixirInjection/
├── compile.hxml           # Standard Reflaxe configuration
├── Main.hx               # Test cases with __elixir__() calls
├── intended/main.ex      # Expected output with direct injection
└── out/main.ex          # Generated output (should match intended)
```

### Validation Approach
1. **Compilation Test**: Ensure `untyped __elixir__()` compiles without errors
2. **Output Verification**: Generated .ex files should contain raw Elixir, not function calls
3. **Syntax Test**: Injected code should be valid Elixir syntax
4. **Integration Test**: Test within various contexts (functions, classes, expressions)

## Common Issues and Solutions

### Issue 1: __elixir__() Generates Function Calls

**Symptom:**
```elixir
# ❌ WRONG: Function call instead of injection
def main() do
    __elixir__("IO.puts(\"Hello!\")")
end
```

**Root Cause:** ElixirCompiler override doesn't call parent implementation

**Solution:** Add parent call in compileExpression override

### Issue 2: "First parameter must be constant String"

**Symptom:**
```
Error: __elixir__ first parameter must be a constant String.
```

**Root Cause:** Using string interpolation or dynamic expressions

**Solution:** Only use literal strings in __elixir__() calls
```haxe
// ✅ CORRECT
untyped __elixir__('IO.puts("Static message")');

// ❌ WRONG  
var msg = "Dynamic";
untyped __elixir__('IO.puts("${msg}")');  // Not constant!
```

### Issue 3: Injection Not Detected

**Symptom:** Code compiles but __elixir__() calls aren't processed

**Root Cause:** targetCodeInjectionName not configured or parent not called

**Solution:** Verify CompilerInit configuration and compileExpression implementation

## When to Use __elixir__()

### Appropriate Use Cases

1. **Emergency Escape Hatch**
   ```haxe
   // When compiler doesn't support specific Elixir pattern
   untyped __elixir__('receive do message -> handle(message) end');
   ```

2. **Complex Native APIs**
   ```haxe
   // Elixir-specific functionality with precise syntax requirements
   untyped __elixir__('Process.send_after(self(), :timeout, 5000)');
   ```

3. **Performance-Critical Sections**
   ```haxe
   // Direct Elixir implementation for performance
   untyped __elixir__('
       :ets.lookup(table, key)
       |> List.first()
       |> elem(1)
   ');
   ```

### When NOT to Use __elixir__()

1. **Simple Method Calls**: Use `@:native` annotations instead
   ```haxe
   // ✅ BETTER: Type-safe with @:native
   @:native("IO.puts") 
   extern static function puts(message: String): Void;
   
   // ❌ WORSE: Injection for simple calls
   untyped __elixir__('IO.puts("message")');
   ```

2. **Standard Library Usage**: Use proper Haxe std library integration
3. **Business Logic**: Keep business logic in type-safe Haxe code

## Architecture Integration

### Reflaxe Framework Integration
- DirectToStringCompiler provides base injection processing
- TargetCodeInjection handles string parameter extraction and replacement
- Each target compiler configures its own injection function name

### Error Handling
- Compile-time validation ensures only constant strings are used
- Position information preserved for accurate error reporting
- Graceful fallback to nil for malformed expressions

## Related Documentation

- [NATIVE_ANNOTATION_FIX.md](NATIVE_ANNOTATION_FIX.md) - Alternative to __elixir__() for simple cases
- [../../05-architecture/REFLAXE_INTEGRATION.md](../../05-architecture/REFLAXE_INTEGRATION.md) - Broader Reflaxe framework patterns
- [COMPILER_PATTERNS.md](COMPILER_PATTERNS.md) - When to use different compilation approaches

## Summary

Target code injection via `__elixir__()` provides a powerful escape hatch for direct Elixir code generation. The key requirements are:

1. **Parent call in compileExpression override** - Enables injection processing
2. **Proper configuration** - targetCodeInjectionName must be set
3. **Constant string parameters** - Only literal strings allowed
4. **Judicious usage** - Reserve for cases where type-safe alternatives don't exist

When implemented correctly, __elixir__() provides seamless integration between Haxe's type system and Elixir's native capabilities.