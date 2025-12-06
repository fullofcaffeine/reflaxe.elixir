package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * FilterPredicateMissingQueryFixTransforms
 *
 * WHAT
 * - In functions that have exactly one parameter ending with `_query`, rewrite
 *   any occurrences of the free variable `query` inside Enum.filter predicates
 *   to `String.downcase(<param>)`.
 *
 * WHY
 * - Some late transforms can produce references to `query` while only a
 *   `*_query` parameter exists. This pass ensures the predicate body uses a
 *   well-defined expression without relying on earlier binder promotions.
 */
class FilterPredicateMissingQueryFixTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body):
          var param = detectQueryParam(args);
          if (param == null) n else makeASTWithMeta(EDef(name, args, guards, rewrite(body, param)), n.metadata, n.pos);
        case EDefp(name2, args2, guards2, body2):
          var param2 = detectQueryParam(args2);
          if (param2 == null) n else makeASTWithMeta(EDefp(name2, args2, guards2, rewrite(body2, param2)), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function detectQueryParam(args:Array<EPattern>): Null<String> {
    if (args == null) return null; var found:Null<String> = null; var count = 0;
    for (a in args) switch (a) { case PVar(n) if (StringTools.endsWith(n, "_query")): found = n; count++; default: }
    return count == 1 ? found : null;
  }

  static function rewrite(body: ElixirAST, qparam:String): ElixirAST {
    function inlineInPredicate(pred: ElixirAST): ElixirAST {
      return ElixirASTTransformer.transformNode(pred, function(x: ElixirAST): ElixirAST {
        return switch (x.def) {
          case EVar(nm) if (nm == "query"):
            makeASTWithMeta(ERemoteCall(makeAST(EVar("String")), "downcase", [makeAST(EVar(qparam))]), x.metadata, x.pos);
          default: x;
        }
      });
    }
    return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case ERemoteCall({def: EVar(m)}, "filter", args) if (m == "Enum" && args != null && args.length == 2):
          var newPred = inlineInPredicate(args[1]);
          makeASTWithMeta(ERemoteCall(makeAST(EVar("Enum")), "filter", [args[0], newPred]), x.metadata, x.pos);
        case ECall(target, "filter", args2) if (args2 != null && args2.length >= 1):
          var last = args2[args2.length - 1];
          var newPred2 = inlineInPredicate(last);
          var prefix = args2.slice(0, args2.length - 1);
          makeASTWithMeta(ECall(target, "filter", prefix.concat([newPred2])), x.metadata, x.pos);
        default:
          x;
      }
    });
  }
}

#end

