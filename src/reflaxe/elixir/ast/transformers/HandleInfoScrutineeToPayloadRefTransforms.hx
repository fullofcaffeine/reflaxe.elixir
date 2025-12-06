package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HandleInfoScrutineeToPayloadRefTransforms
 *
 * WHAT
 * - In handle_info/2, when a nested `case s do {:tag, binder} -> ... end`
 *   appears, rewrite body references of the scrutinee variable `s` to the
 *   tuple payload binder. This repairs guards like `if (s.user_id == ...)`.
 *
 * WHY
 * - Earlier generic passes may rebuild case trees after the initial
 *   scrutinee→binder mapping, leaving stale references to the scrutinee.
 *   Replaying the mapping scoped to handle_info/2 at a very late stage
 *   ensures correctness for LiveView message handling.
 *
 * HOW
 * - Find `def handle_info(_, _) do ... end` bodies and within them, for each
 *   `ECase(EVar(s), clauses)` where a clause pattern is a two‑tuple with a
 *   variable in the second position, replace `EVar(s)` with that binder
 *   throughout the clause body.
 */
class HandleInfoScrutineeToPayloadRefTransforms {
  public static function transformPass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body):
          if (name == "handle_info" && args.length == 2) {
            var newBody = rewriteInBody(body);
            makeASTWithMeta(EDef(name, args, guards, newBody), n.metadata, n.pos);
          } else n;
        default:
          n;
      }
    });
  }

  static function rewriteInBody(body: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case ECase(scrut, clauses):
          var s = switch (scrut.def) { case EVar(v): v; default: null; };
          if (s == null) return x;
          var out:Array<ECaseClause> = [];
          for (cl in clauses) out.push(rewriteClause(cl, s));
          makeASTWithMeta(ECase(scrut, out), x.metadata, x.pos);
        default:
          x;
      }
    });
  }

  static function rewriteClause(cl: ECaseClause, scrutVar:String): ECaseClause {
    var binder = extractSecondBinder(cl.pattern);
    if (binder == null) return cl;
    // Prefer rewriting the exact scrutinee variable only (no name heuristics)
    var newBody = substituteVar(cl.body, scrutVar, binder);
    return { pattern: cl.pattern, guard: cl.guard, body: newBody };
  }

  static function extractSecondBinder(p:EPattern): Null<String> {
    return switch (p) {
      case PTuple(items) if (items.length == 2):
        switch (items[1]) {
          case PVar(n): n;
          case PPin(inner): switch (inner) { case PVar(n2): n2; default: null; };
          default: null;
        }
      default: null;
    }
  }

  static function substituteVar(body: ElixirAST, from:String, to:String): ElixirAST {
    if (from == to) return body;
    return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case EVar(v) if (v == from): makeASTWithMeta(EVar(to), x.metadata, x.pos);
        default: x;
      }
    });
  }
}

#end
