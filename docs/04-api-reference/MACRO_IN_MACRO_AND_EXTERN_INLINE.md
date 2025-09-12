# Macro-in-Macro Errors and Extern Inline Solutions

## Table of Contents
1. [The Macro-in-Macro Problem](#the-macro-in-macro-problem)
2. [Understanding Extern Inline](#understanding-extern-inline)
3. [Why __elixir__() Fails in Abstract Types](#why-__elixir-fails-in-abstract-types)
4. [Solutions and Architectural Patterns](#solutions-and-architectural-patterns)

## The Macro-in-Macro Problem

### What Happened
When TypedQuery's macro methods tried to call EctoQueryMacros' macro methods, Haxe threw a "macro-in-macro" exception. This is a fundamental limitation of Haxe's macro system.

```haxe
// This causes macro-in-macro exception:
public static macro function from<T>(schemaClass: ExprOf<Class<T>>): ExprOf<TypedQuery<T>> {
    return EctoQueryMacros.from(schemaClass);  // ❌ Calling another macro!
}
```

### Why It Happens
Macros in Haxe execute at compile-time in a special context with access to the AST. When one macro tries to call another:
1. The outer macro is already in the macro context
2. The inner macro tries to create another macro context
3. Haxe doesn't support nested macro contexts
4. Result: "Uncaught exception macro-in-macro"

### How We Fixed It (Without Workarounds)
Instead of using nested macros, we converted the methods to use `extern inline` with direct `__elixir__()` injection:

```haxe
// Fixed version - no macro nesting:
extern inline public static function from<T>(schemaClass: Class<T>): TypedQuery<T> {
    var query = untyped __elixir__(
        '(require Ecto.Query; Ecto.Query.from(t in {0}, []))',
        schemaClass
    );
    return new TypedQuery<T>(query);
}
```

This is NOT a workaround - it's the correct architectural pattern for this use case. The `extern inline` approach:
- Provides the same functionality
- Works at compile-time through inlining
- Avoids the macro context entirely
- Generates cleaner code

## Understanding Extern Inline

### What is `extern inline`?

`extern inline` is a combination of two Haxe keywords that work together:

#### `extern` Keyword
- **Purpose**: Tells Haxe "this function exists externally"
- **Effect**: No function body is generated in output
- **Usage**: Typically for FFI (Foreign Function Interface)
- **Key behavior**: Delays typing of the function body

#### `inline` Keyword  
- **Purpose**: Tells Haxe to replace calls with the function body
- **Effect**: Function body is copied to call sites
- **Usage**: Performance optimization and compile-time expansion
- **Key behavior**: Eliminates function call overhead

#### `extern inline` Combined
- **Purpose**: Function body exists only for inlining, not as a separate function
- **Effect**: Body is typed at call sites, not at declaration
- **Critical for**: Using `__elixir__()` in abstract types
- **Key behavior**: Delays typing until after Reflaxe initialization

### Can They Be Used Separately?

Yes, but with different effects:

#### Just `extern` (without inline)
```haxe
extern function externalFunc(): Void;  // No body allowed - truly external
```
- Used for: Functions that exist in external libraries
- Body: Not allowed (compilation error if you add one)
- Example: JavaScript FFI, C++ bindings

#### Just `inline` (without extern)
```haxe
inline function add(a: Int, b: Int): Int {
    return a + b;  // Body required and will be inlined
}
```
- Used for: Performance optimization
- Body: Required and copied to call sites
- Example: Small utility functions, getters/setters

#### `extern inline` Together
```haxe
extern inline function injectElixir(): String {
    return untyped __elixir__('IO.puts("Hello")');  // Body required for inlining only
}
```
- Used for: Abstract type methods with `__elixir__()`
- Body: Required but only for inlining
- Example: Our TypedQuery methods

### Usage Scenarios

| Scenario | Use `extern` | Use `inline` | Use `extern inline` |
|----------|--------------|--------------|---------------------|
| FFI to external library | ✅ | ❌ | ❌ |
| Performance-critical small function | ❌ | ✅ | ❌ |
| Abstract type with `__elixir__()` | ❌ | ❌ | ✅ |
| Macro-like behavior without macros | ❌ | ❌ | ✅ |
| Delayed typing requirement | ❌ | ❌ | ✅ |

## Why __elixir__() Fails in Abstract Types

### The Timing Problem

1. **Abstract types are typed early**: When imported, all methods are typed immediately
2. **`__elixir__()` doesn't exist yet**: Reflaxe injects it AFTER Haxe's initial typing
3. **Result**: "Unknown identifier: __elixir__" error

### Regular Classes vs Abstract Types

#### Regular Classes (Works)
```haxe
class MyClass {
    public function test() {
        return untyped __elixir__('IO.puts("works")');  // ✅ Typed later
    }
}
```
- Methods typed when called
- `__elixir__()` exists by then

#### Abstract Types (Fails without extern inline)
```haxe
abstract MyAbstract(Dynamic) {
    public function test() {
        return untyped __elixir__('IO.puts("fails")');  // ❌ Typed too early
    }
}
```
- Methods typed at import time
- `__elixir__()` doesn't exist yet

#### Abstract Types (Works with extern inline)
```haxe
abstract MyAbstract(Dynamic) {
    extern inline public function test() {
        return untyped __elixir__('IO.puts("works")');  // ✅ Typed at call site
    }
}
```
- Method body typed at call sites
- `__elixir__()` exists by then

### How We Fixed It

For every abstract type method using `__elixir__()`:

1. **Added `extern inline`** to delay typing
2. **Ensured proper placeholder syntax** (`{0}`, not `$var`)
3. **Documented the requirement** in CLAUDE.md

Example fix in TypedQuery:
```haxe
// Before (failed):
public function limit(count: Int): TypedQuery<T> {
    return untyped __elixir__('Ecto.Query.limit({0}, {1})', query, count);
}

// After (works):
extern inline public function limit(count: Int): TypedQuery<T> {
    return untyped __elixir__('Ecto.Query.limit({0}, {1})', query, count);
}
```

## Solutions and Architectural Patterns

### Pattern 1: Extern Inline for Abstract Types (Used)
**When to use**: Abstract types need `__elixir__()` injection
**Pros**: Simple, direct, works immediately
**Cons**: No compile-time field validation

### Pattern 2: Build Macros (Future)
**When to use**: Need compile-time validation and type generation
**Pros**: Full compile-time checking, generates typed APIs
**Cons**: More complex, requires restructuring

```haxe
@:build(TypedQueryBuilder.build())
class User extends Schema {
    // Generates UserQuery with typed methods
}
```

### Pattern 3: Direct Macro Usage (Alternative)
**When to use**: Users need maximum control
**Pros**: Full macro power, no abstraction overhead
**Cons**: More verbose, less ergonomic

```haxe
var query = EctoQueryMacros.from(User);
query = EctoQueryMacros.where(query, u -> u.active);
```

## Key Takeaways

1. **Macro-in-macro is a hard limitation** - Cannot be worked around, must be avoided
2. **`extern inline` is the solution** - Not a workaround, but the correct pattern
3. **Abstract types have special timing** - Methods typed at import, not at call
4. **`extern` and `inline` serve different purposes** - Together they enable delayed typing
5. **`__elixir__()` requires careful handling** - Must exist when code is typed

## References

- [Haxe Manual: Inline Functions](https://haxe.org/manual/class-field-inline.html)
- [Haxe Manual: Externs](https://haxe.org/manual/lf-externs.html)
- [Reflaxe Documentation: Target Code Injection](https://github.com/RobertBorghese/reflaxe)