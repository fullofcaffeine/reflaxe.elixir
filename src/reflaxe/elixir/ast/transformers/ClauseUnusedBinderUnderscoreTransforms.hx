package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

/**
 * ClauseUnusedBinderUnderscoreTransforms
 *
 * WHAT
 * - Prefix unused clause-binder variables with underscore to silence compiler warnings
 *   while preserving readability and scope.
 *
 * WHY
 * - Haxe-generated patterns may bind variables not referenced in the clause body.
 *   Elixir warns on unused vars; adding underscore is idiomatic.
 *
 * HOW
 * - For each case clause, collect body-used names, compare against pattern binders,
 *   and rewrite unused PVar(name) -> PVar("_" + name).
 *
 * EXAMPLES
 * Before: case x do {a, b} -> a end
 * After:  case x do {a, _b} -> a end
 */
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ClauseUnusedBinderUnderscoreTransforms
 *
 * WHAT
 * - Prefix unused case-pattern binders with underscore in a clause when they are
 *   not referenced in the clause body, eliminating unused-variable warnings.
 *
 * WHY
 * - Patterns like {:ok, value} frequently bind variables that the body does not use.
 *   Elixir warns on unused variables unless prefixed with underscore. This is generic
 *   and not app-specific.
 *
 * HOW
 * - For each ECase clause, collect pattern binders and body variable uses. For each
 *   binder not present in body uses, rename PVar(name) to PVar("_" + name).
 */
