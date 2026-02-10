# Inline Markup: TSX‑Like Authoring for Phoenix HEEx

Haxe supports “inline markup” literals:

```haxe
return <div class="counter">
  <h1>${assigns.count}</h1>
</div>;
```

In Reflaxe.Elixir, inline markup is syntax sugar over a compiler-intercepted template entrypoint:

- Inline markup becomes `@:markup "<div ...>...</div>"` (a string constant with metadata).
- A build macro rewrites `@:markup` into `phoenix.hxx.HeexTemplate.root(<typed template expr>)` before typing.
- The compiler lowers `HeexTemplate.root/1` to `~H"""..."""` deterministically (same lowering strategy as `HXX.hxx/1`).

Inline markup parsing extracts `${ ... }` segments and converts them into real Haxe expressions via `Context.parseInlineString`,
so the Haxe typer checks syntax and types.

Legacy note: `@:hxx_legacy` forces the old "rewrite to `HXX.hxx(\"...\")`" behavior for migration.

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

### Loops (avoid HTML-as-string)

In HEEx, returning an HTML string from `<%= ... %>` escapes tags, so you should not build markup by `Enum.join(...)`.

Use `phoenix.hxx.HeexTemplate.for_each/2` instead:

```haxe
import phoenix.hxx.HeexTemplate;

typedef Item = { var name: String; };

return <ul>
  ${HeexTemplate.for_each(assigns.items, (item) -> <li>${item.name}</li>)}
</ul>;
```

This lowers to a HEEx `for` block so the body is parsed as markup, not an escaped string.

## Defaults and Opt-Out

- Inline markup rewrite is enabled by default for Phoenix-facing modules.
- Opt out globally: `-D hxx_no_inline_markup`
- Opt out per module: `@:hxx_no_inline_markup`
- Force legacy rewrite per module: `@:hxx_legacy`

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

Inline markup is the recommended authoring surface because `${ ... }` splices are parsed into real Haxe expressions and type-checked.

However, the broader template system also supports legacy string-level markers (useful for migration), which are **not** Haxe-typed:

- `#{...}` interpolation markers
- `<if { ... }>` / `<for { ... }>` control tags

If you want to enforce a fully-typed TSX-like style, enable TSX mode:

```haxe
@:hxx_mode("tsx")
class MyLive {
  public static function render(assigns: Assigns): String {
    return <div>${assigns.count}</div>;
  }
}
```

In TSX mode, raw `<% ... %>` blocks and string-level markers are rejected.

If you truly need raw HEEx, use `@:hxx_mode("metal")` (discouraged; emits warnings), or the explicit escape hatch `@:allow_heex`.

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
