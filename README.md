<p align="center">
  <img src="assets/haxir-logo.png" alt="Haxir logo" width="170" />
</p>

<h1 align="center">Reflaxe.Elixir</h1>

<p align="center">
  <strong>Typed at the source. At home on the BEAM.</strong><br />
  Add Haxe's type system to Phoenix, Ecto, and OTP—then ship ordinary Elixir through Mix.
</p>

<p align="center">
  <a href="https://github.com/fullofcaffeine/reflaxe.elixir/releases"><img alt="Release" src="https://img.shields.io/github/v/release/fullofcaffeine/reflaxe.elixir" /></a>
  <a href="https://github.com/fullofcaffeine/reflaxe.elixir/actions/workflows/ci.yml"><img alt="CI" src="https://github.com/fullofcaffeine/reflaxe.elixir/actions/workflows/ci.yml/badge.svg" /></a>
  <a href="https://haxe.org"><img alt="Haxe 4.3.7" src="https://img.shields.io/badge/Haxe-4.3.7-orange" /></a>
  <a href="https://elixir-lang.org"><img alt="Elixir 1.14+" src="https://img.shields.io/badge/Elixir-1.14%2B-purple" /></a>
  <a href="LICENSE"><img alt="GPL-3.0 license" src="https://img.shields.io/badge/license-GPL--3.0-2563eb" /></a>
</p>

<p align="center">
  <a href="docs/01-getting-started/WHY_REFLAXE_ELIXIR.md">Why Reflaxe.Elixir?</a> ·
  <a href="#ecto-queries-that-fail-before-mix">Typed Ecto</a> ·
  <a href="#try-it">Try it</a> ·
  <a href="#phoenixhx">PhoenixHx</a> ·
  <a href="docs/06-guides/PHOENIX_GRADUAL_ADOPTION.md">Gradual adoption</a> ·
  <a href="examples/README.md">Examples</a> ·
  <a href="docs/README.md">Docs</a>
</p>

**Reflaxe.Elixir** compiles typed Haxe into `.ex` source for the normal Mix and BEAM pipeline.
**PhoenixHx** adds typed Phoenix, LiveView, Ecto, and OTP authoring while Phoenix remains the runtime.

**For Elixir developers:** add static types, closed domain states, typed Phoenix boundaries, and
compile-time DSL checks one module or feature at a time. Generated and hand-written Elixir coexist
through ordinary module/function contracts.

**For Haxe developers:** use Haxe as the primary language for BEAM services and Phoenix applications
while keeping Mix, Hex packages, Elixir interop, OTP operations, and standard deployment. Functional,
Elixir-flavored Haxe maps closest to direct target code; covered portable and imperative forms keep
their behavior through explicit lowering. Haxe is a build dependency, not a second production VM.

> [!IMPORTANT]
> **Pre-1.0:** suitable for controlled pilots inside documented, pinned paths, not a general stability
> promise. Major 1 will remain blocked until every applicable public Haxe standard-library API is
> supported and tested. See [Production Readiness](docs/06-guides/PRODUCTION_READINESS.md), the
> [independent 1.0 review](docs/08-roadmap/1.0-production-readiness-review.md),
> [standard-library and package roadmap](docs/08-roadmap/stdlib-and-package-ecosystem.md),
> [exact OTP support boundary](docs/04-api-reference/OTP_SUPPORT_CONTRACT.md),
> [Known Limitations](docs/06-guides/KNOWN_LIMITATIONS.md), and
> [Versioning & Stability](docs/06-guides/VERSIONING_AND_STABILITY.md).

## Why It Exists

- **Type the risky boundaries.** Check assigns, params, routes, results, schemas, changesets, child
  specs, and existing Elixir calls before generated code reaches Mix.
- **Adopt in either direction.** Add one typed island to an Elixir app, or author a larger bounded
  context in Haxe while Phoenix and the BEAM remain the platform.
- **Generate beside handwritten Elixir safely.** Manifest-owned, content-hashed output rejects
  collisions and manual edits before publication; stale cleanup and interrupted builds recover
  without scanning or deleting unowned Phoenix files.
- **Keep the output recognizable.** Prefer normal modules, functions, maps, tuples, pattern matches,
  `Enum`, Phoenix, Ecto, and OTP calls whenever Haxe semantics can be preserved.
- **Build typed project DSLs.** Use Haxe macros, metadata, algebraic enums, and structural types to
  remove duplicated strings and invalid framework combinations.
- **Share selected behavior.** Compile a deliberately portable domain layer to Elixir and JavaScript;
  target-specific Phoenix and browser code stays at the edges.
- **Keep normal operations.** Format, test, inspect, profile, and deploy the resulting Elixir with
  ordinary Mix and BEAM tools.

