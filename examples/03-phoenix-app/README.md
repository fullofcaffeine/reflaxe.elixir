# Phoenix Application Integration (Haxe → Elixir)

This example is a minimal Phoenix application whose server-side modules are authored in Haxe and compiled to Elixir with Reflaxe.Elixir.

**Prerequisites**: [02-mix-project](../02-mix-project/) completed  
**Difficulty**: 🟡 Intermediate

## What You'll Learn

- Phoenix application + endpoint/router generation from Haxe
- Mix compiler integration (`mix compile` runs the Haxe compiler)
- A minimal JSON controller written in Haxe

## Quick Start

```bash
cd examples/03-phoenix-app
mix deps.get
mix compile
mix phx.server
```

Then visit `http://localhost:4000/` to see a JSON response.

## Where the Haxe Code Lives

- `examples/03-phoenix-app/src_haxe/PhoenixHaxeExample.hx` — OTP application supervision tree (`@:application`)
- `examples/03-phoenix-app/src_haxe/PhoenixHaxeExampleRouter.hx` — router DSL (`@:router`)
- `examples/03-phoenix-app/src_haxe/controllers/PageController.hx` — minimal JSON controller (`@:controller`)
- `examples/03-phoenix-app/src_haxe/server/infrastructure/*` — `@:endpoint`, `@:phoenixWebModule`, and error renderers

## Notes

- Generated Elixir output is written to `examples/03-phoenix-app/lib/` and is intentionally not committed.
- For a full LiveView example, see `examples/todo-app/`.
