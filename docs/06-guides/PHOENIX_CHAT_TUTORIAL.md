# Phoenix Chat Tutorial (Haxe + Presence + LiveView)

This tutorial walks through building a small real-time chat LiveView in **Haxe**, compiled to idiomatic Elixir, with:

- PubSub broadcasts for chat messages
- Phoenix Presence for “Online users”
- A tiny client-side hook (auto-scroll) compiled with Genes (Haxe -> JS)

Reference implementation: `examples/12-phoenix-chat/`.

## Goal

- Write “normal Haxe” (imperative is fine).
- Let the compiler lower it into the functional Elixir shapes Phoenix expects.
- Keep the generated Elixir readable and framework-faithful.
- Use typed LiveView/Presence/PubSub surfaces so common shape mistakes fail at compile time.

## Prereqs

- Elixir + Phoenix installed
- Node installed (for assets)
- Haxe toolchain managed via lix (recommended)

## 1) Create a Phoenix app (baseline)

```bash
mix phx.new phoenix_chat
cd phoenix_chat
mix setup
mix phx.server
```

Confirm you can load `http://localhost:4000/` before adding Haxe.

## 2) Add Reflaxe.Elixir (server-side)

Add the dependency to `mix.exs`:

```elixir
defp deps do
  [
    {:reflaxe_elixir, github: "fullofcaffeine/reflaxe.elixir", tag: "<RELEASE_TAG>", only: [:dev, :test], runtime: false},
    # ...
  ]
end
```

Then scaffold the Haxe integration:

```bash
mix deps.get
mix haxe.gen.project --phoenix --basic-modules --force
```

What you get:

- `build.hxml` + `src_haxe/**` (server Haxe -> Elixir)
- Mix compiler wiring (`compilers: [:haxe] ++ Mix.compilers()`)
- A starter LiveView module in Haxe

**Important:** In Phoenix projects, `build.hxml` should set `-D app_name=<YourAppModule>` (e.g. `PhoenixChat`).
Presence/Router/Endpoint transforms derive `otp_app` and `PubSub` module names from this prefix.

## 3) Add the Phoenix client scaffold (Haxe hooks + esbuild watch safety)

Run:

```bash
mix haxe.phoenix.scaffold
```

This patches:

- `assets/js/app.js` to `import "./hx_app.js"` and merge `window.Hooks` into LiveView hooks
- `config/dev.exs` to add a `haxe_client:` watcher that runs `mix haxe.watch --promote ...`
- `mix.exs` to ensure `assets.build` / `assets.deploy` compile the client Haxe first

**Fail-fast by default:** if your Phoenix templates are heavily customized and the task can’t find safe insertion
points, it raises (so you don’t end up with a half-wired project). Use `--warn-only` for best-effort mode:

```bash
mix haxe.phoenix.scaffold --warn-only
```

Details: `docs/06-guides/WATCHER_WORKFLOW.md`.

## 4) Implement Presence (server)

Create a Presence module in Haxe:

```haxe
package phoenix_chat_hx.presence;

import phoenix.PresenceBehavior;

typedef PresenceMeta = {
  var onlineAt: Float;
  var name: String;
}

@:native("PhoenixChatWeb.Presence")
@:presence
class ChatPresence implements PresenceBehavior {}
```

Add it to your supervision tree (Elixir), typically in `lib/phoenix_chat/application.ex`:

```elixir
children = [
  {Phoenix.PubSub, name: PhoenixChat.PubSub},
  PhoenixChatWeb.Presence,
  PhoenixChatWeb.Endpoint
]
```

## 5) Implement Chat LiveView (server)

Write your LiveView in Haxe and compile to `PhoenixChatWeb.AppLive` (or `ChatLive`) using `@:native(...)` + `@:liveview`.

Key behaviors:

- On `mount/3` when connected:
  - subscribe to `chat:room:<room>`
  - subscribe to `chat:presence:<room>` (Presence diffs)
  - `Presence.track` the current user
  - `Presence.list` to initialize the online list
- On `handle_event("send_message", ...)`:
  - append message to assigns
  - PubSub broadcast to other subscribers (use `broadcast_from` to avoid echo)
- On `handle_info`:
  - presence diffs -> refresh `Presence.list(topic)` -> recompute online views
  - chat message tuples -> append to assigns

