package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.VarUseAnalyzer;

/**
 * LateEnsureCsBinderTransforms
 *
 * WHAT
 * - Late pass to ensure a `cs` binder exists when the function body references `cs`
 *   in Ecto.Changeset.validate_* calls but no prior `cs = ...` assignment exists.
 *
 * WHY
 * - Earlier hygiene or chain rewrites may leave the initial changeset-producing
 *   expression bound to wildcards (e.g., `_ = _ = ... = expr`) while validation
 *   calls target the canonical `cs` variable. This yields undefined-variable errors.
 *
 * HOW
 * - For EDef/EDefp bodies:
 *   1) Detect if `cs` is referenced anywhere but never declared (lhs match or pattern).
 *   2) Find the earliest statement that produces a changeset:
 *      - match with wildcard LHS and RHS contains Ecto.Changeset.cast/change
 *      - raw expression containing Ecto.Changeset.cast/change
 *      - direct remote call Ecto.Changeset.cast/change
 *   3) Rewrite that statement to `cs = <expr>` and keep subsequent statements unchanged.
 * - Purely shape/API-based; avoids app-specific names.
 */
class LateEnsureCsBinderTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, params, guards, body):
                    makeASTWithMeta(EDef(name, params, guards, ensureBinder(body)), n.metadata, n.pos);
                case EDefp(name, params, guards, body):
                    makeASTWithMeta(EDefp(name, params, guards, ensureBinder(body)), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function ensureBinder(body: ElixirAST): ElixirAST {
        // Fast bail-out when cs is not referenced
        inline function bodyContainsValidateCalls(b: ElixirAST): Bool {
            var found = false;
            function scan(n: ElixirAST): Void {
                if (found || n == null || n.def == null) return;
                switch (n.def) {
                    case ERemoteCall(mod, fn, _):
                        switch (mod.def) { case EVar(m) if (m == "Ecto.Changeset" && (StringTools.startsWith(fn, "validate_"))): found = true; default: }
                    case ERaw(code): if (code != null && code.indexOf("Ecto.Changeset.validate_") != -1) found = true;
                    case EBlock(ss): for (s in ss) scan(s);
                    case EDo(ss2): for (s in ss2) scan(s);
                    case EIf(c,t,e): scan(c); scan(t); if (e != null) scan(e);
                    case ECase(expr, cs): scan(expr); for (c in cs) { if (c.guard != null) scan(c.guard); scan(c.body); }
                    case ECall(t,_,as): if (t != null) scan(t); if (as != null) for (a in as) scan(a);
                    case ERemoteCall(t2,_,as2): scan(t2); if (as2 != null) for (a in as2) scan(a);
                    case EBinary(_, l, r): scan(l); scan(r);
                    case EMatch(_, rhs): scan(rhs);
                    case EFn(clauses): for (cl in clauses) scan(cl.body);
                    default:
                }
            }
            scan(b);
            return found;
        }
        var uses = bodyContainsValidateCalls(body);
        if (!uses) return body;

        // Already declared?
        var declares = bodyDeclaresVar(body, "cs");
        if (declares) return body;

        // Rewrite earliest candidate statement to cs = <expr>
        function ensureTrailingCsBlock(stmts: Array<ElixirAST>): Array<ElixirAST> {
            if (stmts == null || stmts.length == 0) return stmts;
            var last = stmts[stmts.length - 1];
            var endsWithCs = switch (last.def) { case EVar(v) if (v == "cs"): true; default: false; };
            return endsWithCs ? stmts : stmts.concat([ makeAST(EVar("cs")) ]);
        }
        return switch (body.def) {
            case EBlock(stmts):
                var out:Array<ElixirAST> = [];
                var bound = false;
                for (i in 0...stmts.length) {
                    var s = stmts[i];
                    if (!bound) {
                        var rhs = rhsIfChangesetProducer(s);
                        if (rhs != null) {
                            out.push(makeASTWithMeta(EBinary(Match, makeAST(EVar("cs")), rhs), s.metadata, s.pos));
                            bound = true;
                            continue; // skip original s
                        }
                    }
                    out.push(s);
                }
                if (!bound && stmts.length > 0) {
                    var s0 = stmts[0];
                    var rhs0: ElixirAST = switch (s0.def) {
                        case EBinary(Match, _, r): r;
                        case EMatch(_, r2): r2;
                        default: s0;
                    };
                    var newStmts = [ makeASTWithMeta(EBinary(Match, makeAST(EVar("cs")), rhs0), s0.metadata, s0.pos) ];
                    for (i in 1...stmts.length) newStmts.push(stmts[i]);
                    // Always end with `cs`
                    var ensured = ensureTrailingCsBlock(newStmts);
                    makeASTWithMeta(EBlock(ensured), body.metadata, body.pos);
                } else {
                    var ensured2 = ensureTrailingCsBlock(out);
                    makeASTWithMeta(EBlock(ensured2), body.metadata, body.pos);
                }
            case EDo(stmts2):
                var blk = makeAST(EBlock(stmts2));
                var res = ensureBinder(blk);
                switch (res.def) {
                    case EBlock(os): makeASTWithMeta(EDo(os), body.metadata, body.pos);
                    default: res;
                }
            default:
                body;
        }
    }

    static function bodyDeclaresVar(b: ElixirAST, name: String): Bool {
        var found = false;
        function walk(n: ElixirAST): Void {
            if (found || n == null || n.def == null) return;
            switch (n.def) {
                case EMatch(p, _): if (patternDeclares(p, name)) { found = true; return; }
                case EBinary(Match, lhs, _): if (lhsDeclares(lhs, name)) { found = true; return; }
                case EBlock(ss): for (s in ss) walk(s);
                case EIf(c,t,e): walk(c); walk(t); if (e != null) walk(e);
                case ECase(expr, cs): walk(expr); for (c in cs) walk(c.body);
                case EFn(clauses): for (cl in clauses) for (a in cl.args) if (patternDeclares(a, name)) { found = true; return; };
                default:
            }
        }
        walk(b);
        return found;
    }

    static function patternDeclares(p: EPattern, name: String): Bool {
        return switch (p) {
            case PVar(n) if (n == name): true;
            case PTuple(es): for (e in es) if (patternDeclares(e, name)) return true; false;
            case PList(es): for (e in es) if (patternDeclares(e, name)) return true; false;
            case PCons(h, t): patternDeclares(h, name) || patternDeclares(t, name);
            case PMap(kvs): for (kv in kvs) if (patternDeclares(kv.value, name)) return true; false;
            case PStruct(_, fs): for (f in fs) if (patternDeclares(f.value, name)) return true; false;
            case PPin(inner): patternDeclares(inner, name);
            default: false;
        }
    }

    static function lhsDeclares(lhs: ElixirAST, name: String): Bool {
        return switch (lhs.def) {
            case EVar(v) if (v == name): true;
            case EBinary(Match, l2, r2): lhsDeclares(l2, name) || lhsDeclares(r2, name);
            default: false;
        }
    }

    static function rhsIfChangesetProducer(s: ElixirAST): Null<ElixirAST> {
        function containsChangesetProducer(e: ElixirAST): Bool {
            return switch (e.def) {
                case ERemoteCall(mod, fn, _):
                    switch (mod.def) {
                        case EVar(m) if (m == "Ecto.Changeset"):
                            return fn == "cast" || fn == "change";
                        default:
                    }
                    false;
                case ERaw(code): code != null && (code.indexOf("Ecto.Changeset.cast(") != -1 || code.indexOf("Ecto.Changeset.change(") != -1);
                case EMatch(_, inner): containsChangesetProducer(inner);
                case EBinary(Match, _, inner2): containsChangesetProducer(inner2);
                case EParen(inner3): containsChangesetProducer(inner3);
                default: false;
            }
        }
        switch (s.def) {
            case EBinary(Match, _, rhs) if (containsChangesetProducer(rhs)):
                return peel(rhs);
            case EMatch(_, rhs2) if (containsChangesetProducer(rhs2)):
                return rhs2;
            case ERaw(code) if (code != null && (code.indexOf("Ecto.Changeset.cast(") != -1 || code.indexOf("Ecto.Changeset.change(") != -1)):
                return s;
            case ERemoteCall(mod, fn, _) if (containsChangesetProducer(s)):
                return s;
            default:
                return null;
        }
    }

    static function peel(n: ElixirAST): ElixirAST {
        var cur = n;
        while (cur != null && cur.def != null) {
            switch (cur.def) {
                case EBinary(Match, _, inner): cur = inner;
                case EMatch(_, inner2): cur = inner2;
                case EParen(inner3): cur = inner3;
                default: return cur;
            }
        }
        return cur == null ? n : cur;
    }
}

#end
