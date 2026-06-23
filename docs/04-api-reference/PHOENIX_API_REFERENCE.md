# Phoenix API Reference (User-Facing)

This page documents high-impact Phoenix-facing APIs used by applications authored in Haxe and compiled to Elixir.

For the example-driven parity backlog, see `docs/08-roadmap/phoenix-surface-parity.md`.

## Core Module Roles

- `phoenix.Phoenix`: canonical LiveView callback result types and helper entrypoints
- `phoenix.Component`: assign/slot helper APIs and component-oriented utilities
- `phoenix.Phoenix.Socket`: LiveView callback socket surface (includes assign helpers via extensions)
- `phoenix.LiveSocket`: optional typed wrapper operations
- `phoenix.LiveSession`: helpers for string-keyed LiveView session maps
- `phoenix.AssignKeys` and `phoenix.LiveStreams`: typed assign-key and stream-name token generation
- `phoenix.PhoenixFlash`: typed flash helpers
- `phoenix.Channel` + `phoenix.channels.*`: typed channel callback/result helpers
- `phoenix.Presence`, `phoenix.PresenceBehavior`, and generated app Presence modules: presence tracking APIs
- `phoenix.types.*`: typed contracts used by templates, assigns, slots, hooks, and route params

## LiveView Surface

Typical metadata + callback shape:

```haxe
@:native("MyAppWeb.TodoLive")
@:liveview
class TodoLive {
  public static function mount(params:Term, session:Term, socket:Socket<TodoAssigns>):MountResult<TodoAssigns> {
    return Ok(socket);
  }

  public static function handleEvent(event:String, params:Term, socket:Socket<TodoAssigns>):HandleEventResult<TodoAssigns> {
    return NoReply(socket);
  }
}
```

Key points:

- In `@:liveview` modules, exact Haxe-style callbacks emit canonical Phoenix names:
  `handleEvent -> handle_event`, `handleInfo -> handle_info`, `handleParams -> handle_params`, and `handleAsync -> handle_async`.
- Use function-level `@:native("...")` only for explicit interop with an existing Elixir API or unusual callback name.
- Prefer typed assigns typedefs and keep them shared between render/mount/event paths.

## LiveView Assign And Stream APIs (Important)

`phoenix.Phoenix.Socket` supports Phoenix-faithful runtime semantics with Haxe-oriented authoring ergonomics:

- `assign(_.field, value)` for short single-field updates
- `assign({ ... })` for Phoenix-style bulk updates (`assign/2` shape)
- `assignKey(keys.field, value)` as an optional typed-key mode
- `assignNew` / `assignNewKey` and `update` / `updateKey` for default/update workflows
- `stream(streams.field, items)` plus `streamInsert` / `streamDelete` for typed LiveView streams

`merge({ ... })` remains available as a backward-compatible alias; prefer `assign({ ... })` for 1:1 Phoenix API shape.

Typed-key setup is now:
- `var keys = phoenix.AssignKeys.of(MyAssigns)`
- then `assignKey(keys.field, value)`

`phoenix.LiveSocket` keeps the same APIs for explicit wrapper-style helpers.

Typed-stream setup is:

- `var streams = phoenix.LiveStreams.of(MyAssigns)`
- then `stream(streams.field, items)`, `streamInsert(streams.field, item)`, or `streamDelete(streams.field, item)`

`LiveStreams.of(...)` turns list-shaped assigns fields such as `todos:Array<Todo>` into `LiveStreamName<MyAssigns, Todo>` tokens. The generated code remains ordinary Phoenix:

```elixir
Phoenix.LiveView.stream(socket, :todos, todos)
Phoenix.LiveView.stream_insert(socket, :todos, todo)
Phoenix.LiveView.stream_delete(socket, :todos, todo)
```

Raw `Phoenix.LiveView.stream*` extern calls remain available for direct interop and existing code.

Canonical deep dive:

- `docs/04-api-reference/LIVE_SOCKET_ASSIGN_API.md`

## Live Session Handoff

Phoenix LiveViews receive the session payload declared by the router, not the
whole Plug session. Use `liveSessionMfa(...)` in the router and an app-owned
bridge function to copy only the keys the LiveViews need:

```haxe
import phoenix.LiveSession;
import plug.Conn;

@:native("MyAppWeb.LiveSession")
class LiveSessionBridge {
  public static function live_session(conn:Conn<{}>):Term {
    return LiveSession.fromConnKeys(conn, ["user_id", "organization_id"]);
  }
}
```

