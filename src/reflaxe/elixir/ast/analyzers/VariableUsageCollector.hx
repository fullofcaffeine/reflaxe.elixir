package reflaxe.elixir.ast.analyzers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;

/**
 * VariableUsageCollector
 *
 * WHAT
 * - Closure-aware variable usage analysis for EDef/EDefp/EFn scopes. Collects
 *   references that belong to the current function scope, excluding occurrences
 *   shadowed by inner anonymous function binders or pattern-bindings.
 *
 * WHY
 * - Hygiene passes (underscore unused, ref/decl alignment, fallback fixes) need
 *   accurate reference sets. Naive scanners treat any EVar("name") in nested
 *   closures as a use of the outer variable, causing false positives like
 *   renaming outer `_t` because an EFn has `fn t -> ... end`. This breaks
 *   loop bodies (undefined `_elem`) and Ecto pins (binder misuse).
 *
 * HOW
 * - referencedInFunctionScope(body): returns names referenced from the current
 *   function body, counting free variable uses inside nested closures while
 *   excluding names bound by those closures or by pattern-bindings in case/with/
 *   receive clauses and for-generators.
 * - usedInFunctionScope(body, name): convenience wrapper over the above.
 *
 * EXAMPLES
 * Haxe (conceptual):
 *   def f(t) do
 *     Enum.map(xs, fn t -> t + 1 end) # inner t shadows outer t
 *   end
 * Elixir refs (before collector): {"t"}
 * Elixir refs (collector): {}         # inner t is shadowed, outer t unused
 *
 * Haxe (conceptual):
 *   def f(elem) do
 *     Enum.reduce(items, [], fn acc -> acc ++ [render(elem)] end)
 *   end
 * Elixir refs (collector): {"elem"}   # `elem` used free in nested fn
 */
class VariableUsageCollector {
    /** Return set of variable names referenced from the current function scope. */
    public static function referencedInFunctionScope(body: ElixirAST): Map<String, Bool> {
        var refs = new Map<String, Bool>();
        // Shadow-set holds names that are locally bound and therefore should not
        // be counted as references to the outer function scope when seen.
        var empty = new Map<String, Bool>();
        walk(body, empty, refs);
        return refs;
    }

    /** True when `name` is referenced from the current function scope. */
    public static function usedInFunctionScope(body: ElixirAST, name: String): Bool {
        if (name == null || name.length == 0) return false;
        var refs = referencedInFunctionScope(body);
        return refs.exists(name);
    }

    // ------------------------ Internals ------------------------

