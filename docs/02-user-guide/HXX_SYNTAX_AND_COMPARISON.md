# HXX → HEEx: Typed Syntax, UX, and Comparisons

HXX is a compile‑time template system for writing Phoenix HEEx in Haxe with strong typing and clear errors. It expands to idiomatic `~H` at compile time and integrates with Phoenix conventions (assigns, components, directives) without adding runtime cost.

This guide documents the interface, syntax, and developer UX, and compares HXX to Coconut UI (Haxe) and TSX/JSX (TypeScript/React) in terms of syntax and functionality.

## Goals and Principles

- HEEx parity: Generate HEEx that looks hand‑written and follows standard Phoenix patterns.
- Typed authoring: Catch invalid attributes, values, and assigns usage at compile time.
- No runtime tax: All checks run at compile time; output is plain `~H`.
- No app coupling: Never rely on project‑specific names; validation is API/shape‑driven.
- No Dynamic widening: Keep precise types; fix transforms instead of using Dynamic.

See also:
- 02-user-guide/INLINE_MARKUP.md – Inline markup authoring (typed-first)
- 02-user-guide/ESCAPE_HATCHES.md – Raw HEEx escape hatches and when (not) to use them
- 05-architecture/HXX_ARCHITECTURE.md – Technical pipeline
- 07-patterns/PHOENIX_LIVEVIEW_PATTERNS.md – Practical LiveView authoring patterns

## Authoring Model

- Typed-first entrypoint: Haxe inline markup literals (`return <div>...</div>`) are rewritten into a canonical template entrypoint (`phoenix.hxx.HeexTemplate.root/1`), which the builder lowers to `~H`.
- TSX control tags: `<if ${cond}>` / `<for ${item in items}>` are parsed at macro-time into a typed template AST and lowered to HEEx `if`/`for` blocks.
- Typed spread attrs: tag-position attrs expressions (e.g. `<section {assigns.attrs}>`) lower to HEEx spread attrs (`<section {@attrs}>`).
- Typed loop helper: `phoenix.hxx.HeexTemplate.for_each(items, (item) -> <li>...</li>)` remains available when expression-style composition is preferred. Short alias: `phoenix.hxx.H.each(...)` (or `phoenix.hxx.H.for_each(...)`).
- Template strings (legacy/migration): `hxx('...')` / `HXX.block('...')` are supported in **balanced** mode, but they are string-rewritten + linted (template-local markers are not Haxe-typed).
- Layered modes: `@:hxx_mode("tsx"|"balanced"|"metal")` controls how strict the template authoring surface is.

You normally do not write `@:hxx_mode("tsx")`. TSX inline markup is the default for new code; the metadata exists for local overrides when migrating legacy string templates or isolating a raw HEEx escape hatch.

### HXX Mode Contract

| Mode | Use for | Allows legacy `hxx('...')` strings? | Allows raw `<% ... %>`? | Recommendation |
| --- | --- | --- | --- | --- |
| `tsx` | New application code and examples | No | No | Recommended/default authoring path |
| `balanced` | Migration modules and demos | Yes | Only with `@:allow_heex` or `-D hxx_allow_raw_heex` | Compatibility path |
| `metal` | Last-resort raw HEEx interop | Yes | Yes, with a compiler warning | Local escape hatch only |

`tsx` is named after TypeScript JSX-style authoring: dynamic pieces are real typed host-language expressions, not string-rewritten mini-languages.

`metal` here is a template-local escape hatch, not an application-wide compiler profile. For application authoring profiles, use `portable` or `Elixir-first`; both aim to generate idiomatic Elixir, with different priorities when portability and BEAM-native shape conflict. In other words: `@:hxx_mode(...)` answers “how should this template be parsed?”, not “what kind of app am I building?”.

Inline markup notes:
- Root tag must be a valid XML name (Haxe lexer rule).
- Phoenix dot-components like `<.form>` cannot be the *root*; wrap them in a normal element (e.g. `<div>...</div>`).
- Inline markup parses `${...}` segments into real Haxe expressions (`Context.parseInlineString`), so syntax + types are checked by the Haxe typer.

