# RailsHx Todo To PhoenixHx Todo Example

Beads: `haxe.elixir.codex-1fg`

## Decision Summary

Create a new didactic example at `examples/17-railshx-to-phoenixhx-todo/` that ports the user-facing RailsHx todo app from [`reflaxe.ruby/examples/todoapp_rails`](https://github.com/fullofcaffeine/reflaxe.ruby/tree/main/examples/todoapp_rails) to a Phoenix/Reflaxe.Elixir app.

The example should preserve the RailsHx app's UX vocabulary, visual hierarchy, and core user journeys, but the implementation must be idiomatic Phoenix:

- LiveView and function components instead of Rails controllers plus ERB/Turbo partials.
- Ecto schemas, contexts, and changesets instead of ActiveRecord models and strong params.
- Phoenix router and route helpers instead of Rails route helpers.
- PubSub/LiveView updates instead of Turbo Streams for DOM mutation.
- Session-based demo auth/on-mount checks instead of Devise/Warden.
- Genes-compiled Haxe client hooks only for progressive browser behavior, not for duplicating server-rendered UI.

This is a learning example first and a future migration-tool seed second. It should document the conversion crosswalk carefully enough that a later deterministic RailsHx-to-PhoenixHx abstraction can reuse the concepts without pretending Rails and Phoenix have identical APIs.

## Source Reference

RailsHx source app:

- [`README.md`](https://github.com/fullofcaffeine/reflaxe.ruby/blob/main/examples/todoapp_rails/README.md)
- [`Main.hx`](https://github.com/fullofcaffeine/reflaxe.ruby/blob/main/examples/todoapp_rails/Main.hx)
- [`models/**`](https://github.com/fullofcaffeine/reflaxe.ruby/tree/main/examples/todoapp_rails/models)
- [`controllers/**`](https://github.com/fullofcaffeine/reflaxe.ruby/tree/main/examples/todoapp_rails/controllers)
- [`views/**`](https://github.com/fullofcaffeine/reflaxe.ruby/tree/main/examples/todoapp_rails/views)
- [`shared/TodoHooks.hx`](https://github.com/fullofcaffeine/reflaxe.ruby/blob/main/examples/todoapp_rails/shared/TodoHooks.hx)
- [`client/TodoClient.hx`](https://github.com/fullofcaffeine/reflaxe.ruby/blob/main/examples/todoapp_rails/client/TodoClient.hx)
- [`e2e/todoapp.spec.ts`](https://github.com/fullofcaffeine/reflaxe.ruby/blob/main/examples/todoapp_rails/e2e/todoapp.spec.ts)

Local Phoenix patterns to reuse:

- `examples/todo-app/` for full Phoenix app lifecycle, QA sentinel integration, Haxe-authored tests, Playwright, and LiveView conventions.
- `examples/13-elixir-first-liveview/` for compact LiveView example structure.
- `examples/15-phoenix-chat-haxe-first/` for Haxe-first Phoenix app/router/live/presence shape.

## Scope

The first complete slice should include:

1. A Phoenix app example that compiles from Haxe and runs independently.
2. RailsHx-inspired visual layout and interactions:
   - authenticated app chrome/top bar,
   - guest sign-in path,
   - todo composer,
   - todo list/cards,
   - empty state,
   - completion/toggle/delete flow,
   - user attribution where supported,
   - optional chat/user-management panels if they can be done without turning the task into a second full todo-app.
3. A `README.md` that links back to the public [`reflaxe.ruby/examples/todoapp_rails`](https://github.com/fullofcaffeine/reflaxe.ruby/tree/main/examples/todoapp_rails) source and explains the Rails-to-Phoenix mapping.
4. A conversion crosswalk doc, preferably `docs/RAILSHX_TO_PHOENIXHX.md` inside the example, with concrete source-to-source examples.
5. Haxe-authored Phoenix tests for the main flows, plus a thin Playwright smoke that asserts the preserved UX.
6. `examples/qa-manifest.json` entry with meaningful runtime/E2E coverage.

## Non-Goals

- Do not build a compatibility layer that makes Phoenix pretend to be Rails.
- Do not introduce fake Phoenix APIs or Rails-shaped Phoenix APIs.
- Do not use legacy `hxx('...')` / `HXX.hxx('...')` for new templates.
- Do not embed raw HEEx blocks in Haxe-authored templates.
- Do not copy generated Ruby, generated ERB, generated JS, or disposable Rails output.
- Do not broaden compiler behavior unless the example exposes a genuine missing Phoenix/Reflaxe.Elixir capability.

## RailsHx To PhoenixHx Crosswalk

| RailsHx concept | PhoenixHx implementation |
| --- | --- |
| `@:railsModel`, ActiveRecord columns, validations | `@:schema` / Ecto schema module, changeset function, context boundary |
| ActiveRecord relation scopes | Context query functions returning Ecto queries/results |
| Strong params via `ParamsMacro.requirePermit` | Ecto changeset casting/validation at the context boundary |
| `ActionController` actions | LiveView lifecycle and events for interactive UI; controller only for session or non-LiveView edges |
| Devise/Warden auth | Session controller + LiveView `on_mount`/assign checks; document where production auth would plug in |
| HHX ERB templates and partials | Inline HXX LiveView render functions and function components |
| `Routes.todosPath()` Rails helpers | Phoenix router path helpers or verified routes supported by current surface |
| Turbo Streams broadcast + server-rendered partial | Phoenix PubSub plus LiveView `handle_info`, or direct LiveView stream primitives if available |
| Turbo frame user-management island | LiveView component or nested live route; document the lifecycle difference |
| Rails importmap/Turbo client hook | Phoenix asset pipeline + LiveView hooks compiled from Haxe through Genes |
| Rails request/model tests | Haxe-authored ExUnit with ConnTest/LiveViewTest and Ecto assertions |
| Rails Playwright sentinel | Phoenix QA sentinel with Playwright spec |

## Implementation Phases

1. Inventory and UX contract
   - Read the RailsHx todo app sources and tests.
   - Capture the user journeys and selector/hook contract.
   - Decide the MVP surface: required todo/auth flows first; chat/user-management only if they fit the example budget.

2. Scaffold the new example
   - Create `examples/17-railshx-to-phoenixhx-todo/`.
   - Start from the smallest existing Phoenix example that already has LiveView, Ecto, assets, tests, and Haxe builds.
   - Keep generated outputs and checked-in artifacts consistent with the surrounding example policy.

3. Port domain and persistence
   - Port `Todo`, `User`, and optional `ChatMessage` into Ecto-shaped Haxe modules.
   - Add migrations and seed data equivalent to the RailsHx demo data.
   - Keep user-owned fields server-controlled; no spoofable hidden owner field.

4. Port routes/auth/session edges
   - Add Phoenix routes for home/todos, guest sign-in, logout, users/chat if included.
   - Implement session/demo auth with Phoenix conventions.
   - Document the Devise-to-Phoenix-auth difference explicitly.

5. Port UI as Phoenix LiveView/HXX
   - Preserve the RailsHx visual design and copy where appropriate.
   - Implement the main page as LiveView with inline HXX.
   - Extract function components for top bar, composer, summary, card/list, optional chat/user panel.
   - Use the RailsHx CSS as visual reference, adapted to Phoenix asset conventions.

6. Port progressive client behavior
   - Create Haxe shared hook constants mirroring `TodoHooks.hx`.
   - Compile Haxe client hooks via Genes.
   - Keep JS behavior progressive: focus, scroll/session form polish, status flashes. Do not duplicate server DOM rendering.

7. Tests and QA
   - Add Haxe-authored ExUnit coverage for route/session/LiveView CRUD flows.
   - Add Playwright smoke based on the RailsHx spec, importing generated/shared selectors if practical.
   - Add the example to `examples/qa-manifest.json`.
   - Add or update example docs/index references.

8. Documentation and future-tool notes
   - Write a rich README and conversion crosswalk.
   - Include a "future deterministic migration tool" section that separates:
     - deterministic inventory and mechanical mapping,
     - gaps requiring human decisions,
     - possible later Haxe abstractions.

## Expected Gaps To Validate

- LiveView stream/function-component ergonomics may not yet be as typed as RailsHx HHX partial locals.
- Phoenix route helper/verified route surface may need a small example-local wrapper if current typed externs are too verbose.
- Devise has no direct Phoenix equivalent. The example should teach the conceptual migration, not hide it.
- Turbo Streams and LiveView updates have different ownership models; the docs should make that difference explicit.
- If user-management/chat make the first task too broad, split them into follow-up Beads tasks after the todo/auth slice lands.

## Verification

Use bounded commands only.

- `npm run guard:examples-qa`
- `npm run test:examples`
- `npm run test:examples-output`
- `npm run test:examples-elixir`
- `npm run test:examples-runtime`
- New example sentinel/Playwright command, using `scripts/qa-sentinel.sh --async --deadline ...` if a Phoenix server is booted.
- For todo-app-adjacent runtime checks, use the QA sentinel only; do not run Phoenix foreground servers.

## Archive

Archived at: 2026-06-23

Completed by commits:

- `e290e3a06` Add PhoenixHx chat room to RailsHx todo port
- `9cbbab8c1` Use typed LiveView mount results in RailsHx tests
- `f0641ea4d` Add RailsHx port agent guide
- `909dbfd7e` Use portable RailsHx inventory source path
- `2abad0b29` Clarify RailsHx inventory scope

Beads:

- `haxe.elixir.codex-1fg`
- `haxe.elixir.codex-1fg.1`
- `haxe.elixir.codex-1fg.2`
- `haxe.elixir.codex-1fg.3`
