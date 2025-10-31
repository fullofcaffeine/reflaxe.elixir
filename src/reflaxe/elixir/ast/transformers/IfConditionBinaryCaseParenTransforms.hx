package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * IfConditionBinaryCaseParenTransforms
 *
 * WHAT
 * - Ensure if/unless conditions that compare a case/cond/with expression are
 *   parenthesized on that side: if (case ... end) > rhs do ... end.
 *
 * WHY
 * - Prevent parser ambiguity/syntax errors when a do/end block form participates
 *   directly in a comparison.
 *
 * HOW
 * - For EIf/EUnless with condition EBinary(op, left, right): if left or right is
 *   ECase/ECond/EWith/EIf, wrap that side with EParen.
 */
class IfConditionBinaryCaseParenTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EIf(cond, t, e):
          var newCond = parenCaseSide(cond);
          (newCond != cond) ? makeASTWithMeta(EIf(newCond, t, e), n.metadata, n.pos) : n;
        case EUnless(cond2, b, e2):
          var newCond2 = parenCaseSide(cond2);
          (newCond2 != cond2) ? makeASTWithMeta(EUnless(newCond2, b, e2), n.metadata, n.pos) : n;
        default:
          n;
      }
    });
  }

  static inline function isComplex(e: ElixirAST): Bool {
    return switch (e.def) { case ECase(_, _) | ECond(_) | EWith(_,_,_) | EIf(_,_,_): true; default: false; };
  }

  static function parenCaseSide(cond: ElixirAST): ElixirAST {
    return switch (cond.def) {
      case EBinary(op, left, right):
        var nl = isComplex(left) ? makeAST(EParen(left)) : left;
        var nr = (right == null) ? right : (isComplex(right) ? makeAST(EParen(right)) : right);
        (nl != left || nr != right) ? makeAST(EBinary(op, nl, nr)) : cond;
      default:
        cond;
    }
  }
}

#end

