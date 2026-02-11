# 09 - Phoenix Router DSL (`@:routes` + `@:route`)

This example shows the current router authoring model in Reflaxe.Elixir:

- `@:routes([...])` on a `@:router` module (recommended)
- `@:route(...)` on controller actions (legacy/manual-compatible metadata)

## What this example demonstrates

- Typed route declarations with `HttpMethod.*`
- Typed controller/action references (`controller: UserController`, `action: UserController.index`)
- Generated Phoenix router macros (`get`, `post`, `put`, `delete`)
- Controller modules compiled from Haxe `@:controller` classes

## Key Haxe files

- `examples/09-phoenix-router/src_haxe/AppRouter.hx`
- `examples/09-phoenix-router/src_haxe/controllers/UserController.hx`
- `examples/09-phoenix-router/src_haxe/controllers/ProductController.hx`

## Compile and run

```bash
cd examples/09-phoenix-router
mix deps.get
mix compile
mix phx.server
```

## Haxe -> generated Elixir (router)

Haxe (`src_haxe/AppRouter.hx`):

```haxe
@:native("PhoenixRouterWeb.Router")
@:router
@:build(reflaxe.elixir.macros.RouterBuildMacro.generateRoutes())
@:routes([
  {name: "usersIndex", method: HttpMethod.GET, path: "/users", controller: UserController, action: UserController.index},
  {name: "usersShow", method: HttpMethod.GET, path: "/users/:id", controller: UserController, action: UserController.show}
])
class AppRouter {}
```

Generated Elixir shape:

```elixir
defmodule PhoenixRouterWeb.Router do
  use Phoenix.Router

  scope "/", PhoenixRouterWeb do
    pipe_through :browser
    get "/users", UserController, :index
    get "/users/:id", UserController, :show
  end
end
```

## Why keep `@:route` in controllers?

Controller-local `@:route` metadata is still supported for legacy/manual patterns and gradual migration.
For new router definitions, prefer `@:routes` on the router module.

## Related docs

- `docs/04-api-reference/ROUTER_DSL.md`
- `docs/04-api-reference/ANNOTATIONS.md`