Router:

```haxe
liveSession("default", [live("/", AppLive)], {
  session: liveSessionMfa(LiveSessionBridge, "live_session"),
  onMount: [onMount(AuthHook), onMountArg(AuthHook, "admin")]
});
```

This emits normal Phoenix router options:

```elixir
live_session :default,
  session: {MyAppWeb.LiveSession, :live_session, []},
  on_mount: [MyAppWeb.AuthHook, {MyAppWeb.AuthHook, :admin}] do
```

`LiveSession.get(session, "key")`, `getInt(session, "user_id")`, `put`,
`empty`, and `getWithDefault` operate on the LiveView session map itself.
Prefer typed readers such as `getInt` when narrowing session values. Keep
auth/session policy app-owned; these helpers do not introduce a
Rails/Devise-style compatibility layer.

## Component Surface

`@:component` semantics are two-level:

- class-level: component module context
- function-level: discoverable component entrypoint

```haxe
@:native("MyAppWeb.CoreComponents")
@:component
class CoreComponents {
  @:component
  public static function button(assigns:ButtonAssigns):String {
    return <button class={@class}>{@inner_content}</button>;
  }
}
```

Slot typing uses `phoenix.types.Slot` + `@:slot` metadata in assigns typedefs.

The existing component surface is intentionally Phoenix-shaped. Use function components,
attrs, and slots when a real reusable component boundary exists; keep inline HXX in a
LiveView render function when a template is local to that LiveView.

### Forms

For Phoenix 1.7-style forms, use `Phoenix.Component.to_form/1,2` through
`Component.toForm(...)` or `Component.toFormParams(...)`:

```haxe
import phoenix.Component;
import phoenix.ToFormOptions;

var changeset = User.changeset(user, params);
var form = Component.toForm(changeset, ToFormOptions.build("user", "user-form"));
var searchForm = Component.toFormParams({query: ""}, ToFormOptions.build("search"));
```

The call lowers to the real Phoenix API with keyword options equivalent to:

```elixir
Phoenix.Component.to_form(changeset, as: :user, id: "user-form")
Phoenix.Component.to_form(%{query: ""}, as: :search)
```

Use Ecto changesets for schema-backed forms and params maps for lightweight
search/filter forms. `ToFormOptions.build(...)` exists because Phoenix expects
keyword options, not a Haxe object map.

## HXX / HEEx APIs

Primary template entrypoints:

- Inline markup: `return <div>...</div>;` (recommended/default authoring path)
- `phoenix.hxx.HeexTemplate` (`root`, `root_ast`, helpers)
- `HXX.hxx(...)` / `HXX.block(...)` for legacy balanced-mode string-template forms

Authoring rule of thumb:

- New app templates should use inline markup. It gives the compiler real Haxe expressions to type-check.
- Balanced string templates are for migration and compatibility: existing HEEx/string templates, older HXX modules, and focused compiler fixtures.
- Raw HEEx markers inside Haxe-authored templates are explicit escape hatches, not a normal HXX authoring style.

Relevant strictness/authoring metadata:

- `@:hxx_mode("balanced"|"tsx"|"metal")`
- `@:hxx_no_inline_markup`
- `@:allow_heex` (escape hatch)
- `@:phxHookNames` for typed hook-name registries

## Channel and Socket Surface

- `@:socket` + `@:socketChannels([...])` define topic routing at socket module level
- `@:channel` modules implement join/in/out behavior
- `phoenix.channels.JoinResult` and `phoenix.channels.ReplyResult` provide typed callback result contracts

## Presence Surface

- `@:presence` marks a presence module
- `@:presenceTopic("...")` (optional) supplies default topic wiring for presence helpers
- `PresenceTopic.of("...")` and `PresenceKey.of("...")` document app-owned topic/key values at the type level
- Prefer generated app-module helpers from LiveViews: `ChatPresence.trackWithSocket(socket, topic, key, meta)`, `ChatPresence.updateWithSocket(socket, topic, key, meta)`, `ChatPresence.untrackWithSocket(socket, topic, key)`, `ChatPresence.list(topic)`, and `ChatPresence.getByKey(topic, key)`
- Use raw `phoenix.Presence` only for lower-level Phoenix interop; normal app code should call the generated module so emitted Elixir goes through `<AppWeb>.Presence.*`
- Raw strings still work because Phoenix topics are naturally dynamic. Use typed tokens first for fixed app concepts, and plain strings when the topic/key is already coming from dynamic routing or protocol data.

