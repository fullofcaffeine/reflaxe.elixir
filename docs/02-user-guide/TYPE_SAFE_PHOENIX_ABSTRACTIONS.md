# Type-Safe Phoenix Abstractions

Reflaxe.Elixir provides a small set of Phoenix-focused types that keep your **application code typed**, while still generating **idiomatic Phoenix** at runtime.

This document covers the practical surfaces you’ll use most often:
- `phoenix.Phoenix.Socket<TAssigns>` (default callback + assign surface) and `phoenix.LiveSocket<TAssigns>` (optional wrapper)
- `phoenix.types.Assigns<T>`
- `phoenix.types.Flash.FlashMap`
- Experimental typed LiveView hook event protocols

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

## Typed LiveView Hook Events (Experimental)

Phoenix LiveView's vanilla event model is still the runtime contract:
browser hooks call `pushEvent`, and LiveViews receive
`handle_event(event, params, socket)`. PhoenixHx keeps that model visible. The
typed protocol layer is an opt-in macro surface for cases where both sides of a
hook/server boundary are authored in Haxe.

Call this feature **PhoenixHx Live Event Protocols**. It is "tRPC-like" only in
the narrow sense that one shared typed declaration generates helpers for both
ends of the boundary. It is not a new RPC runtime, and v1 does not replace
Phoenix's `handle_event/3`.

Use the direct PhoenixHx path for simple events:

```haxe
class CopyToClipboardHook {
  public static function mounted(hook:HookContext):Void {
    var message = hook.el.getAttribute("data-copied-message");
    if (message == null || message == "") {
      message = "Copied.";
    }

    if (hook.pushEvent != null) {
      hook.pushEvent("clipboard_copied", {message: message});
    }
  }
}
```

```haxe
public static function handleEvent(
  event:String,
  params:Term,
  socket:Socket<ProfileLiveAssigns>
):HandleEventResult<ProfileLiveAssigns> {
  return switch (event) {
    case "clipboard_copied":
      var message = Params.getStringDefault(params, "message", "Copied.");
      NoReply(LiveView.putFlash(socket, FlashType.Info, message));
    case _:
      NoReply(socket);
  };
}
```

This is the right shape for one-off events because it mirrors Phoenix directly.
The cost is that `"clipboard_copied"` and `"message"` now exist in two places:
the hook and the LiveView must be edited together, and the compiler cannot prove
that they still match.

Use a Live Event Protocol when the event is shared between Haxe-generated JS
hooks and Haxe-authored LiveViews:

```haxe
@:liveEventProtocol("HookEvents")
enum HookClientEvent {
  @:event("clipboard_copied")
  ClipboardCopied(message:String);

  @:event("ping")
  HookPing;
}

typedef HookEvents = LiveEventProtocolCompanion<HookClientEvent>;
```

For richer payloads, use a named typedef. PhoenixHx keeps the Haxe side as one
typed value and flattens the typedef fields into the wire payload:

```haxe
typedef ClipboardCopiedPayload = {
  var message:String;

  @:wire("copied_at")
  var copiedAt:String;
}

@:liveEventProtocol("HookEvents")
enum HookClientEvent {
  @:event("clipboard_copied")
  ClipboardCopied(payload:ClipboardCopiedPayload);
}
```

Client hook code then calls generated helpers. With the scalar constructor
above:

```haxe
HookEvents.pushClipboardCopied(hook, message);
```

The generated helper replaces both the raw event string and the ad hoc payload
object in app code. If the protocol changes, the hook callsite and the server
handler are checked by the Haxe compiler instead of drifting until a browser
event is clicked.

With the typedef payload version:

```haxe
HookEvents.pushClipboardCopied(hook, {
  message: "Copied.",
  copiedAt: "2026-06-28T16:00:00Z"
});
```

For domain values that are not native JSON/Phoenix payload scalars, put an
explicit codec on the typedef field:

```haxe
abstract ResourceId(Int) from Int to Int {}

typedef ResourceSelectedPayload = {
  @:codec(ResourceIdCodec.codec())
  var resourceId:ResourceId;

  var source:String;
}

@:liveEventProtocol("ResourceEvents")
enum ResourceEvent {
  @:event("resource_selected")
  ResourceSelected(payload:ResourceSelectedPayload);
}
```

The generated helpers keep `resourceId` typed as `ResourceId` in Haxe while
encoding it as a nested wire payload with `ResourceIdCodec` on both JS and
server paths.

Nullable payload fields must be explicit. Use an optional constructor argument
or `@:optional` typedef field when missing/null is part of the wire contract;
plain `Null<T>` without that marker is rejected so accidental nullable payloads
do not become invisible protocol behavior.

