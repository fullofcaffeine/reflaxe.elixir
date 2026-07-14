# 03 - Minimal Phoenix App (Haxe -> Elixir)

This example is the smallest Phoenix server authored in Haxe and compiled to Elixir.

## What it covers

- `@:application` supervision entrypoint
- `@:router` with module-level typed `routes` DSL
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
- `examples/03-phoenix-app/src_haxe/PhoenixHaxeExampleRouter.hx` - router (`@:router`, module-level `routes`)
- `examples/03-phoenix-app/src_haxe/controllers/PageController.hx` - controller (`@:controller`)
- `examples/03-phoenix-app/src_haxe/server/infrastructure/*` - endpoint/web helpers

## Haxe -> generated Elixir (route + controller)

Haxe router:

```haxe
import controllers.PageController;
import reflaxe.elixir.macros.RouterDsl.*;

@:native("PhoenixHaxeExampleWeb.Router")
@:router
final routes = [
  pipeline(browser, [
    plug(accepts, {initArgs: ["html"]}),
    plug(fetch_session)
  ]),
  scope("/", [
    pipeThrough([browser]),
    get("/", PageController, PageController.home)
  ])
];
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

## Ownership mode: in-place

This example is the small in-place ownership fixture:

- `build.hxml` sets `-D elixir_output=lib`;
- `mix.exs` sets the Haxe compiler `target_dir: "lib"`;
- `_GeneratedFiles.json` records the exact generated paths and content hashes.

That is the same root a normal Phoenix project uses for handwritten modules. Reflaxe.Elixir stages
the complete build and rejects an existing unowned target before publishing anything; stale
manifest-owned paths may be deleted, while unrelated `.ex` files are never discovered by scanning.
The repository's example compile/WAE lanes regenerate this in-place shape. See
[Generated Output Ownership](../../docs/02-user-guide/GENERATED_OUTPUT_OWNERSHIP.md).

## Notes

- Generated Elixir is written under `examples/03-phoenix-app/lib/` (not committed).
- For a full LiveView + Ecto + Presence app, see `examples/todo-app/README.md`.
