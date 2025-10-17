# Attribute-level Expressions for HXX (~H)

Goal: Support attribute expressions with full Haxe type checking and idiomatic HEEx emission.

Examples
- Input (Haxe):
  - `selected=${assigns.sort_by == "created"}`
  - `value=${todo.title}`
  - `class=${todo.completed ? "done" : ""}`
- Output (HEEx):
  - `selected={@sort_by == "created"}`
  - `value={@todo.title}`
  - `class={if @todo.completed, do: "done", else: ""}` (or block form as needed)

Architecture
- Authoring: Attributes accept `${...}` (Haxe expression). Expressions are Haxe-typed at compile-time.
- Builder/Printer: ElixirAST builder captures attribute nodes as fragments; TemplateHelpers renders them to `{...}` inside ~H with assigns.* → @* mapping.
- Lints: Assigns Linter validates referenced @fields against known assigns; type mismatches (e.g., String vs Int) get flagged.

Implementation Plan
1) Parsing & Capture
- Extend TemplateHelpers to detect attribute contexts and record attribute name/value pairs.
- For values with `${...}`, compile the inner Haxe expression to ElixirAST, then map assigns.* → @* in the printed form.
- For plain quotes (e.g., `"foo"`), keep as string literal in HEEx.

2) Printing
- When building ESigil("H", content): print attribute values using `={...}` where `...` is the rendered expression.
- For boolean attributes, accept `true/false` and normalize to `={true}`/absence as appropriate.

3) Control Flow in Attributes
- Ternary (`cond ? a : b`) inside attributes emits `={if cond, do: a, else: b}` or block form when values are long.
- Leverage existing TemplateHelpers splitting logic.

4) Type Safety
- Expressions inside `${...}` are Haxe-typed.
- Assigns Linter validates @field usage post-conversion.

5) Escaping & Safety
- Avoid Phoenix.HTML.raw in attributes.
- Ensure interpolated expressions print as `{...}`; no string concatenation.

6) Tests
- Snapshot cases for common attributes (`value`, `class`, `selected`, `id`, `phx-` values) with literals and expressions.
- Negative tests via Assigns Linter (unknown @field, trivial type mismatches).

Non-goals
- Name-based heuristics (app-specific names) are forbidden.
- Dynamic string surgery post-printing.

Dependencies
- Assigns Linter (late pass) must be active.
- Control-tag and ternary rewrites already land.

Rollout
- Phase 1: value/class/selected/id
- Phase 2: phx-* attributes with normalizations (snake_case).

