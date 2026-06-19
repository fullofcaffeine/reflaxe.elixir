# Ecto API Reference (User-Facing)

This page documents the primary Ecto-facing APIs and metadata used when compiling Haxe to idiomatic Ecto modules.

## Primary Modules

- `ecto.Schema`
- `ecto.Changeset`
- `ecto.Repository`
- `ecto.Query` and `ecto.TypedQuery`
- `ecto.Migration` and `ecto.Migrator`
- `ecto.DatabaseAdapter`
- `ecto.test.Sandbox`

## Schema and Field Metadata

Core schema tags:

- `@:schema("table_name")`
- `@:field`
- `@:primary_key`
- `@:timestamps`
- `@:virtual`
- associations such as `@:has_many`

```haxe
@:native("TodoApp.User")
@:schema("users")
@:timestamps
class User {
  @:field @:primary_key public var id:Int;
  @:field public var name:String;
  @:field public var email:String;
  @:field public var age:Int;
  @:virtual @:field public var password:String;
}
```

## Changeset Metadata

Core changeset tags:

- `@:changeset(...)`
- `@:validate_required([...])`
- `@:validate_format(...)`
- `@:validate_length(...)`
- `@:validate_number(...)`

These map to the standard Ecto validation pipeline and should be used instead of ad-hoc runtime string patching.

## Checked Field Selectors

For handwritten changeset code, prefer `ecto.Field.of` over raw field strings.
It returns a `SchemaField<T>` token that emits an Elixir atom:

```haxe
import ecto.Changeset;
import ecto.Field;

static function changeset(user:User, params:UserParams):Changeset<User, UserParams> {
  return new Changeset(user, params)
    .validateRequired([
      Field.of((user:User) -> user.name),
      Field.of((user:User) -> user.email)
    ])
    .validateLength(Field.of((user:User) -> user.name), {min: 2, max: 80})
    .validateNumber(Field.of((user:User) -> user.age), {
      greater_than_or_equal_to: 18,
      less_than_or_equal_to: 120
    })
    .validateFormat(Field.of((user:User) -> user.email), ~/@/);
}
```

`Field.of((user:User) -> user.email)` is a compile-time selector macro. Haxe checks that `email`
exists on `User`, then the macro lowers it to the snake_case atom expected by Ecto. For example,
`lastLoginAt` lowers to `:last_login_at`.

String literals remain supported for compatibility and migration. They are converted at compile time
when passed to token-based changeset APIs:

```haxe
changeset.validateRequired(["name", "email"]);
```

Generated Elixir still uses atoms:

```elixir
Ecto.Changeset.validate_required(changeset, [:name, :email])
```

For field names that are genuinely dynamic at runtime, use the explicit escape hatch:

```haxe
changeset.validateRequired([Field.unsafe<User>(fieldName)]);
```

Use `Field.unsafe` only for interop or migration paths where the field name is not known at compile time.

## Validation Options

Prefer Ecto-faithful option names when they are available. This makes the Haxe callsite read like
the Elixir code it will generate.

```haxe
changeset.validateNumber(Field.of((user:User) -> user.age), {
  greater_than_or_equal_to: 18,
  less_than_or_equal_to: 120
});
```

Equivalent Ecto call:

```elixir
Ecto.Changeset.validate_number(changeset, :age,
  greater_than_or_equal_to: 18,
  less_than_or_equal_to: 120
)
```

Supported number-validation options:

| Haxe option | Emitted Ecto option | Notes |
| --- | --- | --- |
| `greater_than` | `:greater_than` | Exact Ecto name |
| `greater_than_or_equal_to` | `:greater_than_or_equal_to` | Exact Ecto name |
| `less_than` | `:less_than` | Exact Ecto name |
| `less_than_or_equal_to` | `:less_than_or_equal_to` | Exact Ecto name |
| `equal_to` | `:equal_to` | Exact Ecto name |
| `not_equal_to` | `:not_equal_to` | Exact Ecto name |
| `min` | `:greater_than_or_equal_to` | Compatibility alias |
| `max` | `:less_than_or_equal_to` | Compatibility alias |

If both an exact Ecto option and its alias are present, the exact Ecto option wins. For example,
`greater_than_or_equal_to` takes precedence over `min`.

Length validation already uses Ecto's option names directly:

```haxe
changeset.validateLength(Field.of((user:User) -> user.name), {min: 2, max: 80});
```

