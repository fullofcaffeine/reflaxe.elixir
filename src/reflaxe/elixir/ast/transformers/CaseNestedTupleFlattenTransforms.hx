package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ElixirASTHelpers;

/**
 * CaseNestedTupleFlattenTransforms
 *
 * WHAT
 * - Flattens nested case-of-variable patterns into a single case with merged
 *   tuple patterns when the outer clause binds the same variable that the inner
 *   case scrutinizes. Also rewrites body references from the outer binder to
 *   the inner tuple payload binder to preserve semantics.
 *
 * WHY
 * - Generators often produce:
 *     case parse(msg) do
 *       {:some, v} ->
 *         case v do
 *           {:tag, b} -> body(v, b)
 *         end
 *       {:none} -> else_body
 *     end
 *   which is harder to transform and can retain references to the outer
 *   scrutinee (v) instead of the inner payload (b). Flattening improves shape
 *   for downstream passes and eliminates stale references.
 *
 * HOW
 * - For each ECase(outerExpr, clauses):
 *   - If a clause pattern is PTuple([outerTag, PVar(v)]) and its body is an
 *     ECase(EVar(v), innerClauses), replace that single clause with multiple
 *     clauses by merging patterns: PTuple([outerTag, innerPattern]) and a body
 *     that substitutes EVar(v) → inner payload binder (when present) across the
 *     inner clause body.
 *   - Other clauses unchanged.
 */
class CaseNestedTupleFlattenTransforms {
  public static function transformPass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case ECase(outerExpr, outerClauses):
          var flattened:Array<ECaseClause> = [];
          var changed = false;
          for (cl in outerClauses) {
            var outerTagPat:Null<EPattern> = null;
            var outerVar:Null<String> = null;
            switch (cl.pattern) {
              case PTuple(parts) if (parts.length == 2):
                // First element can be any literal/tag; keep as-is
                outerTagPat = parts[0];
                switch (parts[1]) {
                  case PVar(v): outerVar = v;
                  default:
                }
              default:
            }
            // Only consider when pattern is {:tag, v} and body is case v do ... end
            if (outerTagPat != null && outerVar != null) switch (cl.body.def) {
              case ECase(innerScrut, innerClauses):
                switch (innerScrut.def) {
                  case EVar(s) if (s == outerVar):
                    // Merge each inner clause into an outer clause
                    for (ic in innerClauses) {
                      var newPat:EPattern = PTuple([outerTagPat, ic.pattern]);
                      var binder = extractSecondBinder(ic.pattern);
                      var newBody = (binder == null)
                        ? ic.body
                        : ElixirASTHelpers.replaceVarInAST(ic.body, outerVar, makeAST(EVar(binder)));
                      flattened.push({ pattern: newPat, guard: ic.guard, body: newBody });
                    }
                    changed = true;
                  default:
                    // Body inner case not over the same var; keep original clause
                    flattened.push(cl);
                }
              default:
                flattened.push(cl);
            } else {
              flattened.push(cl);
            }
          }
          if (changed) makeASTWithMeta(ECase(outerExpr, flattened), n.metadata, n.pos) else n;
        default:
          n;
      }
    });
  }

  static function extractSecondBinder(p:EPattern): Null<String> {
    return switch (p) {
      case PTuple(items) if (items.length == 2):
        switch (items[1]) {
          case PVar(n): n;
          case PPin(inner): switch (inner) { case PVar(n2): n2; default: null; };
          default: null;
        }
      default: null;
    }
  }

  // No generic substituteVar needed; we rely on ElixirASTHelpers.replaceVarInAST
}

#end
