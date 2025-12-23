# HXX Template Architecture (Compile‑Time Only)

HXX is Reflaxe.Elixir’s **compile‑time** template system for generating Phoenix **HEEx** (`~H` sigils).

There is **no runtime HXX engine**: the generated Elixir contains standard Phoenix code only.

## The Entry Point: `HXX.hxx/1` and `HXX.block/1`

Reflaxe.Elixir ships a small, non‑inline stub in `std/HXX.hx`:

- `HXX.hxx(templateStr: String): String`
- `HXX.block(content: String): String`

These functions exist so user code can type‑check normally. The compiler **intercepts** calls to
`HXX.hxx`/`HXX.block` in the typed AST and lowers them into `~H"""..."""` during compilation.

## Build‑Time Lowering (TypedExpr → ElixirAST)

During AST building, the compiler:

1. Detects `HXX.hxx(...)` calls in the typed AST
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

## Minimal Example

Haxe:

```haxe
import phoenix.types.Assigns;

typedef AssignsData = { var title: String; }

function render(assigns: Assigns<AssignsData>): String {
  return HXX.hxx('<h1>${assigns.title}</h1>');
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

