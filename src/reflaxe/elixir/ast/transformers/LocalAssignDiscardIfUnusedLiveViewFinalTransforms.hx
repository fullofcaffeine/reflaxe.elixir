package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * LocalAssignDiscardIfUnusedLiveViewFinalTransforms
 *
 * WHAT
 * - In LiveView modules, replace `var = expr` / `var <- expr` with `_ = expr`
 *   when `var` is never referenced later in the same block. Semantics are
 *   preserved; warnings vanish.
 */
class LocalAssignDiscardIfUnusedLiveViewFinalTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      if (n == null || n.metadata == null || Reflect.field(n.metadata, "isLiveView") != true) return n;
      return switch (n.def) {
        case EDef(name, args, guards, body):
          makeASTWithMeta(EDef(name, args, guards, rewrite(body)), n.metadata, n.pos);
        case EDefp(name2, args2, guards2, body2):
          makeASTWithMeta(EDefp(name2, args2, guards2, rewrite(body2)), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function rewrite(node: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(node, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case EBlock(stmts): makeASTWithMeta(EBlock(rewriteBlock(stmts)), x.metadata, x.pos);
        case EDo(stmts2): makeASTWithMeta(EDo(rewriteBlock(stmts2)), x.metadata, x.pos);
        default: x;
      }
    });
  }

  static function rewriteBlock(stmts:Array<ElixirAST>): Array<ElixirAST> {
    if (stmts == null) return stmts;
    var out:Array<ElixirAST> = [];
    for (i in 0...stmts.length) {
      var s = stmts[i];
      var s2 = s;
      switch (s.def) {
        case EBinary(Match, {def: EVar(b)}, rhs):
          if (b != "children" && !usedLater(stmts, i+1, b)) s2 = makeASTWithMeta(EBinary(Match, makeAST(EVar("_")), rhs), s.metadata, s.pos);
        case EMatch(PVar(b2), rhs2):
          if (b2 != "children" && !usedLater(stmts, i+1, b2)) s2 = makeASTWithMeta(EMatch(PVar("_"), rhs2), s.metadata, s.pos);
        default:
      }
      out.push(s2);
    }
    return out;
  }

  static function usedLater(stmts:Array<ElixirAST>, start:Int, name:String): Bool {
    var found = false;
    for (j in start...stmts.length) if (!found) {
      reflaxe.elixir.ast.ASTUtils.walk(stmts[j], function(n: ElixirAST) {
        switch (n.def) { case EVar(v) if (v == name): found = true; default: }
      });
    }
    return found;
  }
}

#end
