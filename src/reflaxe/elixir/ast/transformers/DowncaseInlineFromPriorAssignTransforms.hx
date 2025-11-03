package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;

/**
 * DowncaseInlineFromPriorAssignTransforms
 *
 * WHAT
 * - If a block contains an earlier assignment `v = rhs` and later we see
 *   `String.downcase(v)` with no intervening rebind of `v` and `v` is not used
 *   elsewhere, inline to `String.downcase(rhs)` and drop the earlier assign.
 */
class DowncaseInlineFromPriorAssignTransforms {
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
    var assigns:Map<String, { idx:Int, rhs:ElixirAST } > = new Map();
    for (i in 0...stmts.length) {
      var s = stmts[i];
      var replaced:Null<ElixirAST> = null;
      switch (s.def) {
        case EBinary(Match, left, rhs):
          switch (left.def) { case EVar(v): assigns.set(v, {idx: out.length, rhs: rhs}); default: }
        case ERemoteCall({def: EVar("String")}, "downcase", args) if (args != null && args.length == 1):
          switch (args[0].def) {
            case EVar(vname) if (assigns.exists(vname) && !usedBetween(out, stmts, assigns.get(vname).idx+1, i, vname) && !usedLater(stmts, i+1, vname)):
              var rec = assigns.get(vname);
              // remove earlier assign from out
              out = out.slice(0, rec.idx).concat(out.slice(rec.idx+1));
              replaced = makeASTWithMeta(ERemoteCall(makeASTWithMeta(EVar("String"), s.metadata, s.pos), "downcase", [rec.rhs]), s.metadata, s.pos);
            default:
          }
        default:
      }
      out.push(replaced != null ? replaced : s);
    }
    return out;
  }

  static function usedBetween(out:Array<ElixirAST>, stmts:Array<ElixirAST>, start:Int, endIdx:Int, name:String): Bool {
    var found = false;
    for (j in start...endIdx) if (!found) {
      var node = j < out.length ? out[j] : stmts[j];
      reflaxe.elixir.ast.ASTUtils.walk(node, function(x:ElixirAST){
        switch (x.def) { case EVar(v) if (v == name): found = true; default: }
      });
    }
    return found;
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

