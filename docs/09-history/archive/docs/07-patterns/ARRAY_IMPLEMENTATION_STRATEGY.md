# Array Implementation Strategy for Reflaxe.Elixir

## Executive Summary

This document captures the architectural decision made for implementing Array in Reflaxe.Elixir, comparing approaches taken by other Haxe targets and Reflaxe compilers. We chose the **Direct Native Injection** pattern using `__elixir__()` for efficient, idiomatic Elixir code generation.

## The Problem

When compiling Haxe array operations like `map`, `filter`, and `reduce`, we need to generate idiomatic Elixir code that:
1. Uses native Elixir `Enum` and `List` modules for performance
2. Avoids complex while-loop patterns that don't match Elixir's functional style
3. Maintains Haxe's array semantics and API compatibility

## Our Solution: Direct Native Injection Pattern

### Architecture
```
┌─────────────────────────┐
│   Haxe Source Code      │
│   arr.map(x -> x * 2)   │
└───────────┬─────────────┘
            │
            ▼ Compilation
┌─────────────────────────┐
│     /std/Array.hx       │  ← Standard library implementation
│  Uses __elixir__()      │    with native injection
└───────────┬─────────────┘
            │
            ▼ Generates
┌─────────────────────────┐
│   Elixir Output         │
│  Enum.map(arr, fn x ->  │  ← Idiomatic Elixir code
│    x * 2                │
│  end)                   │
└─────────────────────────┘
```

### Key Implementation Approach

```haxe
// std/Array.hx
@:coreApi
class Array<T> {
    /**
     * Creates a new array by applying function f to all elements
     */
    public function map<S>(f: T -> S): Array<S> {
        return untyped __elixir__("Enum.map({0}, {1})", this, f);
    }
    
    /**
     * Returns a new array containing only elements for which f returns true
     */
    public function filter(f: T -> Bool): Array<T> {
        return untyped __elixir__("Enum.filter({0}, {1})", this, f);
    }
}
```

### Why This Approach Works

1. **Idiomatic Output**: Generates clean `Enum.map`, `Enum.filter` calls instead of complex loops
2. **Performance**: Leverages Elixir's optimized Enum module directly
3. **Simplicity**: No complex AST pattern detection needed
4. **Maintainability**: Clear one-to-one mapping between Haxe methods and Elixir functions

## Comparison with Other Implementations

### 1. Python Target: Delegation Pattern
```haxe
// std/python/_std/Array.hx
@:native("list")
@:coreApi
extern class Array<T> {
    @:runtime inline function map<S>(f:T->S):Array<S> {
        return ArrayImpl.map(this, f);  // Delegates to implementation
    }
}
```

**Analysis**: Python uses an `ArrayImpl` helper class for implementation details
- ✅ Clean separation of interface and implementation
- ❌ Extra indirection layer we don't need

### 2. GDScript Target: Inline Runtime Implementation
```haxe
// reflaxe.GDScript/std/gdscript/_std/Array.hx
@:runtime inline function map<S>(f: (T) -> S):Array<S> {
    final temp = f;
    final result = [];
    for(v in this) result.push(temp(v));
    return result;
}
```

**Analysis**: GDScript implements the logic inline with runtime annotation
- ✅ Pure Haxe implementation
- ❌ Generates imperative loops instead of functional patterns

### 3. C++ Target: Native Helper Functions
```haxe
// reflaxe.CPP/std/cxx/_std/Array.hx
class HxArray {
    public static function concat<T>(a: cxx.Ptr<Array<T>>, other: cxx.Ptr<Array<T>>): Array<T> {
        final result = a.copy();
        for(o in other) {
            result.push(o);
        }
        return result;
    }
}
```

**Analysis**: C++ uses static helper functions with pointer types
- ✅ Type-safe with C++ specifics
- ❌ Complex for our functional target

## Key Design Decisions

### 1. Using `__elixir__()` for Standard Library

**Decision**: Use direct native injection for standard library implementations

**Rationale**:
- Standard library is infrastructure, not user code
- Performance and idiomaticity are critical
- Well-defined, stable API surface
- Matches approach used in other Haxe targets (JS uses native functions)

### 2. Avoiding AST-Level Pattern Detection

**Decision**: Don't detect array patterns in the AST transformer

