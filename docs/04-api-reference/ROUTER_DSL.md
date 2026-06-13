# Router DSL (`final routes` / `@:routes` / `@:route`)

## Summary

Use module-level `final routes = [...]` on a `@:router` declaration for new code.
This is the `@:routes`-first model: route metadata lives in one router-level declaration, not scattered across empty helper functions.

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
  pipeline(browser, [
    plug(accepts, {initArgs: ["html"]}),
    plug(fetch_session)
  ]),
  scope("/", [
    pipeThrough([browser]),
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

## Typed Tokens vs Unsafe Escape Hatches

Why this section exists: `pipeline` and common `plug` names are a finite set in most apps, so plain strings are easy to mistype and hard to autocomplete.

Preferred typed style:

```haxe
import reflaxe.elixir.macros.RouterDsl.*;

final routes = [
  pipeline(browser, [
    plug(accepts, {initArgs: ["html"]}),
    plug(fetch_session)
  ]),
  scope("/", [
    pipeThrough([browser])
  ])
];
```

Custom names (still typed):

```haxe
import reflaxe.elixir.macros.RouterDsl.*;

pipeline(pipelineName("admin"), [
  plug(plugName("my_custom_plug"))
]);
```

Explicit escape hatches for legacy/dynamic values:

```haxe
pipelineUnsafe("admin", [
  plugUnsafe("my_custom_plug")
]);
pipeThroughUnsafe(["admin"]);
```

Use `*Unsafe` only when values are intentionally dynamic or migration glue.

## Router node constructor reference

- Structure:
  - `pipeline(name, children)`
  - `pipelineUnsafe(name, children)` (escape hatch)
  - `scope(path, children, ?opts)`
  - `pipeThrough(pipelines)`
  - `pipeThroughUnsafe(pipelines)` (escape hatch)
  - `liveSession(name, children, ?opts)`
  - `plug(target, ?opts)` where `target` is a typed plug token or module reference
  - `plugUnsafe(target, ?opts)` (escape hatch)
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

## Compatibility: flat `@:routes([...])`

Flat `@:routes([...])` objects remain supported for existing routers and migration work. They still participate in router-level metadata and can use typed controller/action refs.

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

Prefer typed refs in new code. The strict flag is useful in CI once a router has migrated away from string controller literals.

Migration shape:

```haxe
// Legacy compatibility: warns by default.
@:routes([
  {name: "usersIndex", method: "GET", path: "/users", controller: "controllers.UserController", action: "index"}
])

// Migration step: flat @:routes object, but typed refs.
@:routes([
  {name: "usersIndex", method: HttpMethod.GET, path: "/users", controller: UserController, action: UserController.index}
])

// Preferred final shape: module-level typed tree.
final routes = [
  scope("/", [
    get("/users", UserController, UserController.index)
  ])
];
```

## Legacy/manual: `@:route`

`@:route(...)` on controller actions is still available for legacy/manual glue. Use it when a route must stay function-by-function, or when intentional string metadata is bridging existing Elixir/router code.

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
- `docs/04-api-reference/TYPE_SAFE_CHILD_SPEC.md`
- `docs/02-user-guide/INTEROP_WITH_EXISTING_ELIXIR.md`
- `examples/09-phoenix-router/README.md`
