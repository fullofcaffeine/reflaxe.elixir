package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * CaseEmptyListGuardNormalizeTransforms
 *
 * WHAT
 * - For case expressions on lists, when a clause pattern is [] but the guard
 *   references an element (index 0) or asserts non-empty via length>1, rewrite
 *   the clause to [first | rest] and fix the guard to use first/rest.
 *
 * WHY
 * - A guard that implies non-empty contradicts the [] pattern and leads to
 *   invalid Elixir. This transform preserves semantics and fixes syntax.
 *
 * HOW
 * - Detect ECase(..., clauses) and for each clause with PList([]) or
 *   PLiteral(EList([])) whose guardImpliesNonEmpty(guard) is true, change the
 *   pattern to PCons(PVar("first"), PVar("rest")) and rewrite guard:
 *     any [x][0] → first
 *     length(_)>1 → rest != []
 */
class CaseEmptyListGuardNormalizeTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case ECase(scrutinee, clauses):
          var changed = false;
          var updated:Array<ECaseClause> = [];
          for (cl in clauses) {
            var shouldFix = (cl.guard != null) && guardImpliesNonEmpty(cl.guard) && (switch (cl.pattern) { case PList([]) | PLiteral({def: EList([])}): true; default: false; });
            if (shouldFix) {
              changed = true;
              var newPat = PCons(PVar("first"), PVar("rest"));
              var newGuard = rewriteGuard(cl.guard);
              updated.push({ pattern: newPat, guard: newGuard, body: cl.body });
            } else {
              updated.push(cl);
            }
          }
          changed ? makeASTWithMeta(ECase(scrutinee, updated), n.metadata, n.pos) : n;
        default:
          n;
      }
    });
  }

  static function guardImpliesNonEmpty(g: ElixirAST): Bool {
    var found = false;
    function walk(e: ElixirAST): Void {
      if (found || e == null) return;
      switch (e.def) {
        case EAccess(_, {def: EInteger(0)}): found = true;
        case EBinary(Greater, {def: ERemoteCall(_, "length", _) | ECall(null, "length", _)}, {def: EInteger(1)}): found = true;
        case EBinary(_, l, r): walk(l); walk(r);
        case ERemoteCall(m, _, as): walk(m); for (a in as) walk(a);
        case ECall(t, _, as): if (t != null) walk(t); for (a in as) walk(a);
        case EParen(inner) | EUnary(_, inner): walk(inner);
        default:
      }
    }
    walk(g);
    return found;
  }

  static function rewriteGuard(g: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(g, function(e: ElixirAST): ElixirAST {
      return switch (e.def) {
        case EAccess(_, {def: EInteger(0)}): makeAST(EVar("first"));
        case EBinary(Greater, {def: ERemoteCall(_, "length", _) | ECall(null, "length", _)}, {def: EInteger(1)}):
          makeAST(EBinary(NotEqual, makeAST(EVar("rest")), makeAST(EList([]))));
        default:
          e;
      }
    });
  }
}

#end

