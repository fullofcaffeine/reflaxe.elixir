# Phoenix API Reference (User-Facing)

This page documents high-impact Phoenix-facing APIs used by applications authored in Haxe and compiled to Elixir.

## Core Module Roles

- `phoenix.Phoenix`: canonical LiveView callback result types and helper entrypoints
- `phoenix.Component`: assign/slot helper APIs and component-oriented utilities
- `phoenix.LiveSocket`: typed LiveView socket wrapper operations
- `phoenix.PhoenixFlash`: typed flash helpers
- `phoenix.Channel` + `phoenix.channels.*`: typed channel callback/result helpers
- `phoenix.Presence` + `phoenix.PresenceModule`: presence tracking APIs
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

- Inline markup: `return <div>...</div>;`
- `phoenix.hxx.HeexTemplate` (`root`, `root_ast`, helpers)
- `HXX.hxx(...)` / `HXX.block(...)` for explicit string-template forms

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
- Use `Presence.track`, `Presence.update`, and `Presence.list` patterns for stable realtime state

## Testing Surface

Main test APIs:

- `phoenix.test.ConnTest`
- `phoenix.test.LiveViewTest`
- `phoenix.test.LiveView`
- `phoenix.test.Conn`

Keep most coverage in Haxe-authored ExUnit integration tests and use Playwright only as thin smoke coverage.

## Common Failure Modes

- Missing function-level `@:component` on a component function used as `<.name ...>`
- Ambiguous component names under strict component mode (`-D hxx_strict_components`)
- Callback naming drift when `@:native("handle_event")` is omitted
- Untyped slot/let usage under strict slot mode (`-D hxx_strict_slots`)
- Hook names not registered when strict hook mode is enabled (`-D hxx_strict_phx_hook`)

## Related Docs

- `docs/04-api-reference/ANNOTATIONS.md`
- `docs/04-api-reference/ROUTER_DSL.md`
- `docs/02-user-guide/HXX_SYNTAX_AND_COMPARISON.md`
- `docs/02-user-guide/INLINE_MARKUP.md`
