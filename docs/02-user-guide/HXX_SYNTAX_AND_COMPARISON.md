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
- 02-user-guide/HXX_TYPE_SAFETY.md – Type system and validation
- 06-guides/HXX_GUIDE.md – Practical authoring patterns
- 03-compiler-development/hxx-template-compilation.md – Technical pipeline

## Authoring Model

- Entrypoint: `HXX.hxx('...')` returns a compile‑time string tagged as HEEx; the builder emits `~H`.
- Nested fragments: `HXX.block('...')` inlines a fragment within a parent template.

Example:

```haxe
class View {
  public static function render(assigns: { name:String, online:Bool }): String {
    return HXX.hxx('
      <div class=${assigns.online ? "online" : "offline"}>
        Hello, ${assigns.name}!
      </div>
    ');
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
- Text: `${expr}` → `<%= expr %>`; `assigns.*` is mapped to `@*`.
- Attributes: `attr=${expr}` → `attr={expr}`. Ternaries become inline `if`:
  - `${flag ? "on" : "off"}` → `{if flag, do: "on", else: "off"}`

### Assigns
- `render(assigns: AssignsType)` is required; `@field` references are validated against `AssignsType`.
- Linter reports:
  - Unknown fields: `@sort_byy`
  - Obvious literal kind mismatches: `@count == "zero"` when `count:Int`

### Attributes and Directives (Typed)
- Attribute names in Haxe may be camelCase or snake_case; they map to HEEx/HTML:
  - `className` → `class`, `phxClick` → `phx-click`, `dataTestId` → `data-test-id`
- Each element’s allowed attributes and value types come from `phoenix.types.HXXTypes` (e.g., `InputAttributes`, `DivAttributes`).

### Components & Slots
- Phoenix components `<.button ...>` are preserved; attributes can be validated via your registry and typedefs. Slots follow registered shapes.

#### Opt-in: strict component resolution

By default, the compiler **skips validation** for dot-components it cannot resolve unambiguously (to avoid false positives).
If you want TSX-level strictness for component tags, enable:

```bash
-D hxx_strict_components
```

In strict mode:
- Unknown dot-components (e.g. `<.typo>`) are compile errors.
- Ambiguous components (multiple `@:component` functions with the same name) are compile errors.

Phoenix core tags like `<.link>`, `<.form>`, `<.inputs_for>`, and `<.live_component>` remain allowed even without a Haxe definition.

#### Opt-in: strict slot typing for `:let`

By default, `:let` is allowed even if the component/slot does not declare what type is being bound (in that case the linter cannot type-check field access on the bound variable).
If you want TSX-level strictness for `:let`, enable:

```bash
-D hxx_strict_slots
```

In strict mode:
- Using `:let` requires a typed let binding (e.g. `Slot<EntryType, LetType>` or component `inner_block: Slot<..., LetType>`).
- `:let` must be a simple variable binding (`:let={row}`); binding patterns like `:let={{row, idx}}` are rejected.

#### Opt-in: strict `phx-hook` typing

If you want to enforce typed `phx-hook` usage (to prevent drift with your hook registry), enable:

```bash
-D hxx_strict_phx_hook
```

In strict mode:
- `phx-hook="Name"` (literal) is rejected.
- Use an expression form instead (recommended: `phx-hook=${HookName.Name}` in HXX).

Note:
- Phoenix requires a stable DOM id for hooks; the compiler errors if a *non-component* tag uses `phx-hook` without an `id` attribute.

#### Opt-in: strict `phx-*` event typing

If you want to enforce typed LiveView event names (`phx-click`, `phx-submit`, `phx-change`, ...), enable:

```bash
-D hxx_strict_phx_events
```

In strict mode:
- Literal event strings like `phx-click="save"` are rejected.
- Use an expression form instead (recommended: `phx-click=${EventName.Save}` in HXX).

### Control Flow
- Block conditionals in content use HXX control tags (normalized to HEEx):
- `<if cond> ... <else> ... </if>` → HEEx `if/else` block
- Attribute conditionals become inline `if` as shown above.

### Escaping & Safety
- HEEx escaping rules apply; no alternative raw API is introduced. The compiler warns on unsafe patterns in `~H` (validator transforms).

## Typing & Validation

- Element/attribute typing: `HXXTypes` defines allowed attributes and kinds. The macro validates element names and attributes, producing helpful errors and suggestions.
- Assigns typing: The linter cross‑checks `@field` references in `~H` against the Haxe `typedef` used for `assigns`.
- Attribute expressions (in progress): The compiler is moving to a structural AST (`EFragment`) so attribute values are typed expressions instead of text.

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

- From HEEx: keep your template semantics identical; replace `~H` chunks with `HXX.hxx('...')`. Use Haxe types for assigns.
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
    return HXX.hxx('<span class="badge ${color()}">${label}</span>');
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
