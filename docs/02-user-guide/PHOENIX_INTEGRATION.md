# Phoenix Integration (User Guide)

Reflaxe.Elixir is designed to let you use **Phoenix conventions and APIs** while gaining Haxe’s compile-time type safety. You can adopt it in two ways:

1. **Greenfield** — new Phoenix apps where you author many modules in Haxe.
2. **Gradual adoption** — existing Phoenix apps where you move one module at a time.

For step-by-step setup, start here:

- New app: `docs/06-guides/PHOENIX_NEW_APP.md`
- Existing app: `docs/06-guides/PHOENIX_GRADUAL_ADOPTION.md`

## Key Principles

- **Phoenix-first**: generated Elixir should look and behave like normal Phoenix code.
- **Typed interfaces**: use typed Haxe externs to call Phoenix/Ecto/Elixir code.
- **No app-specific hacks**: the compiler should not “know about” your app’s domain.
- **Avoid `__elixir__()` in apps**: if an escape hatch is needed, prefer a reusable helper in `std/phoenix/**` (typed extern/shim) instead of per-app injections.

## Output Layout At A Glance

PhoenixHx is a build-time layer over a Phoenix app. You may write a LiveView in
Haxe, but after compilation Phoenix should still see a normal module under
`lib/my_app_web/live/**`.

```text
# Haxe source
src_haxe/server/live/TodoLive.hx
src_shared/shared/liveview/TodoEvents.hx

# Generated/compiled Phoenix app
lib/my_app_web/live/todo_live.ex
```

For existing apps, this is **in-place Phoenix mode**: generated files live in
the working Phoenix app, guarded by ownership rules. For generated demos or
future dogfood artifacts, **materialized Phoenix app mode** writes a complete
Phoenix tree under a build root such as `build/phoenix`.

You deploy the Phoenix app or release, not the Haxe source tree. Haxe/Reflaxe and
Genes are build-time tools; production runs the generated Elixir, BEAM bytecode,
assets, config, and documented runtime dependencies.

For the full directory comparison with vanilla Phoenix, compile commands, and
deployment rules, see the
[Phoenix Output Model](../05-architecture/PHOENIX_OUTPUT_MODEL.md).

## What You Typically Write in Haxe

You can author any of these in Haxe (incrementally, if desired):

- LiveView modules (`@:liveview`)
- Controllers (`@:controller`)
- Router DSL (`@:router`)
- Ecto schemas/queries/migrations (`@:schema`, query helpers, migrations)
- OTP (GenServers/Supervisors) where it makes sense
- Pure business/domain logic modules (`@:module`)

See working references:

- Minimal Phoenix: `examples/03-phoenix-app/`
- Elixir-first typed LiveView: `examples/13-elixir-first-liveview/`
- End-to-end LiveView + Ecto: `examples/todo-app/`

## Channels (Socket + Channel Modules)

Phoenix Channels are a **client/server boundary**: your browser code (typically JS) connects to a server-side `Phoenix.Socket`, joins a topic, and exchanges events with a `Phoenix.Channel`.

Reflaxe.Elixir supports the server-side pieces via annotations so your generated Elixir remains Phoenix-idiomatic:

- `@:socket` marks a module as a `Phoenix.Socket` and emits `use Phoenix.Socket`.
- `@:socketChannels([{topic, channel}])` emits `channel "<topic>", <ChannelModule>` routes on the socket.
- `@:endpointSockets([{path, socket, session?}])` mounts one or more sockets on your `@:endpoint` (e.g. `"/socket"`).

See a working end-to-end reference (Haxe→Elixir server + Haxe→JS client) in `examples/todo-app/src_shared/shared/channels/` and `examples/todo-app/src_haxe/server/channels/`.

### Shared Protocol Types (Client + Server)

For channel payloads, the repo includes a small, shared, cross-target protocol layer:

- `phoenix.channels.ChannelProtocol` (event names + encode/decode)
- `phoenix.channels.WirePayload` (safe string-key payload access; string-first + existing-atom fallback on Elixir)
- `phoenix.channels.WireFields` / `phoenix.channels.WireCodecs` (composable typed codecs)

These are included automatically:
- **Server builds** via `-lib reflaxe.elixir` (see `haxe_libraries/reflaxe.elixir.hxml`)
- **Client builds** via `-lib phoenix_js` (see `haxe_libraries/phoenix_js.hxml`)

### Client-side (Genes / Haxe→JS)

For browser code, use the repo-local `phoenix_js` library (`-lib phoenix_js`) which provides typed externs for:

- `phoenix.Socket` (Phoenix channels JS client)
- `phoenix.live_view.LiveSocket` (Phoenix LiveView JS client)
- `phoenix.channels.TypedChannelClient` (minimal typed wrapper around JS channels)

See:
- `examples/todo-app/build-client.hxml` (uses `-lib genes` + `-lib phoenix_js`)
- `examples/todo-app/src_haxe/client/channels/PingChannelClient.hx` (typed channel client example)

### Server-side Helpers (Haxe→Elixir)

On the server, prefer keeping your code Phoenix-native while using typed helpers where the wire is untyped:

- `phoenix.channels.TypedChannelServer.decode(protocol, event, payload)` → typed inbound message (or `null`)
- `phoenix.channels.TypedChannelServer.broadcast/push(..., typedMessage)` → encodes to `{event, payload}` then calls `Phoenix.Channel.*`

Reference implementation:
- `examples/todo-app/src_shared/shared/channels/PingProtocol.hx`
- `examples/todo-app/src_haxe/server/channels/PingChannel.hx`

## Naming & Module Mapping

Use `@:native("MyAppWeb.SomeModule")` to select the Elixir module name the Haxe class compiles to. This is the primary mechanism for Phoenix-friendly naming.

Example:

```haxe
@:native("MyAppWeb.TodoLive")
@:liveview
class TodoLive {
  // mount/3, handle_event/3, handle_info/2, render/1, etc.
}
```

## Gradual Adoption Pattern (recommended)

If you have an existing Phoenix app, start by generating modules into a separate namespace and call them from Elixir:

- Compile Haxe to `lib/my_app_hx/**`
- Generate modules under `MyAppHx.*` first
- Call from Elixir (`MyAppHx.SomeModule.some_fun(...)`)
- Later, when ready, you can `@:native` into `MyApp.*` / `MyAppWeb.*` and switch routing/delegation

Important: `-D app_name` is independent of this isolation pattern.

- Use `-D app_name=MyApp` (your Phoenix app module) so Phoenix/Ecto integrations can derive framework modules like `MyApp.Repo`, `MyAppWeb.Endpoint`, and Presence `otp_app`/PubSub correctly.
- Use the Haxe package name (e.g. `my_app_hx.*`) + `-D elixir_output=lib/my_app_hx` to control the generated “Haxe namespace” (`MyAppHx.*`).

This avoids “big bang” rewrites and keeps diffs easy to review.

## Tooling (Mix)

If your Phoenix app includes `{:reflaxe_elixir, ...}` as a dev/test dependency, you get:

- `mix compile.haxe`
- `mix haxe.watch`
- `mix haxe.errors`
- `mix haxe.source_map`

See: `docs/04-api-reference/MIX_TASKS.md`.

## Deployment

Haxe is required at **build time**, not runtime.

- Production checklist + CI/Docker notes: `docs/06-guides/PRODUCTION_DEPLOYMENT.md`
