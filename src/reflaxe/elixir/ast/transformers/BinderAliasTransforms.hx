package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTPrinter;
import reflaxe.elixir.ast.ElixirAST.makeAST;

/**
 * BinderAliasTransforms: Structural binder alignment and alias injection passes
 *
 * WHAT
 * - Provides strictly structural, target-agnostic passes that align case/cond binders with body usage
 *   and inject minimal, local aliases only when provably necessary.
 * - Avoids any app-specific constants or name lists. Only structural conditions are used.
 *
 * WHY
 * - Prevent undefined variable errors introduced by prior renames or nested transformations.
 * - Keep generated Elixir idiomatic by preferring rename over alias where safe, and injecting
 *   a clause-local alias only when exactly one missing simple identifier is referenced.
 * - Centralize binder alias logic outside the transformer registry to keep it thin.
 *
 * HOW
 * - Each pass is a pure `ElixirAST -> ElixirAST` function.
 * - Uses ElixirASTTransformer.transformAST/transformNode/iterateAST for traversal utilities.
 * - Passes are independent and composable; run order is managed by the registry.
 *
 * CONTEXT
 * - Called from ElixirASTTransformer.getEnabledPasses in the Pattern & Binder shaping and late cleanup buckets.
 * - Cooperates with PatternMatchingTransforms and HygieneTransforms.
 *
 * EDGE CASES
 * - Multi-binder clauses: do not guess; require exactly one structurally justified candidate.
 * - Field bases (Map.get/Keyword.get target vars) are excluded from "missing simple identifier" candidates.
 * - Avoids shadowing outer names by preferring binder rename only when body does not reference binder
 *   and exactly one alternative is referenced.
 */
@:nullSafety(Off)
class BinderAliasTransforms {
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

    // Helper to rename a single binder name inside a pattern tree
    static function renameBinderInPattern(p:EPattern, from:String, to:String):EPattern {
        return switch (p) {
            case PVar(n) if (n == from): PVar(to);
            case PTuple(list): PTuple([for (e in list) renameBinderInPattern(e, from, to)]);
            case PList(list): PList([for (e in list) renameBinderInPattern(e, from, to)]);
            case PCons(h, t): PCons(renameBinderInPattern(h, from, to), renameBinderInPattern(t, from, to));
            case PMap(pairs): PMap([for (kv in pairs) {key: kv.key, value: renameBinderInPattern(kv.value, from, to)}]);
            case PStruct(mod, fields): PStruct(mod, [for (f in fields) {key: f.key, value: renameBinderInPattern(f.value, from, to)}]);
            case PAlias(v, inner): PAlias(v == from ? to : v, renameBinderInPattern(inner, from, to));
            case PPin(inner): PPin(renameBinderInPattern(inner, from, to));
            case PBinary(segs): PBinary([for (s in segs) {pattern: renameBinderInPattern(s.pattern, from, to), size: s.size, type: s.type, modifiers: s.modifiers}]);
            default: p;
        };
    }