Defaults / opt-out:
- Inline markup rewrite is enabled by default for Phoenix-facing modules (`@:liveview`, `@:component`, etc.); opt out with `-D hxx_no_inline_markup` or `@:hxx_no_inline_markup`.
- Force-enable per-module with `@:hxx_inline_markup` (useful for non-Phoenix modules).
- Deprecated migration escape hatch: `@:hxx_legacy` forces the older rewrite-to-`HXX.hxx("...")` behavior for that class. Keep it only in legacy/balanced migration fixtures; it is rejected in `tsx` mode and emits a deprecation warning elsewhere.

Interpolation note:
- In inline markup, `${...}` segments are parsed into real Haxe expressions (`Context.parseInlineString`) and are fully type-checked by Haxe.
- In template strings (`hxx('...')`), markers like `#{...}` and `<if { ... }>` / `<for { ... }>` are rewritten + linted, but do not provide Haxe-typed expressions. Prefer inline markup for typed authoring.

Example:

```haxe
import phoenix.hxx.HeexTemplate;

class View {
  public static function render(assigns: { name:String, online:Bool }): String {
    return <div class=${assigns.online ? "online" : "offline"}>
      Hello, ${assigns.name}!
    </div>;
  }
}
```

Generates (Elixir):

```elixir
def render(assigns) do
  ~H"""
  <div class={if @online, do: "online", else: "offline"}>
    Hello, <%= @name %>!
  </div>
  """
end
```

## Syntax Overview

### Interpolations
- Inline markup (typed): `${haxeExpr}` splices are real Haxe expressions and lower to `<%= ... %>` (and `assigns.*` is mapped to `@*`).
- Template strings (legacy): `#{expr}` and `${expr}` are string-level markers rewritten into HEEx; they are convenient for migration but are not Haxe-typed.
- Attributes: `attr={expr}` stays as `attr={expr}` (HEEx attribute expressions). When written via `${...}`, HXX normalizes to `{...}`.
- Spread attrs: `{assigns.attrs}` (or `{@assigns.attrs}`) in tag position lower to HEEx spread attrs `{@attrs}`.

### Raw HEEx Escape Hatch (Avoid)
- Raw `<% ... %>` blocks inside `hxx('...')` / `HXX.hxx('...')` are **disallowed by default**.
- Opt-in escape hatch: add `@:allow_heex` to the enclosing function or class (or compile with `-D hxx_allow_raw_heex`).
- Metal mode: `@:hxx_mode("metal")` allows raw `<% ... %>` without `@:allow_heex` (discouraged; emits warnings). This is scoped to HXX/HEEx authoring and should not be treated as a project-wide profile.

`@:allow_heex` is invalid in `tsx` mode. If a template still needs raw HEEx, keep that scope in `balanced` with explicit `@:allow_heex`, or isolate it in `metal` until it can be rewritten.

### Assigns
- `render(assigns: AssignsType)` is required; `@field` references are validated against `AssignsType`.
- Linter reports:
  - Unknown fields: `@sort_byy`
  - Obvious literal kind mismatches: `@count == "zero"` when `count:Int`

### Attributes and Directives (Typed)
- Attribute names in Haxe may be camelCase or snake_case; they map to HEEx/HTML:
  - `className` → `class`, `phxClick` → `phx-click`, `dataTestId` → `data-test-id`
- Each *registered* HTML element’s allowed attributes and basic value kinds come from:
  - `phoenix.types.HXXTypes` (e.g., `InputAttributes`, `DivAttributes`)
  - `phoenix.types.HXXComponentRegistry` (which tags are registered + which attributes are allowed)

What is checked (TSX-like behavior)
- If the tag is a **registered HTML element** (e.g., `div`, `input`, `button`, `a`), the linter validates:
  - attribute names (including camelCase/snake_case/kebab-case normalization)
  - wildcard-safe attributes (`data-*`, `aria-*`, `phx-value-*`) and HEEx directives (`:if`, `:for`, `:let`)
  - a small set of obvious attribute value kinds (e.g., bool-ish attrs, `phx-hook`, `phx-click`), when statically known
- If the tag is **not registered** (e.g., a custom Web Component like `<my-widget>`), attribute validation is intentionally skipped by default to avoid false positives.

