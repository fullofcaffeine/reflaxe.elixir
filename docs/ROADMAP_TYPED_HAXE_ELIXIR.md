# Roadmap: Typed Haxe API + Idiomatic Elixir + Phoenix Compatibility

## Goal

- Deliver a beautiful, typed Haxe developer experience that:
  - Compiles to idiomatic Elixir that looks hand‑written.
  - Respects Phoenix/Ecto conventions and workflows (mix compile, ecto.migrate, phx.server).
  - Stays app‑agnostic and avoids brittle “magic”.

## Success Criteria

- Haxe code provides compile‑time type safety for schemas, queries, changesets, and migrations.
- Emitted Elixir matches Phoenix/Ecto idioms (schema/changeset, Ecto.Query pipelines, migrations in `priv/repo/migrations`).
- Works with mix tasks, live reload, code reloader, and standard Phoenix conventions.
- No `Dynamic` in compiler metadata or core paths; clear FQCN usage documented.

## Phases and Milestones

### 1) Typed Query API (Macros First)

**Design**

- Provide macro overloads for static queries:
  - `from(Class<T>)` → Ecto query context
  - `where(q -> q.userId == val)` → `where([q], q.user_id == ^val)`
  - `orderBy(q -> [asc: q.insertedAt, desc: q.priority])` → `order_by([q], [asc: q.inserted_at, desc: q.priority])`
  - `select(q -> {id: q.id, title: q.title})` → `select([q], %{id: q.id, title: q.title})`
  - `join(q -> q.posts, :left, as: :posts)` → `join(:left, [q], p in assoc(q, :posts), as: :posts)`
  - `groupBy(q -> [q.userId])` → `group_by([q], [q.user_id])`
  - Aggregates: `count(q.id)`, `avg(q.value)`, window functions if needed.
- Validate lambdas at compile time via SchemaIntrospection (no `Dynamic`).
- Resolve camelCase→snake_case, map Haxe names to Elixir atoms.
- Emit idiomatic pipes with stable bindings.

**Implementation**

- Extend `src/reflaxe/elixir/macro/EctoQueryMacros.hx`:
  - Parse lambdas, extract field paths, directions, aliases.
  - Validate fields against schema metadata (see “Schema Emission”).
  - Generate final Elixir snippet string fragments for each clause.
  - Compose a single Ecto pipeline string with joins, wheres, order_by, select, group_by.
- Keep runtime helpers for dynamic filters only:
  - `where(fieldName: String, value)` → `field(q, ^String.to_existing_atom(Macro.underscore(fieldName))) == ^value`
  - `orderBy(fieldName: String, dir)` → `[asc|desc: field(q, ^String.to_existing_atom(Macro.underscore(fieldName)))]`
- Replace usages in TodoLive to use macros for static fields; keep runtime path for UI‑driven filters.

**Deliverables**

- Updated `std/ecto/Query.hx` with macro surface and runtime fallback.
- Tests: snapshot queries (basic, joins, group, aggregates, order lists).
- Example upgrade: TodoLive uses macros for static parts.

**Acceptance**

- Emitted code matches hand‑written Ecto pipelines.
- Compile‑time errors for invalid fields (nice messages).
- Dynamic filters still work without atom leaks.

### 2) Schema Emission (App‑Agnostic, Typed)

**Design**

- `@:schema` classes become Ecto.Schema modules:
  - Field names map to snake_case atoms.
  - Type mapping:
    - `String` → `:string`
    - `Int` → `:integer`
    - `Bool` → `:boolean`
    - `Float`/`Single` → `:float`
    - `Date`/`NaiveDateTime` → `:naive_datetime` (later add `:utc_datetime`)
    - `Array<String>` → `{:array, :string}` (extendible to other arrays)
    - `Option<T>`/`Null<T>` unwrap to `T` for validation; schema remains Elixir‑idiomatic with nils.
  - `timestamps()` emits only with `@:timestamps`.
  - Associations: plan `@:has_many`/`@:belongs_to`/`@:has_one` (phase 2.5).

**Implementation**

- `ModuleBuilder.hx`: populate `ElixirMetadata` with:
  - `haxeFqcn: String` (Fully Qualified Class Name; example `server.schemas.Todo`).
  - `schemaFields: Array<{name, type}>` inferred from class fields (typed only).
  - `hasTimestamps: Bool` from `@:timestamps`.
  - Note on FQCN: string because transformers run outside macro‑only phases; resolve later using this handle. Documented inline.
- `AnnotationTransforms.hx`: `buildSchemaBody()` consumes typed metadata (no `Dynamic`):
  - Emit `field(:snake_name, :ecto_type)` for each field except id.
  - Emit `timestamps()` conditionally.
- Changesets:
  - Keep `@:changeset` generation and typed Changeset wrappers.
  - Provide helpers for typed attrs; `validateRequired([...])` using Haxe arrays of strings (converted to atoms at emission).

**Deliverables**

- Emitted schemas match Haxe `@:schema` classes field‑for‑field, idiomatic Ecto.
- Example: Todo schema shows `title`, `description`, `completed:boolean`, `priority`, `due_date:naive_datetime`, `tags: {:array, :string}`, `user_id:integer`, `timestamps()`.

**Acceptance**

- No app‑specific fallbacks anywhere.
- No `Dynamic` in emission path.
- Compiles and works with `mix compile`; repo ops succeed.

### 3) Migrations (Define in Haxe, Run via Mix)

**Design**

- `@:migration({table: "todos"})` Haxe classes define table shape with `@:field` metadata:
  - `type`, `null`, `default`, and `@:index`/`@:unique`/`@:constraint` annotations.
  - Examples:
    - `@:field({type: "string", null: false}) public var title: String;`
    - `@:index("email", unique: true)`
    - `@:constraint("name_length", check: "length(name) >= 2")`
  - Derived types from Haxe fields unless overridden by `@:field`.
