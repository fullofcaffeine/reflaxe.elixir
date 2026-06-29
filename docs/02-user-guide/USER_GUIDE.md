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
- Step-by-step gradual adoption tutorial: `docs/06-guides/PHOENIX_GRADUAL_ADOPTION_TUTORIAL.md`

Phoenix integration overview: `docs/02-user-guide/PHOENIX_INTEGRATION.md`.

Chat walkthroughs for both adoption styles:
- Hybrid (gradual): `docs/06-guides/PHOENIX_CHAT_TUTORIAL.md`
- Haxe-first server: `docs/06-guides/PHOENIX_CHAT_TUTORIAL_HAXE_FIRST.md`

## Choose an Authoring Profile

You can build production Phoenix apps with either profile today:

- Portable stdlib-first (cross-target domain emphasis)
- Typed Elixir-first (BEAM/Phoenix extern emphasis)

Both profiles compile through the same compiler pipeline and both aim to emit idiomatic Elixir. The difference is what wins when portability and target-native shape conflict: portable preserves Haxe semantics first; Elixir-first prioritizes BEAM/Phoenix/Ecto/OTP-native source shapes.

This is a source-authoring choice, not a separate backend mode. `metal` is not an application profile in Reflaxe.Elixir; it is a local HXX/HEEx escape hatch.

Start here:

- `docs/02-user-guide/AUTHORING_STYLES_PORTABLE_VS_ELIXIR_FIRST.md`
- `docs/04-api-reference/STANDARD_LIBRARY_HANDLING.md`
- `examples/13-elixir-first-liveview/README.md`

## Calling Existing Elixir Modules

If some modules stay intentionally pure Elixir, use typed extern boundaries from Haxe (and wrappers only when they remove repeated boundary work).

Start here:

- `docs/02-user-guide/INTEROP_WITH_EXISTING_ELIXIR.md`
- `docs/06-guides/ADDING_ELIXIR_LIBS_FROM_HAXE.md`

## Core Concepts

### You don’t write `{:ok, ...}` in Haxe

Elixir idioms like `{:ok, value}` / `{:error, reason}` are represented by typed Haxe enums that compile to atom-tagged tuples.

- Generic `{:ok, value}` / `{:error, reason}`: `haxe.functional.Result` (preferred; marked Elixir-idiomatic by `reflaxe.elixir.CompilerInit.Start()`)
- LiveView callback tuples (`{:ok, socket}`, `{:noreply, socket}`): `std/phoenix/Phoenix.hx`
- Atoms: `std/elixir/types/Atom.hx`
- Opaque Phoenix/Ecto/interop terms: `elixir.types.Term`, decoded near the boundary with `elixir.types.TermDecoder`

Example (generic result):

```haxe
import haxe.functional.Result;

function parseIntSafe(s: String): Result<Int, String> {
  var n = Std.parseInt(s);
  return n == null ? Result.Error("not an int") : Result.Ok(n);
}
```

### LiveView state is a typed `typedef`

LiveView state lives in assigns. In Haxe you model assigns as a `typedef`, then update assigns directly on `Socket<TAssigns>`.

Use this quick rule:

- shortest single update: `assign(_.field, value)`
- Phoenix-style bulk update: `assign({ ... })`
- optional typed-key mode: `assignKey(keys.field, value)`

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

  public static function handleEvent(event: String, params: Term, socket: Socket<CounterAssigns>): HandleEventResult<CounterAssigns> {
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
- `_.count` is a compile-time field selector for typed assigns updates.
- You can keep Haxe argument names plain (`params`, `session`). The compiler adds Elixir-style `_` prefixes when those arguments are unused.
- `LiveSocket<TAssigns>` is still available as an explicit wrapper when you want wrapper-specific helper signatures.
- `assignKey(...)` is optional; preferred setup is `var keys = phoenix.AssignKeys.of(MyAssigns)`.
- For full API behavior details (including macro dispatch and typed keys), see `docs/04-api-reference/LIVE_SOCKET_ASSIGN_API.md`.

Compiles to:

```elixir
defmodule CounterLive do
  use Phoenix.LiveView

  def mount(_params, _session, socket), do: {:ok, assign(socket, :count, 0)}

  def handle_event("increment", _params, socket) do
    next_count = socket.assigns.count + 1
    {:noreply, assign(socket, :count, next_count)}
  end

  def handle_event(_, _params, socket), do: {:noreply, socket}
end
```

See also: `docs/02-user-guide/haxe-for-phoenix.md`.

### HEEx templates from Haxe (HXX)

HXX compiles Haxe-authored templates into standard `~H""" ... """` output.

Start here:
- `examples/todo-app/README.md`
- `std/phoenix/types/HXXTypes.hx`
- `docs/02-user-guide/HXX_SYNTAX_AND_COMPARISON.md`

Recommended strict profile for new Phoenix apps (defaults remain permissive for adoption):
- `-D hxx_strict_phx_hook`
- `-D hxx_strict_phx_events`
- `-D hxx_strict_phx_event_payloads` when using Live Event Protocol template
  events and you want extra `phx-value-*` keys rejected
- `-D hxx_strict_components`
- `-D hxx_strict_slots`
- `-D hxx_strict_attr_values`

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
