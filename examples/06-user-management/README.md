# 06 - User Management (LiveView + Ecto)

This example demonstrates typed Phoenix app code in Haxe for a small CRUD-style user flow.

## What it demonstrates

- `@:schema` / `@:field` for Ecto schema generation
- `@:changeset` for changeset pipeline shaping
- `@:liveview` callbacks with typed assigns
- HXX templates in LiveView render paths

## Key files

- `examples/06-user-management/src_haxe/contexts/Users.hx`
- `examples/06-user-management/src_haxe/live/UserLive.hx`
- `examples/06-user-management/src_haxe/services/UserGenServer.hx`

## Run

```bash
cd examples/06-user-management
mix deps.get
mix compile
mix phx.server
```

Open `http://localhost:4000`.

## Haxe -> generated Elixir examples

Haxe schema excerpt:

```haxe
@:schema("users")
class User {
  @:primary_key public var id: Int;
  @:field({type: "string", nullable: false}) public var name: String;
  @:field({type: "string", nullable: false}) public var email: String;
}
```

Generated Elixir shape:

```elixir
schema "users" do
  field :name, :string
  field :email, :string
  timestamps()
end
```

Haxe LiveView render path excerpt:

```haxe
public static function render(assigns: UserLiveAssigns): String {
  return hxx('
    <div class="user-management">
      ${renderUserList(assigns)}
      ${renderUserForm(assigns)}
    </div>
  ');
}
```

Generated Elixir shape:

```elixir
def render(assigns) do
  ~H"""
  <div class="user-management">
    ...
  </div>
  """
end
```

## Notes

- This example is intentionally compact and focuses on compiler surfaces, not full production UX.
- Templates currently use balanced-mode `hxx('...')` composition for compactness; this is valid, but TSX inline markup is the recommended default for new code.
- For end-to-end Presence, PubSub, richer tests, and E2E smoke, see `examples/todo-app/README.md`.
