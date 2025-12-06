package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ElixirASTPrinter;

/**
 * DebugDumpQueryFunctionBodiesTransforms
 * - Debug-only: print the printed body of any def/defp that has exactly one
 *   parameter ending with `_query` to verify final shapes before print.
 */
class DebugDumpQueryFunctionBodiesTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      switch (n.def) {
        case EDef(name, args, _, body):
          var q = qparam(args);
          if (q != null) {
          }
        case EDefp(name2, args2, _, body2):
          var q2 = qparam(args2);
          if (q2 != null) {
          }
        default:
      }
      return n;
    });
  }
  static function qparam(args:Array<EPattern>): Null<String> {
    if (args == null) return null; var found:Null<String>=null; var count=0;
    for (a in args) switch (a) { case PVar(n) if (StringTools.endsWith(n, '_query')): found=n; count++; default: }
    return count == 1 ? found : null;
  }
}

#end

