# 09 - Phoenix Router DSL

Phoenix Router DSL integration with automatic route generation from Haxe annotations.

## Features Demonstrated

### @:controller Annotation
- Automatic Phoenix controller module generation
- Controller action compilation with proper signatures
- Integration with Phoenix.Controller behavior

### @:route Annotations
- RESTful route definitions with HTTP methods
- Route parameter extraction and validation
- Path pattern matching (`:id`, `:product_id`)
- Named routes with `as` option

### @:resources Annotation
- Automatic RESTful resource routes
- Standard REST actions (index, show, create, update, delete)
- Resource nesting support

### @:router Configuration
- Phoenix router module generation
- Pipeline definitions (browser, api)
- Route scoping and organization
- Controller inclusion system

## Generated Elixir Code

The Haxe classes compile to Phoenix-compatible Elixir modules:

```elixir
defmodule UserController do
  use Phoenix.Controller
  
  def index(conn) do
    conn
    |> put_status(200)
    |> json(%{message: "Action index executed"})
  end
  
  def show(conn, id) do
    conn
    |> put_status(200) 
    |> json(%{message: "Action show executed"})
  end
  
  # ... more actions
end
```

## Usage

Compile the example:

```bash
npx haxe build.hxml
```

Generated files appear in `lib/` directory ready for Phoenix integration.

## Integration with Phoenix

The generated controllers integrate seamlessly with Phoenix applications:

1. Controllers follow Phoenix.Controller conventions
2. Route definitions work with Phoenix.Router macros
3. Pipeline integration supports authorization and plugs
4. Parameter validation ensures type safety

This enables gradual migration from Elixir to Haxe while maintaining full Phoenix compatibility.