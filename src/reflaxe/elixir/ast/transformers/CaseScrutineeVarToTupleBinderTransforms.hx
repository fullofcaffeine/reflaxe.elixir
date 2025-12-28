package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * CaseScrutineeVarToTupleBinderTransforms
 *
 * WHAT
 * - In `case scrutinee do` where a clause pattern is a two‑tuple `{:tag, binder}`,
 *   rewrite body references to the scrutinee variable to refer to the tuple
 *   binder. This fixes shapes like `case todo do {:todo_created, todo2} ->
 *   if (todo.user_id == ...)` by mapping `todo` → `todo2` in the clause body.
 *
 * WHY
 * - When code first binds an event to a variable and then re‑matches it with a
 *   tuple pattern, subsequent body code often intends to use the tuple’s second
 *   element (payload) rather than the original tuple value. Leaving references
 *   to the scrutinee produces invalid field access (e.g., `tuple.user_id`).
 *
 * HOW
 * - For each ECase whose scrutinee is a simple variable `s`, scan clauses; when
 *   a clause pattern is `{:atom, PVar(b)}` (or pinned variant), transform the
 *   clause body by replacing `EVar(s)` with `EVar(b)`. Remote calls/fields are
 *   handled naturally by the generic EVar replacement.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class CaseScrutineeVarToTupleBinderTransforms {
  public static function transformPass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case ECase(scrut, clauses):
          var scrutVar: Null<String> = switch(scrut.def) { case EVar(v): v; default: null; };
          if (scrutVar == null) return n;
          var out:Array<ECaseClause> = [];
          for (cl in clauses) out.push(rewriteClause(cl, scrutVar));
          makeASTWithMeta(ECase(scrut, out), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function rewriteClause(cl: ECaseClause, scrutVar:String): ECaseClause {
    var binder: Null<String> = extractSecondBinder(cl.pattern);
    if (binder == null) return cl;
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
