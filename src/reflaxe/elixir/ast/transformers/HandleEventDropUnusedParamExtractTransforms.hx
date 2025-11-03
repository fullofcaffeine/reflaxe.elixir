package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;

/**
 * HandleEventDropUnusedParamExtractTransforms
 *
 * WHAT
 * - In `def handle_event/3`, drop statements of the form `name = Map.get(params, "key")`
 *   when `name` is not referenced later in the function body.
 */
class HandleEventDropUnusedParamExtractTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body) if (name == "handle_event" && args != null && args.length == 3):
          var nb = rewrite(body);
          makeASTWithMeta(EDef(name, args, guards, nb), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function rewrite(body: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case EBlock(stmts): makeASTWithMeta(EBlock(dropIn(stmts)), x.metadata, x.pos);
        case EDo(stmts2): makeASTWithMeta(EDo(dropIn(stmts2)), x.metadata, x.pos);
        default: x;
      }
    });
  }

  static function dropIn(stmts:Array<ElixirAST>):Array<ElixirAST> {
    if (stmts == null) return stmts;
    var out:Array<ElixirAST> = [];
    for (i in 0...stmts.length) {
      var s = stmts[i];
      var dropped = false;
      switch (s.def) {
        case EBinary(Match, left, rhs):
          switch (left.def) {
            case EVar(v) if (isParamsGet(rhs) && !usedLater(stmts, i+1, v)):
              dropped = true;
            default:
          }
        case EMatch(PVar(pn), rhs2) if (isParamsGet(rhs2) && !usedLater(stmts, i+1, pn)):
          dropped = true;
        default:
      }
      if (!dropped) out.push(s);
    }
    return out;
  }

  static function isParamsGet(e: ElixirAST): Bool {
    return switch (e.def) {
      case ERemoteCall({def: EVar("Map")}, "get", args) if (args != null && args.length == 2):
        switch (args[0].def) { case EVar(p) if (p == "params"): true; default: false; }
      default: false;
    }
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

