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

## Beginner Mental Model

If you know Phoenix, the goal is simple: after Haxe compiles, you should be able
to inspect the Phoenix tree and recognize it.

In vanilla Phoenix, you might write:

```text
lib/todo_app/todos.ex
lib/todo_app/todos/todo.ex
lib/todo_app_web/live/todo_live.ex
priv/repo/migrations/20260101000000_create_todos.exs
assets/js/app.js
```

With PhoenixHx, you may author some of those modules in Haxe:

```text
src_haxe/server/contexts/Todos.hx
src_haxe/server/schemas/Todo.hx
src_haxe/server/live/TodoLive.hx
src_haxe/server/migrations/CreateTodos.hx
src_shared/shared/liveview/TodoEvents.hx
src_haxe/client/hooks/TodoHook.hx
```

but the compiled app should still look like Phoenix:

```text
lib/todo_app/todos.ex
lib/todo_app/todos/todo.ex
lib/todo_app_web/live/todo_live.ex
priv/repo/migrations/20260101000000_create_todos.exs
assets/js/hx_app.js
```

The Haxe folders are for authoring and type checking. The Elixir folders are
what Phoenix, Mix, releases, and deployment use.

## Vanilla Phoenix Comparison

| Question | Vanilla Phoenix | PhoenixHx in-place mode |
| --- | --- | --- |
| Where do app modules live? | `lib/my_app/**`, `lib/my_app_web/**` | Same after compile |
| Who writes the source? | You write `.ex` / `.exs` directly | You write selected `.hx`; the compiler writes `.ex` / `.exs` |
| What does Mix compile? | Elixir files under `lib` | Generated Elixir files under `lib`, plus any handwritten Elixir |
| What runs in production? | BEAM bytecode from the Phoenix app | Same; Haxe is not a runtime dependency |
| What gets deployed? | The Phoenix app/release | The Phoenix app/release after Haxe-generated files are present |
| Can I keep normal Phoenix code? | Yes | Yes; mix handwritten Elixir and Haxe-generated modules deliberately |

The compiler should not invent a second Phoenix layout. PhoenixHx adds typed
authoring, macros, code generation, and shared front/server contracts; it should
not make the generated app feel alien to Phoenix developers.

## Current Status

This document is both a policy and a target architecture.

- Supported today: in-place Phoenix compilation into an existing/generated
  Phoenix project, including isolated helper namespaces such as
  `lib/my_app_hx/**` and app-native output such as `lib/my_app_web/**`.
- Supported today: Haxe-authored migrations emitted to
  `priv/repo/migrations/**`, Haxe-authored ExUnit emitted to
  `test/generated/**`, and Genes JS emitted into the normal Phoenix assets
  pipeline.
- Target direction: materialized Phoenix app mode under `build/phoenix/**` with
  manifest ownership and the same target-module/path mapper.
- Current debt: some examples, including the todo-app, still vendor
  framework/runtime support under top-level `lib/phoenix/**`, `lib/ecto/**`,
  or `lib/plug/**`. Treat that as migration debt toward a documented runtime
  dependency or explicit vendored-runtime output, not the model.

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

Compile in-place during development with the same tools you already use:

```bash
# Server-side Haxe -> Elixir
haxe build-server.hxml

# Browser Haxe -> JS, usually Genes
haxe build-client.hxml

# Phoenix/Mix compilation
mix compile

# Run the app
mix phx.server
```

