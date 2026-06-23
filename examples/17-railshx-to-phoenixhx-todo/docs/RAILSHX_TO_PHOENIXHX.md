# RailsHx To PhoenixHx Conversion Notes

This document records the conversion rules used by the PhoenixHx todo example.
It is intentionally didactic: a later deterministic conversion tool can reuse
the inventory and mapping, but this example does not introduce a Rails
compatibility layer for Phoenix.

## Crosswalk

| RailsHx source concept | PhoenixHx target concept | Notes |
| --- | --- | --- |
| `@:railsModel` ActiveRecord model | Ecto schema plus context boundary | This slice uses Haxe-authored `User`/`Todo` schemas, changesets, context functions, Repo, and migrations. |
| ActiveRecord validation metadata | Ecto changeset validation | Phoenix validates at the data boundary instead of through Rails model callbacks. |
| `ParamsMacro.requirePermit` strong params | Changeset `cast` and explicit context input typedefs | Do not create fake strong-params APIs. |
| ActionController `index/create/update/destroy` | LiveView `mount`, `handleEvent`, and `render` for interactive screens | Controllers remain useful for non-LiveView edges such as session callbacks or APIs. |
| Devise/Warden session | Phoenix session controller plus LiveView session MFA | The router uses `liveSessionMfa(...)` to pass `{PhoenixHxTodoWeb.LiveSession, :live_session, []}` to Phoenix. A richer `on_mount` facade remains a good future API. |
| HHX ERB template artifact | Inline HXX compiled to HEEx `~H` | New Phoenix examples should use inline markup, not legacy `hxx('...')` wrappers. |
| Rails partial locals | Function components or typed helper modules | Typed component/local ergonomics are a place to keep improving. |
| Rails route helpers | Phoenix router helpers or verified routes | If typed route helper coverage is too verbose, add an explicit app-local wrapper. |
| Turbo Stream broadcast | LiveView event diff and Phoenix PubSub | Turbo and LiveView both keep DOM updates server-owned, but their lifecycle models differ. |
| Turbo Frame island | Nested LiveView/component or normal live navigation | Do not emulate frame extraction unless the product needs that exact browser behavior. |
| Rails importmap/Turbo client code | Phoenix assets plus LiveView hooks compiled from Haxe through Genes | Client code should remain progressive, not duplicate server-rendered HTML. |
| Rails request/model tests | Haxe-authored ExUnit and thin Playwright smoke | Keep most behavior in ExUnit; keep browser tests small. |

## Implemented In This Slice

- The RailsHx login shell becomes a Phoenix session controller plus LiveView session handoff.
- The RailsHx todo composer becomes a LiveView `phx-submit` form.
- The RailsHx open-work list becomes inline HXX rendered from Ecto-backed LiveView assigns.
- Create, toggle, and delete are LiveView events that call the `Todos` context instead of Turbo Stream responses.
- The conversion notes are visible in the app so readers can compare framework ownership while using the UI.
- `liveSessionMfa(module, functionName)` was added to the router DSL so typed Haxe can express Phoenix's session MFA tuple without raw Elixir.

## Remaining Work

1. Optional panels
   - Tracked by `haxe.elixir.codex-1fg.2`.
   - Port the RailsHx user-management island as a Phoenix LiveView component or route.
   - Port the chat panel with Phoenix PubSub/LiveView updates rather than Turbo Streams.

2. Deterministic conversion tooling seed
   - Tracked by `haxe.elixir.codex-1fg.3`.
   - Inventory RailsHx model/controller/view/route files.
   - Generate a report that maps each Rails artifact to a Phoenix target category.
   - Emit conservative Haxe stubs only for mappings with deterministic confidence.
   - Require human decisions for auth, background jobs, Turbo-specific interactions, and database behavior.

3. General PhoenixHx API opportunities
   - Add a typed `on_mount` facade when a second app needs shared LiveView auth assignment.
   - Reduce generated ExUnit dependency emission for app-backed test modules so test helpers can stay quiet by default.
   - Keep command-style context APIs returning precise success types (`Bool` for simple commands, `Result` when UI needs changeset details).

## Design Rule

The conversion should preserve product intent and Haxe type safety, not target API names. If a Rails API has no Phoenix equivalent, document the conceptual mapping and use the real Phoenix API.
