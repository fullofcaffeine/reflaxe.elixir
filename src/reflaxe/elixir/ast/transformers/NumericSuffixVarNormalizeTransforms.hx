package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * NumericSuffixVarNormalizeTransforms
 *
 * WHAT
 * - Eliminates numeric suffixes from local variable binders and references
 *   (e.g., g2 -> g, entry3 -> entry) within well-defined scopes.
 *   Conservative gating prevents renaming when digits are part of the
 *   original identifier (e.g., user_id1, html_element5) by requiring
 *   evidence that the base name is relevant in-scope.
 * - Applies to function parameters, local matches, case clause patterns,
 *   and anonymous function parameters and bodies.
 *
 * WHY
 * - Compiler hygiene may introduce numeric suffixes to disambiguate names.
 *   Our style guide forbids numeric suffixes and prefers descriptive names.
 *   This pass normalizes names to their base form without digits whenever
 *   safe (no collisions), or uses a descriptive fallback suffix (e.g., _next,
 *   _alt) instead of numbers.
 *
 * HOW
 * - For each scope (EDef/EDefp/EFn clause/Case clause):
 *   1) Collect currently bound names in the scope.
 *   2) For any newly bound name matching /^(?:_)?[a-z][a-z0-9_]*\d+$/:
 *      - Only consider normalization if the base (digits stripped) is either
 *        referenced in the function body or also declared in the same scope.
 *        This distinguishes Haxe-introduced numeric suffixes from intentional
 *        identifiers that include digits.
 *      - If base is free, rename binder to base; otherwise choose a descriptive
 *        alternative (base_value/base_entry/base_next/...) that avoids numbers.
 *   3) Rewrite all EVar references in the corresponding body using the computed map.
 * - Module names and atoms are never touched (we only rewrite lower-case EVar/PVar).
 *
 * EXAMPLES
 * Before (case clause):
 *   case color do
 *     {:ok, g2} -> g2 + 1
 *   end
 * After:
 *   case color do
 *     {:ok, g} -> g + 1
 *   end
 */