```text
Haxe / HXX -> Reflaxe.Elixir + PhoenixHx -> ordinary .ex / ~H -> Mix -> BEAM
```

Reflaxe.Elixir has one compiler pipeline and two authoring styles: **Typed Elixir-first** favors
BEAM/Phoenix-native APIs and direct output; **portable stdlib-first** prioritizes cross-target Haxe
semantics. They are source-design choices, not separate backends. See
[Authoring Styles](docs/02-user-guide/AUTHORING_STYLES_PORTABLE_VS_ELIXIR_FIRST.md).

## See The Output

These are checked excerpts from executable examples. The links contain the complete imports, types,
build files, and canonical generated output.

### Ecto queries that fail before Mix

This real [`Todos` context](examples/17-railshx-to-phoenixhx-todo/src_haxe/phoenix_hx_todo_hx/contexts/Todos.hx)
queries a typed [`Todo` schema](examples/17-railshx-to-phoenixhx-todo/src_haxe/phoenix_hx_todo_hx/data/Todo.hx).
The lambda is ordinary Haxe, so the compiler knows which schema it is querying and which fields the
predicate may use:

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

It becomes an ordinary Ecto query with normal pins and a normal Repo call (line-wrapped here):

```elixir
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
```

There is no second query engine in production: Ecto executes the generated query. But mistakes stop
earlier. The checked negative fixture deliberately writes:

```haxe
var query = TypedQuery.from(User);
var value = 123;
var q2 = query.where(user -> user.noSuchField == value);
```

and Haxe rejects it with `Field "noSuchField" does not exist in User`. Typed field and association
selectors extend the same idea to changesets, preloads, and joins, while generating normal atoms such
as `:email` and `:posts`. See the [negative fixture](test/snapshot/negative/typed_query_invalid_field/Main.hx),
the exact [generated context](examples/17-railshx-to-phoenixhx-todo/lib/phoenix_hx_todo/todos.ex), and the
[Ecto integration guide](docs/07-patterns/ECTO_INTEGRATION_PATTERNS.md).

### Elixir-first Haxe stays direct

[`SearchDomain.hx`](examples/13-elixir-first-liveview/src_haxe/live/SearchDomain.hx) uses typed
Elixir APIs and Haxe's typed `Result`:

```haxe
var normalized = ElixirString.trim(query);
var needle = ElixirString.downcase(normalized);
var visible = Enum.filter(catalog,
  item -> item != null &&
    ElixirString.contains(ElixirString.downcase(item), needle));
return Ok({query: normalized, visible: visible, result_count: visible.length});
```

```elixir
normalized = String.trim(query)
needle = String.downcase(normalized)

visible =
  Enum.filter(catalog, fn item ->
    not Kernel.is_nil(item) and String.contains?(String.downcase(item), needle)
  end)

{:ok, %{query: normalized, visible: visible, result_count: length(visible)}}
```

The externs become direct `String` and `Enum` calls, `Result` becomes `{:ok, value}` / `{:error, reason}`,
and the structural record becomes a map. See the
[reviewed output](test/quality/handwritten-output/generated/elixir-first-liveview/elixir_first_liveview/search_domain.ex).

### Imperative Haxe can lower functionally

This portable [`Transcript.render`](examples/16-portable-chat-domain/src_haxe/shared/chat/Transcript.hx)
uses a normal Haxe loop and `Array.push`:

```haxe
var lines = [];
for (message in history) {
  lines.push(MessageRules.format(message));
}
return lines;
```

The compiler proves that it is a fresh, ordered, one-value projection and emits:

```elixir
Enum.map(history, fn message ->
  PortableChatDomain.MessageRules.format(message)
end)
```

More complex mutation currently uses explicit immutable rebinding or reducers.
That preserves many local flows, but it does not make another alias observe an
ordinary Haxe object/collection mutation; shared-reference semantics remain a
[known pre-1.0 gap](docs/06-guides/KNOWN_LIMITATIONS.md). See
[Imperative to Functional Lowering](docs/02-user-guide/IMPERATIVE_TO_FUNCTIONAL_LOWERING.md) and the
[reviewed output](test/quality/handwritten-output/generated/portable-chat-domain/portable_chat_domain/transcript.ex).
The same target-neutral [`MessageRules`](examples/16-portable-chat-domain/src_haxe/shared/chat/MessageRules.hx)
is executed through Haxe-authored ExUnit on the BEAM and through the generated JavaScript in Node, so
validation behavior is shared without pulling Phoenix or JavaScript APIs into the domain layer.

## PhoenixHx

PhoenixHx is a build-time typed authoring layer, not a replacement web runtime. LiveViews use typed
`Socket<TAssigns>` and callback result types. Haxe parses inline HXX and type-checks assigns and
embedded expressions before emitting Phoenix `~H`; strict options also check registered components,
slots, hooks, and events. This excerpt is from the checked
[`SearchLive`](examples/13-elixir-first-liveview/src_haxe/live/SearchLive.hx):

