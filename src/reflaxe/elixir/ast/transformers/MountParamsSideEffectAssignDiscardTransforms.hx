package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.OptimizedVarUseAnalyzer;

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
        var usage = OptimizedVarUseAnalyzer.buildExact(stmts);
        var out:Array<ElixirAST> = [];
        for (i in 0...stmts.length) {
          var s = stmts[i];
          switch (s.def) {
            case EMatch(PVar("params"), rhs) if (!OptimizedVarUseAnalyzer.usedLater(usage, i + 1, "params")):
              out.push(rhs);
            case EBinary(Match, {def: EVar("params")}, rhs2) if (!OptimizedVarUseAnalyzer.usedLater(usage, i + 1, "params")):
              out.push(rhs2);
            case EMatch(PVar("_params"), rhs3) if (!OptimizedVarUseAnalyzer.usedLater(usage, i + 1, "_params")):
              out.push(rhs3);
            case EBinary(Match, {def: EVar("_params")}, rhs4) if (!OptimizedVarUseAnalyzer.usedLater(usage, i + 1, "_params")):
              out.push(rhs4);
            default:
              out.push(s);
          }
        }
        makeASTWithMeta(EDo(out), body.metadata, body.pos);
      case EBlock(stmtsB):
        var usage = OptimizedVarUseAnalyzer.buildExact(stmtsB);
        var outB:Array<ElixirAST> = [];
        for (i in 0...stmtsB.length) {
          var s = stmtsB[i];
          switch (s.def) {
            case EMatch(PVar("params"), rhs) if (!OptimizedVarUseAnalyzer.usedLater(usage, i + 1, "params")):
              outB.push(rhs);
            case EBinary(Match, {def: EVar("params")}, rhs2) if (!OptimizedVarUseAnalyzer.usedLater(usage, i + 1, "params")):
              outB.push(rhs2);
            case EMatch(PVar("_params"), rhs3) if (!OptimizedVarUseAnalyzer.usedLater(usage, i + 1, "_params")):
              outB.push(rhs3);
            case EBinary(Match, {def: EVar("_params")}, rhs4) if (!OptimizedVarUseAnalyzer.usedLater(usage, i + 1, "_params")):
              outB.push(rhs4);
            default:
              outB.push(s);
          }
        }
        makeASTWithMeta(EBlock(outB), body.metadata, body.pos);
      default:
        body;
    }
  }
}

#end
