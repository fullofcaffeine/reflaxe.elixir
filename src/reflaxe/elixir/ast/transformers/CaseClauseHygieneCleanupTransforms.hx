package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * CaseClauseHygieneCleanupTransforms
 *
 * WHAT
 * - Cleans common hygiene artifacts inside case clause bodies:
 *   - Drops `nil = _var` lines
 *   - Rewrites `socket = Phoenix.LiveView.put_flash(socket, ...)` to `Phoenix.LiveView.put_flash(socket, ...)`
 *
 * WHY
 * - Avoids Phoenix warnings-as-errors while keeping semantics identical (both statements are no-ops).
 */
class CaseClauseHygieneCleanupTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body):
          var nb = rewrite(body);
          makeASTWithMeta(EDef(name, args, guards, nb), n.metadata, n.pos);
        case EDefp(name2, args2, guards2, body2):
          var nb2 = rewrite(body2);
          makeASTWithMeta(EDefp(name2, args2, guards2, nb2), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function rewrite(body: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case ECase(expr, clauses):
          var newClauses = [];
          for (c in clauses) newClauses.push({ pattern: c.pattern, guard: c.guard, body: clean(c.body) });
          makeASTWithMeta(ECase(expr, newClauses), x.metadata, x.pos);
        default: x;
      }
    });
  }

  static function clean(b: ElixirAST): ElixirAST {
    return switch (b.def) {
      case EBlock(stmts): makeASTWithMeta(EBlock(filter(stmts)), b.metadata, b.pos);
      case EDo(stmts2): makeASTWithMeta(EDo(filter(stmts2)), b.metadata, b.pos);
      default: b;
    }
  }

  static function filter(stmts: Array<ElixirAST>): Array<ElixirAST> {
    var out: Array<ElixirAST> = [];
    for (s in stmts) switch (s.def) {
      case EBinary(Match, left, right):
        // Drop `nil = _var`
        var isNil = switch (left.def) { case EVar(nm) if (nm == "nil"): true; case ENil: true; case EAtom(v) if (v == ":nil" || v == "nil"): true; default: false; };
        var isUnderscored = switch (right.def) { case EVar(nm2) if (nm2 != null && nm2.length > 0 && nm2.charAt(0) == '_'): true; default: false; };
        if (!(isNil && isUnderscored)) {
          // Rewrite `socket = Phoenix.LiveView.put_flash(socket, ...)`
          var rewritten = switch (left.def) {
            case EVar(v) if (v == "socket" && isPutFlashOnSocket(right)):
              right;
            default:
              s;
          };
          out.push(rewritten);
        }
      default:
        out.push(s);
    }
    return out;
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
