package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * IfConditionComplexHoistTransforms
 *
 * WHAT
 * - Hoist complex constructs (case/cond/with/if) used inside binary conditions of
 *   if/unless into a prior binding, then compare the bound value. This avoids
 *   shapes like `if case ... end > -1 do` which are parser-sensitive.
 *
 * HOW
 * - When encountering EIf/EUnless with condition EBinary(op, left, right) and either
 *   side contains ECase/ECond/EWith/EIf, rewrite to an EBlock:
 *   cond_value = <complex>
 *   if cond_value <op> <other> do ... else ... end
 */
class IfConditionComplexHoistTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EIf(cond, thenB, elseB):
          var rewritten = tryHoist(cond, function(newCond) return makeASTWithMeta(EIf(newCond, thenB, elseB), n.metadata, n.pos));
          rewritten != null ? rewritten : n;
        case EUnless(cond2, body, elseB2):
          var rewritten2 = tryHoist(cond2, function(newCond2) return makeASTWithMeta(EUnless(newCond2, body, elseB2), n.metadata, n.pos));
          rewritten2 != null ? rewritten2 : n;
        default:
          n;
      }
    });
  }

  static function containsComplex(e: ElixirAST): Bool {
    var found = false;
    function walk(x:ElixirAST):Void {
      if (found || x == null) return;
      switch (x.def) {
        case ECase(_, _) | ECond(_) | EWith(_,_,_) | EIf(_,_,_): found = true;
        case EBinary(_, l, r): walk(l); if (r != null) walk(r);
        case EUnary(_, ex): walk(ex);
        case EParen(inner): walk(inner);
        case ECall(t,_,as): if (t != null) walk(t); for (a in as) walk(a);
        case ERemoteCall(m,_,as): walk(m); for (a in as) walk(a);
        default:
      }
    }
    walk(e);
    return found;
  }

  static function tryHoist(cond: ElixirAST, rebuild:(ElixirAST)->ElixirAST): Null<ElixirAST> {
    return switch (cond.def) {
      case EBinary(op, left, right) if (containsComplex(left) || containsComplex(right)):
        var hoisted = containsComplex(left) ? left : right;
        var tmpName = 'cond_value';
        var assign = makeAST(EMatch(PVar(tmpName), hoisted));
        var newLeft = containsComplex(left) ? makeAST(EVar(tmpName)) : left;
        var newRight = containsComplex(right) ? makeAST(EVar(tmpName)) : right;
        var newCond = makeAST(EBinary(op, newLeft, newRight));
        makeAST(EBlock([assign, rebuild(newCond)]));
      default:
        null;
    }
  }
}

#end

