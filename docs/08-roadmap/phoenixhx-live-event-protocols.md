# PhoenixHx Live Event Protocols

Status: adopted v1 design plan, with model/manifest, generated companion
encode/decode, JS push helpers, first explicit LiveView dispatcher binding, and
todo-app hook protocol migration in place. Dispatcher-call validation now warns
by default and escalates under `-D phoenixhx_live_events_strict`. Named typedef
payloads with direct built-in field decoding are in place. `@:codec(...)` is
implemented for named typedef payload fields that need explicit domain codecs.
Payload fields typed as `Null<T>` now require an explicit optional marker so
nullable wire contracts stay deliberate. Optional scalar constructor arguments
use Haxe's `?field:Type` syntax; optional named payload fields use
`@:optional var field:Null<Type>`. Known protocol events with malformed required
payloads are consumed by the dispatcher with `NoReply(socket)` instead of
falling through as unknown events. Protocol constructors can now distinguish
hook-origin events from simple template-origin events with `@:hookEvent(...)`
and `@:templateEvent(...)`; template `Int` fields decode DOM string params on
the server. Form-origin events now use `@:submitEvent("event", "root")` and
`@:changeEvent("event", "root")` to generate form-root decoders for typed
handlers while keeping ordinary Phoenix form params at runtime.

PhoenixHx should provide an opt-in, framework-level macro layer for typed
LiveView events that cross the browser hook/server LiveView boundary.

The goal is not to replace Phoenix. The goal is to let Haxe-authored frontend
and backend code share one event contract, then generate the small pieces of
boundary code that are otherwise stringly and repetitive.

## Adopted Review Direction

The accepted v1 direction is protocol-first, explicit-dispatch, and
handler-validated:

- The shared enum is the source of truth for generated event names, payload
  codecs, JS hook push helpers, server decode helpers, and manifest hashes.
- LiveViews keep the normal Phoenix-shaped `handleEvent(event, params, socket)`
  callback and call the generated dispatcher explicitly.
- The macro validates handlers and payload declarations at compile time, but it
  does not infer protocols from arbitrary handler bodies.
- Compiler defines may tighten diagnostics, but they must not turn this into a
  separate backend/profile or silently change runtime behavior.
- Runtime additions after compilation should stay minimal: app code still calls
  Phoenix `pushEvent`, and generated server code still lowers to ordinary
  `handle_event/3` helper clauses/conditionals.

This is a Haxe-layer improvement over vanilla Phoenix when Haxe owns both sides
of the boundary. For one-off template events, Elixir-only LiveViews, or
migration code that intentionally mirrors Phoenix docs, the vanilla/direct
PhoenixHx path remains the better default.

## Name and Positioning

Call the approach **PhoenixHx Live Event Protocols** in public docs and API
names. When explaining the motivation, it is reasonable to say "tRPC-like" as a
short analogy: one typed declaration drives the client helper and the server
receiver. Avoid naming the feature after tRPC, because PhoenixHx is not adding a
new RPC runtime and should not imply request/response semantics for v1.

More precise vocabulary:

- **Live Event Protocol**: the shared Haxe enum that declares event names and
  payload shapes.
- **Generated companion**: the generated Haxe module with event constants,
  encoders/decoders, and hook-origin JS push helpers.
- **Generated dispatcher**: the private LiveView helper that decodes protocol
  events and calls typed handlers.
- **Vanilla Phoenix path**: ordinary `pushEvent`/`handle_event/3` with string
  event names and map payload decoding.
- **Direct PhoenixHx path**: Haxe-authored `handleEvent(event, params, socket)`
  using typed externs such as `Params.getString`, but without a shared protocol
  declaration.

The feature should be described as a typed protocol layer around Phoenix's
existing event contract, not as a replacement for LiveView events.

## Why Not Just Vanilla Phoenix?

