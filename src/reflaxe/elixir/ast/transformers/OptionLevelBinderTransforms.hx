package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;

/**
 * OptionLevelBinderTransforms: Late, narrowly-scoped passes for *_level targets
 *
 * WHAT
 * - Enforce and align the binder name for Option/Result patterns targeting *_level variables.
 * - Prefer renaming to 'level' when the body references 'level'; inject alias only as last resort.
 *
 * WHY
 * - Prevent undefined vars and ensure consistency between case target naming and binder naming
 *   in idiomatic Elixir for Option/Result cases commonly used in guard-level flows.
 *
 * HOW
 * - enforceLevelBinderForLevelTargetsPass: skips heuristic rename for *_level targets, defers to later passes.
 * - forceOptionLevelBinderWhenBodyUsesLevelPass: rename binder to 'level' when body references 'level'.
 * - absoluteLevelBinderEnforcementPass: final enforcement to set binder to 'level' for *_level targets.
 * - optionLevelAliasInjectionPass: clause-local alias fallback for 'level'.
 */
@:nullSafety(Off)
class OptionLevelBinderTransforms {
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

    public static function enforceLevelBinderForLevelTargetsPass(ast: ElixirAST): ElixirAST {
        inline function toSnake(s:String):String return reflaxe.elixir.ast.NameUtils.toSnakeCase(s);
        function renameBinder(p:EPattern, from:String, to:String):EPattern {
            return switch (p) {
                case PVar(n) if (n == from): PVar(to);
                case PTuple(list): PTuple([for (e in list) renameBinder(e, from, to)]);
                case PList(list): PList([for (e in list) renameBinder(e, from, to)]);
                case PCons(h,t): PCons(renameBinder(h, from, to), renameBinder(t, from, to));
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
                var targetName:Null<String> = null; switch (target.def) { case EVar(n): targetName = n; default: }
                var suffixLevel = false;
                if (targetName != null) {
                    var s = toSnake(targetName);
                    suffixLevel = (s != null && ~/.*_level$/.match(s));
                }
                if (suffixLevel) {
                    var newClauses = [];
                    for (cl in clauses) newClauses.push({ pattern: cl.pattern, guard: cl.guard, body: BinderAliasTransforms.optionBinderConsistencyPass(cl.body) });
                    return makeASTWithMeta(ECase(BinderAliasTransforms.optionBinderConsistencyPass(target), newClauses), ast.metadata, ast.pos);
                }
                makeASTWithMeta(ECase(ElixirASTTransformer.transformAST(target, enforceLevelBinderForLevelTargetsPass), clauses.map(c -> {
                    return { pattern: c.pattern, guard: c.guard, body: enforceLevelBinderForLevelTargetsPass(c.body) };
                })), ast.metadata, ast.pos);
            default:
                ElixirASTTransformer.transformAST(ast, enforceLevelBinderForLevelTargetsPass);
        };
    }

    public static function forceOptionLevelBinderWhenBodyUsesLevelPass(ast: ElixirAST): ElixirAST {
        inline function bodyUses(n:ElixirAST, name:String):Bool {
            var found = false;
            function walk(x:ElixirAST):Void {
                if (x == null || found) return;
                switch (x.def) {
                    case EVar(v) if (v == name): found = true;
                    default: iterate(x, walk);
                }
            }
            walk(n);
            return found;
        }
        function renameBinder(p:EPattern, from:String, to:String):EPattern {
            return switch (p) {
                case PVar(n) if (n == from): PVar(to);
                case PTuple(list): PTuple([for (e in list) renameBinder(e, from, to)]);
                case PList(list): PList([for (e in list) renameBinder(e, from, to)]);
                case PCons(h,t): PCons(renameBinder(h, from, to), renameBinder(t, from, to));
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
                    switch (cl.pattern) {
                        case PTuple(elements) if (elements.length >= 2):
                            switch (elements[0]) {
                                case PLiteral({def: EAtom(a)}) if (a == "some" || a == "ok"):
                                    switch (elements[1]) {
                                        case PVar(b) if (bodyUses(cl.body, "level") && b != "level"):
                                            out = { pattern: renameBinder(cl.pattern, b, "level"), guard: cl.guard, body: cl.body };
                                        default:
                                    }
                                default:
                            }
                        default:
                    }
                    fixed.push(out);
                }
                makeASTWithMeta(ECase(forceOptionLevelBinderWhenBodyUsesLevelPass(target), fixed.map(c -> {
                    return { pattern: c.pattern, guard: c.guard, body: forceOptionLevelBinderWhenBodyUsesLevelPass(c.body) };
                })), ast.metadata, ast.pos);
            default:
                ElixirASTTransformer.transformAST(ast, forceOptionLevelBinderWhenBodyUsesLevelPass);
        };
    }

    public static function absoluteLevelBinderEnforcementPass(ast: ElixirAST): ElixirAST {
        inline function toSnake(name:String):String {
            return reflaxe.elixir.ast.NameUtils.toSnakeCase(name);
        }
        function renameBinder(p:EPattern, from:String, to:String):EPattern {
            return switch (p) {
                case PVar(n) if (n == from): PVar(to);
                case PTuple(list): PTuple([for (e in list) renameBinder(e, from, to)]);
                case PList(list): PList([for (e in list) renameBinder(e, from, to)]);
                case PCons(h,t): PCons(renameBinder(h, from, to), renameBinder(t, from, to));
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
                var targetName:Null<String> = null; switch (target.def) { case EVar(n): targetName = n; default: }
                if (targetName != null) {
                    var s = toSnake(targetName);
                    if (s != null && ~/.*_level$/.match(s)) {
                        var fixed:Array<ECaseClause> = [];
                        for (cl in clauses) {
                            var out = cl;
                            switch (cl.pattern) {
                                case PTuple(elements) if (elements.length >= 2):
                                    switch (elements[0]) {
                                        case PLiteral({def: EAtom(a)}) if (a == "some" || a == "ok"):
                                            switch (elements[1]) {
                                                case PVar(b) if (b != "level"): out = { pattern: renameBinder(cl.pattern, b, "level"), guard: cl.guard, body: cl.body };
                                                default:
                                            }
                                        default:
                                    }
                                default:
                            }
                            fixed.push(out);
                        }
                        return makeASTWithMeta(ECase(absoluteLevelBinderEnforcementPass(target), fixed.map(c -> {
                            return { pattern: c.pattern, guard: c.guard, body: absoluteLevelBinderEnforcementPass(c.body) };
                        })), ast.metadata, ast.pos);
                    }
                }
                ElixirASTTransformer.transformAST(ast, absoluteLevelBinderEnforcementPass);
            default:
                ElixirASTTransformer.transformAST(ast, absoluteLevelBinderEnforcementPass);
        };
    }

    public static function optionLevelAliasInjectionPass(ast: ElixirAST): ElixirAST {
        inline function bodyUses(n:ElixirAST, name:String):Bool {
            var found = false;
            function walk(x:ElixirAST):Void {
                if (x == null || found) return;
                switch (x.def) {
                    case EVar(v) if (v == name): found = true;
                    default: iterate(x, walk);
                }
            }
            walk(n);
            return found;
        }
        function injectAlias(body:ElixirAST, binder:String):ElixirAST {
            var aliasStmt = makeAST(EMatch(PVar("level"), makeAST(EVar(binder))));
            return switch (body.def) {
                case EBlock(stmts): makeAST(EBlock([aliasStmt].concat(stmts)));
                default: makeAST(EBlock([aliasStmt, body]));
            };
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
                                    switch (elements[1]) {
                                        case PVar(b) if (bodyUses(cl.body, "level") && b != "level"):
                                            out = { pattern: cl.pattern, guard: cl.guard, body: injectAlias(cl.body, b) };
                                        default:
                                    }
                                default:
                            }
                        default:
                    }
                    fixed.push(out);
                }
                makeASTWithMeta(ECase(OptionLevelBinderTransforms.optionLevelAliasInjectionPass(target), fixed.map(c -> {
                    return { pattern: c.pattern, guard: c.guard, body: OptionLevelBinderTransforms.optionLevelAliasInjectionPass(c.body) };
                })), ast.metadata, ast.pos);
            default:
                ElixirASTTransformer.transformAST(ast, optionLevelAliasInjectionPass);
        };
    }
}
#end
