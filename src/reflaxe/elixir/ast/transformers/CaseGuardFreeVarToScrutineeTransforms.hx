package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * CaseGuardFreeVarToScrutineeTransforms
 *
 * WHAT
 * - In a multi-clause case expression, if a clause's guard references a variable
 *   that is bound in some other clause pattern but not in the current clause
 *   (a clause-local free var), rewrite that reference to the case scrutinee
 *   variable. This eliminates invalid guards like `[] when arr[0] == 72`.
 *
 * WHY
 * - Haxe guards often reuse the list binder name across clauses. In clauses
 *   where that binder is not bound (e.g., the [] clause), Elixir produces
 *   invalid code. Mapping the guard reference to the scrutinee preserves the
 *   semantics without app-specific heuristics.
 *
 * HOW
 * - For ECase(scrutinee, clauses): determine the scrutinee variable; if not a
 *   variable, do nothing (hoist runs in other passes). Compute the union of
 *   binder names used in all clause patterns. For each clause, compute bound
 *   names in its pattern; in guard, rewrite EVar(v) to the scrutinee var when
 *   v is in union but not in bound set.
 */
class CaseGuardFreeVarToScrutineeTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case ECase(scrutinee, clauses):
          var scrutVar: Null<String> = switch (scrutinee.def) { case EVar(nm): nm; default: null; };
          if (scrutVar == null) n else {
            var unionBinders = collectAllBinderNames(clauses);
            var newClauses:Array<ECaseClause> = [];
            for (cl in clauses) {
              var bound = collectBinderNames(cl.pattern);
              var newGuard = cl.guard;
              if (newGuard != null) {
                newGuard = ElixirASTTransformer.transformNode(newGuard, function(g:ElixirAST):ElixirAST {
                  return switch (g.def) {
                    case EVar(vname) if (unionBinders.exists(vname) && !bound.exists(vname)):
                      makeAST(EVar(scrutVar));
                    default: g;
                  }
                });
              }
              newClauses.push({ pattern: cl.pattern, guard: newGuard, body: cl.body });
            }
            makeASTWithMeta(ECase(scrutinee, newClauses), n.metadata, n.pos);
          }
        default:
          n;
      }
    });
  }

  static function collectAllBinderNames(clauses:Array<ECaseClause>): Map<String,Bool> {
    var m = new Map<String,Bool>();
    for (cl in clauses) {
      var b = collectBinderNames(cl.pattern);
      for (k in b.keys()) m.set(k, true);
    }
    return m;
  }

  static function collectBinderNames(p: EPattern): Map<String,Bool> {
    var m = new Map<String,Bool>();
    function walkPat(pp:EPattern):Void {
      switch (pp) {
        case PVar(n): m.set(n, true);
        case PCons(h, t): walkPat(h); walkPat(t);
        case PTuple(els): for (e in els) walkPat(e);
        case PList(els): for (e in els) walkPat(e);
        case PMap(pairs): for (kv in pairs) walkPat(kv.value);
        case PStruct(_, fields): for (f in fields) walkPat(f.value);
        case PPin(inner): walkPat(inner);
        case PAlias(nm, inner): m.set(nm, true); walkPat(inner);
        default:
      }
    }
    walkPat(p);
    return m;
  }
}

#end

