package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * IfConditionRemoveParensSimpleTransforms
 *
 * WHAT
 * - Unwrap superfluous parentheses around simple if/unless conditions to match
 *   snapshot shapes (e.g., `if (a and b) do` → `if a and b do`).
 *
 * WHY
 * - Earlier safety passes may conservatively wrap conditions; for simple boolean
 *   expressions (no case/cond/with/if), parentheses are not required and harm
 *   parity-only tests.
 *
 * HOW
 * - For EIf/EUnless, if condition is EParen(inner) and `inner` does not contain
 *   case/cond/with/if, unwrap it.
 */
class IfConditionRemoveParensSimpleTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EIf(cond, thenB, elseB):
          var newCond = switch (cond.def) {
            case EParen(inner) if (!containsComplex(inner)): inner;
            default: cond;
          };
          makeASTWithMeta(EIf(newCond, thenB, elseB), n.metadata, n.pos);
        case EUnless(cond2, body, elseB2):
          var newCond2 = switch (cond2.def) {
            case EParen(inner2) if (!containsComplex(inner2)): inner2;
            default: cond2;
          };
          makeASTWithMeta(EUnless(newCond2, body, elseB2), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function containsComplex(e: ElixirAST): Bool {
    var found = false;
    function walk(x:ElixirAST):Void {
      if (found || x == null || x.def == null) return;
      switch (x.def) {
        case ECase(_, _) | ECond(_) | EWith(_,_,_) | EIf(_,_,_): found = true;
        case EBinary(_, l, r): walk(l); if (r != null) walk(r);
        case EUnary(_, ex): walk(ex);
        case EParen(inner): walk(inner);
        case ECall(t,_,as): if (t != null) walk(t); if (as != null) for (a in as) walk(a);
        case ERemoteCall(t2,_,as2): walk(t2); if (as2 != null) for (a2 in as2) walk(a2);
        default:
      }
    }
    walk(e);
    return found;
  }
}

#end

