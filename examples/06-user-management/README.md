# 06 - User Management (LiveView + Ecto)

This example demonstrates typed Phoenix app code in Haxe for a small CRUD-style user flow.

## What it demonstrates

- `@:schema` / `@:field` for Ecto schema generation
- `@:changeset` for changeset pipeline shaping
- `@:liveview` callbacks with typed assigns
- Strict TSX inline HXX authoring in LiveView render paths

## Key files

- `examples/06-user-management/src_haxe/contexts/Users.hx`
- `examples/06-user-management/src_haxe/live/UserLive.hx`
- `examples/06-user-management/src_haxe/services/UserGenServer.hx`
- `examples/06-user-management/test/user_management_test.exs`

## Run

```bash
cd examples/06-user-management
mix deps.get
mix compile
mix phx.server
```

Open `http://localhost:4000`.

## Runtime check

```bash
cd examples/06-user-management
mix deps.get
mix test --no-start
```

The runtime test intentionally uses `--no-start` because this compact pattern catalog does not include a
`UserManagement.Application` supervision module. The test still exercises generated Ecto schemas and stable
context functions so CI catches runtime regressions beyond compile-only checks.

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

Haxe LiveView render path excerpt (default strict TSX):

```haxe
public static function render(assigns: UserLiveAssigns): String {
  return <div class="user-management">
    ${renderUserList(assigns)}
    ${renderUserForm(assigns)}
  </div>;
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
- The default build path is strict TSX (compiler default).
- For the intentional legacy/balanced migration demo, see `examples/05-heex-templates/README.md`.
- For end-to-end Presence, PubSub, richer tests, and E2E smoke, see `examples/todo-app/README.md`.
