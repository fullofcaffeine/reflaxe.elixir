# Portable Chat Tutorial (Shared Haxe Domain)

This tutorial focuses on writing **portable** Haxe that can be reused across targets (Elixir, JS, etc.).

Unlike `docs/06-guides/PHOENIX_CHAT_TUTORIAL.md`, the goal here is not “Phoenix-first typed extern usage”.
The goal is:

- keep domain logic target-agnostic
- isolate Phoenix/Elixir extern calls at the edges

## Pattern: Split “domain” from “transport”

Recommended folder split:

- `src_haxe/shared/**` for portable logic (no `elixir.*`, no `phoenix.*`)
- `src_haxe/<app>_hx/**` for Phoenix adapters (LiveView, Presence, PubSub, etc.)

## Example: Message validation (portable)

`src_haxe/shared/chat/Message.hx`:

```haxe
package shared.chat;

typedef Message = {
  var author: String;
  var body: String;
  var at: Float;
}

class MessageRules {
  public static function normalizeBody(body: String): String {
    if (body == null) return "";
    return StringTools.trim(body);
  }

  public static function isAcceptable(body: String): Bool {
    var b = normalizeBody(body);
    return b.length > 0 && b.length <= 500;
  }
}
```

This code is plain Haxe:

- no `Term`
- no `Atom`
- no Phoenix runtime assumptions

## Edge adapter: LiveView uses the portable rules

In your Phoenix LiveView module (Haxe -> Elixir), you can keep the transport concerns at the boundary:

- parse event params (Phoenix maps / `Term`)
- call `shared.chat.MessageRules`
- broadcast/assign using Phoenix externs

See the “Phoenix-first” example for the boundary mechanics:

- `docs/06-guides/PHOENIX_CHAT_TUTORIAL.md`
- `examples/12-phoenix-chat/`

## Tradeoffs

- Portable logic is easier to test and reuse.
- Phoenix adapters will still be target-specific, but they stay small and explicit.
- You can iterate toward portability gradually: start Phoenix-first, then peel off pure helpers.

