# 09 - Phoenix Router DSL (`final routes` + `@:route`)

This example focuses on router authoring in Haxe for Phoenix.

## What this example demonstrates

- Module-level `final routes = [...]` with static-imported typed router nodes (`pipeline(...)`, `scope(...)`, `get(...)`).
- Typed controller/action references.
- Path-param contract validation via `paramsContract`.
- Legacy/manual `@:route(...)` support on controller actions for migration.

## Router styles in this project

- Recommended for new routers: module-level `final routes = [...typed router nodes...]` with `import reflaxe.elixir.macros.RouterDsl.*;`.
- Compatibility mode: flat `@:routes([{name, method, path, ...}])` route objects (still supported, not used here).
- Legacy/manual mode: `@:route(...)` on individual controller actions.

This example's `AppRouter.hx` uses the typed tree form.
See `docs/04-api-reference/ROUTER_DSL.md` for the full reference.

## Compile and run

```bash
cd examples/09-phoenix-router
mix deps.get
mix compile
mix phx.server
```

## Haxe -> generated Elixir (typed tree routes)

Haxe (`src_haxe/AppRouter.hx`):

```haxe
import controllers.UserController;
import reflaxe.elixir.macros.RouterDsl.*;

@:native("PhoenixRouterWeb.Router")
@:router
final routes = [
  pipeline(browser, [
    plug(accepts, {initArgs: ["html"]}),
    plug(fetch_session)
  ]),
  scope("/", [
    pipeThrough([browser]),
    get("/users", UserController, UserController.index),
    get("/users/:id", UserController, UserController.show, {
      paramsContract: UserIdPathParams
    })
  ])
];
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

## Typed tree variant (no `RouterDsl.` prefix)

Use this when you want source nesting to match Phoenix router nesting and to enable stronger compile-time validations.

```haxe
import reflaxe.elixir.macros.RouterDsl.*;

final routes = [
  pipeline(browser, [
    plug(accepts, {initArgs: ["html"]}),
    plug(fetch_session)
  ]),
  scope("/", [
    pipeThrough([browser]),
    get("/users", UserController, UserController.index)
  ])
];
```

## Why keep `@:route` in controllers?

Controller-local `@:route` is still useful for incremental migration or intentionally manual routing glue.
For new router definitions, prefer module-level `final routes = [...]`.

## Related docs

- `docs/04-api-reference/ROUTER_DSL.md`
- `docs/04-api-reference/ANNOTATIONS.md`
- `docs/02-user-guide/INTEROP_WITH_EXISTING_ELIXIR.md`
