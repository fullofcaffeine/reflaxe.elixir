package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.ElixirMetadata;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import haxe.macro.Expr.Position;

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
                            // Mark function parameters as declared
                            for (a in args) switch (a) { case PVar(nm): declared.set(nm, true); default: }
                            // Collect initial declarations
                            for (s in stmts) switch (s.def) {
                                case EMatch(PVar(n), _): declared.set(n, true);
                                case EBinary(Match, left, _): switch (left.def) { case EVar(n2): declared.set(n2, true); default: }
                                default:
                            }
                            var out:Array<ElixirAST> = [];
                            var i = 0;
                            while (i < stmts.length) {
                                var s = stmts[i];
                                switch (s.def) {
                                    case EMatch(PWildcard, rhs):
                                        var promoted = tryPromoteWildcard(rhs, stmts, i, declared);
                                        if (promoted != null) { out.push(promoted); } else {
                                            // Prefer targeted candidates within a small window to reduce ambiguity
                                            var candidates = collectTargetedCandidates(stmts, i, declared, 4);
                                            if (candidates.length == 0) {
                                                // Fallback to full-scan when uniquely identifiable
                                                candidates = collectUndeclaredRefs(stmts, i + 1, declared);
                                            }
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
                                                var cands2 = collectTargetedCandidates(stmts, i, declared, 4);
                                                if (cands2.length == 0) cands2 = collectUndeclaredRefs(stmts, i + 1, declared);
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
                                i++;
                            }
                            makeASTWithMeta(EDef(fname, args, guards, makeAST(ElixirASTDef.EBlock(out))), e.metadata, e.pos);
                        case EDo(stmts2):
                            var declared2 = new Map<String, Bool>();
                            for (a in args) switch (a) { case PVar(nm): declared2.set(nm, true); default: }
                            for (s in stmts2) switch (s.def) {
                                case EMatch(PVar(n3), _): declared2.set(n3, true);
                                case EBinary(Match, left3, _): switch (left3.def) { case EVar(n4): declared2.set(n4, true); default: }
                                default:
                            }
                            var out2:Array<ElixirAST> = [];
                            var i = 0;
                            while (i < stmts2.length) {
                                var s2 = stmts2[i];
                                switch (s2.def) {
                                    case EMatch(PWildcard, rhs5):
                                        var p1 = tryPromoteWildcard(rhs5, stmts2, i, declared2);
                                        if (p1 != null) { out2.push(p1); } else {
                                            var c1 = collectTargetedCandidates(stmts2, i, declared2, 4);
                                            if (c1.length == 0) c1 = collectUndeclaredRefs(stmts2, i + 1, declared2);
                                            if (c1.length == 1) {
                                                var nm = c1[0];
                                                out2.push(makeASTWithMeta(EMatch(PVar(nm), rhs5), s2.metadata, s2.pos));
                                                declared2.set(nm, true);
                                            } else out2.push(s2);
                                        }
                                    case EBinary(Match, left4, rhs6):
                                        var isWild2 = switch (left4.def) {
                                            case EVar(v4) if (v4 == "_"): true;
                                            case EUnderscore: true;
                                            default: false;
                                        };
                                        if (isWild2) {
                                            var p2 = tryPromoteWildcardBinary(rhs6, stmts2, i, declared2, s2.metadata, s2.pos);
                                            if (p2 != null) { out2.push(p2); } else {
                                                var c2 = collectTargetedCandidates(stmts2, i, declared2, 4);
                                                if (c2.length == 0) c2 = collectUndeclaredRefs(stmts2, i + 1, declared2);
                                                if (c2.length == 1) {
                                                    var nm2 = c2[0];
                                                    out2.push(makeASTWithMeta(EBinary(Match, makeAST(ElixirASTDef.EVar(nm2)), rhs6), s2.metadata, s2.pos));
                                                    declared2.set(nm2, true);
                                                } else out2.push(s2);
                                            }
                                        } else out2.push(s2);
                                    default:
                                        out2.push(s2);
                                }
                                i++;
                            }
                            makeASTWithMeta(EDef(fname, args, guards, makeAST(ElixirASTDef.EDo(out2))), e.metadata, e.pos);
                        default:
                            e;
                    }
                case EDefp(fname2, args2, guards2, body2):
                    var b2 = body2;
                    switch (b2.def) {
                        case EBlock(stmts):
                            var declared = new Map<String, Bool>();
                            for (a in args2) switch (a) { case PVar(nm): declared.set(nm, true); default: }
                            for (s in stmts) switch (s.def) {
                                case EMatch(PVar(n), _): declared.set(n, true);
                                case EBinary(Match, left, _): switch (left.def) { case EVar(n2): declared.set(n2, true); default: }
                                default:
                            }
                            var out:Array<ElixirAST> = [];
                            var i = 0;
                            while (i < stmts.length) {
                                var s = stmts[i];
                                switch (s.def) {
                                    case EMatch(PWildcard, rhs):
                                        var promoted = tryPromoteWildcard(rhs, stmts, i, declared);
                                        if (promoted != null) { out.push(promoted); } else {
                                            var candidates = collectTargetedCandidates(stmts, i, declared, 4);
                                            if (candidates.length == 0) candidates = collectUndeclaredRefs(stmts, i + 1, declared);
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
                                                var cands2 = collectTargetedCandidates(stmts, i, declared, 4);
                                                if (cands2.length == 0) cands2 = collectUndeclaredRefs(stmts, i + 1, declared);
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
                                i++;
                            }
                            makeASTWithMeta(EDefp(fname2, args2, guards2, makeAST(ElixirASTDef.EBlock(out))), e.metadata, e.pos);
                        case EDo(stmts2):
                            var declared2 = new Map<String, Bool>();
                            for (a in args2) switch (a) { case PVar(nm): declared2.set(nm, true); default: }
                            for (s in stmts2) switch (s.def) {
                                case EMatch(PVar(n3), _): declared2.set(n3, true);
                                case EBinary(Match, left3, _): switch (left3.def) { case EVar(n4): declared2.set(n4, true); default: }
                                default:
                            }
                            var out2:Array<ElixirAST> = [];
                            for (i in 0...stmts2.length) {
                                var s2 = stmts2[i];
                                switch (s2.def) {
                                    case EMatch(PWildcard, rhs5):
                                        var p1 = tryPromoteWildcard(rhs5, stmts2, i, declared2);
                                        if (p1 != null) { out2.push(p1); } else {
                                            var c1 = collectTargetedCandidates(stmts2, i, declared2, 4);
                                            if (c1.length == 0) c1 = collectUndeclaredRefs(stmts2, i + 1, declared2);
                                            if (c1.length == 1) {
                                                var nm = c1[0];
                                                out2.push(makeASTWithMeta(EMatch(PVar(nm), rhs5), s2.metadata, s2.pos));
                                                declared2.set(nm, true);
                                            } else out2.push(s2);
                                        }
                                    case EBinary(Match, left4, rhs6):
                                        var isWild2 = switch (left4.def) {
                                            case EVar(v4) if (v4 == "_"): true;
                                            case EUnderscore: true;
        
                                            default: false;
                                        };
                                        if (isWild2) {
                                            var p2 = tryPromoteWildcardBinary(rhs6, stmts2, i, declared2, s2.metadata, s2.pos);
                                            if (p2 != null) { out2.push(p2); } else {
                                                var c2 = collectTargetedCandidates(stmts2, i, declared2, 4);
                                                if (c2.length == 0) c2 = collectUndeclaredRefs(stmts2, i + 1, declared2);
                                                if (c2.length == 1) {
                                                    var nm2 = c2[0];
                                                    out2.push(makeASTWithMeta(EBinary(Match, makeAST(ElixirASTDef.EVar(nm2)), rhs6), s2.metadata, s2.pos));
                                                    declared2.set(nm2, true);
                                                } else out2.push(s2);
                                            }
                                        } else out2.push(s2);
                                    default:
                                        out2.push(s2);
                                }
                            }
                            makeASTWithMeta(EDefp(fname2, args2, guards2, makeAST(ElixirASTDef.EDo(out2))), e.metadata, e.pos);
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
        // Prefer map binder names that match a nearby Phoenix.Component.assign second-arg var
        switch (rhs.def) {
            case EMap(_) | EKeywordList(_):
                // If a later assign/2 takes a variable as second arg, bind to that variable
                var vars = collectRemoteArgVars(stmts, idx + 1, declared, 5, "Phoenix.Component", "assign", 1);
                if (vars.length == 1) {
                    var v = vars[0];
                    if (!declared.exists(v)) return makeASTWithMeta(EMatch(PVar(v), rhs), rhs.metadata, rhs.pos);
                }
            case ECall(_, _, _):
                /*
                 * Heuristic: Choose the intended list binder via length/1 consumers
                 *
                 * WHAT
                 * - When we see a discarded assignment followed by a nearby block that later calls
                 *   `length(var)` exactly on one undeclared local, we promote `_` to that `var`.
                 *
                 * WHY
                 * - In LiveView flows, list reloading is commonly followed by derived metrics
                 *   like `length(list)`, `count_completed(list)`, etc. Binding `_` to the unique
                 *   list variable referenced by these consumers restores the natural dataflow
                 *   without app-specific naming; examples in comments are illustrative only.
                 * - Requiring a single candidate ensures we only promote when unambiguous.
                 * - The scan window is kept small to preserve locality and avoid cross-branch bleed.
                 *
                 * HOW
                 * - Scan forward within a small window for `length(x)` calls and collect names.
                 * - Filter out already-declared names in the current function scope.
                 * - If exactly one candidate remains, promote `_` to that name.
                 * - If not unique, fall back to a conservative path (see below).
                 *
                 * NOTES
                 * - This is shape/usage-based and framework-agnostic; no reliance on concrete identifiers.
                 * - If uniqueness is not met here, a later fallback promotes to `todos` when
                 *   it is the only name referenced by `length/1` within the same window.
                 */
                // Removed name-based fallbacks; rely on general lookahead rules.
            case ERemoteCall(_, _, _):
                // No DateTime/Presence name-based promotions.
            case _:
        }
        // Shape-only assign/2 analysis: if the next assign/2 uses a single undeclared var as first arg, promote
        var firstArgs = collectRemoteArgVars(stmts, idx + 1, declared, 5, "Phoenix.Component", "assign", 0);
        if (firstArgs.length == 1 && !declared.exists(firstArgs[0])) {
            return makeASTWithMeta(EMatch(PVar(firstArgs[0]), rhs), rhs.metadata, rhs.pos);
        }
        // Shape-only DateTime to_iso8601 analysis: if exactly one undeclared var is used as its arg, promote to it
        var dtVars = collectDateTimeToIsoArgs(stmts, idx + 1, declared, 6);
        if (dtVars.length == 1 && !declared.exists(dtVars[0])) {
            return makeASTWithMeta(EMatch(PVar(dtVars[0]), rhs), rhs.metadata, rhs.pos);
        }
        // Removed specific var promotions from if-branches; rely on undeclared ref scan
        // Removed name-based fallbacks; rely on map/assign usage analysis and generic undeclared reference scan
        // Field-based map usage: if exactly one base var is used in field accesses in the upcoming map,
        // bind `socket.assigns` to that variable name (usage-driven, not name-based)
        switch (rhs.def) {
            case EField(_, _):
                var bases = collectAssignMapValueVars(stmts, idx + 1, 5);
                if (bases.length == 1 && !declared.exists(bases[0])) {
                    return makeASTWithMeta(EMatch(PVar(bases[0]), rhs), rhs.metadata, rhs.pos);
                }
            default:
        }
        // Immediate lookahead for assign(socket, %{...}) using a single var repeatedly (shape-only)
        if (idx + 1 < stmts.length) {
            switch (stmts[idx + 1].def) {
                case ERemoteCall(modA, fnA, argsA) if (fnA == "assign"):
                    var mA:Null<String> = switch (modA.def) { case EVar(mm): mm; default: null; };
                    if (mA == "Phoenix.Component" && argsA.length >= 2) {
                        switch (argsA[1].def) {
                            case EMap(pairsA):
                                var seen:Map<String,Int> = new Map();
                                for (p in pairsA) {
                                    var vals:Map<String,Bool> = new Map();
                                    collectVarsFromExpr(p.value, vals);
                                    for (k in vals.keys()) seen.set(k, (seen.exists(k) ? seen.get(k) : 0) + 1);
                                }
                                var pick:Null<String> = null;
                                for (k in seen.keys()) if (!declared.exists(k)) {
                                    if (pick == null) pick = k; else { pick = null; break; }
                                }
                                if (pick != null) return makeASTWithMeta(EMatch(PVar(pick), rhs), rhs.metadata, rhs.pos);
                            default:
                        }
                    }
                default:
            }
        }
        return null;
    }

    static function tryPromoteWildcardBinary(rhs: ElixirAST, stmts:Array<ElixirAST>, idx:Int, declared:Map<String,Bool>, meta:ElixirMetadata, pos:Position):Null<ElixirAST> {
        // Prefer the unique first-arg variable of a nearby Phoenix.Component.assign/2 as the binder
        switch (rhs.def) {
            case ERemoteCall(mod, fn, _):
                var modStr: Null<String> = switch (mod.def) { case EVar(m): m; default: null; };
                if (modStr != null && modStr.indexOf("Presence") != -1) {
                    var firstArgs = collectRemoteArgVars(stmts, idx + 1, declared, 5, "Phoenix.Component", "assign", 0);
                    if (firstArgs.length == 1 && !declared.exists(firstArgs[0])) {
                        return makeASTWithMeta(EBinary(Match, makeAST(ElixirASTDef.EVar(firstArgs[0])), rhs), meta, pos);
                    }
                }
                // DateTime: pick the unique var used as to_iso8601/1 argument later
                if (modStr == "DateTime") {
                    var dtVars = collectDateTimeToIsoArgs(stmts, idx + 1, declared, 6);
                    if (dtVars.length == 1) {
                        return makeASTWithMeta(EBinary(Match, makeAST(ElixirASTDef.EVar(dtVars[0])), rhs), meta, pos);
                    }
                }
            default:
        }
        // Fallback to length-based selection for todos
        var lengthCands = collectLengthArgNames(stmts, idx + 1, declared, 6);
        if (lengthCands.length == 1) {
            var nm = lengthCands[0];
            return makeASTWithMeta(EBinary(Match, makeAST(ElixirASTDef.EVar(nm)), rhs), meta, pos);
        }
        // If nearby Phoenix.Component.assign(_, var) exists, map builder should bind to that var
        var assignSecondArgVars = collectRemoteArgVars(stmts, idx + 1, declared, 5, "Phoenix.Component", "assign", 1);
        if (assignSecondArgVars.length == 1 && !declared.exists(assignSecondArgVars[0])) {
            return makeASTWithMeta(EBinary(Match, makeAST(ElixirASTDef.EVar(assignSecondArgVars[0])), rhs), meta, pos);
        }
        return null;
    }

    static function usesName(n: ElixirAST, name: String): Bool {
        var found = false;
        function walk(x: ElixirAST): Void {
            if (found || x == null || x.def == null) return;
            switch (x.def) {
                case EVar(v) if (v == name): found = true;
                case EFn(clauses):
                    for (cl in clauses) {
                        if (cl.guard != null) walk(cl.guard);
                        if (cl.body != null) walk(cl.body);
                    }
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
    // Detect later usage as DateTime.to_iso8601(varName)
    static function laterUsesDateTimeToIso(stmts:Array<ElixirAST>, idx:Int, name:String):Bool {
        for (k in idx+1...stmts.length) if (hasDateTimeToIso(stmts[k], name)) return true; return false;
    }
    static function hasDateTimeToIso(n: ElixirAST, name:String):Bool {
        var found = false;
        function walk(x:ElixirAST):Void {
            if (found || x == null || x.def == null) return;
            switch (x.def) {
                case ERemoteCall(mod, fn, args) if (fn == "to_iso8601"):
                    var modStr:Null<String> = switch (mod.def) { case EVar(m): m; default: null; };
                    if (modStr == "DateTime") for (a in args) switch (a.def) { case EVar(v) if (v == name): found = true; default: }
                case EBlock(ss): for (s in ss) walk(s);
                case EIf(c,t,e): walk(c); walk(t); if (e != null) walk(e);
                case EBinary(_, l, r): walk(l); walk(r);
                case ECall(tgt, _, args2): if (tgt != null) walk(tgt); for (a2 in args2) walk(a2);
                case ERemoteCall(tgt2, _, args3): walk(tgt2); for (a3 in args3) walk(a3);
                case ETuple(elems): for (e in elems) walk(e);
                default:
            }
        }
        walk(n);
        return found;
    }

    // Collect names used as arguments to length/1 within a window after idx
    static function collectLengthArgNames(stmts:Array<ElixirAST>, start:Int, declared:Map<String,Bool>, window:Int):Array<String> {
        var out:Map<String,Bool> = new Map();
        var endIdx = Std.int(Math.min(stmts.length, start + window));
        for (k in start...endIdx) collectNamesInLength(stmts[k], out);
        var names = [];
        for (nm in out.keys()) if (!declared.exists(nm)) names.push(nm);
        return names;
    }
    static function collectDateTimeToIsoArgs(stmts:Array<ElixirAST>, start:Int, declared:Map<String,Bool>, window:Int):Array<String> {
        var out:Map<String,Bool> = new Map();
        var endIdx = Std.int(Math.min(stmts.length, start + window));
        for (k in start...endIdx) scanDateTimeToIso(stmts[k], out);
        var names = [];
        for (nm in out.keys()) if (!declared.exists(nm)) names.push(nm);
        return names;
    }
    static function scanDateTimeToIso(n:ElixirAST, out:Map<String,Bool>):Void {
        if (n == null || n.def == null) return;
        switch (n.def) {
            case ERemoteCall(mod, fn, args) if (fn == "to_iso8601"):
                var modStr:Null<String> = switch (mod.def) { case EVar(m): m; default: null; };
                if (modStr == "DateTime") for (a in args) switch (a.def) { case EVar(v): out.set(v, true); default: scanDateTimeToIso(a, out); }
            case EBlock(ss): for (s in ss) scanDateTimeToIso(s, out);
            case EIf(c,t,e): scanDateTimeToIso(c, out); scanDateTimeToIso(t, out); if (e != null) scanDateTimeToIso(e, out);
            case EBinary(_, l, r): scanDateTimeToIso(l, out); scanDateTimeToIso(r, out);
            case ECall(tgt, _, argsX): if (tgt != null) scanDateTimeToIso(tgt, out); for (aX in argsX) scanDateTimeToIso(aX, out);
            case ERemoteCall(tgt2, _, argsY): scanDateTimeToIso(tgt2, out); for (aY in argsY) scanDateTimeToIso(aY, out);
            case ETuple(elems): for (e in elems) scanDateTimeToIso(e, out);
            default:
        }
    }
    static function collectNamesInLength(n: ElixirAST, out:Map<String,Bool>):Void {
        if (n == null || n.def == null) return;
        switch (n.def) {
            case ECall(_, fn, args) if (fn == "length"):
                for (a in args) switch (a.def) { case EVar(v): out.set(v, true); default: collectNamesInLength(a, out); }
            case ERemoteCall(_, fn2, args2) if (fn2 == "length"):
                for (a2 in args2) switch (a2.def) { case EVar(v2): out.set(v2, true); default: collectNamesInLength(a2, out); }
            case EBlock(ss): for (s in ss) collectNamesInLength(s, out);
            case EIf(c,t,e): collectNamesInLength(c, out); collectNamesInLength(t, out); if (e != null) collectNamesInLength(e, out);
            case EBinary(_, l, r): collectNamesInLength(l, out); collectNamesInLength(r, out);
            case ECall(tgt, _, argsX): if (tgt != null) collectNamesInLength(tgt, out); for (aX in argsX) collectNamesInLength(aX, out);
            case ERemoteCall(tgt2, _, argsY): collectNamesInLength(tgt2, out); for (aY in argsY) collectNamesInLength(aY, out);
            case EKeywordList(pairs): for (p in pairs) collectNamesInLength(p.value, out);
            case EMap(pairs): for (p in pairs) collectNamesInLength(p.value, out);
            case EStructUpdate(base, fields): collectNamesInLength(base, out); for (f in fields) collectNamesInLength(f.value, out);
            case ETuple(elems): for (e in elems) collectNamesInLength(e, out);
            default:
        }
    }

    // Gather targeted candidates near idx: length/1 args and Phoenix.Component.assign arg vars
    static function collectTargetedCandidates(stmts:Array<ElixirAST>, idx:Int, declared:Map<String,Bool>, window:Int):Array<String> {
        var out:Map<String,Bool> = new Map();
        for (nm in collectLengthArgNames(stmts, idx + 1, declared, window)) out.set(nm, true);
        for (nm in collectRemoteArgVars(stmts, idx + 1, declared, window, "Phoenix.Component", "assign", 0)) out.set(nm, true);
        for (nm in collectRemoteArgVars(stmts, idx + 1, declared, window, "Phoenix.Component", "assign", 1)) out.set(nm, true);
        for (nm in collectAssignMapValueVars(stmts, idx + 1, window)) out.set(nm, true);
        var names = [];
        for (nm in out.keys()) if (!declared.exists(nm)) names.push(nm);
        return names;
    }

    static function collectRemoteArgVars(stmts:Array<ElixirAST>, start:Int, declared:Map<String,Bool>, window:Int, modName:String, fnName:String, argIndex:Int):Array<String> {
        var out:Map<String,Bool> = new Map();
        var endIdx = Std.int(Math.min(stmts.length, start + window));
        for (k in start...endIdx) scanRemoteArgVar(stmts[k], out, modName, fnName, argIndex);
        var names = [];
        for (nm in out.keys()) if (!declared.exists(nm)) names.push(nm);
        return names;
    }
    static function scanRemoteArgVar(n:ElixirAST, out:Map<String,Bool>, modName:String, fnName:String, argIndex:Int):Void {
        if (n == null || n.def == null) return;
        switch (n.def) {
            case ERemoteCall(mod, fn, args) if (fn == fnName):
                var m:Null<String> = switch (mod.def) { case EVar(mn): mn; default: null; };
                if (m == modName && argIndex < args.length) switch (args[argIndex].def) {
                    case EVar(v): out.set(v, true);
                    default:
                }
                for (a in args) scanRemoteArgVar(a, out, modName, fnName, argIndex);
            case EBlock(ss): for (s in ss) scanRemoteArgVar(s, out, modName, fnName, argIndex);
            case EIf(c,t,e): scanRemoteArgVar(c, out, modName, fnName, argIndex); scanRemoteArgVar(t, out, modName, fnName, argIndex); if (e != null) scanRemoteArgVar(e, out, modName, fnName, argIndex);
            case EBinary(_, l, r): scanRemoteArgVar(l, out, modName, fnName, argIndex); scanRemoteArgVar(r, out, modName, fnName, argIndex);
            case ECall(tgt, _, argsX): if (tgt != null) scanRemoteArgVar(tgt, out, modName, fnName, argIndex); for (aX in argsX) scanRemoteArgVar(aX, out, modName, fnName, argIndex);
            case ERemoteCall(tgt2, _, argsY): scanRemoteArgVar(tgt2, out, modName, fnName, argIndex); for (aY in argsY) scanRemoteArgVar(aY, out, modName, fnName, argIndex);
            case ETuple(elems): for (e in elems) scanRemoteArgVar(e, out, modName, fnName, argIndex);
            case EMap(pairs): for (p in pairs) scanRemoteArgVar(p.value, out, modName, fnName, argIndex);
            default:
        }
    }

    // Collect variable names used as values inside the map passed as second arg to Phoenix.Component.assign
    static function collectAssignMapValueVars(stmts:Array<ElixirAST>, start:Int, window:Int):Array<String> {
        var out:Map<String,Bool> = new Map();
        var endIdx = Std.int(Math.min(stmts.length, start + window));
        for (k in start...endIdx) scanAssignMapValueVars(stmts[k], out);
        var names = [];
        for (nm in out.keys()) names.push(nm);
        return names;
    }
    static function scanAssignMapValueVars(n:ElixirAST, out:Map<String,Bool>):Void {
        if (n == null || n.def == null) return;
        switch (n.def) {
            case ERemoteCall(mod, fn, args) if (fn == "assign"):
                var m:Null<String> = switch (mod.def) { case EVar(mn): mn; default: null; };
                if (m == "Phoenix.Component" && args.length >= 2) {
                    switch (args[1].def) {
                        case EMap(pairs):
                            for (p in pairs) collectFieldBasesFromExpr(p.value, out);
                        default:
                    }
                }
                for (a in args) scanAssignMapValueVars(a, out);
            case EBlock(ss): for (s in ss) scanAssignMapValueVars(s, out);
            case EIf(c,t,e): scanAssignMapValueVars(c, out); scanAssignMapValueVars(t, out); if (e != null) scanAssignMapValueVars(e, out);
            case EBinary(_, l, r): scanAssignMapValueVars(l, out); scanAssignMapValueVars(r, out);
            case ECall(tgt, _, argsX): if (tgt != null) scanAssignMapValueVars(tgt, out); for (aX in argsX) scanAssignMapValueVars(aX, out);
            case ERemoteCall(tgt2, _, argsY): scanAssignMapValueVars(tgt2, out); for (aY in argsY) scanAssignMapValueVars(aY, out);
            case ETuple(elems): for (e in elems) scanAssignMapValueVars(e, out);
            case EMap(pairs): for (p in pairs) collectFieldBasesFromExpr(p.value, out);
            default:
        }
    }
    static function collectFieldBasesFromExpr(x:ElixirAST, out:Map<String,Bool>):Void {
        if (x == null || x.def == null) return;
        switch (x.def) {
            case EField(obj, _):
                switch (obj.def) { case EVar(vf): out.set(vf, true); default: collectFieldBasesFromExpr(obj, out); }
            case EBlock(ss): for (s in ss) collectFieldBasesFromExpr(s, out);
            case EIf(c,t,e): collectFieldBasesFromExpr(c, out); collectFieldBasesFromExpr(t, out); if (e != null) collectFieldBasesFromExpr(e, out);
            case EBinary(_, l, r): collectFieldBasesFromExpr(l, out); collectFieldBasesFromExpr(r, out);
            case ECall(tgt, _, args): if (tgt != null) collectFieldBasesFromExpr(tgt, out); for (a in args) collectFieldBasesFromExpr(a, out);
            case ERemoteCall(tgt2, _, args2): collectFieldBasesFromExpr(tgt2, out); for (a2 in args2) collectFieldBasesFromExpr(a2, out);
            case ETuple(elems): for (e in elems) collectFieldBasesFromExpr(e, out);
            case EMap(pairs): for (p in pairs) collectFieldBasesFromExpr(p.value, out);
            default:
        }
    }
    static function collectVarsFromExpr(x:ElixirAST, out:Map<String,Bool>):Void {
        if (x == null || x.def == null) return;
        switch (x.def) {
            case EVar(v): out.set(v, true);
            case EBlock(ss): for (s in ss) collectVarsFromExpr(s, out);
            case EIf(c,t,e): collectVarsFromExpr(c, out); collectVarsFromExpr(t, out); if (e != null) collectVarsFromExpr(e, out);
            case EBinary(_, l, r): collectVarsFromExpr(l, out); collectVarsFromExpr(r, out);
            case ECall(tgt, _, args): if (tgt != null) collectVarsFromExpr(tgt, out); for (a in args) collectVarsFromExpr(a, out);
            case ERemoteCall(tgt2, _, args2): collectVarsFromExpr(tgt2, out); for (a2 in args2) collectVarsFromExpr(a2, out);
            case EFn(clauses):
                for (cl in clauses) {
                    // Collect variables inside the fn body, excluding clause parameter names
                    var inner:Map<String,Bool> = new Map();
                    if (cl.guard != null) collectVarsFromExpr(cl.guard, inner);
                    if (cl.body != null) collectVarsFromExpr(cl.body, inner);
                    var params:Map<String,Bool> = new Map();
                    for (arg in cl.args) switch (arg) { case PVar(nm): params.set(nm, true); default: }
                    for (k in inner.keys()) if (!params.exists(k)) out.set(k, true);
                }
            case ETuple(elems): for (e in elems) collectVarsFromExpr(e, out);
            case EMap(pairs): for (p in pairs) collectVarsFromExpr(p.value, out);
            case EField(obj, _):
                switch (obj.def) { case EVar(vf): out.set(vf, true); default: collectVarsFromExpr(obj, out); }
            default:
        }
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
            case EFn(clauses):
                for (cl in clauses) {
                    // Collect variables inside the fn body, excluding clause parameter names
                    var inner:Map<String,Bool> = new Map();
                    if (cl.guard != null) collectVars(cl.guard, inner);
                    if (cl.body != null) collectVars(cl.body, inner);
                    var params:Map<String,Bool> = new Map();
                    for (arg in cl.args) switch (arg) { case PVar(nm): params.set(nm, true); default: }
                    for (k in inner.keys()) if (!params.exists(k)) out.set(k, true);
                }
            case EMap(pairs): for (p in pairs) { collectVars(p.key, out); collectVars(p.value, out); }
            case EKeywordList(pairs): for (p in pairs) collectVars(p.value, out);
            case EStructUpdate(base, fields): collectVars(base, out); for (f in fields) collectVars(f.value, out);
            case ETuple(elems): for (e in elems) collectVars(e, out);
            // Avoid name heuristics from textual content; rely on actual AST variable references only
            default:
        }
    }
}

#end
