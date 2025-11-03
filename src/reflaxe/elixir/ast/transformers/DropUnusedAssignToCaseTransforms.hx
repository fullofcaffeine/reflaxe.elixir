package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

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
      switch (s.def) {
        case EBinary(Match, left, rhs) if (isCase(rhs)):
          switch (left.def) {
            case EVar(name) if (!usedLater(stmts, i+1, name)):
              out.push(rhs);
            default:
              out.push(s);
          }
        case EMatch(PVar(name2), rhs2) if (isCase(rhs2) && !usedLater(stmts, i+1, name2)):
          out.push(rhs2);
        default:
          out.push(s);
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
