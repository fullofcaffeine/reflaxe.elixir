# PhoenixHx Live Event Protocols

Status: adopted v1 design plan, with model/manifest, generated companion
encode/decode, JS push helpers, first explicit LiveView dispatcher binding, and
todo-app hook protocol migration in place. Richer payload typedef/custom codec
support is not shipped.

PhoenixHx should provide an opt-in, framework-level macro layer for typed
LiveView events that cross the browser hook/server LiveView boundary.

The goal is not to replace Phoenix. The goal is to let Haxe-authored frontend
and backend code share one event contract, then generate the small pieces of
boundary code that are otherwise stringly and repetitive.

## Design Position

Adopt v1 as protocol-first, explicit-dispatch, and handler-validated.

- Developers declare a shared Haxe event protocol once.
- PhoenixHx generates event names, payload encoders/decoders, browser push
  helpers, and server dispatch helpers.
- LiveView modules keep a normal Phoenix-shaped `handleEvent(event, params,
  socket)` and explicitly call the generated dispatcher.
- No metadata means no generated behavior and no validation.
- Compiler defines may affect diagnostics, but must not silently switch runtime
  behavior or create a separate backend/profile.

This fits the authoring profile contract: direct Phoenix interop remains the
floor, while typed Haxe macros improve the authoring ceiling.

## v1 Source API

Prefer a shared enum protocol as the source of truth:

```haxe
package shared.liveview;

@:liveEventProtocol
enum ProfileHookEvent {
  @:event("clipboard_copied")
  ClipboardCopied(message:String);

  @:event("ping")
  Ping;
}
```

The macro should derive defaults:

- companion module: `ProfileHookEvents`
- dispatch method: `dispatchProfileHookEvent`
- handler names: `handleClipboardCopied`, `handlePing`

String overrides should remain available for interop or naming conflicts:

```haxe
@:liveEventProtocol("ProfileHookEvents")
enum ProfileHookEvent { ... }

@:liveEvents(ProfileHookEvent, "dispatchProfileHookEvent")
class ProfileLive { ... }
```

Bind a LiveView separately. The current implementation requires an explicit
dispatch helper name:

```haxe
@:liveEvents(ProfileHookEvent, "dispatchProfileHookEvent")
class ProfileLive {
  public static function handleEvent(
    event:String,
    params:Payload,
    socket:Socket<ProfileLiveAssigns>
  ):HandleEventResult<ProfileLiveAssigns> {
    var handled = dispatchProfileHookEvent(event, params, socket);
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

  static function handlePing(
    socket:Socket<ProfileLiveAssigns>
  ):HandleEventResult<ProfileLiveAssigns> {
    return NoReply(socket);
  }
}
```

The explicit dispatch call is intentional. It keeps the Phoenix callback visible
and makes fallback behavior obvious.

## Generated Surface

For the protocol above, PhoenixHx should generate a companion class:

```haxe
class ProfileHookEvents {
  public static inline var ClipboardCopiedEvent:String = "clipboard_copied";
  public static inline var PingEvent:String = "ping";

  public static function encode(event:ProfileHookEvent):EncodedEvent;
  public static function decode(eventName:String, payload:Payload):Null<ProfileHookEvent>;

  #if js
  public static function push(hook:HookContext, event:ProfileHookEvent):Void;
  public static function pushClipboardCopied(hook:HookContext, message:String):Void;
  public static function pushPing(hook:HookContext):Void;
  #end
}
```

Current implementation uses a generic-build typedef as the first companion
entrypoint while the final metadata-only naming flow is still being designed:

```haxe
typedef ProfileHookEvents = LiveEventProtocolCompanion<ProfileHookEvent>;
```

That typedef already exposes event constants plus `encode` and `decode` helpers
generated from the shared protocol model. On JS builds, it also exposes
`push(hook, event)` plus per-event helpers such as
`pushClipboardCopied(hook, message)`.

LiveView classes can opt into the first server binding with:

