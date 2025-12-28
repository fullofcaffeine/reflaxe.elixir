package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.OptimizedVarUseAnalyzer;

/**
 * HandleInfoDropUnusedAssignTransforms
 *
 * WHAT
 * - Inside `def handle_info/2`, drop leading assignments of the shape
 *   `var = case ... end` where `var` is not used afterwards. This targets the
 *   common lowering that binds the case result to a throwaway variable like `g`.
 *
 * WHY
 * - Avoids WAE warnings without touching semantics. The case already returns
 *   `{:noreply, socket}` in each branch.

 *
 * HOW
 * - Walk the ElixirAST with `ElixirASTTransformer.transformNode` and rewrite matching nodes.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class HandleInfoDropUnusedAssignTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body) if (name == "handle_info" && args != null && args.length == 2):
          var newBody = rewriteBody(body);
          makeASTWithMeta(EDef(name, args, guards, newBody), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function rewriteBody(body: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case EBlock(stmts): makeASTWithMeta(EBlock(rewrite(stmts)), x.metadata, x.pos);
        case EDo(statements): makeASTWithMeta(EDo(rewrite(statements)), x.metadata, x.pos);
        default: x;
      }
    });
  }

  static function rewrite(stmts:Array<ElixirAST>):Array<ElixirAST> {
    if (stmts == null) return stmts;
    var useIndex = OptimizedVarUseAnalyzer.buildExact(stmts);
    var out:Array<ElixirAST> = [];
    for (i in 0...stmts.length) {
      var stmt = stmts[i];
      var handled = false;
      switch (stmt.def) {
        case EBinary(Match, left, rhs):
          switch (left.def) {
            case EVar(name) if (!OptimizedVarUseAnalyzer.usedLater(useIndex, i + 1, name) && isCase(rhs)):
              out.push(rhs); handled = true;
            default:
          }
        case EMatch(PVar(binderName), rhs) if (!OptimizedVarUseAnalyzer.usedLater(useIndex, i + 1, binderName) && isCase(rhs)):
          out.push(rhs); handled = true;
        default:
      }
      if (!handled) out.push(stmt);
    }
    return out;
  }

  static function isCase(e: ElixirAST): Bool {
    var cur = e;
    while (true) switch (cur.def) { case EParen(inner): cur = inner; continue; default: break; }
    return switch (cur.def) { case ECase(_, _): true; default: false; }
  }
}

#end
