package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * SplitChainAssignTransforms
 *
 * WHAT
 * - Splits chained assignments of the form `a = (b = rhs)` into two linear statements:
 *     b = rhs
 *     a = b
 *
 * WHY
 * - Enables downstream windows such as `a=b; if cond(b) … else b` → `a=if cond(b) …` without
 *   relying on immediate adjacency to the original chain, and improves readability.
 *
 * HOW
 * - Walks EBlock/EDo statements and replaces any `a = (b = rhs)` or `EMatch(PVar(a), EBinary(Match, EVar(b), rhs))`
 *   with two statements preserving metadata/positions.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class SplitChainAssignTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EBlock(stmts): makeASTWithMeta(EBlock(rewrite(stmts)), n.metadata, n.pos);
        case EDo(statements): makeASTWithMeta(EDo(rewrite(statements)), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function rewrite(stmts:Array<ElixirAST>): Array<ElixirAST> {
    var out:Array<ElixirAST> = [];
    var i = 0;
    while (i < stmts.length) {
      var s = stmts[i];
      var splitDone = false;
      switch (s.def) {
        case EBinary(Match, {def: EVar(a)}, rhsAny):
          switch (rhsAny.def) {
            case EBinary(Match, {def: EVar(b)}, rhs):
              out.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(b), s.metadata, s.pos), rhs), s.metadata, s.pos));
              out.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(a), s.metadata, s.pos), makeASTWithMeta(EVar(b), s.metadata, s.pos)), s.metadata, s.pos));
              splitDone = true;
            default:
          }
        case EMatch(PVar(leftVar), rhsAny2):
          if (!splitDone) {
            switch (rhsAny2.def) {
              case EBinary(Match, {def: EVar(rightVar)}, rhsExpr):
                out.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(rightVar), s.metadata, s.pos), rhsExpr), s.metadata, s.pos));
                out.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(leftVar), s.metadata, s.pos), makeASTWithMeta(EVar(rightVar), s.metadata, s.pos)), s.metadata, s.pos));
                splitDone = true;
              default:
            }
          }
        default:
      }
      if (!splitDone) out.push(s);
      i++;
    }
    return out;
  }
}

#end
