# Router DSL (`final routes` / `@:routes` / `@:route`)

## Summary

Use module-level `final routes = [...]` on a `@:router` declaration for new code.

Router declarations support:

1. **Typed tree nodes** from `RouterDsl.*` static imports (recommended)
2. **Flat route objects** `{name, method, path, ...}` (compatibility mode)

`@:route(...)` on controller functions is still supported for legacy/manual routing.

## Recommended: Module-Level `final routes` with typed router nodes

Why this section exists: Phoenix routers are nested (`pipeline`, `scope`, `live_session`). Static-imported router node builders let your Haxe source express that structure directly.

### Haxe input

```haxe
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
final routes = [
  pipeline("browser", [
    plug("accepts", {initArgs: ["html"]}),
    plug("fetch_session")
  ]),
  scope("/", [
    pipeThrough(["browser"]),
    liveSession("default", [
      live("/", UsersLive),
      get("/users/:id", UserController, UserController.show, {
        paramsContract: UserPathParams
      })
    ])
  ])
];
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
      live "/", UsersLive
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
- Controller/live/action refs should resolve as types (for example `UserController` via import, or `Main.UserController` in single-file test modules).

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
  - `live(path, liveModule, ?action, ?opts)`
  - `match(verb, path, controller, action, ?opts)`
- Other Phoenix router macros:
  - `forward(path, moduleRef, ?opts)`
  - `resources(path, controller, ?opts)`
  - `resource(path, controller, ?opts)`
  - `liveDashboard(path, ?opts)`
  - `mailbox(path, ?opts)`

### Live route action behavior

- `live("/", AppLive)` is valid and compiles to `live "/", AppLive`.
- Add an explicit action only when you need it:
  - `live("/todos/:id/edit", TodoLive, TodoLive.edit)`
- WHY: Phoenix supports live routes without `:action`; forcing placeholder action methods adds noise.

## Route option parity

- Typed route-node options are Phoenix-shaped:
  - `asName` maps to Phoenix `as:`
  - `paramsContract` is a compiler-only type check for path params
- Leave `asName` unset to keep Phoenix default helper-name inference.
- `name` is for flat compatibility-route metadata and is not a Phoenix route keyword.

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

## Compatibility: `@:routes([...])`

`@:routes([...])` remains supported for existing routers and migration work.

```haxe
import controllers.UserController;
import reflaxe.elixir.macros.HttpMethod;

@:router
@:routes([
  {
    name: "usersIndex",
    method: HttpMethod.GET,
    path: "/users",
    controller: UserController,
    action: UserController.index
  }
])
class LegacyRouter {}
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

For new routers, prefer module-level `final routes = [...]`.

## References

- `docs/04-api-reference/ANNOTATIONS.md`
- `docs/02-user-guide/INTEROP_WITH_EXISTING_ELIXIR.md`
- `examples/09-phoenix-router/README.md`
