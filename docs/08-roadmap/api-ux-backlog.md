# API UX Backlog

This audit tracks developer ergonomics papercuts across Phoenix, Ecto, and general interop APIs. The goal is not to hide Elixir; it is to make the Haxe authoring surface hard to misuse while still emitting idiomatic Elixir/Phoenix/Ecto shapes.

## Decision Principles

- Prefer typed handles over raw strings for finite or schema-derived names.
- Keep Phoenix/Ecto API faithfulness in the generated Elixir; improve Haxe authoring with typed overloads, helpers, and clearer diagnostics.
- Make unsafe/dynamic paths explicit with `*Unsafe`, metadata, or strict-mode escape hatches.
- Add compile-time suggestions where the compiler can infer the intended fix.
- Keep examples on the recommended path first; show compatibility paths only in migration sections.
- Do not add broad profiles for local choices. Use orthogonal metadata/defines only when a compiler check needs a stable switch.

## Top Follow-Up Tasks

These are the immediate follow-ups selected from the audit:

| Priority | Area | Task | Why first |
| --- | --- | --- | --- |
| 1 | Ecto | `haxe.elixir-944.14` - typed schema field tokens for changeset APIs | Highest repeated papercut: raw field strings appear in validation-heavy code and are easy to mistype during refactors. |
| 2 | Phoenix | `haxe.elixir-944.15` - reduce LiveView callback naming boilerplate | A common first-app footgun: Haxe-friendly callback names still need `@:native("handle_event")` in several examples. |
| 3 | Interop | `haxe.elixir-944.16` - app-local extern boundary scaffold/checklist | Existing guidance is sound, but users still have to hand-roll the same `@:native`/`@:unsafeExtern extern class` wrapper pattern. |

## Prioritized Papercuts

