package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * MountParamsSideEffectAssignDiscardTransforms
 *
 * WHAT
 * - Inside `def mount/3`, drop statements of the form `params = expr` when the
 *   `params` binder is not referenced later. Keeps side effects, removes warning.
 */
class MountParamsSideEffectAssignDiscardTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body) if (name == "mount" && args != null && args.length == 3):
          var nb = discard(body);
          makeASTWithMeta(EDef(name, args, guards, nb), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function discard(body: ElixirAST): ElixirAST {
    return switch (body.def) {
      case EDo(stmts):
        var out:Array<ElixirAST> = [];
        for (i in 0...stmts.length) {
          var s = stmts[i];
          switch (s.def) {
            case EMatch(PVar("params"), rhs) if (!usedLater(stmts, i+1, "params")):
              out.push(rhs);
            case EBinary(Match, {def: EVar("params")}, rhs2) if (!usedLater(stmts, i+1, "params")):
              out.push(rhs2);
            default:
              out.push(s);
          }
        }
        makeASTWithMeta(EDo(out), body.metadata, body.pos);
      case EBlock(stmtsB):
        var outB:Array<ElixirAST> = [];
        for (i in 0...stmtsB.length) {
          var s = stmtsB[i];
          switch (s.def) {
            case EMatch(PVar("params"), rhs) if (!usedLater(stmtsB, i+1, "params")):
              outB.push(rhs);
            case EBinary(Match, {def: EVar("params")}, rhs2) if (!usedLater(stmtsB, i+1, "params")):
              outB.push(rhs2);
            default:
              outB.push(s);
          }
        }
        makeASTWithMeta(EBlock(outB), body.metadata, body.pos);
      default:
        body;
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
