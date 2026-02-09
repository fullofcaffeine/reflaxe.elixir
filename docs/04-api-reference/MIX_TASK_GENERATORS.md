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
- Reflaxe.Elixir can emit runnable `.exs` migrations via an opt-in migration build (`-D ecto_migrations_exs`).

### `mix haxe.gen.extern`

Generates a starter Haxe `extern` from an Elixir or Erlang module.

Examples:

```bash
mix haxe.gen.extern Enum
mix haxe.gen.extern Ecto.Changeset --package externs.ecto --out src_haxe/externs
mix haxe.gen.extern :crypto --package externs.erlang --out src_haxe/externs
```

Output:
- `src_haxe/externs/<Module>.hx` (configurable via `--out`, `--package`, `--class-name`)

Notes:
- This generator is intended to keep app code away from untyped `__elixir__()` strings.
- The generated extern uses `elixir.types.Term` at the boundary by default (safe, generic).
- Functions with multiple arities are generated using Haxe overloads.

### `mix haxe.gen.project`

Adds Reflaxe.Elixir plumbing to an existing Mix project (directory layout, `build.hxml`, Mix compiler config).

Examples:

```bash
# Minimal scaffold (gradual adoption)
mix haxe.gen.project --force

# Phoenix-friendly scaffold (adds a typed LiveView example + HXX)
mix haxe.gen.project --phoenix --basic-modules --force
```

Output (defaults; configurable via flags):
- `src_haxe/<app>_hx/**` — isolated Haxe namespace (e.g. `src_haxe/todo_app_hx/*`)
- `build.hxml` — aligned with current compiler flags:
  - `-lib reflaxe.elixir`
  - `-D elixir_output=lib/<app>_hx`
  - `-D reflaxe_runtime`
  - `-D no-utf16`
  - `-D app_name=<ModuleName>`
  - `-dce full`
  - `-D hxx_string_to_sigil` (when `--phoenix` is enabled)
- `package.json` + `.haxerc` (unless `--skip-npm`)
- `mix.exs` updated to include `compilers: [:haxe] ++ Mix.compilers()` and a `haxe: [...]` config block
- `.gitignore` updated to ignore generated output dir by default

Notes:
- `-D app_name` should match your Phoenix app module (e.g. `MyApp`). It is used to derive framework modules (`MyApp.Repo`, `MyAppWeb.Endpoint`, Presence `otp_app`/PubSub, etc). It does not need to match your generated Haxe module namespace (which is controlled by your Haxe packages, e.g. `my_app_hx.*` → `MyAppHx.*`).
- This task is intended for **gradual adoption**: start by compiling helper modules into an isolated namespace (by default `MyAppHx.*`, derived from `src_haxe/<app>_hx/**` + `-D elixir_output=lib/<app>_hx`), call them from Elixir, and only later replace Phoenix-facing modules.
- It does not install Haxe libraries for you. Use `npx lix install ...` + `npx lix download` (see `docs/06-guides/PHOENIX_GRADUAL_ADOPTION.md`).
- `--phoenix` is meant to be run from a **Phoenix app root**.
  - If the project does not look like Phoenix (missing `assets/js/app.js` or `config/dev.exs`), the task will still scaffold the server-side parts and print instructions to run `mix haxe.phoenix.scaffold` once Phoenix files exist.

#### Phoenix Client Scaffold (`mix haxe.phoenix.scaffold`)

Phoenix client wiring is handled by a dedicated task:

```bash
mix haxe.phoenix.scaffold
```

For a scenario-driven overview (greenfield vs existing app, fail-fast vs `--warn-only`, and how marker blocks work), see `docs/06-guides/SCAFFOLDING_SYSTEM.md`.

This is the canonical entrypoint for integrating a Haxe-generated JS client bundle (Genes) into Phoenix LiveView in a way that is robust under esbuild `--watch`.

Key behaviors:
- **Marker blocks**: patches `assets/js/app.js`, `config/dev.exs`, and `mix.exs` using explicit `BEGIN reflaxe_elixir ...` / `END reflaxe_elixir ...` blocks (reruns replace block content only).
- **Fail-fast by default**: if the task cannot find an expected Phoenix insertion point (template drift or heavy customization), it raises instead of silently producing a partial scaffold.
- **Opt-out**: `mix haxe.phoenix.scaffold --warn-only` emits warnings and skips patches it cannot safely apply.

See `docs/06-guides/WATCHER_WORKFLOW.md` for the rationale and the “temp output + promote” pattern used to avoid transient `Could not resolve "./hx_app.js"` errors under esbuild watch mode.
