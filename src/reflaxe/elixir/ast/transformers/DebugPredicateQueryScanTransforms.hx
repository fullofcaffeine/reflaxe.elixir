package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ElixirASTPrinter;

/**
 * DebugPredicateQueryScanTransforms
 * - Debug-only: for functions with a single *_query param, detect Enum.filter
 *   predicates that reference `query` and print the predicate body.
 */
class DebugPredicateQueryScanTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body):
          var qp = detectQueryParam(args);
          if (qp != null) scan(name, qp, body);
          n;
        case EDefp(name2, args2, guards2, body2):
          var qp2 = detectQueryParam(args2);
          if (qp2 != null) scan(name2, qp2, body2);
          n;
        default: n;
      }
    });
  }
  static function detectQueryParam(args:Array<EPattern>): Null<String> {
    if (args == null) return null; var found:Null<String> = null; var count=0;
    for (a in args) switch (a) { case PVar(n) if (StringTools.endsWith(n, "_query")): found = n; count++; default: }
    return count == 1 ? found : null;
  }
  static function scan(fname:String, qparam:String, body:ElixirAST): Void {
    ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      switch (x.def) {
        case ERemoteCall({def: EVar(m)}, "filter", args) if (m == "Enum" && args != null && args.length == 2):
          if (predUsesQuery(args[1])) {
          }
        case ECall(_, "filter", args2) if (args2 != null && args2.length >= 1):
          var pred = args2[args2.length - 1];
          if (predUsesQuery(pred)) {
          }
        default:
      }
      return x;
    });
  }
  static function predUsesQuery(pred:ElixirAST): Bool {
    var used = false;
    ElixirASTTransformer.transformNode(pred, function(y:ElixirAST): ElixirAST { if (used) return y; switch (y.def) { case EVar(nm) if (nm == 'query'): used = true; default: } return y; });
    return used;
  }
}

#end