Vanilla Phoenix is excellent at the runtime boundary: browser hooks push an
event name plus a payload, and the LiveView receives `handle_event/3`. That
shape is simple, observable, and well understood. The weak spot appears when
both sides are authored in Haxe but the boundary remains stringly:

```javascript
hook.pushEvent("clipboard_copied", { message: message })
```

```elixir
def handle_event("clipboard_copied", params, socket) do
  message = Map.get(params, "message")
  {:noreply, put_flash(socket, :info, message)}
end
```

The direct PhoenixHx version is already better because the server can use typed
extern helpers instead of raw map access:

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

That still leaves two independent sources of truth: the hook must remember the
event string and payload key, and the LiveView must decode matching strings.
Renaming the event, changing a payload field, or moving a hook to another
LiveView can drift silently until runtime.

Live Event Protocols move that contract into shared Haxe:

```haxe
@:liveEventProtocol("HookEvents")
enum HookClientEvent {
  @:hookEvent("clipboard_copied")
  ClipboardCopied(message:String);

  @:hookEvent("ping")
  HookPing;
}

typedef HookEvents = LiveEventProtocolCompanion<HookClientEvent>;
```

Client hook code becomes:

```haxe
HookEvents.pushClipboardCopied(hook, message);
```

Server LiveView code stays Phoenix-shaped but dispatches through the generated
boundary helper:

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

The generated Elixir should still read like handwritten Phoenix code:

```elixir
defp dispatch_hook_event(event_name, params, socket) do
  cond do
    event_name == "clipboard_copied" ->
      message_raw =
        if not is_nil(params) and is_map(params) do
          Map.get(params, "message")
        else
          nil
        end

      message = if is_binary(message_raw), do: message_raw, else: nil
      if is_nil(message), do: nil, else: handle_clipboard_copied(message, socket)

    true ->
      nil
  end
end
```

The value proposition is therefore not "Phoenix events are bad." It is:
Phoenix already gives us a clean runtime protocol, and Haxe lets PhoenixHx make
that protocol compile-time visible on both sides.

The improvement over raw Phoenix is specifically a shared-boundary improvement.
Raw Phoenix is string/map based at the hook boundary: the hook pushes
`"event_name"` and a payload map, and the LiveView separately matches the same
string and reads the same keys. Live Event Protocols collapse those duplicated
facts into one shared Haxe enum. The generated code should then give the hook a
typed `pushX(...)` helper, give the LiveView a typed handler signature, and make
renames or payload-shape changes fail at compile time instead of at the next
browser interaction.

That does not make the protocol path universally better. For a local
`phx-click`, Elixir-only LiveView, migration step copied from Phoenix docs, or
server-only Haxe event, raw Phoenix or direct PhoenixHx is still lower ceremony
and often the better DevEx. The framework should present Live Event Protocols
as an opt-in upgrade for shared Haxe browser/server contracts, not as a
replacement for ordinary Phoenix event handling.

| Approach | Best fit | Tradeoff |
| --- | --- | --- |
| Vanilla Phoenix | Existing Elixir apps, one-off events, direct interop, fastest local debugging | Event names and payload keys are strings/maps; drift is caught at runtime |
| Direct PhoenixHx | Haxe-authored LiveViews that mostly receive template events | Server-side decoding is typed, but client/server hook contracts are still manually synchronized |
| Live Event Protocols | Haxe-authored hooks and LiveViews sharing an event boundary | Requires an explicit protocol enum and dispatcher call, but gives one source of truth, generated helpers, handler validation, and manifest/hash drift checks |

