# 14 - Abstraction Lab (Haxe + Elixir)

This lab collects three abstraction patterns and explains each one against a direct baseline (without the extra abstraction layer).

## Why this lab exists

The goal is not to replace Elixir style. The goal is to show where a typed Haxe authoring layer can remove drift or repeated boundary code while still compiling to regular Elixir modules.

## Run and test

```bash
cd examples/14-abstraction-lab
mix deps.get
mix test
```

The Mix compiler builds Haxe to `lib/`, and the test alias compiles
`test_haxe/quality/AbstractionLabRuntimeTest.hx` to ExUnit. The runtime tests
exercise both retry strategies, both renderers, and the process boundary; this
example is no longer compile-only.

## 1) Protocol-style contract + implementations

### Direct baseline (without this abstraction layer)

Define one contract module and manually keep every implementation module aligned with that contract as signatures evolve.

### Haxe abstraction input

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

### Generated Elixir shape

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

### Edge over the direct baseline

- One typed contract surface for all implementations.
- Signature drift is caught earlier when implementations no longer match the typed contract.

### Tradeoff

This emits contract/implementation modules, not native `defprotocol/defimpl` macros.

## 2) Behavior-style retry policies

### Direct baseline (without this abstraction layer)

Define callback conventions and keep each retry policy implementation aligned by convention and review.

### Haxe abstraction input

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

### Generated Elixir shape

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

### Edge over the direct baseline

- Typed callback/state shapes make policy refactors safer.
- Swapping strategies (`ImmediateRetryPolicy` vs `ExponentialRetryPolicy`) keeps one typed contract.

### Tradeoff

If you want literal `@callback` / `@behaviour` macro surfaces in source, keep those boundaries explicit and minimal while the rest stays Haxe-authored.

## 3) Typed boundary over low-level process primitives

### Direct baseline (without this abstraction layer)

Repeat `is_pid` checks, `send`, `self`, and type checks at multiple call sites.

### Haxe abstraction input

```haxe
class ProcessBoundary {
  public static function sendIfPid(destination:Term, message:Term):Bool {
    if (!Kernel.isPid(destination)) return false;
    Kernel.send(destination, message);
    return true;
  }
}
```

### Generated Elixir shape

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

### Edge over the direct baseline

- One reusable, typed boundary for low-level operations.
- Reduces duplicated guard/send boilerplate and keeps boundary behavior consistent.

### Tradeoff

Wrappers can hide details if overused; for one-off low-level calls, direct Haxe->Elixir code is often clearer.

## Key files

- `examples/14-abstraction-lab/src_haxe/protocols/CommandRenderable.hx`
- `examples/14-abstraction-lab/src_haxe/behaviors/RetryPolicy.hx`
- `examples/14-abstraction-lab/src_haxe/abstractions/ProcessBoundary.hx`
- `examples/14-abstraction-lab/src_haxe/implementations/*.hx`

## Generated output quality contract

The retry policy and process boundary are reviewed in the
[handwritten-output corpus](../../docs/03-compiler-development/GENERATED_OUTPUT_QUALITY_CORPUS.md).
It compares the canonical generated modules with small native Elixir versions
and measures the support footprint. This keeps the tradeoff explicit: the
typed Haxe class/protocol model currently retains receiver dispatch metadata,
while direct Kernel boundary calls compile without application-visible
Reflaxe helpers.
