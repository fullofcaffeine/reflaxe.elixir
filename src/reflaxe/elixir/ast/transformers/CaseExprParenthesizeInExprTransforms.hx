package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * CaseExprParenthesizeInExprTransforms
 *
 * WHAT
 * - Ensures ECase used in expression positions (assignment RHS) is explicitly
 *   parenthesized to match intended snapshot shapes and avoid precedence
 *   ambiguities. This is a cosmetic, semantics‑preserving transform.
 *
 * WHY
 * - Some snapshots expect `(case ...)` when a case expression appears as a value.
 *   Parentheses are idiomatic and safe in expression contexts.
 *
 * HOW
 * - For EMatch(_, rhs) and EBinary(Match, _, rhs) when rhs is ECase, wrap rhs in EParen.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class CaseExprParenthesizeInExprTransforms {
  public static function transformPass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EMatch(pat, rhs):
          switch (rhs.def) {
            case ECase(_, _): makeASTWithMeta(EMatch(pat, makeASTWithMeta(EParen(rhs), rhs.metadata, rhs.pos)), n.metadata, n.pos);
            default: n;
          }
        case EBinary(Match, left, rhs2):
          switch (rhs2.def) {
            case ECase(_, _): makeASTWithMeta(EBinary(Match, left, makeASTWithMeta(EParen(rhs2), rhs2.metadata, rhs2.pos)), n.metadata, n.pos);
            default: n;
          }
        default:
          n;
      }
    });
  }
}

#end