```haxe
return <p data-testid="result-count">
  ${assigns.result_count} result(s)
</p>;
```

```elixir
~H"""
<p data-testid="result-count">
  {@result_count} result(s)
</p>
"""
```

Phoenix still compiles the resulting HEEx, and there is no separate template runtime. The same
example's typed [`final routes` DSL](examples/13-elixir-first-liveview/src_haxe/ElixirFirstLiveviewRouter.hx)
emits normal `Phoenix.Router` pipelines, scopes, and `live_session` declarations. See the tracked
Haxe-first router [source](examples/15-phoenix-chat-haxe-first/src_haxe/PhoenixChatRouter.hx) and
[generated output](examples/15-phoenix-chat-haxe-first/lib/phoenix_chat_web/router.ex),
[Phoenix Integration](docs/02-user-guide/PHOENIX_INTEGRATION.md), and the complete
[`SearchLive` output](test/quality/handwritten-output/generated/elixir-first-liveview/elixir_first_liveview_web/search_live.ex).

Repeated client/server events can be one checked contract instead of three matching strings. This
real shared declaration generates the event name companion, requires the LiveView binding, and owns
the `id` decoder:

```haxe
@:liveEventProtocol
enum TodoEvent {
  @:templateEvent
  ToggleTodo(id:Int);
}

@:liveEvents(TodoEvent)
class AppLive {}
```

The inline template uses `phx-click=${TodoEvents.ToggleTodoEvent}` and the emitted HEEx uses
`phx-click={"toggle_todo"}`. Phoenix still receives a normal `handle_event/3` boundary; PhoenixHx
generates the string-to-`Int` decoding and rejects missing handlers or incompatible template payloads
at Haxe compile time. See the complete [event contract](examples/17-railshx-to-phoenixhx-todo/src_shared/shared/liveview/TodoEvents.hx),
[LiveView source](examples/17-railshx-to-phoenixhx-todo/src_haxe/phoenix_hx_todo_hx/live/AppLive.hx), and
[generated LiveView](examples/17-railshx-to-phoenixhx-todo/lib/phoenix_hx_todo_web/app_live.ex).

## One Type System Across the App

