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
| 2 | Phoenix | `haxe.elixir-944.15` - reduce LiveView callback naming boilerplate | Implemented: exact Haxe-style LiveView callback names now emit Phoenix callback names by default; function-level `@:native` remains the explicit interop escape hatch. |
| 3 | Interop | `haxe.elixir-944.16` - app-local extern boundary scaffold/checklist | Implemented: `mix haxe.gen.extern --boundary` now scaffolds app-local module-reference externs without loading the Elixir module; strict-mode diagnostics and docs point to the scaffolded `@:native` + `@:unsafeExtern` shape. |

## Prioritized Papercuts

| Rank | Area | Location | Pain | Proposal | Impact / Effort |
| --- | --- | --- | --- | --- | --- |
| 1 | Ecto changesets | `std/ecto/Field.hx`, `std/ecto/SchemaField.hx`, `std/ecto/Changeset.hx`, `docs/04-api-reference/ANNOTATIONS.md` | Implemented: `Field.of((schema) -> schema.field)` returns a schema-typed `SchemaField<T>` token, and `castFields`, `validateRequired`, `validateLength`, `validateFormat`, `validateNumber`, `validateInclusion`, and `validateExclusion` consume token fields that emit Ecto atoms. String literals remain migration-compatible and also compile to atoms when passed directly. | Keep examples typed-token-first; use `Field.unsafe<T>(fieldName)` only for dynamic runtime field names. | Done / Low |
| 2 | Phoenix LiveView | `std/phoenix/Phoenix.hx`, `docs/04-api-reference/PHOENIX_API_REFERENCE.md`, `docs/04-api-reference/ANNOTATIONS.md` | Implemented: `@:liveview` normalizes exact known callback names (`handleEvent`, `handleInfo`, `handleParams`, `handleAsync`) and preserves explicit function-level `@:native`. | Keep examples/docs on Haxe-style callback names by default; use `@:native` only for explicit interop. | Done / Low |
| 3 | Interop tooling | `docs/02-user-guide/INTEROP_WITH_EXISTING_ELIXIR.md`, `docs/04-api-reference/TYPE_SAFE_CHILD_SPEC.md`, `lib/mix/tasks/haxe.gen.extern.ex`, `src/reflaxe/elixir/macros/StrictModeEnforcer.hx` | App-owned Elixir modules need tiny extern wrappers, often with `@:unsafeExtern` in strict contexts. | Implemented: use `mix haxe.gen.extern MyApp.Module --boundary --package my_app.infrastructure --out src_haxe` for marker externs; callable externs continue to use the default introspecting generator with optional wrapper/decoder/test scaffolds. | Done / Low |
| 4 | Ecto associations/query | `std/ecto/Association.hx`, `std/ecto/SchemaAssociation.hx`, `std/ecto/TypedQuery.hx`, `std/ecto/Repository.hx` | Implemented first slice: `Association.of((schema) -> schema.association)` returns a schema-typed `SchemaAssociation<T>` token, `TypedQuery.joinAssociation` / `TypedQuery.preloadAssociations` use token inputs, and `Repository.preloadAssociations` provides the typed repository path while raw string/`Term` APIs remain compatibility paths. | Keep examples/docs typed-token-first; use `Association.unsafe<T>(name)` only for dynamic runtime association names. Future expansion can derive named constants from schema metadata if real apps need shorter callsites. | Done first slice / Low |
| 5 | Router resources | `src/reflaxe/elixir/macros/RouterDsl.hx`, `docs/04-api-reference/ROUTER_DSL.md` | Implemented first slice: `ResourceOptions.only` and `except` now accept typed `ResourceAction` tokens via `resourceIndex`, `resourceShow`, `resourceNew`, `resourceCreate`, `resourceEdit`, `resourceUpdate`, and `resourceDelete`. Valid string literals remain migration-compatible and compile to Phoenix atoms. | Keep examples typed-token-first. Add an explicit dynamic escape hatch only if a real router needs runtime resource-action names. | Done first slice / Low |
| 6 | Router path params | `docs/04-api-reference/ROUTER_DSL.md`, `src/reflaxe/elixir/ElixirCompiler.hx` | Implemented: missing `paramsContract` errors now include an inferred typedef skeleton, for example `typedef UserPathParams = { var id:Int; }`, plus a route call showing where to pass it. | Keep the diagnostic focused on missing path-param contracts; future work can add similar suggestions for contracts missing individual fields. | Done / Low |
| 7 | Presence topics/keys | `std/phoenix/Presence.hx`, `std/phoenix/PresenceBehavior.hx`, `docs/04-api-reference/PHOENIX_API_REFERENCE.md` | Topics and keys were raw strings across generated Presence helpers. Dynamic topics are real, but common fixed topics benefit from typed tokens. | Done first slice: `PresenceTopic.of(...)` / `PresenceKey.of(...)` tokens, generated helper signatures use the token types, and raw strings remain source-compatible for dynamic Phoenix interop. | Medium / Medium |
| 8 | HXX mode metadata | `docs/04-api-reference/ANNOTATIONS.md`, `docs/02-user-guide/HXX_SYNTAX_AND_COMPARISON.md` | `@:hxx_mode("balanced"|"tsx"|"metal")` was easy to confuse with application portability profiles. | Done: docs now state TSX inline markup is the default, `@:hxx_mode(...)` is only a local template authoring override, and warnings call metal/legacy paths template-mode escape hatches rather than app profiles. | Done / Low |
| 9 | Term boundary decoding | `std/elixir/types/Term.hx`, `std/elixir/types/TermDecoder.hx`, interop docs | `Term` is the right opaque boundary, but callsites often needed repeated manual decoding after Phoenix/Elixir APIs returned open shapes. | Done first slice: added required/optional string-key and atom-key fetch+decode helpers plus `okError(...)` for Elixir `{:ok, value}` / `{:error, reason}` tuples. Docs now show local decode-at-boundary recipes. | Done first slice / Low |
| 10 | LiveView testing strings | `std/phoenix/test/LiveViewTest.hx`, `std/phoenix/test/LiveViewEventName.hx`, `std/phoenix/test/ConnTest.hx` | Test helpers used only string keys/events/selectors for assigns and LiveView events. This mirrors Phoenix, but Haxe tests can do better for app-owned keys/events. | Done first slice: `LiveViewTest.get_assign_key` / `has_assign_key` consume existing `AssignKey` tokens, and `LiveViewEventName` powers typed `render_*_event` helpers. Raw string APIs remain the Phoenix-faithful path for CSS selectors, paths, and migration code. | Done first slice / Low |
| 11 | Ecto validation option naming | `std/ecto/Changeset.hx`, `docs/04-api-reference/ECTO_API_REFERENCE.md` | Some Haxe option names (`min`, `max`) were ergonomic but obscured the exact Ecto option emitted (`greater_than_or_equal_to`, `less_than_or_equal_to`). | Done first slice: `NumberValidationOptions` accepts Ecto-faithful names plus `min`/`max` compatibility aliases, and docs show emitted Ecto names next to each Haxe option. | Done first slice / Low |
| 12 | Query escape hatches | `std/ecto/TypedQuery.hx` | `whereRaw` and `orderByRaw` were useful, but the safe/unsafe boundary was not as visually obvious as router/child-spec `*Unsafe`. | Done first slice: added `whereUnsafeRaw` and `orderByUnsafeRaw` as preferred spellings, kept `whereRaw` / `orderByRaw` as compatibility aliases, and documented the raw SQL boundary. | Done first slice / Low |

## Follow-Up Task Acceptance Template

Use this for each implementation bead created from the backlog:

- Add or update the typed API without removing the current compatibility surface.
- If a raw/dynamic path remains, name it or document it as an explicit migration/unsafe path.
- Update the deep API reference, examples, and any first-use docs.
- Add compile-time or snapshot coverage for compiler-facing changes.
- For Phoenix/todo-app behavior changes, run the todo-app QA sentinel with Playwright.
