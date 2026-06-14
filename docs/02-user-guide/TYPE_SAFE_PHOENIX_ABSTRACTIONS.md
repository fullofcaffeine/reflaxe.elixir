# Type-Safe Phoenix Abstractions

Reflaxe.Elixir provides a small set of Phoenix-focused types that keep your **application code typed**, while still generating **idiomatic Phoenix** at runtime.

This document covers the practical surfaces you’ll use most often:
- `phoenix.Phoenix.Socket<TAssigns>` (default callback + assign surface) and `phoenix.LiveSocket<TAssigns>` (optional wrapper)
- `phoenix.types.Assigns<T>`
- `phoenix.types.Flash.FlashMap`

## Typed Assigns (Recommended)

Define assigns as a Haxe `typedef` and use it everywhere:

```haxe
typedef CounterAssigns = {
  count: Int
};
```

In LiveView modules, take a typed socket and choose the assign shape that matches your goal:

- `assign(_.field, value)`: shortest single-field update
- `assign({ ... })`: Phoenix-style bulk assign
- `assignKey(keys.field, value)`: optional typed-key mode

Single-field example:

```haxe
import elixir.types.Term;
import phoenix.Phoenix.MountResult;
import phoenix.Phoenix.Socket;

@:liveview
class CounterLive {
  public static function mount(params: Term, session: Term, socket: Socket<CounterAssigns>): MountResult<CounterAssigns> {
    socket = socket.assign(_.count, 0);
    return Ok(socket);
  }
}
```

Notes:
- `_.count` is a typed field selector that the assign macro reads at compile time.
- Haxe callback arguments do not need `_` prefixes; unused ones are normalized to `_name` in generated Elixir.

Bulk assign example:

```haxe
socket = socket.assign({
  count: 0
});
```

Typed-key example:

```haxe
import phoenix.AssignKeys;

var keys = AssignKeys.of(CounterAssigns);

socket = socket.assignKey(keys.count, 0);
```

`AssignKeys.of(...)` is the recommended typed-key setup.
If you use `assign(_.field, value)` / `assign({ ... })`, no key setup is required.

Pros/cons at a glance:
- Default assign style (`assign(_.field, value)` / `assign({ ... })`): least code, best for most app code.
- Typed-key style (`assignKey(keys.field, value)`): more explicit key tokens and stronger key/value coupling in signatures.
- `LiveSocket<TAssigns>` is still available if you prefer explicit wrapper-style chaining in helpers.

Compiles to:

```elixir
defmodule CounterLive do
  use Phoenix.LiveView

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :count, 0)}
  end
end
```

Deep dive:

- `docs/04-api-reference/LIVE_SOCKET_ASSIGN_API.md`

In `render/1`, prefer a typed assigns parameter:

```haxe
public static function render(assigns: CounterAssigns): String {
  return <h1>${assigns.count}</h1>;
}
```

## `Assigns<T>` (Components / Template Helpers)

Some Phoenix helpers expose assigns as a map. The stdlib models that as `phoenix.types.Assigns<T>`.

Key behavior:
- `Assigns<T>` is a typed wrapper over Phoenix assigns.
- It supports typed field access as `T` (use your `typedef`).
	- It still supports term interop when needed (it’s a Phoenix runtime map).

Example in a function component:

```haxe
import phoenix.Component;
import phoenix.types.Assigns;

typedef ButtonAssigns = { label: String };

@:hxx_inline_markup
class MyComponents {
  public static function button(_ignored: Term): String {
    var assigns: Assigns<ButtonAssigns> = Component.assigns();
    return <button>${assigns.label}</button>;
  }
}
```

## Flash + Current User

Phoenix has a stable `flash` shape, so `Assigns<T>` exposes:
- `getFlash(): Null<phoenix.types.Flash.FlashMap>`

`current_user` is application-defined, so `Assigns<T>` exposes a typed generic getter:
- `getCurrentUser<TUser>(): Null<TUser>`

Prefer fully typing these via your assigns `typedef` when possible, but the helpers are useful for shared components/layouts.

## Avoid `__elixir__()` in Apps

Event params and assigns originate from a dynamic runtime world (Phoenix). Keep the untyped boundary small:
- decode once at module boundaries (`handle_event`, `handle_info`), then operate on typed domain code.

If you need a Phoenix helper that doesn’t exist yet, don’t use `untyped __elixir__()` in the app:
- add a typed extern/shim under `std/phoenix/**` and reuse it across apps.
