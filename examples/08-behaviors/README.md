# Example 08: OTP Behaviors

This example demonstrates how to implement Elixir/OTP behaviors using Haxe with Reflaxe.Elixir.

## Overview

Behaviors in Elixir/OTP define a common interface that multiple modules can implement, ensuring consistent APIs and enabling hot code swapping. This example shows:

- **Behavior Definition**: Using `@:behaviour` to define callback contracts
- **Multiple Implementations**: Different strategies implementing the same behavior  
- **Callback Validation**: Compile-time enforcement of required callbacks
- **Optional Callbacks**: Flexible interface definitions

## Files Structure

```
src_haxe/
├── behaviors/
│   └── DataProcessor.hx          # Behavior definition with callbacks
└── implementations/
    ├── BatchProcessor.hx         # Batch processing implementation
    └── StreamProcessor.hx        # Streaming implementation
```

## Key Features Demonstrated

### 1. Behavior Definition (`@:behaviour`)

```haxe
@:behaviour
class DataProcessor {
    @:callback
    public function process_item(item: Dynamic, state: Dynamic): ProcessResult {
        throw "Callback must be implemented by behavior user";
    }
    
    @:optional_callback  
    public function get_stats(): Map<String, Dynamic> {
        throw "Optional callback can be implemented by behavior user";
    }
}
```

### 2. Behavior Implementation (`@:use`)

```haxe
@:use(DataProcessor)
class BatchProcessor {
    // Must implement all @:callback methods
    public function process_item(item: Dynamic, state: Dynamic): ProcessResult {
        // Implementation specific to batch processing
        return processInBatch(item, state);
    }
    
    // Optional callbacks can be omitted
    // public function get_stats() - not implemented
}
```

### 3. Different Processing Strategies

- **BatchProcessor**: Accumulates data and processes in large batches for efficiency
- **StreamProcessor**: Processes data items individually in real-time

## Generated Elixir Code

The Haxe behavior definitions compile to proper Elixir behavior modules:

```elixir
# From DataProcessor.hx
defmodule DataProcessor do
  @callback init(config :: any()) :: {:ok, any()} | {:error, String.t()}
  @callback process_item(item :: any(), state :: any()) :: {:result, any(), new_state :: any()}
  @callback process_batch(items :: [any()], state :: any()) :: {:results, [any()], new_state :: any()}
  @callback validate_data(data :: any()) :: boolean()
  @callback handle_error(error :: any(), context :: any()) :: String.t()
  
  # Optional callbacks
  @optional_callbacks get_stats: 0, cleanup: 1
  @callback get_stats() :: %{String.t() => any()}
  @callback cleanup(state :: any()) :: :ok
end
```

```elixir  
# From BatchProcessor.hx
defmodule BatchProcessor do
  @behaviour DataProcessor
  
  def init(config) do
    batch_size = Map.get(config, :batch_size, 100)
    {:ok, %{batch_size: batch_size, mode: :batch_processing}}
  end
  
  def process_item(item, state) do
    # Batch processing logic
  end
  
  # ... other callback implementations
end
```

## Compilation

```bash
# Compile the behavior example
haxe build.hxml

# The generated Elixir modules will be available for use in Mix projects
```

## Usage in Elixir

Once compiled, the behaviors can be used in standard Elixir applications:

```elixir
# In your Mix project
defmodule MyApp.DataPipeline do
  @behaviour DataProcessor
  
  def start_link(processor_module) do
    GenServer.start_link(__MODULE__, processor_module)
  end
  
  def init(processor_module) do
    {:ok, state} = processor_module.init(%{batch_size: 50})
    {:ok, %{processor: processor_module, state: state}}
  end
  
  def handle_call({:process, item}, _from, %{processor: mod, state: state}) do
    {result, new_state} = mod.process_item(item, state)
    {:reply, result, %{processor: mod, state: new_state}}
  end
end

# Usage
{:ok, pid} = MyApp.DataPipeline.start_link(BatchProcessor)
GenServer.call(pid, {:process, %{id: 1, data: "example"}})
```

## Key Benefits

1. **Type Safety**: Compile-time validation ensures all required callbacks are implemented
2. **Hot Code Swapping**: Standard Elixir behavior support enables live updates
3. **Polymorphism**: Different implementations can be swapped at runtime
4. **Documentation**: Behaviors serve as contracts documenting expected APIs
5. **OTP Integration**: Works seamlessly with GenServer, Supervisor, and other OTP patterns

## Next Steps

- Explore combining behaviors with GenServer implementations
- See how behaviors enable supervisor restart strategies
- Learn about dynamic behavior loading and hot code replacement
- Integration with Phoenix applications for pluggable components

This example shows how Haxe's powerful type system can enhance Elixir's behavior-driven architecture while maintaining full OTP compatibility.