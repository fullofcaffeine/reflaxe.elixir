package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * FlattenNestedMatchLhsTransforms
 *
 * WHAT
 * - Flattens invalid nested match expressions that appear on the left-hand side of a
 *   match, e.g., `( _ = call1(...) ) = call2(...)`, into two sequential statements:
 *     _ = call1(...)
 *     _ = call2(...)
 *
 * WHY
 * - Some prior cleanups can accidentally nest EBinary(Match, ...) as the LHS of another
 *   EBinary(Match, ...), which prints as `call1(...) = call2(...)` (invalid Elixir). This
 *   pass preserves intent (two effectful calls) and restores valid syntax.
 *
 * HOW
 * - Scans EBlock/EDo statements and rewrites any statement where the LHS of `=` is itself
 *   an EBinary/EMatch into two statements: the inner match first, followed by `_ = <rhs>`.
 */
class FlattenNestedMatchLhsTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EBlock(stmts): makeASTWithMeta(EBlock(rewrite(stmts)), n.metadata, n.pos);
        case EDo(stmts2): makeASTWithMeta(EDo(rewrite(stmts2)), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function rewrite(stmts:Array<ElixirAST>): Array<ElixirAST> {
    if (stmts == null) return stmts;
    var out:Array<ElixirAST> = [];
    for (s in stmts) switch (s.def) {
      case EBinary(Match, left, rhs):
        switch (left.def) {
          case EBinary(Match, l2, r2):
            out.push(makeASTWithMeta(EBinary(Match, l2, r2), s.metadata, s.pos));
            out.push(makeASTWithMeta(EBinary(Match, makeAST(EVar("_")), rhs), s.metadata, s.pos));
          case EMatch(pat, r3):
            out.push(makeASTWithMeta(EMatch(pat, r3), s.metadata, s.pos));
            out.push(makeASTWithMeta(EBinary(Match, makeAST(EVar("_")), rhs), s.metadata, s.pos));
          default:
            out.push(s);
        }
      default:
        out.push(s);
    }
    return out;
  }
}

#end

