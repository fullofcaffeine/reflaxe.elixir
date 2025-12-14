# 📚 The Definitive Guide: Implementing Standard Library for Idiomatic Target Code

> **Purpose**: This is THE authoritative guide for implementing Haxe standard library functions that generate idiomatic Elixir code while maintaining Haxe's interface and type safety.

## Table of Contents
1. [Core Concepts](#core-concepts)
2. [Understanding Compilation Contexts](#understanding-compilation-contexts)
3. [Implementation Approaches](#implementation-approaches)
4. [Practical Examples](#practical-examples)
5. [Decision Framework](#decision-framework)
6. [Common Pitfalls](#common-pitfalls)
7. [Testing Strategy](#testing-strategy)

---

## Core Concepts

### What We're Solving

The fundamental challenge: **How do we provide Haxe's familiar standard library interface while generating idiomatic Elixir code that looks hand-written?**

### Key Terms Clarified

- **Extern Class**: A Haxe class that declares an interface to code that exists elsewhere (in the target platform)
- **Target Code Injection**: Using `__elixir__()` to inject exact Elixir code during compilation
- **Compiler Transformation**: Detecting patterns in the AST and transforming them to idiomatic target code
- **Inline Function**: A function whose body is inserted at the call site instead of being called

---

## Understanding Compilation Contexts

### The Three Phases of Code Existence

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  1. MACRO TIME  │ --> │ 2. REFLAXE TIME  │ --> │ 3. TARGET TIME  │
│                 │     │                  │     │                 │
│ Haxe macros run │     │ Transpiler runs  │     │ Elixir runs     │
│ AST generated   │     │ AST → Elixir     │     │ Your app runs   │
└─────────────────┘     └──────────────────┘     └─────────────────┘
```

### Phase 1: Macro Time (`#if macro`)
- **When**: During Haxe's macro expansion
- **Available**: Haxe stdlib, macro APIs, Context functions
- **NOT Available**: `__elixir__()`, target code, TypedExpr
- **Purpose**: Build macros, code generation, AST manipulation

### Phase 2: Reflaxe Time (`#if reflaxe_runtime`)
- **When**: After type checking, during transpilation
- **Available**: TypedExpr AST, `__elixir__()`, Reflaxe APIs
- **NOT Available**: Not a real runtime! Still compile-time
- **Purpose**: Transform typed Haxe AST to Elixir code

### Phase 3: Target Time (Generated Elixir)
- **When**: When your application actually runs
- **Available**: Full Elixir/BEAM platform
- **NOT Available**: Haxe compiler, AST, macros
- **Purpose**: Your actual application execution

### Critical Understanding: `#if (macro || reflaxe_runtime)`

This pattern appears in all compiler files because:
1. **Reflaxe extends Haxe's macro system** - it runs as a macro
2. **The compiler needs to exist in both contexts** - initialization and execution
3. **It's NOT runtime code** - it's compile-time infrastructure

---

## Implementation Approaches

### Approach 1: Pure Haxe Implementation

**What**: Write standard library in pure Haxe that compiles to any target.

```haxe
// std/Lambda.hx
class Lambda {
    public static function map<A, B>(it: Iterable<A>, f: A -> B): Array<B> {
        return [for (x in it) f(x)];  // Pure Haxe comprehension
    }
}
```

**Compiles to**:
```elixir
# Not idiomatic - generates imperative loop
defmodule Lambda do
  def map(it, f) do
    result = []
    for x <- it do
      result = result ++ [f.(x)]
    end
    result
  end
end
```

**When to use**:
- Cross-platform libraries that must work on all targets
- Simple utilities where idiomaticity doesn't matter
- Proof of concept implementations

**Pros**: ✅ Cross-platform, ✅ Type-safe, ✅ Simple
**Cons**: ❌ Not idiomatic, ❌ May be inefficient

---

### Approach 2: Target Code Injection (`__elixir__()`)

**What**: Use `untyped __elixir__()` to inject exact Elixir code.

```haxe
// std/ArrayTools.hx
class ArrayTools {
    public static function reduce<T, U>(array: Array<T>, func: (U, T) -> U, initial: U): U {
        // Note: {0}, {1}, {2} are replaced with compiled arguments
        return untyped __elixir__("Enum.reduce({0}, {1}, fn item, acc -> {2}.(acc, item) end)", 
                                  array, initial, func);
    }
}
```

**Compiles to**:
```elixir
# Idiomatic Elixir!
Enum.reduce(array, initial, fn item, acc -> func.(acc, item) end)
```

**When to use**:
- Standard library functions that need idiomatic output
- Performance-critical operations
- When you need exact control over generated code

**Pros**: ✅ Idiomatic output, ✅ Full control, ✅ Efficient
**Cons**: ❌ Target-specific, ❌ Requires `untyped`, ❌ No cross-platform

**Important Notes**:
- `__elixir__()` is ONLY available during Reflaxe compilation (Phase 2)
- Must use `untyped` because Haxe doesn't know about `__elixir__()`
- Arguments are compiled and substituted into {0}, {1}, etc. placeholders

---

### Approach 3: Compiler Transformation

**What**: Detect patterns in the compiler and transform them to idiomatic code.

```haxe
// In ElixirASTBuilder.hx
case TCall(e, el):
    if (isLambdaCall(e)) {
        var methodName = getLambdaMethod(e);
        return switch(methodName) {
            case "map": 
                ERemoteCall(makeAST(EVar("Enum")), "map", compileArgs(el));
            case "fold":
                // Reorder parameters: Lambda.fold(it, f, acc) → Enum.reduce(it, acc, f)
                var args = compileArgs(el);
                ERemoteCall(makeAST(EVar("Enum")), "reduce", [args[0], args[2], args[1]]);
            default:
                compileFallback(e, el);
        }
    }
```

**When to use**:
- Heavily-used standard library (Lambda, Array methods)
- Complex transformations (parameter reordering, pattern detection)
- When you want to eliminate runtime overhead completely

**Pros**: ✅ Perfect idiomatic output, ✅ No runtime overhead, ✅ Type-safe
**Cons**: ❌ Complex to implement, ❌ Requires compiler changes, ❌ Maintenance burden

---

### Approach 4: Extern Classes (For Existing Libraries)

**What**: Declare interface to existing Elixir/Erlang modules.

```haxe
// std/elixir/Enum.hx
@:native("Enum")
extern class Enum {
    static function map<T,R>(enumerable: Array<T>, func: T -> R): Array<R>;
    static function reduce<T,R>(enumerable: Array<T>, acc: R, func: (T, R) -> R): R;
}
```

**When to use**:
- Wrapping existing Elixir/Erlang modules (Phoenix, Ecto, OTP)
- When the target library already exists and has the exact API you need
- Framework integration

**Pros**: ✅ Type-safe wrapper, ✅ No implementation needed, ✅ Direct mapping
**Cons**: ❌ Only for existing libraries, ❌ Can't transform API shape

**Critical**: Extern means "this exists elsewhere" - you can't use extern for Lambda because Lambda doesn't exist in Elixir!

---

### Approach 5: Extern Inline (Limited Use)

**What**: Extern functions with inline bodies for simple transformations.

```haxe
extern class MathTools {
    @:extern static inline function clamp(v: Float, min: Float, max: Float): Float {
        return untyped __elixir__("min(max({0}, {1}), {2})", v, min, max);
    }
}
```

**When to use**:
- Simple one-liner transformations
- When you need forced inlining
- Mathematical or utility functions

**Pros**: ✅ Forced inlining, ✅ Can use `__elixir__()`
**Cons**: ❌ Must be simple enough to inline, ❌ Compiler error if can't inline

---

## Practical Examples

### Example 1: Lambda Library Implementation

**Goal**: Transform Lambda calls to Elixir's Enum module.

**Step 1**: Understand the mapping
```
Lambda.map        → Enum.map         (direct)
Lambda.filter     → Enum.filter      (direct)
Lambda.fold       → Enum.reduce      (reorder params)
Lambda.exists     → Enum.any?        (rename)
Lambda.foreach    → Enum.all?        (rename)
Lambda.find       → Enum.find        (direct)
Lambda.mapi       → Enum.with_index + Enum.map (composition)
```

**Step 2**: Choose implementation strategy
- ❌ Pure Haxe: Would generate loops, not Enum calls
- ❌ Extern: Lambda doesn't exist in Elixir
- ✅ Compiler Transformation: Perfect for this use case

**Step 3**: Implement in compiler
```haxe
// ElixirASTBuilder.hx
private static function transformLambdaToEnum(e: TypedExpr, args: Array<TypedExpr>): ElixirASTDef {
    var method = extractLambdaMethod(e);
    var compiledArgs = [for (arg in args) buildFromTypedExpr(arg)];
    
    return switch(method) {
        case "map":
            ERemoteCall(makeAST(EVar("Enum")), "map", compiledArgs);
            
        case "fold":
            // Lambda.fold(it, func, initial) → Enum.reduce(it, initial, func)
            ERemoteCall(makeAST(EVar("Enum")), "reduce", 
                       [compiledArgs[0], compiledArgs[2], compiledArgs[1]]);
            
        case "mapi":
            // Lambda.mapi(it, func) → Enum.with_index |> Enum.map
            var withIndex = makeAST(ERemoteCall(makeAST(EVar("Enum")), "with_index", 
                                                [compiledArgs[0]]));
            var mapFunc = makeAST(EFn([{
                args: [PTuple([PVar("item"), PVar("index")])],
                guard: null,
                body: makeAST(ECall(compiledArgs[1], "", 
                                   [makeAST(EVar("index")), makeAST(EVar("item"))]))
            }]));
            ERemoteCall(makeAST(EVar("Enum")), "map", [withIndex, mapFunc]);
            
        default:
            throw 'Unsupported Lambda method: $method';
    }
}
```

### Example 2: ArrayTools with Native Implementation

**Goal**: Provide array utilities that compile to Elixir's Enum.

```haxe
// std/ArrayTools.hx
class ArrayTools {
    /**
     * Reduces array to single value using accumulator
     * Compiles to: Enum.reduce(array, initial, fn item, acc -> func.(acc, item) end)
     */
    public static inline function reduce<T, U>(array: Array<T>, func: (U, T) -> U, initial: U): U {
        return untyped __elixir__("Enum.reduce({0}, {1}, fn item, acc -> {2}.(acc, item) end)", 
                                  array, initial, func);
    }
    
    /**
     * Executes action for each element (side effects)
     * Compiles to: Enum.each(array, action)
     */
    public static inline function forEach<T>(array: Array<T>, action: T -> Void): Void {
        return untyped __elixir__("Enum.each({0}, {1})", array, action);
    }
    
    /**
     * Takes first n elements
     * Compiles to: Enum.take(array, n)
     */
    public static inline function take<T>(array: Array<T>, n: Int): Array<T> {
        return untyped __elixir__("Enum.take({0}, {1})", array, n);
    }
}
```

### Example 3: Framework Integration with Externs

**Goal**: Type-safe access to Phoenix LiveView.

```haxe
// std/phoenix/Socket.hx
package phoenix;

@:native("Phoenix.LiveView.Socket")
extern class Socket {
    // Direct mapping to Phoenix.LiveView.Socket functions
    @:native("assign")
    static function assign(socket: Socket, key: String, value: Dynamic): Socket;
    
    @:native("assign")  
    static function assignMap(socket: Socket, assigns: Dynamic): Socket;
    
    @:native("push_event")
    static function pushEvent(socket: Socket, event: String, payload: Dynamic): Socket;
}
```

---

## Decision Framework

### Choosing the Right Approach

```
Start Here
    ↓
Does the library exist in Elixir/Erlang?
    ├─ YES → Use Extern Class (@:native)
    └─ NO ↓
       Is it heavily used (like Lambda)?
           ├─ YES → Compiler Transformation
           └─ NO ↓
              Need exact idiomatic output?
                  ├─ YES → Target Code Injection (__elixir__)
                  └─ NO → Pure Haxe Implementation
```

### Quick Reference Table

| Scenario | Recommended Approach | Example |
|----------|---------------------|---------|
| Wrapping Phoenix/Ecto | Extern Class | `@:native("Phoenix.Router")` |
| Lambda/Array operations | Compiler Transformation | Transform in AST builder |
| String/Math utilities | Target Code Injection | `untyped __elixir__()` |
| Cross-platform utils | Pure Haxe | Simple algorithms |
| One-liner transforms | Extern Inline | Math operations |

---

## Common Pitfalls

### Pitfall 1: Using Extern for Non-Existent Libraries

```haxe
// ❌ WRONG: Lambda doesn't exist in Elixir
@:native("Lambda")
extern class Lambda {
    static function map(...);  // This will fail at runtime!
}

// ✅ RIGHT: Transform to Enum in compiler
// Or use __elixir__() to generate Enum calls
```

### Pitfall 2: Expecting `__elixir__()` at Macro Time

```haxe
// ❌ WRONG: This won't work
#if macro
class MyMacro {
    static function generate() {
        return macro untyped __elixir__("...");  // NOT AVAILABLE!
    }
}
#end

// ✅ RIGHT: __elixir__() only works during Reflaxe compilation
class MyClass {
    function myMethod() {
        return untyped __elixir__("...");  // Available here
    }
}
```

### Pitfall 3: Forgetting Parameter Order Differences

```haxe
// ❌ WRONG: Direct parameter passing
Lambda.fold(array, func, initial)  // Haxe order
→ Enum.reduce(array, func, initial)  // Wrong Elixir order!

// ✅ RIGHT: Reorder parameters
Lambda.fold(array, func, initial)  // Haxe order
→ Enum.reduce(array, initial, func)  // Correct Elixir order
```

### Pitfall 4: Not Using `untyped` with `__elixir__()`

```haxe
// ❌ WRONG: Haxe doesn't know about __elixir__
return __elixir__("Enum.map({0}, {1})", array, func);  // Compiler error!

// ✅ RIGHT: Must use untyped
return untyped __elixir__("Enum.map({0}, {1})", array, func);
```

---

## Testing Strategy

### 1. Snapshot Testing
Create test cases that compile Haxe to Elixir and verify output:

```haxe
// test/tests/TestLambda.hx
class TestLambda {
    static function main() {
        var arr = [1, 2, 3];
        
        // Should compile to: Enum.map([1, 2, 3], fn x -> x * 2 end)
        var doubled = Lambda.map(arr, x -> x * 2);
        
        // Should compile to: Enum.reduce([1, 2, 3], 0, fn x, acc -> acc + x end)
        var sum = Lambda.fold(arr, (x, acc) -> acc + x, 0);
    }
}
```

### 2. Integration Testing
Test with real Phoenix/Ecto applications:

```bash
cd examples/todo-app
npx haxe build-server.hxml
mix compile --force
mix test
```

### 3. Idiomatic Output Verification
Manually review generated Elixir for idiomaticity:

```elixir
# Good: Idiomatic Elixir
Enum.map(items, & &1 * 2)
Enum.reduce(items, 0, &+/2)

# Bad: Non-idiomatic
result = []
for item <- items do
  result = result ++ [item * 2]
end
```

---

## Summary

The key to implementing standard library for idiomatic target code is understanding:

1. **Compilation Contexts**: When code runs (macro vs reflaxe vs target)
2. **Available Tools**: What's available in each context
3. **Right Tool for the Job**: Choose based on your specific needs
4. **Idiomatic Output**: Always prioritize target language conventions

Remember:
- **Extern** = "This exists in the target" (Phoenix, Ecto)
- **`__elixir__()`** = "Generate this exact code" (ArrayTools)
- **Compiler Transform** = "Detect and transform patterns" (Lambda)
- **Pure Haxe** = "Cross-platform compatibility" (simple utils)

This guide is your single source of truth for implementing standard library that maintains Haxe's interface while generating beautiful, idiomatic Elixir code.