    /**
     * OptionBinderConsistencyPass
     *
     * WHY: Subsequent naming passes or earlier builder heuristics can occasionally misalign
     * the Option.Some/ok binder name with the identifiers actually used in the clause body.
     * This can surface as undefined variables (e.g., pattern {:some, msg} while body uses `level`).
     *
     * WHAT: For every case clause with pattern {:some|:ok, binder}, if the binder is not referenced
     * in the clause body and there is exactly one viable identifier referenced in the body that is
     * not a field-base (Map.get/Keyword.get target), not already a binder, and not an obvious
     * outer/param name, rename the binder to that identifier. This keeps pattern and body consistent
     * and prevents undefined variable errors while avoiding shadowing of outer variables like `msg`.
     */
    public static function optionBinderConsistencyPass(ast: ElixirAST): ElixirAST {
        inline function isSimpleIdent(n:String):Bool {
            return n != null && ~/^[a-z_][a-z0-9_]*$/.match(n);
        }
        
        function collectBinders(p:EPattern, acc:Map<String,Bool>):Void {
            switch (p) {
                case PVar(n): acc.set(n, true);
                case PTuple(list): for (e in list) collectBinders(e, acc);
                case PList(list): for (e in list) collectBinders(e, acc);
                case PCons(h,t): collectBinders(h, acc); collectBinders(t, acc);
                case PMap(pairs): for (kv in pairs) collectBinders(kv.value, acc);
                case PStruct(_, fields): for (f in fields) collectBinders(f.value, acc);
                case PAlias(v, inner): acc.set(v, true); collectBinders(inner, acc);
                case PPin(inner): collectBinders(inner, acc);
                case PBinary(segs): for (s in segs) collectBinders(s.pattern, acc);
                default:
            }
        }

        function collectUsed(node:ElixirAST, acc:Map<String,Bool>):Void {
            if (node == null) return;
            switch (node.def) {
                case EVar(name): if (isSimpleIdent(name)) acc.set(name, true);
                default: iterate(node, n -> collectUsed(n, acc));
            }
        }

        function collectFieldBases(node:ElixirAST, acc:Map<String,Bool>):Void {
            if (node == null) return;
            switch (node.def) {
                case ERemoteCall({def: EVar("Map")}, func, args) if (func == "get" && args.length > 0):
                    switch (args[0].def) { case EVar(n): if (isSimpleIdent(n)) acc.set(n, true); default: }
                    for (a in args) collectFieldBases(a, acc);
                case ERemoteCall({def: EVar("Keyword")}, func, args) if (func == "get" && args.length > 0):
                    switch (args[0].def) { case EVar(n): if (isSimpleIdent(n)) acc.set(n, true); default: }
                    for (a in args) collectFieldBases(a, acc);
                default:
                    iterate(node, n -> collectFieldBases(n, acc));
            }
        }

        function renameBinder(p:EPattern, from:String, to:String):EPattern {
            return switch (p) {
                case PVar(n) if (n == from): PVar(to);
                case PTuple(list): PTuple([for (e in list) renameBinder(e, from, to)]);
                case PList(list): PList([for (e in list) renameBinder(e, from, to)]);
                case PCons(h, t): PCons(renameBinder(h, from, to), renameBinder(t, from, to));
                case PMap(pairs): PMap([for (kv in pairs) {key: kv.key, value: renameBinder(kv.value, from, to)}]);
                case PStruct(mod, fields): PStruct(mod, [for (f in fields) {key: f.key, value: renameBinder(f.value, from, to)}]);
                case PAlias(v, inner): PAlias(v == from ? to : v, renameBinder(inner, from, to));
                case PPin(inner): PPin(renameBinder(inner, from, to));
                case PBinary(segs): PBinary([for (s in segs) {pattern: renameBinder(s.pattern, from, to), size: s.size, type: s.type, modifiers: s.modifiers}]);
                default: p;
            };
        }

        return switch (ast.def) {
            case ECase(target, clauses):
                var fixed:Array<ECaseClause> = [];
                for (cl in clauses) {
                    var out = cl;
                    // Look for {:some|:ok, binder}
                    switch (cl.pattern) {
                        case PTuple(elements) if (elements.length >= 2):
                            switch (elements[0]) {
                                case PLiteral({def: EAtom(a)}) if (a == "some" || a == "ok"):
                                    var binderName:Null<String> = null;
                                    switch (elements[1]) { case PVar(b): binderName = b; default: }
                                    if (binderName != null) {
                                        // If binder is not used in body, see if there is exactly one viable identifier to rename to
                                        var used = new Map<String,Bool>();
                                        var fieldBases = new Map<String,Bool>();
                                        collectUsed(cl.body, used);
                                        collectFieldBases(cl.body, fieldBases);

                                        // Exclude binder name and field base names
                                        used.remove(binderName);
                                        for (k in fieldBases.keys()) used.remove(k);

                                        // Ensure the candidate is not already bound in pattern
                                        var binders = new Map<String,Bool>();
                                        collectBinders(cl.pattern, binders);
                                        for (k in binders.keys()) used.remove(k);

                                        var candidates:Array<String> = [];
                                        for (k in used.keys()) if (isSimpleIdent(k)) candidates.push(k);

                                        if (candidates.length == 1) {
                                            var toName = candidates[0];
                                            out = { pattern: renameBinder(cl.pattern, binderName, toName), guard: cl.guard, body: cl.body };
                                        }
                                    }
                                default:
                            }
                        default:
                    }
                    fixed.push(out);
                }
                makeASTWithMeta(ECase(target, fixed), ast.metadata, ast.pos);
            default:
                ElixirASTTransformer.transformAST(ast, optionBinderConsistencyPass);
        };
    }

