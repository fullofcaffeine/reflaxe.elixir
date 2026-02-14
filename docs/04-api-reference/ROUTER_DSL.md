# Router DSL (`@:routes` / `@:route`)

## Summary

Use `@:routes` on a `@:router` module for new code.

Inside `@:routes([...])` you can use:

1. **Typed tree nodes** from `RouterDsl.*` static imports (recommended)
2. **Flat route objects** `{name, method, path, ...}` (compatibility mode)

`@:route(...)` on controller functions is still supported for legacy/manual routing.

## Recommended: Typed router nodes (without `RouterDsl.` prefix)

Why this section exists: Phoenix routers are nested (`pipeline`, `scope`, `live_session`). Static-imported router node builders let your Haxe source express that structure directly.

### Haxe input

```haxe
import reflaxe.elixir.macros.HttpMethod;
import reflaxe.elixir.macros.RouterDsl.*;

typedef UserPathParams = {
  var id:Int;
}

class UsersLive {
  public static function index():String return "ok";
}

class UserController {
  public static function show():String return "ok";
}

@:native("MyAppWeb.Router")
@:router
@:routes([
  pipeline("browser", [
    plug("accepts", {initArgs: ["html"]}),
    plug("fetch_session")
  ]),
  scope("/", [
    pipeThrough(["browser"]),
    liveSession("default", [
      live("/", UsersLive, UsersLive.index),
      get("/users/:id", UserController, UserController.show, {
        paramsContract: UserPathParams
      })
    ])
  ])
])
class MyAppRouter {}
```

### Generated Elixir shape

```elixir
defmodule MyAppWeb.Router do
  use Phoenix.Router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
  end

  scope "/" do
    pipe_through :browser

    live_session :default do
      live "/", UsersLive, :index
      get "/users/:id", UserController, :show
    end
  end
end
```

Why the compiler emits this: it lowers each router node to the matching Phoenix router macro (`pipeline`, `scope`, `live_session`, `get`, `live`, etc.) while preserving nesting from the Haxe source.

## Compile-time validation for typed DSL

For typed router nodes, the compiler validates:

- Controller/live module references are real types.
- Action references exist on the target module.
- Routes with path params (`:id`, `*rest`) include `paramsContract`.
- `paramsContract` contains fields for those path params (snake_case-normalized).
- Controller/live/action refs should use resolvable type paths (for example `controllers.UserController`, and `Main.UserController` in single-file test modules).

Example of a rejected route:

```haxe
get("/users/:id", UserController, UserController.show)
```

This fails because `paramsContract` is required when path params are present.

## Router node constructor reference

- Structure:
  - `pipeline(name, children)`
  - `scope(path, children, ?opts)`
  - `pipeThrough(pipelines)`
  - `liveSession(name, children, ?opts)`
- Routes:
  - `get/post/put/patch/delete/options/head/connect/trace(path, controller, action, ?opts)`
  - `live(path, liveModule, action, ?opts)`
  - `match(verb, path, controller, action, ?opts)`
- Other Phoenix router macros:
  - `forward(path, moduleRef, ?opts)`
  - `resources(path, controller, ?opts)`
  - `resource(path, controller, ?opts)`
  - `liveDashboard(path, ?opts)`
  - `mailbox(path, ?opts)`

## Supported `HttpMethod` values

Prefer `reflaxe.elixir.macros.HttpMethod`:

- `GET`
- `POST`
- `PUT`
- `PATCH`
- `DELETE`
- `OPTIONS`
- `HEAD`
- `CONNECT`
- `TRACE`
- `MATCH`
- `LIVE`
- `LIVE_DASHBOARD`
- `MAILBOX`

## Compatibility: flat `@:routes` objects

Flat objects remain supported and are useful for migration:

```haxe
@:routes([
  {
    name: "usersIndex",
    method: HttpMethod.GET,
    path: "/users",
    controller: controllers.UserController,
    action: controllers.UserController.index
  }
])
```

String controller refs in flat `@:routes` objects are compatibility-only:

- Default: warning
- `-D router_strict_typed_refs`: compile error

Prefer typed refs in new code.

## Legacy/manual: `@:route`

`@:route(...)` on controller actions is still available for legacy/manual glue.

```haxe
@:router
class LegacyRouter {
  @:route({method: "GET", path: "/users", controller: "controllers.UserController", action: "index"})
  public static function usersIndex():String return "/users";
}
```

For new routers, prefer `@:routes` with static-imported router nodes.

## References

- `docs/04-api-reference/ANNOTATIONS.md`
- `docs/02-user-guide/INTEROP_WITH_EXISTING_ELIXIR.md`
- `examples/09-phoenix-router/README.md`
