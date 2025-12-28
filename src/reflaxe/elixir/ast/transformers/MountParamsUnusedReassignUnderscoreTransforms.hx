package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.OptimizedVarUseAnalyzer;

/**
 * MountParamsUnusedReassignUnderscoreTransforms
 *
 * WHAT
 * - In def mount/3 bodies, rename `params = ...` to `_params = ...` when `params`
 *   is not referenced later in the same body. Preserves RHS side-effects.

 *
 * WHY
 * - Avoid warnings and keep generated Elixir output idiomatic.

 *
 * HOW
 * - Walk the ElixirAST with `ElixirASTTransformer.transformNode` and rewrite matching nodes.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class MountParamsUnusedReassignUnderscoreTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef("mount", args, guards, body) if (args != null && args.length == 3):
          makeASTWithMeta(EDef("mount", args, guards, rewrite(body)), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function rewrite(body: ElixirAST): ElixirAST {
    return switch (body.def) {
      case EBlock(stmts): makeASTWithMeta(EBlock(rewriteSeq(stmts)), body.metadata, body.pos);
      case EDo(statements): makeASTWithMeta(EDo(rewriteSeq(statements)), body.metadata, body.pos);
      default: body;
    }
  }

  static function rewriteSeq(stmts:Array<ElixirAST>):Array<ElixirAST> {
    if (stmts == null) return stmts;
    var useIndex = OptimizedVarUseAnalyzer.buildExact(stmts);
    var out:Array<ElixirAST> = [];
    for (i in 0...stmts.length) {
      var stmt = stmts[i];
      var rewrittenStmt = switch (stmt.def) {
        case EMatch(PVar("params"), rhs) if (!OptimizedVarUseAnalyzer.usedLater(useIndex, i + 1, "params")):
          makeASTWithMeta(EMatch(PVar("_params"), rhs), stmt.metadata, stmt.pos);
        case EBinary(Match, {def: EVar("params")}, rhs) if (!OptimizedVarUseAnalyzer.usedLater(useIndex, i + 1, "params")):
          makeASTWithMeta(EBinary(Match, makeAST(EVar("_params")), rhs), stmt.metadata, stmt.pos);
        default: stmt;
      };
      out.push(rewrittenStmt);
    }
    return out;
  }
}

#end
