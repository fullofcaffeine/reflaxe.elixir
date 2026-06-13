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
| PubSub direct calls | `phoenix.PubSubShim`, partial `phoenix.Phoenix.PubSub` extern | chat examples | Needs std surface cleanup |
| Phoenix tests | `phoenix.test.ConnTest`, `phoenix.test.LiveViewTest`, `LiveViewTest.view/initial_html` | `examples/13-elixir-first-liveview/test_haxe` | Covered with typed result follow-up |
| Channels | `phoenix.Channel`, `phoenix.channels.*` | channel snapshots/docs | Covered, needs example-driven expansion only |
| App-owned infra modules | app-local `@:unsafeExtern` for Endpoint/PubSub/Telemetry/DNSCluster | Haxe-first chat + Elixir-first LiveView examples | Intentional boundary |

## Open Gaps

### P1: Replace PubSubShim With API-Faithful PubSub Helpers

Current pain:

- Chat examples use `phoenix.PubSubShim.subscribe/2` and `broadcast/3`.
- `PubSubShim` exists because direct calls through `phoenix.Phoenix.PubSub` previously printed as bare `PubSub.*` in some contexts.
- The shim intentionally uses `broadcast_from/4` to avoid the sending LiveView double-applying its own broadcast.

Target:

- Add a focused `std/phoenix/PubSub.hx` or repair `phoenix.Phoenix.PubSub` so app code can call API-faithful helpers directly.
- Include explicit surfaces for:
  - `subscribe(pubsub, topic)`
  - `subscribe(pubsub, topic, opts)`
  - `broadcast(pubsub, topic, message)`
  - `broadcast_from(pubsub, from, topic, message)`
  - `unsubscribe(pubsub, topic)`
- Preserve a small ergonomic helper only if it is clearly named as policy, for example `broadcastFromSelf`.

Required evidence:

- Snapshot proving fully-qualified `Phoenix.PubSub.*` emission.
- Update chat examples away from `PubSubShim`.
- Run `examples/12-phoenix-chat` sentinel with `--playwright --e2e-spec "e2e/presence.spec.ts"`.

### P1: Refresh Presence API Docs Around Topic-Aware Generated Helpers

Current pain:

- `PresenceBehavior.hx` and `docs/04-api-reference/PHOENIX_API_REFERENCE.md` under-describe the topic-aware helper shape now used by chat examples.
- Real usage relies on generated helpers such as `trackWithSocket(socket, topic, key, meta)`, `list(topic)`, and topic-aware `getByKey`.

Target:

- Update `PresenceBehavior.hx`, `Presence.hx`, and `PHOENIX_API_REFERENCE.md` to state the canonical app-facing patterns:
  - define a `@:presence` module
  - optionally set `@:presenceTopic("topic")`
  - from LiveViews, prefer generated module helpers (`ChatPresence.trackWithSocket(...)`, `ChatPresence.list(topic)`)
  - use raw `phoenix.Presence` extern only for lower-level interop
- Make old socket-only examples non-canonical or remove them.

Required evidence:

- Docs link guard.
- One existing Presence snapshot or chat sentinel run referenced in the close note.

### P2: Typed LiveViewTest Result Wrapper

Current pain:

- `LiveViewTest.live/2` correctly returns the Phoenix tuple as `Term`.
- Callers then use `LiveViewTest.view(result)` and `initial_html(result)` helpers.
- This avoids `Dynamic`, but still leaves tuple shape implicit.

Target:

- Add a typed result abstraction such as `LiveViewMountResult` or helper functions with clearer names and docs.
- Preserve API faithfulness: Phoenix still returns `{:ok, view, html}`; the wrapper only decodes the tuple for Haxe tests.

Required evidence:

- Haxe-authored ExUnit test in `examples/13-elixir-first-liveview` or a snapshot that uses the wrapper.
- `npm run test:mix-fast` or focused example test gate.

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
