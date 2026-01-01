# Phoenix LiveView Patterns (Haxe→Elixir)

This document focuses on **patterns that match the current compiler + stdlib APIs**.

If you see older content using `@:event(...)`, `jsx(...)`, or custom return types (e.g. `LiveViewResult`), those were legacy experiments and are now archived under `docs/09-history/archive/`.

## Core Idea: Keep Phoenix Idioms, Add Haxe Types

Reflaxe.Elixir generates idiomatic LiveView modules:
- Implement `mount/3`, `handle_event/3`, `handle_info/2`, and `render/1`.
- Return values stay Phoenix-native (`{:ok, socket}`, `{:noreply, socket}`, …) but are authored as typed Haxe enums (`MountResult.*`, `HandleEventResult.*`, …).
- Keep application code free of `untyped __elixir__(...)`. If a Phoenix helper is missing, add a typed extern/shim under `std/phoenix/**`.

## Pattern: Typed Assigns + `LiveSocket.assign`

Define assigns as a Haxe `typedef` and keep state updates typed end-to-end.

	```haxe
	import HXX;
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
	    var liveSocket: LiveSocket<CounterAssigns> = socket;
	    liveSocket = liveSocket.assign(_.count, 0);
	    return MountResult.Ok(liveSocket);
	  }

	  @:native("handle_event")
	  public static function handle_event(event: String, _params: Term, socket: Socket<CounterAssigns>): HandleEventResult<CounterAssigns> {
	    var liveSocket: LiveSocket<CounterAssigns> = socket;

    return switch (event) {
      case "increment":
        var nextCount = liveSocket.assigns.count + 1;
        HandleEventResult.NoReply(liveSocket.assign(_.count, nextCount));
      case _:
        HandleEventResult.NoReply(liveSocket);
    }
  }

  public static function render(assigns: CounterAssigns): String {
    return HXX.hxx('
      <div class="counter">
        <h1>${assigns.count}</h1>
        <button phx-click="increment">+</button>
      </div>
    ');
  }
}
```

Notes:
- `event` and `_params` are runtime values from Phoenix.
- Typed assigns give you compile-time validation in both LiveView logic and templates.

## Pattern: Decode Event Params Once (Boundary → Typed)

LiveView event params arrive as an untyped map. Prefer converting **once** at the boundary (per event), then operating on typed values.

```haxe
typedef CreateTodoParams = {
  title: String,
  ?description: String
};

import elixir.ElixirMap;
import elixir.types.Term;

class Params {
  public static function getString(params: Term, key: String): Null<String> {
    var value: Term = ElixirMap.get(params, key);
    return (value == null) ? null : Std.string(value);
  }
}
```

Then:

```haxe
case "create_todo":
  var title = Params.getString(_params, "title");
  if (title == null) return HandleEventResult.NoReply(liveSocket);
  // ...call typed domain code...
```

This keeps the untyped surface contained to a small parsing helper.

## Pattern: Live Updates Across Browser Sessions (PubSub)

LiveView processes do not automatically “sync state” between browser sessions. If you want updates to propagate to other connected users/tabs, you must:
1) broadcast an event (usually via `Phoenix.PubSub`), and
2) handle it in `handle_info/2` to update assigns.

The stdlib includes PubSub externs and helpers under `std/phoenix/**` (see `phoenix.Phoenix.PubSub` and `phoenix.SafePubSub`).

For a full working reference, see:
- `examples/todo-app/src_haxe/server/live/TodoLive.hx`

## Pattern: Client Hooks (Haxe → JS)

Hooks run in the browser. The todo-app authors hooks in Haxe, compiles them to JS, and attaches them via `window.Hooks`.

Reference implementation:
- `examples/todo-app/src_haxe/client/extern/Phoenix.hx` (hook interface)
- `examples/todo-app/src_haxe/client/hooks/` (hook implementations)
- `examples/todo-app/assets/js/app.js` (bootstrap that reads `window.Hooks`)

## Pattern: Typed `phx-hook` Names (Shared With Genes)

Hook names are stringly-typed in Phoenix by default (`phx-hook="MyHook"`). To make refactors safe and keep
server templates in sync with the client hook registry, define a single source of truth:

```haxe
@:phxHookNames
enum abstract HookName(String) from String to String {
  var ThemeToggle = "ThemeToggle";
  var CopyToClipboard = "CopyToClipboard";
}
```

Then:
- **Server (HXX/HEEx)**: `phx-hook=${HookName.ThemeToggle}`
- **Client (Genes/JS)**: use `HookName.ThemeToggle` as the key in your hooks map

When at least one `@:phxHookNames` registry exists in the project, the compiler lints literal hook usages
like `phx-hook="..."` and reports unknown names. Dynamic hook expressions (e.g. `phx-hook={@hook}`) are
intentionally not validated to keep false positives low.

## Anti-Pattern: `__elixir__()` in Application Code

Avoid `untyped __elixir__(...)` in application modules. If you need a missing Phoenix helper:
- add a typed extern/shim under `std/phoenix/**`, and
- reuse it across apps.
