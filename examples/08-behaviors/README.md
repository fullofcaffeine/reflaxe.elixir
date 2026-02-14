# 08 - Behavior-Style Contracts (Haxe -> Elixir)

This example shows how `@:behaviour` + `@:use` can model callback contracts and strategy implementations.

## Why this example exists

A skeptical Elixir question is: "Why not define `@callback` and `@behaviour` directly in Elixir modules?"
This example shows where the Haxe layer helps and where plain Elixir may still be preferable.

## Compile

```bash
cd examples/08-behaviors
haxe build.hxml
```

## Key files

- `examples/08-behaviors/src_haxe/behaviors/DataProcessor.hx`
- `examples/08-behaviors/src_haxe/implementations/BatchProcessor.hx`
- `examples/08-behaviors/src_haxe/implementations/StreamProcessor.hx`
- `examples/08-behaviors/lib/behaviors/data_processor.ex`

## Plain Elixir baseline

In plain Elixir, you usually keep callback docs/specs, expected state maps, and implementation modules aligned by convention and review.

## Haxe abstraction input

```haxe
@:behaviour
class DataProcessor {
  @:callback
  public function process_item(item:DataItem, state:ProcessorState):ProcessItemResponse {
    throw "Callback must be implemented by behavior user";
  }

  @:optional_callback
  public function get_stats():ProcessorStats {
    throw "Optional callback can be implemented by behavior user";
  }
}

@:use(DataProcessor)
class BatchProcessor {
  public function process_item(item:DataItem, state:ProcessorState):ProcessItemResponse {
    if (!validate_data(item)) {
      // error path
    }
    // batch processing path
  }
}
```

## Generated Elixir shape

```elixir
defmodule DataProcessor do
  def process_item(_, _, _) do
    raise Reflaxe.Elixir.HaxeThrow, [value: "Callback must be implemented by behavior user"]
  end
end

defmodule BatchProcessor do
  def process_item(struct, item, state) do
    # implementation body
    apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :validate_data, [struct, item])
  end
end
```

## Edge over plain Elixir

- Callback signatures and payload/state shapes are typed in one place (`typedef`s + function signatures).
- Changing contract fields propagates through compile-time checks across implementations.
- Strategy modules (`BatchProcessor`, `StreamProcessor`) reuse one typed contract surface and can focus on logic.

## Tradeoff

Generated behavior contracts are emitted as contract-style modules (with raising stubs), not literal Elixir `@callback` attributes. For teams that want canonical `@behaviour` macro surfaces in source, plain Elixir can be clearer for that layer.
