# 07 - Protocol-Style Contracts (Haxe -> Elixir)

This example shows how `@:protocol` and `@:impl` can define a shared typed contract and multiple implementations.

## Why this example exists

A skeptical Elixir question is: "Why not just write the polymorphic modules directly in Elixir?"
This example demonstrates when the Haxe layer helps and what tradeoff comes with it.

## Compile

```bash
cd examples/07-protocols
haxe build.hxml
```

## Runtime tests

```bash
cd examples/07-protocols
mix deps.get
mix test
```

The tests call each generated implementation module and the base protocol
contract. That keeps this example honest: it must compile, and the generated
Elixir must behave as the Haxe contract describes.

## Key files

- `examples/07-protocols/src_haxe/protocols/Drawable.hx`
- `examples/07-protocols/src_haxe/implementations/StringDrawable.hx`
- `examples/07-protocols/src_haxe/implementations/NumberDrawable.hx`
- `examples/07-protocols/lib/protocols/drawable.ex`
- `examples/07-protocols/test/protocols_test.exs`

## Direct baseline (without this abstraction layer)

Without this abstraction layer, you would maintain one contract module and each implementation module manually, keeping arities and value-shapes in sync yourself.

## Haxe abstraction input

```haxe
@:protocol
class Drawable {
  public function draw(value:Term):String {
    throw "Protocol method should be implemented";
  }
}

@:impl
class StringDrawable {
  public function draw(value:String):String {
    return "Drawing string: " + value;
  }
}
```

## Generated Elixir shape

```elixir
defmodule Drawable do
  def draw(_, _) do
    raise Reflaxe.Elixir.HaxeThrow, [value: "Protocol method should be implemented"]
  end
end

defmodule StringDrawable do
  def draw(_, value), do: "Drawing string: #{value}"
end
```

## Edge over the direct baseline

- The contract and implementations share typed signatures in one authoring layer.
- Refactors that change argument/return shapes fail earlier in compile-time checks instead of drifting across modules.
- Adding another implementation reuses the same typed contract surface.

## Tradeoff

This compiler currently emits contract/implementation modules, not native `defprotocol/defimpl` macros. If protocol-macro semantics are required in a specific boundary, keep that boundary explicit and minimal while the rest remains Haxe-authored.
