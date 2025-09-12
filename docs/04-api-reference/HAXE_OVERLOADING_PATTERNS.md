# Haxe Overloading Patterns in Reflaxe.Elixir

## Overview

Haxe provides two distinct approaches for function overloading, each with different use cases and trade-offs. This document explains both patterns and when to use each.

## 1. The `overload` Keyword (Haxe 4.2+) - Modern Approach

### What It Is
The `overload` keyword allows defining multiple function signatures with separate implementations.

### Syntax
```haxe
// Each overload has its own implementation body
overload extern inline public function whereRaw(sql: String): TypedQuery<T> {
    return untyped __elixir__('Ecto.Query.where({0}, fragment({1}))', this, sql);
}

overload extern inline public function whereRaw<A>(sql: String, p1: A): TypedQuery<T> {
    return untyped __elixir__('Ecto.Query.where({0}, fragment({1}, ^{2}))', this, sql, p1);
}

overload extern inline public function whereRaw<A, B>(sql: String, p1: A, p2: B): TypedQuery<T> {
    return untyped __elixir__('Ecto.Query.where({0}, fragment({1}, ^{2}, ^{3}))', this, sql, p1, p2);
}
```

### Pros
- ✅ **Clean syntax**: Each overload is a complete function
- ✅ **Separate implementations**: Each signature can have different logic
- ✅ **Better IDE support**: Modern IDEs understand this pattern better
- ✅ **Works with `extern inline`**: Perfect for abstract types using `__elixir__()`
- ✅ **No base function needed**: All overloads are equal

### Cons
- ❌ **Requires Haxe 4.2+**: Not available in older versions
- ❌ **Limited compiler support**: Still evolving, may have edge cases
- ❌ **Not well documented**: Many developers don't know about it

### Best For
- Abstract types with `__elixir__()` injection
- Functions with completely different implementations per signature
- Modern codebases using Haxe 4.2+

## 2. The `@:overload` Annotation - Classic Approach

### What It Is
The traditional metadata-based approach using annotations above a single base function.

### Syntax
```haxe
// Annotations define additional signatures
@:overload(function(sql: String): TypedQuery<T> {})
@:overload(function<A>(sql: String, p1: A): TypedQuery<T> {})
@:overload(function<A, B>(sql: String, p1: A, p2: B): TypedQuery<T> {})
public function whereRaw<A, B, C>(sql: String, p1: A, p2: B, p3: C): TypedQuery<T> {
    // Single implementation handles all cases
    // Must detect which overload was called and handle accordingly
    return untyped __elixir__('...complex logic...');
}
```

### Pros
- ✅ **Works in all Haxe versions**: Maximum compatibility
- ✅ **Battle-tested**: Used extensively in standard library
- ✅ **Well-documented**: Lots of examples and documentation
- ✅ **Good for externs**: Especially JavaScript externs

### Cons
- ❌ **Less intuitive syntax**: Annotations feel like metadata, not code
- ❌ **Single implementation**: Must handle all cases in one function body
- ❌ **Complex runtime detection**: Need to check which overload was called
- ❌ **Base function exposed**: The widest signature is callable

### Best For
- Extern definitions for JavaScript libraries
- Legacy codebases or those requiring Haxe < 4.2
- Functions where all overloads share the same implementation

## 3. Comparison Table

| Feature | `overload` keyword | `@:overload` annotation |
|---------|-------------------|------------------------|
| **Haxe Version** | 4.2+ | All versions |
| **Syntax Clarity** | Very clear | Less intuitive |
| **Implementation** | Separate per overload | Single shared |
| **IDE Support** | Better | Good |
| **Use with `extern inline`** | Perfect | Complicated |
| **Documentation** | Limited | Extensive |
| **Maturity** | New, evolving | Stable, proven |

## 4. Decision Guide

### Use `overload` keyword when:
- Using Haxe 4.2 or newer
- Working with abstract types and `__elixir__()`
- Each overload needs different implementation
- Clean, modern syntax is preferred

### Use `@:overload` annotation when:
- Supporting older Haxe versions
- Creating JavaScript externs
- All overloads share the same logic
- Following established patterns

## 5. Real-World Example: TypedQuery.whereRaw

```haxe
// Using overload keyword (RECOMMENDED for Reflaxe.Elixir)
abstract TypedQuery<T>(EctoQueryStruct) {
    // Clean, separate implementations
    overload extern inline public function whereRaw(sql: String): TypedQuery<T> {
        var newQuery = untyped __elixir__(
            'Ecto.Query.where({0}, fragment({1}))',
            this, sql
        );
        return new TypedQuery<T>(newQuery);
    }
    
    overload extern inline public function whereRaw<A>(sql: String, p1: A): TypedQuery<T> {
        var newQuery = untyped __elixir__(
            'Ecto.Query.where({0}, fragment({1}, ^{2}))',
            this, sql, p1
        );
        return new TypedQuery<T>(newQuery);
    }
}

// Usage is identical for both patterns:
query.whereRaw("active = true");
query.whereRaw("age > ?", 18);
```

## 6. References

- [Haxe 4.2 Overload Feature](https://community.haxe.org/t/sneaky-feature-showcase-overloads-in-haxe-4-2/2971)
- [Pull Request #9793](https://github.com/HaxeFoundation/haxe/pull/9793) - Implementation details
- [Haxe Manual - Function Overloading](https://haxe.org/manual/types-function-overloading.html)

## Recommendation for Reflaxe.Elixir

**Use the `overload` keyword** for new code in Reflaxe.Elixir because:
1. It works perfectly with `extern inline` and `__elixir__()`
2. Each parameter count can have its own Elixir code generation
3. Cleaner, more maintainable code
4. Better represents the actual API surface