# 12 - Phoenix Chat (LiveView + Presence)

Realtime chat example authored in Haxe and compiled to idiomatic Phoenix LiveView + Presence modules.

## What this example covers

- LiveView callbacks (`mount/3`, `handle_event/3`, `handle_info/2`)
- Presence-backed online user list and count
- PubSub message fanout for chat messages
- Haxe->JS client boot hook (`AutoScroll`) for LiveView

## Run

```bash
cd examples/12-phoenix-chat
mix setup
mix phx.server
```

Open `http://localhost:4000`.

## Tests

Compile Haxe-authored ExUnit tests and run:

```bash
cd examples/12-phoenix-chat
mix test
```

The example includes a Haxe-authored ExUnit test:

- `examples/12-phoenix-chat/src_haxe/test/live/ChatStateTest.hx`

## Key Haxe files

- `examples/12-phoenix-chat/src_haxe/phoenix_chat_hx/live/AppLive.hx`
- `examples/12-phoenix-chat/src_haxe/phoenix_chat_hx/live/AppLiveTypes.hx`
- `examples/12-phoenix-chat/src_haxe/phoenix_chat_hx/presence/ChatPresence.hx`
- `examples/12-phoenix-chat/src_haxe/client/Boot.hx`

## Haxe -> generated Elixir examples

Haxe Presence module:

```haxe
@:native("PhoenixChatWeb.Presence")
@:presence
class ChatPresence implements PresenceBehavior {}
```

Generated Elixir shape:

```elixir
defmodule PhoenixChatWeb.Presence do
  use Phoenix.Presence, otp_app: :phoenix_chat
end
```

Haxe LiveView render excerpt (typed TSX mode):

```haxe
@:hxx_mode("tsx")
public static function render(assigns: AppLiveAssigns): String {
  return <div class="panel">
    <div class="badge">${assigns.online_user_count}</div>
  </div>;
}
```

Generated Elixir shape:

```elixir
def render(assigns) do
  ~H"""
  <div class="panel">
    <div class="badge"><%= @online_user_count %></div>
  </div>
  """
end
```

## Notes

- This example now uses strict TSX mode in `AppLive.hx` (`@:hxx_mode("tsx")`).
- Template expressions are real Haxe expressions (`${...}`), so syntax/type errors are caught by the Haxe typer.
- For detailed template authoring guidance, see `docs/02-user-guide/INLINE_MARKUP.md` and `docs/02-user-guide/HXX_SYNTAX_AND_COMPARISON.md`.
- For the most complete end-to-end app (Ecto + tests + Playwright), see `examples/todo-app/README.md`.
- Playwright smoke for two-session presence is at `examples/12-phoenix-chat/e2e/presence.spec.ts`.
