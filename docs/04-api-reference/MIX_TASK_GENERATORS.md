# Mix Task Generators (`mix haxe.gen.*`)

Reflaxe.Elixir ships a small set of Mix generators to help scaffold **Haxe-first** Phoenix/Ecto code.

## Design Principles

- **Haxe-first output**: generators write **Haxe source files only**. Elixir modules are produced when you compile via `mix compile.haxe` / `haxe build.hxml`.
- **No app-specific heuristics**: templates are generic and follow Phoenix/Ecto APIs as-is.
- **Typed by default**: prefer typed assigns/params/changesets and avoid `Dynamic` in generator output.

For end-to-end reference patterns, always compare against `examples/todo-app/`.

## Generators

### `mix haxe.gen.schema`

Generates a Haxe `@:schema` module.

Examples:

```bash
mix haxe.gen.schema User
mix haxe.gen.schema Post --table posts
mix haxe.gen.schema Account --fields "name:string,email:string,age:integer"
```

Output:
- `src_haxe/schemas/<Schema>.hx` (or `--haxe-dir`)

Notes:
- Uses modern schema metadata (`@:schema("table")`, `@:field`, `@:timestamps`, `@:changeset(...)`).
- Emits a `typedef <Schema>Params` plus an extern `changeset/2` that the compiler generates.

### `mix haxe.gen.context`

Generates a Haxe Phoenix context module (optionally also generates the schema).

Examples:

```bash
mix haxe.gen.context Accounts User users
mix haxe.gen.context Blog Post posts --schema-attrs "title:string,body:text"
mix haxe.gen.context Billing Invoice invoices --no-schema
```

Output:
- `src_haxe/contexts/<Context>.hx` (or `--haxe-dir`)
- Optional: schema via `mix haxe.gen.schema` (unless `--no-schema`)

Notes:
- Generates Phoenix-convention functions (`list_*`, `get_*`, `create_*`, `update_*`, `delete_*`).
- Uses typed `ecto.Changeset` + `haxe.functional.Result`.

### `mix haxe.gen.live`

Generates a Haxe Phoenix LiveView module with typed assigns and an HXX template.

Examples:

```bash
mix haxe.gen.live DashboardLive
mix haxe.gen.live UsersLive --events "refresh,search"
mix haxe.gen.live CounterLive --assigns "count:Int"
```

Output:
- `src_haxe/live/<Module>.hx` (or `--haxe-dir`)

Notes:
- Generates `mount/3`, `handle_event/3`, and `render/1` in Haxe (compiled to idiomatic LiveView callbacks).
- The template uses HXX assigns interpolation (e.g. `\#{@count}`) and plain HTML elements to avoid CoreComponents coupling.

### `mix haxe.gen.migration` (experimental)

Generates a Haxe migration skeleton using the typed migration DSL (`std/ecto/Migration.hx`).

Examples:

```bash
mix haxe.gen.migration CreateUsersTable --table users --columns "name:string,email:string"
mix haxe.gen.migration AddIndexToUsers --table users --index email --unique
```

Output:
- `src_haxe/migrations/<Migration>.hx` (or `--haxe-dir`)

Important:
- Ecto executes migrations from `priv/repo/migrations/*.exs`.
- If you need executable migrations today, prefer `mix ecto.gen.migration` and keep migrations in Elixir for now.

### `mix haxe.gen.project` (legacy / being refreshed)

Adds Reflaxe.Elixir plumbing to an existing Mix project (directory layout, `build.hxml`, Mix compiler config).

This task still exists for convenience, but its templates are being updated post‑`v1.0.x`. For new Phoenix apps,
prefer:

- `docs/06-guides/PHOENIX_NEW_APP.md`
- `docs/06-guides/PHOENIX_GRADUAL_ADOPTION.md`