This means:
- `<div hreff="...">` is a compile-time error (typo on a registered element).
- `<my-widget hreff="...">` is not an error by default (unknown/custom tags are treated as “user-defined”).

### Components & Slots
- Phoenix components `<.button ...>` are preserved; attributes can be validated via your registry and typedefs. Slots follow registered shapes.

#### Opt-in: strict component resolution

By default, the compiler **skips validation** for dot-components it cannot resolve unambiguously (to avoid false positives).
If you want TSX-level strictness for component tags, enable globally with `-D hxx_strict_components` or locally with `@:hxx_strict_components` (on the class or the `render/1` function):

```bash
-D hxx_strict_components
```

In strict mode:
- Unknown dot-components (e.g. `<.typo>`) are compile errors.
- Ambiguous components (multiple `@:component` functions with the same name) are compile errors.

Phoenix core tags like `<.link>`, `<.form>`, `<.inputs_for>`, and `<.live_component>` remain allowed even without a Haxe definition.

#### Opt-in: strict slot typing for `:let`

By default, `:let` is allowed even if the component/slot does not declare what type is being bound (in that case the linter cannot type-check field access on the bound variable).
If you want TSX-level strictness for `:let`, enable globally with `-D hxx_strict_slots` or locally with `@:hxx_strict_slots`:

```bash
-D hxx_strict_slots
```

In strict mode:
- Using `:let` requires a typed let binding (e.g. `Slot<EntryType, LetType>` or component `inner_block: Slot<..., LetType>`).
- `:let` must be a simple variable binding (`:let={row}`); binding patterns like `:let={{row, idx}}` are rejected.

#### Opt-in: strict `phx-hook` typing

If you want to enforce typed `phx-hook` usage (to prevent drift with your hook registry), enable globally with `-D hxx_strict_phx_hook` or locally with `@:hxx_strict_phx_hook`:

```bash
-D hxx_strict_phx_hook
```

In strict mode:
- `phx-hook="Name"` (literal) is rejected.
- `phx-hook={@hook}` (dynamic) is rejected.
- Use a compile-time constant from a `@:phxHookNames` registry (recommended: `phx-hook=${HookName.Name}` in HXX).

Note:
- Phoenix requires a stable DOM id for hooks; the compiler errors if a *non-component* tag uses `phx-hook` without an `id` attribute.

#### Opt-in: strict `phx-*` event typing

If you want to enforce typed LiveView event names (`phx-click`, `phx-submit`, `phx-change`, ...), enable globally with `-D hxx_strict_phx_events` or locally with `@:hxx_strict_phx_events`:

```bash
-D hxx_strict_phx_events
```

In strict mode:
- Event names must be compile-time constants, and must be known to the compiler.
- In a `@:liveview` module, the compiler can *derive* allowed events from your `handle_event/3` body (literal strings in `switch (event)` and `if (event == "...")` comparisons).
- Otherwise, define a `@:phxEventNames` registry and reference it from templates (recommended: `phx-click=${EventName.Save}` in HXX).

Rejected in strict mode:
- Fully dynamic event expressions (e.g. `phx-click={@event}`) are rejected because they cannot be validated.

#### Opt-in: strict literal values for selected attributes

If you want stricter TSX-like checks for known string-literal vocabularies, enable globally with `-D hxx_strict_attr_values` or locally with `@:hxx_strict_attr_values`:

```bash
-D hxx_strict_attr_values
```

In strict mode, constant string literals are validated for selected attributes:
- `input[type]` (e.g. `text`, `email`, `number`, ...)
- `button[type]` (`button|submit|reset`)
- `form[method]` (`get|post`)
- `textarea[wrap]` (`hard|soft`)
- `phx-update` (`replace|stream|append|prepend|ignore`)

Notes:
- This check is intentionally conservative: only compile-time constant string literals are validated to avoid noisy false positives.
- Dynamic values (e.g. interpolated assigns) are not rejected by this rule.

### Control Flow
- Typed-first (recommended): use normal Haxe control flow inside `${ ... }` and typed helpers like `HeexTemplate.for_each/2`.
- TSX mode also supports explicit control tags with typed headers:
  - `<if ${cond}> ... <else> ... </else> </if>`
  - `<for ${item in items}> ... </for>`
