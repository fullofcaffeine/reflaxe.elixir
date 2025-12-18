# Reflaxe.Elixir User Guide

Reflaxe.Elixir is a Haxe→Elixir compiler target (Reflaxe-based) that generates idiomatic Elixir suitable for real Phoenix/Ecto/OTP apps.

This guide is a “start here” map: it explains the core concepts and points you to the canonical docs and working examples.

## Getting Started

- Install + verify toolchains: `docs/01-getting-started/installation.md`
- Day-to-day workflow: `docs/01-getting-started/development-workflow.md`
- Try a real app: `examples/todo-app/README.md`

## Phoenix: New App vs Gradual Adoption

The Phoenix docs are split into two concrete paths:

- New Phoenix app in Haxe: `docs/06-guides/PHOENIX_NEW_APP.md`
- Add Haxe modules to an existing Phoenix app: `docs/06-guides/PHOENIX_GRADUAL_ADOPTION.md`

Phoenix integration overview: `docs/02-user-guide/PHOENIX_INTEGRATION.md`.

## Core Concepts

### You don’t write `{:ok, ...}` in Haxe

Elixir idioms like `{:ok, value}` / `{:error, reason}` are represented by typed Haxe enums that compile to atom-tagged tuples.

- Generic `{:ok, value}` / `{:error, reason}`: `std/elixir/types/Result.hx`
- LiveView callback tuples (`{:ok, socket}`, `{:noreply, socket}`): `std/phoenix/Phoenix.hx`
- Atoms: `std/elixir/types/Atom.hx`

Example (generic result):

```haxe
import elixir.types.Result;

function parseIntSafe(s: String): Result<Int, String> {
  var n = Std.parseInt(s);
  return n == null ? Result.Error("not an int") : Result.Ok(n);
}
```

### LiveView state is a typed `typedef`

LiveView state lives in assigns. In Haxe you model assigns as a `typedef`, then use `phoenix.LiveSocket` to update assigns with compile-time field validation.

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

See also: `docs/02-user-guide/haxe-for-phoenix.md`.

### HEEx templates from Haxe (HXX)

HXX compiles Haxe-authored templates into standard `~H""" ... """` output.

Start here:
- `examples/todo-app/README.md`
- `std/phoenix/types/HXXTypes.hx`

### Ecto integration

Ecto docs:
- `docs/02-user-guide/ECTO_INTEGRATION_PATTERNS.md`
- `examples/04-ecto-migrations/README.md`

### Router + controllers

Router/controller example:
- `examples/09-phoenix-router/README.md`

Annotation reference (source-of-truth):
- `docs/04-api-reference/ANNOTATIONS.md`

## Mix Integration

Mix tasks (source-of-truth):
- `docs/04-api-reference/MIX_TASKS.md`

## Testing

Repo-wide:

- `npm test`
- `npm run test:examples`

Todo-app runtime verification (non-blocking sentinel; see repo root `AGENTS.md`):

- `npm run qa:sentinel`

## Deployment

Haxe is required at build time, not at runtime. Production checklist and Docker/mix release patterns:

- `docs/06-guides/PRODUCTION_DEPLOYMENT.md`
