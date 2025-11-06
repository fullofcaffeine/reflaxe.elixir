package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * CaseSuccessVarUnifyTransforms
 *
 * WHAT
 * - Promotes success-binder names in `{:ok, _x}` case patterns to `{:ok, x}` when the clause body clearly
 *   references `x`. This resolves undefined-variable WAE issues introduced by earlier underscore hygiene.
 *
 * WHY
 * - Hygiene passes may underscore unused pattern binders (e.g., `_updated_todo`) while later code in the
 *   success branch refers to the intended name (`updated_todo`). That mismatch causes undefined-variable
 *   errors even though the value is bound by the case pattern. Usage-driven promotion restores coherence
 *   without relying on app-specific identifiers.
 *
 * HOW
 * - Scope: only case clauses whose pattern is a 2-tuple with first element `:ok` and second element `PVar`.
 * - Guard: second element must be a variable name starting with `_`. The trimmed name (without `_`) must
 *   be referenced in the clause body (usage-driven, not name-heuristic).
 * - Rewrite: pattern `{:ok, _x}` becomes `{:ok, x}`. Guard/body remain unchanged.
 * - Ordering: intended to run very late (absolute), after other binder/underscore passes, to converge on
 *   the final binder spelling that the body actually uses.
 *
 * EXAMPLES
 * Before:
 *   case TodoApp.Repo.update(changeset) do
 *     {:ok, _updated_todo} ->
 *       TodoPubSub.broadcast(:todo_updates, {:todo_updated, updated_todo})
 *       update_todo_in_list(updated_todo, socket)
 *   end
 * After:
 *   case TodoApp.Repo.update(changeset) do
 *     {:ok, updated_todo} ->
 *       TodoPubSub.broadcast(:todo_updates, {:todo_updated, updated_todo})
 *       update_todo_in_list(updated_todo, socket)
 *   end
 *
 * SAFETY & LIMITS
 * - No name invention: only trims a single leading underscore and only when the body references the trimmed
 *   name. If the body doesn’t use it, the pattern binder remains underscored.
 * - Shape/API-based: restricted to the success tuple `{:ok, _x}`; error branches and other tuples untouched.
 * - Complements CaseSuccessVarUnifier (which rewrites undefined body refs to the bound success var); this
 *   pass aligns the pattern itself with usage to avoid future drift.
 */
class CaseSuccessVarUnifyTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ECase(expr, clauses):
                    var newClauses = [];
                    for (cl in clauses) {
                        // Skip if payload binder is locked/canonicalized to _value
                        if (isLockedPayload(cl)) { newClauses.push(cl); continue; }
                        // Collect names used in body
                        var used = new Map<String, Bool>();
                        collectNames(cl.body, used);
                        // Rewrite {:ok, _x} -> {:ok, x} when body references x
                        var newPattern:EPattern = cl.pattern;
                                switch (cl.pattern) {
                            case PTuple(parts) if (parts.length == 2):
                                var firstIsOk = false;
                                switch (parts[0]) {
                                    case PLiteral(lit):
                                        firstIsOk = switch (lit.def) {
                                            case EAtom(val) if (val == ":ok" || val == "ok"): true;
                                            default: false;
                                        };
                                    default:
                                }
                                if (firstIsOk) switch (parts[1]) {
                                    case PVar(binder) if (binder != null && binder.length > 1 && binder.charAt(0) == '_'):
                                        var cand = binder.substr(1);
                                        if (used.exists(cand)) newPattern = PTuple([parts[0], PVar(cand)]);
                                    default:
                                }
                            default:
                        }
                        newClauses.push({ pattern: newPattern, guard: cl.guard, body: cl.body });
                    }
                    makeASTWithMeta(ECase(expr, newClauses), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static inline function isLockedPayload(cl: ECaseClause): Bool {
        var isTwo = false;
        var secondIsValue = false;
        switch (cl.pattern) {
            case PTuple(parts) if (parts.length == 2):
                isTwo = true;
                switch (parts[1]) { case PVar(b) if (b == "_value"): secondIsValue = true; default: }
            default:
        }
        if (!isTwo) return false;
        if (secondIsValue) return true;
        // Also honor explicit lock flag on the body, if present
        var locked = false;
        try {
            locked = untyped (cl.body != null && cl.body.metadata != null && (cl.body.metadata.lockPayloadBinder == true));
        } catch (e:Dynamic) {}
        return locked;
    }

    static function collectNames(node: ElixirAST, acc: Map<String, Bool>): Void {
        if (node == null || node.def == null) return;
        switch (node.def) {
            case EVar(n): acc.set(n, true);
            case EBlock(ss): for (s in ss) collectNames(s, acc);
            case EIf(c,t,e): collectNames(c, acc); collectNames(t, acc); if (e != null) collectNames(e, acc);
            case ECase(ex, cls): collectNames(ex, acc); for (c in cls) collectNames(c.body, acc);
            case EBinary(_, l, r): collectNames(l, acc); collectNames(r, acc);
            case EMatch(p, rhs): collectNames(rhs, acc);
            case ECall(tgt, _, args): if (tgt != null) collectNames(tgt, acc); for (a in args) collectNames(a, acc);
            case ERemoteCall(tgt2, _, args2): collectNames(tgt2, acc); for (a2 in args2) collectNames(a2, acc);
            case EList(els): for (e in els) collectNames(e, acc);
            case ETuple(els): for (e in els) collectNames(e, acc);
            case EMap(kvs): for (kv in kvs) { collectNames(kv.key, acc); collectNames(kv.value, acc); }
            case EKeywordList(kvs): for (kv in kvs) collectNames(kv.value, acc);
            case EStructUpdate(base, flds): collectNames(base, acc); for (f in flds) collectNames(f.value, acc);
            case EFn(clauses): for (cl in clauses) collectNames(cl.body, acc);
            default:
        }
    }
}

#end
