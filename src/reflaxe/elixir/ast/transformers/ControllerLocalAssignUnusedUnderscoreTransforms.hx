package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ElixirAST.EPattern;
import reflaxe.elixir.ast.analyzers.OptimizedVarUseAnalyzer;

/**
 * ControllerLocalAssignUnusedUnderscoreTransforms
 *
 * WHAT
 * - In functions whose first parameter is named `conn` (common Phoenix
 *   controller/actions pattern), underscore local assignment binders that are
 *   not referenced later in the same block/arm.
 *
 * WHY
 * - Eliminates WAE warnings for throwaway locals introduced during lowering
 *   (e.g., data/json/user/changeset), without relying on specific names.

 *
 * HOW
 * - Walk the ElixirAST with `ElixirASTTransformer.transformNode` and rewrite matching nodes.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class ControllerLocalAssignUnusedUnderscoreTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body) if (args != null && args.length >= 1 && isConnParam(args[0])):
          var nb = rewriteBlocks(body);
          makeASTWithMeta(EDef(name, args, guards, nb), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static inline function isConnParam(pat: EPattern): Bool {
    return switch (pat) { case PVar(n) if (n == "conn"): true; default: false; }
  }

  static function rewriteBlocks(node: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(node, function(x: ElixirAST): ElixirAST {
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
      var rewrittenStmt = switch (stmt.def) {
        case EBinary(Match, {def: EVar(b)}, rhs)
          if (canUnderscoreBinder(b) && !OptimizedVarUseAnalyzer.usedLater(useIndex, i + 1, b) && isSimple(rhs)):
          makeASTWithMeta(EBinary(Match, makeAST(EVar('_' + b)), rhs), stmt.metadata, stmt.pos);
        case EMatch(PVar(binderName), rhsExpr)
          if (canUnderscoreBinder(binderName) && !OptimizedVarUseAnalyzer.usedLater(useIndex, i + 1, binderName) && isSimple(rhsExpr)):
          makeASTWithMeta(EMatch(PVar('_' + binderName), rhsExpr), stmt.metadata, stmt.pos);
        default: stmt;
      }
      out.push(rewrittenStmt);
    }
    return out;
  }

  static inline function canUnderscoreBinder(name: String): Bool {
    // Never double-underscore already-safe binders like `_x` (would become `__x`) and
    // never rewrite the wildcard discard `_` (would become `__`, which Elixir treats
    // as an unknown compiler variable).
    return name != null && name.length > 0 && name.charAt(0) != '_';
  }

  static function isSimple(e: ElixirAST): Bool {
    return switch (e.def) {
      case EVar(_): true;
      case EString(_): true;
      case EInteger(_): true;
      case EFloat(_): true;
      case EBoolean(_): true;
      case ENil: true;
      default: false;
    }
  }
}

#end
