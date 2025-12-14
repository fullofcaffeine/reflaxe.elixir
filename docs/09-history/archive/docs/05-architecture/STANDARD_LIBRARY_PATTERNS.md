# Standard Library Implementation Patterns for Reflaxe.Elixir

## Executive Summary

This document outlines the best practices and patterns for implementing standard library types in Reflaxe.Elixir, based on lessons learned from implementing core types like Array, Date, and StringTools.

## Core Architecture Principles

### 1. Directory Structure for Core Types

```
std/
├── _std/                 # Core Haxe types (@:coreApi)
│   ├── Array.hx         # Core Array implementation
│   ├── Date.hx          # Core Date implementation
│   └── String.hx        # Core String extensions
├── ArrayTools.hx        # Static extension methods
├── MapTools.hx          # Static extension methods
└── elixir/              # Elixir-specific externs
    └── otp/             # OTP patterns
```

**Key Insight**: Types marked with `@:coreApi` MUST be placed in the `_std/` directory to be recognized by Haxe's type system during compilation.

## Implementation Patterns

### Pattern 1: Core Type with Native Injection (@:coreApi)

**When to use**: For fundamental Haxe types that need efficient native implementation (Array, Date, String)

```haxe
// std/_std/Array.hx
package;

/**
 * Array implementation for Reflaxe.Elixir
 * 
 * Implementation notes:
 * - Uses untyped __elixir__() for native operations
 * - Maintains Haxe API compatibility
 * - Generates idiomatic Elixir code
 */
@:coreApi
class Array<T> {
    // Internal native representation
    private var _list: Dynamic;
    
    public var length(default, null): Int = 0;
    
    public function new() {
        // Direct Elixir injection for initialization
        _list = untyped __elixir__("[]");
        length = 0;
    }
    
    public function push(x: T): Int {
        // Native operation with type safety at Haxe level
        _list = untyped __elixir__("{0} ++ [{1}]", _list, x);
        updateLength();
        return length;
    }
    
    private function updateLength(): Void {
        length = untyped __elixir__("length({0})", _list);
    }
}
```

**Benefits**:
- Maximum performance with native operations
- Type safety at Haxe compilation time
- Idiomatic Elixir code generation
- Full IDE support and autocomplete

**Limitations**:
- `untyped __elixir__()` bypasses Haxe type checking
- Must handle Dynamic internal representation carefully
- Requires understanding of both Haxe and Elixir semantics

### Pattern 2: Static Extension Tools

**When to use**: For functional operations that extend core types without modifying them

```haxe
// std/ArrayTools.hx
package;

/**
 * Static extension methods for Array<T>
 * Usage: using ArrayTools;
 */
class ArrayTools {
    /**
     * Reduces array to single value
     * @param array The array to reduce
     * @param func Accumulator function
     * @param initial Initial value
     * @return Accumulated result
     */
    public static function reduce<T, U>(array: Array<T>, func: (U, T) -> U, initial: U): U {
        return untyped __elixir__(
            "Enum.reduce({0}, {1}, fn item, acc -> {2}.(acc, item) end)",
            array, initial, func
        );
    }
    
    public static function find<T>(array: Array<T>, predicate: T -> Bool): Null<T> {
        return untyped __elixir__(
            "Enum.find({0}, fn item -> {1}.(item) end)",
            array, predicate
        );
    }
}
```

**Benefits**:
- Extends types without modifying core implementation
- Can be selectively imported with `using`
- Maintains functional programming patterns
- Easy to test and maintain

### Pattern 3: Extern Classes for Native Libraries

**When to use**: For wrapping existing Elixir/Erlang modules with type-safe interfaces

```haxe
// std/elixir/IO.hx
package elixir;

/**
 * Type-safe wrapper for Elixir's IO module
 */
@:native("IO")
extern class IO {
    /**
     * Writes to standard output
     */
    static function puts(item: Dynamic): Dynamic;
    
    /**
     * Reads a line from input
     */
    static function gets(prompt: String): String;
    
    /**
     * Inspects any term
     */
    static function inspect(item: Dynamic, ?opts: Dynamic): Dynamic;
}
```

**Benefits**:
- Direct mapping to native modules
- No runtime overhead
- Type safety for external APIs
- IntelliSense support

### Pattern 4: Abstract Types for Compile-Time Safety

**When to use**: For creating type-safe wrappers around primitive types

