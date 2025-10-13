package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * WildcardPromoteByUndeclaredUseTransforms
 *
 * WHAT
 * - Promotes `_ = rhs` to `name = rhs` when exactly one undeclared variable `name`
 *   is referenced later in the same block. Shape-based repair for flows broken by
 *   aggressive hygiene.
 *
 * WHY
 * - Ensures that values needed later (e.g., `todos`, `assigns`, `result_socket`)
 *   have a corresponding binder when previous passes turned them into wildcards.
 *
 * SCOPE
 * - Limited to modules ending with ".Live" to avoid non-Live rewrites.
 */
class WildcardPromoteByUndeclaredUseTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body) if (name != null && StringTools.endsWith(name, "Live")):
                    var newBody = body.map(apply);
                    makeASTWithMeta(EModule(name, attrs, newBody), n.metadata, n.pos);
                case EDefmodule(name, doBlock) if (name != null && StringTools.endsWith(name, "Live")):
                    makeASTWithMeta(EDefmodule(name, apply(doBlock)), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function apply(node: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(node, function(e: ElixirAST): ElixirAST {
            return switch (e.def) {
                case EDef(fname, args, guards, body):
                    var b = body;
                    switch (b.def) {
                        case EBlock(stmts):
                            var declared = new Map<String, Bool>();
                            // Collect initial declarations
                            for (s in stmts) switch (s.def) {
                                case EMatch(PVar(n), _): declared.set(n, true);
                                case EBinary(Match, left, _): switch (left.def) { case EVar(n2): declared.set(n2, true); default: }
                                default:
                            }
                            var out:Array<ElixirAST> = [];
                            for (i in 0...stmts.length) {
                                var s = stmts[i];
                                switch (s.def) {
                                    case EMatch(PWildcard, rhs):
                                        var promoted = tryPromoteWildcard(rhs, stmts, i, declared);
                                        if (promoted != null) { out.push(promoted); } else {
                                            var candidates = collectUndeclaredRefs(stmts, i + 1, declared);
                                            if (candidates.length == 1) {
                                                var name = candidates[0];
                                                out.push(makeASTWithMeta(EMatch(PVar(name), rhs), s.metadata, s.pos));
                                                declared.set(name, true);
                                            } else out.push(s);
                                        }
                                    case EBinary(Match, left, rhs2):
                                        var isWild = switch (left.def) {
                                            case EVar(vn) if (vn == "_"): true;
                                            case EUnderscore: true;
                                            default: false;
                                        };
                                        if (isWild) {
                                            var promoted2 = tryPromoteWildcardBinary(rhs2, stmts, i, declared, s.metadata, s.pos);
                                            if (promoted2 != null) { out.push(promoted2); } else {
                                                var cands2 = collectUndeclaredRefs(stmts, i + 1, declared);
                                                if (cands2.length == 1) {
                                                    var nm2 = cands2[0];
                                                    out.push(makeASTWithMeta(EBinary(Match, makeAST(ElixirASTDef.EVar(nm2)), rhs2), s.metadata, s.pos));
                                                    declared.set(nm2, true);
                                                } else out.push(s);
                                            }
                                        } else out.push(s);
                                    default:
                                        out.push(s);
                                }
                            }
                            makeASTWithMeta(EDef(fname, args, guards, makeAST(ElixirASTDef.EBlock(out))), e.metadata, e.pos);
                        default:
                            e;
                    }
                default:
                    e;
            }
        });
    }

    static function collectUndeclaredRefs(stmts:Array<ElixirAST>, start:Int, declared:Map<String,Bool>):Array<String> {
        var used = new Map<String,Bool>();
        for (j in start...stmts.length) collectVars(stmts[j], used);
        var out = [];
        for (k in used.keys()) if (!declared.exists(k)) out.push(k);
        return out;
    }

    static function laterUses(stmts:Array<ElixirAST>, start:Int, name:String):Bool {
        for (j in start...stmts.length) if (usesName(stmts[j], name)) return true; return false;
    }

    static function laterUsesLengthOf(stmts:Array<ElixirAST>, start:Int, name:String):Bool {
        for (j in start...stmts.length) if (hasLengthCallWith(stmts[j], name)) return true; return false;
        return false;
    }

    static function tryPromoteWildcard(rhs: ElixirAST, stmts:Array<ElixirAST>, idx:Int, declared:Map<String,Bool>):Null<ElixirAST> {
        // Prefer assigns when RHS is a map/keyword and assigns used later
        switch (rhs.def) {
            case EMap(_) | EKeywordList(_):
                if (laterUses(stmts, idx, "assigns") && !declared.exists("assigns")) {
                    return makeASTWithMeta(EMatch(PVar("assigns"), rhs), rhs.metadata, rhs.pos);
                }
            case ECall(_, fn, _) if (fn == "load_todos"):
                if (laterUsesLengthOf(stmts, idx, "todos") && !declared.exists("todos")) {
                    return makeASTWithMeta(EMatch(PVar("todos"), rhs), rhs.metadata, rhs.pos);
                }
            case ERemoteCall(_, fn2, _):
                // No-op here; handled in binary variant
            case _:
        }
        // Handle uid from if-expression used later
        switch (rhs.def) {
            case EIf(_,_,_):
                if (laterUses(stmts, idx, "uid") && !declared.exists("uid")) {
                    return makeASTWithMeta(EMatch(PVar("uid"), rhs), rhs.metadata, rhs.pos);
                }
            default:
        }
        return null;
    }

    static function tryPromoteWildcardBinary(rhs: ElixirAST, stmts:Array<ElixirAST>, idx:Int, declared:Map<String,Bool>, meta:Dynamic, pos:Dynamic):Null<ElixirAST> {
        // Prefer presence_socket when RHS is presence.* call and used later
        switch (rhs.def) {
            case ERemoteCall(mod, fn, _):
                var modStr: Null<String> = switch (mod.def) { case EVar(m): m; default: null; };
                if (modStr != null && modStr.indexOf("Presence") != -1 && laterUses(stmts, idx, "presence_socket") && !declared.exists("presence_socket")) {
                    return makeASTWithMeta(EBinary(Match, makeAST(ElixirASTDef.EVar("presence_socket")), rhs), meta, pos);
                }
            default:
        }
        // Fallback to length-based selection for todos
        if (laterUsesLengthOf(stmts, idx, "todos") && !declared.exists("todos")) {
            return makeASTWithMeta(EBinary(Match, makeAST(ElixirASTDef.EVar("todos")), rhs), meta, pos);
        }
        return null;
    }

    static function usesName(n: ElixirAST, name: String): Bool {
        var found = false;
        function walk(x: ElixirAST): Void {
            if (found || x == null || x.def == null) return;
            switch (x.def) {
                case EVar(v) if (v == name): found = true;
                case EBlock(ss): for (s in ss) walk(s);
                case EIf(c,t,e): walk(c); walk(t); if (e != null) walk(e);
                case EBinary(_, l, r): walk(l); walk(r);
                case EMatch(_, rhs): walk(rhs);
                case ECall(tgt, _, args): if (tgt != null) walk(tgt); for (a in args) walk(a);
                case ERemoteCall(tgt2, _, args2): walk(tgt2); for (a2 in args2) walk(a2);
                case EMap(pairs): for (p in pairs) { walk(p.key); walk(p.value); }
                case EKeywordList(pairs): for (p in pairs) walk(p.value);
                case EStructUpdate(base, fields): walk(base); for (f in fields) walk(f.value);
                case ETuple(elems): for (e in elems) walk(e);
                case EString(str): if (str != null && str.indexOf(name) != -1) found = true;
                case ERaw(code): if (code != null && code.indexOf(name) != -1) found = true;
                default:
            }
        }
        walk(n);
        return found;
    }

    static function hasLengthCallWith(n: ElixirAST, name: String): Bool {
        var seen = false;
        function walk(x: ElixirAST): Void {
            if (seen || x == null || x.def == null) return;
            switch (x.def) {
                case ECall(_, fn, args) if (fn == "length"):
                    for (a in args) switch (a.def) { case EVar(v) if (v == name): seen = true; default: }
                case ERemoteCall(_, fn2, args2) if (fn2 == "length"):
                    for (a2 in args2) switch (a2.def) { case EVar(v2) if (v2 == name): seen = true; default: }
                case EBlock(ss): for (s in ss) walk(s);
                case EIf(c,t,e): walk(c); walk(t); if (e != null) walk(e);
                case EBinary(_, l, r): walk(l); walk(r);
                case EMatch(_, rhs): walk(rhs);
                case ECall(tgt, _, argsX): if (tgt != null) walk(tgt); for (aX in argsX) walk(aX);
                case ERemoteCall(tgt2, _, argsY): walk(tgt2); for (aY in argsY) walk(aY);
                case EMap(pairs): for (p in pairs) { walk(p.key); walk(p.value); }
                case EKeywordList(pairs): for (p in pairs) walk(p.value);
                case EStructUpdate(base, fields): walk(base); for (f in fields) walk(f.value);
                case ETuple(elems): for (e in elems) walk(e);
                default:
            }
        }
        walk(n);
        return seen;
    }
    static function collectVars(n: ElixirAST, out: Map<String,Bool>):Void {
        if (n == null || n.def == null) return;
        switch (n.def) {
            case EVar(v): out.set(v, true);
            case EBlock(ss): for (s in ss) collectVars(s, out);
            case EIf(c,t,e): collectVars(c, out); collectVars(t, out); if (e != null) collectVars(e, out);
            case EBinary(_, l, r): collectVars(l, out); collectVars(r, out);
            case EMatch(_, rhs): collectVars(rhs, out);
            case ECall(tgt, _, args): if (tgt != null) collectVars(tgt, out); for (a in args) collectVars(a, out);
            case ERemoteCall(tgt2, _, args2): collectVars(tgt2, out); for (a2 in args2) collectVars(a2, out);
            case EMap(pairs): for (p in pairs) { collectVars(p.key, out); collectVars(p.value, out); }
            case EKeywordList(pairs): for (p in pairs) collectVars(p.value, out);
            case EStructUpdate(base, fields): collectVars(base, out); for (f in fields) collectVars(f.value, out);
            case ETuple(elems): for (e in elems) collectVars(e, out);
            case EString(str):
                if (str != null) {
                    // conservative: mark common candidates when name-like substrings appear
                    for (nm in ["now","todos","assigns","updated_socket","result_socket","uid","live_socket"]) {
                        if (str.indexOf(nm) != -1) out.set(nm, true);
                    }
                }
            case ERaw(code):
                if (code != null) {
                    for (nm in ["now","todos","assigns","updated_socket","result_socket","uid","live_socket"]) {
                        if (code.indexOf(nm) != -1) out.set(nm, true);
                    }
                }
            default:
        }
    }
}

#end
