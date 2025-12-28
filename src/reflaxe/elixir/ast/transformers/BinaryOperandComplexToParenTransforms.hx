package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * BinaryOperandComplexToParenTransforms
 *
 * WHAT
 * - Wrap complex expressions (case/cond/with/if) used as operands of binary
 *   operators in parentheses to ensure valid Elixir syntax, e.g.:
 *   `if (case ... end) > -1 do ... end`.
 *
 * WHY
 * - Elixir requires parentheses around these constructs when they participate
 *   in binary expressions; otherwise it raises a SyntaxError.
 *
 * HOW
 * - Visit EBinary nodes and replace complex left/right operands with EParen.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class BinaryOperandComplexToParenTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EBinary(op, left, right):
          var newLeft = wrapIfNeeded(left);
          var newRight = right == null ? right : wrapIfNeeded(right);
          if (newLeft != left || newRight != right) makeASTWithMeta(EBinary(op, newLeft, newRight), n.metadata, n.pos) else n;
        default:
          n;
      }
    });
  }

  static inline function wrapIfNeeded(e: ElixirAST): ElixirAST {
    return switch (e.def) {
      case ECase(_, _) | ECond(_) | EWith(_,_,_) | EIf(_,_,_):
        makeAST(EParen(e));
      case EParen(_):
        e;
      default:
        e;
    }
  }
}

#end

