# Phoenix API Reference (User-Facing)

This page documents high-impact Phoenix-facing APIs used by applications authored in Haxe and compiled to Elixir.

For the example-driven parity backlog, see `docs/08-roadmap/phoenix-surface-parity.md`.

## Core Module Roles

- `phoenix.Phoenix`: canonical LiveView callback result types and helper entrypoints
- `phoenix.Component`: assign/slot helper APIs and component-oriented utilities
- `phoenix.Phoenix.Socket`: LiveView callback socket surface (includes assign helpers via extensions)
- `phoenix.LiveSocket`: optional typed wrapper operations
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

  @:native("handle_event")
  public static function handleEvent(event:String, params:Term, socket:Socket<TodoAssigns>):HandleEventResult<TodoAssigns> {
    return NoReply(socket);
  }
}
```

Key points:

- Use `@:native("handle_event")` when your Haxe method name differs from canonical callback naming.
- Prefer typed assigns typedefs and keep them shared between render/mount/event paths.

## LiveView Assign APIs (Important)

`phoenix.Phoenix.Socket` supports Phoenix-faithful runtime semantics with Haxe-oriented authoring ergonomics:

- `assign(_.field, value)` for short single-field updates
- `assign({ ... })` for Phoenix-style bulk updates (`assign/2` shape)
- `assignKey(keys.field, value)` as an optional typed-key mode
- `assignNew` / `assignNewKey` and `update` / `updateKey` for default/update workflows

`merge({ ... })` remains available as a backward-compatible alias; prefer `assign({ ... })` for 1:1 Phoenix API shape.

Typed-key setup is now:
- `var keys = phoenix.AssignKeys.of(MyAssigns)`
- then `assignKey(keys.field, value)`

`phoenix.LiveSocket` keeps the same APIs for explicit wrapper-style helpers.

Canonical deep dive:

- `docs/04-api-reference/LIVE_SOCKET_ASSIGN_API.md`

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

## HXX / HEEx APIs

Primary template entrypoints:

- Inline markup: `return <div>...</div>;` (recommended/default authoring path)
- `phoenix.hxx.HeexTemplate` (`root`, `root_ast`, helpers)
- `HXX.hxx(...)` / `HXX.block(...)` for legacy balanced-mode string-template forms

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
- Prefer generated app-module helpers from LiveViews: `ChatPresence.trackWithSocket(socket, topic, key, meta)`, `ChatPresence.updateWithSocket(socket, topic, key, meta)`, `ChatPresence.untrackWithSocket(socket, topic, key)`, `ChatPresence.list(topic)`, and `ChatPresence.getByKey(topic, key)`
- Use raw `phoenix.Presence` only for lower-level Phoenix interop; normal app code should call the generated module so emitted Elixir goes through `<AppWeb>.Presence.*`

Canonical Haxe shape:

```haxe
import phoenix.PresenceBehavior;

typedef PresenceMeta = {
  var onlineAt:Float;
  var name:String;
}

@:native("PhoenixChatWeb.Presence")
@:presence
class ChatPresence implements PresenceBehavior {}

// From a LiveView callback:
var topic = "chat:presence:lobby";
live = ChatPresence.trackWithSocket(live, topic, currentUserId, {
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

With `@:presenceTopic("users")`, the macro also provides `trackSimple(key, meta)`, `updateSimple(key, meta)`, `untrackSimple(key)`, and `listSimple()` for fixed-topic modules. Use explicit `topic` helpers when the topic is dynamic, such as per-room chat presence.

## Testing Surface

Main test APIs:

- `phoenix.test.ConnTest`
- `phoenix.test.LiveViewTest`
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

Keep most coverage in Haxe-authored ExUnit integration tests and use Playwright only as thin smoke coverage.

## Common Failure Modes

- Missing function-level `@:component` on a component function used as `<.name ...>`
- Ambiguous component names under strict component mode (`-D hxx_strict_components`)
- Callback naming drift when `@:native("handle_event")` is omitted
- Untyped slot/let usage under strict slot mode (`-D hxx_strict_slots`)
- Hook names not registered when strict hook mode is enabled (`-D hxx_strict_phx_hook`)

## Related Docs

- `docs/04-api-reference/LIVE_SOCKET_ASSIGN_API.md`
- `docs/04-api-reference/ANNOTATIONS.md`
- `docs/04-api-reference/ROUTER_DSL.md`
- `docs/02-user-guide/HXX_SYNTAX_AND_COMPARISON.md`
- `docs/02-user-guide/INLINE_MARKUP.md`
- `docs/08-roadmap/phoenix-surface-parity.md`
