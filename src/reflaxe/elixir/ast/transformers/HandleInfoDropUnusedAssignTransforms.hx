package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HandleInfoDropUnusedAssignTransforms
 *
 * WHAT
 * - Inside `def handle_info/2`, drop leading assignments of the shape
 *   `var = case ... end` where `var` is not used afterwards. This targets the
 *   common lowering that binds the case result to a throwaway variable like `g`.
 *
 * WHY
 * - Avoids WAE warnings without touching semantics. The case already returns
 *   `{:noreply, socket}` in each branch.
 */
class HandleInfoDropUnusedAssignTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body) if (name == "handle_info" && args != null && args.length == 2):
          var newBody = rewriteBody(body);
          makeASTWithMeta(EDef(name, args, guards, newBody), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function rewriteBody(body: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case EBlock(stmts): makeASTWithMeta(EBlock(rewrite(stmts)), x.metadata, x.pos);
        case EDo(stmts2): makeASTWithMeta(EDo(rewrite(stmts2)), x.metadata, x.pos);
        default: x;
      }
    });
  }

  static function rewrite(stmts:Array<ElixirAST>):Array<ElixirAST> {
    if (stmts == null) return stmts;
    var out:Array<ElixirAST> = [];
    for (i in 0...stmts.length) {
      var s = stmts[i];
      var handled = false;
      switch (s.def) {
        case EBinary(Match, left, rhs):
          switch (left.def) {
            case EVar(name) if (!usedLater(stmts, i+1, name) && isCase(rhs)):
              out.push(rhs); handled = true;
            default:
          }
        case EMatch(PVar(name2), rhs2) if (!usedLater(stmts, i+1, name2) && isCase(rhs2)):
          out.push(rhs2); handled = true;
        default:
      }
      if (!handled) out.push(s);
    }
    return out;
  }

  static function isCase(e: ElixirAST): Bool {
    var cur = e;
    while (true) switch (cur.def) { case EParen(inner): cur = inner; continue; default: break; }
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