**Rationale**:
- Complex pattern detection is fragile and hard to maintain
- Standard library approach is cleaner and more predictable
- Follows separation of concerns (stdlib vs compiler)
- User can still write custom loops if needed

### 3. Immutability Handling

**Decision**: Array methods return new arrays (matching Elixir's immutability)

**Challenges**:
- Methods like `reverse()` and `sort()` are mutating in Haxe
- Elixir lists are immutable

**Solution**:
- Document the difference clearly
- Consider a future `@:mutable` annotation for special cases
- Most Haxe code doesn't rely on in-place mutation

## Implementation Checklist

### Core Methods (Implemented)
- [x] `new()` - Create empty list
- [x] `push(x)` - Add element (returns new list)
- [x] `pop()` - Get last element
- [x] `map(f)` - Transform elements
- [x] `filter(f)` - Filter elements
- [x] `concat(a)` - Concatenate arrays
- [x] `reverse()` - Reverse order
- [x] `sort(f)` - Sort with comparator
- [x] `slice(pos, end)` - Get subarray
- [x] `join(sep)` - Join to string
- [x] `indexOf(x)` - Find element index
- [x] `contains(x)` - Check membership
- [x] `iterator()` - Create iterator
- [x] `keyValueIterator()` - Create key-value iterator

### Additional Methods (TODO)
- [ ] `resize(len)` - Resize array
- [ ] `lastIndexOf(x)` - Find last occurrence
- [ ] `shift()` - Remove first element
- [ ] `unshift(x)` - Add to beginning

## Lessons Learned

### 1. Start with Standard Library

When we initially tried to detect array patterns at the AST level, it became complex:
- Pattern detection was fragile
- Edge cases multiplied quickly
- Generated code was unpredictable

The standard library approach is cleaner and matches what other targets do.

### 2. Native Functions Are Not a Compromise

Using `__elixir__()` in the standard library is pragmatic:
- Haxe's JS target uses native JavaScript arrays
- Python target uses native Python lists
- We use native Elixir lists and Enum module

This is not a workaround - it's the correct architectural choice.

### 3. Follow Target Language Idioms

Generating idiomatic target code is more important than literal translation:
- Elixir developers expect `Enum.map`, not while loops
- Functional patterns are more performant in Elixir
- Code readability and maintainability improve

## Migration Guide

### For Existing Code Using Arrays

No changes needed! The Array API remains the same:

```haxe
// Your existing Haxe code works unchanged
var numbers = [1, 2, 3, 4, 5];
var doubled = numbers.map(x -> x * 2);
var evens = numbers.filter(x -> x % 2 == 0);
```

### Generated Elixir Output

```elixir
# Clean, idiomatic Elixir
numbers = [1, 2, 3, 4, 5]
doubled = Enum.map(numbers, fn x -> x * 2 end)
evens = Enum.filter(numbers, fn x -> rem(x, 2) == 0 end)
```

## Future Improvements

### Potential Enhancements

1. **Lazy Evaluation**: Support for `Stream` operations
2. **Parallel Operations**: Use `Task.async_stream` for parallel map
3. **Custom Operators**: Support for Elixir-specific operations
4. **Performance Hints**: Annotations for optimization hints

### Compatibility Considerations

1. **Mutation Semantics**: Document differences from mutable targets
2. **Performance Characteristics**: Different from imperative implementations
3. **Memory Usage**: Functional operations may use more memory

## Related Documentation

- [STRINGTOOLS_STRATEGY.md](STRINGTOOLS_STRATEGY.md) - Similar approach for StringTools
- [ELIXIR_INJECTION_GUIDE.md](../06-guides/ELIXIR_INJECTION_GUIDE.md) - Using `__elixir__()`
- [FUNCTIONAL_PATTERNS.md](FUNCTIONAL_PATTERNS.md) - Functional programming patterns

## Conclusion

The Direct Native Injection pattern for Array implementation provides:
- **Idiomatic Elixir code** that Elixir developers expect
- **Simple, maintainable implementation** in the standard library
- **Predictable compilation** without complex AST transformations
- **Performance benefits** from native Elixir modules

This approach aligns with how other Haxe targets handle standard library implementations and provides the best balance of simplicity, performance, and idiomaticity.