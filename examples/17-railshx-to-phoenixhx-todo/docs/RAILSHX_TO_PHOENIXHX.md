# RailsHx To PhoenixHx Conversion Notes

This document records the conversion rules used by the PhoenixHx todo example.
It is intentionally didactic: a later deterministic conversion tool can reuse
the inventory and mapping, but this example does not introduce a Rails
compatibility layer for Phoenix.

## Crosswalk

| RailsHx source concept | PhoenixHx target concept | Notes |
| --- | --- | --- |
| `@:railsModel` ActiveRecord model | Ecto schema plus context boundary | This first slice uses in-memory LiveView state. The next persistence slice should add Haxe-authored Ecto schema, changeset, context, and migration. |
| ActiveRecord validation metadata | Ecto changeset validation | Phoenix validates at the data boundary instead of through Rails model callbacks. |
| `ParamsMacro.requirePermit` strong params | Changeset `cast` and explicit context input typedefs | Do not create fake strong-params APIs. |
| ActionController `index/create/update/destroy` | LiveView `mount`, `handleEvent`, and `render` for interactive screens | Controllers remain useful for non-LiveView edges such as session callbacks or APIs. |
| Devise/Warden session | Phoenix session controller plus LiveView `on_mount` | This slice uses a LiveView-local demo gate. Production auth should become a real Phoenix session flow. |
| HHX ERB template artifact | Inline HXX compiled to HEEx `~H` | New Phoenix examples should use inline markup, not legacy `hxx('...')` wrappers. |
| Rails partial locals | Function components or typed helper modules | Typed component/local ergonomics are a place to keep improving. |
| Rails route helpers | Phoenix router helpers or verified routes | If typed route helper coverage is too verbose, add an explicit app-local wrapper. |
| Turbo Stream broadcast | LiveView event diff and Phoenix PubSub | Turbo and LiveView both keep DOM updates server-owned, but their lifecycle models differ. |
| Turbo Frame island | Nested LiveView/component or normal live navigation | Do not emulate frame extraction unless the product needs that exact browser behavior. |
| Rails importmap/Turbo client code | Phoenix assets plus LiveView hooks compiled from Haxe through Genes | Client code should remain progressive, not duplicate server-rendered HTML. |
| Rails request/model tests | Haxe-authored ExUnit and thin Playwright smoke | Keep most behavior in ExUnit; keep browser tests small. |

## Implemented In This Slice

- The RailsHx login shell becomes a PhoenixHx LiveView demo gate.
- The RailsHx todo composer becomes a LiveView `phx-submit` form.
- The RailsHx open-work list becomes inline HXX rendered from LiveView assigns.
- Toggle and delete are LiveView events instead of Turbo Stream responses.
- The conversion notes are visible in the app so readers can compare framework ownership while using the UI.

## Remaining Work

1. Ecto persistence
   - Tracked by `haxe.elixir.codex-1fg.1`.
   - Add `Todo` and `User` schemas.
   - Add changesets and context functions.
   - Add Haxe-authored migrations.
   - Move create/toggle/delete from LiveView state into the context.

2. Production-shaped auth
   - Tracked by `haxe.elixir.codex-1fg.1`.
   - Replace the LiveView-local demo gate with a Phoenix session controller.
   - Add `on_mount` or equivalent LiveView auth assignment.
   - Keep the RailsHx Devise comparison in the docs.

3. Optional panels
   - Tracked by `haxe.elixir.codex-1fg.2`.
   - Port the RailsHx user-management island as a Phoenix LiveView component or route.
   - Port the chat panel with Phoenix PubSub/LiveView updates rather than Turbo Streams.

4. Deterministic conversion tooling seed
   - Tracked by `haxe.elixir.codex-1fg.3`.
   - Inventory RailsHx model/controller/view/route files.
   - Generate a report that maps each Rails artifact to a Phoenix target category.
   - Emit conservative Haxe stubs only for mappings with deterministic confidence.
   - Require human decisions for auth, background jobs, Turbo-specific interactions, and database behavior.

## Design Rule

The conversion should preserve product intent and Haxe type safety, not target API names. If a Rails API has no Phoenix equivalent, document the conceptual mapping and use the real Phoenix API.