Use Live Event Protocols when an event crosses a Haxe-authored browser/server
boundary or when the payload has enough shape that duplication would be risky.
Keep vanilla Phoenix or direct PhoenixHx for simple local `phx-click` style
events, gradual adoption, and places where matching Phoenix examples exactly is
more important than shared compile-time typing.

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
  @:hookEvent("clipboard_copied")
  ClipboardCopied(message:String);

  @:hookEvent("ping")
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
generated from the shared protocol model. On JS builds, all-hook protocols also
expose `push(hook, event)` plus per-event helpers such as
`pushClipboardCopied(hook, message)`. Mixed protocols only expose per-event push
helpers for `@:hookEvent(...)` constructors; `@:templateEvent(...)`
constructors are driven by Phoenix's DOM event attributes and do not get hook
push helpers.

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
      message_raw =
        if not is_nil(params) and is_map(params) do
          Map.get(params, "message")
        else
          nil
        end

      message = if is_binary(message_raw), do: message_raw, else: nil
      if is_nil(message), do: nil, else: handle_clipboard_copied(message, socket)

    event_name == "ping" ->
      handle_ping(socket)

    true ->
      nil
  end
end
```

Current dispatcher output returns `nil` only for unknown protocol event names.
Known events whose required payload fields fail to decode return
`NoReply(socket)` so malformed protocol payloads are consumed safely and cannot
fall through into ordinary fallback handling.

A later diagnostic/telemetry iteration may still split the public dispatcher
result into `Unhandled`, `Handled(result)`, and `InvalidPayload`, but v1 keeps
the simple `Null<HandleEventResult<T>>` helper API and uses no-op `NoReply` for
known invalid payloads.

## Payload Rules

Support these first:

- empty constructors: `Ping`
- scalar constructor arguments: `ClipboardCopied(message:String)`
- named typedef payloads: `ClipboardCopied(payload:ClipboardCopiedPayload)`
- `@:wire("wire_name")` on typedef payload fields when the wire key should not
  be the default snake_case field name
- `String`, `Int`, `Bool`, `Float`
- `Array<String>` and `Array<Int>`
- `Null<T>` only for explicitly optional fields
- custom codecs through `@:codec(...)` on named typedef payload fields

`Null<T>` is intentionally not enough by itself. Use an optional constructor
argument or an `@:optional` typedef field so optionality is visible in the
protocol declaration and reflected in the generated manifest.

```haxe
@:templateEvent("search")
Search(?query:String);

typedef ProfileForm = {
  var name:String;
  @:optional var bio:Null<String>;
}

@:submitEvent("save_profile", "profile")
SaveProfile(payload:ProfileForm);
```

Avoid these in v1 protocol declarations:

- `Dynamic`
- `Map<String, Dynamic>`
- `haxe.ds.Map`
- `Reflect.field` payload access
- raw `__elixir__`
- custom class instances without an explicit codec

Generate direct helper functions for the built-in payload types. Prefer
macro-emitted JS object access and Elixir `%{}`/`Map.put`/`Map.get` plus
`Kernel.is_*` predicates over both `WirePayload` calls and generic runtime
codec objects in the default path. The manual todo-app `HookEvents` prototype
proved the value of a shared contract, but the framework macro should now lower
that contract directly to Phoenix-shaped code.

Use `@:codec(...)` only where the wire value is genuinely domain-specific:

```haxe
typedef ResourceSelectedPayload = {
  @:codec(ResourceIdCodec.codec())
  var resourceId:ResourceId;

  var source:String;
}
```

Most protocol fields should not use a codec. `String`, `Int`, `Bool`, `Float`,
simple arrays, and explicit optional fields are generated directly. For
template-origin events, ordinary DOM params such as `phx-value-id` for an `Int`
also use generated parsing rather than a custom codec.

## Template-Origin Events

Use `@:templateEvent(...)` when a normal Phoenix template event has a small,
important `phx-value-*` contract that should be checked and decoded with the
same protocol machinery:

```haxe
@:liveEventProtocol("TodoEvents")
enum TodoEvent {
  @:templateEvent("toggle_todo")
  ToggleTodo(id:Int);

  @:hookEvent("clipboard_copied")
  ClipboardCopied(message:String);
}

