# Two `__elixir__()` Injection Systems

## Executive Summary

Reflaxe.Elixir uses **two different systems** for handling `__elixir__()` code injection, each serving a distinct purpose:

1. **Reflaxe's TargetCodeInjection** - For direct user code
2. **Method Body Inspection** - For standard library implementations

## System 1: Reflaxe's TargetCodeInjection (Direct User Code)

### When It's Used
When developers write `untyped __elixir__()` **directly in application code**:

```haxe
// Application code (Main.hx, TodoLive.hx, etc.)
class MyApp {
    function example() {
        // Direct __elixir__() call in user code
        var time = untyped __elixir__("DateTime.utc_now()");
        var result = untyped __elixir__("IO.inspect({0})", value);
    }
}
```

### How It Works
1. **Reflaxe Framework Injection**: Reflaxe's macro system adds the `__elixir__` identifier to the global scope
2. **Early Expansion**: Before our compiler even sees it, Reflaxe expands these calls
3. **TypedExpr AST**: We receive already-expanded AST with inline Elixir code
4. **No Compiler Action Needed**: Our compiler just processes the expanded AST

### Configuration
Set up in `CompilerInit.hx`:
```haxe
targetCodeInjectionName: "__elixir__"
```

### Expected Result
```elixir
# Should generate inline Elixir:
time = DateTime.utc_now()
result = IO.inspect(value)

# NOT literal function calls:
time = __elixir__.("DateTime.utc_now()")  # ❌ WRONG
```

## System 2: Method Body Inspection (Standard Library)

### When It's Used
When `__elixir__()` is **inside standard library method implementations**:

```haxe
// Standard library (std/Array.hx, std/Date.hx, etc.)
@:coreApi
class Array<T> {
    public function map<S>(f: T -> S): Array<S> {
        // __elixir__() inside stdlib method
        return untyped __elixir__("Enum.map({0}, {1})", this, f);
    }
}
```

### How It Works
1. **Method Call Detection**: When compiling `array.map(fn)`, detect it's an Array method
2. **Body Inspection**: Use `ClassField.expr()` to get the method's TypedExpr body
3. **AST Traversal**: Recursively search for `__elixir__()` calls in the body
4. **Manual Expansion**: Extract the Elixir code and parameter substitution
5. **Direct Generation**: Generate inline Elixir instead of method call

### Implementation
Located in `ElixirASTBuilder.hx`:
- `tryExpandElixirInjection()` - Traverses method body AST
- `tryExpandElixirCall()` - Detects and expands `__elixir__()` calls
- Parameter substitution with `{0}`, `{1}`, etc.

### Expected Result
```elixir
# User writes: array.map(fn x -> x * 2 end)
# Should generate:
result = Enum.map(array, fn x -> x * 2 end)

# NOT:
result = Array.map(array, fn x -> x * 2 end)  # ❌ No Array module in Elixir
```

## Why Two Different Systems?

### Architectural Reasons

1. **Reflaxe Can't See Method Bodies**
   - Reflaxe's TargetCodeInjection operates at the expression level
   - It doesn't inspect the implementation of called methods
   - Standard library methods are external to user code

2. **Stdlib Methods Are Extern or @:coreApi**
   - These classes exist during macro expansion
   - Reflaxe can't modify their behavior
   - We need to handle them specially during compilation

3. **Performance and Separation of Concerns**
   - Direct user code: Handled by framework (fast, automatic)
   - Stdlib calls: Handled by compiler (specialized, optimized)

### Example Flow Comparison

#### Direct Code (System 1: Reflaxe)
```
Haxe Source: untyped __elixir__("DateTime.utc_now()")
     ↓ Reflaxe Macro System
TypedExpr: (inline Elixir AST)
     ↓ ElixirCompiler
Generated: DateTime.utc_now()
```

#### Stdlib Call (System 2: Method Body Inspection)
```
Haxe Source: array.map(fn)
     ↓ Haxe Typing
TypedExpr: TCall(FInstance(Array.map), [array, fn])
     ↓ ElixirASTBuilder detects Array method
ClassField.expr(): Access method body
     ↓ Find __elixir__() in body
Extract: "Enum.map({0}, {1})"
     ↓ Substitute parameters
Generated: Enum.map(array, fn)
```

## Current Issue (January 2025)

**Problem**: System 1 (Reflaxe TargetCodeInjection) is NOT working!

**Symptoms**:
```elixir
# Generated code (WRONG):
time = __elixir__.("DateTime.utc_now()")

# Expected (CORRECT):
time = DateTime.utc_now()
```

**Impact**:
- Todo-app has ~12 "undefined variable __elixir__" compilation errors
- Direct `untyped __elixir__()` calls in application code fail
- Regression tests demonstrate the issue

**Root Cause Investigation Needed**:
1. Is `targetCodeInjectionName` properly registered?
2. Is Reflaxe's expansion happening at all?
3. Is our compiler generating literal calls instead of expanded code?

## Solution Strategy

### For System 1 (Reflaxe TargetCodeInjection)
**Need to investigate**:
- Why Reflaxe isn't expanding `__elixir__()` calls
- Check if our compiler is bypassing Reflaxe's injection system
- Verify the GenericCompiler integration

### For System 2 (Method Body Inspection)
**Already working**:
- Method body inspection is implemented
- Parameter substitution works
- Standard library integration functions correctly

## Testing Both Systems

### Test System 1 (Direct Code)
```haxe
class TestDirectInjection {
    static function main() {
        var time = untyped __elixir__("DateTime.utc_now()");
        var result = untyped __elixir__("{0} + {1}", 10, 20);
    }
}
```

Expected output:
```elixir
defmodule TestDirectInjection do
  def main() do
    time = DateTime.utc_now()
    result = 10 + 20
  end
end
```

### Test System 2 (Stdlib Methods)
```haxe
class TestStdlibInjection {
    static function main() {
        var numbers = [1, 2, 3];
        var doubled = numbers.map(x -> x * 2);
    }
}
```

Expected output:
```elixir
defmodule TestStdlibInjection do
  def main() do
    numbers = [1, 2, 3]
    doubled = Enum.map(numbers, fn x -> x * 2 end)
  end
end
```

## Summary

| Aspect | System 1: Reflaxe | System 2: Method Body |
|--------|-------------------|----------------------|
| **When** | Direct user code | Stdlib method calls |
| **Who** | Reflaxe framework | ElixirCompiler |
| **How** | Macro expansion | AST inspection |
| **Status** | ❌ BROKEN (Jan 2025) | ✅ WORKING |
| **Priority** | CRITICAL FIX | Maintenance |

**Next Steps**:
1. Fix Reflaxe TargetCodeInjection (System 1) - CRITICAL
2. Document why both systems are necessary
3. Add regression tests for both systems
4. Validate todo-app works with fixes