    /** CaseClauseBindingAlias: alias missing simple identifiers from clause binders. */
    public static function caseClauseBindingAliasPass(ast: ElixirAST): ElixirAST {
        inline function isSimpleIdent(n:String):Bool {
            return n != null && ~/^[a-z_][a-z0-9_]*$/.match(n);
        }
        function declaredIn(p:EPattern):Map<String,Bool> {
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
        function transformFunc(body:ElixirAST, declared:Map<String,Bool>):ElixirAST {
            // Scan for exactly-one missing simple identifier in body
            var used = new Map<String,Bool>();
            var missing = new Array<String>();
            function collectUsed(node:ElixirAST):Void {
                if (node == null) return;
                switch (node.def) {
                    case EVar(name): used.set(name, true);
                    default: iterate(node, collectUsed);
                }
            }
            collectUsed(body);
            for (k in used.keys()) if (isSimpleIdent(k) && !declared.exists(k)) missing.push(k);
            if (missing.length == 1) {
                var aliasStmt = makeAST(EMatch(PVar(missing[0]), makeAST(EVar(missing[0])))); // placeholder, real binder provided by clause wrapper
                return switch (body.def) {
                    case EBlock(sts): makeAST(EBlock([aliasStmt].concat(sts)));
                    default: makeAST(EBlock([aliasStmt, body]));
                };
            }
            return body;
        }
        return switch (ast.def) {
            case EDef(name, args, guards, body):
                makeASTWithMeta(EDef(name, args, guards, caseClauseBindingAliasPass(body)), ast.metadata, ast.pos);
            case ECase(target, clauses):
                var newClauses:Array<ECaseClause> = [];
                for (cl in clauses) {
                    var declared = declaredIn(cl.pattern);
                    var body2 = transformFunc(cl.body, declared);
                    // If we introduced a placeholder alias, rewrite its RHS from the binder name in pattern
                    switch (body2.def) {
                        case EBlock(sts) if (sts.length > 0):
                            switch (sts[0].def) {
                                case EMatch(PVar(aliasName), rhs):
                                    // Find binder providing alias value
                                    var binderName:Null<String> = null;
                                    function findBinder(p:EPattern):Void {
                                        switch (p) {
                                            case PVar(n): binderName = n;
                                            case PTuple(l): for (e in l) findBinder(e);
                                            case PList(l): for (e in l) findBinder(e);
                                            case PCons(h,t): findBinder(h); findBinder(t);
                                            case PMap(ps): for (kv in ps) findBinder(kv.value);
                                            case PStruct(_, fs): for (f in fs) findBinder(f.value);
                                            case PAlias(n, inner): binderName = n; findBinder(inner);
                                            case PPin(inner): findBinder(inner);
                                            case PBinary(segs): for (s in segs) findBinder(s.pattern);
                                            default:
                                        }
                                    }
                                    findBinder(cl.pattern);
                                    var aliasRhs = binderName != null ? makeAST(EVar(binderName)) : rhs;
                                    var newFirst = makeAST(EMatch(PVar(aliasName), aliasRhs));
                                    var rest = sts.slice(1);
                                    var newBody = makeAST(EBlock([newFirst].concat(rest)));
                                    newClauses.push({ pattern: cl.pattern, guard: cl.guard, body: newBody });
                                default:
                                    newClauses.push({ pattern: cl.pattern, guard: cl.guard, body: body2 });
                            }
                        default:
                            newClauses.push({ pattern: cl.pattern, guard: cl.guard, body: body2 });
                    }
                }
                makeASTWithMeta(ECase(target, newClauses), ast.metadata, ast.pos);
            case ECond(conds):
                var nConds = [];
                for (c in conds) nConds.push({ condition: c.condition, body: caseClauseBindingAliasPass(c.body) });
                makeASTWithMeta(ECond(nConds), ast.metadata, ast.pos);
            default:
                ElixirASTTransformer.transformAST(ast, caseClauseBindingAliasPass);
        };
    }

    /** GlobalOptionBinderAlias: pre-bind exactly-one missing simple var to the {:some|:ok, binder} */
    public static function globalOptionBinderAliasPass(ast: ElixirAST): ElixirAST {
        inline function isSimpleIdent(n:String):Bool return n != null && ~/^[a-z_][a-z0-9_]*$/.match(n);
        function declaredIn(p:EPattern):Map<String,Bool> {
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
        function collectUsed(node:ElixirAST, acc:Map<String,Bool>):Void {
            if (node == null) return; switch (node.def) { case EVar(n): acc.set(n, true); default: iterate(node, v -> collectUsed(v, acc)); }
        }
        return switch (ast.def) {
            case ECase(target, clauses):
                var fixed:Array<ECaseClause> = [];
                for (cl in clauses) {
                    var out = cl;
                    switch (cl.pattern) {
                        case PTuple(elements) if (elements.length >= 2):
                            switch (elements[0]) {
                                case PLiteral({def: EAtom(a)}) if (a == "some" || a == "ok"):
                                    var binder:Null<String> = null;
                                    switch (elements[1]) { case PVar(n): binder = n; default: }
                                    if (binder != null) {
                                        var used = new Map<String,Bool>(); collectUsed(cl.body, used);
                                        var declared = declaredIn(cl.pattern);
                                        var missing:Array<String> = [];
                                        for (u in used.keys()) if (isSimpleIdent(u) && !declared.exists(u)) missing.push(u);
                                        if (missing.length == 1) {
                                            var aliasName = missing[0];
                                            var aliasStmt = makeAST(EMatch(PVar(aliasName), makeAST(EVar(binder))));
                                            var newBody = switch (cl.body.def) {
                                                case EBlock(sts): makeAST(EBlock([aliasStmt].concat(sts)));
                                                default: makeAST(EBlock([aliasStmt, cl.body]));
                                            };
                                            out = { pattern: cl.pattern, guard: cl.guard, body: newBody };
                                        }
                                    }
                                default:
                            }
                        default:
                    }
                    fixed.push(out);
                }
                makeASTWithMeta(ECase(target, fixed), ast.metadata, ast.pos);
            case ECond(conds):
                var newConds = [];
                for (c in conds) newConds.push({ condition: c.condition, body: globalOptionBinderAliasPass(c.body) });
                makeASTWithMeta(ECond(newConds), ast.metadata, ast.pos);
            case EDef(name, args, guards, body):
                makeASTWithMeta(EDef(name, args, guards, globalOptionBinderAliasPass(body)), ast.metadata, ast.pos);
            case EDefp(name, args, guards, body):
                makeASTWithMeta(EDefp(name, args, guards, globalOptionBinderAliasPass(body)), ast.metadata, ast.pos);
            case EModule(name, attributes, body):
                makeASTWithMeta(EModule(name, attributes, [for (b in body) globalOptionBinderAliasPass(b)]), ast.metadata, ast.pos);
            default:
                ElixirASTTransformer.transformAST(ast, globalOptionBinderAliasPass);
        };
    }

    /** GeneralTupleBinderAlias: rename {atom, binder} binder to exactly-one missing simple identifier */
    public static function generalTupleBinderAliasPass(ast: ElixirAST): ElixirAST {
        inline function isSimpleIdent(n:String):Bool return n != null && ~/^[a-z_][a-z0-9_]*$/.match(n);
        function declaredIn(p:EPattern):Map<String,Bool> {
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
        function collectUsed(node:ElixirAST, acc:Map<String,Bool>):Void { if (node == null) return; switch (node.def) { case EVar(n): acc.set(n, true); default: iterate(node, v -> collectUsed(v, acc)); } }
        return switch (ast.def) {
            case ECase(target, clauses):
                var newClauses:Array<ECaseClause> = [];
                for (cl in clauses) {
                    var out = cl;
                    switch (cl.pattern) {
                        case PTuple(elements) if (elements.length >= 2):
                            switch (elements[0]) {
                                case PLiteral({def: EAtom(_)}):
                                    var binder:Null<String> = null;
                                    switch (elements[1]) { case PVar(n): binder = n; default: }
                                    if (binder != null) {
                                        var used = new Map<String,Bool>(); collectUsed(cl.body, used);
                                        var declared = declaredIn(cl.pattern);
                                        var missing:Array<String> = [];
                                        for (u in used.keys()) if (isSimpleIdent(u) && !declared.exists(u)) missing.push(u);
                                        if (missing.length == 1 && missing[0] != binder) {
                                            out = { pattern: renameBinderInPattern(cl.pattern, binder, missing[0]), guard: cl.guard, body: cl.body };
                                        }
                                    }
                                default:
                            }
                        default:
                    }
                    newClauses.push(out);
                }
                makeASTWithMeta(ECase(target, newClauses), ast.metadata, ast.pos);
            default:
                ElixirASTTransformer.transformAST(ast, generalTupleBinderAliasPass);
        };
        // use renameBinderInPattern instead
    }

    /** GeneralAtomBinderAlias: alias unique missing var to single binder in {:atom, binder} */
    public static function generalAtomBinderAliasPass(ast: ElixirAST): ElixirAST {
        inline function isSimpleIdent(n:String):Bool return n != null && ~/^[a-z_][a-z0-9_]*$/.match(n);
        function isAtomHeadSingleBinder(p:EPattern):{ok:Bool, binder:Null<String>} {
            return switch (p) {
                case PTuple(elements) if (elements.length >= 2):
                    switch (elements[0]) {
                        case PLiteral({def: EAtom(_)}):
                            switch (elements[1]) { case PVar(n): {ok: true, binder: n}; default: {ok: true, binder: null}; }
                        default: {ok: false, binder: null};
                    }
                default: {ok: false, binder: null};
            };
        }
        function collectUsed(node:ElixirAST, acc:Map<String,Bool>):Void {
            if (node == null) return; switch (node.def) {
                case EVar(n): acc.set(n, true);
                default: iterate(node, v -> collectUsed(v, acc));
            }
        }
        function declaredIn(p:EPattern):Map<String,Bool> {
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
        return switch (ast.def) {
            case ECase(target, clauses):
                var newClauses:Array<ECaseClause> = [];
                for (cl in clauses) {
                    var info = isAtomHeadSingleBinder(cl.pattern);
                    if (info.ok && info.binder != null) {
                        var used = new Map<String,Bool>(); collectUsed(cl.body, used);
                        var declared = declaredIn(cl.pattern);
                        var missing:Array<String> = [];
                        for (u in used.keys()) if (isSimpleIdent(u) && !declared.exists(u)) missing.push(u);
                        if (missing.length == 1) {
                            var aliasName = missing[0];
                            var aliasStmt = makeAST(EMatch(PVar(aliasName), makeAST(EVar(info.binder))));
                            var newBody = switch (cl.body.def) {
                                case EBlock(sts): makeAST(EBlock([aliasStmt].concat(sts)));
                                default: makeAST(EBlock([aliasStmt, cl.body]));
                            };
                            newClauses.push({ pattern: cl.pattern, guard: cl.guard, body: newBody });
                            continue;
                        }
                    }
                    newClauses.push(cl);
                }
                makeASTWithMeta(ECase(target, newClauses), ast.metadata, ast.pos);
            case ECond(conds):
                var nConds = [];
                for (c in conds) nConds.push({ condition: c.condition, body: generalAtomBinderAliasPass(c.body) });
                makeASTWithMeta(ECond(nConds), ast.metadata, ast.pos);
            default:
                ElixirASTTransformer.transformAST(ast, generalAtomBinderAliasPass);
        };
    }

    /** SingleBinderMissingVarAlias: alias missing var to sole binder when unique and safe */
    public static function singleBinderMissingVarAliasPass(ast: ElixirAST): ElixirAST {
        inline function isSimpleIdent(n:String):Bool return n != null && ~/^[a-z_][a-z0-9_]*$/.match(n);
        function countBinders(p:EPattern, acc:Array<String>):Void {
            switch (p) {
                case PVar(n): acc.push(n);
                case PTuple(l): for (e in l) countBinders(e, acc);
                case PList(l): for (e in l) countBinders(e, acc);
                case PCons(h,t): countBinders(h, acc); countBinders(t, acc);
                case PMap(ps): for (kv in ps) countBinders(kv.value, acc);
                case PStruct(_, fs): for (f in fs) countBinders(f.value, acc);
                case PAlias(n, inner): acc.push(n); countBinders(inner, acc);
                case PPin(inner): countBinders(inner, acc);
                case PBinary(segs): for (s in segs) countBinders(s.pattern, acc);
                default:
            }
        }
        function collectUsed(node:ElixirAST, acc:Map<String,Bool>):Void { if (node == null) return; switch (node.def) { case EVar(n): acc.set(n, true); default: iterate(node, v -> collectUsed(v, acc)); } }
        function declaredIn(p:EPattern):Map<String,Bool> { var m=new Map<String,Bool>(); function visit(q:EPattern):Void { switch(q){ case PVar(n): m.set(n,true); case PTuple(l): for(e in l) visit(e); case PList(l): for(e in l) visit(e); case PCons(h,t): visit(h); visit(t); case PMap(ps): for(kv in ps) visit(kv.value); case PStruct(_,fs): for(f in fs) visit(f.value); case PAlias(n,inner): m.set(n,true); visit(inner); case PPin(inner): visit(inner); case PBinary(segs): for(s in segs) visit(s.pattern); default: } } visit(p); return m; }
        function collectBound(body:ElixirAST):Map<String,Bool> {
            var bound = new Map<String,Bool>();
            function visit(n:ElixirAST):Void {
                if (n == null) return; switch (n.def) {
                    case EMatch(PVar(v), _): bound.set(v, true);
                    default: iterate(n, visit);
                }
            }
            visit(body);
            return bound;
        }
        return switch (ast.def) {
            case ECase(target, clauses):
                var fixed:Array<ECaseClause> = [];
                for (cl in clauses) {
                    var binders:Array<String> = []; countBinders(cl.pattern, binders);
                    if (binders.length == 1) {
                        var used = new Map<String,Bool>(); collectUsed(cl.body, used);
                        var declared = declaredIn(cl.pattern);
                        var bound = collectBound(cl.body);
                        var missing:Array<String> = [];
                        for (u in used.keys()) if (isSimpleIdent(u) && !declared.exists(u) && !bound.exists(u)) missing.push(u);
                        if (missing.length == 1) {
                            var aliasName = missing[0]; var binder = binders[0];
                            var aliasStmt = makeAST(EMatch(PVar(aliasName), makeAST(EVar(binder))));
                            var newBody = switch (cl.body.def) {
                                case EBlock(sts): makeAST(EBlock([aliasStmt].concat(sts)));
                                default: makeAST(EBlock([aliasStmt, cl.body]));
                            };
                            fixed.push({ pattern: cl.pattern, guard: cl.guard, body: newBody });
                            continue;
                        }
                    }
                    fixed.push(cl);
                }
                makeASTWithMeta(ECase(target, fixed), ast.metadata, ast.pos);
            case ECond(conds):
                var nConds = [];
                for (c in conds) nConds.push({ condition: c.condition, body: singleBinderMissingVarAliasPass(c.body) });
                makeASTWithMeta(ECond(nConds), ast.metadata, ast.pos);
            default:
                ElixirASTTransformer.transformAST(ast, singleBinderMissingVarAliasPass);
        };
    }

    /** GenericBinderSubstitution: rewrite nested payload vars to clause binder or alias uniquely */
    public static function genericBinderSubstitutionPass(ast: ElixirAST): ElixirAST {
        inline function isSimpleIdent(n:String):Bool return n != null && ~/^[a-z_][a-z0-9_]*$/.match(n);
        inline function tupleOfAtomAndVar(p:EPattern):{ok:Bool, atom:Null<String>, binder:Null<String>} {
            return switch (p) {
                case PTuple(elements) if (elements.length >= 2):
                    switch (elements[0]) {
                        case PLiteral({def: EAtom(a)}):
                            var b:Null<String> = null; switch (elements[1]) { case PVar(n): b = n; default: }
                            { ok: true, atom: a, binder: b };
                        default: { ok: false, atom: null, binder: null };
                    }
                default: { ok: false, atom: null, binder: null };
            };
        }
        function collectUsed(node:ElixirAST, acc:Map<String,Bool>):Void { if (node == null) return; switch (node.def) { case EVar(n): acc.set(n, true); default: iterate(node, v -> collectUsed(v, acc)); } }
        function declaredIn(p:EPattern):Map<String,Bool> { var m=new Map<String,Bool>(); function visit(q:EPattern):Void { switch(q){ case PVar(n): m.set(n,true); case PTuple(l): for(e in l) visit(e); case PList(l): for(e in l) visit(e); case PCons(h,t): visit(h); visit(t); case PMap(ps): for(kv in ps) visit(kv.value); case PStruct(_,fs): for(f in fs) visit(f.value); case PAlias(n,inner): m.set(n,true); visit(inner); case PPin(inner): visit(inner); case PBinary(segs): for(s in segs) visit(s.pattern); default: } } visit(p); return m; }

        function transformCase(astLocal:ElixirAST):ElixirAST {
            return switch (astLocal.def) {
                case ECase(target, clauses):
                    var newClauses:Array<ECaseClause> = [];
                    for (cl in clauses) {
                        var info = tupleOfAtomAndVar(cl.pattern);
                        if (info.ok && info.binder != null) {
                            // Prefer direct substitution inside nested tuple payloads
                            // If uncertain and exactly one free identifier is used, alias it to binder
                            var used = new Map<String,Bool>(); collectUsed(cl.body, used);
                            var declared = declaredIn(cl.pattern);
                            var missing:Array<String> = [];
                            for (u in used.keys()) if (isSimpleIdent(u) && !declared.exists(u)) missing.push(u);
                            if (missing.length == 1) {
                                var aliasName = missing[0];
                                // Clause-local alias var = binder
                                var aliasStmt = makeAST(EMatch(PVar(aliasName), makeAST(EVar(info.binder))));
                                var body2 = switch (cl.body.def) {
                                    case EBlock(sts): makeAST(EBlock([aliasStmt].concat(sts)));
                                    default: makeAST(EBlock([aliasStmt, cl.body]));
                                };
                                newClauses.push({ pattern: cl.pattern, guard: cl.guard, body: body2 });
                            } else {
                                // Attempt fast substitution in nested payloads
                                function rewrite(node:ElixirAST):ElixirAST {
                                    return switch (node.def) {
                                        case ETuple(elems):
                                            var newElems = [];
                                            var changed = false;
                                            for (e in elems) {
                                                switch (e.def) {
                                                    case ETuple(inner):
                                                        // Rewrite tuple inner occurrences of "free" var to clause binder
                                                        var innerNew = [];
                                                        var innerChanged = false;
                                                        for (ie in inner) {
                                                            switch (ie.def) {
                                                                case EVar(n) if (isSimpleIdent(n) && !declared.exists(n)):
                                                                    innerNew.push(makeAST(EVar(info.binder)));
                                                                    innerChanged = true;
                                                                default:
                                                                    innerNew.push(ie);
                                                            }
                                                        }
                                                        if (innerChanged) changed = true;
                                                        newElems.push(makeAST(ETuple(innerNew)));
                                                    default:
                                                        newElems.push(e);
                                                }
                                            }
                                            changed ? makeAST(ETuple(newElems)) : node;
                                        default:
                                            node;
                                    };
                                }
                                var rewritten = rewrite(cl.body);
                                newClauses.push({ pattern: cl.pattern, guard: cl.guard, body: rewritten });
                            }
                        } else {
                            newClauses.push(cl);
                        }
                    }
                    makeASTWithMeta(ECase(target, newClauses), astLocal.metadata, astLocal.pos);
                case ECond(conds):
                    var nc = [];
                    for (c in conds) nc.push({ condition: c.condition, body: transformCase(c.body) });
                    makeASTWithMeta(ECond(nc), astLocal.metadata, astLocal.pos);
                case EIf(cond, t, e):
                    makeASTWithMeta(EIf(transformCase(cond), transformCase(t), e != null ? transformCase(e) : null), astLocal.metadata, astLocal.pos);
                case EBlock(sts):
                    makeASTWithMeta(EBlock([for (s in sts) transformCase(s)]), astLocal.metadata, astLocal.pos);
                default:
                    astLocal;
            };
        }
        return transformCase(ast);
    }
}
#end