- Compiler writes timestamped `.exs` files under `priv/repo/migrations`.
- `mix ecto.migrate` picks them up normally.

**Implementation**

- Add MigrationCompiler (or extend transformer):
  - Discover `@:migration` classes.
  - Compute filename timestamp deterministically (or at compile time).
  - Emit `Ecto.Migration` modules:
    - `change/0` with `create table`; add columns/types/options.
    - `create index`/`unique_index`; constraints.
    - `timestamps` when requested.
  - Support `alter`/`add`/`remove` via dedicated annotations or naming (phase 2).
- Mix task integration:
  - Keep `mix haxe.gen.migration` for scaffolding, but primary migration files come from Haxe compilation.

**Deliverables**

- Compiler emits `.exs` migrations on build into `priv/repo/migrations`.
- Example: `CreateTodos` and `CreateUsers` produced from Haxe sources, correct types.
- Docs for the `@:migration` and `@:field` DSL.

**Acceptance**

- `mix ecto.migrate` works end‑to‑end without manual editing.
- Migrations are reproducible and deterministic.

### 4) Repo/Types/Config

- Repo config:
  - Keep `:types` optional in dev to avoid `Postgrex.TypeManager` races; re‑enable in prod/test once stable.
  - `@:postgrexTypes` and `@:dbTypes` remain supported and deterministic (`Types.define`).
- Environment:
  - Ensure dev watchers don’t fight Haxe recompile; keep watcher optional, document enabling.

### 5) LiveView/Phoenix Integration

- LiveView modules:
  - Keep `@:liveview` builder producing public `def` functions for callbacks.
  - Ensures assigns handling uses snake_case on the Elixir side; Haxe remains camelCase via assign macros.
- Router macros:
  - `@:route` macros validate and generate `Phoenix.Router` code idiomatically.

### 6) Changesets and Ecto Optionality

- Typed Changeset wrapper:
  - Provide typed `Changeset<T, Params>` to validate and cast.
  - Map Haxe `Null`/`Option` to Ecto `nil` semantics within changesets.
  - Helper functions: `validateRequired([...])`, `validateLength("field", {min, max})`, `validateFormat("email", regex)`.

### 7) Advanced Query Coverage (Phase 2)

- Add typed support for:
  - `preload` (assoc lists)
  - `distinct`, `limit`/`offset` (typed ints)
  - Composable `fragment` with guardrails
  - Transactions and Repo options (typed)
  - Window functions and `over`/`partition_by`

### 8) Date/Time Handling

- Keep `Date.now()` wrapper design:
  - Haxe `Date` instance with private `datetime` pointing to Elixir `DateTime`, preventing stray `this` expansions.
- `DateConverter` round‑trips for `Date`/`NaiveDateTime`/`DateTime` externs.
- Unix time units correctness (`:millisecond` vs `:second`).

### 9) Determinism and Ordering

- Maintain global topological ordering for require/inline deterministic strategy.
- Ensure generated file names and module names are stable.
- Avoid multi‑line injections that split expressions.

### 10) Validation and Tests

- Snapshot tests:
  - Typed Query macros: basic → advanced patterns.
  - Schema emission from `@:schema`: fields, types, timestamps, arrays.
  - Migration emission: table creation, indexes, constraints.
- Elixir validation:
  - `test/validate_elixir.sh` parse‑only checks across snapshots.
- Example app integration:
  - `make -C test all`
  - `cd examples/todo-app && mix ecto.reset && mix phx.server`

### 11) Documentation

- Add a developer guide:
  - FQCN metadata semantics and why it’s a String.
  - Typed Query macro usage; examples mapping Haxe → Elixir.
  - `@:schema` type mapping table (Haxe → Ecto types).
  - `@:migration` DSL: all fields, indexes, constraints, timestamps.
  - Phoenix integration: watchers, reloader, OTP application behavior.
- Update AGENTS.md references:
  - Layered API policy (externs vs high‑level wrappers).
  - Bootstrap strategies and entrypoints.
  - `Date.hx` design rationale, `@:privateAccess` note.

### 12) Cleanup and Regression Removal

- Remove any app‑specific fallbacks or hotfixes in compiler paths.
- Ensure no `Dynamic` remains in metadata paths used by transformers.
- Restore optional Postgrex types usage with a documented toggle.

## Milestone Plan (Suggested Order)

1. Typed Query macros + macro tests + migrate TodoLive to macros (static parts).
2. Finalize `@:schema` emission from typed metadata; schema tests; Todo schema verified.
3. Implement `@:migration` compiler; integrate with `mix ecto.migrate`; migration tests.
4. Repo/types config cleanup + docs on enabling Types in prod/test.
5. Advanced query features + tests (preload/distinct/windows/transactions).
6. Docs and examples polish; verify todo app end‑to‑end as a regular Phoenix app.

## Risks and Mitigations

- Atom leaks from dynamic filters:
  - Use `String.to_existing_atom(Macro.underscore(field))`; document runtime error if unknown field (good feedback).
- Postgrex.TypeManager races:
  - Keep types module optional in dev; enable in prod/test; or ensure deterministic types define.
- Elixir warnings from Date compare result strings:
  - Adjust date utils to compare atoms (`:eq`, `:gt`, `:lt`) instead of strings.

## Acceptance Checklist

- Todo app launches with `mix phx.server`, renders index, queries run with typed `where/order_by`, migrations applied purely from Haxe definitions.
- Emitted code is idiomatic Ecto/Phoenix; no helper leakage; matches hand‑written style.
- Typed Haxe API provides clear compile‑time errors for invalid fields; runtime helpers exist for dynamic cases.

