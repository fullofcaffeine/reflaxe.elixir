# Layered API Architecture for Reflaxe.Elixir

## Executive Summary

This document defines the foundational layered API architecture for Reflaxe.Elixir's standard library, establishing a clear separation between Elixir-native APIs and Haxe cross-platform abstractions. This architecture enables developers to choose between idiomatic Elixir patterns or portable Haxe patterns while ensuring both generate optimal Elixir code.

## Problem Statement

### Current Challenges
- Mixed responsibilities between Elixir externs and Haxe stdlib
- Unclear when to use native Elixir APIs vs Haxe abstractions  
- Inconsistent code generation patterns
- Mutable Haxe patterns don't map cleanly to immutable Elixir
- Iterator-based patterns (ArrayIterator) don't match Elixir's functional approach

## Solution: Three-Layer Architecture

### Architecture Overview

```
┌─────────────────────────────────────┐
│   Haxe Standard Library (Layer 3)   │  ← Cross-platform abstractions
│  Lambda, StringBuf, Map, Array, etc. │     (uses Layer 2)
└─────────────────────────────────────┘
                  ↓ uses
┌─────────────────────────────────────┐
│    Elixir Externs (Layer 2)         │  ← 1:1 Elixir API mappings
│  Enum, String, List, Map, etc.       │     (faithful to Elixir)
└─────────────────────────────────────┘
                  ↓ compiles to
┌─────────────────────────────────────┐
│    Elixir Runtime (Layer 1)         │  ← Native Elixir modules
│  Actual BEAM modules and functions   │
└─────────────────────────────────────┘
```

## Layer Specifications

### Layer 1: Elixir Runtime (Native BEAM)

**What it is**: The actual Elixir/Erlang runtime - the BEAM VM and its standard library modules.

**Examples**:
- `Enum` module with `map/2`, `filter/2`, `reduce/3`
- `List` module with `flatten/1`, `zip/2`
- `String` module with `split/2`, `trim/1`
- Phoenix modules like `Phoenix.LiveView`
- OTP behaviors like `GenServer`, `Supervisor`

### Layer 2: Elixir Externs (Type-Safe Bindings)

**Purpose**: Provide type-safe 1:1 mappings to Elixir's runtime modules

**Location**: `std/elixir/` directory

**Characteristics**:
- Exact representation of Elixir modules and functions
- Haxe naming conventions (camelCase) with @:native annotations
- Full type safety with proper generics
- No business logic, pure API definitions
- Zero runtime overhead (compiles away completely)

**Example Implementation**:
```haxe
// std/elixir/Enum.hx
package elixir;

/**
 * Type-safe extern for Elixir's Enum module
 * Provides 1:1 mapping to all Enum functions
 */
@:native("Enum")
extern class Enum {
    @:native("map")
    static function map<T,R>(enumerable: Array<T>, fun: T -> R): Array<R>;
    
    @:native("filter") 
    static function filter<T>(enumerable: Array<T>, fun: T -> Bool): Array<T>;
    
    @:native("reduce")
    static function reduce<T,A>(enumerable: Array<T>, acc: A, fun: (T, A) -> A): A;
    
    @:native("each")
    static function each<T>(enumerable: Array<T>, fun: T -> Void): Void;
    
    @:native("all?")
    static function all<T>(enumerable: Array<T>, fun: T -> Bool): Bool;
    
    @:native("any?")
    static function any<T>(enumerable: Array<T>, fun: T -> Bool): Bool;
    
    @:native("find")
    static function find<T>(enumerable: Array<T>, fun: T -> Bool): Null<T>;
    
    @:native("find_index")
    static function findIndex<T>(enumerable: Array<T>, fun: T -> Bool): Null<Int>;
}
```

### Layer 3: Haxe Standard Library (Cross-Platform Abstraction)

**Purpose**: Provide cross-platform APIs that compile to idiomatic target code

**Location**: `std/` root directory

**Characteristics**:
- Built on top of Elixir externs (Layer 2)
- Maintains Haxe's cross-platform contract
- Handles mutable→immutable transformations
- May use `__elixir__()` for critical optimizations
- Provides migration helpers for Haxe patterns