The LiveView remains Phoenix-shaped and explicitly calls the generated
dispatcher before falling back to ordinary events:

```haxe
@:liveEvents(HookClientEvent, "dispatchHookEvent")
class ProfileLive {
  public static function handleEvent(
    event:String,
    params:Term,
    socket:Socket<ProfileLiveAssigns>
  ):HandleEventResult<ProfileLiveAssigns> {
    var handled = dispatchHookEvent(event, params, socket);
    if (handled != null) {
      return handled;
    }

    return switch (event) {
      case EventName.SaveProfile:
        NoReply(saveProfile(params, socket));
      case _:
        NoReply(socket);
    };
  }

  static function handleClipboardCopied(
    message:String,
    socket:Socket<ProfileLiveAssigns>
  ):HandleEventResult<ProfileLiveAssigns> {
    return NoReply(LiveView.putFlash(socket, FlashType.Info, message));
  }
}
```

If the constructor uses `ClipboardCopied(payload:ClipboardCopiedPayload)`, the
handler convention becomes `handleClipboardCopied(payload, socket)` and the
payload is typed as `ClipboardCopiedPayload`.

Compared with vanilla Phoenix or direct PhoenixHx event handling, the protocol
path gives you one source of truth for event names and payload fields, generated
browser push helpers, generated server decoding, handler validation, and
manifest/hash drift checks across the JS and Elixir builds. The cost is an
explicit protocol enum plus an explicit dispatcher call.

Known protocol events with malformed required payloads are consumed safely by
the generated dispatcher as `NoReply(socket)`. Unknown event names still return
`null` so ordinary `handleEvent` fallback code can run. That distinction matters
when a raw fallback branch happens to share a protocol event name: bad protocol
payloads should not silently fall through as if they were unrelated Phoenix
events.

### Better Than Raw Phoenix When...

Live Event Protocols improve on raw Phoenix when an event contract crosses the
Haxe frontend/server boundary. In raw Phoenix, the browser side owns a string
event name and a map-shaped payload, while the LiveView separately owns another
copy of the same string and manual map decoding. PhoenixHx can do better there
because both sides are Haxe: one enum becomes the event registry, the hook push
API, the payload encoder, the server decoder, and the handler signature.

That changes the failure mode. With raw Phoenix, renaming
`"clipboard_copied"` or changing `"message"` to `"body"` can compile and fail
only when the browser pushes the event. With a Live Event Protocol, the hook
callsite, generated codec, and LiveView handler stop compiling until they agree.
That is the DevEx win: less repeated boundary code, safer refactors, and fewer
string/map synchronization bugs.

It is not automatically better than raw Phoenix. If the event is a one-off
template event, if the LiveView is Elixir-only, if the code is being kept close
to Phoenix docs during migration, or if there is no shared Haxe JS hook involved,
plain Phoenix or direct PhoenixHx is simpler. In those cases, use
`handleEvent(event, params, socket)` plus the typed `Params`/`WirePayload`
helpers where useful, and skip the protocol.

Use this decision guide:

| Scenario | Prefer | Why |
| --- | --- | --- |
| One-off `phx-click` or `phx-submit` handled only by the LiveView | Vanilla Phoenix or direct PhoenixHx | A protocol enum would add ceremony without removing much duplication. |
| Existing Elixir LiveView or code copied from Phoenix docs | Vanilla Phoenix | Keeping the original idiom is easier to debug and migrate. |
| Haxe LiveView receiving template events only | Direct PhoenixHx | You get typed boundary helpers without introducing a shared browser/server contract. |
| Haxe JS hook pushes an event to a Haxe LiveView | Live Event Protocol | The event name, payload shape, JS push helper, server decode, and handler signature come from one enum. |
| Reused hook protocol across multiple LiveViews | Live Event Protocol | Each LiveView binds explicitly with `@:liveEvents`, while the shared hook callsites stay typed. |
| Domain values such as `ResourceId`, `OrganizationSlug`, or non-primitive IDs | Live Event Protocol plus `@:codec(...)` | The Haxe API remains domain-typed while the wire shape stays explicit and snapshot-testable. |
| Hook push expects a typed reply | Direct PhoenixHx for now | Typed replies are a future Live Event Protocol extension, not part of v1. |

The feature is an improvement when Haxe owns both sides of the event boundary.
It is not always better than vanilla Phoenix. For a simple local event, the
plain Phoenix-shaped code is often the better DevEx; for cross-boundary Haxe
events, the protocol removes repeated string/payload bookkeeping and turns
rename/refactor mistakes into compile-time feedback.

Deep dive:

- [PhoenixHx Live Event Protocols](../08-roadmap/phoenixhx-live-event-protocols.md)
