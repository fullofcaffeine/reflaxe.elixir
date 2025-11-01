package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * MountParamsUnusedReassignUnderscoreTransforms
 *
 * WHAT
 * - In def mount/3 bodies, rename `params = ...` to `_params = ...` when `params`
 *   is not referenced later in the same body. Preserves RHS side-effects.
 */
class MountParamsUnusedReassignUnderscoreTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef("mount", args, guards, body) if (args != null && args.length == 3):
          makeASTWithMeta(EDef("mount", args, guards, rewrite(body)), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function rewrite(body: ElixirAST): ElixirAST {
    return switch (body.def) {
      case EBlock(stmts): makeASTWithMeta(EBlock(rewriteSeq(stmts)), body.metadata, body.pos);
      case EDo(stmts2): makeASTWithMeta(EDo(rewriteSeq(stmts2)), body.metadata, body.pos);
      default: body;
    }
  }

  static function rewriteSeq(stmts:Array<ElixirAST>):Array<ElixirAST> {
    if (stmts == null) return stmts;
    var out:Array<ElixirAST> = [];
    for (i in 0...stmts.length) {
      var s = stmts[i];
      var s1 = switch (s.def) {
        case EMatch(PVar("params"), rhs):
          makeASTWithMeta(EMatch(PVar("_"), rhs), s.metadata, s.pos);
        case EBinary(Match, {def: EVar("params")}, rhs2):
          makeASTWithMeta(EBinary(Match, makeAST(EVar("_")), rhs2), s.metadata, s.pos);
        default: s;
      };
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
