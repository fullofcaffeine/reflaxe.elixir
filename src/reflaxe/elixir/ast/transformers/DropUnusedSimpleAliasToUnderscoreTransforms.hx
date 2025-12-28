package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.OptimizedVarUseAnalyzer;

/**
 * DropUnusedSimpleAliasToUnderscoreTransforms
 *
 * WHAT
 * - Converts trivial alias assignments like `tmp = value` to `_ = value` when `tmp` is not
 *   referenced later in the enclosing block.
 *
 * WHY
 * - Hygiene/aliasing passes may introduce helper locals (e.g., `n2 = value`, `x3 = n`) to
 *   stabilize shapes during transformation. When those locals are not subsequently referenced,
 *   they should be discarded to avoid numeric-suffix variables and warnings-as-errors.
 *
 * HOW
 * - For each statement in EBlock/EDo: if it is an assignment with a simple LHS variable and
 *   RHS that is a simple expression (var, atom, number, string, remote/local call) and the
 *   LHS is not used later in the same container, rewrite the LHS to `_`.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class DropUnusedSimpleAliasToUnderscoreTransforms {
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
    if (stmts == null) return stmts;
    var useIndex = OptimizedVarUseAnalyzer.buildExact(stmts);
    var out:Array<ElixirAST> = [];
    for (i in 0...stmts.length) {
      var stmt = stmts[i];
      var rewrittenStmt = stmt;
      switch (stmt.def) {
        case EBinary(Match, {def: EVar(lhs)}, rhs) if (isSimple(rhs) && hasNumericSuffix(lhs) && !OptimizedVarUseAnalyzer.usedLater(useIndex, i + 1, lhs)):
          rewrittenStmt = makeASTWithMeta(EBinary(Match, makeAST(EVar("_")), rhs), stmt.metadata, stmt.pos);
        case EMatch(PVar(lhs), rhs) if (isSimple(rhs) && hasNumericSuffix(lhs) && !OptimizedVarUseAnalyzer.usedLater(useIndex, i + 1, lhs)):
          rewrittenStmt = makeASTWithMeta(EMatch(PVar("_"), rhs), stmt.metadata, stmt.pos);
        default:
      }
      out.push(rewrittenStmt);
    }
    return out;
  }

  static function isSimple(e: ElixirAST): Bool {
    return switch (e.def) {
      case EVar(_)|EString(_)|EInteger(_)|EFloat(_)|EBoolean(_)|ENil|EAtom(_): true;
      case ERemoteCall(_,_,_)|ECall(_,_,_): true;
      case EParen(inner): isSimple(inner);
      default: false;
    }
  }

  static inline function hasNumericSuffix(name:String): Bool {
    if (name == null) return false;
    var re = ~/^(.+?)(\d+)$/;
    return re.match(name);
  }
}

#end
