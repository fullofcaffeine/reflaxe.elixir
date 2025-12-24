package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.OptimizedVarUseAnalyzer;

/**
 * DropUnusedAssignToCaseTransforms
 *
 * WHAT
 * - Rewrites `v = case ... end` into just `case ... end` when `v` is not used
 *   afterwards in the same block/do body. Handles common handle_info shapes
 *   where the case already returns {:noreply, socket}.
 */
class DropUnusedAssignToCaseTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EBlock(stmts): makeASTWithMeta(EBlock(rewrite(stmts)), n.metadata, n.pos);
        case EDo(statements): makeASTWithMeta(EDo(rewrite(statements)), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function rewrite(stmts:Array<ElixirAST>):Array<ElixirAST> {
    if (stmts == null) return stmts;
    var useIndex = OptimizedVarUseAnalyzer.buildExact(stmts);
    var out:Array<ElixirAST> = [];
    for (i in 0...stmts.length) {
      var stmt = stmts[i];
      switch (stmt.def) {
        case EBinary(Match, left, rhs) if (isCase(rhs)):
          switch (left.def) {
            case EVar(name) if (!OptimizedVarUseAnalyzer.usedLater(useIndex, i + 1, name)):
              out.push(rhs);
            default:
              out.push(stmt);
          }
        case EMatch(PVar(binderName), rhs) if (isCase(rhs) && !OptimizedVarUseAnalyzer.usedLater(useIndex, i + 1, binderName)):
          out.push(rhs);
        default:
          out.push(stmt);
      }
    }
    return out;
  }

  static inline function isCase(e: ElixirAST): Bool {
    // Unwrap parens to catch shapes like (case ... end)
    var cur = e;
    while (true) {
      switch (cur.def) {
        case EParen(inner): cur = inner; continue;
        default: break;
      }
    }
    return switch (cur.def) { case ECase(_, _): true; default: false; }
  }
}

#end
