package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * CasePatternUnusedBinderUnderscoreTransforms
 *
 * WHAT
 * - In case clauses that pattern-match on two-tuples like `{:tag, binder}`,
 *   underscore the payload `binder` to `_binder` when it is not referenced in
 *   the clause body. This avoids unused-variable warnings under WAE.
 *
 * WHY
 * - Controllers and LiveViews commonly match `{:ok, value}` / `{:error, reason}`.
 *   When the payload is not used, keeping a named binder triggers warnings.
 *   Renaming to `_value`/`_reason` is the idiomatic Elixir practice.
 *
 * HOW
 * - Walk ECase nodes; for each clause with a PTuple([PLiteral(_), PVar(name)]):
 *   - If `name` does not appear in the clause body, rewrite the pattern to
 *     use `_name`. The body is left unchanged.
 */
class CasePatternUnusedBinderUnderscoreTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case ECase(expr, clauses):
          var out = [];
          for (cl in clauses) out.push(underscoreIfUnused(cl));
          makeASTWithMeta(ECase(expr, out), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function underscoreIfUnused(cl:{pattern:EPattern, guard:Null<ElixirAST>, body:ElixirAST}):{pattern:EPattern, guard:Null<ElixirAST>, body:ElixirAST} {
    var name:Null<String> = null;
    switch (cl.pattern) {
      case PTuple(es) if (es.length == 2):
        switch (es[1]) { case PVar(nm): name = nm; default: }
      default:
    }
    if (name == null) return cl;
    var used = false;
    reflaxe.elixir.ast.ASTUtils.walk(cl.body, function(n:ElixirAST){
      switch (n.def) { case EVar(v) if (v == name): used = true; default: }
    });
    if (used) return cl;
    // Rewrite binder to _name if not already underscored
    var newPat = switch (cl.pattern) {
      case PTuple(es2) if (es2.length == 2):
        var payload = switch (es2[1]) {
          case PVar(nm2) if (nm2.length > 0 && nm2.charAt(0) != '_'): PVar('_' + nm2);
          default: es2[1];
        };
        PTuple([es2[0], payload]);
      default:
        cl.pattern;
    }
    return { pattern: newPat, guard: cl.guard, body: cl.body };
  }
}

#end

