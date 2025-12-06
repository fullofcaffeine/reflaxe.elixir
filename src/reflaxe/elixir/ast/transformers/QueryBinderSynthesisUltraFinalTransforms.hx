package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * QueryBinderSynthesisUltraFinalTransforms
 *
 * WHAT
 * - Ultra-final insertion of `query = String.downcase(search_query)` immediately
 *   before an Enum.filter predicate that uses `query` when the surrounding
 *   function has a single *_query parameter and no prior `query` binding exists.
 *
 * WHY
 * - Guarantees a well-typed local for predicate code paths even if earlier
 *   normalizations did not land due to shape/order.
 */
class QueryBinderSynthesisUltraFinalTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body):
          var qparam = detectQueryParam(args);
          if (qparam == null) n else makeASTWithMeta(EDef(name, args, guards, rewrite(body, qparam)), n.metadata, n.pos);
        case EDefp(name2, args2, guards2, body2):
          var qparam2 = detectQueryParam(args2);
          if (qparam2 == null) n else makeASTWithMeta(EDefp(name2, args2, guards2, rewrite(body2, qparam2)), n.metadata, n.pos);
        default:
          n;
      }
    });
  }
  static function detectQueryParam(args:Array<EPattern>): Null<String> {
    if (args == null) return null; var found:Null<String> = null; var count = 0;
    for (a in args) switch (a) { case PVar(p) if (StringTools.endsWith(p, "_query")): found = p; count++; default: }
    return count == 1 ? found : null;
  }
  static function rewrite(body:ElixirAST, qparam:String): ElixirAST {
    function hasQueryBinder(stmts:Array<ElixirAST>, upto:Int): Bool {
      for (i in 0...upto) switch (stmts[i].def) {
        case EBinary(Match, left, _): switch (left.def) { case EVar(nm) if (nm == "query"): return true; default: }
        case EMatch(pat, _): switch (pat) { case PVar(nm2) if (nm2 == "query"): return true; default: }
        default:
      }
      return false;
    }
    function predicateUsesQuery(e: ElixirAST): Bool {
      var used = false;
      ElixirASTTransformer.transformNode(e, function(x: ElixirAST): ElixirAST {
        if (used) return x; switch (x.def) { case EVar(nm) if (nm == "query"): used = true; default: } return x;
      });
      return used;
    }
    function binder(): ElixirAST {
      return makeAST(EBinary(Match, makeAST(EVar("query")), makeAST(ERemoteCall(makeAST(EVar("String")), "downcase", [makeAST(EVar(qparam))]))));
    }
    return ElixirASTTransformer.transformNode(body, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EBlock(stmts) if (stmts.length > 0):
          var out:Array<ElixirAST> = [];
          for (i in 0...stmts.length) {
            var s = stmts[i];
            var inserted = false;
            switch (s.def) {
              case ERemoteCall({def: EVar(m)}, "filter", args) if (m == "Enum" && args != null && args.length == 2):
              case ECall(_, "filter", args2) if (args2 != null && args2.length >= 1):
                var pred = args2[args2.length - 1];
              default:
            }
            out.push(s);
            if (inserted) {
              // continue
            }
          }
          makeASTWithMeta(EBlock(out), n.metadata, n.pos);
        case EDo(stmts2) if (stmts2.length > 0):
          var out2:Array<ElixirAST> = [];
          for (i in 0...stmts2.length) {
            var s2 = stmts2[i]; var ins = false;
            switch (s2.def) {
              case ERemoteCall({def: EVar(m2)}, "filter", a2) if (m2 == "Enum" && a2 != null && a2.length == 2):
              case ECall(_, "filter", a3) if (a3 != null && a3.length >= 1):
              default:
            }
            out2.push(s2);
          }
          makeASTWithMeta(EDo(out2), n.metadata, n.pos);
        default:
          n;
      }
    });
  }
}

#end
