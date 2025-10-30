package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * CaseListScrutineeHoistTransforms
 *
 * WHAT
 * - Hoists non-variable list scrutinees into a local variable before case
 *   matching, i.e., `case [..] do ... end` becomes `list_value = [..]; case list_value do ... end`.
 *
 * WHY
 * - Enables subsequent guard rewrites to reference head/tail binders and avoid
 *   undefined variables in guards (e.g., arr[0]) by providing a proper scrutinee
 *   variable in scope.
 *
 * HOW
 * - For ECase(scrutinee, clauses) where scrutinee is not EVar(_):
 *   emit EBlock([ list_value = scrutinee, case list_value do ... end ]).
 *   Keeps metadata/position.
 */
class CaseListScrutineeHoistTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case ECase(scrutinee, clauses):
          switch (scrutinee.def) {
            case EVar(_): n; // already a variable
            case EList(_):
              var varName = "list_value";
              var assign = makeASTWithMeta(EBinary(Match, makeAST(EVar(varName)), scrutinee), n.metadata, n.pos);
              var repairedClauses = rewriteGuardsToListVar(clauses, varName);
              var caze = makeASTWithMeta(ECase(makeAST(EVar(varName)), repairedClauses), n.metadata, n.pos);
              makeASTWithMeta(EBlock([assign, caze]), n.metadata, n.pos);
            case EBitstring(_):
              var varName2 = "bin_value";
              var assign2 = makeASTWithMeta(EBinary(Match, makeAST(EVar(varName2)), scrutinee), n.metadata, n.pos);
              var repairedClauses2 = rewriteGuardsToListVar(clauses, varName2);
              var caze2 = makeASTWithMeta(ECase(makeAST(EVar(varName2)), repairedClauses2), n.metadata, n.pos);
              makeASTWithMeta(EBlock([assign2, caze2]), n.metadata, n.pos);
          default:
              n; // do not hoist non-list scrutinees (e.g., length(list))
          }
        default:
          n;
      }
    });
  }

  public static function rewriteGuardsToListVar(clauses:Array<ECaseClause>, listVar:String):Array<ECaseClause> {
    var out:Array<ECaseClause> = [];
    for (cl in clauses) {
      var g = cl.guard;
      if (g != null) {
        g = ElixirASTTransformer.transformNode(g, function(m:ElixirAST):ElixirAST {
          return switch (m.def) {
            case EVar(v) if (v == "arr" || v == "data"): makeAST(EVar(listVar));
            default: m;
          }
        });
      }
      out.push({ pattern: cl.pattern, guard: g, body: cl.body });
    }
    return out;
  }
}

#end
