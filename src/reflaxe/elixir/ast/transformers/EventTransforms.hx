package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer; // transformNode
import reflaxe.elixir.ast.NameUtils;
import reflaxe.elixir.ast.naming.ElixirAtom;

/**
 * EventTransforms
 *
 * WHAT
 * - Event/Controller param aliasing kept modular from the main transformer.
 * - Implements: eventParamsAliasPass
 *
 * WHY
 * - Avoid app-specific key lists; structurally alias only what is used and missing.
 * - Keep ElixirASTTransformer as a thin registry.
 */
class EventTransforms {
    // Local AST iterator to avoid relying on private ElixirASTTransformer.iterateAST
    static function iterate(node: ElixirAST, visitor: ElixirAST -> Void): Void {
        if (node == null || node.def == null) return;
        switch (node.def) {
            case EBlock(exprs): for (e in exprs) if (e != null) visitor(e);
            case EModule(_, _, body): for (b in body) if (b != null) visitor(b);
            case EDefmodule(_, doBlock): if (doBlock != null) visitor(doBlock);
            case EDef(_, _, _, body): if (body != null) visitor(body);
            case EDefp(_, _, _, body): if (body != null) visitor(body);
            case EIf(c,t,e): if (c!=null) visitor(c); if (t!=null) visitor(t); if (e!=null) visitor(e);
            case ECase(target, clauses): if (target!=null) visitor(target); for (c in clauses) { if (c.guard!=null) visitor(c.guard); if (c.body!=null) visitor(c.body);} 
            case EMatch(_, expr): if (expr!=null) visitor(expr);
            case EBinary(_, l, r): if (l!=null) visitor(l); if (r!=null) visitor(r);
            case EUnary(_, e): if (e!=null) visitor(e);
            case ECall(target, _, args): if (target!=null) visitor(target); for (a in args) if (a!=null) visitor(a);
            case ERemoteCall(mod, _, args): if (mod!=null) visitor(mod); for (a in args) if (a!=null) visitor(a);
            case EMacroCall(_, args, doBlock): for (a in args) if (a!=null) visitor(a); if (doBlock!=null) visitor(doBlock);
            case ETuple(items): for (i in items) if (i!=null) visitor(i);
            case EList(items): for (i in items) if (i!=null) visitor(i);
            case EMap(pairs): for (p in pairs) { if (p.key!=null) visitor(p.key); if (p.value!=null) visitor(p.value); }
            case EKeywordList(pairs): for (p in pairs) if (p.value!=null) visitor(p.value);
            case EStruct(_, fields): for (f in fields) if (f.value!=null) visitor(f.value);
            case EFor(gens, filters, body, into, _): for (g in gens) if (g.expr!=null) visitor(g.expr); for (f in filters) if (f!=null) visitor(f); if (body!=null) visitor(body); if (into!=null) visitor(into);
            case EFn(clauses): for (cl in clauses) { if (cl.guard!=null) visitor(cl.guard); if (cl.body!=null) visitor(cl.body);} 
            case EReceive(clauses, after): for (cl in clauses) { if (cl.guard!=null) visitor(cl.guard); if (cl.body!=null) visitor(cl.body);} if (after!=null) { if (after.timeout!=null) visitor(after.timeout); if (after.body!=null) visitor(after.body);} 
            case ECond(conds): for (c in conds) { if (c.condition!=null) visitor(c.condition); if (c.body!=null) visitor(c.body);} 
            case EField(obj,_): if (obj!=null) visitor(obj);
            case EModuleAttribute(_, value): if (value!=null) visitor(value);
            case EParen(e): if (e!=null) visitor(e);
            case _:
        }
    }
    /**
     * EventArmBinderRenameByUsage
     *
     * WHAT
     * - Within handler/controller functions, for case arms with atom-head tuple patterns (e.g., {:create_todo, _}),
     *   if the clause body references exactly one simple missing identifier and there exists at least one unused binder
     *   among the tuple components after the atom head, rename the first unused binder to that identifier.
     *   If there is no unused binder but the identifier is provably a params key used via Map.get(params, :key),
     *   inject a clause-local alias `missing = Map.get(params, :key)`.
     *
     * WHY
     * - Prevent undefined variables in event/controller arm bodies in a structurally provable and idiomatic way
     *   without app-specific whitelists.
     *
     * HOW
     * - Detect atom-head tuple patterns and collect used/declared names; compute missing simple identifiers.
     * - Prefer binder rename when an unused binder exists after the atom; otherwise alias from params when provable.
     */
    public static function eventArmBinderRenameByUsagePass(ast: ElixirAST): ElixirAST {
        inline function isSimpleIdent(n:String):Bool return n != null && ~/^[a-z_][a-z0-9_]*$/.match(n);
        function isAtomHeadTuple(p:EPattern):Bool {
            return switch (p) {
                case PTuple(el) if (el.length >= 1):
                    switch (el[0]) { case PLiteral({def: EAtom(_)}): true; default: false; }
                default: false;
            };
        }
        function collectUsedVars(node: ElixirAST, acc: Map<String, Bool>): Void {
            if (node == null) return;
            switch (node.def) { case EVar(name): if (isSimpleIdent(name)) acc.set(name, true); default: iterate(node, v -> collectUsedVars(v, acc)); }
        }
        function collectBodyDeclaredLocals(node:ElixirAST, acc:Map<String,Bool>):Void {
            if (node == null) return;
            switch (node.def) {
                case EMatch(pat, expr):
                    function gather(p:EPattern):Void {
                        switch (p) {
                            case PVar(n): acc.set(n, true);
                            case PTuple(l): for (e in l) gather(e);
                            case PList(l): for (e in l) gather(e);
                            case PCons(h,t): gather(h); gather(t);
                            case PMap(ps): for (kv in ps) gather(kv.value);
                            case PStruct(_, fs): for (f in fs) gather(f.value);
                            case PAlias(n, inner): acc.set(n, true); gather(inner);
                            case PPin(inner): gather(inner);
                            case PBinary(segs): for (s in segs) gather(s.pattern);
                            default:
                        }
                    }
                    gather(pat);
                    collectBodyDeclaredLocals(expr, acc);
                case EBlock(stmts): for (s in stmts) collectBodyDeclaredLocals(s, acc);
                case EIf(c,t,e): collectBodyDeclaredLocals(c, acc); collectBodyDeclaredLocals(t, acc); if (e != null) collectBodyDeclaredLocals(e, acc);
                case ECase(target, clauses): collectBodyDeclaredLocals(target, acc); for (cl in clauses) collectBodyDeclaredLocals(cl.body, acc);
                case ECond(conds): for (c in conds) collectBodyDeclaredLocals(c.body, acc);
                case ECall(target, _, args): if (target != null) collectBodyDeclaredLocals(target, acc); for (a in args) collectBodyDeclaredLocals(a, acc);
                case ERemoteCall(mod, _, args): collectBodyDeclaredLocals(mod, acc); for (a in args) collectBodyDeclaredLocals(a, acc);
                case EParen(inner): collectBodyDeclaredLocals(inner, acc);
                default:
            }
        }
        function declaredInPattern(p:EPattern):Map<String,Bool> {
            var m = new Map<String,Bool>();
            function visit(q:EPattern):Void {
                switch (q) {
                    case PVar(n): m.set(n, true);
                    case PTuple(l): for (e in l) visit(e);
                    case PList(l): for (e in l) visit(e);
                    case PCons(h,t): visit(h); visit(t);
                    case PMap(ps): for (kv in ps) visit(kv.value);
                    case PStruct(_, fs): for (f in fs) visit(f.value);
                    case PAlias(n, inner): m.set(n, true); visit(inner);
                    case PPin(inner): visit(inner);
                    case PBinary(segs): for (s in segs) visit(s.pattern);
                    default:
                }
            }
            visit(p);
            return m;
        }
        function collectUnusedBindersAfterHead(p:EPattern, used:Map<String,Bool>):Array<{idx:Int, name:String}> {
            var out:Array<{idx:Int, name:String}> = [];
            switch (p) {
                case PTuple(el) if (el.length >= 2):
                    var idx = 1; while (idx < el.length) {
                        switch (el[idx]) { case PVar(nm) if (!used.exists(nm)): out.push({idx: idx, name: nm}); default: }
                        idx++;
                    }
                default:
            }
            return out;
        }
        function renameBinderAtIndex(p:EPattern, index:Int, toName:String):EPattern {
            return switch (p) {
                case PTuple(el) if (index >= 0 && index < el.length):
                    var newEl = el.copy();
                    switch (newEl[index]) { case PVar(_): newEl[index] = PVar(toName); default: }
                    PTuple(newEl);
                default: p;
            };
        }
        function tupleBinderNamesAfterHead(p:EPattern):Array<String> {
            var out:Array<String> = [];
            switch (p) {
                case PTuple(el) if (el.length >= 2): for (i in 1...el.length) switch (el[i]) { case PVar(nm): out.push(nm); default: }
                default:
            }
            return out;
        }
        function removeSingleSocketRebind(body:ElixirAST, binder:String):ElixirAST {
            var count = reflaxe.elixir.ast.ElixirASTHelpers.countVarOccurrencesInAST(body, binder);
            if (count != 1) return body;
            return switch (body.def) {
                case EBlock(stmts) if (stmts.length > 0):
                    switch (stmts[0].def) {
                        case EMatch(PVar(lhs), rhs) if (lhs == "socket"):
                            switch (rhs.def) {
                                case EVar(v) if (v == binder): makeAST(EBlock(stmts.slice(1)));
                                default: body;
                            }
                        default: body;
                    }
                default: body;
            };
        }
        inline function toSnake(name:String):String return NameUtils.toSnakeCase(name);
        function isParamsKeyIn(name:String, scope:ElixirAST):Bool {
            if (name == null || scope == null) return false;
            var snake = toSnake(name);
            var found = false;
            ElixirASTTransformer.transformNode(scope, function(n) {
                if (found) return n;
                switch (n.def) {
                    case ERemoteCall({def: EVar(mod)}, func, args) if (mod == "Map" && func == "get" && args != null && args.length == 2):
                        switch (args[0].def) {
                            case EVar(p) if (p == "params"):
                                switch (args[1].def) {
                                    case EAtom(a): if (toSnake(a) == snake) found = true;
                                    default:
                                }
                            default:
                        }
                    default:
                }
                return n;
            });
            return found;
        }
        function collectParamBinders(patterns:Array<EPattern>):Array<String> {
            var out:Array<String> = [];
            function visit(p:EPattern):Void {
                switch (p) {
                    case PVar(n): out.push(n);
                    case PTuple(l): for (e in l) visit(e);
                    case PList(l): for (e in l) visit(e);
                    case PCons(h,t): visit(h); visit(t);
                    case PMap(ps): for (kv in ps) visit(kv.value);
                    case PStruct(_, fs): for (f in fs) visit(f.value);
                    case PAlias(n, inner): out.push(n); visit(inner);
                    case PPin(inner): visit(inner);
                    case PBinary(segs): for (s in segs) visit(s.pattern);
                    default:
                }
            }
            if (patterns != null) for (p in patterns) visit(p);
            return out;
        }
        // Local handler predicate (mirrors controller/live handler names structurally used elsewhere)
        inline function isHandlerName(name:String):Bool {
            if (name == null) return false;
            return name == "handle_event" || name == "handle_info" || name == "mount"
                || name == "index" || name == "create" || name == "update" || name == "delete" || name == "show" || name == "new" || name == "edit";
        }
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case EDef(name, args, guard, body) if (isHandlerName(name)):
                    var declaredInFunc = new Map<String,Bool>();
                    collectBodyDeclaredLocals(body, declaredInFunc);
                    var funcParamNames = collectParamBinders(args);
                    var hasParams = false; for (pn in funcParamNames) if (pn == "params") { hasParams = true; break; }
                    function process(n:ElixirAST):ElixirAST {
                        return switch (n.def) {
                            case ECase(target, clauses):
                                var newClauses:Array<ECaseClause> = [];
                                for (cl in clauses) {
                                    var out = cl;
                                    if (isAtomHeadTuple(cl.pattern)) {
                                        var locals = new Map<String,Bool>();
                                        collectBodyDeclaredLocals(cl.body, locals);
                                        var used = new Map<String,Bool>(); collectUsedVars(cl.body, used);
                                        var declared = declaredInPattern(cl.pattern);
                                        var missing:Array<String> = [];
                                        for (u in used.keys()) if (isSimpleIdent(u) && !declared.exists(u) && !locals.exists(u)) missing.push(u);
                                        if (missing.length == 1) {
                                            var candidates = tupleBinderNamesAfterHead(cl.pattern);
                                            var cleanedBody = cl.body;
                                            for (bn in candidates) cleanedBody = removeSingleSocketRebind(cleanedBody, bn);
                                            used = new Map<String,Bool>(); collectUsedVars(cleanedBody, used);
                                            var unusedBinders = collectUnusedBindersAfterHead(cl.pattern, used);
                                            if (unusedBinders.length >= 1) {
                                                var toName = missing[0];
                                                var reserved = new Map<String,Bool>(); reserved.set("conn", true); reserved.set("socket", true); reserved.set("assigns", true); reserved.set("params", true);
                                                if (!locals.exists(toName) && !reserved.exists(toName)) {
                                                    var idxInfo = unusedBinders[0];
                                                    var np = renameBinderAtIndex(cl.pattern, idxInfo.idx, toName);
                                                    out = { pattern: np, guard: cl.guard, body: cleanedBody };
                                                }
                                            } else if (hasParams && isParamsKeyIn(missing[0], cleanedBody)) {
                                                var keyAtom = ElixirAtom.raw(toSnake(missing[0]));
                                                var aliasStmt = makeAST(EMatch(PVar(missing[0]), makeAST(ERemoteCall(makeAST(EVar("Map")), "get", [makeAST(EVar("params")), makeAST(EAtom(keyAtom))]))));
                                                var newBody = switch (cleanedBody.def) {
                                                    case EBlock(sts): makeAST(EBlock([aliasStmt].concat(sts)));
                                                    default: makeAST(EBlock([aliasStmt, cleanedBody]));
                                                };
                                                out = { pattern: cl.pattern, guard: cl.guard, body: newBody };
                                            }
                                        }
                                    }
                                    newClauses.push(out);
                                }
                                makeAST(ECase(process(target), newClauses));
                            case ECond(conds):
                                var nc = []; for (c in conds) nc.push({ condition: c.condition, body: process(c.body) });
                                makeAST(ECond(nc));
                            case EBlock(stmts): makeAST(EBlock([for (s in stmts) process(s)]));
                            case EIf(c, t, e): makeAST(EIf(process(c), process(t), e != null ? process(e) : null));
                            default: n;
                        }
                    }
                    makeASTWithMeta(EDef(name, args, guard, process(body)), node.metadata, node.pos);
                default:
                    node;
            };
        });
    }
    public static function eventParamsAliasPass(ast: ElixirAST): ElixirAST {
        inline function toSnake(s:String):String return NameUtils.toSnakeCase(s);
        inline function isSimpleIdent(n:String):Bool return n != null && ~/^[a-z_][a-z0-9_]*$/.match(n);
        inline function isHandlerName(name:String):Bool {
            if (name == null) return false;
            switch (name) {
                case "handle_event" | "handle_info" | "mount": return true;
                default:
                    return name == "index" || name == "create" || name == "update" || name == "delete" || name == "show" || name == "new" || name == "edit";
            }
        }
        function collectParamBinders(patterns:Array<EPattern>):Array<String> {
            var out:Array<String> = [];
            function visit(p:EPattern):Void {
                switch (p) {
                    case PVar(n): out.push(n);
                    case PTuple(l): for (e in l) visit(e);
                    case PList(l): for (e in l) visit(e);
                    case PCons(h,t): visit(h); visit(t);
                    case PMap(ps): for (kv in ps) visit(kv.value);
                    case PStruct(_, fs): for (f in fs) visit(f.value);
                    case PAlias(n, inner): out.push(n); visit(inner);
                    case PPin(inner): visit(inner);
                    case PBinary(segs): for (s in segs) visit(s.pattern);
                    default:
                }
            }
            if (patterns != null) for (p in patterns) visit(p);
            return out;
        }
        function collectUsed(node:ElixirAST, acc:Map<String,Bool>):Void {
            if (node == null) return;
            ElixirASTTransformer.transformNode(node, function(n) {
                switch (n.def) { case EVar(v): if (isSimpleIdent(v)) acc.set(v, true); default: }
                return n;
            });
        }
        function gatherNamesFromPattern(p:EPattern, acc:Map<String,Bool>):Void {
            switch (p) {
                case PVar(name): acc.set(name, true);
                case PTuple(el): for (e in el) gatherNamesFromPattern(e, acc);
                case PList(el): for (e in el) gatherNamesFromPattern(e, acc);
                case PCons(h,t): gatherNamesFromPattern(h, acc); gatherNamesFromPattern(t, acc);
                case PMap(pairs): for (pair in pairs) gatherNamesFromPattern(pair.value, acc);
                case PStruct(_, fields): for (f in fields) gatherNamesFromPattern(f.value, acc);
                case PAlias(n, inner): acc.set(n, true); gatherNamesFromPattern(inner, acc);
                case PPin(inner): gatherNamesFromPattern(inner, acc);
                case PBinary(segs): for (s in segs) gatherNamesFromPattern(s.pattern, acc);
                default:
            }
        }
        function collectBodyDeclaredLocals(node:ElixirAST, acc:Map<String,Bool>):Void {
            if (node == null) return;
            switch (node.def) {
                case EMatch(pat, expr): gatherNamesFromPattern(pat, acc); collectBodyDeclaredLocals(expr, acc);
                case EBlock(stmts): for (s in stmts) collectBodyDeclaredLocals(s, acc);
                case EIf(c,t,e): collectBodyDeclaredLocals(c, acc); collectBodyDeclaredLocals(t, acc); if (e != null) collectBodyDeclaredLocals(e, acc);
                case ECase(target, clauses): collectBodyDeclaredLocals(target, acc); for (cl in clauses) collectBodyDeclaredLocals(cl.body, acc);
                case ECond(conds): for (c in conds) collectBodyDeclaredLocals(c.body, acc);
                case ECall(target, _, args): if (target != null) collectBodyDeclaredLocals(target, acc); for (a in args) collectBodyDeclaredLocals(a, acc);
                case ERemoteCall(mod, _, args): collectBodyDeclaredLocals(mod, acc); for (a in args) collectBodyDeclaredLocals(a, acc);
                case EParen(inner): collectBodyDeclaredLocals(inner, acc);
                default:
            }
        }
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case EDef(name, args, guard, body) if (isHandlerName(name)):
                    var paramNames = collectParamBinders(args);
                    var hasParams = false; for (pn in paramNames) if (pn == "params") { hasParams = true; break; }
                    if (!hasParams) return node;
                    var declared = new Map<String,Bool>(); for (p in paramNames) declared.set(p, true);
                    collectBodyDeclaredLocals(body, declared);
                    var used = new Map<String,Bool>(); collectUsed(body, used);
                    var reserved = new Map<String,Bool>();
                    for (n in ["conn","socket","assigns","params"]) reserved.set(n, true);
                    var prebinds:Array<ElixirAST> = [];
                    for (u in used.keys()) {
                        if (!declared.exists(u) && !reserved.exists(u) && isSimpleIdent(u)) {
                            var atom = ElixirAtom.raw(toSnake(u));
                            var getCall = makeAST(ERemoteCall(makeAST(EVar("Map")), "get", [makeAST(EVar("params")), makeAST(EAtom(atom))]));
                            prebinds.push(makeAST(EMatch(PVar(u), getCall)));
                            declared.set(u, true);
                        }
                    }
                    if (prebinds.length == 0) return node;
                    var newBody = switch (body.def) {
                        case EBlock(stmts): makeAST(EBlock(prebinds.concat(stmts)));
                        default: makeAST(EBlock(prebinds.concat([body])));
                    };
                    makeASTWithMeta(EDef(name, args, guard, newBody), node.metadata, node.pos);
                default:
                    node;
            };
        });
    }
}

#end
