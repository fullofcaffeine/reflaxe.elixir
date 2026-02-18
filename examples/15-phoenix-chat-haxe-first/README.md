# 15 - Phoenix Chat (Haxe-First)

Realtime chat example where the server module source-of-truth is Haxe, compiled to Phoenix LiveView + Presence.

This example is the Haxe-first counterpart to `examples/12-phoenix-chat/`:
- `12-phoenix-chat`: hybrid adoption shape (feature logic in Haxe, core Phoenix wiring hand-authored Elixir)
- `15-phoenix-chat-haxe-first`: app/router/live/presence authored in Haxe

## What this example covers

- `@:application` supervision tree authored in Haxe
- `@:router` module-level typed routes authored in Haxe
- `@:liveview` callbacks and render in Haxe
- `@:presence` module in Haxe
- Haxe->JS client hook (`AutoScroll`) for LiveView
- TSX-style HXX templates (`-D hxx_mode=tsx`)

## Run

```bash
cd examples/15-phoenix-chat-haxe-first
mix setup
mix phx.server
```

Open `http://localhost:4000`.

## Tests

```bash
cd examples/15-phoenix-chat-haxe-first
mix test
```

The example includes a Haxe-authored ExUnit test:
- `examples/15-phoenix-chat-haxe-first/src_haxe/test/live/ChatStateTest.hx`

## Source-of-truth split

### Haxe-authored server modules

- `examples/15-phoenix-chat-haxe-first/src_haxe/PhoenixChat.hx`
  - `@:application` supervision tree (`PhoenixChat.Application`)
- `examples/15-phoenix-chat-haxe-first/src_haxe/PhoenixChatRouter.hx`
  - `@:router` module-level route DSL (`PhoenixChatWeb.Router`)
- `examples/15-phoenix-chat-haxe-first/src_haxe/phoenix_chat_hx/live/AppLive.hx`
  - `@:liveview` callbacks + render (`PhoenixChatWeb.AppLive`)
- `examples/15-phoenix-chat-haxe-first/src_haxe/phoenix_chat_hx/presence/ChatPresence.hx`
  - `@:presence` module (`PhoenixChatWeb.Presence`)

### Elixir modules that still make sense to keep in Elixir

- Phoenix config/runtime wiring:
  - `examples/15-phoenix-chat-haxe-first/config/*.exs`
- Phoenix web infrastructure scaffold:
  - `examples/15-phoenix-chat-haxe-first/lib/phoenix_chat_web/endpoint.ex`
  - `examples/15-phoenix-chat-haxe-first/lib/phoenix_chat_web.ex`
  - `examples/15-phoenix-chat-haxe-first/lib/phoenix_chat_web/components/**`

Why this split exists: Phoenix project/config conventions are already Elixir-native and stable, while app behavior and framework modules can be type-checked and authored in Haxe.

## Key Haxe snippets

Application (`@:application`):

```haxe
@:application
@:appName("PhoenixChat")
class PhoenixChat {
  public static function start(type: ApplicationStartType, args: ApplicationArgs): ApplicationResult {
    var children:Array<ChildSpecFormat> = [
      TypeSafeChildSpec.telemetry("PhoenixChatWeb.Telemetry"),
      ModuleWithConfig("DNSCluster", [{key: "query", value: dnsClusterQuery}]),
      TypeSafeChildSpec.pubSub("PhoenixChat.PubSub"),
      ModuleRef("PhoenixChatWeb.Presence"),
      TypeSafeChildSpec.endpoint("PhoenixChatWeb.Endpoint")
    ];
    return SupervisorExtern.startLink(children, options);
  }
}
```

Router (`@:router` module-level field):

```haxe
import reflaxe.elixir.macros.RouterDsl.*;

@:native("PhoenixChatWeb.Router")
@:router
final routes = [
  pipeline("browser", [
    plug("accepts", {initArgs: ["html"]}),
    plug("fetch_session"),
    plug("fetch_live_flash"),
    plug("protect_from_forgery"),
    plug("put_secure_browser_headers")
  ]),
  scope("/", [
    pipeThrough(["browser"]),
    liveSession("default", [live("/", AppLive)])
  ])
];
```

Note: live routes can omit actions (`live("/", AppLive)`), which keeps LiveView modules free of placeholder `index/show/edit` methods when you do not need route-action dispatch.

## Build configuration

- `examples/15-phoenix-chat-haxe-first/build.hxml`
  - `-D elixir_output=lib` so Haxe-generated server modules land in standard Phoenix `lib/**` paths.
  - Includes app + router + live/presence modules in the compile roots.

## Related docs

- Haxe-first walkthrough: `docs/06-guides/PHOENIX_CHAT_TUTORIAL_HAXE_FIRST.md`
- Hybrid walkthrough: `docs/06-guides/PHOENIX_CHAT_TUTORIAL.md`
- New app setup: `docs/06-guides/PHOENIX_NEW_APP.md`
