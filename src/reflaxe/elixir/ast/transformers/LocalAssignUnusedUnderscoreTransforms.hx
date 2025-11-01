package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * LocalAssignUnusedUnderscoreTransforms
 *
 * WHAT
 * - For block/do bodies, underscore local assignment binders that are not
 *   referenced in any subsequent statement of the same block.
 *
 * WHY
 * - Silences warnings like "variable `x` is unused" while keeping the
 *   assignment expression semantics intact (returns RHS).
 */
class LocalAssignUnusedUnderscoreTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EBlock(stmts):
          makeASTWithMeta(EBlock(rewrite(stmts)), n.metadata, n.pos);
        case EDo(stmts2):
          makeASTWithMeta(EDo(rewrite(stmts2)), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function rewrite(stmts:Array<ElixirAST>):Array<ElixirAST> {
    if (stmts == null) return stmts;
    var out:Array<ElixirAST> = [];
    for (i in 0...stmts.length) {
      var s = stmts[i];
      var s1 = switch (s.def) {
        case EMatch(PVar(b), rhs) if (!usedLater(stmts, i+1, b)):
          makeASTWithMeta(EMatch(PVar('_' + b), rhs), s.metadata, s.pos);
        case EBinary(Match, {def: EVar(b2)}, rhs2) if (!usedLater(stmts, i+1, b2)):
          makeASTWithMeta(EBinary(Match, makeAST(EVar('_' + b2)), rhs2), s.metadata, s.pos);
        default:
          s;
      }
      out.push(s1);
    }
    return out;
  }

  static function usedLater(stmts:Array<ElixirAST>, start:Int, name:String): Bool {
    var found = false;
    for (j in start...stmts.length) if (!found) {
      reflaxe.elixir.ast.ASTUtils.walk(stmts[j], function(x:ElixirAST){
        switch (x.def) { case EVar(v) if (v == name): found = true; default: }
      });
    }
    return found;
  }
}

#end

