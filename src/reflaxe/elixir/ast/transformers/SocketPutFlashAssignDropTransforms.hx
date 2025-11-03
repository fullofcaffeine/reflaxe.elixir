package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * SocketPutFlashAssignDropTransforms
 *
 * WHAT
 * - Rewrites `socket = Phoenix.LiveView.put_flash(socket, ...)` to just
 *   `Phoenix.LiveView.put_flash(socket, ...)` to avoid unused-variable warnings.
 *
 * WHY
 * - The assignment is redundant and triggers WAE when the resulting value is
 *   not rebound (common in branches).
 */
class SocketPutFlashAssignDropTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body):
          var nb = rewrite(body);
          makeASTWithMeta(EDef(name, args, guards, nb), n.metadata, n.pos);
        case EDefp(name2, args2, guards2, body2):
          var nb2 = rewrite(body2);
          makeASTWithMeta(EDefp(name2, args2, guards2, nb2), n.metadata, n.pos);
        default: rewrite(n);
      }
    });
  }

  static function rewrite(node: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(node, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EBinary(Match, left, rhs) if (isSocketVar(left) && isPutFlashOnSocket(rhs)):
          rhs;
        case EMatch(PVar(name), rhs2) if (name == "socket" && isPutFlashOnSocket(rhs2)):
          rhs2;
        default: n;
      }
    });
  }

  static inline function isSocketVar(e: ElixirAST): Bool {
    return switch (e.def) { case EVar(nm) if (nm == "socket"): true; default: false; }
  }

  static inline function isPutFlashOnSocket(e: ElixirAST): Bool {
    return switch (e.def) {
      case ERemoteCall(target, fnName, args) if (fnName == "put_flash" && args != null && args.length >= 2):
        var isMod = switch (target.def) { case EVar(m) if (m == "Phoenix.LiveView"): true; default: false; };
        var firstIsSocket = switch (args[0].def) { case EVar(n) if (n == "socket"): true; default: false; };
        isMod && firstIsSocket;
      default: false;
    }
  }
}

#end
