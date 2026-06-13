# Phoenix Surface Parity Checklist

This checklist tracks Phoenix/PubSub/Presence/LiveView API gaps discovered from real examples and tutorials. It is intentionally example-driven: add a gap here only when an app, guide, generator, or test needs the surface.

Canonical examples that drive this list:

- `examples/12-phoenix-chat/` - hybrid LiveView + Presence + PubSub adoption
- `examples/13-elixir-first-liveview/` - Elixir-first LiveView, typed test helpers, app-local externs
- `examples/15-phoenix-chat-haxe-first/` - Haxe-authored app/router/live/presence server path
- `examples/todo-app/` - production-shaped LiveView/Ecto app

## Policy

Use this decision rule for every Phoenix surface addition:

1. Prefer an existing `std/phoenix/**` or `std/ecto/**` typed surface.
2. If the API is reusable and maps cleanly to Phoenix, add an API-faithful extern or wrapper under `std/phoenix/**`.
3. If the module is app-owned Phoenix infrastructure (`MyAppWeb.Endpoint`, `MyApp.PubSub`, `MyAppWeb.Telemetry`, `DNSCluster`), keep a tiny app-local `@:unsafeExtern` marker. That is an intentional boundary, not a stdlib gap.
4. If an app needs a temporary bridge, isolate it in a framework helper with tests. Do not put `__elixir__()` in app code.
5. Every new surface needs one of: snapshot coverage, Haxe-authored ExUnit coverage, or example/E2E coverage.

## Current Coverage

| Area | Current surface | Evidence | Status |
| --- | --- | --- | --- |
| LiveView callbacks | `@:liveview`, `MountResult`, `HandleEventResult`, `HandleInfoResult`, `Socket<TAssigns>` | `examples/todo-app`, `examples/12-phoenix-chat`, `examples/13-elixir-first-liveview`, `examples/15-phoenix-chat-haxe-first` | Covered |
| Assign helpers | `Socket<T>.assign`, `assignKey`, `assignNew`, `update`; `LiveSocket<T>` wrapper | `docs/04-api-reference/LIVE_SOCKET_ASSIGN_API.md`, todo/chat examples | Covered |
| HXX/HEEx templates | inline markup, `HeexTemplate`, strict raw-HEEx guard | HXX snapshots, examples, CI guard | Covered |
| Router DSL | module-level `@:router`, `RouterDsl.*` nodes | `examples/09-phoenix-router`, `examples/13-elixir-first-liveview`, `examples/15-phoenix-chat-haxe-first` | Covered with UX follow-up |
| Presence module generation | `@:presence`, `PresenceBehavior`, `@:presenceTopic`, generated `list/getByKey/*WithSocket` helpers | chat examples + Presence E2E | Covered with docs/API drift follow-up |
| PubSub direct calls | `phoenix.PubSub` API-faithful extern | `test/snapshot/phoenix/pubsub_api_faithful`, chat examples | Covered |
| Phoenix tests | `phoenix.test.ConnTest`, `phoenix.test.LiveViewTest`, `LiveViewTest.view/initial_html` | `examples/13-elixir-first-liveview/test_haxe` | Covered with typed result follow-up |
| Channels | `phoenix.Channel`, `phoenix.channels.*` | channel snapshots/docs | Covered, needs example-driven expansion only |
| App-owned infra modules | app-local `@:unsafeExtern` for Endpoint/PubSub/Telemetry/DNSCluster | Haxe-first chat + Elixir-first LiveView examples | Intentional boundary |

## Open Gaps

### Done: Replace PubSubShim With API-Faithful PubSub Helpers

Implemented:

- `std/phoenix/PubSub.hx` provides direct typed externs for Phoenix.PubSub.
- Chat and todo examples use `phoenix.PubSub` instead of `phoenix.PubSubShim`.
- Chat and todo preserve sender exclusion with `PubSub.broadcastFrom(pubsub, Kernel.self(), topic, message)`.
- A final AST rewrite normalizes bare `PubSub.*` call nodes to fully-qualified `Phoenix.PubSub.*`.