- TSX mode also supports `:for` directive sugar on elements:
  - `<li :for ${item in items}>...</li>` (lowered to a HEEx `for` block around the element, with typed binder scope).
- Template strings (migration): block conditionals/loops can use HXX control tags (normalized to HEEx):
  - `<if {cond}> ... <else> ... </if>` → HEEx `if/else` block
  - `<for {pattern in expr}> ... </for>` → HEEx `for` block

Note: The `{cond}` / `{pattern in expr}` headers inside template strings are not parsed as Haxe AST, so they are not type-checked by the Haxe typer.

### Escaping & Safety
- HEEx escaping rules apply; no alternative raw API is introduced. The compiler warns on unsafe patterns in `~H` (validator transforms).

## Typing & Validation

- Element/attribute typing: `HXXTypes` defines allowed attributes and kinds. The linter validates attributes for registered HTML tags, producing helpful errors and suggestions (unknown/custom tags are skipped by default).
- Assigns typing: The linter cross‑checks `@field` references in `~H` against the Haxe `typedef` used for `assigns`.
- Component prop kind typing: component assigns types are reduced to simple “kinds” (e.g. `string`, `bool`, `map`) and checked against attribute values when resolvable. `haxe.extern.EitherType<A, B>` (and `haxe.ds.Either<A, B>`) is treated as a union kind (`kindA|kindB`) when both sides are known.
- Struct-like externs: if an extern type represents an Elixir struct and should behave like a map in HXX kind checks, annotate it with `@:elixirStruct` (e.g. `phoenix.JS`).
- Attribute expressions (in progress): The compiler is moving to a structural AST (`EFragment`) so attribute values are typed expressions instead of text.

## Extending the HXX type vocabulary

## HXX Flags and Metadata Status

| Surface | Status | Notes |
| --- | --- | --- |
| default / `-D hxx_mode=tsx` / `@:hxx_mode("tsx")` | Default | Strict typed authoring path for new code; explicit forms are only needed to override a non-TSX scope. |
| `@:hxx_mode("balanced")` | Supported compatibility | Useful for migration modules that still need string templates. |
| `@:hxx_mode("metal")` | Escape hatch | Allows raw HEEx and emits warnings when raw markers are present. |
| `@:allow_heex` / `-D hxx_allow_raw_heex` | Escape hatch | Avoid in app code; invalid under `tsx`. Global define is migration-only. |
| `@:hxx_legacy` | Deprecated migration-only | Emits a warning; rejected under `tsx`. Prefer typed inline markup or explicit balanced string templates. |
| `@:hxx_no_inline_markup` / `-D hxx_no_inline_markup` | Supported opt-out | Use only when inline markup conflicts with non-template Haxe syntax. |
| `@:hxx_inline_markup` | Supported opt-in | Enables inline markup for non-Phoenix helper modules. |
| `-D hxx_allow_string_fallback` / `@:hxx_allow_string_fallback` | Debug/compatibility | Forces legacy string scanning when typed HEEx AST metadata is available; do not use as an app authoring mode. |

These flags are template-authoring controls only. Keep application profile decisions in normal source shape: portable domain modules should avoid target-only APIs, while Elixir-first modules can import Phoenix/Ecto/OTP surfaces directly.

You have two “vocabularies” you can extend:

1) HTML element typing
- Source of truth:
  - `std/phoenix/types/HXXTypes.hx` (attribute typedefs like `InputAttributes`, `DivAttributes`, etc.)
  - `std/phoenix/types/HXXComponentRegistry.hx` (which tags are registered + which attributes are allowed)
- Add a new element or attribute:
  - Add/extend the attribute typedef in `HXXTypes.hx`
  - Register the element (or extend its allowed attribute set) in `HXXComponentRegistry.hx`
  - Add a negative snapshot (typo attribute should fail) under `test/snapshot/negative/` and run `npm test`

2) Phoenix component typing (`<.my_component ...>`, slots, `:let`)
- For user components, define a discoverable `@:component` function and typed assigns/slots.
- The linter uses RepoDiscovery to resolve components and then enforces:
  - allowed props / required props
  - allowed slots / required slots
  - typed `:let` when the component/slot declares a `Slot<EntryProps, LetType>`

