package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * MountCaseSocketAssignDropTransforms
 *
 * WHAT
 * - In `def mount/3`, drop clause bodies of the form `socket = Phoenix.LiveView.put_flash(socket, ...)`
 *   to just the call expression, avoiding unused-variable warnings.
 */
class MountCaseSocketAssignDropTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body) if (name == "mount" && args != null && args.length == 3):
          var nb = rewriteInBody(body);
          makeASTWithMeta(EDef(name, args, guards, nb), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function rewriteInBody(body: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case ECase(expr, clauses):
          var newClauses = [];
          for (c in clauses) {
            var newBody = dropSocketAssign(c.body);
            newClauses.push({pattern: c.pattern, guard: c.guard, body: newBody});
          }
          makeASTWithMeta(ECase(expr, newClauses), x.metadata, x.pos);
        case EBinary(Match, left, rhs):
          // Also drop top-level `socket = Phoenix.LiveView.put_flash(socket, ...)`
          switch (left.def) {
            case EVar(v) if (v == "socket"):
              rhs;
            default: x;
          }
        default: x;
      }
    });
  }

  static function dropSocketAssign(b: ElixirAST): ElixirAST {
    return switch (b.def) {
      case EBinary(Match, left, rhs):
        switch (left.def) {
          case EVar(v) if (v == "socket"): rhs;
          default: b;
        }
      default: b;
    }
  }
}

#end
