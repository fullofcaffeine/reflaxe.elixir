package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.OptimizedVarUseAnalyzer;

/**
 * DropUnusedEnumAssignToUnderscoreTransforms
 *
 * WHAT
 * - Rewrites top-level assignments of the form `name = Enum.map(...)/Enum.filter(...)` to
 *   `_ = Enum.map(...)` (or filter) when `name` is never referenced later in the same block.
 *
 * WHY
 * - Prevents synthesis of unused locals like `doubled`, `strings`, etc. in snapshot suites
 *   such as core/array_map_idiomatic. Elixir warns on unused locals; the intent here is a
 *   side-effect only, so an underscore assignment is idiomatic and matches canonical outputs.
 *
 * HOW
 * - Visits EBlock/EDo and inspects each statement. When it matches an assignment whose RHS is
 *   `ERemoteCall(Enum, map|filter|reject|each|flat_map|with_index|reduce|sort|reverse|concat|uniq, ...)`
 *   and the LHS variable does not occur in subsequent statements of the same container, it rewrites
 *   the LHS to `_`.
 *
 * EXAMPLES
 * Before:
 *   doubled = Enum.map(numbers, fn n -> n * 2 end)
 * After:
 *   _ = Enum.map(numbers, fn n -> n * 2 end)
 */
class DropUnusedEnumAssignToUnderscoreTransforms {
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
        case EBinary(Match, {def: EVar(lhs)}, rhs) if (isEnumCall(rhs) && !OptimizedVarUseAnalyzer.usedLater(useIndex, i + 1, lhs)):
          rewrittenStmt = makeASTWithMeta(EBinary(Match, makeAST(EVar("_")), rhs), stmt.metadata, stmt.pos);
        case EMatch(PVar(lhs), rhs) if (isEnumCall(rhs) && !OptimizedVarUseAnalyzer.usedLater(useIndex, i + 1, lhs)):
          rewrittenStmt = makeASTWithMeta(EMatch(PVar("_"), rhs), stmt.metadata, stmt.pos);
        default:
      }
      out.push(rewrittenStmt);
    }
    return out;
  }

  static inline function isEnumCall(e: ElixirAST): Bool {
    return switch (e.def) {
      case ERemoteCall(mod, name, _):
        switch (mod.def) {
          case EVar(m) if (m == "Enum"):
            switch (name) {
              case "map" | "filter" | "reject" | "each" | "flat_map" | "with_index" | "reduce" | "sort" | "reverse" | "concat" | "uniq": true;
              default: false;
            }
          default: false;
        }
      default: false;
    }
  }
}

#end
