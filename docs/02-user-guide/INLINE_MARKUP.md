# Inline Markup (Optional): TSX‑Like Sugar Over `hxx('...')`

Haxe supports “inline markup” literals:

```haxe
return <div class="counter">
  <h1>${assigns.count}</h1>
</div>;
```

In Reflaxe.Elixir, inline markup is **pure syntax sugar** over HXX:

- Haxe parses inline markup as `@:markup "<div ...>...</div>"` (a string constant with metadata).
- The compiler normally rejects `@:markup` during typing (“Markup literals must be processed by a macro”).
- Reflaxe.Elixir provides an opt‑in macro (`InlineMarkup`) that rewrites these expressions into `HXX.hxx("...")`
  before typing.
- After rewrite, the standard HXX → HEEx pipeline runs (assigns mapping, attribute normalization, strict checks, etc).

This means inline markup:
- Generates the **same Elixir** as `hxx('...')`.
- Has **no runtime cost**.
- Uses the **same type checking and HXX linting** once rewritten.

## Enabling

Inline markup is **opt‑in** to avoid any compilation overhead unless you want it.

Add the define to your `.hxml` / build:

```hxml
-D hxx_inline_markup
```

## Where It Runs (Scope)

Even when enabled, the rewrite is scoped to keep overhead minimal:

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

Implementation: `src/reflaxe/elixir/macros/InlineMarkup.hx`.

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

Inline markup is still **HXX text** under the hood, so the rules are the same:

- Text interpolation uses `${expr}` and is lowered to HEEx/EEx.
- Attribute interpolation uses `attr=${expr}`.
- `assigns.*` is mapped to `@*` in HEEx.

## Editor Completions

The companion VSCode extension (`tools/vscode-hxx/`) reads `tmp/hxx-registry.json` and provides:

- Tag completions (dot-components and slot tags)
- Attribute completions for known component props and slot props

It works inside both:
- `hxx('...')` / `HXX.hxx('...')` templates
- Inline markup literals (`<div ...>`) when `-D hxx_inline_markup` is enabled

Note: inline-markup completion detection is heuristic (it avoids triggering inside normal string literals).

## Performance

- **Runtime:** no impact (everything is compile-time).
- **Compile time:** there is a small extra AST walk *only* when `-D hxx_inline_markup` is enabled and only for
  the scoped Phoenix-facing modules (or `@:hxx_inline_markup`).