| Rank | Area | Location | Pain | Proposal | Impact / Effort |
| --- | --- | --- | --- | --- | --- |
| 1 | Ecto changesets | `std/ecto/Field.hx`, `std/ecto/Changeset.hx`, `docs/04-api-reference/ANNOTATIONS.md` | `castFields`, `validateRequired`, `validateLength`, `validateFormat`, and related APIs still lower through the string-compatible changeset surface. `Field.of((schema) -> schema.field)` now covers typo/refactor safety, but full first-class token overloads and cleaner atom-list lowering remain open. Follow-up: `haxe.elixir-958`. | Build on `Field.of` with first-class typed field tokens/overloads when the changeset abstract lowering is ready. Keep string compatibility clearly documented for dynamic/migration cases. | High / Medium |
| 2 | Phoenix LiveView | `std/phoenix/Phoenix.hx`, `docs/04-api-reference/PHOENIX_API_REFERENCE.md`, `docs/04-api-reference/ANNOTATIONS.md` | Users writing Haxe-style callback names such as `handleEvent` must remember `@:native("handle_event")`. Missing metadata compiles to the wrong callback name rather than feeling Phoenix-native. | Add `@:liveview` callback normalization or diagnostics for known callback names: `handleEvent`, `handleInfo`, `handleParams`, `handleAsync`, etc. Prefer auto-normalization only for exact known callbacks; otherwise emit a suggestion. | High / Medium |
| 3 | Interop tooling | `docs/02-user-guide/INTEROP_WITH_EXISTING_ELIXIR.md`, `docs/04-api-reference/TYPE_SAFE_CHILD_SPEC.md`, `std/elixir/otp/TypeSafeChildSpec.hx` | App-owned Elixir modules need tiny extern wrappers, often with `@:unsafeExtern` in strict contexts. The pattern is repetitive and easy to forget. | Add a documented scaffold helper or Mix task that creates minimal typed extern boundaries, plus strict-mode diagnostics that suggest the exact wrapper shape. | High / Low-Medium |
| 4 | Ecto associations/query | `std/ecto/TypedQuery.hx`, `std/ecto/Repository.hx` | `join(association:String, ...)`, `preload(Array<String>)`, and `Repo.preload(..., Term)` are still stringly typed even though associations are declared on schemas. | Add association tokens derived from schema metadata, for example `TodoAssociations.user`, and overload `join`/`preload`/`Repo.preload`. Keep string APIs as compatibility paths. | High / Medium-High |
| 5 | Router resources | `src/reflaxe/elixir/macros/RouterDsl.hx`, `docs/04-api-reference/ROUTER_DSL.md` | `ResourceOptions.only` and `except` are `Array<String>` even though Phoenix resource actions are finite. | Add a `ResourceAction` enum abstract and overload options to accept `Array<ResourceAction>`. Keep `Array<String>` only as `resourcesUnsafe` or compatibility input. | Medium / Low |
| 6 | Router path params | `docs/04-api-reference/ROUTER_DSL.md`, `src/reflaxe/elixir/macros/RouterDsl.hx` | Routes with path params require a manual `paramsContract`. The current error is useful, but users still have to discover the typedef shape. | Improve diagnostics to print a suggested typedef skeleton for missing params, e.g. `typedef UserPathParams = { var id:Int; }`, and link to the router guide. | Medium / Low |
| 7 | Presence topics/keys | `std/phoenix/Presence.hx`, `std/phoenix/PresenceBehavior.hx`, `docs/04-api-reference/PHOENIX_API_REFERENCE.md` | Topics and keys are raw strings across generated Presence helpers. Dynamic topics are real, but common fixed topics could be typed. | Add lightweight `PresenceTopic` / `PresenceKey` constructors and generated fixed-topic helpers when `@:presenceTopic` is present. | Medium / Medium |
| 8 | HXX mode metadata | `docs/04-api-reference/ANNOTATIONS.md`, `docs/02-user-guide/HXX_SYNTAX_AND_COMPARISON.md` | `@:hxx_mode("balanced"|"tsx"|"metal")` is powerful but easy to confuse with application portability profiles. | Keep TSX inline markup as the default, move mode metadata deeper into migration docs, and make warnings explicitly say "template mode, not app profile." | Medium / Low |
| 9 | Term boundary decoding | `std/elixir/types/Term.hx`, `std/elixir/types/TermDecoder.hx`, interop docs | `Term` is the right opaque boundary, but callsites often need repeated manual decoding after Phoenix/Elixir APIs return open shapes. | Expand `TermDecoder` recipes and add small typed decoder helpers for common Phoenix/Ecto return shapes. Prefer local decoding immediately after boundaries. | Medium / Medium |
| 10 | LiveView testing strings | `std/phoenix/test/LiveViewTest.hx`, `std/phoenix/test/ConnTest.hx` | Test helpers still use string keys/events/selectors for assigns and LiveView events. This mirrors Phoenix, but Haxe tests can do better for app-owned keys/events. | Add optional typed assign/event key helpers that compose with existing raw Phoenix test calls. Keep string APIs because Phoenix selectors remain inherently textual. | Medium / Medium |
| 11 | Ecto validation option naming | `std/ecto/Changeset.hx`, `docs/04-api-reference/ECTO_API_REFERENCE.md` | Some Haxe option names (`min`, `max`) are ergonomic but obscure the exact Ecto option emitted (`greater_than_or_equal_to`, `less_than_or_equal_to`). | Provide Ecto-faithful option typedefs plus short aliases. Docs should show emitted Ecto names next to the Haxe shorthand. | Medium / Low |
| 12 | Query escape hatches | `std/ecto/TypedQuery.hx` | `whereRaw` and `orderByRaw` are useful, but the safe/unsafe boundary is not as visually obvious as router/child-spec `*Unsafe`. | Rename/add aliases such as `whereUnsafeRaw` and `orderByUnsafeRaw`, keep old names as compatibility aliases with docs nudging toward the explicit form. | Low-Medium / Low |

## Follow-Up Task Acceptance Template

Use this for each implementation bead created from the backlog:

- Add or update the typed API without removing the current compatibility surface.
- If a raw/dynamic path remains, name it or document it as an explicit migration/unsafe path.
- Update the deep API reference, examples, and any first-use docs.
- Add compile-time or snapshot coverage for compiler-facing changes.
- For Phoenix/todo-app behavior changes, run the todo-app QA sentinel with Playwright.
