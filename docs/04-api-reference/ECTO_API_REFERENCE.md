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
  @:field public var email:String;
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
