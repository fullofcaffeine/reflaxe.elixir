# Ecto Integration Patterns

This document shows the current, supported patterns for using Ecto from Haxe in Reflaxe.Elixir.

See working references:

- [End-to-end LiveView + Ecto](../../examples/todo-app/README.md)
- [Migrations DSL](../../examples/04-ecto-migrations/README.md)

## Typed Queries (`ecto.TypedQuery`)

The recommended query API is `ecto.TypedQuery`, which builds ordinary Ecto queries while validating
schema fields and predicate shapes during Haxe compilation. This excerpt is from the executable
[`Todos` context](../../examples/17-railshx-to-phoenixhx-todo/src_haxe/phoenix_hx_todo_hx/contexts/Todos.hx):

```haxe
import ecto.TypedQuery;
import elixir.Enum;
import phoenix_hx_todo_hx.data.Todo;
import phoenix_hx_todo_hx.infrastructure.Repo;

using reflaxe.elixir.macros.TypedQueryLambda;

class Todos {
  static function getForUser(userId:Int, id:Int):Null<Todo> {
    var query = TypedQuery.from(Todo)
      .where(todo -> todo.userId == userId && todo.id == id);
    var todos:Array<Todo> = Repo.all(query);

    return Enum.at(todos, 0);
  }
}
```

Compiles to:

```elixir
defmodule PhoenixHxTodo.Todos do
  require Ecto.Query

  defp get_for_user(user_id, id) do
    query =
      (require Ecto.Query;
       Ecto.Query.where(
         Ecto.Query.from(t in PhoenixHxTodo.Todo, []),
         [t],
         (t.user_id == ^user_id) and (t.id == ^id)
       ))

    todos = PhoenixHxTodo.Repo.all(query)
    Enum.at(todos, 0)
  end
end
```

Notes:

- Field names use Haxe schema fields such as `userId`; generated query fields are snake-cased to
  `user_id`.
- Captured values become normal Ecto pins, and `TypedQuery<Todo>` keeps `Repo.all` typed as
  `Array<Todo>` at the source boundary.
- Ecto—not a Reflaxe query runtime—executes the generated `Ecto.Query` struct.

When a field does not exist, compilation fails before Mix runs:

```haxe
var query = TypedQuery.from(User);
var value = 123;
var q2 = query.where(user -> user.noSuchField == value);
```

```text
Field "noSuchField" does not exist in User
```

That failure is covered by the checked
[`typed_query_invalid_field`](../../test/snapshot/negative/typed_query_invalid_field/Main.hx) fixture.

## Associations (Compile-Time Validation)

Reflaxe.Elixir supports Ecto-style associations on `@:schema` modules and validates the common FK shapes at compile time.

Recommended pattern:

- Declare the association field (typed), and also declare the FK field explicitly.
- Prefer resolvable target types (`Post`, `Array<Post>`) so cross-schema validation can run.

Example:

```haxe
@:schema("users")
class User {
  @:field public var id: Int;

  @:has_many("posts")
  public var posts: Array<Post>;
}

@:schema("posts")
class Post {
  @:field public var id: Int;

  @:field public var userId: Int; // validated by @:belongs_to("user")

  @:belongs_to("user")
  public var user: User;
}
```

Validation behavior:

- `@:belongs_to("user")` requires a local FK field `user_id` (or `userId`).
- `@:has_many("posts")` / `@:has_one("post")` requires the target schema to have `user_id` (or `userId`) when the target schema type is resolvable.
- FK overrides are supported via a third string param or an options object with `foreign_key`.

Configuration / escape hatches:

- Default: missing FK fields are **errors** (compile fails).
- `-D ecto_assoc_warn_only`: downgrade missing FK errors to warnings.
- `-D ecto_no_assoc_validation`: disable globally.
- `@:ecto_no_assoc_validation`: disable for a single schema.

Notes:

- This validates schema shapes, not your database. Use migrations + `foreign_key_constraint` for full DB integrity.
- If the association target type is `Dynamic`/unresolvable, cross-schema validation is skipped with a warning.
  - If needed, you can provide a string target hint (e.g. `@:has_many("posts", "Post")`) as long as that type is compiled in the same Haxe build.

## Changesets

Reflaxe.Elixir supports two complementary approaches:

1. **Schema-driven changesets** via `@:changeset` (recommended for common CRUD flows).
2. **Direct `Ecto.Changeset` externs** for custom validation and advanced pipelines.

### 1) Schema-driven changesets (`@:changeset`)

