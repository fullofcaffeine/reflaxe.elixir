# 09 - Phoenix Router DSL (`@:routes` + `@:route`)

This example focuses on router authoring in Haxe for Phoenix.

## What this example demonstrates

- `@:routes([...])` as the primary router surface.
- Typed controller/action references (`controller: UserController`, `action: UserController.index`).
- Legacy/manual `@:route(...)` support on controller actions for migration.

## Router styles in this project

- Recommended for new routers: `@:routes([...typed router nodes...])` with `import reflaxe.elixir.macros.RouterDsl.*;`.
- Compatibility mode: flat `@:routes([{name, method, path, ...}])` route objects.
- Legacy/manual mode: `@:route(...)` on individual controller actions.

This example's `AppRouter.hx` currently uses the flat object `@:routes` shape.
See `docs/04-api-reference/ROUTER_DSL.md` for the typed tree form.

## Compile and run

```bash
cd examples/09-phoenix-router
mix deps.get
mix compile
mix phx.server
```

## Haxe -> generated Elixir (flat object `@:routes`)

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

## Typed tree variant (no `RouterDsl.` prefix) for new routers

Use this when you want source nesting to match Phoenix router nesting (`pipeline`, `scope`, `live_session`) and to enable stronger compile-time validations.

```haxe
import reflaxe.elixir.macros.RouterDsl.*;

@:routes([
  pipeline("browser", [
    plug("accepts", {initArgs: ["html"]}),
    plug("fetch_session")
  ]),
  scope("/", [
    pipeThrough(["browser"]),
    get("/users", UserController, UserController.index)
  ])
])
```

## Why keep `@:route` in controllers?

Controller-local `@:route` is still useful for incremental migration or intentionally manual routing glue.
For new router definitions, prefer `@:routes` on the router module.

## Related docs

- `docs/04-api-reference/ROUTER_DSL.md`
- `docs/04-api-reference/ANNOTATIONS.md`
- `docs/02-user-guide/INTEROP_WITH_EXISTING_ELIXIR.md`
