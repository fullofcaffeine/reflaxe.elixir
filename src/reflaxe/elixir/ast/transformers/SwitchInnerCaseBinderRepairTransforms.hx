package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTTransformer;
using StringTools;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;

/**
 * SwitchInnerCaseBinderRepairTransforms
 *
 * WHAT
 * - Repairs a hazardous shape produced by lowering where the result variable
 *   of a `case` is referenced inside the very `case` body before it is bound.
 *   Typical broken shape:
 *
 *     g = case parse(msg) do
 *       {:some, _tmp} ->
 *         case g do ... end   # g is not yet bound here ⇒ undefined
 *       :none -> ...
 *     end
 *
 * - Rewrites the inner `case g do` to use the binder introduced by the match
 *   pattern (`_tmp` above): `case _tmp do ... end`.
 *
 * WHY
 * - Ensures lexical correctness and eliminates undefined-variable errors
 *   without relying on application names or ad-hoc heuristics.
 *
 * HOW
 * - Looks for assignment `lhs = ECase(target, clauses)` where any clause has a
 *   pattern `{ :some, PVar(binder) }` (or PTuple with first element :some).
 * - If that clause body contains an immediate `ECase(EVar(lhs), ...)`, rewrite
 *   its scrutinee to `EVar(binder)`.
 * - Handles bodies wrapped in simple EBlock[…, ECase(..)] as well.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class SwitchInnerCaseBinderRepairTransforms {
    public static function repairPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EBinary(Match, left, rhs):
                    var fixed = tryRepairBinary(left, rhs);
                    if (fixed != null) {
                        fixed;
                    } else n;
                case EMatch(pat, rhs2):
                    var fixed2 = tryRepairMatch(pat, rhs2);
                    if (fixed2 != null) {
                        fixed2;
                    } else n;
                case ECase(target, clauses):
                    // Best-effort: for each clause that binds a variable in a tagged tuple,
                    // rewrite any inner `case <infraTemp>` to use that binder.
                    var newClauses = new Array<{ pattern:EPattern, guard:Null<ElixirAST>, body:ElixirAST }>();
                    var changed = false;
                    for (cl in clauses) {
                        var binder = extractSomeBinder(cl.pattern);
                        if (binder != null) {
                            var newBody = rewriteInfraScrutinee(cl.body, binder);
                            // Also rewrite stray references to infra temp vars in the clause body to binder
                            newBody = rewriteInfraVarRefs(newBody, binder);
                            if (newBody != cl.body) changed = true;
                            newClauses.push({ pattern: cl.pattern, guard: cl.guard, body: newBody });
                        } else {
                            newClauses.push(cl);
                        }
                    }
                    if (changed) {
                        makeASTWithMeta(ECase(target, newClauses), n.metadata, n.pos);
                    } else n;
                default:
                    n;
            }
        });
    }

    static function tryRepairBinary(lhs: ElixirAST, rhs: ElixirAST): Null<ElixirAST> {
        // LHS must be a variable name to compare with inner scrutinee
        var lhsName: Null<String> = switch (lhs.def) {
            case EVar(nm): nm;
            case EBinary(Match, l2, _):
                // Nested chain: a = b = case ... ; operate on the innermost var
                switch (l2.def) { case EVar(nm): nm; default: null; }
            default: null;
        };
        if (lhsName == null) return null;

        // RHS must be a case expression
        return switch (rhs.def) {
            case ECase(target, clauses):
                var newClauses = new Array<{ pattern:EPattern, guard:Null<ElixirAST>, body:ElixirAST }>();
                var changed = false;
                for (cl in clauses) {
                    var binder: Null<String> = extractSomeBinder(cl.pattern);
                    if (binder != null) {
                        var newBody = rewriteInnerCaseScrutinee(cl.body, lhsName, binder, changed);
                        if (newBody != cl.body) changed = true;
                        newClauses.push({ pattern: cl.pattern, guard: cl.guard, body: newBody });
                    } else {
                        newClauses.push(cl);
                    }
                }
                if (!changed) return null;
                #if debug_switch_binder_repair
                #end
                makeASTWithMeta(EBinary(Match, lhs, { def: ECase(target, newClauses), metadata: rhs.metadata, pos: rhs.pos }),
                    { }, // keep outer metadata minimal; parent retains it
                    null);
            default:
                null;
        }
    }

    static function tryRepairMatch(pat: EPattern, rhs: ElixirAST): Null<ElixirAST> {
        // Extract lhs variable name from simple PVar pattern
        var lhsName: Null<String> = switch (pat) { case PVar(nm): nm; default: null; };
        if (lhsName == null) return null;
        return switch (rhs.def) {
            case ECase(target, clauses):
                var newClauses = new Array<{ pattern:EPattern, guard:Null<ElixirAST>, body:ElixirAST }>();
                var changed = false;
                for (cl in clauses) {
                    var binder: Null<String> = extractSomeBinder(cl.pattern);
                    if (binder != null) {
                        var newBody = rewriteInnerCaseScrutinee(cl.body, lhsName, binder, changed);
                        if (newBody != cl.body) changed = true;
                        newClauses.push({ pattern: cl.pattern, guard: cl.guard, body: newBody });
                    } else {
                        newClauses.push(cl);
                    }
                }
                if (!changed) return null;
                #if debug_switch_binder_repair
                #end
                makeASTWithMeta(EMatch(pat, { def: ECase(target, newClauses), metadata: rhs.metadata, pos: rhs.pos }), { }, null);
            default:
                null;
        }
    }

    static function extractSomeBinder(p: EPattern): Null<String> {
        // Prefer {:some, PVar(binder)}; fallback to first variable anywhere in the pattern
        switch (p) {
            case PTuple(es) if (es.length >= 2):
                var name: Null<String> = null;
                switch (es[0]) {
                    case PLiteral(ast):
                        switch (ast.def) { case EAtom(nm) if (nm == "some"): name = extractVar(es[1]); default: }
                    default:
                }
                if (name != null) return name;
            default:
        }
        var found: Null<String> = null;
        function walk(pt:EPattern):Void {
            if (found != null || pt == null) return;
            switch (pt) {
                case PVar(nm): found = nm;
                case PPin(inner): walk(inner);
                case PAlias(nm, inner): if (found == null) found = nm; if (found == null) walk(inner);
                case PTuple(es): for (e in es) walk(e);
                case PList(es): for (e in es) walk(e);
                case PCons(h, t): walk(h); walk(t);
                case PMap(kvs): for (kv in kvs) walk(kv.value);
                case PStruct(_, fs): for (f in fs) walk(f.value);
                default:
            }
        }
        walk(p);
        return found;
    }

    static inline function extractVar(p:EPattern):Null<String> {
        return switch (p) {
            case PVar(nm): nm;
            case PPin(inner): switch (inner) { case PVar(nm2): nm2; default: null; }
            case PAlias(nm3, _): nm3;
            default: null;
        }
    }

    static function rewriteInnerCaseScrutinee(body: ElixirAST, oldName: String, newName: String, changed: Bool): ElixirAST {
        // Recursively rewrite any ECase whose scrutinee is the outer result var.
        function rw(n: ElixirAST): ElixirAST {
            if (n == null || n.def == null) return n;
            return switch (n.def) {
                case ECase(scr, cls):
                    var ns = (isVar(scr, oldName) || isInfraTempVar(scr)) ? v(newName) : rw(scr);
                    var ncls = [];
                    for (c in cls) ncls.push({ pattern: c.pattern, guard: c.guard == null ? null : rw(c.guard), body: rw(c.body) });
                    makeASTWithMeta(ECase(ns, ncls), n.metadata, n.pos);
                case EBlock(ss):
                    var out = [];
                    for (s in ss) out.push(rw(s));
                    makeASTWithMeta(EBlock(out), n.metadata, n.pos);
                case EDo(ss2):
                    var out2 = [];
                    for (s in ss2) out2.push(rw(s));
                    makeASTWithMeta(EDo(out2), n.metadata, n.pos);
                case EIf(c,t,e):
                    makeASTWithMeta(EIf(rw(c), rw(t), e == null ? null : rw(e)), n.metadata, n.pos);
                case EMatch(p, r):
                    makeASTWithMeta(EMatch(p, rw(r)), n.metadata, n.pos);
                case EBinary(op, l, r):
                    makeASTWithMeta(EBinary(op, rw(l), rw(r)), n.metadata, n.pos);
                case ECall(tgt, fnm, args):
                    var nt = tgt == null ? null : rw(tgt);
                    var nargs = [for (a in args) rw(a)];
                    makeASTWithMeta(ECall(nt, fnm, nargs), n.metadata, n.pos);
                case ERemoteCall(tgt2, fnm2, args2):
                    var nt2 = rw(tgt2);
                    var nargs2 = [for (a in args2) rw(a)];
                    makeASTWithMeta(ERemoteCall(nt2, fnm2, nargs2), n.metadata, n.pos);
                default:
                    n;
            }
        }
        return rw(body);
    }

    // Variant: rewrite any inner case whose scrutinee is an infrastructure temp (g/_g/gN)
    static function rewriteInfraScrutinee(body: ElixirAST, newName: String): ElixirAST {
        function rw(n: ElixirAST): ElixirAST {
            if (n == null || n.def == null) return n;
            return switch (n.def) {
                case ECase(scr, cls):
                    var ns = isInfraTempVar(scr) ? v(newName) : rw(scr);
                    var ncls = [];
                    for (c in cls) ncls.push({ pattern: c.pattern, guard: c.guard == null ? null : rw(c.guard), body: rw(c.body) });
                    makeASTWithMeta(ECase(ns, ncls), n.metadata, n.pos);
                case EBlock(ss):
                    var out = [];
                    for (s in ss) out.push(rw(s));
                    makeASTWithMeta(EBlock(out), n.metadata, n.pos);
                case EDo(ss2):
                    var out2 = [];
                    for (s in ss2) out2.push(rw(s));
                    makeASTWithMeta(EDo(out2), n.metadata, n.pos);
                case EIf(c,t,e):
                    makeASTWithMeta(EIf(rw(c), rw(t), e == null ? null : rw(e)), n.metadata, n.pos);
                case EMatch(p, r):
                    makeASTWithMeta(EMatch(p, rw(r)), n.metadata, n.pos);
                case EBinary(op, l, r):
                    makeASTWithMeta(EBinary(op, rw(l), rw(r)), n.metadata, n.pos);
                case ECall(tgt, fnm, args):
                    var nt = tgt == null ? null : rw(tgt);
                    var nargs = [for (a in args) rw(a)];
                    makeASTWithMeta(ECall(nt, fnm, nargs), n.metadata, n.pos);
                case ERemoteCall(tgt2, fnm2, args2):
                    var nt2 = rw(tgt2);
                    var nargs2 = [for (a in args2) rw(a)];
                    makeASTWithMeta(ERemoteCall(nt2, fnm2, nargs2), n.metadata, n.pos);
                default:
                    n;
            }
        }
        return rw(body);
    }

    // Replace plain references to infra temp vars (g/_g/gN) with the provided binder
    static function rewriteInfraVarRefs(body: ElixirAST, newName: String): ElixirAST {
        return ElixirASTTransformer.transformNode(body, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EVar(v):
                    var isInfra = false;
                    if (v == "g" || v == "_g") isInfra = true;
                    else if (v != null && v.length > 1 && StringTools.startsWith(v, "g") && isDigits(v.substr(1))) isInfra = true;
                    else if (v != null && v.length > 2 && StringTools.startsWith(v, "_g") && isDigits(v.substr(2))) isInfra = true;
                    if (isInfra) makeASTWithMeta(EVar(newName), n.metadata, n.pos) else n;
                default:
                    n;
            }
        });
    }

    static function isDigits(s:String):Bool {
        for (i in 0...s.length) {
            var c = s.charCodeAt(i);
            if (c < '0'.code || c > '9'.code) return false;
        }
        return true;
    }

    static function isVar(e: ElixirAST, name: String): Bool {
        return e != null && switch (e.def) { case EVar(nm): nm == name; default: false; };
    }
    // Detect infrastructure temp variables like g, _g, g1, g2
    static function isInfraTempVar(e: ElixirAST): Bool {
        return e != null && switch (e.def) {
            case EVar(nm):
                if (nm == null || nm.length == 0) false else {
                    var name = nm.charAt(0) == "_" ? nm.substr(1) : nm;
                    if (name == "g") true else if (name.charAt(0) == "g") {
                        // ensure all remaining chars are digits
                        var ok = true;
                        for (i in 1...name.length) {
                            var c = name.charCodeAt(i);
                            if (c < '0'.code || c > '9'.code) { ok = false; break; }
                        }
                        ok;
                    } else false;
                }
            default: false;
        };
    }
    static inline function v(nm: String): ElixirAST {
        return { def: EVar(nm), metadata: {}, pos: null };
    }
}

#end
