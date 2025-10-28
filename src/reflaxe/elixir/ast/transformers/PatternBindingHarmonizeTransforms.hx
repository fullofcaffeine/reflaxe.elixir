package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * PatternBindingHarmonizeTransforms
 *
 * WHAT
 * - When a case clause pattern binds an underscore-prefixed variable (e.g., _value)
 *   but the clause body clearly uses exactly one undefined local (e.g., todo),
 *   rename the pattern binder to that local to harmonize names.
 *
 * WHY
 * - Upstream usage analysis can conservatively underscore binders. If the body
 *   unambiguously uses a single undefined local, the intent is clear and this
 *   produces idiomatic, consistent code while avoiding undefined-variable references.
 *
 * HOW
 * - For each ECase, compute:
 *   - bound names from the clause pattern (PVar only)
 *   - declared names in the clause body (left-hand of assignments and inner patterns)
 *   - referenced names (simple EVar) in the clause body
 *   - undefined = referenced \ (bound ∪ declared)
 *   If undefined has size 1 and the pattern contains an underscore-prefixed PVar,
 *   rewrite the first such PVar to the undefined name.
 */
class PatternBindingHarmonizeTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ECase(scrut, clauses):
                    var newClauses = [];
                    for (cl in clauses) {
                        var bound = collectPatternVars(cl.pattern);
                        var declared = collectDeclaredVars(cl.body);
                        var referenced = collectReferencedVars(cl.body);
                        var known = new Map<String,Bool>();
                        for (b in bound) known.set(b,true);
                        for (d in declared) known.set(d,true);
                        var undefined: Array<String> = [];
                        for (r in referenced) if (!known.exists(r) && isCandidate(r)) undefined.push(r);
                        var rewrittenPattern = cl.pattern;
                        if (undefined.length == 1 && hasUnderscoreBinder(cl.pattern)) {
                            // Prefer renaming the tagged payload binder {:tag, _x} when present
                            var renamedPayload = renameUnderscoredTaggedPayload(cl.pattern, undefined[0]);
                            rewrittenPattern = renamedPayload != null ? renamedPayload : renameFirstUnderscoreBinder(cl.pattern, undefined[0]);
                        }
                        newClauses.push({ pattern: rewrittenPattern, guard: cl.guard, body: cl.body });
                    }
                    makeASTWithMeta(ECase(scrut, newClauses), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function isCandidate(name:String):Bool {
        if (name == null || name.length == 0) return false;
        var c = name.charCodeAt(0);
        // must start lowercase or underscore-letter (but not plain underscore-only temp)
        return (c >= 'a'.code && c <= 'z'.code);
    }

    static function hasUnderscoreBinder(p:EPattern):Bool {
        var found = false;
        function walk(pt:EPattern):Void {
            if (found) return;
            switch (pt) {
                case PVar(n) if (n != null && n.length > 1 && n.charAt(0) == '_'): found = true;
                case PTuple(es): for (e in es) walk(e);
                case PList(es): for (e in es) walk(e);
                case PCons(h,t): walk(h); walk(t);
                case PMap(kvs): for (kv in kvs) walk(kv.value);
                case PStruct(_, fs): for (f in fs) walk(f.value);
                case PPin(inner): walk(inner);
                case PAlias(_, inner): walk(inner);
                default:
            }
        }
        walk(p);
        return found;
    }

    static function renameFirstUnderscoreBinder(p:EPattern, newName:String):EPattern {
        // Prefer renaming payload binder in tagged tuple {:tag, _x}
        switch (p) {
            case PTuple(es) if (es.length >= 2):
                switch (es[1]) {
                    case PVar(n) if (n != null && n.length > 1 && n.charAt(0) == '_'):
                        var copy = es.copy();
                        copy[1] = PVar(newName);
                        return PTuple(copy);
                    default:
                }
            default:
        }
        var done = false;
        function rw(pt:EPattern):EPattern {
            if (done) return pt;
            return switch (pt) {
                case PVar(n) if (n != null && n.length > 1 && n.charAt(0) == '_'):
                    done = true;
                    PVar(newName);
                case PTuple(es): PTuple([ for (e in es) rw(e) ]);
                case PList(es): PList([ for (e in es) rw(e) ]);
                case PCons(h,t): PCons(rw(h), rw(t));
                case PMap(kvs): PMap([ for (kv in kvs) { key: kv.key, value: rw(kv.value) } ]);
                case PStruct(mod, fs): PStruct(mod, [ for (f in fs) { key: f.key, value: rw(f.value) } ]);
                case PPin(inner): PPin(rw(inner));
                case PAlias(a, inner): PAlias(a, rw(inner));
                default: pt;
            }
        }
        return rw(p);
    }

    static function renameUnderscoredTaggedPayload(p:EPattern, newName:String):Null<EPattern> {
        return switch (p) {
            case PTuple(es) if (es.length >= 2):
                switch (es[1]) {
                    case PVar(n) if (n != null && n.length > 1 && n.charAt(0) == '_'):
                        var copy = es.copy();
                        copy[1] = PVar(newName);
                        PTuple(copy);
                    default: null;
                }
            default: null;
        }
    }

    static function collectPatternVars(p:EPattern):Array<String> {
        var out:Array<String> = [];
        function walk(pt:EPattern):Void {
            switch (pt) {
                case PVar(n) if (n != null && n.length > 0 && n.charAt(0) != '_'): out.push(n);
                case PTuple(es): for (e in es) walk(e);
                case PList(es): for (e in es) walk(e);
                case PCons(h,t): walk(h); walk(t);
                case PMap(kvs): for (kv in kvs) walk(kv.value);
                case PStruct(_, fs): for (f in fs) walk(f.value);
                case PPin(inner): walk(inner);
                case PAlias(a, inner): out.push(a); walk(inner);
                default:
            }
        }
        walk(p);
        return out;
    }

    static function collectDeclaredVars(body: ElixirAST):Array<String> {
        var out:Array<String> = [];
        ElixirASTTransformer.transformNode(body, function(n: ElixirAST):ElixirAST {
            switch (n.def) {
                case EMatch(pat, _):
                    // harvest PVar declarations in patterns
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

    static function collectReferencedVars(body: ElixirAST):Array<String> {
        var s = new Map<String,Bool>();
        ElixirASTTransformer.transformNode(body, function(n: ElixirAST):ElixirAST {
            switch (n.def) {
                case EVar(v) if (v != null && v.length > 0): s.set(v, true);
                default:
            }
            return n;
        });
        return [for (k in s.keys()) k];
    }
}

#end
