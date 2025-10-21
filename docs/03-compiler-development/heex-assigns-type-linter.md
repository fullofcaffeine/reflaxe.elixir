# HEEx Assigns Type Linter (HeexAssignsTypeLinterTransforms)

## WHAT
- A compiler pass that statically validates `@assigns` usage inside `~H` templates (HEEx) produced from HXX strings.
- Detects:
  1) Unknown assigns fields (e.g., `@srot_by` when only `sort_by` exists)
  2) Obvious literal type mismatches involving `@field` (e.g., `@sort_by == 1` when `sort_by: String`)

## WHY
- HXX expressions like `${assigns.show_form}` are type-checked by Haxe because they are real Haxe expressions.
- Raw HEEx content (inside an HXX string literal) is not visible to the Haxe typer. Authors may write `@field` or HEEx control blocks directly. This pass bridges the gap and gives compile-time feedback even for raw `~H` content.

## HOW (High Level)
1) HXX.hxx('...') content is normalized to `~H` (HeexStringReturnToSigilTransforms) and control tags like `<if {cond}>` are rewritten (HeexControlTagTransforms).
2) HeexAssignsTypeLinterTransforms runs over resulting `~H` contents:
   - Finds the `render(assigns: TAssigns)` function and extracts the `typedef` for `TAssigns` from the original Haxe source file.
   - Scans `~H` content for `@field` usages and literal comparisons (numbers, strings, true/false, nil).
   - Reports errors via the Haxe CompilationContext (build fails before Elixir).

## EXAMPLES
### Unknown Field
```haxe
typedef Assigns = { var sort_by: String; }
class Main {
  static function render(assigns: Assigns): String {
    return HXX.hxx('<div><p>Sort: <%= @srot_by %></p></div>'); // @srot_by (typo)
  }
}
// Error: HEEx assigns error: Unknown field @srot_by (not found in typedef Assigns)
```

### Literal Type Mismatch
```haxe
typedef Assigns = { var sort_by: String; }
class Main {
  static function render(assigns: Assigns): String {
    return HXX.hxx('<div><%= if @sort_by == 1 do %>Wrong<% else %>OK<% end %></div>');
  }
}
// Error: @sort_by is String; compared to Int literal 1
```

## LIMITATIONS (Current)
- Checks literal comparisons only (simple kinds); does not fully type complex expressions inside HEEx yet.
- Relies on parsing the originating Haxe file to extract the assigns typedef.

## RELATIONSHIP TO HXX TYPING
- HXX expressions `${assigns.field}` are type-checked by Haxe directly.
- This linter complements that by checking `@field` usages in raw `~H`.
- Together, they provide strong typing across both HXX expressions and HEEx blocks.

## PASS REGISTRATION
- Registered in `ElixirASTPassRegistry` after `~H` materialization and control tag rewrite.
- Files: `src/reflaxe/elixir/ast/transformers/HeexAssignsTypeLinterTransforms.hx`

## TESTS
- Negative tests:
  - `test/snapshot/negative/HXXAssignsLinterErrors/` — raw HEEx `@field` unknown + type mismatch
  - `test/snapshot/negative/hxx_block_if_invalid/` — HXX block-if using unknown `assigns.*` 

