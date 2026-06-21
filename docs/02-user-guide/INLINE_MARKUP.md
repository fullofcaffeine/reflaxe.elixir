# Inline Markup: TSX‑Like Authoring for Phoenix HEEx

Inline markup is the preferred HXX authoring style for new Phoenix code. It lets you write markup
directly in Haxe while still emitting ordinary Phoenix HEEx (`~H"""..."""`) in the generated Elixir.

Use this path by default because template expressions are real Haxe expressions: the Haxe typer can
check field names, expression syntax, and many component/attribute shapes before Phoenix ever compiles
the generated `~H`.

Haxe supports “inline markup” literals:

```haxe
return <div class="counter">
  <h1>${assigns.count}</h1>
</div>;
```

Compiles to:

```elixir
~H"""
<div class="counter">
  <h1><%= @count %></h1>
</div>
"""
```

In Reflaxe.Elixir, inline markup is syntax sugar over a compiler-intercepted template entrypoint:

- Inline markup becomes `@:markup "<div ...>...</div>"` (a string constant with metadata).
- A build macro rewrites `@:markup` into `phoenix.hxx.HeexTemplate.root(<typed template expr>)` before typing.
- The compiler lowers `HeexTemplate.root/1` to `~H"""..."""` deterministically (same lowering strategy as `HXX.hxx/1`).

Inline markup parsing extracts `${ ... }` segments and converts them into real Haxe expressions via `Context.parseInlineString`,
so the Haxe typer checks syntax and types.

Migration note: `@:hxx_legacy` forces the old "rewrite to `HXX.hxx(\"...\")`" behavior. It is deprecated, emits a compiler warning, and is rejected in `@:hxx_mode("tsx")`.

Implementation: `src/reflaxe/elixir/macros/InlineMarkup.hx`.

## Typed Control Flow (Recommended)

Because `${ ... }` segments become real Haxe expressions, you can use normal Haxe control flow and keep it type-checked.

### Conditional markup

```haxe
return <div class="root">
  ${if (assigns.show) <span class="yes">Yes</span> else <span class="no">No</span>}
</div>;
```

This lowers to a real HEEx block:

```elixir
<%= if @show do %>
  <span class="yes">Yes</span>
<% else %>
  <span class="no">No</span>
<% end %>
```

### Loops

In default TSX mode, use typed control tags directly:

```haxe
return <ul>
  <for ${item in assigns.items}>
    <li>${item.name}</li>
  </for>
</ul>;
```

This lowers to a HEEx `for` block and keeps binder expressions fully Haxe-typed.

Compiles to:

```elixir
<%= for item <- @items do %>
  <li><%= item.name %></li>
<% end %>
```

TSX also supports `:for` directive sugar on elements:

```haxe
return <ul>
  <li :for ${item in assigns.items}>${item.name}</li>
</ul>;
```

This lowers to the same HEEx `for` block shape (wrapped around the element), so binder usage remains typed.

In balanced mode, if you need expression-level composition, use `phoenix.hxx.HeexTemplate.for_each/2` (or `phoenix.hxx.H.for_each/2`):

```haxe
import phoenix.hxx.HeexTemplate;

typedef Item = { var name: String; };

return <ul>
  ${HeexTemplate.for_each(assigns.items, (item) -> <li>${item.name}</li>)}
</ul>;
```

This lowers to a HEEx `for` block so the body is parsed as markup, not an escaped string.

Compiles to:

```elixir
<%= for item <- @items do %>
  <li><%= item.name %></li>
<% end %>
```

Short alias (recommended when you prefer concise callsites):

```haxe
import phoenix.hxx.H;

return <ul>
  ${H.each(assigns.items, (item) -> <li>${item.name}</li>)}
</ul>;
```

### Spread attributes (TSX mode)

Use a typed attrs expression directly in tag position:

```haxe
typedef Assigns = { var attrs: Map<String, String>; };

public static function render(assigns: Assigns): String {
  return <section {assigns.attrs} data-testid="users"></section>;
}
```

Generated HEEx:

```elixir
<section {@attrs} data-testid="users"></section>
```

Notes:
- `{@assigns.attrs}` is also accepted in TSX markup and lowers to the same output.
- Prefer `{assigns.attrs}` for Haxe-native authoring readability.

## Defaults and Opt-Out

- Inline markup rewrite is enabled by default for Phoenix-facing modules.
- Opt out globally: `-D hxx_no_inline_markup`
- Opt out per module: `@:hxx_no_inline_markup`
- Force legacy rewrite per module: `@:hxx_legacy` (deprecated; migration fixtures only)

## Where It Runs (Scope)

The rewrite is scoped to keep overhead minimal:

- By default, it only runs for Phoenix‑facing modules:
  - `@:liveview`, `@:component`, `@:controller`, `@:channel`, `@:endpoint`, `@:router`, `@:presence`, `@:socket`, `@:phoenix.components`
- If you want it on another class, opt in per-module:

```haxe
@:hxx_inline_markup
class SomeHelper {
  public static function render(assigns: { var title:String; }):String {
    return <h1>${assigns.title}</h1>;
  }
}
```

## Limitations (Haxe Lexer Rules)

Haxe’s markup lexer has XML-ish rules that affect what can be the **root** tag of a markup literal.

### Root tag must be a valid XML name