**Example Implementation**:
```haxe
// std/Array.hx
@:coreApi
class Array<T> {
    public var length(default, null): Int;
    
    /**
     * Creates a new array by applying function f to all elements.
     * Uses Elixir's Enum.map for optimal code generation.
     */
    public function map<R>(f: T -> R): Array<R> {
        return elixir.Enum.map(this, f);
    }
    
    /**
     * Returns a new array containing only elements for which f returns true.
     * Uses Elixir's Enum.filter for idiomatic output.
     */
    public function filter(f: T -> Bool): Array<T> {
        return elixir.Enum.filter(this, f);
    }
    
    /**
     * Adds an element to the array.
     * WARNING: In Elixir, this creates a new list (immutable).
     * Consider using elixir.List functions for explicit immutable semantics.
     */
    public function push(item: T): Int {
        #if elixir_warn_mutability
        @:compilerWarning("Array.push creates new list in Elixir (immutable)")
        #end
        untyped __elixir__('{0} ++ [{1}]', this, item);
        return length;
    }
    
    /**
     * Returns an iterator for the array.
     * NOTE: Only exists for Haxe macro compatibility.
     * Elixir uses Enum functions, not iterator objects.
     */
    public inline function iterator(): Iterator<T> {
        #if macro
        // Only exists at compile-time for Haxe's macro system
        return new haxe.iterators.ArrayIterator(this);
        #else
        // In Elixir, for-in loops are transformed to Enum operations
        return null;
        #end
    }
}
```

## Code Generation Principles

### Principle 1: Both Layers Generate Idiomatic Elixir

Whether developers use Layer 2 (Elixir externs) or Layer 3 (Haxe stdlib), the generated Elixir code should be idiomatic and nearly identical.

**Using Layer 2 (Elixir Externs)**:
```haxe
// Developer writes:
import elixir.Enum;
var doubled = Enum.map(numbers, x -> x * 2);
var evens = Enum.filter(doubled, x -> x % 2 == 0);

// Generates:
doubled = Enum.map(numbers, fn x -> x * 2 end)
evens = Enum.filter(doubled, fn x -> rem(x, 2) == 0 end)
```

**Using Layer 3 (Haxe Standard Library)**:
```haxe
// Developer writes:
var doubled = numbers.map(x -> x * 2);
var evens = doubled.filter(x -> x % 2 == 0);

// ALSO generates (identical):
doubled = Enum.map(numbers, fn x -> x * 2 end)
evens = Enum.filter(doubled, fn x -> rem(x, 2) == 0 end)
```

### Principle 2: Compiler Warnings for Semantic Differences

When Haxe patterns don't map cleanly to Elixir's immutable semantics:

```haxe
// Developer writes:
var list = [1, 2, 3];
list.push(4);  // Mutable operation expectation

// Compiler warns:
// Warning: Array.push() creates a new list in Elixir (immutable).
// The original list is not modified. Consider using:
//   list = list.concat([4]);  // Explicit rebinding
// Or use Elixir's List module:
//   list = elixir.List.append(list, 4);

// Generates:
list = [1, 2, 3]
list = list ++ [4]  // New binding, not mutation
```

### Principle 3: No Iterator Objects in Generated Code

Elixir doesn't use iterator objects. The compiler transforms iteration patterns:

```haxe
// Developer writes:
for (item in array) {
    trace(item);
}

// Generates (no iterator objects):
Enum.each(array, fn item ->
    IO.inspect(item)
end)
```

## Implementation Strategy

### Phase 1: Complete Elixir Extern Coverage

**Goal**: Comprehensive Layer 2 externs for Elixir stdlib

- [x] Core modules: Atom, Kernel, System, IO
- [x] Collections: Tuple
- [ ] Complete Enum extern with all functions
- [ ] Complete List extern
- [ ] Complete Map extern  
- [ ] Complete String extern
- [ ] Date/Time modules
- [ ] Process, Task, Agent
- [ ] GenServer, Supervisor, Application

### Phase 2: Rebuild Haxe Standard Library

**Goal**: Layer 3 built entirely on Layer 2 externs

- [ ] Array using Enum/List externs
- [ ] Map using elixir.Map extern
- [ ] StringBuf using IO lists
- [ ] Date using DateTime externs
- [ ] Remove non-idiomatic patterns (iterators)
- [ ] Add immutability warnings

### Phase 3: Framework Integration

**Goal**: Type-safe externs for Phoenix/Ecto

- [ ] Phoenix.LiveView extern
- [ ] Phoenix.Router extern
- [ ] Ecto.Schema extern
- [ ] Ecto.Changeset extern
- [ ] Ecto.Query extern

### Phase 4: Compiler Enhancements

**Goal**: Smart transformations and warnings

