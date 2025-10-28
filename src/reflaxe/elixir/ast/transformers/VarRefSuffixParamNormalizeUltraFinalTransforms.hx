package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * VarRefSuffixParamNormalizeUltraFinalTransforms
 *
 * WHAT
 * - Ultra-final safeguard that, within a function that has a parameter ending
 *   with `_query`, rewrites free references to `query` to that parameter name
 *   (e.g., `search_query`).
 *
 * WHY
 * - Some late-ordering or predicate inlining shapes may still reference `query`
 *   when only `search_query` exists. Earlier passes handle this in most cases;
 *   this is a last-resort, strictly shape-based normalization that avoids
 *   application coupling and corrects undefined refs.
 *
 * HOW
 * - For each def/defp, detect exactly one parameter whose suffix is `_query`.
 * - Replace EVar("query") in the body subtree with EVar(<that_param>).
 */
class VarRefSuffixParamNormalizeUltraFinalTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body):
          var target = detectQueryParam(args);
          #if sys if (target != null) Sys.println('[VarRefSuffixParamNormalize_UltraFinal] def ' + name + ' query->' + target); #end
          if (target == null) n else makeASTWithMeta(EDef(name, args, guards, rewrite(body, target)), n.metadata, n.pos);
        case EDefp(name2, args2, guards2, body2):
          var target2 = detectQueryParam(args2);
          #if sys if (target2 != null) Sys.println('[VarRefSuffixParamNormalize_UltraFinal] defp ' + name2 + ' query->' + target2); #end
          if (target2 == null) n else makeASTWithMeta(EDefp(name2, args2, guards2, rewrite(body2, target2)), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function detectQueryParam(args:Array<EPattern>): Null<String> {
    if (args == null) return null;
    var candidate:Null<String> = null; var count = 0;
    for (a in args) switch (a) {
      case PVar(p):
        if (StringTools.endsWith(p, "_query")) { candidate = p; count++; }
      default:
    }
    return count == 1 ? candidate : null;
  }

  static function rewrite(body:ElixirAST, paramName:String): ElixirAST {
    return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case EVar(nm) if (nm == "query"):
          #if sys Sys.println('[VarRefSuffixParamNormalize_UltraFinal] rewrite query -> ' + paramName);
          #end
          makeASTWithMeta(EVar(paramName), x.metadata, x.pos);
        default: x;
      }
    });
  }
}

#end
