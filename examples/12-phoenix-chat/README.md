# 12 - Phoenix Chat (LiveView + Presence)

Realtime chat example authored in Haxe and compiled to Phoenix LiveView + Presence modules.

This example is intentionally **hybrid by design**: Haxe generates the app feature logic, while a small Phoenix scaffold remains hand-authored Elixir.

## What this example covers

- LiveView callbacks (`mount/3`, `handle_event/3`, `handle_info/2`)
- Presence-backed online user list and count
- PubSub message fanout for chat messages
- Haxe->JS client boot hook (`AutoScroll`) for LiveView
- Strict TSX template authoring in Haxe for LiveView render code

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

## Architecture

This app demonstrates a practical migration/adoption shape for Phoenix apps.

### Hybrid by design

- The Haxe compiler is configured to emit into `lib/phoenix_chat_hx`.
  - `examples/12-phoenix-chat/build.hxml` sets `-D elixir_output=lib/phoenix_chat_hx`.
  - `examples/12-phoenix-chat/mix.exs` configures `target_dir: "lib/phoenix_chat_hx"` for the `:haxe` compiler.
- Mix still boots a normal Phoenix app module.
  - `examples/12-phoenix-chat/mix.exs` sets `mod: {PhoenixChat.Application, []}`.
- Phoenix scaffold modules in `lib/phoenix_chat*.ex` and `lib/phoenix_chat_web/**` provide conventional boot/runtime wiring.
- Haxe-generated modules in `lib/phoenix_chat_hx/**` provide feature logic and typed LiveView behavior.

This is the repository's isolated ownership example. The generated root has its own
`lib/phoenix_chat_hx/_GeneratedFiles.json`, while handwritten Phoenix modules remain outside that
root. Compiler publication, formatting, stale deletion, and Mix clean still use the same hashed
ownership protocol as in-place output; isolation changes only the physical review boundary. The
example compile, runtime Mix tests, and sentinel browser path exercise this layout. See
[Generated Output Ownership](../../docs/02-user-guide/GENERATED_OUTPUT_OWNERSHIP.md).

### Why this approach exists

- It keeps the app runnable as a conventional Phoenix project.
- It shows incremental adoption: teams can move features to Haxe without rewriting framework glue first.
- It keeps boundaries obvious:
  - Phoenix boot/web wiring remains standard Elixir.
  - App feature behavior is authored in Haxe and generated to Elixir.

### Source-of-truth boundaries

- Haxe source-of-truth:
  - `examples/12-phoenix-chat/src_haxe/phoenix_chat_hx/**`
  - `examples/12-phoenix-chat/src_haxe/client/**`
- Scaffold source-of-truth:
  - `examples/12-phoenix-chat/lib/phoenix_chat/application.ex`
  - `examples/12-phoenix-chat/lib/phoenix_chat.ex`
  - `examples/12-phoenix-chat/lib/phoenix_chat_web.ex`
  - `examples/12-phoenix-chat/lib/phoenix_chat_web/**`

## How This Differs From todo-app

`examples/todo-app` and `examples/12-phoenix-chat` have different goals.

### 12-phoenix-chat goal

- Demonstrate a focused realtime feature set (LiveView + Presence + PubSub) in a small app.
- Demonstrate incremental Haxe adoption in an otherwise standard Phoenix structure.
- Keep Phoenix scaffold modules explicit and easy to inspect.

### todo-app goal

- Demonstrate end-to-end Haxe-driven application code at larger scope.
- Use Haxe for a much broader slice of server code (`TodoApp` / `TodoAppWeb` modules), plus client hooks.
- Serve as the primary integration canary (Ecto + LiveView + Playwright + QA sentinel).

### Practical difference in generation model

- `12-phoenix-chat`:
  - Generated server modules are namespaced under `lib/phoenix_chat_hx/**`.
  - Scaffold runtime modules under `lib/phoenix_chat*.ex` + `lib/phoenix_chat_web/**` remain hand-authored.
- `todo-app`:
  - The generated server surface is broader and maps more directly into app/web module namespaces.
  - It still remains a normal Phoenix project, but with a much larger Haxe-authored surface area.

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
  use Phoenix.Presence,
    otp_app: :phoenix_chat,
    pubsub_server: PhoenixChat.PubSub
end
```

Haxe LiveView render excerpt (default typed TSX mode):

```haxe
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

- This example uses strict TSX inline markup by default in `AppLive.hx`.
- Template expressions are real Haxe expressions (`${...}`), so syntax/type errors are caught by the Haxe typer.
- For detailed template authoring guidance, see `docs/02-user-guide/INLINE_MARKUP.md` and `docs/02-user-guide/HXX_SYNTAX_AND_COMPARISON.md`.
- For the most complete end-to-end app (Ecto + tests + Playwright), see `examples/todo-app/README.md`.
- Playwright smoke for two-session presence is at `examples/12-phoenix-chat/e2e/presence.spec.ts`.