- [ ] Mutable operation warnings
- [ ] Suggest idiomatic alternatives
- [ ] Optimize common patterns
- [ ] Dead code elimination for iterator paths

## Benefits

### For Elixir Developers
- **Familiar APIs**: Use Elixir modules/functions you know
- **Type Safety**: Compile-time checking for Elixir code
- **No Magic**: Generated code looks hand-written
- **Easy Adoption**: Gradual migration from pure Elixir

### For Haxe Developers
- **Cross-Platform**: Write once, compile to multiple targets
- **Familiar Patterns**: Use Haxe stdlib you know
- **Clear Warnings**: Understand semantic differences
- **Gradual Learning**: Learn Elixir patterns over time

### For the Ecosystem
- **Clean Architecture**: Clear separation of concerns
- **Extensible**: Easy to add new frameworks
- **Maintainable**: Each layer has single responsibility
- **Performant**: Zero abstraction overhead

## Anti-Patterns to Avoid

### ❌ Mixing Layers
```haxe
// BAD: Adding helpers to extern classes
@:native("Enum")
extern class Enum {
    static function map<T,R>(enum: Array<T>, fun: T -> R): Array<R>;
    
    // DON'T: Add non-extern helpers
    static inline function mapIndexed<T,R>(enum: Array<T>, fun: (T, Int) -> R): Array<R> {
        // This belongs in a separate helper class
    }
}
```

### ❌ Bypassing Extern Layer
```haxe
// BAD: Using __elixir__() instead of externs
class Lambda {
    public static function map<T,R>(it: Iterable<T>, f: T -> R): Array<R> {
        // DON'T: Bypass the extern layer
        return untyped __elixir__('Enum.map({0}, {1})', it, f);
        
        // DO: Use the extern
        return elixir.Enum.map(cast it, f);
    }
}
```

### ❌ Creating Non-Idiomatic Patterns
```haxe
// BAD: Iterator objects that don't exist in Elixir
class ElixirIterator<T> {
    var list: Array<T>;
    var index: Int = 0;
    
    public function hasNext(): Bool {
        return index < list.length;
    }
    
    public function next(): T {
        return list[index++];
    }
}
// This pattern doesn't exist in Elixir!
```

## Testing Strategy

### Layer 2 (Extern) Testing
- Verify correct @:native annotations
- Test type inference works correctly
- Ensure no runtime code generated
- Validate against Elixir documentation

### Layer 3 (Stdlib) Testing  
- Test cross-platform behavior consistency
- Verify idiomatic Elixir generation
- Test immutability warnings trigger
- Benchmark against hand-written Elixir

### Integration Testing
- Test todo-app with both API styles
- Verify generated code quality
- Test with real Phoenix apps
- Performance comparison tests

## Migration Guide

### For Existing Code

**Step 1**: Identify current API usage
```haxe
// Current (mixed approach):
array.push(item);  // Haxe pattern
Enum.map(array, fn);  // Direct Elixir

// After migration (choose one):
// Option A: Haxe stdlib (Layer 3)
array.push(item);
array.map(fn);

// Option B: Elixir externs (Layer 2)
import elixir.*;
List.append(array, item);
Enum.map(array, fn);
```

**Step 2**: Choose your API layer based on needs:
- Cross-platform code → Use Layer 3 (Haxe stdlib)
- Elixir-specific code → Consider Layer 2 (Externs)
- Learning Elixir → Start with Layer 2

**Step 3**: Update imports
```haxe
// For Elixir externs:
import elixir.Enum;
import elixir.List;
import elixir.String as ElixirString;

// For Haxe stdlib (default):
// No special imports needed
```

## Future Enhancements

### Compiler Intelligence
- Auto-suggest Layer 2 alternatives when using Layer 3
- Performance hints for common patterns
- Dead code elimination for unused layers
- Inline Layer 3 calls to Layer 2 in release builds

### Documentation Generation
- Auto-generate API comparison tables
- Show Layer 2 vs Layer 3 for each operation
- Include performance characteristics
- Generate migration guides

### IDE Support
- Quick-fix to switch between layers
- Show generated Elixir on hover
- Immutability warnings in editor
- Auto-complete for both layers

## Conclusion

This layered architecture provides the best of both worlds: familiar APIs for Elixir developers and cross-platform abstractions for Haxe developers, all while generating idiomatic, performant Elixir code. The clear separation ensures maintainability, extensibility, and optimal developer experience regardless of background.

The key insight is that both approaches should generate nearly identical Elixir code - the choice is about developer preference and use case, not about output quality.