# HXX Template Architecture (Compile‑Time Only)

HXX is Reflaxe.Elixir’s **compile‑time** template system for generating Phoenix **HEEx** (`~H` sigils).

> [!NOTE]
> This is an **advanced** architecture doc. Examples here illustrate internal lowering shapes and are not CI-smoked as “copy/paste commands”.

There is **no runtime HXX engine**: the generated Elixir contains standard Phoenix code only.

## The Entry Point: `HXX.hxx/1` and `HXX.block/1`

Reflaxe.Elixir ships a small, non‑inline stub in `std/HXX.hx`:

- `HXX.hxx(templateStr: String): String` (commonly used as `hxx('...')` via `import HXX.*;`)
- `HXX.block(content: String): String`

These functions exist so user code can type‑check normally. The compiler **intercepts** calls to
`HXX.hxx`/`HXX.block` in the typed AST and lowers them into `~H"""..."""` during compilation.

## Build‑Time Lowering (TypedExpr → ElixirAST)

During AST building, the compiler:

1. Detects `HXX.hxx(...)` calls in the typed AST (including unqualified `hxx(...)` calls via `import HXX.*;`)
2. Collects the template string (including concatenation shapes created by Haxe interpolation)
3. Converts HXX/HTML conventions into HEEx‑compatible content
4. Emits an Elixir AST sigil node representing `~H"""..."""`

Relevant implementation entrypoints:

- `src/reflaxe/elixir/ast/ElixirASTBuilder.hx` (HXX detection + template collection)
- `src/reflaxe/elixir/ast/TemplateHelpers.hx` (helpers used by the builder)

## Output

The printer renders the sigil AST node as standard Phoenix HEEx:

```elixir
~H"""
<div>Hello</div>
"""
```

No HXX module/function calls remain in the generated output.

## Nested Fragments with `HXX.block/1`

`HXX.block(...)` marks nested fragments that should be **inlined** inside an outer `HXX.hxx(...)`
without introducing extra interpolation wrappers. This is useful for composing template helpers.

## No Runtime Artifacts

Compile‑time‑only helper modules (including HXX helpers) are suppressed from emission when they
would otherwise produce empty/no‑runtime `.ex` files. This keeps generated projects “pure Phoenix”.

## Optional: Macro‑Validated HXX

There is also an optional macro implementation (`reflaxe.elixir.macros.HXX`) which can validate
and pre‑process string literals, tagging them for the builder. The **recommended default** for
applications is the `std/HXX.hx` stub + AST‑intercept path to avoid nested macro forwarding issues.

## Optional: Inline Markup (Syntax Sugar)

Haxe also supports inline markup literals (`return <div>...</div>`). Reflaxe.Elixir enables these
as **syntax sugar** over HXX by rewriting `@:markup "..."` (the parser representation) into
`HXX.hxx("...")` before typing, so the existing HXX pipeline and linters apply.

Implementation:
- `src/reflaxe/elixir/macros/InlineMarkup.hx`
- Opt-in via `-D hxx_inline_markup` (the macro is wired from `src/reflaxe/elixir/CompilerInit.hx`)

Limitations:
- Haxe’s markup lexer requires a valid XML root tag name. Phoenix dot-components like `<.form>` can’t be the root
  of an inline markup literal; wrap them in a fragment `<> ... </>` (or a normal element).

Performance:
- Inline markup has no runtime cost. Compile-time overhead is a small additional AST walk to rewrite `@:markup` into `HXX.hxx(...)`.

## Minimal Example

Haxe:

```haxe
import HXX.*;
import phoenix.types.Assigns;

typedef AssignsData = { var title: String; }

function render(assigns: Assigns<AssignsData>): String {
  return hxx('<h1>${assigns.title}</h1>');
}
```

Generated Elixir:

```elixir
def render(assigns) do
  ~H"""
  <h1>{assigns.title}</h1>
  """
end
```
