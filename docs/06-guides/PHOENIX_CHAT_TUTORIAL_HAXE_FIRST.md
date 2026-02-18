# Phoenix Chat Tutorial (Haxe-First Server)

This tutorial shows a Haxe-first Phoenix chat app:

- supervision tree in Haxe (`@:application`)
- router in Haxe (`@:router` + module-level `final routes`)
- LiveView + Presence in Haxe
- tiny client hook in Haxe (Genes -> JS)

Reference implementation: `examples/15-phoenix-chat-haxe-first/`.

If you want gradual adoption (keep app/router in Elixir first), use:
`docs/06-guides/PHOENIX_CHAT_TUTORIAL.md`.

## Why this tutorial exists

Some teams want server behavior source-of-truth in Haxe from day one, while still running a normal Phoenix app.
This guide shows that path without hiding Phoenix conventions.

## Prerequisites

- Elixir + Phoenix installed
- Node installed (assets/watchers)
- Haxe toolchain (lix recommended)

## 1) Create a baseline Phoenix app

```bash
mix phx.new phoenix_chat
cd phoenix_chat
mix setup
mix phx.server
```

Confirm `http://localhost:4000` loads, then stop the server.

## 2) Add Reflaxe.Elixir and scaffold Haxe integration

In `mix.exs`, add:

```elixir
{:reflaxe_elixir, github: "fullofcaffeine/reflaxe.elixir", tag: "<RELEASE_TAG>", only: [:dev, :test], runtime: false}
```

Then run:

```bash
mix deps.get
mix haxe.gen.project --phoenix --basic-modules --force
mix haxe.phoenix.scaffold
```

What this gives you:
- server compile pipeline (`build.hxml`, `src_haxe/**`, Mix `:haxe` compiler)
- client hook pipeline (`build-client.hxml`, `assets/js/hx_app.js`, watcher wiring)

## 3) Move the application supervision tree to Haxe

Create `src_haxe/PhoenixChat.hx`:

```haxe
package;

import elixir.Atom;
import elixir.otp.Application;
import elixir.otp.Supervisor.ChildSpecFormat;
import elixir.otp.Supervisor.SupervisorExtern;
import elixir.otp.Supervisor.SupervisorOptions;
import elixir.otp.Supervisor.SupervisorStrategy;
import elixir.otp.TypeSafeChildSpec;

@:application
@:appName("PhoenixChat")
class PhoenixChat {
  @:keep
  public static function start(type: ApplicationStartType, args: ApplicationArgs): ApplicationResult {
    var dnsClusterQuery = elixir.Application.get_env(
      Atom.create("phoenix_chat"),
      Atom.create("dns_cluster_query"),
      Atom.create("ignore")
    );

    var children:Array<ChildSpecFormat> = [
      TypeSafeChildSpec.telemetry("PhoenixChatWeb.Telemetry"),
      ModuleWithConfig("DNSCluster", [{key: "query", value: dnsClusterQuery}]),
      TypeSafeChildSpec.pubSub("PhoenixChat.PubSub"),
      ModuleRef("PhoenixChatWeb.Presence"),
      TypeSafeChildSpec.endpoint("PhoenixChatWeb.Endpoint")
    ];

    final options:SupervisorOptions = {
      strategy: SupervisorStrategy.OneForOne,
      max_restarts: 3,
      max_seconds: 5
    };

    return SupervisorExtern.startLink(children, options);
  }
}
```

## 4) Move router definition to Haxe

Create `src_haxe/PhoenixChatRouter.hx`:

```haxe
package;

import phoenix_chat_hx.live.AppLive;
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

Why this shape: Phoenix routers are nested (`pipeline`, `scope`, `live_session`), so the module-level DSL mirrors real Phoenix router structure while keeping route/module/action references typed.

Note: `live("/", AppLive)` intentionally omits an action. Phoenix supports this directly, so you do not need placeholder `index()` methods just for routing.

## 5) Author Presence + LiveView in Haxe

Presence module:
- `src_haxe/phoenix_chat_hx/presence/ChatPresence.hx`

LiveView module:
- `src_haxe/phoenix_chat_hx/live/AppLive.hx`

Both compile to normal Phoenix modules:
- `PhoenixChatWeb.Presence`
- `PhoenixChatWeb.AppLive`

## 6) Compile output to standard Phoenix `lib/**`

Use `build.hxml`:

```hxml
-D elixir_output=lib
-D app_name=PhoenixChat
```

Why this matters: generated server modules land where Phoenix expects them (`lib/phoenix_chat/**`, `lib/phoenix_chat_web/**`), so `mix compile` and runtime boot remain conventional.

## 7) What still stays in Elixir

Even in a Haxe-first server setup, it is normal to keep:
- `config/*.exs` (runtime env/deploy config)
- `mix.exs` (project/dependency/build tool wiring)
- base web infra modules from Phoenix scaffolding (endpoint/web helpers/layout wrappers)

This is not a limitation; it keeps Phoenix-native operational surfaces where Phoenix developers expect them.

## 8) Run and verify

```bash
mix setup
mix phx.server
```

Manual smoke:
1. open two browser windows on `/`
2. both windows show online count `2`
3. send a message in one window
4. message appears in the other window

## 9) QA sentinel (bounded, non-blocking)

From repo root:

```bash
scripts/qa-sentinel.sh --app examples/15-phoenix-chat-haxe-first --port 4015 --async --deadline 600 -v
scripts/qa-logpeek.sh --run-id <RUN_ID> --until-done 120
```

## Where to go next

- Hybrid/gradual counterpart: `docs/06-guides/PHOENIX_CHAT_TUTORIAL.md`
- Reference example: `examples/15-phoenix-chat-haxe-first/README.md`
- Router DSL details: `docs/04-api-reference/ROUTER_DSL.md`
