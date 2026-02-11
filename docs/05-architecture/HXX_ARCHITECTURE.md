# HXX Template Architecture (Compile‑Time Only)

HXX is Reflaxe.Elixir’s **compile‑time** template system for generating Phoenix **HEEx** (`~H` sigils).

> [!NOTE]
> This is an **advanced** architecture doc. Examples here illustrate internal lowering shapes and are not CI-smoked as “copy/paste commands”.

There is **no runtime HXX engine**: the generated Elixir contains standard Phoenix code only.

## Entry Points (Typed-first)

Recommended template producers:

- `phoenix.hxx.HeexTemplate.root/1` (and `root_ast/1` for TSX AST mode)
- `phoenix.hxx.H.root/1` / `H.root_ast/1` (short aliases)

Legacy migration producers (still supported):

- `HXX.hxx/1`
- `HXX.block/1`

Reflaxe.Elixir ships compile-time-only stubs for these entrypoints:

- `std/phoenix/hxx/HeexTemplate.hx`
- `std/phoenix/hxx/H.hx`
- `std/HXX.hx`

These functions exist so user code can type-check normally. The compiler **intercepts** calls to
template producers in the typed AST and lowers them into `~H"""..."""` during compilation.

## Build‑Time Lowering (TypedExpr → ElixirAST)

During AST building, the compiler:

1. Detects template producer calls in the typed AST (`HeexTemplate.root`, `H.root`, `HXX.hxx`, etc.)
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

## Nested Fragments with `HXX.block/1` (Legacy)

`HXX.block(...)` marks nested fragments that should be **inlined** inside an outer `HXX.hxx(...)`
without introducing extra interpolation wrappers. This is useful for composing template helpers.

## No Runtime Artifacts

Compile‑time‑only helper modules (including HXX helpers) are suppressed from emission when they
would otherwise produce empty/no‑runtime `.ex` files. This keeps generated projects “pure Phoenix”.

## Optional: Macro‑Validated HXX (Legacy path)

There is also an optional macro implementation (`reflaxe.elixir.macros.HXX`) which can validate
and pre‑process string literals, tagging them for the builder. The **recommended default** for
applications is the `std/HXX.hx` stub + AST‑intercept path to avoid nested macro forwarding issues.

## Optional: Inline Markup (Syntax Sugar)

Haxe also supports inline markup literals (`return <div>...</div>`). Reflaxe.Elixir enables these
as syntax sugar by rewriting `@:markup "..."` (the parser representation) into a canonical,
compiler-intercepted template entrypoint: `phoenix.hxx.HeexTemplate.root(...)`.

Implementation:
- `src/reflaxe/elixir/macros/InlineMarkup.hx`
- Default-on for Phoenix-facing modules; opt out with `-D hxx_no_inline_markup` / `@:hxx_no_inline_markup`
- Legacy escape hatch: `@:hxx_legacy` forces the old rewrite-to-`HXX.hxx("...")` behavior for that class

How it works (high-level):
- Haxe parses `<div>...</div>` into an expression `@:markup "<div>...</div>"`.
- The `InlineMarkup` build macro walks expressions and rewrites `@:markup` into `HeexTemplate.root(<typedExpr>)`.
- `${ ... }` segments inside the markup payload are parsed into real Haxe expressions (`Context.parseInlineString`),
  so the Haxe typer checks syntax and types.
- The AST builder lowers `HeexTemplate.root/1` to `~H"""..."""` deterministically.
- The rewrite is copy-on-write and scoped to Phoenix-facing modules to keep overhead minimal.

Limitations:
- Haxe’s markup lexer requires a valid XML root tag name. Phoenix dot-components like `<.form>` can’t be the root
  of an inline markup literal; wrap them in a normal element (e.g. `<div>...</div>`).

Strict phx-hook / phx-event typing:
- Inline markup brace attribute expressions are raw text. For common patterns like `phx-hook={HookName.Ping}` /
  `phx-click={EventName.Save}`, the HEEx transformer rewrites those constant references into string literals
  (e.g. `phx-hook={"Ping"}`) so output is valid Elixir and strict linters can treat them as compile-time constants.

Performance:
Inline markup has no runtime cost. Compile-time overhead is a small additional AST walk to rewrite `@:markup` and parse `${...}` segments.

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
  <h1><%= @title %></h1>
  """
end
```
