# Phoenix + Haxe Integration Example

This example demonstrates how to create a Phoenix application with Haxe→Elixir compilation using Reflaxe.Elixir.

## Features

- **Phoenix LiveView**: Counter component with real-time updates
- **Mix Integration**: Haxe compiler integrated into Phoenix build pipeline  
- **Live Reload**: Changes to `.hx` files trigger automatic recompilation
- **Production Ready**: Full Phoenix app structure with config, supervision, etc.

## Quick Start

```bash
# From project root, install dependencies
cd examples/03-phoenix-app
mix deps.get

# Compile Haxe source to Elixir
npx haxe build.hxml

# Start Phoenix server
mix phx.server
```

Open [http://localhost:4000](http://localhost:4000) to see the counter.

## Architecture

### Haxe Source (`src_haxe/`)
- `phoenix/Application.hx` - Main application with LiveView component
- Uses `@:liveview` annotation for automatic LiveView generation

### Generated Elixir (`lib/`)
- Phoenix modules generated from Haxe source
- Standard Phoenix application structure

### Build Process
1. **Haxe compilation**: `npx haxe build.hxml` converts `.hx` → `.ex`
2. **Elixir compilation**: `mix compile` processes generated Elixir code  
3. **Phoenix server**: `mix phx.server` runs the application

## LiveView Example

The `CounterLive` class demonstrates:

**Haxe Source:**
```haxe
@:liveview
class CounterLive {
    var count = 0;
    
    function handle_event("increment", _params, socket) {
        count++;
        return {status: "noreply", socket: assign(socket, "count", count)};
    }
}
```

**Generated Elixir:**
```elixir
defmodule CounterLive do
  use Phoenix.LiveView
  
  def handle_event("increment", _params, socket) do
    count = socket.assigns.count + 1
    {:noreply, assign(socket, :count, count)}
  end
end
```

## Development Workflow

1. **Edit Haxe**: Modify files in `src_haxe/`
2. **Compile**: Run `npx haxe build.hxml` (or use Phoenix live reload)
3. **Test**: Browser automatically refreshes with changes

## Next Steps

- Add more LiveView components
- Integrate with Ecto for database operations
- Add OTP GenServers for business logic
- Deploy to production with releases