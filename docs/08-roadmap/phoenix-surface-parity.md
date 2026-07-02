# Phoenix Surface Parity Checklist

This checklist tracks Phoenix/PubSub/Presence/LiveView API gaps discovered from real examples and tutorials. It is intentionally example-driven: add a gap here only when an app, guide, generator, or test needs the surface.

Canonical examples that drive this list:

- `examples/12-phoenix-chat/` - hybrid LiveView + Presence + PubSub adoption
- `examples/13-elixir-first-liveview/` - Elixir-first LiveView, typed test helpers, app-local externs
- `examples/15-phoenix-chat-haxe-first/` - Haxe-authored app/router/live/presence server path
- `examples/17-railshx-to-phoenixhx-todo/` - RailsHx-inspired UX port implemented with Phoenix-native LiveView, Ecto, PubSub, and session patterns
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
| RailsHx-to-PhoenixHx learning port | Phoenix-native LiveView/Ecto/PubSub/session implementation of a RailsHx-inspired UX | `examples/17-railshx-to-phoenixhx-todo/` | Covered, with follow-up parity tasks below |

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

### Done: Typed LiveViewTest Assign/Event Tokens

Implemented:

- `std/phoenix/test/LiveViewEventName.hx` adds an erased typed token for app-owned LiveView event names.
- `LiveViewTest.get_assign_key` and `LiveViewTest.has_assign_key` reuse `AssignKey<TAssigns, TValue>` from `AssignKeys.of(...)`.
- `LiveViewTest.render_click_event`, `render_submit_event`, and `render_change_event` accept typed event-name tokens and emit ordinary Phoenix `render_*` calls.
- Raw string APIs remain available for CSS selectors, paths, and direct Phoenix parity.

Evidence:

- `make -C test single TEST=phoenix/liveview_test_typed_tokens`

### Done: LiveView Components And Streams From RailsHx Port

Tracked by `haxe.elixir-944.2.7`.

The RailsHx-inspired todo port kept the product surface comparable while using
one Phoenix LiveView render function and assign-backed lists. Phoenix itself
usually reaches for function components with attrs/slots and, for mutable lists,
`stream/3` plus `phx-update="stream"`.

Decision:

- No Rails partial or Turbo compatibility API was added.
- The existing Phoenix-shaped component surface (`@:component`, attrs/assigns, slots, and inline HXX)
  remains the right API; no new component DSL was needed.
- Added typed LiveView stream-name tokens with `phoenix.LiveStreams.of(MyAssigns)`.
- Added `Socket<T>` and `LiveSocket<T>` helpers for `stream`, `streamInsert`, and `streamDelete`.
- Raw `Phoenix.LiveView.stream*` extern calls remain available for direct interop and older code.

Evidence:

- `std/phoenix/LiveStreams.hx`
- `std/phoenix/types/LiveStreamName.hx`
- `std/phoenix/macros/LiveStreamMacro.hx`
- `test/snapshot/phoenix/liveview_stream_tokens`

### Done: on_mount, live_session, Forms, And Changesets From RailsHx Port

Tracked by `haxe.elixir-944.2.8`.

The RailsHx-inspired todo port used Phoenix session controller + `live_session`
MFA wiring and raw LiveView form events. That is valid Phoenix, but the Haxe
layer now makes the Phoenix-native path easier to express:

- `RouterDsl.onMount(...)` and `RouterDsl.onMountArg(...)` emit real Phoenix
  `on_mount:` live-session options.
- `phoenix.LiveSession.fromConnKeys(...)` builds string-keyed LiveView session
  maps from selected Plug session keys.
- `phoenix.Component.toForm(...)`, `toFormParams(...)`, and
  `phoenix.ToFormOptions.build(...)` call real `Phoenix.Component.to_form/1,2`
  with keyword options.
- `examples/17-railshx-to-phoenixhx-todo` now uses the shared LiveSession
  handoff helper instead of app-local map assembly.

Non-goals:

- no Devise/Warden emulation
- no Rails strong-params API
- no auth compatibility layer hidden inside Reflaxe.Elixir

Evidence:

- `test/snapshot/phoenix/live_session_form_surface`

### P3: Review Legacy todo-app After RailsHx Port

Tracked by `haxe.elixir-944.2.6`.

Review `examples/todo-app/` after the RailsHx-to-PhoenixHx learning port and
look for improvements that should flow back into the older production-shaped
sentinel app:

- typed LiveView/session/form/list APIs that reduce app code
- test and Playwright selector improvements
- docs updates that clarify the difference between the learning port and the
  sentinel app

Do not change `todo-app` UI/UX unless the justification is explicit and
documented before implementation. Do not merge the examples, copy Rails-shaped
APIs into `todo-app`, or weaken the sentinel role of `examples/todo-app/`.
Implement type/API improvements in atomic commits with clear descriptions.

Progress:

- `examples/todo-app` now uses explicit router `live_session` MFA wiring with
  `TodoAppWeb.live_session/1`.
- `TodoAppWeb.live_session/1` uses the shared `phoenix.LiveSession.fromConnKeys`
  helper instead of hand-building a LiveView session map.
- LiveViews now call the app-owned `TodoAppWeb.sessionUserId(session)` helper
  instead of repeating session-map parsing locally.
- UI/UX was intentionally left unchanged.

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
3. Create or update a task with acceptance criteria.
4. Add coverage before closing the task.
