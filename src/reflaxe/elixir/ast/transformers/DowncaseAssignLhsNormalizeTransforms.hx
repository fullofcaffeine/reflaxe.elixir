package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * DowncaseAssignLhsNormalizeTransforms
 *
 * WHAT
 * - Normalize malformed assignments where the left-hand side is
 *   `String.downcase(p)` to the proper variable `p` when the right-hand side is
 *   also `String.downcase(p)`.
 *
 * WHY
 * - Some late rewrites can produce incorrect LHS expressions. This shape-only
 *   fixer restores a valid assignment without app-specific logic.

 *
 * HOW
 * - Walk the ElixirAST with `ElixirASTTransformer.transformNode` and rewrite matching nodes.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class DowncaseAssignLhsNormalizeTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EBinary(Match, left, right):
          var p = extractDowncaseVar(right);
          if (p != null && isDowncaseCallOf(left, p)) {
            makeASTWithMeta(EBinary(Match, makeAST(EVar(p)), right), n.metadata, n.pos);
          } else n;
        case EMatch(pat, rhs):
          var p2 = extractDowncaseVar(rhs);
          // EMatch assigns a pattern; not used for variable binding target → leave as-is
          n;
        default:
          n;
      }
    });
  }
  static function extractDowncaseVar(e: ElixirAST): Null<String> {
    return switch (e.def) {
      case ERemoteCall({def: EVar(m)}, "downcase", args) if (m == "String" && args != null && args.length == 1):
        switch (args[0].def) { case EVar(v): v; default: null; }
      default: null;
    }
  }
  static function isDowncaseCallOf(e: ElixirAST, name:String): Bool {
    return switch (e.def) {
      case ERemoteCall({def: EVar(m)}, "downcase", args):
        if (m != "String" || args == null || args.length != 1) false else switch (args[0].def) { case EVar(v) if (v == name): true; default: false; }
      default: false;
    }
  }
}

#end

