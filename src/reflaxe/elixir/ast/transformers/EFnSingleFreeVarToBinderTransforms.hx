package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.VariableUsageCollector;

/**
 * EFnSingleFreeVarToBinderTransforms
 *
 * WHAT
 * - In a single-argument anonymous function, if the body contains exactly one free, lowercase
 *   variable (not declared within the function), replace all occurrences of that variable with
 *   the binder name. Works even if the binder is already referenced in the body.
 *
 * WHY
 * - Some shapes accidentally reference an out-of-scope variable (e.g., `todo`) while the binder
 *   (e.g., `elem`) is present and used. This causes undefined-variable errors. Aligning the single
 *   free variable to the binder is safe and idiomatic when unambiguous.
 *
 * HOW
 * - For EFn with exactly one argument pattern PVar(binder):
 *   - Collect referenced variables in function scope (closure-aware).
 *   - Remove locally bound names (arguments and inner pattern binds).
 *   - If exactly one remaining name is a lowercase identifier (no module dots), rewrite EVar(name)
 *     to EVar(binder) in the body. Skip ERaw.
 */
class EFnSingleFreeVarToBinderTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EFn(clauses):
                    var out = [];
                    for (cl in clauses) out.push(rewriteClause(cl));
                    makeASTWithMeta(EFn(out), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function rewriteClause(cl: {args:Array<EPattern>, guard:Null<ElixirAST>, body:ElixirAST}): {args:Array<EPattern>, guard:Null<ElixirAST>, body:ElixirAST} {
        var binder: Null<String> = null;
        if (cl.args != null && cl.args.length == 1) switch (cl.args[0]) { case PVar(n): binder = n; default: }
        if (binder == null) return cl;
        var referenced = VariableUsageCollector.referencedInFunctionScope(cl.body);
        var bound = collectLocallyBoundNames(cl);
        referenced.remove(binder);
        for (k in bound.keys()) referenced.remove(k);
        var freeNames:Array<String> = [];
        for (k in referenced.keys()) if (looksLikeVar(k)) freeNames.push(k);
        if (freeNames.length != 1) return cl;
        var victim = freeNames[0];
        #if sys Sys.println('[EFnSingleFreeVarToBinder] Rewriting free var ' + victim + ' -> ' + binder); #end
        var newBody = renameVarInNode(cl.body, victim, binder);
        return { args: cl.args, guard: cl.guard, body: newBody };
    }

    static function looksLikeVar(name:String):Bool {
        if (name == null || name.length == 0) return false;
        var c = name.charAt(0);
        if (c == '_' || c.toLowerCase() != c) return false;
        return name.indexOf('.') == -1;
    }

    static function collectLocallyBoundNames(clause: {args:Array<EPattern>, guard:Null<ElixirAST>, body:ElixirAST}): Map<String, Bool> {
        var m = new Map<String, Bool>();
        if (clause.args != null) for (a in clause.args) for (k in collectPatternVars(a).keys()) m.set(k, true);
        function walk(n: ElixirAST): Void {
            if (n == null || n.def == null) return;
            switch (n.def) {
                case EMatch(p, _): for (k in collectPatternVars(p).keys()) m.set(k, true);
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
        function add(nm:String):Void { if (nm != null && nm.length > 0) m.set(nm, true); }
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
                case ERaw(_): n;
                default: n;
            }
        });
    }
}

#end
