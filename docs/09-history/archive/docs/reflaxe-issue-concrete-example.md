# Add this section after "The Impact" section:

## Concrete Example: Array Standard Library Implementation

Here's a real-world example from implementing the Array standard library for Reflaxe.Elixir:

### What We Want (But Can't Have)

```haxe
// Ideal Array.hx with @:runtime inline + __elixir__()
@:coreApi
class Array<T> {
    @:runtime public inline function map<S>(f: T -> S): Array<S> {
        return untyped __elixir__('Enum.map({0}, {1})', this, f);
    }
    
    @:runtime public inline function filter(f: T -> Bool): Array<T> {
        return untyped __elixir__('Enum.filter({0}, {1})', this, f);
    }
    
    @:runtime public inline function contains(x: T): Bool {
        return untyped __elixir__('Enum.member?({0}, {1})', this, x);
    }
    
    @:runtime public inline function join(sep: String): String {
        return untyped __elixir__('Enum.join({0}, {1})', this, sep);
    }
}
```

This would generate **zero-overhead, direct Elixir calls**:
```elixir
# Haxe: myArray.map(x -> x * 2)
# Would generate: Enum.map(my_array, fn x -> x * 2 end)

# Haxe: items.filter(x -> x > 0)
# Would generate: Enum.filter(items, fn x -> x > 0 end)
```

### What We Have to Do Instead

```haxe
// Current Array.hx - regular methods with __elixir__()
@:coreApi
class Array<T> {
    public function map<S>(f: T -> S): Array<S> {
        return untyped __elixir__('Enum.map({0}, {1})', this, f);
    }
    
    public function filter(f: T -> Bool): Array<T> {
        return untyped __elixir__('Enum.filter({0}, {1})', this, f);
    }
    
    public function contains(x: T): Bool {
        return untyped __elixir__('Enum.member?({0}, {1})', this, x);
    }
    
    public function join(sep: String): String {
        return untyped __elixir__('Enum.join({0}, {1})', this, sep);
    }
}
```

This generates **wrapper functions with overhead**:
```elixir
defmodule Array do
  def map(array, f) do
    Enum.map(array, f)  # Just a wrapper!
  end
  
  def filter(array, f) do
    Enum.filter(array, f)  # Another wrapper!
  end
  
  def contains(array, x) do
    Enum.member?(array, x)  # More wrapping!
  end
  
  def join(array, sep) do
    Enum.join(array, sep)  # Yet another wrapper!
  end
end

# Haxe: myArray.map(x -> x * 2)
# Generates: Array.map(my_array, fn x -> x * 2 end)  # Extra function call!

# Haxe: items.filter(x -> x > 0)  
# Generates: Array.filter(items, fn x -> x > 0 end)  # Extra function call!
```

### Performance Impact in Real Code

Consider a typical functional programming chain:
```haxe
// Haxe code
var result = data
    .filter(x -> x.isValid)
    .map(x -> x.value * 2)
    .filter(x -> x > threshold)
    .map(x -> x.toString());
```

**With @:runtime inline (if it worked):**
```elixir
# Direct Elixir calls - zero overhead
result = data
  |> Enum.filter(fn x -> x.is_valid end)
  |> Enum.map(fn x -> x.value * 2 end)
  |> Enum.filter(fn x -> x > threshold end)
  |> Enum.map(fn x -> to_string(x) end)
```

**Current situation (wrapper functions):**
```elixir
# Every operation goes through a wrapper
result = data
  |> Array.filter(fn x -> x.is_valid end)    # Calls Enum.filter internally
  |> Array.map(fn x -> x.value * 2 end)      # Calls Enum.map internally
  |> Array.filter(fn x -> x > threshold end)  # Calls Enum.filter internally
  |> Array.map(fn x -> to_string(x) end)     # Calls Enum.map internally

# That's 4 extra function calls in the chain!
```

### Why This Matters

1. **API Consistency**: Native Haxe targets (C++, C#) can provide zero-overhead abstractions, custom targets cannot
2. **Performance**: While each wrapper adds only microseconds, it accumulates in hot paths and functional programming chains
3. **Code Quality**: Generated code looks less idiomatic - Elixir developers expect direct `Enum` calls, not wrapper modules
4. **Standard Library Design**: We have to choose between functionality (`__elixir__()` for complex operations) and performance (`@:runtime inline` for simple operations), but can't have both

### Current Workaround Analysis

We investigated several alternatives:

1. **Pure externs**: Don't work with `@:coreApi` classes
2. **Metadata injection** (`@:nativeFunctionCode`): Would require significant compiler changes
3. **Accepting the overhead**: Current pragmatic solution, but not ideal

The complete investigation is documented in our [RUNTIME_INLINE_PATTERN.md](./03-compiler-development/RUNTIME_INLINE_PATTERN.md).
