package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * DowncaseParamThenFilterPredicateNormalizeTransforms
 *
 * WHAT
 * - When a function with a single *_query parameter performs an in-place
 *   downcase of that parameter (`p = String.downcase(p)`) followed immediately
 *   by `Enum.filter(base, fn ... -> ... query ... end)`, rewrite any free
 *   `query` references inside the predicate to `p`.
 *
 * WHY
 * - Ensures the predicate uses the lowered variable already computed in the
 *   prior statement, fixing undefined `query` without app-specific names.
 */
class DowncaseParamThenFilterPredicateNormalizeTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body):
          var qp = detectQueryParam(args);
          if (qp == null) n else makeASTWithMeta(EDef(name, args, guards, normalize(body, qp)), n.metadata, n.pos);
        case EDefp(name2, args2, guards2, body2):
          var qp2 = detectQueryParam(args2);
          if (qp2 == null) n else makeASTWithMeta(EDefp(name2, args2, guards2, normalize(body2, qp2)), n.metadata, n.pos);
        default: n;
      }
    });
  }
  static function detectQueryParam(args:Array<EPattern>): Null<String> {
    if (args == null) return null; var one:Null<String> = null; var cnt = 0;
    for (a in args) switch (a) { case PVar(n) if (StringTools.endsWith(n, "_query")): one = n; cnt++; default: }
    return cnt == 1 ? one : null;
  }
  static function isDowncaseAssignOf(param:String, stmt:ElixirAST): Bool {
    return switch (stmt.def) {
      case EBinary(Match, {def: EVar(lhs)}, rhs) if (lhs == param): isDowncaseOfParam(param, rhs);
      case EMatch(PVar(lhs2), rhs2) if (lhs2 == param): isDowncaseOfParam(param, rhs2);
      default: false;
    }
  }
  static function isDowncaseOfParam(param:String, e:ElixirAST): Bool {
    return switch (e.def) {
      case ERemoteCall({def: EVar(m)}, "downcase", args) if (m == "String" && args != null && args.length == 1):
        switch (args[0].def) { case EVar(v) if (v == param): true; default: false; }
      default: false;
    }
  }
  static function rewriteQueryToParam(pred:ElixirAST, param:String): ElixirAST {
    return ElixirASTTransformer.transformNode(pred, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case EVar(nm) if (nm == "query"):
          #if sys Sys.println('[DowncaseParamThenFilter] query -> ' + param); #end
          makeASTWithMeta(EVar(param), x.metadata, x.pos);
        default: x;
      }
    });
  }
  static function normalize(body:ElixirAST, param:String): ElixirAST {
    return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case EBlock(stmts) if (stmts.length >= 2):
          var out = [];
          var i = 0;
          while (i < stmts.length) {
            var s = stmts[i];
            if (i + 1 < stmts.length && isDowncaseAssignOf(param, s)) {
              #if sys Sys.println('[DowncaseParamThenFilter] detected downcase assign of ' + param + ' before possible Enum.filter'); #end
              var next = stmts[i + 1];
              switch (next.def) {
                case ERemoteCall({def: EVar(m)}, "filter", args) if (m == "Enum" && args != null && args.length == 2):
                  #if sys Sys.println('[DowncaseParamThenFilter] rewriting Enum.filter(remote) predicate query→' + param); #end
                  var np = rewriteQueryToParam(args[1], param);
                  out.push(s);
                  out.push(makeASTWithMeta(ERemoteCall(makeAST(EVar("Enum")), "filter", [args[0], np]), next.metadata, next.pos));
                  i += 2; continue;
                case ECall(tgt, "filter", args2) if (args2 != null && args2.length >= 1):
                  #if sys Sys.println('[DowncaseParamThenFilter] rewriting Enum.filter(call) predicate query→' + param); #end
                  var last = args2[args2.length - 1];
                  var np2 = rewriteQueryToParam(last, param);
                  var prefix = args2.slice(0, args2.length - 1);
                  out.push(s);
                  out.push(makeASTWithMeta(ECall(tgt, "filter", prefix.concat([np2])), next.metadata, next.pos));
                  i += 2; continue;
                default:
              }
            }
            out.push(s);
            i++;
          }
          makeASTWithMeta(EBlock(out), x.metadata, x.pos);
        default: x;
      }
    });
  }
}

#end