Equivalent Ecto call:

```elixir
Ecto.Changeset.validate_length(changeset, :name, min: 2, max: 80)
```

## Checked Association Selectors

For handwritten query and preload code, prefer `ecto.Association.of` over raw
association strings. It returns a `SchemaAssociation<T>` token that emits the
Ecto atom after Haxe checks the selected association exists:

```haxe
import ecto.Association;
import ecto.TypedQuery;

var query = TypedQuery.from(User)
  .preloadAssociations([
    Association.of((user:User) -> user.posts)
  ]);

var withUser = TypedQuery.from(Post)
  .joinAssociation(Association.of((post:Post) -> post.user), Left);

var withNamedUser = TypedQuery.from(Post)
  .joinAssociationAs(Association.of((post:Post) -> post.user), Left, "user");

var loaded = Repo.preloadAssociations(user, [
  Association.of((user:User) -> user.posts)
]);
```

`Association.of((user:User) -> user.posts)` follows the same model as
`Field.of`: Haxe type-checks the selector, then the macro lowers the field name
to the snake_case atom Ecto expects.

String literals remain supported for compatibility:

```haxe
query.preload(["posts"]);
Repo.preload(user, ["posts"]);
```

For association names that are genuinely dynamic at runtime, use the explicit
escape hatch:

```haxe
query.preload([Association.unsafe<User>(associationName)]);
```

Use `Association.unsafe` only for interop or migration paths where the
association name is not known at compile time.

## Repository Surface

`@:repo({...})` configures a repository module with typed adapter options.

```haxe
@:native("TodoApp.Repo")
@:repo({adapter: Postgres, json: Jason, extensions: [], poolSize: 10})
extern class Repo {}
```

`ecto.Repository` and typed query externs provide strongly-typed query entrypoints while still emitting standard Ecto usage.

## Query Surface

Recommended user-facing patterns:

- Prefer typed query externs (`ecto.TypedQuery`) and typed lambdas/macros
- Keep table/schema references typed wherever possible
- Use `ROUTER_DSL.md`-style typed refs philosophy analogously for query callsites: avoid stringly-typed schema identifiers

Raw SQL fragments are still available for database-specific features, but the preferred spelling makes
the escape hatch visible:

```haxe
var query = TypedQuery.from(User)
  .whereUnsafeRaw("name ILIKE ?", search)
  .orderByUnsafeRaw("CASE WHEN role = 'admin' THEN 0 ELSE 1 END, inserted_at DESC");
```

Equivalent Ecto call:

```elixir
query
|> Ecto.Query.where(fragment("name ILIKE ?", ^search))
|> Ecto.Query.order_by(fragment("CASE WHEN role = 'admin' THEN 0 ELSE 1 END, inserted_at DESC"))
```

`whereRaw(...)` and `orderByRaw(...)` remain compatibility aliases. Prefer
`whereUnsafeRaw(...)` and `orderByUnsafeRaw(...)` in new code so reviewers can spot raw SQL at a
glance. Parameters passed through `?` placeholders are still pinned into Ecto fragments rather than
string-concatenated.

`@:query` currently appears as a reserved/forward-looking marker in examples; do not treat it as a stable codegen contract unless explicitly documented for your version.

## Migration Surface

`@:migration` marks migration classes for migration-specific processing.

- In `.exs` migration mode (`-D ecto_migrations_exs`), only the documented supported DSL subset is guaranteed.
- For unsupported advanced migration shapes, use hand-written Elixir migrations.

## Test Surface

- `ecto.test.Sandbox` provides typed test transaction/sandbox controls.
- Pair sandbox setup with ExUnit metadata (`@:exunit`, `@:setup`, `@:teardown`) for deterministic DB tests.

## Common Failure Modes

- Missing FK field expectations in associations (`@:belongs_to`, `@:has_many`) when association validation is enabled
- Overreliance on dynamic/untyped query snippets when typed query APIs exist
- Assuming all migration DSL shapes are rewritten in `.exs` mode
- Using generated runtime outputs as source-of-truth instead of changing `std/_std/*.hx` or compiler pipeline sources

## Related Docs

- `docs/04-api-reference/ANNOTATIONS.md`
- `docs/04-api-reference/STDLIB_SUPPORT_MATRIX.md`
- `docs/07-patterns/ECTO_INTEGRATION_PATTERNS.md`