Annotate your schema with `@:changeset(...)`. Named config is recommended:
`@:changeset(cast([...]), validate([...]))`.
The schema macro auto-injects a typed Haxe declaration for
`changeset<Params>(schema, params)` when one is not explicitly defined.

Example (from the todo-app pattern):

```haxe
typedef TodoParams = {
  ?title: String,
  ?description: String,
  ?completed: Bool,
  ?priority: String,
  ?userId: Int
}

@:schema("todos")
@:changeset(cast(["title", "description", "completed", "priority", "userId"]), validate(["title"]))
class Todo {
  @:field public var id: Int;
  @:field public var title: String;
  @:field public var completed: Bool;
  @:field public var userId: Int;
}
```

Optional compatibility path (not required for new code):

```haxe
class Todo {
  extern public static function changeset(todo: Todo, params: TodoParams): ecto.Changeset<Todo, TodoParams>;
}
```

Legacy positional form remains supported: `@:changeset(["title", ...], ["title"])`.

Compiles to:

```elixir
defmodule Todo do
  use Ecto.Schema
  import Ecto.Changeset

  schema "todos" do
    field :title, :string
    field :description, :string
    field :completed, :boolean
    field :priority, :string
    field :user_id, :integer
    timestamps()
  end

  def changeset(todo, params) do
    todo
    |> cast(params, [:title, :description, :completed, :priority, :user_id])
    |> validate_required([:title])
  end
end
```

Using it with a typed Repo surface:

```haxe
import ecto.Changeset;
import MyApp.Repo;
import haxe.functional.Result;

function createTodo(params: TodoParams): Result<Todo, Changeset<Todo, TodoParams>> {
  var changeset = Todo.changeset(new Todo(), params);
  return Repo.insert(changeset);
}
```

Pattern matching stays in Haxe enums, not Elixir tuples:

```haxe
switch (createTodo(params)) {
  case Result.Ok(todo):
    // success
  case Result.Error(changeset):
    // validation errors
}
```

For custom/manual changeset pipelines, prefer checked selectors over raw field strings:

```haxe
import ecto.Changeset;
import ecto.Field;

function validateTodo(todo:Todo, params:TodoParams):Changeset<Todo, TodoParams> {
  return new Changeset(todo, params)
    .validateRequired([Field.of((todo:Todo) -> todo.title)])
    .validateLength(Field.of((todo:Todo) -> todo.title), {min: 2, max: 120});
}
```

`Field.of` catches field typos during Haxe compilation and converts camelCase schema fields to the
snake_case atom fields expected by Ecto. String literals still work for migration, but dynamic
field names should use `Field.unsafe<Todo>(fieldName)` so runtime atom creation is explicit.

### 2) Keep `__elixir__()` out of apps (use std bridges)

Some Ecto ergonomics are easiest to express with `__elixir__()` (sigils, keyword options, certain pipeline shapes).

Rule of thumb:

- Don’t use `__elixir__()` directly in application code.
- Prefer a reusable, typed helper in `std/ecto/**` (or `std/phoenix/**`) that centralizes any required injection.

For example, `std/ecto/ChangesetBridge.hx` wraps common `Ecto.Changeset.*` pipelines while keeping injection in the stdlib.

## Migrations (`@:migration`)

Migrations can be authored in Haxe using the typed DSL in `std/ecto/Migration.hx` and compiled into standard `Ecto.Migration` modules.

Example (runnable `.exs` emission requires a timestamp):

```haxe
import ecto.Migration;
import ecto.Migration.ColumnType;

@:migration({timestamp: "20240101120000"})
class CreateUsers extends Migration {
  public function up(): Void {
    createTable("users")
      .addId()
      .addColumn("name", ColumnType.String(), {nullable: false})
      .addColumn("email", ColumnType.String(), {nullable: false})
      .addTimestamps()
      .addIndex(["email"], {unique: true});
  }

  public function down(): Void {
    dropTable("users");
  }
}
```

Compiles to:

```elixir
defmodule Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def up do
    create table(:users) do
      add :name, :string, null: false
      add :email, :string, null: false
      timestamps()
    end

    create unique_index(:users, [:email])
  end

  def down do
    drop table(:users)
  end
end
```

Compile migrations with a migration-only build (recommended), then run with standard Ecto tooling:

- `mix haxe.compile.migrations` (or `haxe build-migrations.hxml`)
- `mix ecto.migrate`
- `mix ecto.rollback`

See the full migration example and workflow notes in `examples/04-ecto-migrations/README.md`.
