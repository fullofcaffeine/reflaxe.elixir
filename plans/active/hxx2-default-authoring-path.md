# HeexTemplate (formerly HXX2): Default Authoring Path (TSX-like Haxe Expressions, Phoenix HEEx Output)

NOTE: The canonical inline-markup entrypoint is now `phoenix.hxx.HeexTemplate.root/1`.
`phoenix.hxx.HXX2.root/1` remains as a deprecated alias for backward compatibility, but should not be used in new docs/examples.

## Summary

Make HeexTemplate the default authoring story for Phoenix LiveView templates, so inline markup provides a TSX-like experience:
- `{ ... }` blocks inside markup are **real Haxe expressions** (syntax + type-checked by the typer).
- Output is still standard Phoenix HEEx (`~H"""..."""`) with no runtime helper tax.
- Raw HEEx/EEx markers (`<% ... %>`) remain an explicit escape hatch only (`@:allow_heex`), not the default.
- Reduce cognitive overhead from `-D` flags by preferring metadata defaults and localized opt-outs.

Legacy HXX1 string templates remain supported for backward compatibility and as an escape hatch, but examples/docs should
push users toward HeexTemplate.

## Motivation (Why This Exists)

The current HXX pipeline is primarily “typed HEEx authoring” but still lets users accidentally paste raw HEEx expressions
into templates (e.g. `<>` or `if ..., do:` inside `class={...}`), which:
- bypasses Haxe typing for embedded logic
- shifts errors to Elixir compile-time (or runtime)
- increases drift between “Haxe-first” and “HEEx-first” authoring

HeexTemplate aims to be:
- Phoenix-first for output conventions
- Haxe-first for authoring and type safety
- strict-by-default for “no raw HEEx in HXX” unless explicitly opted in

## Non-Goals

- A full JSX runtime / a Coconut UI clone. We still emit HEEx to Phoenix.
- Solving all template typing in one shot. We stage this with a canonical entrypoint and incremental enhancements.

## Beads Mapping

This plan drives:
- `haxe.elixir-hxx2.2` inline-markup build-macro rewrite
- `haxe.elixir-hxx2.3` Builder lowering to `~H`
- `haxe.elixir-hxx2.7` Defaults and metadata (reduce `-D`)
- `haxe.elixir-hxx2.8` Snapshot coverage
- Follow-ups: `haxe.elixir-hxx2.6` class sugar/spread attrs, `haxe.elixir-hxx2.10` docs migration

## Design Overview

### Canonical entrypoint (already stubbed)

`phoenix.hxx.HeexTemplate.root(template: String): String`

This is a compile-time-only, non-inline function. The compiler detects calls to it in the typed AST and lowers them to
`ESigil("H", ...)` deterministically (same strategy as `HXX.hxx` today).

### Source of truth for inline markup: `@:markup`

Haxe inline markup is represented in macro AST as:
- `EMeta(name=":markup", innerExpr)` where `innerExpr` contains the markup payload.

Today we rewrite it to `HXX.hxx(innerExpr)` and then the macro processes the template as a string, which prevents `{...}`
from being treated as a real Haxe expression.

HeexTemplate’s rewrite instead:
- parses the markup payload
- extracts `{ ... }` segments
- turns each `{ ... }` into a real Haxe `Expr` via `Context.parseInlineString`
- reconstructs a typed Haxe expression that concatenates string fragments and inserted expressions
- wraps the resulting typed expression with `phoenix.hxx.HeexTemplate.root(...)`

This keeps 100% of the expression typing in the Haxe typer and eliminates “raw Elixir in templates” for the common cases.

### Lowering strategy (builder)

The builder treats `phoenix.hxx.HeexTemplate.root(expr)` like `HXX.hxx(expr)`:
- Build the argument expression into ElixirAST.
- Use `TemplateHelpers.collectTemplateContent(argAst)` to produce a HEEx string.
- Run the same HEEx normalization passes (control tags, attribute interpolation normalization, assigns rewriting).
- Emit `ESigil("H", content, "")`.

Raw HEEx markers remain forbidden by default; `@:allow_heex` (method/class) or `-D hxx_allow_raw_heex` are the only opt-ins.

## Detailed Implementation Spec

### 1) Macro rewrite (beads: `haxe.elixir-hxx2.2`)

File: `src/reflaxe/elixir/macros/InlineMarkup.hx`

Change:
- Replace rewrite target from `HXX.hxx(innerExpr)` to `phoenix.hxx.HeexTemplate.root(rewrittenExpr)`.