class ClauseUnusedBinderUnderscoreTransforms {
    public static function clauseUnusedBinderUnderscorePass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case ECase(target, clauses):
                    var newClauses = [];
                    for (cl in clauses) {
                        var binders = collectPatternBinders(cl.pattern);
                        var used = collectUsedVars(cl.body);
                        // Treat EString/ERaw interpolations ("#{name}") as usage as well
                        for (b in binders) if (!arrayContains(used, b) && stringInterpolatesName(cl.body, b)) used.push(b);

                        // Compute clause-local declared names from pattern and simple matches
                        var declared = collectDeclaredVars(cl.body);
                        for (b in binders) if (!arrayContains(declared, b)) declared.push(b);

                        // Identify sole undefined lower-case local used in body
                        var undefined:Array<String> = [];
                        for (u in used) if (!arrayContains(declared, u) && isLower(u)) undefined.push(u);

                        var newPat = cl.pattern;
                        // If there is exactly one undefined and pattern is {:tag, PVar(b)}
                        // prefer harmonizing binder to that undefined name instead of underscoring
                        if (undefined.length == 1) {
                            var target = undefined[0];
                            var renamed = renameTaggedPayloadBinder(newPat, target);
                            if (renamed != null) newPat = renamed;
                        } else {
                            // Otherwise underscore truly unused binders
                            var unused = [for (b in binders) if (used.indexOf(b) == -1) b];
                            newPat = (unused.length > 0) ? underscoreBinders(newPat, unused) : newPat;
                            #if debug_hygiene
                            if (unused.length > 0) {
                            }
                            #end
                        }
                        newClauses.push({ pattern: newPat, guard: cl.guard, body: cl.body });
                    }
                    makeASTWithMeta(ECase(target, newClauses), node.metadata, node.pos);
                default:
                    node;
            }
        });
    }

    static function underscoreBinders(p: EPattern, names: Array<String>): EPattern {
        return switch (p) {
            case PVar(n):
                if (names.indexOf(n) != -1 && n.charAt(0) != "_") PVar("_" + n) else p;
            case PTuple(es): PTuple([for (e in es) underscoreBinders(e, names)]);
            case PList(es): PList([for (e in es) underscoreBinders(e, names)]);
            case PCons(h, t): PCons(underscoreBinders(h, names), underscoreBinders(t, names));
            case PMap(kvs): PMap([for (kv in kvs) { key: kv.key, value: underscoreBinders(kv.value, names) }]);
            case PStruct(nm, fs): PStruct(nm, [for (f in fs) { key: f.key, value: underscoreBinders(f.value, names) }]);
            case PPin(inner): PPin(underscoreBinders(inner, names));
            default: p;
        }
    }

    static function collectPatternBinders(p: EPattern): Array<String> {
        var out: Array<String> = [];
        function walk(px: EPattern) {
            switch (px) {
                case PVar(n): out.push(n);
                case PTuple(es): for (e in es) walk(e);
                case PList(es): for (e in es) walk(e);
                case PCons(h, t): walk(h); walk(t);
                case PMap(kvs): for (kv in kvs) walk(kv.value);
                case PStruct(_, fs): for (f in fs) walk(f.value);
                case PPin(inner): walk(inner);
                default:
            }
        }
        walk(p);
        return out;
    }

    static function collectUsedVars(body: ElixirAST): Array<String> {
        var names = new Map<String, Bool>();
        // Include builder-provided metadata when present
        try {
            var meta:Dynamic = body.metadata;
            if (meta != null && untyped meta.usedLocalsFromTyped != null) {
                var arr:Array<String> = untyped meta.usedLocalsFromTyped;
                for (n in arr) if (n != null && n.length > 0) names.set(n, true);
            }
        } catch (e:Dynamic) {}
        ElixirASTTransformer.transformNode(body, function(n: ElixirAST): ElixirAST {
            switch (n.def) {
                case EVar(v): names.set(v, true);
                default:
            }
            return n;
        });
        return [for (k in names.keys()) k];
    }

    static function arrayContains(a:Array<String>, s:String):Bool {
        for (x in a) if (x == s) return true; return false;
    }

    static inline function isLower(s:String):Bool {
        if (s == null || s.length == 0) return false;
        var c = s.charAt(0);
        return c.toLowerCase() == c;
    }

    static function collectDeclaredVars(body: ElixirAST): Array<String> {
        var out:Array<String> = [];
        ElixirASTTransformer.transformNode(body, function(n: ElixirAST):ElixirAST {
            switch (n.def) {
                case EMatch(pat, _):
                    // harvest simple PVar
                    function pv(pt:EPattern):Void {
                        switch (pt) {
                            case PVar(name) if (name != null && name.length > 0): out.push(name);
                            case PTuple(es): for (e in es) pv(e);
                            case PList(es): for (e in es) pv(e);
                            case PCons(h,t): pv(h); pv(t);
                            case PMap(kvs): for (kv in kvs) pv(kv.value);
                            case PStruct(_, fs): for (f in fs) pv(f.value);
                            case PPin(inner): pv(inner);
                            case PAlias(a, inner): out.push(a); pv(inner);
                            default:
                        }
                    }
                    pv(pat);
                case EBinary(Match, {def: EVar(lhs)}, _): out.push(lhs);
                default:
            }
            return n;
        });
        return out;
    }

    static function renameTaggedPayloadBinder(p:EPattern, newName:String):Null<EPattern> {
        return switch (p) {
            case PTuple(es) if (es.length == 2):
                switch (es[0]) {
                    case PLiteral(_):
                        switch (es[1]) {
                            case PVar(old) if (old != newName): PTuple([es[0], PVar(newName)]);
                            default: null;
                        }
                    default: null;
                }
            default: null;
        }
    }

    static function stringInterpolatesName(body: ElixirAST, name: String): Bool {
        var found = false;
        function visit(n: ElixirAST):Void {
            if (found || n == null || n.def == null) return;
            switch (n.def) {
                case EString(v):
                    if (v != null && name != null && v.indexOf("#{" + name) != -1) found = true;
                case ERaw(code):
                    if (code != null && name != null && code.indexOf("#{" + name) != -1) found = true;
                case EBlock(ss): for (s in ss) visit(s);
                case EIf(c,t,e): visit(c); visit(t); if (e != null) visit(e);
                case EBinary(_, l, r): visit(l); visit(r);
                case EMatch(_, rhs): visit(rhs);
                case ECall(tgt, _, args): if (tgt != null) visit(tgt); for (a in args) visit(a);
                case ERemoteCall(t2, _, args2): visit(t2); for (a2 in args2) visit(a2);
                case ECase(expr, cs): visit(expr); for (c in cs) visit(c.body);
                default:
            }
        }
        visit(body);
        return found;
    }
}

#end
