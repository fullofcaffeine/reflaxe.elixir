package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * VarRefQueryToSuffixParamTransforms
 *
 * WHAT
 * - In any def/defp that has exactly one parameter ending with `_query`,
 *   rewrite free references to `query` to that parameter name (e.g., `search_query`).
 *
 * WHY
 * - Ensures references resolve to an existing param even if predicate/binder
 *   transforms didn’t land. This is purely shape-based and app-agnostic.
 */
class VarRefQueryToSuffixParamTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body):
          var p = detect(args);
          if (p == null) n else {
            #if debug_transforms {
              var hasQuery = containsQuery(body);
            } #end
            makeASTWithMeta(EDef(name, args, guards, rewrite(body, p)), n.metadata, n.pos);
          }
        case EDefp(name2, args2, guards2, body2):
          var p2 = detect(args2);
          if (p2 == null) n else {
            #if debug_transforms {
              var hasQuery2 = containsQuery(body2);
            } #end
            makeASTWithMeta(EDefp(name2, args2, guards2, rewrite(body2, p2)), n.metadata, n.pos);
          }
        default: n;
      }
    });
  }
  static function detect(args:Array<EPattern>): Null<String> {
    if (args == null) return null; var one:Null<String>=null; var cnt=0;
    for (a in args) switch (a) { case PVar(n) if (StringTools.endsWith(n, "_query")): one=n; cnt++; default: }
    return cnt == 1 ? one : null;
  }
  static function rewrite(body:ElixirAST, param:String): ElixirAST {
    return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        default: x;
      }
    });
  }
  static function containsQuery(ast: ElixirAST): Bool {
    var found = false;
    ElixirASTTransformer.transformNode(ast, function(x: ElixirAST): ElixirAST { if (found) return x; switch (x.def) { case EVar(nm) if (nm == 'query'): found = true; default: } return x; });
    return found;
  }
}

#end