typedef TodoEvents = LiveEventProtocolCompanion<TodoEvent>;
```

The template stays ordinary PhoenixHx/HXX:

```haxe
<button
  type="button"
  phx-click=${TodoEvents.ToggleTodoEvent}
  phx-value-id=${Std.string(todo.id)}>
  Done
</button>
```

When the event name is statically known, HXX validates the protocol contract at
compile time:

- `@:templateEvent` is valid on DOM event attributes such as `phx-click`,
  `phx-blur`, `phx-focus`, and key events, but not on `phx-submit` or
  `phx-change`.
- Required constructor fields must appear as sibling `phx-value-*` attributes.
  `ToggleTodo(id:Int)` requires `phx-value-id`.
- Under `-D hxx_strict_phx_event_payloads`, extra `phx-value-*` keys are
  rejected when the event is protocol-owned.

The generated server dispatcher reads `"id"` from the Phoenix params map and
parses the DOM string before calling the typed handler:

```haxe
static function handleToggleTodo(
  id:Int,
  socket:Socket<TodoAssigns>
):HandleEventResult<TodoAssigns> {
  return NoReply(toggleTodo(id, socket));
}
```

No JS helper is generated for `ToggleTodo` because Phoenix already sends
template events from the DOM. The generated companion still provides
`TodoEvents.ToggleTodoEvent` for template authoring and event-name validation.

Use this when the template event is repeated, payload-bearing, or domain
important. For a one-off local button such as `phx-click="close_modal"`, direct
PhoenixHx is still clearer.

## Form-Origin Events

Use `@:submitEvent(...)` and `@:changeEvent(...)` when a Phoenix form event has
a repeated or important params contract:

```haxe
typedef TodoForm = {
  var title:String;

  @:optional
  var notes:Null<String>;
}

@:liveEventProtocol("TodoEvents")
enum TodoEvent {
  @:submitEvent("create_todo", "todo")
  CreateTodo(payload:TodoForm);

  @:changeEvent("update_form", "todo")
  UpdateForm(payload:TodoForm);
}
```

The first string is the Phoenix event name. The second string is the form root,
matching input names such as `todo[title]`. Generated server code still lowers
to plain Phoenix params handling: read `Map.get(params, "todo")`, read fields
from that map, parse primitives, and call the typed handler.

No JS helper is generated for form-origin events because Phoenix sends
`phx-submit` and `phx-change` from the DOM. The generated companion provides
event constants for HXX authoring and validation:

```haxe
<form
  phx-change=${TodoEvents.UpdateFormEvent}
  phx-submit=${TodoEvents.CreateTodoEvent}>
  <input type="text" name="todo[title]" value={@form.title} />
