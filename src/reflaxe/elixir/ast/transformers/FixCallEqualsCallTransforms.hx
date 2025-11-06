package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * FixCallEqualsCallTransforms
 *
 * WHAT
 * - Rewrites invalid match expressions where both LHS and RHS are calls
 *   (e.g., `Log.trace(...)=Log.trace(...)`) into two sequential underscore
 *   assignments.
 *
 * WHY
 * - Such shapes can arise from nested cleanups and are not valid Elixir. The
 *   intent is to perform both calls for their effects and discard results.
 *
 * HOW
 * - In EBlock/EDo, replace `EBinary(Match, E(Call|RemoteCall), E(Call|RemoteCall))`
 *   with `[_ = leftCall, _ = rightCall]`.
 */
class FixCallEqualsCallTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      if (n == null || n.def == null) return n;
      return switch (n.def) {
        case EBinary(Match, l, r):
          var ll = unwrapParens(l);
          var rr = unwrapParens(r);
          var leftIsCall = switch (ll.def) { case ECall(_,_,_) | ERemoteCall(_,_,_): true; default: false; };
          var rightIsCall = switch (rr.def) { case ECall(_,_,_) | ERemoteCall(_,_,_): true; default: false; };
          if (leftIsCall && rightIsCall) {
            makeASTWithMeta(EBlock([
              makeAST(EBinary(Match, makeAST(EVar("_")), ll)),
              makeAST(EBinary(Match, makeAST(EVar("_")), rr))
            ]), n.metadata, n.pos);
          } else n;
        default:
          n;
      }
    });
  }

  static function unwrapParens(e: ElixirAST): ElixirAST {
    var cur = e;
    while (cur != null && cur.def != null) switch (cur.def) {
      case EParen(inner): cur = inner; continue;
      default: break;
    }
    return cur;
  }
}

#end
