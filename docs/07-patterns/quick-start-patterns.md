# Quick Start Patterns - Copy-Paste Ready

Copy‑paste patterns aligned with **Reflaxe.Elixir v1.0+** and the repo’s **No‑Dynamic** policy.

> When Phoenix/Ecto hand you “raw params” maps, model them as typed `typedef`s (preferred) or use `elixir.types.Term` as the explicit boundary type (never `Dynamic`).

## 1) Phoenix LiveView (typed assigns + typed params)

```haxe
package live;

import elixir.types.Term;
import phoenix.LiveSocket;
import phoenix.Phoenix.HandleEventResult;
import phoenix.Phoenix.LiveView;
import phoenix.Phoenix.MountResult;
import phoenix.Phoenix.Socket;

typedef Product = {
    var id: Int;
    var title: String;
}

typedef ProductAssigns = {
    var products: Array<Product>;
    var query: String;
    var selectedId: Null<Int>;
}

typedef ProductEventParams = {
    var ?query: String;
    var ?id: Int;
}

@:native("MyAppWeb.ProductLive")
@:liveview
class ProductLive {
    public static function mount(_params: Term, _session: Term, socket: Socket<ProductAssigns>): MountResult<ProductAssigns> {
        var liveSocket: LiveSocket<ProductAssigns> = cast socket;

        liveSocket = LiveView.assignMultiple(liveSocket, {
            products: [],
            query: "",
            selectedId: null
        });

        return Ok(liveSocket);
    }

    @:native("handle_event")
    public static function handle_event(event: String, params: ProductEventParams, socket: Socket<ProductAssigns>): HandleEventResult<ProductAssigns> {
        var liveSocket: LiveSocket<ProductAssigns> = cast socket;

        return switch (event) {
            case "search":
                var query = params.query != null ? params.query : "";
                liveSocket = LiveView.assignMultiple(liveSocket, {query: query});
                NoReply(liveSocket);

            case "select":
                liveSocket = LiveView.assignMultiple(liveSocket, {selectedId: params.id});
                NoReply(liveSocket);

            case _:
                NoReply(liveSocket);
        };
    }
}
```

Compiles to:

```elixir
defmodule ProductLive do
  use Phoenix.LiveView

  def mount(_params, _session, socket) do
    {:ok, assign(socket, %{products: [], query: "", selected_id: nil})}
  end

  def handle_event("search", params, socket) do
    query = Map.get(params, "query", "")
    {:noreply, assign(socket, %{query: query})}
  end

  def handle_event("select", params, socket) do
    {:noreply, assign(socket, %{selected_id: Map.get(params, "id")})}
  end

  def handle_event(_, _params, socket), do: {:noreply, socket}
end
```

Notes
- Use `Socket<TAssigns>` in callback signatures (what Phoenix expects).
- Cast to `LiveSocket<TAssigns>` to use ergonomic, type‑safe helpers.
- Keep params typed (`typedef ProductEventParams`) so you can do `params.query` without reflection.

## 2) Ecto schema + generated changeset (recommended default)

Use `@:changeset([...permitted], [...required])` for the common case (cast + validate_required).

```haxe
package schemas;

import ecto.Changeset;
import elixir.types.Term;

typedef UserParams = {
    ?email: String,
    ?name: String,
    ?role: String,
    ?active: Bool
}

/**
 * If you need to accept “raw” form maps, keep a broader param type around.
 * Prefer a `typedef` with optional fields and only use `Term` where truly polymorphic.
 */
typedef UserChangesetParams = {
    ?email: String,
    ?name: String,
    ?role: String,
    ?active: Bool
}

@:native("MyApp.User")
@:schema("users")
@:timestamps
@:changeset(["email", "name", "role", "active"], ["email", "name"])
class User {
    @:field @:primary_key public var id: Int;
    @:field public var email: String;
    @:field public var name: String;
    @:field public var role: String;
    @:field public var active: Bool = true;
}
```

No manual `extern` is required here: `@:schema` auto-injects a typed
`changeset<Params>(schema, params): Changeset<Schema, Params>` declaration for Haxe calls.
An explicit `extern` declaration is still accepted as an optional compatibility path.

Compiles to:

```elixir
defmodule MyApp.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :name, :string
    field :role, :string
    field :active, :boolean, default: true
    timestamps()
  end

  def changeset(user, params) do
    user
    |> cast(params, [:email, :name, :role, :active])
    |> validate_required([:email, :name])
  end
end
```

## 3) Repo module (`@:repo` config + typed results)

```haxe
package infrastructure;

import ecto.Changeset;
import ecto.DatabaseAdapter.*;
import ecto.Query.EctoQuery;
import haxe.functional.Result;

@:native("MyApp.Repo")
@:repo({
    adapter: Postgres,
    json: Jason,
    extensions: [],
    poolSize: 10
})
extern class Repo {
    @:overload(function<T>(query: EctoQuery<T>): Array<T> {})
    public static function all<T>(queryable: Class<T>): Array<T>;

    public static function get<T>(queryable: Class<T>, id: Int): Null<T>;

    public static function insert<T, P>(changeset: Changeset<T, P>): Result<T, Changeset<T, P>>;
    public static function update<T, P>(changeset: Changeset<T, P>): Result<T, Changeset<T, P>>;
    public static function delete<T>(struct: T): Result<T, Changeset<T, {}>>;
}
```

## 4) Typed queries (`Ecto.Query` + `TypedQueryLambda`)

```haxe
import ecto.Query;
using reflaxe.elixir.macros.TypedQueryLambda;

var pattern = "%" + query + "%";

var q = from(u in User)
    .where(ilike(u.email, ^pattern))
    .orderBy(u -> u.name, :asc);

var users = Repo.all(q);
```

Compiles to:

```elixir
pattern = "%" <> query <> "%"

q =
  from u in User,
    where: ilike(u.email, ^pattern),
    order_by: [asc: u.name]

users = Repo.all(q)
```

## 5) HEEx templates in Haxe (HXX)

```haxe
	import HXX.*;
import phoenix.types.Assigns;

typedef PageAssigns = {
    title: String
}

class Page {
    public static function render(assigns: Assigns<PageAssigns>): String {
        return hxx('<h1>${assigns.title}</h1>');
    }
}
```

## Next docs to read
- Gradual adoption into an existing Phoenix app: `docs/06-guides/PHOENIX_GRADUAL_ADOPTION.md`
- Todo‑app (end‑to‑end reference): `examples/todo-app/README.md`
- Example index: `examples/README.md`