</form>
```

HXX also validates event origin for form events when the event name is
statically known: `@:submitEvent` belongs on `phx-submit`, and `@:changeEvent`
belongs on `phx-change`. Full form field inference remains intentionally out of
scope for v1; the durable payload guarantee comes from generated server-side
decoding and typed handler signatures.

Use direct PhoenixHx instead for one-off local forms where manual params code is
shorter and clearer.

The runtime call introduced by a custom codec is not a new protocol runtime.
It is the same domain parse/validate call a handwritten Phoenix
`handle_event/3` would already need before using a value object such as
`ResourceId`, `OrganizationSlug`, or an opaque token. The protocol macro moves
that conversion into the generated decoder so app handlers receive typed values
instead of open params.

The expression currently returns `phoenix.channels.WireCodec<T>`. Generated code
inserts the codec output with direct payload map/object writes and reads the raw
field with direct map/object access before calling the codec. The codec itself
may use `WirePayload` when it owns an open or nested boundary shape, but the
generated protocol scaffolding should not.

## Diagnostics

Protocol diagnostics should catch:

- duplicate event names
- unsupported payload field types
- duplicate wire keys after name conversion
- `Dynamic` or unsafe map payloads
- invalid `@:hookEvent`, `@:event`, `@:templateEvent`, `@:wire`, or
  `@:codec` metadata

LiveView binding diagnostics should catch:

- missing handler method
- wrong handler argument list
- wrong handler return type
- duplicate handler bindings
- protocol binding without an explicit dispatcher call

HXX diagnostics should catch:

- protocol event origin mismatches, such as `@:submitEvent` used on
  `phx-click`
- missing required `phx-value-*` attributes for statically known
  `@:templateEvent` usage
- extra `phx-value-*` keys under `-D hxx_strict_phx_event_payloads`

Dispatcher-call validation should be a warning by default and an error under a
strict define such as:

```text
-D phoenixhx_live_events_strict
```

Current implementation note: dispatcher-call validation warns by default. When
the explicit call is missing, PhoenixHx skips generating the dispatcher helper
for that binding so generated Elixir does not contain an unused private
function. Under `-D phoenixhx_live_events_strict`, the same condition is a hard
compile error.

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
- Keep the metadata grammar narrow and validated: `@:hookEvent(...)`,
  legacy `@:event(...)`, `@:templateEvent(...)`, `@:wire(...)`,
  `@:codec(...)`, handler overrides, and nothing inferred from arbitrary
  handler bodies.
- Keep generated default payload code direct. Built-in field types should lower
  to target-native JS object and Elixir map operations, not `WirePayload` calls
  and not a generic runtime codec object path.
- Prefer source-positioned macro diagnostics for duplicate event names, duplicate
  wire keys, unsupported types, invalid metadata, and missing handlers.
- Use warnings for inferential checks such as "does `handleEvent` call the
  dispatcher?", then escalate under `-D phoenixhx_live_events_strict`.

Implementation should evaluate whether the generated companion is best produced
through a `@:genericBuild` placeholder type or through `Context.defineType` from
the protocol metadata. The public API should stay stable either way. The
important constraints are deterministic type generation, deterministic manifest
hashes, and generated Elixir/JS that remains easy to snapshot and review.

Current API note: the implemented entrypoint is still:

```haxe
typedef HookEvents = LiveEventProtocolCompanion<HookClientEvent>;
```

The `@:liveEventProtocol("HookEvents")` name feeds the generated native/module
name and manifest. A future polish pass may remove the typedef ceremony by
generating an importable `HookEvents` type directly from metadata, but that
should be treated as public API design work rather than a hidden refactor.

Initial implementation note: `phoenix.live_view.macros.LiveEventProtocolModel`
now normalizes a `@:liveEventProtocol` enum into a deterministic protocol
manifest/hash and generated companion helpers. `LiveEventProtocol.manifest/hash`
snapshot the drift-detection layer, and `LiveEventProtocolCompanion<T>` generates
event constants, direct `encode`/`decode` helpers, and JS-only hook push
helpers. Built-in fields now generate JS object literals/bracket reads and
Elixir `%{}`/`Map.put`/`Map.get` plus `Kernel.is_*` checks instead of
`WirePayload` helper calls. `@:liveEvents(Protocol, "dispatchName")` now adds
the first server-side dispatcher binding from the same model, emitting
straight-line map reads and private handler calls in the LiveView module when
the LiveView explicitly calls the dispatcher. The model distinguishes Haxe
constructor/handler arguments from flattened wire fields, so a named typedef
payload remains one typed Haxe value while generated JS and Elixir helpers still
emit direct per-field code. Custom codec support is now part of the same model
for named typedef payload fields; v1 keeps `WireCodec<T>` as the explicit
manual-domain escape hatch, while built-in protocol fields stay macro-first and
runtime-minimal.

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

Current remaining v1 polish:

- Decide whether to add metadata-only generated companion imports or keep the
  explicit `typedef FooEvents = LiveEventProtocolCompanion<FooEvent>` shape.
- Decide whether known-but-invalid payloads need a distinct diagnostic/telemetry
  result beyond the current safe `NoReply(socket)` behavior.
- Add typed replies only after fire-and-forget hook events remain stable in the
  todo-app and generated snapshots.

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
