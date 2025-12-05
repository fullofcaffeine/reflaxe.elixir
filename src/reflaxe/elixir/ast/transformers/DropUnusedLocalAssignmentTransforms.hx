package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.VarUseAnalyzer;

/**
 * DropUnusedLocalAssignmentTransforms
 *
 * WHAT
 * - Removes local assignments whose bound variable is not referenced in any
 *   subsequent statement within the same block or do-end body. Preserves RHS
 *   evaluation to keep side effects.
 *
 * WHY
 * - Prevents compiler from emitting throwaway locals like `data`, `json`,
 *   `changeset`, `g`, etc., which trigger warnings under WAE and add noise.
 *   This pass keeps semantics identical while eliminating unused binders.
 *
 * HOW
 * - For each EBlock/EDo, scan statements in order. If a statement is a match
 *   or `=` bind to a variable `v` and `v` is not used in any later statement
 *   in the same sequence, replace the statement with just its RHS expression.
 *   Applies recursively inside anonymous function bodies as well.
 */
class DropUnusedLocalAssignmentTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EBlock(stmts): makeASTWithMeta(EBlock(rewrite(stmts)), n.metadata, n.pos);
        case EDo(stmts2): makeASTWithMeta(EDo(rewrite(stmts2)), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function rewrite(stmts:Array<ElixirAST>):Array<ElixirAST> {
    if (stmts == null) return stmts;
    var out:Array<ElixirAST> = [];
    for (i in 0...stmts.length) {
      var s = stmts[i];
      var replaced:Null<ElixirAST> = null;
      switch (s.def) {
        case EBinary(Match, left, rhs):
          switch (left.def) {
            case EVar(name):
              // Use centralized VarUseAnalyzer for proper closure/interpolation detection
              if (!VarUseAnalyzer.usedLater(stmts, i+1, name)) {
                // If binder is underscored and its base name is used later, promote binder
                if (name.length > 1 && name.charAt(0) == "_") {
                  var base = name.substr(1);
                  if (VarUseAnalyzer.usedLater(stmts, i+1, base)) {
                    // Keep assignment but rename binder to base
                    replaced = makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(base), left.metadata, left.pos), rhs), s.metadata, s.pos);
                  } else {
                    replaced = rhs;
                  }
                } else {
                  replaced = rhs;
                }
              }
            default:
          }
        case EMatch(PVar(name2), rhs2):
          // Use centralized VarUseAnalyzer for proper closure/interpolation detection
          if (!VarUseAnalyzer.usedLater(stmts, i+1, name2)) {
            if (name2.length > 1 && name2.charAt(0) == "_") {
              var base2 = name2.substr(1);
              if (VarUseAnalyzer.usedLater(stmts, i+1, base2)) {
                // Keep match but rename binder to base
                replaced = makeASTWithMeta(EMatch(PVar(base2), rhs2), s.metadata, s.pos);
              } else {
                replaced = rhs2;
              }
            } else {
              replaced = rhs2;
            }
          }
        default:
      }
      out.push(replaced != null ? replaced : s);
    }
    return out;
  }
}

#end
