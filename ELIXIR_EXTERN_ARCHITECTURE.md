# Elixir Extern Architecture: Layered API Design

## Core Philosophy: Native First, Abstractions Second

### The Problem We're Solving
Currently, we're trying to implement Haxe standard library classes directly with `__elixir__()` injections. This approach:
- Mixes concerns (cross-platform abstractions with platform-specific implementations)
- Limits user choice (forced to use Haxe abstractions even when Elixir API would be better)
- Makes maintenance harder (changes to either layer affect the other)
- Reduces idiomaticity (Elixir developers can't use familiar patterns)

### The Solution: Layered Architecture

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

## Implementation Strategy

### Layer 2: Elixir Externs (1:1 API Mapping)

Create faithful externs that match Elixir APIs exactly:

```haxe
// std/elixir/Enum.hx
@:native("Enum")
extern class Enum {
    // 1:1 mapping to Elixir's Enum module
    static function map<T,R>(enumerable: Enumerable<T>, fun: T -> R): Array<R>;
    static function filter<T>(enumerable: Enumerable<T>, fun: T -> Bool): Array<T>;
    static function reduce<T,Acc>(enumerable: Enumerable<T>, acc: Acc, fun: (T, Acc) -> Acc): Acc;
    static function all<T>(enumerable: Enumerable<T>, ?fun: T -> Bool): Bool;
    static function any<T>(enumerable: Enumerable<T>, ?fun: T -> Bool): Bool;
    static function at<T>(enumerable: Enumerable<T>, index: Int, ?default_value: T): T;
    static function chunk_every<T>(enumerable: Enumerable<T>, count: Int): Array<Array<T>>;
    static function count<T>(enumerable: Enumerable<T>): Int;
    static function each<T>(enumerable: Enumerable<T>, fun: T -> Void): Void;
    static function empty<T>(enumerable: Enumerable<T>): Bool;
    static function find<T>(enumerable: Enumerable<T>, fun: T -> Bool): Null<T>;
    static function flat_map<T,R>(enumerable: Enumerable<T>, fun: T -> Enumerable<R>): Array<R>;
    static function group_by<T,K>(enumerable: Enumerable<T>, key_fun: T -> K): Map<K, Array<T>>;
    static function join<T>(enumerable: Enumerable<T>, ?joiner: String = ""): String;
    static function max<T>(enumerable: Enumerable<T>): T;
    static function min<T>(enumerable: Enumerable<T>): T;
    static function random<T>(enumerable: Enumerable<T>): T;
    static function reverse<T>(enumerable: Enumerable<T>): Array<T>;
    static function sort<T>(enumerable: Enumerable<T>): Array<T>;
    static function sum(enumerable: Enumerable<Float>): Float;
    static function take<T>(enumerable: Enumerable<T>, count: Int): Array<T>;
    static function uniq<T>(enumerable: Enumerable<T>): Array<T>;
    static function zip<T,U>(enumerable1: Enumerable<T>, enumerable2: Enumerable<U>): Array<Tuple2<T,U>>;
    
    // Use @:native for snake_case methods
    @:native("reduce_while")
    static function reduceWhile<T,Acc>(enumerable: Enumerable<T>, acc: Acc, fun: (T, Acc) -> ReduceWhileResult<Acc>): Acc;
    
    @:native("flat_map_reduce")
    static function flatMapReduce<T,R,Acc>(enumerable: Enumerable<T>, acc: Acc, fun: (T, Acc) -> Tuple2<Enumerable<R>, Acc>): Tuple2<Array<R>, Acc>;
}

// Supporting types for Elixir patterns
enum ReduceWhileResult<T> {
    Cont(value: T);
    Halt(value: T);
}
```

Or using `__elixir__()` injection where externs don't work well:

```haxe
// std/elixir/ElixirString.hx
class ElixirString {
    // Use injection for more complex patterns
    public static inline function slice(string: String, start: Int, length: Int): String {
        return untyped __elixir__('String.slice({0}, {1}, {2})', string, start, length);
    }
    
    public static inline function trim(string: String): String {
        return untyped __elixir__('String.trim({0})', string);
    }
    
    public static inline function split(string: String, pattern: String): Array<String> {
        return untyped __elixir__('String.split({0}, {1})', string, pattern);
    }
    
    public static inline function replace(string: String, pattern: String, replacement: String): String {
        return untyped __elixir__('String.replace({0}, {1}, {2})', string, pattern, replacement);
    }
    
    public static inline function upcase(string: String): String {
        return untyped __elixir__('String.upcase({0})', string);
    }
    
    public static inline function downcase(string: String): String {
        return untyped __elixir__('String.downcase({0})', string);
    }
}
```

### Layer 3: Haxe Standard Library (Cross-Platform Abstractions)

Build Haxe stdlib on top of the externs:

```haxe
// std/Lambda.hx - Haxe's functional utilities
class Lambda {
    // Haxe's cross-platform API, implemented using Elixir externs
    public static function array<T>(it: Iterable<T>): Array<T> {
        #if elixir
        return elixir.Enum.map(it, function(x) return x);
        #else
        // Other platform implementation
        #end
    }
    
    public static function map<T,R>(it: Iterable<T>, f: T -> R): List<R> {
        #if elixir
        // Use Elixir's Enum for efficient implementation
        var result = elixir.Enum.map(it, f);
        return List.fromArray(result);
        #else
        // Cross-platform implementation
        #end
    }
    
    public static function filter<T>(it: Iterable<T>, f: T -> Bool): List<T> {
        #if elixir
        var result = elixir.Enum.filter(it, f);
        return List.fromArray(result);
        #else
        // Cross-platform implementation
        #end
    }
    
    public static function fold<T,Acc>(it: Iterable<T>, f: T -> Acc -> Acc, first: Acc): Acc {
        #if elixir
        // Note: Elixir's reduce has parameters in different order
        return elixir.Enum.reduce(it, first, function(item, acc) return f(item, acc));
        #else
        // Cross-platform implementation
        #end
    }
    
    public static function exists<T>(it: Iterable<T>, f: T -> Bool): Bool {
        #if elixir
        return elixir.Enum.any(it, f);
        #else
        // Cross-platform implementation
        #end
    }
    
    public static function foreach<T>(it: Iterable<T>, f: T -> Void): Void {
        #if elixir
        elixir.Enum.each(it, f);
        #else
        // Cross-platform implementation
        #end
    }
}
```

## Benefits of This Architecture

### 1. User Choice
Developers can choose their preferred API style:

```haxe
// Option A: Use Elixir API directly (idiomatic for Elixir developers)
import elixir.Enum;

var doubled = Enum.map([1, 2, 3], function(x) return x * 2);
var sum = Enum.reduce(doubled, 0, function(x, acc) return x + acc);

// Option B: Use Haxe stdlib (familiar for Haxe developers)
import Lambda;

var doubled = Lambda.map([1, 2, 3], function(x) return x * 2);
var sum = Lambda.fold(doubled, function(x, acc) return x + acc, 0);
```

### 2. Better Code Generation
When using Elixir externs directly, code generation is more idiomatic:

```elixir
# From Elixir extern usage
doubled = Enum.map([1, 2, 3], fn x -> x * 2 end)
sum = Enum.reduce(doubled, 0, fn x, acc -> x + acc end)

# Instead of wrapped abstractions
doubled = Lambda.map([1, 2, 3], fn x -> x * 2 end)  # Less idiomatic
```

### 3. Maintainability
- Changes to Elixir APIs only affect the extern layer
- Haxe stdlib remains stable across Elixir versions
- Clear separation of concerns

### 4. Learning Curve
- Elixir developers can use familiar APIs while gaining type safety
- Gradual transition from Elixir patterns to Haxe patterns
- Documentation can reference official Elixir docs for extern layer

### 5. Performance
- Direct extern calls have zero overhead
- No abstraction penalty for Elixir-specific code
- Can optimize hot paths with direct Elixir calls

## Implementation Priority

### Phase 1: Core Elixir Externs
Create externs for the most commonly used Elixir modules:
- `Enum` - Collection operations
- `String` - String manipulation  
- `List` - List-specific operations
- `Map` - Map operations
- `Process` - Process operations
- `GenServer` - OTP patterns

### Phase 2: Phoenix Externs
Create faithful Phoenix API mappings:
- `Phoenix.LiveView` - All LiveView functions
- `Phoenix.Controller` - Controller helpers
- `Phoenix.Router` - Router helpers
- `Phoenix.Channel` - Real-time channels

### Phase 3: Ecto Externs
Complete Ecto API coverage:
- `Ecto.Query` - Query DSL
- `Ecto.Changeset` - Validation
- `Ecto.Schema` - Schema definitions

### Phase 4: Haxe Stdlib on Top
Implement Haxe standard library using externs:
- `Lambda` - Uses `Enum` extern
- `StringTools` - Uses `String` extern  
- `Map` abstractions - Uses `Map` extern

## Migration Strategy

For existing code like StringBuf:

### Before (Direct Implementation)
```haxe
class StringBuf {
    public function toString(): String {
        return untyped __elixir__('IO.iodata_to_binary({0})', this.parts);
    }
}
```

### After (Using Externs)
```haxe
// First, create the extern
@:native("IO")
extern class IO {
    static function iodata_to_binary(iodata: Dynamic): String;
}

// Then use it in StringBuf
class StringBuf {
    public function toString(): String {
        return IO.iodata_to_binary(this.parts);
    }
}
```

## Example: Math Implementation

Instead of direct implementation, layer it:

```haxe
// Layer 2: Elixir math extern
@:native(":math")
extern class ElixirMath {
    static function sin(x: Float): Float;
    static function cos(x: Float): Float;
    static function tan(x: Float): Float;
    static function asin(x: Float): Float;
    static function acos(x: Float): Float;
    static function atan(x: Float): Float;
    static function atan2(y: Float, x: Float): Float;
    static function exp(x: Float): Float;
    static function log(x: Float): Float;
    static function log10(x: Float): Float;
    static function pow(x: Float, y: Float): Float;
    static function sqrt(x: Float): Float;
    static function pi(): Float;
}

@:native(":rand")
extern class ElixirRand {
    static function uniform(): Float;
    static function uniform(n: Int): Int;
}

// Layer 3: Haxe Math using externs
class Math {
    public static var PI(default, never): Float = ElixirMath.pi();
    
    public static inline function sin(v: Float): Float {
        return ElixirMath.sin(v);
    }
    
    public static inline function random(): Float {
        return ElixirRand.uniform();
    }
    
    // Add Haxe-specific conveniences
    public static function round(v: Float): Int {
        return Math.floor(v + 0.5);
    }
}
```

## Conclusion

This layered architecture provides:
1. **Maximum flexibility** - Use Elixir or Haxe APIs
2. **Better idiomaticity** - Direct Elixir API usage generates idiomatic code
3. **Cleaner separation** - Externs vs abstractions are clearly separated
4. **Easier maintenance** - Changes isolated to appropriate layer
5. **Learning-friendly** - Can reference official Elixir documentation

The key insight: **Don't hide Elixir, embrace it.** Provide type-safe access to Elixir's excellent APIs while also offering familiar Haxe abstractions for those who want them.