```haxe
@:liveview
@:liveEvents(ProfileHookEvent, "dispatchProfileHookEvent")
class ProfileLive { ... }
```

That binding validates the explicit dispatcher call in `handleEvent`, validates
matching handler names and return types, registers generated event names for HXX
`phx-*` checks, and generates a private helper in the LiveView module.

Server binding should generate a private dispatch helper in the LiveView module
or an equivalent helper with the same readable target shape:

```elixir
defp dispatch_profile_hook_event(event_name, params, socket) do
  cond do
    event_name == "clipboard_copied" ->
      message = Phoenix.Channels.WirePayload.get_string(params, "message")
      if is_nil(message), do: nil, else: handle_clipboard_copied(message, socket)

    event_name == "ping" ->
      handle_ping(socket)

    true ->
      nil
  end
end
```

Current dispatcher output returns `nil` both for unknown protocol events and for
known events whose required payload fields fail to decode. A later iteration may
split "unknown" from "known but invalid" if todo-app coverage shows that
fallback handling needs a tri-state result.

## Payload Rules

Support these first:

- empty constructors: `Ping`
- scalar constructor arguments: `ClipboardCopied(message:String)`
- named typedef payloads
- `String`, `Int`, `Bool`, `Float`
- `Array<String>` and `Array<Int>`
- `Null<T>` only for explicitly optional fields
- custom codecs through `@:codec(...)` after the direct built-ins are stable

Avoid these in v1 protocol declarations:

- `Dynamic`
- `Map<String, Dynamic>`
- `haxe.ds.Map`
- `Reflect.field` payload access
- raw `__elixir__`
- custom class instances without an explicit codec

Generate direct helper functions for the built-in payload types. Prefer clear
`WirePayload.getString/putString`, `getInt/putInt`, etc. over runtime codec
objects in the default path. The current manual todo-app `HookEvents` prototype
showed that direct helpers produce clearer Elixir than a generic codec value
when the compiler has to lower enum decoding.

## Diagnostics

Protocol diagnostics should catch:

- duplicate event names
- unsupported payload field types
- duplicate wire keys after name conversion
- `Dynamic` or unsafe map payloads
- invalid `@:event`, `@:wire`, or `@:codec` metadata

LiveView binding diagnostics should catch:

- missing handler method
- wrong handler argument list
- wrong handler return type
- duplicate handler bindings
- protocol binding without an explicit dispatcher call

Dispatcher-call validation should be a warning by default and an error under a
strict define such as:

```text
-D phoenixhx_live_events_strict
```

Current implementation note: dispatcher-call validation is a hard compile error
while the API is still experimental. Revisit this before documenting the feature
as stable.

JS and server builds run separately, so cross-build drift should be caught with
a deterministic protocol manifest/hash generated from the shared enum and
validated in snapshots or todo-app CI.

## Macro Architecture Notes

Tink Web is the closest Haxe macro reference for this work, but the lesson is
architectural rather than semantic. PhoenixHx should not import Tink Web's HTTP
router complexity; it should borrow the shape of the implementation:

- Normalize the declaration before emitting code. Build a small typed model such
  as `LiveEventCollection`, `LiveEventSignature`, `LiveEventPayload`, and
  `LiveEventField` from the protocol enum and LiveView metadata.
- Generate browser helpers and server dispatch helpers from the same model so
  the hook push path and LiveView receive path cannot drift.
- Keep the metadata grammar narrow and validated: `@:event(...)`,
  `@:wire(...)`, `@:codec(...)`, handler overrides, and nothing inferred from
  arbitrary handler bodies.
- Keep generated default payload code direct. Built-in field types should lower
  to readable `WirePayload` helpers, not a generic runtime codec object path.
- Prefer source-positioned macro diagnostics for duplicate event names, duplicate
  wire keys, unsupported types, invalid metadata, and missing handlers.
- Use warnings for inferential checks such as "does `handleEvent` call the
  dispatcher?", then escalate under `-D phoenixhx_live_events_strict`.