Available surfaces:

- `subscribe(pubsub, topic)`
- `subscribeWithOptions(pubsub, topic, opts)` → `Phoenix.PubSub.subscribe/3`
- `broadcast(pubsub, topic, message)`
- `broadcastFrom(pubsub, from, topic, message)` → `Phoenix.PubSub.broadcast_from/4`
- `unsubscribe(pubsub, topic)`

Evidence:

- `test/snapshot/phoenix/pubsub_api_faithful` proves fully-qualified `Phoenix.PubSub.*` emission.
- Chat examples no longer import `PubSubShim`.
- Runtime evidence: `examples/12-phoenix-chat` sentinel passed with `--playwright --e2e-spec "e2e/presence.spec.ts"`.

### Done: Refresh Presence API Docs Around Topic-Aware Generated Helpers

Implemented:

- `PresenceBehavior.hx`, `Presence.hx`, and `PHOENIX_API_REFERENCE.md` now describe the canonical app-facing pattern:
  - define a `@:presence` module implementing `PresenceBehavior`
  - optionally set `@:presenceTopic("topic")` for fixed-topic helpers
  - from LiveViews, prefer generated module helpers such as `ChatPresence.trackWithSocket(socket, topic, key, meta)`, `ChatPresence.list(topic)`, and `ChatPresence.getByKey(topic, key)`
  - use raw `phoenix.Presence` only for lower-level interop
- `ANNOTATIONS.md` no longer teaches old socket-only Presence examples as the main path.
- `PresenceModule.hx` is marked as a legacy helper, with `PresenceBehavior` documented as the preferred API.

Evidence:

- `npm run guard:docs-links`
- `make -C test single TEST=phoenix/PresenceNativeRegression`

### Done: Typed LiveViewTest Result Wrapper

Implemented:

- `std/phoenix/test/LiveViewMountResult.hx` wraps Phoenix's raw `{:ok, view, html}` tuple as a `Term` abstract.
- `LiveViewTest.live/2` now returns `LiveViewMountResult`, preserving raw `Term` compatibility via `from Term` / `to Term`.
- Haxe-authored tests can use `result.view()` and `result.initialHtml()` instead of tuple-position helpers.
- Existing raw helpers `LiveViewTest.view(result)` and `LiveViewTest.initial_html(result)` remain available for compatibility.
- `examples/13-elixir-first-liveview/test_haxe/web/SearchLiveIntegrationTest.hx` exercises the typed wrapper in a Haxe-authored ExUnit integration test.

Evidence:

- `haxe build-tests.hxml` from `examples/13-elixir-first-liveview`
- `MIX_ENV=test mix test` from `examples/13-elixir-first-liveview`
- `npm run guard:docs-links`
- `npm run test:mix-fast`

### P2: Router DSL UX Follow-Ups

Tracked separately by `haxe.elixir-944.10`.

Keep router work out of this checklist unless a tutorial/example discovers a missing Phoenix route primitive.

## Intentional Non-Gaps

- App-local `@:unsafeExtern extern class Endpoint {}` is expected for hand-written Phoenix infrastructure modules.
- App-local `@:unsafeExtern extern class PubSub {}` is expected when representing the app's named PubSub server module as a child spec.
- `Term` is acceptable at Phoenix boundaries where Phoenix itself returns open runtime shapes; prefer typed decoding immediately after the boundary.
- Playwright remains a thin browser smoke layer; most Phoenix behavior should be covered by Haxe-authored ExUnit/ConnTest/LiveViewTest.

## How to Add a New Gap

When a tutorial or example needs a missing Phoenix API:

1. Add a row to **Open Gaps** with the exact app/doc that needs it.
2. State whether the fix belongs in `std/phoenix/**`, an app-local extern, a compiler transform, or docs only.
3. Create or update a bead task with acceptance criteria.
4. Add coverage before closing the task.
