# Ecto Integration Patterns

This document shows the current, supported patterns for using Ecto from Haxe in Reflaxe.Elixir.

See working references:

- End-to-end LiveView + Ecto: `examples/todo-app/README.md`
- Migrations DSL: `examples/04-ecto-migrations/README.md`

## Typed Queries (`ecto.TypedQuery`)

The recommended query API is `ecto.TypedQuery`, which lets you build Ecto queries with compile-time field validation and idiomatic Elixir output.

```haxe
import ecto.TypedQuery;
import MyApp.Repo;
import MyApp.Todo;

class TodoQueries {
  public static function listTodosForUser(userId: Int): Array<Todo> {
    var query = TypedQuery
      .from(Todo)
      .where(t -> t.userId == userId)
      .orderBy(t -> [desc: t.insertedAt]);

    return Repo.all(query);
  }
}
```

Notes:

- Field names use your Haxe schema fields (e.g. `userId`, `insertedAt`); output is snake_cased to match Ecto fields.
- When a field doesn’t exist, compilation fails early with a schema validation error.

## Changesets

Reflaxe.Elixir supports two complementary approaches:

1. **Schema-driven changesets** via `@:changeset` (recommended for common CRUD flows).
2. **Direct `Ecto.Changeset` externs** for custom validation and advanced pipelines.

### 1) Schema-driven changesets (`@:changeset`)

Annotate your schema with `@:changeset(...)` and declare an `extern` for the generated function.

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
@:changeset(["title", "description", "completed", "priority", "userId"], ["title"])
class Todo {
  @:field public var id: Int;
  @:field public var title: String;
  @:field public var completed: Bool;
  @:field public var userId: Int;

  extern public static function changeset(todo: Todo, params: TodoParams): ecto.Changeset.Changeset<Todo, TodoParams>;
}
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

Compile migrations with a migration-only build (recommended), then run with standard Ecto tooling:

- `mix haxe.compile.migrations` (or `haxe build-migrations.hxml`)
- `mix ecto.migrate`
- `mix ecto.rollback`

See the full migration example and workflow notes in `examples/04-ecto-migrations/README.md`.
