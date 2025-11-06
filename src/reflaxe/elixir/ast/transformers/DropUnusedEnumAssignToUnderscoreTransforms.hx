package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

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
        case EDo(stmts2): makeASTWithMeta(EDo(rewrite(stmts2)), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function rewrite(stmts:Array<ElixirAST>): Array<ElixirAST> {
    if (stmts == null) return stmts;
    var out:Array<ElixirAST> = [];
    for (i in 0...stmts.length) {
      var s = stmts[i];
      var s2 = s;
      switch (s.def) {
        case EBinary(Match, {def: EVar(lhs)}, rhs) if (isEnumCall(rhs) && !usedLater(stmts, i+1, lhs)):
          s2 = makeASTWithMeta(EBinary(Match, makeAST(EVar("_")), rhs), s.metadata, s.pos);
        case EMatch(PVar(lhs2), rhs2) if (isEnumCall(rhs2) && !usedLater(stmts, i+1, lhs2)):
          s2 = makeASTWithMeta(EMatch(PVar("_"), rhs2), s.metadata, s.pos);
        default:
      }
      out.push(s2);
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

  static function usedLater(stmts:Array<ElixirAST>, from:Int, name:String): Bool {
    if (name == null || name == "_") return false;
    var found = false;
    for (j in from...stmts.length) if (!found) {
      reflaxe.elixir.ast.ASTUtils.walk(stmts[j], function(n: ElixirAST) {
        switch (n.def) { case EVar(v) if (v == name): found = true; default: }
      });
    }
    return found;
  }
}

#end