`rewrittenExpr` construction:
- If `innerExpr` is already a concatenation expression (rare, but handle defensively), still walk and replace embedded
  markup-specific literal nodes as needed.
- If `innerExpr` is a string constant (expected), scan it to split into:
  - literal chunks (outside braces)
  - expression chunks (inside `{ ... }`)

Scanning rules (must be deterministic, no heuristics):
- Track quote state for `"..."` and `'...'` inside attributes and text.
- Treat `{` / `}` as expression delimiters only when not inside quotes.
- Support nested braces inside `{ ... }` by depth counting.
- Fail fast on:
  - unclosed `{`
  - `}` without an opening `{`
  - empty expression `{}` (unless explicitly allowed; default: error)
- For each expression chunk:
  - `Context.parseInlineString(exprText, exprPos)` to obtain `Expr`
  - Wrap parsed expression in parentheses when stitching (avoid precedence surprises).

Reconstruction:
- Build an `Expr` equivalent to:
  - `"<prefix>" + (expr1) + "<mid>" + (expr2) + "<suffix>"`
- Avoid allocations when no `{...}` blocks exist: just call `HeexTemplate.root(innerExprStringConst)` directly.

Opt-out / legacy:
- Default should become “process Phoenix-facing modules” (same gating as current InlineMarkup, but without requiring `-D`).
- Add `-D hxx_no_inline_markup` and `@:hxx_no_inline_markup` to opt out.
- Add `@:hxx_legacy` to force old HXX1 rewrite behavior in a module (for migration).

Diagnostics:
- Errors must point at the right position in the original inline markup payload.
- Error messages must include:
  - what failed
  - the nearest snippet (bounded)
  - how to fix (escape hatch or correct syntax)

### 2) Builder lowering (beads: `haxe.elixir-hxx2.3`)

Files:
- `src/reflaxe/elixir/ast/builders/CallExprBuilder.hx`
- `src/reflaxe/elixir/ast/transformers/HeexStringReturnToSigilTransforms.hx` (var binding + return conversions)

Change:
- Add detection for static calls to `phoenix.hxx.HeexTemplate.root/1` (and accept `HXX2.root/1` as deprecated alias).
- Treat it identically to `HXX.hxx/1` for lowering to `ESigil("H", ...)`.
- Preserve the raw HEEx policy checks:
  - if the collected content includes raw markers and allowRawHeex=false: error
  - otherwise emit `~H` content (and still run HXX control tag normalization)

Additionally:
- Extend var-binding conversions to detect `HeexTemplate.root(...)` as a template producer (not only `HXX.hxx`).

### 3) Defaults and metadata (beads: `haxe.elixir-hxx2.7`)

Goal:
- Reduce `-D` overhead: default behavior should “just work” for Phoenix modules.

Decisions:
- Inline markup enabled by default in Phoenix-facing modules (same class metadata gating as today).
- Opt-outs:
  - `-D hxx_no_inline_markup` global
  - `@:hxx_no_inline_markup` per class
- Legacy escape hatch:
  - `@:hxx_legacy` on class forces rewrite to `HXX.hxx(...)` for now

Strict flags migration:
- Keep current `-D` flags backward compatible.
- Add metadata equivalents (per-module) for strict modes where it reduces cognitive load:
  - `@:hxx_strict_html`
  - `@:hxx_strict_phx_events`
  - `@:hxx_strict_phx_hook`
  - plus any additional strict flags already supported

### 4) Tests/snapshots (beads: `haxe.elixir-hxx2.8`)

Add/extend snapshots:
- Positive: inline markup with `{assigns.foo}` becomes HeexTemplate.root call and lowers to `~H` with `@foo`.
- Positive: inline markup with attribute value `{cond ? "a" : "b"}` lowers correctly and does not require raw HEEx.
- Negative: malformed `{` / `}` yields positional compile error.
- Negative: raw `<% ... %>` markers remain disallowed unless `@:allow_heex`.

Keep existing HXX1 snapshots passing; add new ones specifically keyed to the HeexTemplate entrypoint.

Verification:
- `npm test`
- todo-app: `npm run qa:sentinel` then bounded log peek until DONE

## Rollout Notes

- Start by supporting HeexTemplate lowering without changing existing `hxx('...')` authoring.
- Once stable, update docs/examples to prefer inline markup + HeexTemplate patterns.
- Keep HXX1 as fallback for at least one minor release cycle.