Canonical Haxe shape:

```haxe
import phoenix.PresenceBehavior;
import phoenix.PresenceKey;
import phoenix.PresenceTopic;

typedef PresenceMeta = {
  var onlineAt:Float;
  var name:String;
}

@:native("PhoenixChatWeb.Presence")
@:presence
class ChatPresence implements PresenceBehavior {}

// From a LiveView callback:
var topic = PresenceTopic.of("chat:presence:lobby");
var key = PresenceKey.of(currentUserId);
live = ChatPresence.trackWithSocket(live, topic, key, {
  onlineAt: Date.now().getTime(),
  name: currentUserName
});

var onlineUsers:Map<String, phoenix.Presence.PresenceEntry<PresenceMeta>> =
  cast ChatPresence.list(topic);
```

Canonical Elixir shape:

```elixir
PhoenixChatWeb.Presence.track(self(), topic, current_user_id, %{online_at: online_at, name: name})
online_users = PhoenixChatWeb.Presence.list(topic)
```

With `@:presenceTopic("users")`, the macro also provides `trackSimple(key, meta)`, `updateSimple(key, meta)`, `untrackSimple(key)`, and `listSimple()` for fixed-topic modules. Pass `PresenceKey.of(...)` for app-owned keys. Use explicit `PresenceTopic.of(...)` helpers when the topic is dynamic, such as per-room chat presence.

## Testing Surface

Main test APIs:

- `phoenix.test.ConnTest`
- `phoenix.test.LiveViewTest`
- `phoenix.test.LiveViewEventName`
- `phoenix.test.LiveViewMountResult`
- `phoenix.test.LiveView`
- `phoenix.test.Conn`

`LiveViewTest.live(conn, path)` preserves Phoenix API faithfulness: the emitted call is still
`Phoenix.LiveViewTest.live/2`, which returns `{:ok, view, html}`. Haxe wraps that tuple as
`LiveViewMountResult`, so tests can use named accessors:

```haxe
var result = LiveViewTest.live(conn, "/");
var liveView = result.view();
var initialHtml = result.initialHtml();
```

The wrapper is `from Term` / `to Term`, so existing raw tuple helpers such as
`LiveViewTest.view(result)` and `LiveViewTest.initial_html(result)` remain available for
compatibility.

For app-owned assigns and LiveView event names, tests can use typed tokens while still emitting
ordinary Phoenix calls:

```haxe
import phoenix.AssignKeys;
import phoenix.test.LiveViewEventName;
import phoenix.test.LiveViewTest;

typedef CounterAssigns = {
  var count:Int;
}

@:phxEventNames
enum abstract CounterEvent(String) to String {
  var Increment = "increment";
}

var keys = AssignKeys.of(CounterAssigns);
var count:Int = LiveViewTest.get_assign_key(liveView, keys.count);
liveView = LiveViewTest.render_click_event(liveView, LiveViewEventName.of(CounterEvent.Increment));
```

Why this shape: `AssignKeys.of(...)` reuses the same assign-key tokens as LiveView code, and
`LiveViewEventName.of(...)` works well with event registries already used by HXX strict event
checking. CSS selectors remain raw strings because selector syntax is inherently textual and should
mirror Phoenix directly.

Keep most coverage in Haxe-authored ExUnit integration tests and use Playwright only as thin smoke coverage.

## Common Failure Modes

- Missing function-level `@:component` on a component function used as `<.name ...>`
- Ambiguous component names under strict component mode (`-D hxx_strict_components`)
- Callback naming drift from misspelled callback names; exact Haxe-style names are normalized automatically in `@:liveview`
- Untyped slot/let usage under strict slot mode (`-D hxx_strict_slots`)
- Hook names not registered when strict hook mode is enabled (`-D hxx_strict_phx_hook`)

## Related Docs

- `docs/04-api-reference/LIVE_SOCKET_ASSIGN_API.md`
- `docs/04-api-reference/ANNOTATIONS.md`
- `docs/04-api-reference/ROUTER_DSL.md`
- `docs/02-user-guide/HXX_SYNTAX_AND_COMPARISON.md`
- `docs/02-user-guide/INLINE_MARKUP.md`
- `docs/08-roadmap/phoenix-surface-parity.md`
