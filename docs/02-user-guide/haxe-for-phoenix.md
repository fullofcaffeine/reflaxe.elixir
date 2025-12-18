# Haxe for Phoenix (Reflaxe.Elixir)

Phoenix is already a highly productive framework. Reflaxe.Elixir lets you keep Phoenix’s runtime and conventions while writing the application logic in Haxe with compile-time types and IDE tooling.

This page focuses on what exists in Reflaxe.Elixir **today** (v1.x): how to build Phoenix apps in Haxe, and how to adopt it gradually in an existing Elixir codebase.

## Start Here

- **New Phoenix app (recommended)**: use the project generator and follow the generated `README.md`.
- **Existing Phoenix app**: follow `docs/06-guides/PHOENIX_GRADUAL_ADOPTION.md`.
- **Working examples**: start with `examples/todo-app/README.md`, then browse `examples/*/README.md`.

## What You Get (Today)

### 1) Type-safe LiveView state (assigns)

In Elixir, LiveView state lives in `socket.assigns` and is keyed by atoms. In Haxe, you model assigns as a `typedef` and update them through `phoenix.LiveSocket`, which validates fields at compile time and emits atom keys in Elixir.

	```haxe
	import elixir.types.Term;
	import phoenix.LiveSocket;
	import phoenix.Phoenix.HandleEventResult;
	import phoenix.Phoenix.MountResult;
	import phoenix.Phoenix.Socket;

typedef CounterAssigns = { count: Int };

	@:native("MyAppWeb.CounterLive")
	@:liveview
	class CounterLive {
	  public static function mount(_params: Term, _session: Term, socket: Socket<CounterAssigns>): MountResult<CounterAssigns> {
	    var ls: LiveSocket<CounterAssigns> = socket;
	    return MountResult.Ok(ls.assign(_.count, 0));
	  }

	  @:native("handle_event")
	  public static function handle_event(event: String, _params: Term, socket: Socket<CounterAssigns>): HandleEventResult<CounterAssigns> {
	    var ls: LiveSocket<CounterAssigns> = socket;

    return switch (event) {
      case "increment":
        var nextCount = ls.assigns.count + 1;
        HandleEventResult.NoReply(ls.assign(_.count, nextCount));
      case _:
        HandleEventResult.NoReply(ls);
    }
  }
}
```

### 2) HEEx templates from Haxe via HXX

HXX lets you author HEEx-like templates in Haxe and compile them to standard Phoenix `~H""" ... """` templates.

See:
- `examples/todo-app/README.md`
- `std/phoenix/types/HXXTypes.hx`

### 3) Ecto schemas + changesets with typed Haxe

Reflaxe.Elixir provides Ecto externs and compiler support for generating idiomatic schemas and changesets.

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
