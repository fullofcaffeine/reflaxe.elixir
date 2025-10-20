# HXX Migration Plan — From Stub to Fully Typed Compile‑Time HXX

This document tracks the planned migration from the transitional `std/HXX.cross.hx` stub to a fully macro‑driven, type‑checked HXX experience (akin to TSX), and the intermediate safeguards that keep generated HEEx valid and idiomatic during the transition.

## Status (2025-10-20)

- Step 4 complete: default HXX now uses the macro path via `std/HXX.hx` (forwarder to `reflaxe.elixir.macros.HXX`).
- Step 5 complete: transitional stub `std/HXX.cross.hx` removed after green QA sentinel on `examples/todo-app` and snapshot coverage.
- Added tests:
  - `phoenix/hxx_inline_expr` and `phoenix/hxx_block_if` – deterministic ~H + control-tag rewrite
  - `phoenix/hxx_assigns_linter_ok` – valid assigns usage compiles
  - `negative/HXXAssignsLinterErrors` – unknown assigns and type mismatch rejected

## Previous State (Transitional Stub)

- File: `std/HXX.cross.hx`
- WHAT: Minimal extern/inline class exposing `HXX.hxx(String)` and `HXX.block(String)` that returns the input string.
- WHY: Keeps existing application code compiling while we convert final HTML‑like strings to `~H` at the AST stage.
- HOW: The AST pipeline performs the real work:
  - `HeexRenderStringToSigilTransforms` converts functions returning HTML‑like strings (e.g., LiveView `render/1`) into `~H` sigils.
  - `TemplateHelpers` maps `#{}`, `${}` and `assigns.* → @*` in template content.
  - `HeexControlTagTransforms` rewrites HXX control tags (`<if {cond}> … </if>`) into block HEEx.

Limitations:
- Authoring is still string‑based; Haxe cannot type‑check inside raw strings.
- Use `${assigns.foo}` for expressions you want Haxe to check before it is converted to `@foo`.

## Final State (Compile‑Time Macro with Type Checking)

- File: `src/reflaxe/elixir/macros/HXX.hx` (already present)
- WHAT: `HXX.hxx()` macro validates and transforms templates at compile time and returns a string literal tagged `@:heex`.
- HOW: `ElixirASTBuilder` recognizes `@:heex` and emits `ESigil("H", ...)` directly — no string detours.
- Benefits:
  - Haxe type checking for expressions (TSX‑like authoring) with compile‑time errors.
  - Deterministic, idiomatic HEEx output without brittle string surgery.
  - Attribute‑level expression support (e.g., `selected=${assigns.sort_by == "created"}`) with proper types.

## Migration Steps (Acceptance Gates)

1) Deterministic `render/1` normalization (in progress)
- Ensure all `render(assigns)` final strings become `~H` (EString, EParen(EString), or EBlock(last=EString)).
- Apply control‑tag rewrite on the resulting `~H` content.
- QA: todo‑app compiles and boots; no literal `<if>` remains.

2) Assigns linter (late pass)
- Walk `~H` content, collect `@field` usage and validate against typed assigns for the module/function.
- Detect obvious type mismatches (e.g., comparing a `String` field to a numeric literal).
- Add negative snapshots and ensure clear compile‑time error messages.

3) Attribute‑level expression support
- Spec and implement EFragment/attribute parsing so `foo=${expr}` becomes `foo={@...}` with type checking.
- Cover common attributes: `class`, `selected`, `value`, `id`, LiveView `phx-*` values.

4) Switch default `HXX` to macro path
- Replace the stub with a macro forwarder (`std/HXX.hx` or direct import) so `HXX.hxx()` expands to a literal tagged `@:heex` and the builder emits `ESigil` directly.
- Keep target‑conditional gating so macro code doesn’t leak Elixir‑only internals into non‑Elixir contexts.

5) Remove transitional stub
- DONE (2025-10-20): `std/HXX.cross.hx` deleted. Macro is the sole path.

## Guardrails & Non‑Goals

- No app‑specific heuristics (names, atoms, routes) in compiler code.
- No widening to `Dynamic` on public surfaces.
- Follow Phoenix and Elixir APIs exactly; HXX provides authoring/typing, not alternate APIs.

## Cross‑References
- docs/01-getting-started/cross-hx.md — What `.cross.hx` is and when to use it
- docs/03-compiler-development/CROSS_FILES_STAGING_MECHANISM.md — Staging `.cross.hx` to `std/_std/`
- docs/05-architecture/TARGET_CONDITIONAL_STDLIB_GATING.md — Target‑conditional classpath injection
- docs/03-compiler-development/hxx-template-compilation.md — HXX → HEEx pipeline and transforms
