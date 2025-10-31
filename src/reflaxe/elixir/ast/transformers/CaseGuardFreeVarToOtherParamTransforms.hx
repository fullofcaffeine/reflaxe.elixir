package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;

/**
 * CaseGuardFreeVarToOtherParamTransforms
 *
 * WHAT
 * - In functions where a case scrutinee is one parameter (e.g., category),
 *   rewrite guard references to a single free variable (e.g., n) to the other
 *   function parameter (e.g., value) when there is exactly one such candidate.
 *
 * WHY
 * - Guard expressions must reference bound variables. Haxe sources sometimes
 *   produce a neutral name (like n) in guards, expecting it to correspond to
 *   another function argument. This pass resolves that reference deterministically
 *   without any app-specific heuristics.
 *
 * HOW
 * - For each def/defp: collect parameter names. Descend into ECase nodes whose
 *   scrutinee is EVar(s). For each clause with a guard, compute free variables
 *   in the guard. If the set is exactly one var V and V is not bound in the
 *   pattern and not equal to s, and there is exactly one function parameter P
 *   different from s, rewrite occurrences of V -> P in the guard and body of
 *   the clause. This is purely shape-based.
 */
class CaseGuardFreeVarToOtherParamTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body):
          var paramNames = extractParamNames(args);
          var nb = rewriteBodyCases(body, paramNames);
          makeASTWithMeta(EDef(name, args, guards, nb), n.metadata, n.pos);
        case EDefp(name2, args2, guards2, body2):
          var paramNamesLocal = extractParamNames(args2);
          var rewrittenBody = rewriteBodyCases(body2, paramNamesLocal);
          makeASTWithMeta(EDefp(name2, args2, guards2, rewrittenBody), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function extractParamNames(args:Array<EPattern>):Array<String> {
    var out:Array<String> = [];
    for (a in args) switch (a) { case PVar(n): if (n != null && n.length > 0) out.push(n); default: }
    return out;
  }

  static function rewriteBodyCases(body: ElixirAST, paramNames:Array<String>): ElixirAST {
    return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case ECase(expr, clauses):
          var scrutinee = switch (expr.def) { case EVar(v): v; default: null; };
          var newClauses = [for (c in clauses) rewriteClause(c, paramNames, scrutinee)];
          makeASTWithMeta(ECase(expr, newClauses), x.metadata, x.pos);
        default:
          x;
      }
    });
  }

  static function rewriteClause(c:ECaseClause, params:Array<String>, scrutinee:Null<String>):ECaseClause {
    if (scrutinee == null) return c;
    var bound = new Map<String,Bool>();
    collectBinders(c.pattern, bound);
    // free vars in guard
    var free = collectFreeVars(c.guard, bound);
    if (free.length == 1) {
      var v = free[0];
      if (v != scrutinee && !bound.exists(v)) {
        var candidates = [for (p in params) if (p != scrutinee) p];
        if (candidates.length == 1) {
          var target = candidates[0];
          // substitute in guard and body
          var newGuard = substituteVar(c.guard, v, target);
          var newBody = substituteVar(c.body, v, target);
          return { pattern: c.pattern, guard: newGuard, body: newBody };
        }
      }
    }
    return c;
  }

  static function collectBinders(p:EPattern, out:Map<String,Bool>):Void {
    switch (p) {
      case PVar(n): if (n != null && n.length > 0) out.set(n, true);
      case PTuple(ps) | PList(ps): for (q in ps) collectBinders(q, out);
      case PCons(h,t): collectBinders(h, out); collectBinders(t, out);
      case PMap(kvs): for (kv in kvs) collectBinders(kv.value, out);
      case PStruct(_,fs): for (f in fs) collectBinders(f.value, out);
      case PPin(inner): collectBinders(inner, out);
      default:
    }
  }

  static function collectFreeVars(e:Null<ElixirAST>, bound:Map<String,Bool>):Array<String> {
    var out = new Map<String,Bool>();
    if (e == null) return [];
    function walk(x:ElixirAST):Void {
      if (x == null) return;
      switch (x.def) {
        case EVar(n): if (!bound.exists(n)) out.set(n, true);
        case EBinary(_, l, r): walk(l); walk(r);
        case EUnary(_, ex): walk(ex);
        case ECall(t,_,as): if (t != null) walk(t); for (a in as) walk(a);
        case ERemoteCall(m,_,as): walk(m); for (a in as) walk(a);
        case EIf(c,t,ee): walk(c); walk(t); if (ee != null) walk(ee);
        case EParen(inner): walk(inner);
        default:
      }
    }
    walk(e);
    return [for (k in out.keys()) k];
  }

  static function substituteVar(n:Null<ElixirAST>, from:String, to:String):Null<ElixirAST> {
    if (n == null) return null;
    return ElixirASTTransformer.transformNode(n, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case EVar(v) if (v == from): makeASTWithMeta(EVar(to), x.metadata, x.pos);
        default: x;
      }
    });
  }
}

#end