Implementation should evaluate whether the generated companion is best produced
through a `@:genericBuild` placeholder type or through `Context.defineType` from
the protocol metadata. The public API should stay stable either way. The
important constraints are deterministic type generation, deterministic manifest
hashes, and generated Elixir/JS that remains easy to snapshot and review.

Initial implementation note: `phoenix.live_view.macros.LiveEventProtocolModel`
now normalizes a `@:liveEventProtocol` enum into a deterministic protocol
manifest/hash and generated companion helpers. `LiveEventProtocol.manifest/hash`
snapshot the drift-detection layer, and `LiveEventProtocolCompanion<T>` generates
event constants, direct `WirePayload`-based `encode`/`decode` helpers, and JS-only
hook push helpers. `@:liveEvents(Protocol, "dispatchName")` now adds the first
server-side dispatcher binding from the same model, emitting straight-line
`WirePayload` reads and private handler calls in the LiveView module. The next
slices should migrate the todo-app prototype and add payload typedef/custom codec
support without adding a second parser.

Avoid copying these Tink patterns into v1:

- HTTP path/query/header/body routing machinery.
- Protocol inference from handler bodies.
- Global generated counters that make output or manifests unstable.
- Invisible replacement of the user's Phoenix callback.

## Todo-App Migration

The todo-app is the first migrated example:

1. Replace manual `shared.liveview.HookEvents` codecs with
   `HookClientEvent` plus generated `HookEvents`.
2. Generate `HookEvents` for the Genes JS hook path.
3. Change `CopyToClipboardHook` to call
   `HookEvents.pushClipboardCopied(hook, message)`.
4. Change `PingHook` to call `HookEvents.pushHookPing(hook)`.
5. Add `@:liveEvents(HookClientEvent, "dispatchHookEvent")` to `ProfileLive`
   and `TodoLive`.
6. Call `dispatchHookEvent(event, params, socket)` first in each bound
   `handleEvent`.
7. Keep ordinary `EventName` values only for template-driven Phoenix events.
8. Remove hook-only event names from `EventName` once generated event names are
   registered with HXX/HEEx strict event checks.

Current todo-app validation: `haxe build-client.hxml`, `haxe
build-server.hxml`, `haxe build-tests.hxml`, `mix test`, and async QA sentinel
with Playwright smoke/auth coverage.

Docs should show the direct Phoenix alternative next to the generated path:

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

That comparison keeps the value proposition honest: typed protocols reduce
drift, but raw Phoenix remains available.

## Implementation Phases

1. Add protocol metadata parsing and the normalized macro model
   (`LiveEventCollection`, signatures, payload fields, diagnostics).
2. Generate only the shared companion from that model.
3. Migrate client hooks from manual `HookEvents.encodeClientPush(...)` to
   generated per-event push helpers.
4. Add LiveView binding metadata and generated dispatch helper.
5. Migrate todo-app LiveViews to explicit dispatch-first handling.
6. Add diagnostics and strict-mode escalation.
7. Add protocol manifest/hash generation for cross-build drift checks.
8. Register generated event names with HXX/HEEx strict event validation.
9. Document the generated path in the user guide after the API is implemented.

## Required Validation

- Snapshot coverage for generated companion code.
- Snapshot coverage for generated dispatch code and generated Elixir shape.
- Snapshot or macro-unit coverage for the normalized protocol model so client
  helpers and server dispatch are proven to share one source of truth.
- Diagnostic tests for duplicate event names, missing handlers, bad payload
  types, and unsafe dynamic payloads.
- Todo-app Haxe client and server builds.
- Todo-app ExUnit coverage for the LiveView dispatch path.
- Todo-app QA sentinel with Playwright coverage for clipboard copied flash and
  ping no-op behavior.

## Not v1

- Automatically wrapping or replacing `handleEvent`.
- Inferring protocols from arbitrary `handleEvent` bodies.
- Typed replies from hook pushes.
- App-wide profile/backend switches.
- Custom runtime event systems that do not lower to Phoenix `pushEvent` and
  `handle_event/3`.
