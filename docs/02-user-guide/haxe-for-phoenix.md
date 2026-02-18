# Haxe for Phoenix (Reflaxe.Elixir)

Phoenix is already a highly productive framework. Reflaxe.Elixir lets you keep Phoenix’s runtime and conventions while writing the application logic in Haxe with compile-time types and IDE tooling.

This page focuses on what exists in Reflaxe.Elixir **today** (v1.x): how to build Phoenix apps in Haxe, and how to adopt it gradually in an existing Elixir codebase.

## Start Here

- **New Phoenix app (recommended)**: use the project generator and follow the generated `README.md`.
- **Existing Phoenix app**: follow `docs/06-guides/PHOENIX_GRADUAL_ADOPTION.md`.
- **Working examples**: start with `examples/todo-app/README.md`, then browse `examples/*/README.md`.

## What You Get (Today)

### 1) Type-safe LiveView state (assigns)

In Elixir, LiveView state lives in `socket.assigns` and is keyed by atoms. In Haxe, you model assigns as a `typedef` and update them directly on `Socket<TAssigns>`.

Default assign paths:

- `assign(_.field, value)` for concise single-field updates
- `assign({ ... })` for Phoenix-style bulk assigns (`assign/2`)

```haxe
import elixir.types.Term;
import phoenix.Phoenix.HandleEventResult;
import phoenix.Phoenix.MountResult;
import phoenix.Phoenix.Socket;

typedef CounterAssigns = { count: Int };

@:native("MyAppWeb.CounterLive")
@:liveview
class CounterLive {
  public static function mount(params: Term, session: Term, socket: Socket<CounterAssigns>): MountResult<CounterAssigns> {
    return Ok(socket.assign(_.count, 0));
  }

  @:native("handle_event")
  public static function handle_event(event: String, params: Term, socket: Socket<CounterAssigns>): HandleEventResult<CounterAssigns> {
    return switch (event) {
      case "increment":
        var nextCount = socket.assigns.count + 1;
        NoReply(socket.assign(_.count, nextCount));
      case _:
        NoReply(socket);
    }
  }
}
```

Notes:
- `_.count` is a typed field selector consumed at compile time by `socket.assign`.
- `params` and `session` do not need leading `_` in Haxe. When unused, generated Elixir still emits `_params` / `_session`.
- `LiveSocket<TAssigns>` is still available as an explicit wrapper when you want pipe-style chaining or helper signatures that use `LiveSocket`.

Bulk assign example (Phoenix-style):

```haxe
socket = socket.assign({
  count: 0,
  search_query: "",
  sort_by: "created"
});
```

Optional typed-key path (no `@:build` required):

```haxe
import phoenix.AssignKeys;

typedef CounterAssigns = { count: Int };

var keys = AssignKeys.of(CounterAssigns);

socket = socket.assignKey(keys.count, 0);
```

Use this only if you explicitly want key-token APIs (`assignKey`/`updateKey`) and slightly more explicit call sites.
For most application code, `assign(_.field, value)` and `assign({ ... })` are the intended defaults.

Quick decision:
- Choose default assign style when you want the shortest Phoenix-like authoring flow.
- Choose typed-key style when shared helpers/APIs benefit from explicit key tokens in function signatures.

Technical + behavior details:

- `docs/04-api-reference/LIVE_SOCKET_ASSIGN_API.md`

### 2) HEEx templates from Haxe via HXX

HXX lets you author HEEx-like templates in Haxe and compile them to standard Phoenix `~H""" ... """` templates.

See:
- `examples/todo-app/README.md`
- `std/phoenix/types/HXXTypes.hx`

### 3) Ecto schemas + changesets with typed Haxe

Reflaxe.Elixir provides Ecto externs and compiler support for generating idiomatic schemas and changesets.

```haxe
import ecto.Changeset;

typedef UserParams = {
  ?name: String,
  ?email: String
}

@:native("MyApp.Accounts.User")
@:schema("users")
@:timestamps
@:changeset(["name", "email"], ["name", "email"])
class User {
  @:field @:primary_key public var id: Int;
  @:field public var name: String;
  @:field public var email: String;
}
```

No manual `extern` is needed: `@:schema` auto-injects a typed
`changeset<Params>(schema, params): Changeset<Schema, Params>` declaration.
If you intentionally keep an explicit declaration for compatibility, it is still supported.

Compiles to:

```elixir
defmodule MyApp.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :name, :string
    field :email, :string
    timestamps()
  end

  def changeset(user, params) do
    user
    |> cast(params, [:name, :email])
    |> validate_required([:name, :email])
  end
end
```

See:
- `docs/02-user-guide/ECTO_INTEGRATION_PATTERNS.md`
- `examples/04-ecto-migrations/README.md`

### 4) Phoenix router + controllers from annotations

Reflaxe.Elixir can generate Phoenix controllers and `router.ex` from Haxe modules annotated with Phoenix-specific metadata.

See:
- `examples/09-phoenix-router/README.md`
- `docs/04-api-reference/ANNOTATIONS.md`

### 5) Atom-tagged tuples as typed Haxe enums

Common Elixir idioms like `{:ok, value}` / `{:error, reason}` and LiveView callback tuples are represented as typed Haxe enums that compile to atom-tagged tuples.

See:
- `std/elixir/types/Result.hx`
- `std/phoenix/Phoenix.hx` (`MountResult`, `HandleEventResult`, `HandleInfoResult`)

## Gradual Adoption Strategy

The recommended adoption strategy is:

1. Keep your existing Phoenix app structure (Endpoint, Router, Controllers, LiveViews).
2. Compile selected Haxe modules into `lib/` (or a dedicated namespace under `lib/`).
3. Route requests/LiveViews to the Haxe-compiled modules one piece at a time.

Follow `docs/06-guides/PHOENIX_GRADUAL_ADOPTION.md` for the step-by-step flow and recommended folder layout.

## Testing & Verification

- Repo-wide tests: run `npm test` from repo root.
- Todo-app end-to-end build + boot: use the QA sentinel (`npm run qa:sentinel`) and keep it non-blocking (see repo root `AGENTS.md`).
- Browser smoke tests: Playwright lives in `examples/todo-app/e2e/`.

## Where to Look Next

- `docs/01-getting-started/installation.md`
- `docs/01-getting-started/development-workflow.md`
- `docs/04-api-reference/ANNOTATIONS.md`
- `docs/07-patterns/`
