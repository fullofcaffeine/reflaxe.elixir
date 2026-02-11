# 03 - Minimal Phoenix App (Haxe -> Elixir)

This example is the smallest Phoenix server authored in Haxe and compiled to Elixir.

## What it covers

- `@:application` supervision entrypoint
- `@:router` with `@:routes` typed route metadata
- `@:controller` action authored in Haxe
- Mix integration (`mix compile` runs Haxe compilation)

## Run

```bash
cd examples/03-phoenix-app
mix deps.get
mix compile
mix phx.server
```

Then open `http://localhost:4000/`.

## Haxe source map

- `examples/03-phoenix-app/src_haxe/PhoenixHaxeExample.hx` - OTP app module (`@:application`)
- `examples/03-phoenix-app/src_haxe/PhoenixHaxeExampleRouter.hx` - router (`@:router`, `@:routes`)
- `examples/03-phoenix-app/src_haxe/controllers/PageController.hx` - controller (`@:controller`)
- `examples/03-phoenix-app/src_haxe/server/infrastructure/*` - endpoint/web helpers

## Haxe -> generated Elixir (route + controller)

Haxe router:

```haxe
@:routes([
  {
    name: "home",
    method: HttpMethod.GET,
    path: "/",
    controller: controllers.PageController,
    action: controllers.PageController.home
  }
])
class PhoenixHaxeExampleRouter {}
```

Haxe controller:

```haxe
@:controller
class PageController {
  public static function home(conn: Conn<EmptyParams>, params: EmptyParams): Conn<EmptyParams> {
    return conn.json({message: "Hello from Haxe -> Elixir!"});
  }
}
```

Generated Elixir shape:

```elixir
get "/", PageController, :home

def home(conn, _params) do
  json(conn, %{message: "Hello from Haxe -> Elixir!"})
end
```

## Notes

- Generated Elixir is written under `examples/03-phoenix-app/lib/` (not committed).
- For a full LiveView + Ecto + Presence app, see `examples/todo-app/README.md`.