    static function walk(n: ElixirAST, shadowed: Map<String, Bool>, refs: Map<String, Bool>): Void {
        if (n == null || n.def == null) return;
        switch (n.def) {
            // References
            case EVar(v):
                if (!shadowed.exists(v)) refs.set(v, true);

            // Do not treat LHS as reference; only RHS can reference
            case EBinary(Match, left, rhs):
                walk(rhs, shadowed, refs);
            case EMatch(_, rhsExpr):
                walk(rhsExpr, shadowed, refs);

            // Blocks / groups
            case EBlock(stmts):
                for (s in stmts) walk(s, shadowed, refs);
            case EDo(statements):
                for (s in statements) walk(s, shadowed, refs);
            case EParen(e):
                walk(e, shadowed, refs);
            case EPipe(l, r):
                walk(l, shadowed, refs); walk(r, shadowed, refs);

            // Control flow
            case EIf(c,t,e):
                walk(c, shadowed, refs); walk(t, shadowed, refs); if (e != null) walk(e, shadowed, refs);
            case EUnless(c, b, e):
                walk(c, shadowed, refs); walk(b, shadowed, refs); if (e != null) walk(e, shadowed, refs);

            // Case/Receive: pattern binds names visible within guard/body
            case ECase(expr, clauses):
                walk(expr, shadowed, refs);
                for (cl in clauses) {
                    var add = collectPatternVars(cl.pattern);
                    var next = extendShadow(shadowed, add);
                    if (cl.guard != null) walk(cl.guard, next, refs);
                    walk(cl.body, next, refs);
                }
            case EReceive(clauses, after):
                for (cl in clauses) {
                    var add = collectPatternVars(cl.pattern);
                    var next = extendShadow(shadowed, add);
                    walk(cl.body, next, refs);
                }
                if (after != null) walk(after.body, shadowed, refs);

            // With: each clause pattern binds names; these are visible in do/else
            case EWith(clauses, doBlock, elseBlock):
                var accum = cloneShadow(shadowed);
                for (wc in clauses) {
                    // The expression may reference outer vars
                    walk(wc.expr, accum, refs);
                    // Pattern binds new names for subsequent clauses and do/else
                    var add = collectPatternVars(wc.pattern);
                    for (k in add.keys()) accum.set(k, true);
                }
                walk(doBlock, accum, refs);
                if (elseBlock != null) walk(elseBlock, accum, refs);

            // For/comprehension: generator pattern binds names for filters/body
            case EFor(gens, filters, body, into, _uniq):
                var accum = cloneShadow(shadowed);
                for (g in gens) {
                    walk(g.expr, accum, refs);
                    var add = collectPatternVars(g.pattern);
                    for (k in add.keys()) accum.set(k, true);
                }
                for (f in filters) walk(f, accum, refs);
                if (body != null) walk(body, accum, refs);
                if (into != null) walk(into, shadowed, refs);

            // Pin operator: inner can reference vars
            case EPin(inner):
                walk(inner, shadowed, refs);

            // Calls / data structures
            case ECall(tgt, _, args):
                if (tgt != null) walk(tgt, shadowed, refs);
                for (a in args) walk(a, shadowed, refs);
            case ERemoteCall(targetExpr, _, argsList):
                walk(targetExpr, shadowed, refs);
                for (a in argsList) walk(a, shadowed, refs);
            case EField(obj, _):
                walk(obj, shadowed, refs);
            case EAccess(objectExpr, key):
                walk(objectExpr, shadowed, refs); walk(key, shadowed, refs);
            case EKeywordList(pairs):
                for (p in pairs) walk(p.value, shadowed, refs);
            case EMap(pairs):
                for (p in pairs) { walk(p.key, shadowed, refs); walk(p.value, shadowed, refs); }
            case EStructUpdate(base, fields):
                walk(base, shadowed, refs); for (f in fields) walk(f.value, shadowed, refs);
            case ETuple(elems) | EList(elems):
                for (e in elems) walk(e, shadowed, refs);

            // Anonymous functions: binder args shadow same-named outer vars
            case EFn(clauses):
                for (cl in clauses) {
                    var add = collectArgVars(cl.args);
                    var next = extendShadow(shadowed, add);
                    if (cl.guard != null) walk(cl.guard, next, refs);
                    walk(cl.body, next, refs);
                }

            // Try/catch/rescue: patterns bind vars within respective bodies
            case ETry(body, rescueClauses, catchClauses, afterBlock, elseBlock):
                walk(body, shadowed, refs);
                if (rescueClauses != null) for (rc in rescueClauses) {
                    var add = collectPatternVars(rc.pattern);
                    var next = extendShadow(shadowed, add);
                    walk(rc.body, next, refs);
                }
                if (catchClauses != null) for (cc in catchClauses) {
                    var add = collectPatternVars(cc.pattern);
                    var next = extendShadow(shadowed, add);
                    walk(cc.body, next, refs);
                }
                if (afterBlock != null) walk(afterBlock, shadowed, refs);
                if (elseBlock != null) walk(elseBlock, shadowed, refs);

            // Ignore raw literals and strings for now; ERaw/ESigil usage is handled by
            // transform-specific heuristics when needed.
            default:
        }
    }

    static function extendShadow(base: Map<String, Bool>, add: Map<String, Bool>): Map<String, Bool> {
        var m = cloneShadow(base);
        for (k in add.keys()) m.set(k, true);
        return m;
    }

    static function cloneShadow(m: Map<String, Bool>): Map<String, Bool> {
        var n = new Map<String, Bool>();
        for (k in m.keys()) n.set(k, true);
        return n;
    }

    static function collectArgVars(args: Array<EPattern>): Map<String, Bool> {
        var m = new Map<String, Bool>();
        for (a in args) for (k in collectPatternVars(a).keys()) m.set(k, true);
        return m;
    }

    static function collectPatternVars(p: EPattern): Map<String, Bool> {
        var m = new Map<String, Bool>();
        function add(nm: String): Void {
            if (nm == null) return;
            // Shadow exactly the bound name; do not map underscore/base variants.
            // In Elixir, `name` and `_name` are distinct variables; referencing `name`
            // when `_name` is bound should be considered a free use of `name`.
            m.set(nm, true);
        }
        function visit(pp: EPattern): Void {
            switch (pp) {
                case PVar(n): add(n);
                case PAlias(varName, pat): add(varName); visit(pat);
                case PTuple(es): for (e in es) visit(e);
                case PList(es): for (e in es) visit(e);
                case PCons(h, t): visit(h); visit(t);
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
}

#end
