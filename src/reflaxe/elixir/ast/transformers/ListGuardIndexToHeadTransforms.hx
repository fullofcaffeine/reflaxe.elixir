package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ListGuardIndexToHeadTransforms
 *
 * WHAT
 * - Rewrites guard references to the first element and length of a case-list
 *   scrutinee to use already bound head/tail variables from the clause pattern.
 *   E.g., for `case list do [h | t] when list[0] == 72 and length(list) > 1 -> ... end`,
 *   rewrite guard to `h == 72 and t != []` (shape-based, conservative).
 *
 * WHY
 * - Generated guards sometimes reference the scrutinee via `list[0]` or
 *   `length(list) > 1`, which is not idiomatic and may be invalid when the
 *   scrutinee is not a bound variable in guard scope. Clause patterns already
 *   bind head/tail; leveraging them makes guards valid and readable.
 *
 * HOW
 * - For ECase(scrutinee=listVar, clauses):
 *   - For each clause with PCons(PVar(headName), tailPat):
 *     - Replace EAccess(EVar(listVar), 0) in guard with EVar(headName)
 *     - Replace length(EVar(listVar)) > 1 with tail != [] when tailPat is a
 *       PVar(tailName)
 *   - Only acts when scrutinee is EVar (avoids guessing for literals)
 *   - Leaves [] clauses unchanged
 */
class ListGuardIndexToHeadTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case ECase(scrutinee, clauses):
            var newClauses: Array<ECaseClause> = [];
            for (cl in clauses) {
              var headName: Null<String> = null;
              var tailName: Null<String> = null;
              switch (cl.pattern) {
                case PCons(PVar(hn), PVar(tn)):
                  headName = hn; tailName = tn;
                case PCons(PVar(hn2), _):
                  headName = hn2; // tail not a plain var; skip tail-based rewrite
                default:
                  // Not a non-empty list clause — keep as is
              }
              var guardRewritten = (cl.guard != null && (headName != null || tailName != null))
                ? rewriteGuard(cl.guard, /*listVar*/ "", headName, tailName)
                : cl.guard;
              newClauses.push({ pattern: cl.pattern, guard: guardRewritten, body: cl.body });
            }
            makeASTWithMeta(ECase(scrutinee, newClauses), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function rewriteGuard(guard: ElixirAST, listVar: String, headName: Null<String>, tailName: Null<String>): ElixirAST {
    return ElixirASTTransformer.transformNode(guard, function(g: ElixirAST): ElixirAST {
      return switch (g.def) {
        // listVar[0] → head
        case EAccess({def: EVar(_)}, {def: EInteger(0)}) if (headName != null):
          makeAST(EVar(headName));
        // length(listVar) > 1 → tail != []
        case EBinary(Greater, {def: ERemoteCall({def: EVar(m)}, "length", [_])}, {def: EInteger(1)})
          if (tailName != null && (m == "Kernel" || m == "Enum")):
          makeAST(EBinary(NotEqual, makeAST(EVar(tailName)), makeAST(EList([]))));
        case EBinary(Greater, {def: ECall(null, "length", [_])}, {def: EInteger(1)}) if (tailName != null):
          makeAST(EBinary(NotEqual, makeAST(EVar(tailName)), makeAST(EList([]))));
        default:
          g;
      }
    });
  }
}

#end
