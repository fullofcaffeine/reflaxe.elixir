package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * CaseListGuardToConsTransforms
 *
 * WHAT
 * - When a case clause matches [] (empty list) but its guard references the
 *   first element via list[0] or length(list) > 1, rewrite the clause pattern
 *   to [head | tail] and rewrite the guard to use head/tail binders.
 *
 * WHY
 * - A guard like `arr[0] == 72` implies non-empty, which contradicts the []
 *   pattern and leads to invalid code. Rewriting to a cons pattern restores
 *   validity and preserves intent.
 *
 * HOW
 * - Detect ECase(..., clauses) and scan clauses with PList([]) patterns whose
 *   guard contains head/tail conditions (index 0 or length>1). Replace pattern
 *   with PCons(PVar("head"), PVar("tail")) and apply guard substitutions:
 *     list[0] → head; length(list) > 1 → tail != [] (shape-only).
 */
class CaseListGuardToConsTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case ECase(scrutinee, clauses):
          var updated: Array<ECaseClause> = [];
          for (cl in clauses) {
            switch (cl.pattern) {
              case PList([]) if (cl.guard != null && guardImpliesNonEmpty(cl.guard)):
                Sys.println('[CaseListGuardToCons] Rewrite [] → [head|tail] with repaired guard');
                var newPat = PCons(PVar("head"), PVar("tail"));
                var newGuard = rewriteGuard(cl.guard);
                updated.push({ pattern: newPat, guard: newGuard, body: cl.body });
              case PLiteral({def: EList([])}) if (cl.guard != null && guardImpliesNonEmpty(cl.guard)):
                Sys.println('[CaseListGuardToCons] Rewrite PLiteral([]) → [head|tail] with repaired guard');
                var newPat2 = PCons(PVar("head"), PVar("tail"));
                var newGuard2 = rewriteGuard(cl.guard);
                updated.push({ pattern: newPat2, guard: newGuard2, body: cl.body });
              default:
                updated.push(cl);
            }
          }
          makeASTWithMeta(ECase(scrutinee, updated), n.metadata, n.pos);
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
        case EAccess(_, {def: EInteger(0)}): makeAST(EVar("head"));
        case EBinary(Greater, {def: ERemoteCall(_, "length", _) | ECall(null, "length", _)}, {def: EInteger(1)}):
          makeAST(EBinary(NotEqual, makeAST(EVar("tail")), makeAST(EList([]))));
        default:
          e;
      }
    });
  }
}

#end