```haxe
// std/elixir/Atom.hx
package elixir;

/**
 * Type-safe atom representation
 */
abstract Atom(String) from String to String {
    public inline function new(s: String) {
        this = ':$s';
    }
    
    @:from
    public static inline function fromString(s: String): Atom {
        return new Atom(s);
    }
    
    @:to
    public inline function toString(): String {
        return this;
    }
}
```

## Best Practices

### 1. Using `untyped __elixir__()`

**✅ DO**:
- Use for performance-critical native operations
- Keep injected code simple and readable
- Document what the injection does
- Validate inputs before injection

**❌ DON'T**:
- Use for complex logic that could be in Haxe
- Inject untrusted user input directly
- Forget to handle null/undefined cases
- Mix business logic with native operations

### 2. Type Safety Guidelines

**Maximize Type Information**:
```haxe
// ✅ GOOD: Typed parameters and return
public function map<S>(f: T -> S): Array<S> {
    var result = new Array<S>();
    result._list = untyped __elixir__(
        "Enum.map({0}, fn item -> {1}.(item) end)",
        _list, f
    );
    return result;
}

// ❌ BAD: Using Dynamic everywhere
public function map(f: Dynamic): Dynamic {
    return untyped __elixir__("Enum.map({0}, {1})", _list, f);
}
```

### 3. Handling Mutability vs Immutability

**Challenge**: Haxe Arrays are mutable, Elixir lists are immutable

**Solution**: Update internal reference on "mutations"
```haxe
public function push(x: T): Int {
    // Create new list (immutable)
    _list = untyped __elixir__("{0} ++ [{1}]", _list, x);
    // Update cached length
    updateLength();
    return length;
}
```

### 4. Performance Considerations

**Use Native Operations When Available**:
```haxe
// ✅ GOOD: Single native operation
public function resize(len: Int): Void {
    if (len > length) {
        var toAdd = len - length;
        _list = untyped __elixir__(
            "{0} ++ List.duplicate(nil, {1})",
            _list, toAdd
        );
    }
}

// ❌ BAD: Loop with multiple operations
public function resize(len: Int): Void {
    while (length < len) {
        push(null);  // Multiple list concatenations!
    }
}
```

## Testing Strategy

### 1. Snapshot Testing
- Test compilation output matches expected Elixir code
- Verify idiomatic code generation
- Check for proper variable scoping

### 2. Runtime Testing
- Validate behavior matches Haxe specification
- Test edge cases (empty arrays, null values)
- Verify cross-platform compatibility

### 3. Integration Testing
- Test with real Phoenix/Ecto applications
- Verify framework integration works
- Check performance characteristics

## Common Pitfalls and Solutions

### Pitfall 1: Forgetting `_std/` Directory for Core Types

**Problem**: `@:coreApi` types in `std/` aren't recognized
```
Unknown identifier: __elixir__
```

**Solution**: Move to `std/_std/` directory

### Pitfall 2: Type Checking `untyped` Expressions

**Problem**: Can't type check injected code
```haxe
// This won't compile
var result: String = untyped __elixir__("IO.gets(\">\")");
```

**Solution**: Use cast or intermediate variable
```haxe
var result = cast untyped __elixir__("IO.gets(\">\")");
```

### Pitfall 3: Incorrect Placeholder Syntax

**Problem**: Wrong placeholder format in injection
```haxe
// ❌ WRONG
untyped __elixir__("List.delete($list, $item)");

// ✅ CORRECT  
untyped __elixir__("List.delete({0}, {1})", list, item);
```

## Migration Path from Pure Elixir

For teams migrating from Elixir to Haxe:

1. **Start with Externs**: Wrap existing Elixir modules
2. **Add Type Safety**: Create typed interfaces
3. **Gradual Migration**: Move logic to Haxe incrementally
4. **Maintain Compatibility**: Keep same module names

## Future Improvements

### Potential Enhancements

1. **Macro-based Code Generation**:
   - Generate boilerplate automatically
   - Compile-time validation of injections
   - Type-safe SQL/Ecto queries

2. **Better IDE Integration**:
   - Syntax highlighting for injected code
   - Jump-to-definition for extern types
   - Inline documentation

3. **Performance Optimizations**:
   - Compile-time constant folding
   - Dead code elimination
   - Inlining of simple operations

## Conclusion

The standard library implementation patterns provide a balance between:
- **Type Safety**: Full Haxe type checking where possible
- **Performance**: Native operations for efficiency
- **Idiomatic Code**: Generated Elixir looks hand-written
- **Developer Experience**: IDE support and documentation

By following these patterns, we can create a robust standard library that leverages the best of both Haxe and Elixir while maintaining cross-platform compatibility.