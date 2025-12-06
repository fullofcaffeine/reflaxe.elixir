package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.VariableUsageCollector;

/**
 * EFnSingleArgUndefinedAlignTransforms
 *
 * WHAT
 * - Aligns single-argument anonymous function bodies to their binder when
 *   exactly one undefined body variable is present and the binder itself is
 *   not referenced. Rewrites occurrences of that single free variable to the
 *   binder name.
 *
 * WHY
 * - Hygiene: During complex lowerings, anonymous fn bodies can accidentally
 *   reference a non-existent local (e.g., `todo`) instead of the binder
 *   (`elem`). This leads to undefined-variable warnings at runtime. When the
 *   body contains exactly one such free variable and the binder is unused,
 *   it is safe and intention-revealing to align the body to the binder.
 *   Shape-based and name-agnostic, no app coupling.
 *
 * HOW
 * - For EFn with exactly one argument pattern PVar(binder):
 *   1) If the binder is referenced in body, skip.
 *   2) Collect body references with closure-aware VariableUsageCollector and
 *      remove names bound within the fn (args and inner pattern binds).
 *   3) If the remaining set of free variable names has size 1 (varX), and
 *      varX is a simple lowercase identifier (avoid atoms/modules), rewrite
 *      all occurrences of varX (EVar) in the body to the binder.
 *
 * EXAMPLES
 * Haxe:
 *   Enum.each(pending, fn elem -> todo.id end)
 * Elixir (before):
 *   Enum.each(pending, fn elem -> todo.id end)
 * Elixir (after):
 *   Enum.each(pending, fn elem -> elem.id end)
 */
class EFnSingleArgUndefinedAlignTransforms {
    public static function alignPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EFn(clauses):
                    var newClauses = [];
                    for (cl in clauses) {
                        // Only consider single-argument anonymous functions with simple PVar binder
                        var binderName: Null<String> = null;
                        if (cl.args != null && cl.args.length == 1) {
                            switch (cl.args[0]) {
                                case PVar(name): binderName = name;
                                case _: binderName = null;
                            }
                        }
                        if (binderName == null) {
                            newClauses.push(cl);
                            continue;
                        }
                        // Skip if binder already used in body
                        if (VariableUsageCollector.usedInFunctionScope(cl.body, binderName)) {
                            newClauses.push(cl);
                            continue;
                        }
                        // Compute free vars in body: referenced minus locally bound
                        var referenced = VariableUsageCollector.referencedInFunctionScope(cl.body);
                        var bound = collectLocallyBoundNames(cl);
                        // Remove bound and binderName itself
                        referenced.remove(binderName);
                        for (k in bound.keys()) referenced.remove(k);
                        // Count remaining lower-case free vars
                        var freeNames:Array<String> = [];
                        for (k in referenced.keys()) if (looksLikeVar(k)) freeNames.push(k);
                        #if debug_efn_align
                        // DISABLED: trace('[EFnSingleArgUndefinedAlign] binder=' + binderName + ' freeNames={' + freeNames.join(',') + '}');
                        #end
                        if (freeNames.length == 1) {
                            var victim = freeNames[0];
                            var newBody = renameVarInNode(cl.body, victim, binderName);
                            #if debug_efn_align
                            // DISABLED: trace('[EFnSingleArgUndefinedAlign] Rewriting free var ' + victim + ' -> ' + binderName);
                            #end
                            newClauses.push({args: cl.args, guard: cl.guard, body: newBody});
                        } else {
                            newClauses.push(cl);
                        }
                    }
                    makeASTWithMeta(EFn(newClauses), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function looksLikeVar(name:String):Bool {
        if (name == null || name.length == 0) return false;
        // lower-case start, avoid leading underscore and module-like (Foo.Bar)
        var c = name.charAt(0);
        if (c == '_' || c.toLowerCase() != c) return false;
        return name.indexOf('.') == -1; // not a module
    }

    static function collectLocallyBoundNames(clause: {args:Array<EPattern>, guard:Null<ElixirAST>, body:ElixirAST}): Map<String, Bool> {
        var m = new Map<String, Bool>();
        // Arg pattern binds
        if (clause.args != null) for (a in clause.args) for (k in collectPatternVars(a).keys()) m.set(k, true);
        // Inner pattern binds within the body (case/with/receive/match LHS)
        function walk(n: ElixirAST): Void {
            if (n == null || n.def == null) return;
            switch (n.def) {
                case EMatch(pat, _): for (k in collectPatternVars(pat).keys()) m.set(k, true);
                case ECase(_, cs): for (c in cs) for (k in collectPatternVars(c.pattern).keys()) m.set(k, true);
                case EReceive(cs, _): for (c in cs) for (k in collectPatternVars(c.pattern).keys()) m.set(k, true);
                case EWith(cs, _, _): for (c in cs) for (k in collectPatternVars(c.pattern).keys()) m.set(k, true);
                case EFn(inner): for (cc in inner) for (aa in cc.args) for (k in collectPatternVars(aa).keys()) m.set(k, true);
                case EBlock(sts) | EDo(sts): for (s in sts) walk(s);
                case EIf(c,t,e): walk(c); walk(t); if (e != null) walk(e);
                case ECall(t,_,as): if (t != null) walk(t); if (as != null) for (a in as) walk(a);
                case ERemoteCall(t2,_,as2): walk(t2); if (as2 != null) for (a in as2) walk(a);
                default:
            }
        }
        walk(clause.body);
        return m;
    }

    static function collectPatternVars(p:EPattern): Map<String, Bool> {
        var m = new Map<String, Bool>();
        function add(nm:String):Void {
            if (nm != null && nm.length > 0) m.set(nm, true);
        }
        function visit(pp:EPattern):Void {
            switch (pp) {
                case PVar(n): add(n);
                case PAlias(n, pat): add(n); visit(pat);
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

    static function renameVarInNode(node: ElixirAST, from: String, to: String): ElixirAST {
        return ElixirASTTransformer.transformNode(node, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EVar(name) if (name == from): makeASTWithMeta(EVar(to), n.metadata, n.pos);
                case ERaw(_): n; // don't touch raw code
                default: n;
            }
        });
    }
}

#end