In projects wired through Mix tasks, `mix compile` can invoke the Haxe compile
step first. In production builds, run the Haxe compile before `mix compile` or
before building the release.

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
mix deps.get
mix compile
mix test
```

Deploy the materialized app the same way you would deploy any Phoenix app: build
and release the generated Phoenix tree. Do not deploy `src_haxe/**` as runtime
code; it is source input to the build.

Until this mode is fully implemented, treat `build/phoenix` as the architecture
target for examples, scaffolds, CI artifacts, and dogfood apps rather than as a
guaranteed command-line feature.

## What To Deploy

Deploy the Phoenix application, not a separate Haxe runtime application.

For in-place mode, deploy the normal app root after generated files are present:

```text
mix.exs
config/
lib/
priv/
assets/
```

For materialized mode, deploy the materialized Phoenix root:

```text
build/phoenix/mix.exs
build/phoenix/config/
build/phoenix/lib/
build/phoenix/priv/
build/phoenix/assets/
```

Haxe, Reflaxe.Elixir, and Genes are build-time tools. They belong in the build
environment or dev/test dependencies. The running BEAM release should contain
compiled Elixir/Erlang code, static assets, config, and any documented runtime
support dependencies, just like a normal Phoenix release.

Typical release flow:

```bash
haxe build-server.hxml
haxe build-client.hxml
mix assets.deploy
mix compile
mix release
```

Projects can wrap this with Mix tasks or CI scripts, but the conceptual order is
the same: generate target files, let Phoenix compile/assets/release normally,
deploy the Phoenix release.

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

The mapping rule is target-module first. PhoenixHx should derive app-facing
modules from Phoenix annotations plus `-D app_name` / `-D app_web_name` whenever
it can: `@:liveview class TodoLive` targets `TodoAppWeb.TodoLive`,
`@:controller class SessionController` targets `TodoAppWeb.SessionController`,
and `@:schema class Todo` targets `TodoApp.Todo`. `@:native("Exact.Module")`
remains the low-level escape hatch for externs and unusual interop, not the
default app-authoring API. Haxe packages are an authoring aid, not the last word
on app-facing Elixir layout.

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

The compiler supports `@:native("Target.Module")` for exact interop, but
PhoenixHx-owned app modules should prefer derived target names. Any remaining
string module target should be either a true extern boundary or a documented
temporary gap where no typed PhoenixHx marker exists yet.

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

- `@:native("TodoApp.SomeModule")`: exact interop escape hatch for externs or
  unusual modules that cannot yet be derived from PhoenixHx metadata.
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

The todo-app server build now avoids app-facing modules under top-level
`lib/shared/**` and `lib/server/**`; shared Haxe contracts that need runtime
modules are emitted under `TodoApp.*` / `TodoAppWeb.*`. Tracked example debt now
mainly lives in vendored support modules under top-level `lib/phoenix/**`,
`lib/ecto/**`, and `lib/plug/**`, including in the todo-app. If another example
emits those paths, or top-level `lib/shared/**` / `lib/server/**`, treat that as
migration debt, not as the desired architecture.

New app-facing output should avoid:

```text
lib/shared/**
lib/server/**
lib/client/**
lib/phoenix/**
lib/ecto/**
lib/plug/**
```

Allowlist only documented runtime support namespaces. A follow-up CI guard
should first account for the current vendored-runtime baseline, then fail on
new unowned app-facing leakage into those paths.

## Tests To Add

The implementation should be protected at these layers:

- Snapshot tests for module and path together: application, router, endpoint,
  LiveView, controller, schema, native enum, generated companion, and migration.
- Negative layout guards for forbidden app-facing paths.
- Todo-app WAE/runtime checks that assert no app-facing `lib/shared/**` or
  `lib/server/**` remains, and no new unallowlisted runtime support appears
  under `lib/phoenix/**`, `lib/ecto/**`, or `lib/plug/**` beyond the current
  vendored-runtime baseline.
- Materialized app tests that generate into a temporary `build/phoenix`, then
  run `mix compile --warnings-as-errors` and `mix test`.
- Ownership tests for first write, manifest-owned rewrite, unowned collision,
  generated-header adoption, stale cleanup, force, and path traversal rejection.
- Live Event Protocol tests proving private one-LiveView protocols emit no
  public companion module unless reused or explicitly requested.

The key invariant is simple: both workflow modes must use the same target module
and path mapper. Mode only decides where the Phoenix app tree is written.
