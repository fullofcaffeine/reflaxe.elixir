package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import StringTools;

/**
 * AssignChainPruneTransforms
 *
 * WHAT
 * - Prune unused binders in chained assignments like `a = b = expr` and
 *   drop trivial unused assignments such as `tmp = nil` when `tmp` is not
 *   referenced later in the block.
 *
 * WHY
 * - Builder can emit chain assignments to thread values across steps.
 *   When an intermediate binder is never referenced, Elixir warns about
 *   unused variables. Removing those binders preserves semantics while
 *   eliminating warnings.
 *
 * HOW
 * - Walk EBlock statements. For any statement at index i that matches
 *   `leftA = (leftB = expr)`, scan statements (i+1..end) for references
 *   to leftB. If not referenced, rewrite to `leftA = expr`.
 * - Also, if the chain is `leftA (unused) = (leftB = expr)` and leftA is
 *   never used later, rewrite to `leftB = expr`.
 * - Additionally, drop assignments of the form `var = nil` when `var` is
 *   not used later in the block.
 *
 * EXAMPLES
 * Before:
 *   cs = this1 = Ecto.Changeset.change(todo, params)
 *   this1 = cs = Ecto.Changeset.validate_required(cs, [:title])
 * After:
 *   cs = Ecto.Changeset.change(todo, params)
 *   cs = Ecto.Changeset.validate_required(cs, [:title])
 */
class AssignChainPruneTransforms {
    public static function prunePass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body) if (looksLikePresenceModule(name, n)):
                    n;
                case EDefmodule(name, doBlock) if (looksLikePresenceModule(name, n)):
                    n;
                case EBlock(stmts):
                    var out:Array<ElixirAST> = [];
                    for (i in 0...stmts.length) {
                        var s = stmts[i];
                        // Drop `var = nil` when var not used later
                        var dropped = false;
                        switch (s.def) {
                            case EBinary(Match, left0, right0):
                                // Never drop or rewrite presence effect assignments
                                if (isPresenceEffectCall(right0)) {
                                    out.push(s);
                                    continue;
                                }
                                var lhsName0:Null<String> = switch (left0.def) { case EVar(nm): nm; default: null; };
                                if (lhsName0 != null) {
                                    switch (right0.def) {
                                        case ENil:
                                            if (!nameUsedLater(stmts, i+1, lhsName0)) { dropped = true; }
                                        default:
                                    }
                                }
                            default:
                        }
                        if (dropped) continue;

                        // Prune chain assignments: a = (b = expr)
                        switch (s.def) {
                            case EBinary(Match, leftA, right):
                                switch (right.def) {
                                    case EBinary(Match, leftB, expr):
                                        if (isPresenceEffectCall(expr)) { out.push(s); continue; }
                                        var aName:Null<String> = switch (leftA.def) { case EVar(na): na; default: null; };
                                        var bName:Null<String> = switch (leftB.def) { case EVar(nb): nb; default: null; };
                                        if (bName != null && !nameUsedLater(stmts, i+1, bName)) {
                                            out.push(makeASTWithMeta(EBinary(Match, leftA, expr), s.metadata, s.pos));
                                            continue;
                                        }
                                        if (aName != null && !nameUsedLater(stmts, i+1, aName) && bName != null) {
                                            out.push(makeASTWithMeta(EBinary(Match, leftB, expr), s.metadata, s.pos));
                                            continue;
                                        }
                                        out.push(s);
                                    default:
                                        out.push(s);
                                }
                            case EMatch(patA, right2):
                                switch (right2.def) {
                                    case EBinary(Match, leftB2, expr2):
                                        if (isPresenceEffectCall(expr2)) { out.push(s); continue; }
                                        var bName2:Null<String> = switch (leftB2.def) { case EVar(nb2): nb2; default: null; };
                                        // If left pattern is a single variable and it is unused, rewrite
                                        var aName2:Null<String> = switch (patA) { case PVar(na2): na2; default: null; };
                                        if (bName2 != null && !nameUsedLater(stmts, i+1, bName2) && aName2 != null) {
                                            out.push(makeASTWithMeta(EMatch(patA, expr2), s.metadata, s.pos));
                                            continue;
                                        }
                                        if (aName2 != null && !nameUsedLater(stmts, i+1, aName2) && bName2 != null) {
                                            out.push(makeASTWithMeta(EBinary(Match, leftB2, expr2), s.metadata, s.pos));
                                            continue;
                                        }
                                        out.push(s);
                                    default:
                                        out.push(s);
                                }
                            default:
                                out.push(s);
                        }
                    }
                    makeASTWithMeta(EBlock(out), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static inline function looksLikePresenceModule(name:String, node:ElixirAST):Bool {
        if (node != null && node.metadata != null && node.metadata.isPresence == true) return true;
        if (name == null) return false;
        return StringTools.endsWith(name, ".Presence") || StringTools.endsWith(name, "Web.Presence");
    }

    static function isPresenceEffectCall(e: ElixirAST): Bool {
        return switch (e.def) {
            case ERemoteCall({def: EVar(mod)}, func, _):
                var isPresence = (mod == "Phoenix.Presence") || StringTools.endsWith(mod, ".Presence") || (mod == "Presence");
                isPresence && (func == "track" || func == "update" || func == "untrack");
            default:
                false;
        };
    }

    static function nameUsedLater(stmts:Array<ElixirAST>, start:Int, name:String):Bool {
        for (k in start...stmts.length) if (statementUsesName(stmts[k], name)) return true;
        return false;
    }

    static function statementUsesName(s: ElixirAST, name: String): Bool {
        var found = false;
        function visit(e: ElixirAST): Void {
            if (found || e == null || e.def == null) return;
            switch (e.def) {
                case EVar(n) if (n == name): found = true;
                case EBlock(ss): for (x in ss) visit(x);
                case EIf(c,t,el): visit(c); visit(t); if (el != null) visit(el);
                case ECase(expr, cs): visit(expr); for (c in cs) { if (c.guard != null) visit(c.guard); visit(c.body);} 
                // Do not treat assignment/match LHS as a "use" of the variable
                case EBinary(Match, _l, r): visit(r);
                case EBinary(_, l, r): visit(l); visit(r);
                case EMatch(_pat, rhs): visit(rhs);
                case ECall(tgt, _, args): if (tgt != null) visit(tgt); for (a in args) visit(a);
                case ERemoteCall(tgt2, _, args2): visit(tgt2); for (a in args2) visit(a);
                case EList(els): for (el in els) visit(el);
                case ETuple(els): for (el in els) visit(el);
                case EMap(pairs): for (p in pairs) { visit(p.key); visit(p.value); }
                case EKeywordList(pairs): for (p in pairs) visit(p.value);
                case EStructUpdate(base, fields): visit(base); for (f in fields) visit(f.value);
                case EFn(clauses): for (cl in clauses) visit(cl.body);
                default:
            }
        }
        visit(s);
        return found;
    }
}

#end
