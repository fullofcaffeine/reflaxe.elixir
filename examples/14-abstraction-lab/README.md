# 14 - Abstraction Lab (Haxe + Elixir)

This example shows how to author reusable abstractions in Haxe that compile to familiar Elixir runtime constructs.

## What this example demonstrates

- `@:protocol` + `@:impl` for polymorphic rendering contracts.
- `@:behaviour` + `@:use` for callback contracts and interchangeable implementations.
- A typed wrapper over low-level `Kernel` process primitives (`self`, `send`, `is_pid`, `node`).
- Haxe-first authoring with direct mapping to Elixir contract/implementation modules and process primitives.

## Why this example exists

Most examples focus on Phoenix/Ecto app features. This lab isolates the abstraction pattern itself: define authoring surfaces in Haxe, keep runtime output native to Elixir.

## Key files

- `examples/14-abstraction-lab/src_haxe/protocols/CommandRenderable.hx`
- `examples/14-abstraction-lab/src_haxe/behaviors/RetryPolicy.hx`
- `examples/14-abstraction-lab/src_haxe/abstractions/ProcessBoundary.hx`
- `examples/14-abstraction-lab/src_haxe/implementations/*.hx`

## Compile

```bash
cd examples/14-abstraction-lab
haxe build.hxml
```

Generated Elixir files are emitted to `examples/14-abstraction-lab/lib/`.

## Haxe -> generated Elixir shapes

### Protocol contract + implementations

Haxe:

```haxe
@:protocol
class CommandRenderable {
  public function renderCommand(value:Term):String {
    throw "Protocol method should be implemented";
  }
}

@:impl
class StringCommandRenderable {
  public function renderCommand(value:String):String {
    return "run:" + value;
  }
}
```

Generated Elixir shape:

```elixir
defmodule AbstractionLab.CommandRenderable do
  def render_command(_, _) do
    raise Reflaxe.Elixir.HaxeThrow, [value: "Protocol method should be implemented"]
  end
end

defmodule AbstractionLab.StringCommandRenderable do
  def render_command(_, value), do: "run:#{value}"
end
```

### Behavior contract + implementations

Haxe:

```haxe
@:behaviour
class RetryPolicy {
  @:callback
  public function nextDelayMs(attempt:Int):Int {
    throw "Callback must be implemented by behavior user";
  }
}

@:use(RetryPolicy)
class ExponentialRetryPolicy {
  public function nextDelayMs(attempt:Int):Int {
    return Std.int(Math.pow(2, attempt) * 100);
  }
}
```

Generated Elixir shape:

```elixir
defmodule AbstractionLab.RetryPolicy do
  def next_delay_ms(_, _) do
    raise Reflaxe.Elixir.HaxeThrow, [value: "Callback must be implemented by behavior user"]
  end
end

defmodule AbstractionLab.ExponentialRetryPolicy do
  def next_delay_ms(_, attempt), do: trunc(:math.pow(2, attempt) * 100)
end
```

### Typed boundary over low-level process primitives

Haxe:

```haxe
class ProcessBoundary {
  public static function sendIfPid(destination:Term, message:Term):Bool {
    if (!Kernel.isPid(destination)) return false;
    Kernel.send(destination, message);
    return true;
  }
}
```

Generated Elixir shape:

```elixir
def send_if_pid(destination, message) do
  if not Kernel.is_pid(destination) do
    false
  else
    Kernel.send(destination, message)
    true
  end
end
```
