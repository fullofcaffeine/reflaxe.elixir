# 07-protocols - Elixir Protocol System Example

**Difficulty**: Intermediate  
**Features**: @:protocol, @:impl annotations, polymorphic dispatch  
**Use Case**: Type-safe polymorphic behavior with compile-time validation

## 📖 Overview

This example demonstrates Elixir protocol support in Reflaxe.Elixir, enabling polymorphic dispatch similar to interfaces but following Elixir conventions.

## 🎯 What You'll Learn

- How to define protocols with `@:protocol` annotation
- Implementing protocols for different types with `@:impl`
- Polymorphic dispatch at runtime
- Type-safe protocol contracts

## 📁 Files

- `src_haxe/protocols/Drawable.hx` - Protocol definition
- `src_haxe/implementations/StringDrawable.hx` - String implementation
- `src_haxe/implementations/NumberDrawable.hx` - Number implementations
- `build.hxml` - Build configuration

## 🚀 Running the Example

```bash
cd examples/07-protocols
haxe build.hxml
```

Generated files appear in `lib/` directory:
- `lib/protocols/drawable.ex` - Protocol module
- `lib/implementations/string_drawable.ex` - String implementation
- `lib/implementations/number_drawable.ex` - Number implementations

## 📋 Generated Elixir Code

### Protocol Definition
```elixir
defprotocol Drawable do
  @spec draw(any()) :: String
  def draw(value)
  
  @spec area(any()) :: Float
  def area(value)
end
```

### Protocol Implementations
```elixir
defimpl Drawable, for: String do
  def draw(value), do: "Drawing string: #{value}"
  def area(value), do: String.length(value)
end

defimpl Drawable, for: Integer do
  def draw(value), do: "Drawing integer: #{value}"
  def area(value), do: value * value
end
```

## 🧪 Testing with Elixir

```elixir
# In IEx console:
iex(1)> Drawable.draw("hello")
"Drawing string: hello"

iex(2)> Drawable.draw(42)
"Drawing integer: 42"

iex(3)> Drawable.area("test")
4

iex(4)> Drawable.area(5)
25
```

## 🔑 Key Features

1. **Type Safety**: Protocol contracts enforced at compile time
2. **Polymorphism**: Same interface, different implementations
3. **Extensibility**: Add implementations for new types easily
4. **Performance**: Native Elixir dispatch, no runtime overhead
5. **Integration**: Works seamlessly with existing Elixir protocols