- ✅ Valid roots: `<div>`, `<span>`, `<my-widget>` (custom tags), `<svg>`, …
- ❌ Not valid root: Phoenix dot-components like `<.form>` because `.form` is not a valid XML name.

Recommended pattern for dot-components:

```haxe
return <div>
  <.form for=${assigns.formFor} action="/save">
    ...
  </.form>
</div>;
```

Note: Haxe 4’s inline markup lexer does not support React-style fragment roots (`<> ... </>`). If fragment
syntax becomes available in a future Haxe release, we can adopt it to avoid wrapper elements.

## Interpolation and HEEx

Inline markup expressions are authored in Haxe:

- Text interpolation uses `${expr}` and is lowered to HEEx/EEx.
- Attribute interpolation uses `attr=${expr}` (and supports mixed static + interpolation).
- `assigns.*` is mapped to `@*` in HEEx where applicable.

## Template Modes

Inline markup is the default authoring surface because `${ ... }` splices are parsed into real Haxe expressions and type-checked.

However, the broader template system also supports legacy string-level markers (useful for migration), which are **not** Haxe-typed:

- `#{...}` interpolation markers
- `<if { ... }>` / `<for { ... }>` control tags

For new code, no HXX mode metadata is required:

```haxe
class MyLive {
  public static function render(assigns: Assigns): String {
    return <div>${assigns.count}</div>;
  }
}
```

Use `@:hxx_mode("balanced")` only for migration modules that still need legacy `hxx('...')` string templates. Use `@:hxx_mode("tsx")` only when you need to override an enclosing/global non-TSX mode back to the default.

In TSX mode, raw `<% ... %>` blocks and string-level markers are rejected.

## When to Use Legacy `hxx('...')`

Legacy string templates are a compatibility tool, not the happy path for new app code.

They are still useful when:

- Migrating an existing Phoenix/HEEx template gradually and you want to keep the source shape close to the original while moving logic into typed Haxe over time.
- Maintaining older Reflaxe.Elixir code that already uses `hxx('...')` and should be changed incrementally rather than rewritten all at once.
- Writing focused compatibility tests or examples that prove the legacy string-template path still lowers to valid HEEx.
- Temporarily isolating a template that depends on Haxe lexer edge cases that inline markup cannot express yet, such as a Phoenix dot-component as the root node.

Prefer inline markup even in migration modules as soon as you touch a template deeply. In `hxx('...')`,
markers such as `#{...}`, `${...}`, `<if { ... }>` and `<for { ... }>` are string-level constructs. They
are rewritten and linted, but they are not parsed as full Haxe AST in the same way inline markup splices are.

Raw HEEx (`<% ... %>` / `<%= ... %>`) is a stronger escape hatch than `hxx('...')`. Keep it out of new app
templates. If a migration truly needs it, isolate the scope with `@:allow_heex` in balanced mode or
`@:hxx_mode("metal")`, then plan to remove it.

Compiles to:

```elixir
def render(assigns) do
  ~H"<div><%= @count %></div>"
end
```

`tsx` is named after the TypeScript JSX authoring model: expressions inside template splices are real typed host-language expressions, not string-rewritten mini-languages.

TSX-mode control tags:

- `<if ${cond}> ... <else> ... </else> </if>`
- `<for ${item in items}> ... </for>`

Legacy marker headers with braces (`<if { ... }>` / `<for { ... }>` ) are rejected in TSX mode.

If you truly need raw HEEx, use `@:hxx_mode("metal")` (discouraged; emits warnings), or the explicit escape hatch `@:allow_heex` in a balanced migration scope. `@:allow_heex` is invalid in TSX mode. This is a local template escape hatch, not an application-wide authoring profile.

## Typed `phx-hook` / `phx-*` Names in Inline Markup

Recommended: author hook/event names as normal Haxe expressions:

```haxe
return <div phx-hook=${HookName.Ping}></div>;
```

Escape hatch: brace attributes like `phx-hook={HookName.Ping}` are still supported, but the inner
expression is raw text. To keep strict Phoenix typing usable (and to ensure generated HEEx is valid
Elixir), the compiler rewrites known string-constant references inside brace attributes into literal
binaries:

Haxe:

```haxe
@:phxHookNames
enum abstract HookName(String) from String to String {
  var Ping = "Ping";
}

return <div phx-hook={HookName.Ping}></div>;
```

Generated HEEx:

```elixir
<div phx-hook={"Ping"}></div>
```

This makes strict hook/event typing compatible with inline markup even when brace attributes are used.

## Editor Completions

The companion VSCode extension (`tools/vscode-hxx/`) reads `tmp/hxx-registry.json` and provides:

- Tag completions (dot-components and slot tags)
- Attribute completions for known component props and slot props
- Value completions (best-effort):
  - `phx-hook=` values from your `@:phxHookNames` registry (optionally narrowed by what the current template uses)
  - `phx-click=` / `phx-submit=` / `phx-change=` / etc values from the current LiveView’s derived events, falling back to global `@:phxEventNames` registries

It works inside both:
- `hxx('...')` / `HXX.hxx('...')` templates
- Inline markup literals (`<div ...>`)

Note: inline-markup completion detection is heuristic (it avoids triggering inside normal string literals).

## Performance

- **Runtime:** no impact (everything is compile-time).
- **Compile time:** there is a small extra AST walk only for scoped Phoenix-facing modules (or `@:hxx_inline_markup`).
