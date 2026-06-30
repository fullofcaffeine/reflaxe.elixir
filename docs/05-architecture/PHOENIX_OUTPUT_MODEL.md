# Phoenix Output Model

PhoenixHx has Haxe-specific authoring tools, but generated app code should still
look like a handwritten Phoenix app. This document defines the output model used
for Phoenix applications and examples.

## Principle

PhoenixHx may use Haxe source roots, packages, macros, manifests, and runtime
support internally. App-facing generated Phoenix code should target normal
`MyApp.*` / `MyAppWeb.*` modules and normal Phoenix paths unless a documented
runtime-support artifact is strictly required.

Do not treat Haxe source layout as the Elixir app architecture. In particular,
`src_shared/shared/**` is a Haxe classpath root for shared typing; it does not
mean generated app code should live under `lib/shared/**`.

## Four Independent Axes

Keep these concepts separate:

| Axis | Meaning | Example |
| --- | --- | --- |
| Haxe source root | What Haxe can import and type | `src_shared`, `src_haxe/server` |
| Haxe package | Authoring organization | `shared.liveview`, `server.live` |
| Target Elixir module | Runtime/review namespace | `TodoAppWeb.TodoLive` |
| Physical output root | Where files are written | `lib`, `build/phoenix/lib` |

The compiler flow should be:

```text
Haxe source roots
  -> Haxe module/package/type graph
  -> PhoenixHx target namespace mapping
  -> Elixir modules: MyApp.* / MyAppWeb.*
  -> physical output root chosen by the workflow mode
```

## Workflow Modes

PhoenixHx should support two workflow modes. They choose where files are
materialized; they must not create different semantic output models.

### In-Place Phoenix Mode

Use this for existing Phoenix apps and gradual adoption. The Phoenix app is the
working app, and PhoenixHx writes generated artifacts into that app's normal
paths with ownership safeguards.

Typical output:

```text
lib/my_app/**
lib/my_app_web/**
priv/repo/migrations/**
test/generated/**
assets/js/phoenix_hx/**
```

`-D elixir_output=lib` is valid for app-native output. The important part is the
target module mapping: application modules should be `MyApp.*` / `MyAppWeb.*`,
not accidental top-level `Server.*` or `Shared.*` modules derived from source
folders.

For low-risk gradual adoption, an isolated helper namespace is still useful:

```hxml
-D elixir_output=lib/my_app_hx
```

with Haxe packages such as `my_app_hx.*` emitting modules such as
`MyAppHx.Greeter`. That is a namespace strategy inside in-place mode, not a
separate backend.

### Materialized Phoenix App Mode

Use this for generated demo apps, examples, CI artifacts, release smoke tests,
and dogfood apps whose Phoenix tree is produced from Haxe inputs.

The default root should be:

```text
build/phoenix
```

`dist/phoenix` should be reserved for release-like artifacts. A materialized app
is generated source that should be inspectable, compilable, and testable:

```text
build/phoenix/
  mix.exs
  config/
  lib/
    todo_app.ex
    todo_app/
    todo_app_web.ex
    todo_app_web/
  priv/
    repo/migrations/
  assets/
  test/
  .phoenixhx/
    manifest.json
```

For a single app, the happy path should be:

```bash
cd build/phoenix
mix test
```

## Phoenix-Native Path Mapping

For an app module `TodoApp` and web module `TodoAppWeb`, app-native output should
follow Phoenix conventions:

| Artifact | Target module | Path |
| --- | --- | --- |
| Application callback | `TodoApp.Application` | `lib/todo_app/application.ex` |
| Repo | `TodoApp.Repo` | `lib/todo_app/repo.ex` |
| Domain context | `TodoApp.Todos` | `lib/todo_app/todos.ex` |
| Schema | `TodoApp.Todos.Todo` | `lib/todo_app/todos/todo.ex` |
| Router | `TodoAppWeb.Router` | `lib/todo_app_web/router.ex` |
| Endpoint | `TodoAppWeb.Endpoint` | `lib/todo_app_web/endpoint.ex` |
| Controller | `TodoAppWeb.TodoController` | `lib/todo_app_web/controllers/todo_controller.ex` |
| LiveView | `TodoAppWeb.TodoLive` | `lib/todo_app_web/live/todo_live.ex` |
| Core components | `TodoAppWeb.CoreComponents` | `lib/todo_app_web/components/core_components.ex` |
| Channel | `TodoAppWeb.TodoChannel` | `lib/todo_app_web/channels/todo_channel.ex` |
| Live event contract, when public/reused | `TodoAppWeb.LiveEvents.TodoEvents` | `lib/todo_app_web/live_events/todo_events.ex` |
| Domain contract, when public/runtime | `TodoApp.Contracts.TodoPayload` | `lib/todo_app/contracts/todo_payload.ex` |
| Migration | `TodoApp.Repo.Migrations.CreateTodos` | `priv/repo/migrations/<timestamp>_create_todos.exs` |
| Haxe-authored ExUnit test | `TodoAppWeb.TodoLiveGeneratedTest` | `test/generated/**/*_test.exs` initially |

The mapping rule is target-module first. `@:native("TodoAppWeb.TodoLive")`,
Phoenix annotations, and future namespace mappings should decide the target
module and therefore the output path. Haxe packages are an authoring aid, not the
last word on app-facing Elixir layout.

## Shared Contracts

A good source layout is:

```text
src_shared/
  shared/
    liveview/
      TodoEvent.hx
    channels/
      PingProtocol.hx

src_haxe/
  server/
    live/
      TodoLive.hx
  client/
    hooks/
      TodoHook.hx
```