See: `examples/12-phoenix-chat/src_haxe/phoenix_chat_hx/live/AppLive.hx`.

Typed abstractions used here:

- `Socket<AppLiveAssigns>` and `LiveSocket<AppLiveAssigns>` keep assigns shape-checked.
- `MountParams` / `Session` typedefs avoid “stringly typed map” access in callbacks.
- `PresenceEntry<PresenceMeta>` keeps presence metadata typed when computing online views.

These prevent common mistakes like assigning unknown keys, reading missing params, or treating Presence meta as untyped blobs.

Haxe callback shape:

```haxe
public static function mount(params:MountParams, session:Session, socket:Socket<AppLiveAssigns>):MountResult<AppLiveAssigns> {
  var live:LiveSocket<AppLiveAssigns> = socket.assign({
    room: "lobby",
    messages: [],
    online_user_count: 0
  });
  return Ok(live);
}
```

Notes:
- `params` and `session` are plain Haxe names here; if unused, generated Elixir will still use `_params` / `_session`.
- `_.field` syntax in `LiveSocket.assign` is a compile-time field selector, not a runtime variable.

Why this generated shape matters: `socket.assign({...})` lowers to a pipe of `assign/3` calls, so
stacktraces/logs map cleanly back to the Haxe assigns you wrote.

```elixir
def mount(_params, _session, socket) do
  live =
    socket
    |> assign(:room, "lobby")
    |> assign(:messages, [])
    |> assign(:online_user_count, 0)

  {:ok, live}
end
```

## 6) Client hook (auto-scroll)

Implement a tiny LiveView hook in Haxe client code:

- `src_haxe/client/Boot.hx` publishes `window.Hooks.AutoScroll`
- the LiveView template uses `phx-hook="AutoScroll"` on the messages container

See: `examples/12-phoenix-chat/src_haxe/client/Boot.hx`.

## 7) Run and manually test

Run:

```bash
mix setup
mix phx.server
```

Manual test checklist:

1. Open `http://localhost:4000/` in two separate browser windows (not just two tabs in the same session).
2. Both windows should show online count `2`, and one row labeled `you` per window.
3. Send a message from one window.
4. The other window should receive it immediately (PubSub).
5. Close one window: the online count should decrement (Presence).

## 8) Functional style variant (same feature)

You can write the same logic in a more functional Haxe style (pure helper + explicit rebinding), which still compiles to idiomatic Elixir:

```haxe
static function appendMessage(messages:Array<ChatMessage>, msg:ChatMessage):Array<ChatMessage> {
  var next = messages.copy();
  next.push(msg);
  return next;
}

static function applyIncoming(socket:LiveSocket<AppLiveAssigns>, msg:ChatMessage):LiveSocket<AppLiveAssigns> {
  return socket.assign(_.messages, appendMessage(socket.assigns.messages, msg));
}
```

This maps cleanly to data-in/data-out updates in generated Elixir and avoids hidden mutation pitfalls.

## 9) QA + E2E smoke (2 sessions)

Haxe-authored ExUnit unit coverage is included:

```bash
cd examples/12-phoenix-chat
mix test
```

Example test: `examples/12-phoenix-chat/src_haxe/test/live/ChatStateTest.hx`.

`examples/12-phoenix-chat` already includes Playwright coverage at `examples/12-phoenix-chat/e2e/presence.spec.ts`.

Run with sentinel-managed lifecycle:

```bash
scripts/qa-sentinel.sh --app examples/12-phoenix-chat --port 4012 --playwright --e2e-spec "e2e/presence.spec.ts" --async --deadline 600 -v
```

Then bounded log follow:

```bash
scripts/qa-logpeek.sh --run-id <RUN_ID> --until-done 120
```

This validates two browser sessions (online count + message fanout) without foreground server blocking.

## Troubleshooting

- `Could not resolve "./hx_app.js"` under esbuild watch:
  - You’re missing the “temp output + promote” workflow. Re-run `mix haxe.phoenix.scaffold` and ensure
    `build-client.hxml` outputs to `assets/js/_hx_app_tmp.js`.
- Presence fails to start with an “unknown registry” error:
  - Ensure `Phoenix.PubSub` is started in the supervision tree.
  - Ensure your Presence module uses the correct `otp_app` + `pubsub_server` for your Phoenix app.
  - Ensure `build.hxml` uses `-D app_name=<YourAppModule>` (not a custom suffix).