class NumericSuffixVarNormalizeTransforms {
    public static function normalizePass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, params, guards, body):
                    var res = normalizeFunctionScope(params, body);
                    makeASTWithMeta(EDef(name, res.params, guards, res.body), n.metadata, n.pos);
                case EDefp(name, privateParams, privateGuards, privateBody):
                    var privateResult = normalizeFunctionScope(privateParams, privateBody);
                    makeASTWithMeta(EDefp(name, privateResult.params, privateGuards, privateResult.body), n.metadata, n.pos);
                case ECase(expr, clauses):
                    var newClauses = new Array<{ pattern:EPattern, guard:Null<ElixirAST>, body:ElixirAST }>();
                    for (cl in clauses) {
                        var declared = collectPatternVars(cl.pattern);
                        // Consider both guard and body references to decide if base names are desired
                        var refScope = (cl.guard == null)
                            ? cl.body
                            : makeASTWithMeta(EBlock([cl.guard, cl.body]), {}, cl.body.pos);
                        var refs = reflaxe.elixir.ast.analyzers.VariableUsageCollector.referencedInFunctionScope(refScope);
                        var rename = computeNumericRenamesGated(declared, refs);
                        var newPattern = renamePattern(cl.pattern, rename);
                        var newBody = renameBodyVars(cl.body, rename);
                        var newGuard = (cl.guard == null) ? null : renameBodyVars(cl.guard, rename);
                        newClauses.push({ pattern: newPattern, guard: newGuard, body: newBody });
                    }
                    makeASTWithMeta(ECase(expr, newClauses), n.metadata, n.pos);
                case EFn(clauses):
                    var out = [];
                    for (cl in clauses) {
                        var paramVars = new Map<String,Bool>();
                        for (a in cl.args) for (nm in collectPatternVars(a).keys()) paramVars.set(nm, true);
                        var refs = reflaxe.elixir.ast.analyzers.VariableUsageCollector.referencedInFunctionScope(cl.body);
                        var rename = computeNumericRenamesGated(paramVars, refs);
                        out.push({ args: [for (a in cl.args) renamePattern(a, rename)], guard: cl.guard, body: renameBodyVars(cl.body, rename) });
                    }
                    makeASTWithMeta(EFn(out), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function normalizeFunctionScope(params:Array<EPattern>, body: ElixirAST): { params:Array<EPattern>, body:ElixirAST } {
        // Gather declared names from params
        var declared = new Map<String,Bool>();
        for (p in params) for (k in collectPatternVars(p).keys()) declared.set(k, true);
        // Propose renames for numeric-suffixed declared names in params
        // Conservative gating: only rename when the base form is referenced or also declared.
        var __refs = reflaxe.elixir.ast.analyzers.VariableUsageCollector.referencedInFunctionScope(body);
        var paramRename = containsERaw(body) ? new Map<String,String>() : computeNumericRenamesGated(declared, __refs);
        var newParams = [for (p in params) renamePattern(p, paramRename)];

        // Extend declared with any new param names post-rename
        declared = new Map();
        for (p in newParams) for (k in collectPatternVars(p).keys()) declared.set(k, true);

        // Find new LHS local binds and compute renames for numeric-suffixed ones
        var bodyDecl = collectLocalBinds(body);
        // Exclude already-declared param names from renaming decisions (avoid collisions)
        for (k in declared.keys()) if (bodyDecl.exists(k)) bodyDecl.remove(k);
        var bodyRename = containsERaw(body) ? new Map<String,String>() : computeNumericRenamesGated(bodyDecl, __refs, declared);

        // Merge rename maps (params first, then body).
        var rename = new Map<String,String>();
        for (k in paramRename.keys()) rename.set(k, paramRename.get(k));
        for (k in bodyRename.keys()) rename.set(k, bodyRename.get(k));

        var newBody = renameBodyVars(body, rename);
        return { params: newParams, body: newBody };
    }

    // Collect variable names bound by patterns (PVar) from a pattern tree
    static function collectPatternVars(p: EPattern): Map<String,Bool> {
        var vars = new Map<String,Bool>();
        function walk(pt:EPattern):Void {
            switch (pt) {
                case PVar(n) if (isLowerName(n)): vars.set(n, true);
                case PTuple(es): for (e in es) walk(e);
                case PList(es): for (e in es) walk(e);
                case PCons(h, t): walk(h); walk(t);
                case PMap(kvs): for (kv in kvs) walk(kv.value);
                case PStruct(_, fs): for (f in fs) walk(f.value);
                case PPin(inner): walk(inner);
                default:
            }
        }
        if (p != null) walk(p);
        return vars;
    }

    // Collect variable names introduced by simple matches (lhs = ... or PVar = ...)
    static function collectLocalBinds(body: ElixirAST): Map<String,Bool> {
        var vars = new Map<String,Bool>();
        function walk(n: ElixirAST): Void {
            if (n == null || n.def == null) return;
            switch (n.def) {
                case EBinary(Match, left, _):
                    switch (left.def) { case EVar(v) if (isLowerName(v)): vars.set(v, true); default: }
                case EMatch(pat, _):
                    for (k in collectPatternVars(pat).keys()) vars.set(k, true);
                case EBlock(ss): for (s in ss) walk(s);
                case EDo(doStmts): for (s in doStmts) walk(s);
                case EIf(c,t,e): walk(c); walk(t); if (e != null) walk(e);
                case ECase(expr, clauses):
                    walk(expr);
                    for (c in clauses) {
                        for (k in collectPatternVars(c.pattern).keys()) vars.set(k, true);
                        if (c.guard != null) walk(c.guard);
                        walk(c.body);
                    }
                case EWith(clauses, doBlock, elseBlock):
                    for (wc in clauses) {
                        for (k in collectPatternVars(wc.pattern).keys()) vars.set(k, true);
                        walk(wc.expr);
                    }
                    walk(doBlock);
                    if (elseBlock != null) walk(elseBlock);
                case ECall(t, _, args): if (t != null) walk(t); for (a in args) walk(a);
                case ERemoteCall(m, _, remoteArgs): walk(m); for (a in remoteArgs) walk(a);
                case EList(items) | ETuple(items): for (i in items) walk(i);
                case EMap(pairs): for (p in pairs) { walk(p.key); walk(p.value); }
                default:
            }
        }
        walk(body);
        return vars;
    }

    // Conservative numeric-suffix normalization: only when base is present/referenced.
    static function computeNumericRenamesGated(toNormalize: Map<String,Bool>, refs: Map<String,Bool>, ?reserved: Map<String,Bool>): Map<String,String> {
        var rename = new Map<String,String>();
        var used = new Map<String,Bool>();
        for (k in toNormalize.keys()) used.set(k, true);
        if (reserved != null) for (k in reserved.keys()) used.set(k, true);

        for (k in toNormalize.keys()) {
            var split = splitNumericSuffix(k);
            if (split == null) continue;
            var base = split.base;
            var baseDeclared = used.exists(base);
            var baseReferenced = refs != null && refs.exists(base);
            if (!baseDeclared && !baseReferenced) continue; // keep original numeric name
            if (!used.exists(base)) {
                rename.set(k, base);
                used.remove(k); used.set(base, true);
            } else {
                var alt = firstAvailableAlt(base, used);
                if (alt != null) {
                    rename.set(k, alt);
                    used.remove(k); used.set(alt, true);
                }
            }
        }
        return rename;
    }

    static function renamePattern(p: EPattern, rename: Map<String,String>): EPattern {
        function tx(pt:EPattern):EPattern {
            return switch (pt) {
                case PVar(n) if (rename.exists(n)): PVar(rename.get(n));
                case PTuple(es): PTuple([for (e in es) tx(e)]);
                case PList(es): PList([for (e in es) tx(e)]);
                case PCons(h, t): PCons(tx(h), tx(t));
                case PMap(kvs): PMap([for (kv in kvs) { key: kv.key, value: tx(kv.value) }]);
                case PStruct(m, fs): PStruct(m, [for (f in fs) { key: f.key, value: tx(f.value) }]);
                case PPin(inner): PPin(tx(inner));
                default: pt;
            }
        }
        return tx(p);
    }

    static function renameBodyVars(body: ElixirAST, rename: Map<String,String>): ElixirAST {
        if (rename == null || Lambda.count(rename) == 0) return body;
        return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
            return switch (x.def) {
                case EVar(v) if (isLowerName(v) && rename.exists(v)):
                    makeASTWithMeta(EVar(rename.get(v)), x.metadata, x.pos);
                default:
                    x;
            }
        });
    }

    static function containsERaw(n: ElixirAST): Bool {
        var found = false;
        function walk(x: ElixirAST): Void {
            if (found || x == null || x.def == null) return;
            switch (x.def) {
                case ERaw(_): found = true;
                case EBlock(ss): for (s in ss) walk(s);
                case EDo(doStmts2): for (s in doStmts2) walk(s);
                case EIf(c,t,e): walk(c); walk(t); if (e != null) walk(e);
                case ECase(expr, clauses):
                    walk(expr);
                    for (c in clauses) { if (c.guard != null) walk(c.guard); walk(c.body); }
                case EWith(clauses, doBlock, elseBlock):
                    for (wc in clauses) { walk(wc.expr); }
                    walk(doBlock); if (elseBlock != null) walk(elseBlock);
                case ECall(t,_,as): if (t != null) walk(t); for (a in as) walk(a);
                case ERemoteCall(m,_,remoteArgs2): walk(m); for (a in remoteArgs2) walk(a);
                case EList(items) | ETuple(items): for (i in items) walk(i);
                case EMap(pairs): for (p in pairs) { walk(p.key); walk(p.value); }
                default:
            }
        }
        walk(n);
        return found;
    }

    static inline function isLowerName(n: String): Bool {
        return n != null && n.length > 0 && n.charAt(0).toLowerCase() == n.charAt(0);
    }

    static function splitNumericSuffix(name:String): Null<{ base:String, digits:String }>{
        if (name == null) return null;
        var re = ~/^(_?[a-z][a-z0-9_]*?)(\d+)$/;
        if (re.match(name)) {
            var base = re.matched(1);
            var digits = re.matched(2);
            return { base: base, digits: digits };
        }
        return null;
    }

    static function firstAvailableAlt(base:String, used: Map<String,Bool>): Null<String> {
        var candidates = [
            base + "_value",
            base + "_entry",
            base + "_next",
            base + "_alt",
            base + "_copy",
            base + "_new",
            base + "_item"
        ];
        for (c in candidates) if (!used.exists(c)) return c;
        // Last resort: add another descriptive suffix chain without numbers
        var fallback = base + "_value_alt";
        if (!used.exists(fallback)) return fallback;
        return null;
    }
}

#end