3) Custom HTML tags (Web Components)
- By default, unknown/custom tags skip attribute validation to avoid false positives.
- If you want to *opt in* to typing for a custom tag, register it in your app using metadata:

```haxe
@:hxxHtmlTags
class CustomTags {
  // Register the tag name (used by `-D hxx_strict_html` / `@:hxx_strict_html`)
  @:hxxTagAttrs(["enabled", "variant"])
  public static final MyWidget = "my-widget";
}
```

## Editor tooling: JSON index export

You can generate a small JSON vocabulary for editor tooling (autocomplete/lint helpers) that includes:
- built-in HTML tags + allowed attributes
- discovered dot-components + their props/slots
- global hook/event registries (`@:phxHookNames` / `@:phxEventNames`)
- per-`@:liveview`:
  - `derivedEvents` (from `handle_event/3`)
  - `templateEvents` / `templateHooks` / `templateComponents` / `templateSlots` (from template scanning)
  - `usedComponents` (best-effort join of `templateComponents` → component definitions)

Generate:

```bash
npm run docs:hxx:index
```

This writes `tmp/hxx-registry.json`.

Notes:
- Registered custom tags are recognized by `-D hxx_strict_html` / `@:hxx_strict_html` (so they don’t error as “unknown tags”).
- Attribute validation for custom tags is only enabled when you provide an explicit `@:hxxTagAttrs(...)` allowlist.

### Will the compiler complain about unknown tags?
- Unknown dot-components (`<.typo ...>`) are only errors under `-D hxx_strict_components` / `@:hxx_strict_components` (recommended when you want TSX-level strictness).
- Unknown HTML/custom tags (`<my-widget ...>`) are not errors by default; they are treated as user-defined to support custom elements. Registered HTML tags still get strict attribute checking.
- If you want TSX-like strictness for custom elements too, enable `-D hxx_strict_html` / `@:hxx_strict_html`:
  - Unknown HTML/custom tags become errors unless registered or explicitly allowed via `-D hxx_strict_html_allow_tags=my-widget,another-tag`.

## Developer UX

- Immediate compile‑time feedback with precise messages (field names, expected kinds).
- Idiomatic Elixir output with standard HEEx; easy to review and debug.
- No vendor‑specific runtime helpers; everything compiles to plain Phoenix patterns.

## Comparison: HXX vs Coconut UI vs TSX/JSX

| Aspect | HXX (Haxe→HEEx) | Coconut UI (Haxe) | TSX/JSX (TypeScript/React) |
|---|---|---|---|
| Primary Target | Phoenix HEEx (server) | Haxe UI Virtual DOM/React‑like (client) | React Virtual DOM (client) |
| Output | `~H` (string) → Phoenix engine | Haxe code & VDOM structures | JavaScript/JSX → React elements |
| Typing of HTML attrs | Yes (HXXTypes per element) | Yes (component/property typing) | Yes (DOM/React types) |
| Assigns/Props typing | Yes (`render(assigns: T)`, linter over `@field`) | Yes (component props) | Yes (component props) |
| Attribute expressions | `{...}` (structural AST planned) | Haxe expressions in HXX/tpl | `{...}` (JS expressions) |
| Components/slots | Phoenix components `<.comp>`; slot shapes | Component system with templates/slots | Components with children/props |
| Control flow | HEEx block `if`, comprehensions via idioms | HXX‐templating & Haxe control | JS expressions (ternary/map) |
| Runtime | Server‑rendered HEEx (LiveView) | Client runtime (VDOM/reactive) | Client runtime (VDOM) |
| Escape semantics | HEEx (server‑safe by default) | UI lib‑defined | React escaping rules |
| Integration | Phoenix/LiveView/Ecto idioms | Haxe app frameworks | React ecosystems |

Notes:
- Coconut UI’s HXX (tink_hxx) targets client‑side component rendering with a reactive runtime; Reflaxe.Elixir’s HXX targets server‑side HEEx generation for Phoenix. Both bring strong typing and template ergonomics, but the runtime and integration targets differ.
- TSX offers excellent developer tooling for client apps. HXX focuses on typed server templates that integrate deeply with Phoenix patterns, while allowing shared business logic via Haxe.

