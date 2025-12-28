package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * IfConditionComplexToParenTransforms
 *
 * WHAT
 * - Parenthesize if/unless conditions when they contain case/cond/with/if
 *   constructs used inside binary expressions. This prevents SyntaxError in
 *   shapes like: `if case ... end > -1 do`.
 *
 * HOW
 * - Visit EIf/ EUnless. If condition AST contains any of ECase/ECond/EWith/EIf,
 *   wrap the entire condition in EParen.

 *
 * WHY
 * - Avoid warnings and keep generated Elixir output idiomatic.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class IfConditionComplexToParenTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EIf(cond, thenB, elseB):
          var newCond = containsComplex(cond) ? makeAST(EParen(cond)) : cond;
          makeASTWithMeta(EIf(newCond, thenB, elseB), n.metadata, n.pos);
        case EUnless(cond2, body, elseB2):
          var newCond2 = containsComplex(cond2) ? makeAST(EParen(cond2)) : cond2;
          makeASTWithMeta(EUnless(newCond2, body, elseB2), n.metadata, n.pos);
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
        case ECase(_, _) | ECond(_) | EWith(_,_,_) | EIf(_,_,_):
          found = true;
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
}

#end

