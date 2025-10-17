package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.VariableUsageCollector;
import reflaxe.elixir.ast.analyzers.ValueShapeAnalyzer;

/**
 * EFnEnumClosureAlignTransforms
 *
 * WHAT
 * - Final, shape-scoped alignment for anonymous functions passed to Enum.* calls.
 *   Repairs common mismatches: `_primary` -> `primary`, `_elem` -> `primary`, and a
 *   single lower_snake free var used as a field receiver → `primary`.
 *
 * WHY
 * - Earlier/later passes may still leave closures with body vars that do not
 *   match the primary binder in typical Enum.* patterns, causing undefined vars.
 *
 * HOW
 * - Matches ERemoteCall where mod is `Enum` and func in {each,map,reduce,reduce_while,filter,find}.
 * - For closure arity 1 or 2, selects the first arg as `primary` binder.
 * - Rewrites body `_primary` -> `primary` and single underscored other var -> `primary`.
 * - If `primary` unused and exactly one lower_snake free var is used as field receiver,
 *   rewrites it to `primary`.
 * - Type-aware guard (shape-based): do not rewrite an id-like variable to a struct-like
 *   `primary`, and do not rewrite a struct-like variable into an id-like `primary`.
 */
class EFnEnumClosureAlignTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ERemoteCall(mod, func, args) if (isEnum(mod) && isTargetFunc(func)):
                    #if debug_enum_closure
                    trace('[EFnEnumAlign] Visiting Enum.' + func);
                    #end
                    var newArgs = (args == null) ? args : args.copy();
                    for (i in 0...newArgs.length) {
                        switch (newArgs[i].def) {
                            case EFn(clauses):
                                newArgs[i] = makeASTWithMeta(EFn(alignEFnForFunc(clauses, func)), newArgs[i].metadata, newArgs[i].pos);
                            default:
                        }
                    }
                    makeASTWithMeta(ERemoteCall(mod, func, newArgs), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function isEnum(mod: ElixirAST): Bool {
        return switch (mod.def) { case EVar(name) if (name == 'Enum'): true; default: false; }
    }

    static function isTargetFunc(func: String): Bool {
        return func == 'each' || func == 'map' || func == 'reduce' || func == 'reduce_while' || func == 'filter' || func == 'find';
    }

    static function alignEFnForFunc(clauses:Array<{args:Array<EPattern>, guard:Null<ElixirAST>, body:ElixirAST}>, func:String):Array<{args:Array<EPattern>, guard:Null<ElixirAST>, body:ElixirAST}> {
        var out = [];
        for (cl in clauses) {
            var primary: Null<String> = null;
            if (cl.args != null && cl.args.length >= 1) switch (cl.args[0]) { case PVar(n): primary = n; default: }
            if (primary == null) { out.push(cl); continue; }
            var p = primary;
            var body = cl.body;
            var shapes = ValueShapeAnalyzer.classify(body);
            #if debug_enum_closure
            trace('[EFnEnumAlign] primary=' + p);
            #end
            // _primary -> primary
            body = renameVarDeep(body, '_' + p, p);
            // Single underscored free var -> primary
            var used = collectUsedVars(body);
            var assigned = collectLocallyAssignedVarNames(body);
            used.remove(p); used.remove('_' + p);
            for (k in assigned.keys()) used.remove(k);
            var unders:Array<String> = [];
            for (k in used.keys()) if (k != null && k.length > 1 && k.charAt(0) == '_' && looksLikeVar(k.substr(1))) unders.push(k);
            if (unders.length == 1) {
                #if debug_enum_closure
                trace('[EFnEnumAlign] underscored victim ' + unders[0] + ' -> ' + p);
                #end
                // Guard against incompatible shape rewrites
                var victim = unders[0];
                if (!(ValueShapeAnalyzer.isIdLike(victim, shapes) && ValueShapeAnalyzer.isStructLike(p, shapes))
                    && !(ValueShapeAnalyzer.isStructLike(victim, shapes) && ValueShapeAnalyzer.isIdLike(p, shapes))) {
                    body = renameVarDeep(body, victim, p);
                }
            }
            // Prefer a single field-receiver free var to rewrite to primary
            // Only for Enum.each: prefer single field-receiver victim to rewrite to primary
            if (func == 'each') {
                var victims:Array<String> = [];
                for (k in used.keys()) if (looksLikeVar(k)) victims.push(k);
                var recvVictims = [];
                for (v in victims) if (varUsedAsFieldReceiver(body, v)) recvVictims.push(v);
                #if debug_enum_closure
                trace('[EFnEnumAlign] victims={' + victims.join(',') + '} recvVictims={' + recvVictims.join(',') + '}');
                #end
                if (recvVictims.length == 1 && recvVictims[0] != p) {
                    #if debug_enum_closure
                    trace('[EFnEnumAlign] field-receiver victim ' + recvVictims[0] + ' -> ' + p);
                    #end
                var rv = recvVictims[0];
                if (!(ValueShapeAnalyzer.isIdLike(rv, shapes) && ValueShapeAnalyzer.isStructLike(p, shapes))) {
                    body = renameVarDeep(body, rv, p);
                }
                }
                // If exactly one free var appears as a call argument, rewrite to primary
                var argVictims = collectArgVarUses(body);
                // remove binder and assigned
                var filteredArgs:Array<String> = [];
                for (a in argVictims) if (a != p && !assigned.exists(a)) filteredArgs.push(a);
                if (filteredArgs.length == 1) {
                    #if debug_enum_closure
                    trace('[EFnEnumAlign] single arg victim ' + filteredArgs[0] + ' -> ' + p);
                    #end
                var fav = filteredArgs[0];
                if (!(ValueShapeAnalyzer.isIdLike(fav, shapes) && ValueShapeAnalyzer.isStructLike(p, shapes))) {
                    body = renameVarDeep(body, fav, p);
                }
                }
                // If we still have multiple, but they are all action victims (field receiver or arg), rewrite all
                var actionVictims = new Map<String,Bool>();
                for (v in recvVictims) if (v != p) actionVictims.set(v, true);
                for (a in filteredArgs) if (a != p) actionVictims.set(a, true);
                var actionList = [for (k in actionVictims.keys()) k];
                if (actionList.length >= 1) {
                    #if debug_enum_closure
                    trace('[EFnEnumAlign] action victims {' + actionList.join(',') + '} -> ' + p);
                    #end
                for (av in actionList) {
                    if ((ValueShapeAnalyzer.isIdLike(av, shapes) && ValueShapeAnalyzer.isStructLike(p, shapes))
                        || (ValueShapeAnalyzer.isStructLike(av, shapes) && ValueShapeAnalyzer.isIdLike(p, shapes))) {
                        continue;
                    }
                    body = renameVarDeep(body, av, p);
                }
                }
                #if debug_enum_closure
                trace('[EFnEnumAlign] filteredArgs={' + filteredArgs.join(',') + '}');
                #end
                // If exactly one remaining free var (after excluding locals), rewrite to primary
                if (victims.length == 1 && victims[0] != p) {
                    #if debug_enum_closure
                    trace('[EFnEnumAlign] single free var victim ' + victims[0] + ' -> ' + p);
                    #end
                    var v = victims[0];
                    if (!((ValueShapeAnalyzer.isIdLike(v, shapes) && ValueShapeAnalyzer.isStructLike(p, shapes))
                        || (ValueShapeAnalyzer.isStructLike(v, shapes) && ValueShapeAnalyzer.isIdLike(p, shapes)))) {
                        body = renameVarDeep(body, v, p);
                    }
                }
                #if debug_enum_closure
                var afterUsed = collectUsedVars(body);
                var afterList = [];
                for (k in afterUsed.keys()) afterList.push(k);
                trace('[EFnEnumAlign] after used={' + afterList.join(',') + '}');
                #end
            }
            // Drop numeric sentinels inside closure body (last local step)
            body = dropNumericSentinels(body);
            out.push({args: cl.args, guard: cl.guard, body: body});
        }
        return out;
    }

    static function looksLikeVar(name:String):Bool {
        if (name == null || name.length == 0) return false;
        var c = name.charAt(0);
        if (c == '_' || c.toLowerCase() != c) return false;
        return name.indexOf('.') == -1;
    }

    static function collectUsedVars(node: ElixirAST): Map<String, Bool> {
        var used = new Map<String, Bool>();
        function visit(e: ElixirAST): Void {
            if (e == null || e.def == null) return;
            switch (e.def) {
                case EVar(name): used.set(name, true);
                case EField(target, _): visit(target);
                case EBlock(stmts): for (s in stmts) visit(s);
                case EIf(c,t,el): visit(c); visit(t); if (el != null) visit(el);
                case ECase(expr, clauses): visit(expr); for (c in clauses) { if (c.guard != null) visit(c.guard); visit(c.body); }
                case EBinary(_, l, r): visit(l); visit(r);
                case EMatch(_, rhs): visit(rhs);
                case ECall(tgt, _, args): if (tgt != null) visit(tgt); for (a in args) visit(a);
                case ERemoteCall(tgt2, _, args2): visit(tgt2); for (a2 in args2) visit(a2);
                case EList(els): for (el in els) visit(el);
                case ETuple(els): for (el in els) visit(el);
                case EMap(pairs): for (p in pairs) { visit(p.key); visit(p.value); }
                case EKeywordList(pairs): for (p in pairs) visit(p.value);
                case EStructUpdate(base, fields): visit(base); for (f in fields) visit(f.value);
                case EFn(clauses): for (cl in clauses) visit(cl.body);
                default:
            }
        }
        visit(node);
        return used;
    }

    static function collectLocallyAssignedVarNames(node: ElixirAST): Map<String, Bool> {
        var assigned = new Map<String, Bool>();
        function walk(n: ElixirAST): Void {
            if (n == null || n.def == null) return;
            switch (n.def) {
                case EMatch(pat, _):
                    switch (pat) {
                        case PVar(name) if (name != null): assigned.set(name, true);
                        default:
                    }
                case EBinary(Match, left, _):
                    switch (left.def) { case EVar(name) if (name != null): assigned.set(name, true); default: }
                case EBlock(ss): for (s in ss) walk(s);
                case EDo(ss2): for (s in ss2) walk(s);
                case EIf(c,t,e): walk(c); walk(t); if (e != null) walk(e);
                case ECase(expr, clauses):
                    walk(expr);
                    for (c in clauses) {
                        // collect names bound in the pattern
                        var patNames = collectPatternVars(c.pattern);
                        for (k in patNames.keys()) assigned.set(k, true);
                        walk(c.body);
                    }
                case EWith(clauses, doBlock, elseBlock): for (wc in clauses) walk(wc.expr); walk(doBlock); if (elseBlock != null) walk(elseBlock);
                case ECall(t,_,as): if (t != null) walk(t); for (a in as) walk(a);
                case ERemoteCall(t2,_,as2): walk(t2); for (a in as2) walk(a);
                default:
            }
        }
        walk(node);
        return assigned;
    }

    static function collectPatternVars(p: EPattern): Map<String, Bool> {
        var m = new Map<String, Bool>();
        function add(nm:String):Void { if (nm != null && nm.length > 0) m.set(nm, true); }
        function visit(pp:EPattern):Void {
            switch (pp) {
                case PVar(n): add(n);
                case PAlias(n, inner): add(n); visit(inner);
                case PTuple(es): for (e in es) visit(e);
                case PList(es): for (e in es) visit(e);
                case PCons(h,t): visit(h); visit(t);
                case PMap(kvs): for (kv in kvs) visit(kv.value);
                case PStruct(_, fs): for (f in fs) visit(f.value);
                case PBinary(segs): for (s in segs) visit(s.pattern);
                case PPin(inner): visit(inner);
                default:
            }
        }
        visit(p);
        return m;
    }

    static function varUsedAsFieldReceiver(node: ElixirAST, varName: String): Bool {
        var found = false;
        function walk(n: ElixirAST): Void {
            if (n == null || n.def == null || found) return;
            switch (n.def) {
                case EField(target, _):
                    switch (target.def) {
                        case EVar(v) if (v == varName): found = true;
                        default: walk(target);
                    }
                case EBlock(ss): for (s in ss) walk(s);
                case EDo(ss2): for (s in ss2) walk(s);
                case EIf(c,t,e): walk(c); walk(t); if (e != null) walk(e);
                case ECase(expr, cls): walk(expr); for (cl in cls) { if (cl.guard != null) walk(cl.guard); walk(cl.body); }
                case EWith(clauses, doBlock, elseBlock): for (wc in clauses) walk(wc.expr); walk(doBlock); if (elseBlock != null) walk(elseBlock);
                case ECall(t,_,as): if (t != null) walk(t); if (as != null) for (a in as) walk(a);
                case ERemoteCall(t2,_,as2): walk(t2); if (as2 != null) for (a2 in as2) walk(a2);
                case EKeywordList(pairs): for (p in pairs) walk(p.value);
                case EMap(pairs): for (p in pairs) { walk(p.key); walk(p.value); }
                case EStructUpdate(base, fs): walk(base); for (f in fs) walk(f.value);
                case ETuple(es) | EList(es): for (e in es) walk(e);
                case EFn(clauses): for (cl in clauses) { if (cl.guard != null) walk(cl.guard); walk(cl.body); }
                default:
            }
        }
        walk(node);
        return found;
    }

    static function collectArgVarUses(node: ElixirAST): Array<String> {
        var names = new Map<String,Bool>();
        function visit(n: ElixirAST): Void {
            if (n == null || n.def == null) return;
            switch (n.def) {
                case ECall(t,_,as):
                    if (t != null) visit(t);
                    if (as != null) for (a in as) switch (a.def) { case EVar(name): if (looksLikeVar(name)) names.set(name, true); default: visit(a); }
                case ERemoteCall(t2,_,as2):
                    visit(t2);
                    if (as2 != null) for (a2 in as2) switch (a2.def) { case EVar(name2): if (looksLikeVar(name2)) names.set(name2, true); default: visit(a2); }
                case EBlock(ss): for (s in ss) visit(s);
                case EDo(ss2): for (s in ss2) visit(s);
                case EIf(c,t,e): visit(c); visit(t); if (e != null) visit(e);
                case ECase(expr, clauses): visit(expr); for (c in clauses) visit(c.body);
                case EWith(clauses, doBlock, elseBlock): for (wc in clauses) { visit(wc.expr); } visit(doBlock); if (elseBlock != null) visit(elseBlock);
                default:
            }
        }
        visit(node);
        return [for (k in names.keys()) k];
    }

    static function renameVarInNode(node: ElixirAST, from: String, to: String): ElixirAST {
        return ElixirASTTransformer.transformNode(node, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EVar(name) if (name == from): makeASTWithMeta(EVar(to), n.metadata, n.pos);
                case ERaw(_): n;
                default: n;
            }
        });
    }

    static function renameVarDeep(node: ElixirAST, from: String, to: String): ElixirAST {
        if (node == null || node.def == null) return node;
        return switch (node.def) {
            case EVar(name) if (name == from): makeASTWithMeta(EVar(to), node.metadata, node.pos);
            case EField(target, name):
                var nt = renameVarDeep(target, from, to);
                makeASTWithMeta(EField(nt, name), node.metadata, node.pos);
            case EAccess(obj, key):
                var no = renameVarDeep(obj, from, to);
                var nk = renameVarDeep(key, from, to);
                makeASTWithMeta(EAccess(no, nk), node.metadata, node.pos);
            case ECall(tgt, func, args):
                var nt = tgt != null ? renameVarDeep(tgt, from, to) : null;
                var na = args != null ? [for (a in args) renameVarDeep(a, from, to)] : null;
                makeASTWithMeta(ECall(nt, func, na), node.metadata, node.pos);
            case ERemoteCall(tgt, func, args):
                var nt = renameVarDeep(tgt, from, to);
                var na = args != null ? [for (a in args) renameVarDeep(a, from, to)] : null;
                makeASTWithMeta(ERemoteCall(nt, func, na), node.metadata, node.pos);
            case EBlock(stmts):
                makeASTWithMeta(EBlock([for (s in stmts) renameVarDeep(s, from, to)]), node.metadata, node.pos);
            case EDo(stmts):
                makeASTWithMeta(EDo([for (s in stmts) renameVarDeep(s, from, to)]), node.metadata, node.pos);
            case EIf(c,t,e):
                makeASTWithMeta(EIf(renameVarDeep(c, from, to), renameVarDeep(t, from, to), e != null ? renameVarDeep(e, from, to) : null), node.metadata, node.pos);
            case ECase(expr, clauses):
                var ne = renameVarDeep(expr, from, to);
                var ncs = [];
                for (cl in clauses) ncs.push({pattern: cl.pattern, guard: cl.guard != null ? renameVarDeep(cl.guard, from, to) : null, body: renameVarDeep(cl.body, from, to)});
                makeASTWithMeta(ECase(ne, ncs), node.metadata, node.pos);
            case EWith(clauses, doBlock, elseBlock):
                var ncls = [];
                for (wc in clauses) ncls.push({pattern: wc.pattern, expr: renameVarDeep(wc.expr, from, to)});
                makeASTWithMeta(EWith(ncls, renameVarDeep(doBlock, from, to), elseBlock != null ? renameVarDeep(elseBlock, from, to) : null), node.metadata, node.pos);
            case EMatch(pat, rhs):
                makeASTWithMeta(EMatch(pat, renameVarDeep(rhs, from, to)), node.metadata, node.pos);
            case EBinary(op, left, right):
                makeASTWithMeta(EBinary(op, renameVarDeep(left, from, to), renameVarDeep(right, from, to)), node.metadata, node.pos);
            case EKeywordList(pairs):
                var np = [];
                for (p in pairs) np.push({key: p.key, value: renameVarDeep(p.value, from, to)});
                makeASTWithMeta(EKeywordList(np), node.metadata, node.pos);
            case EMap(pairs):
                var mp = [];
                for (p in pairs) mp.push({key: renameVarDeep(p.key, from, to), value: renameVarDeep(p.value, from, to)});
                makeASTWithMeta(EMap(mp), node.metadata, node.pos);
            case EStructUpdate(base, fields):
                var nb = renameVarDeep(base, from, to);
                var nfs = [];
                for (f in fields) nfs.push({key: f.key, value: renameVarDeep(f.value, from, to)});
                makeASTWithMeta(EStructUpdate(nb, nfs), node.metadata, node.pos);
            case ETuple(elems):
                makeASTWithMeta(ETuple([for (e in elems) renameVarDeep(e, from, to)]), node.metadata, node.pos);
            case EList(elems):
                makeASTWithMeta(EList([for (e in elems) renameVarDeep(e, from, to)]), node.metadata, node.pos);
            case EFn(clauses):
                var ncl = [];
                for (cl in clauses) ncl.push({args: cl.args, guard: cl.guard != null ? renameVarDeep(cl.guard, from, to) : null, body: renameVarDeep(cl.body, from, to)});
                makeASTWithMeta(EFn(ncl), node.metadata, node.pos);
            case ERaw(_): node;
            default:
                node;
        }
    }

    static function dropNumericSentinels(body: ElixirAST): ElixirAST {
        if (body == null || body.def == null) return body;
        return switch (body.def) {
            case EBlock(stmts):
                var out = [];
                for (s in stmts) switch (s.def) {
                    case EInteger(v) if (v == 0 || v == 1):
                    case EFloat(f) if (f == 0.0):
                    default: out.push(s);
                }
                makeASTWithMeta(EBlock(out), body.metadata, body.pos);
            case EDo(stmts2):
                var out2 = [];
                for (s2 in stmts2) switch (s2.def) {
                    case EInteger(v2) if (v2 == 0 || v2 == 1):
                    case EFloat(f2) if (f2 == 0.0):
                    default: out2.push(s2);
                }
                makeASTWithMeta(EDo(out2), body.metadata, body.pos);
            default:
                body;
        }
    }
}

#end