Builds should include only the roots they need:

```hxml
# server
-cp src_shared
-cp src_haxe/server

# client
-cp src_shared
-cp src_haxe/client

# tests
-cp src_shared
-cp src_haxe/test
```

Avoid broad `-cp src_haxe` in tests just to import shared contracts. That can
type routers, LiveViews, controllers, and client modules that are unrelated to
the test and can trigger macro timing or dependency-cycle failures.

Emission policy for shared contracts:

| Contract kind | Default emission |
| --- | --- |
| Pure typedef used only for Haxe type checking | No Elixir module |
| Live Event Protocol used by one LiveView | Private decode/dispatch helpers inside that LiveView |
| Live Event Protocol reused by multiple LiveViews | `MyAppWeb.LiveEvents.<Name>` |
| Channel protocol crossing JS/server | `MyApp.Contracts.Channels.<Name>` or context-specific app namespace |
| Public API DTO/contract | Explicit app namespace, preferably context-owned |
| Runtime enum/module genuinely needed by Elixir | Explicit `MyApp.*` / `MyAppWeb.*`, never accidental top-level `Shared.*` |

## Configuration And Metadata Direction

The current compiler already supports `@:native("Target.Module")` for many
module mappings. The output model should make that rule universal across
classes, enums, abstracts, generated companions, extra files, Live Event
Protocol artifacts, Repo companion modules, and migrations.

Future PhoenixHx configuration can make larger apps less annotation-heavy:

```json
{
  "appModule": "TodoApp",
  "webModule": "TodoAppWeb",
  "mode": "in_place",
  "outputRoot": ".",
  "elixirOutput": "lib",
  "runtime": "dependency",
  "sourceRoots": {
    "server": "src_haxe/server",
    "client": "src_haxe/client",
    "shared": "src_shared"
  },
  "namespaceMappings": [
    {
      "haxePackage": "server.contexts",
      "elixirNamespace": "TodoApp"
    },
    {
      "haxePackage": "server.live",
      "elixirNamespace": "TodoAppWeb"
    },
    {
      "haxePackage": "shared.liveview",
      "elixirNamespace": "TodoAppWeb.LiveEvents",
      "emit": "auto"
    }
  ]
}
```

Useful metadata concepts:

- `@:native("TodoApp.SomeModule")`: authoritative target module and output path.
- `@:compileTimeOnly`: no `.ex` / `.exs` output; useful for shared typedefs,
  phantom protocol declarations, and macro-only declarations.
- `@:runtimeSupport`: marks compiler/framework runtime modules so they go to a
  runtime package or explicit vendored-runtime output, not app-facing paths.
- Higher-level Phoenix metadata such as `@:phoenixContext("Todos")`,
  `@:phoenixWeb`, or `@:phoenixContract(...)` can reduce repeated raw
  `@:native` strings once the mapping is implemented.

## Runtime Support

Runtime support is not app business code. Generated app code may call real
Phoenix/Ecto/Plug APIs and documented support namespaces:

```text
Phoenix.*
Ecto.*
Plug.*
MyApp.*
MyAppWeb.*
PhoenixHx.*
Reflaxe.*
```

Generated app code must not define modules under real framework namespaces such
as `Phoenix.*`, `Ecto.*`, or `Plug.*`.

The preferred long-term model is a runtime dependency for `PhoenixHx.*`,
`Reflaxe.*`, and Haxe compatibility support. A vendored fallback may be useful
for examples or offline snapshots, but it should be explicit and visibly owned,
for example:

```text
lib/phoenix_hx_runtime/**
```

Do not copy support into `lib/phoenix/**`, `lib/ecto/**`, or `lib/plug/**`.

## Ownership

In-place mode needs fail-closed writes:

- Write a missing generated file.
- Rewrite a manifest-owned file.
- Adopt a file with a valid generated header.
- Refuse to overwrite an unowned app file.
- Remove stale manifest-owned files.
- Allow `--force` only as an explicit ownership-transfer action.

The manifest should live at:

```text
.phoenixhx/manifest.json
```

App-facing generated files should carry a short header:

```elixir
# Generated by PhoenixHx from src_haxe/server/live/TodoLive.hx.
# Managed by .phoenixhx/manifest.json. Do not edit this file directly.
```

## Current Debt And Guardrails

Existing examples may still emit some app-facing modules under top-level
`lib/shared/**` or `lib/server/**`. Treat that as migration debt, not as the
desired architecture.

New app-facing output should avoid:

```text
lib/shared/**
lib/server/**
lib/client/**
lib/phoenix/**
lib/ecto/**
lib/plug/**
```

Allowlist only documented runtime support namespaces. Once the todo-app output
is migrated, CI should fail on new app-facing leakage into those paths.

## Tests To Add

The implementation should be protected at these layers:

- Snapshot tests for module and path together: application, router, endpoint,
  LiveView, controller, schema, native enum, generated companion, and migration.
- Negative layout guards for forbidden app-facing paths.
- Todo-app WAE/runtime checks that also assert no app-facing `lib/shared/**` or
  `lib/server/**` remains after migration.
- Materialized app tests that generate into a temporary `build/phoenix`, then
  run `mix compile --warnings-as-errors` and `mix test`.
- Ownership tests for first write, manifest-owned rewrite, unowned collision,
  generated-header adoption, stale cleanup, force, and path traversal rejection.
- Live Event Protocol tests proving private one-LiveView protocols emit no
  public companion module unless reused or explicitly requested.

The key invariant is simple: both workflow modes must use the same target module
and path mapper. Mode only decides where the Phoenix app tree is written.