| Check in Haxe | What ships to the target |
| --- | --- |
| [`final routes`](examples/15-phoenix-chat-haxe-first/src_haxe/PhoenixChatRouter.hx) with typed plugs, sessions, LiveViews, and params | Normal `Phoenix.Router` pipelines, scopes, and routes in [`router.ex`](examples/15-phoenix-chat-haxe-first/lib/phoenix_chat_web/router.ex) |
| [`@:application` + typed child specs](examples/17-railshx-to-phoenixhx-todo/src_haxe/PhoenixHxTodo.hx) | An ordinary `Application` module and `Supervisor.start_link/2` child list in [`application.ex`](examples/17-railshx-to-phoenixhx-todo/lib/phoenix_hx_todo/application.ex); the [OTP contract](docs/04-api-reference/OTP_SUPPORT_CONTRACT.md) explains the tested boot boundary and restart/failure exclusions |
| [`@:exunit`, `ConnTest`, and `LiveViewTest`](examples/17-railshx-to-phoenixhx-todo/src_haxe/test/web/TodoPersistenceTest.hx) | Normal ExUnit integration tests in [`todo_persistence_test.exs`](examples/17-railshx-to-phoenixhx-todo/test/generated/phoenix_hx_todo/todo_persistence_test.exs) |
| [Closed domain enums and portable rules](examples/16-portable-chat-domain/src_haxe/shared/chat/MessageRules.hx) | The same selected behavior compiled and executed as [Elixir](test/quality/handwritten-output/generated/portable-chat-domain/portable_chat_domain/message_rules.ex) and [JavaScript](examples/16-portable-chat-domain/README.md#run) |

The benefit is not new runtime machinery. It is one typed authoring vocabulary across the risky
boundaries, followed by framework code that Elixir teams can still format, inspect, test, and operate.

## Native First, Compatibility When Required

The compiler tries, in order: proven native lowering such as `Int` operators and `Enum.map`; direct
typed Elixir/Phoenix/Ecto/OTP APIs; Haxe stdlib overrides backed by `String`, `Map`, `:crypto`, and
other BEAM primitives; then explicit compatibility lowering or small helpers when semantics differ.
Special floats, unresolved numeric values, and arbitrary Haxe `throw` values are examples of the last case.

Correctness wins when source and target semantics differ. Today the two core helper modules are kept
in generated builds even when a particular application has no call site for one of them; generated
calls remain selective, but module inclusion is not yet fully demand-driven. This is tracked footprint
work, not an application mode. Normal applications do not use `-D reflaxe_runtime`; see
[`reflaxe_runtime` And Generated Helpers](docs/02-user-guide/REFLAXE_RUNTIME_EXPLAINED.md).

## Start Where It Pays

| Goal | Start here |
| --- | --- |
| Compile the smallest Haxe modules | [`01-simple-modules`](examples/01-simple-modules/) |
| Bring a Haxe service or library to the BEAM | [`02-mix-project`](examples/02-mix-project/) |
| Add one feature to an existing Phoenix app | [Gradual Adoption Tutorial](docs/06-guides/PHOENIX_GRADUAL_ADOPTION_TUTORIAL.md) |
| Author typed LiveViews or call hand-written Elixir | [`13-elixir-first-liveview`](examples/13-elixir-first-liveview/) |
| See a complete typed Phoenix/Ecto vertical slice | [`17-railshx-to-phoenixhx-todo`](examples/17-railshx-to-phoenixhx-todo/) |
| Share selected browser/server domain logic | [`16-portable-chat-domain`](examples/16-portable-chat-domain/) |
| Explore the full reference app | [`todo-app`](examples/todo-app/) |
| Install a verified release package | [Installation](docs/01-getting-started/installation.md) |

No all-at-once rewrite is required.

## Reflaxe.Elixir And Gleam

Reflaxe.Elixir fits best when generated Elixir, Phoenix integration, gradual adoption, Haxe macros,
or existing Haxe/JavaScript sharing matter. Gleam favors a smaller immutable language and mature 1.x
ecosystem. Read the [honest comparison](docs/01-getting-started/WHY_REFLAXE_ELIXIR.md#reflaxeelixir-and-gleam).

## Try It

```bash
git clone https://github.com/fullofcaffeine/reflaxe.elixir.git
cd reflaxe.elixir
npm install
npm run test:quick
```

For application use, install and checksum a pinned release ZIP rather than depending on a source
checkout. Continue with [Installation](docs/01-getting-started/installation.md) and
[Start Here](docs/01-getting-started/START_HERE.md).

## Evidence And Maturity

CI covers full codegen snapshots and negative cases, Haxe-authored ExUnit semantics, selected upstream
stdlib fixtures, strict generated-Elixir compilation, runtime examples, source/package parity,
reproducible release artifacts, and Phoenix browser smoke.

Those tests prove the features listed as supported; they do not guarantee that every Haxe program
works yet. The loop and nested-comprehension bugs found during the 1.0 review are fixed. Mix now
rebuilds when any tracked Haxe input changes, and the compiler refuses to overwrite or delete a file
unless it can verify that it generated the file. The tested OTP feature set is deliberately small
and clearly listed. Callback functions written directly inside `Result` branches also have source
and runtime tests. Before the project can promise 1.0 stability, it still needs an exact list of
supported APIs and versions, a qualified licensing decision, and one unchanged proposed release
tested in independent projects for a defined period.

## Explore

| Topic | Guide |
| --- | --- |
| Product thesis and tradeoffs | [Why Reflaxe.Elixir?](docs/01-getting-started/WHY_REFLAXE_ELIXIR.md) |
| Setup and first application | [Start Here](docs/01-getting-started/START_HERE.md) |
| Elixir-friendly Haxe | [Writing Idiomatic Haxe](docs/02-user-guide/WRITING_IDIOMATIC_HAXE_FOR_ELIXIR.md) |
| Portable vs Elixir-first source design | [Authoring Styles](docs/02-user-guide/AUTHORING_STYLES_PORTABLE_VS_ELIXIR_FIRST.md) |
| Native lowering and compatibility helpers | [`reflaxe_runtime` And Generated Helpers](docs/02-user-guide/REFLAXE_RUNTIME_EXPLAINED.md) |
| Runtime-tested OTP operations and exclusions | [OTP Support Contract](docs/04-api-reference/OTP_SUPPORT_CONTRACT.md) |
| Phoenix, LiveView, Ecto, and API references | [Documentation Index](docs/README.md) |
| Supported versions and sharp edges | [Support Matrix](docs/06-guides/SUPPORT_MATRIX.md) |
| Contributor architecture and tests | [Contributing](docs/10-contributing/contributing.md) |

## Development

```bash
npm test
```

Compiler changes must preserve source/package behavior, runtime semantics, generated-output quality,
examples, and browser QA. See [Testing Infrastructure](docs/03-compiler-development/TESTING_INFRASTRUCTURE.md).

## License

[GPL-3.0](LICENSE). Generated applications can include support code from this repository; review
[Licensing & Distribution](docs/06-guides/LICENSING_AND_DISTRIBUTION.md) before commercial distribution.