## Migration Tips

- From HEEx: keep your template semantics identical; move the markup into inline Haxe markup (`return <div>...</div>`). Use Haxe types for assigns.
- From older HXX: keep `hxx('...')` only in balanced migration modules, then migrate toward inline markup as you touch templates.
- From Coconut UI/TSX: move client‑side interactivity to LiveView patterns (events, assigns) or to genes‑generated JS when needed. Keep shared validation in Haxe to use on both server and client.

## Roadmap to Full Parity

1. Attribute‑level AST (EFragment) for typed attribute values and children.
2. Linter over attribute AST (beyond literal comparisons).
3. Retire string rewrite helpers in favor of pure AST.
4. Broaden Phoenix component/slot typing coverage.

All roadmap items are tracked in the Shrimp task “Transform: HXX Assigns Type Linter + Snapshots”.

## Future Idea: Universal HXX (HEEx + JSX Dual‑Target)

This is a forward‑looking concept for a Haxe‑augmented UI framework that compiles the same component source to both HEEx (server, Phoenix LiveView) and JSX/ES6 (client, React or similar). The purpose is to share types, business logic, and even component structure across server and client while preserving idiomatic patterns on each side.

Goals
- One component definition, two idiomatic outputs: HEEx for LiveView, JSX for client frameworks.
- Strong typing end‑to‑end: props/assigns, events/messages, slots/children.
- No runtime bridge layer in production builds; all branching happens at compile time.
- Preserve Phoenix/React conventions — never invent fake APIs.

Core Ideas
- Universal component class with typed props and optional slots.
- Target‑specific renderers using metadata annotations.
- Shared logic (validation, derived state) in plain Haxe.
- Compile‑time selection of output (Elixir or JavaScript) with separate build commands.

Sketch (illustrative; not an API commitment):

```haxe
@:universal
class Badge {
  public var label:String;
  public var kind:BadgeKind; // Info | Success | Warning

  // Shared logic
  inline function color():String return switch kind { case Info: "blue"; case Success: "green"; case Warning: "orange"; }

  // Server: HEEx (Phoenix LiveView)
  @:target("elixir")
  public function renderHeex():String {
    return <span class=${"badge " + color()}>${label}</span>;
  }

  // Client: JSX (ES6 via genes)
  @:target("javascript")
  public function renderJsx():String {
    return JSX.jsx('<span className={"badge " + color()}>{label}</span>');
  }
}
```

Build/Integration
- Server build: HXX → `~H` via Elixir backend; LiveView owns DOM updates.
- Client build: genes → ES6 modules with JSX (or JSX‑like) output for bundlers (esbuild/vite).
- Projects choose per‑component where to render (server, client, or both for progressive enhancement).

Events & Messages (shape‑based)
- Server: `phx-*` directives map to typed event enums; handlers are LiveView callbacks.
- Client: DOM/React events map to typed callbacks; shapes mirror server enums to share type safety.
- Messages are defined as Haxe enums/typedefs so both sides agree on payloads.

SSR/CSR Strategies
- Server‑only: render via HEEx; no client artifact.
- Client‑only: render via JSX with client runtime.
- Progressive enhancement: HEEx renders baseline; optional client module enhances behavior.

Constraints & Non‑Goals
- Do not invent Phoenix or React APIs — compile to their established patterns.
- Prefer a lowest‑common‑denominator attribute/slot model; target‑specific extras live behind `@:target` sections.
- Maintain the No‑Dynamic policy for public surfaces; use precise types for props/events.

Why this is interesting
- Eliminates server/client drift by sharing types and logic.
- Makes LiveView apps incrementally “client‑capable” without a rewrite.
- Gives React teams a typed on‑ramp to Phoenix while retaining familiar patterns.

Open Questions
- Hydration semantics when mixing LiveView and client islands.
- Debuggability and source maps across dual targets.
- Tooling for slot typing parity between components on both sides.

Status: Design exploration. The current compiler already supports Elixir (~H) and JS (via genes) separately; a universal HXX layer would formalize a single authoring model that targets both cleanly.
