package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ASTUtils;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * CaseOkBinderAlignTransforms
 *
 * WHAT
 * - Aligns `{:ok, var}` case binders to the meaningful local name used in the clause body,
 *   avoiding accidental picks like `socket`/`ok_value` and preventing
 *   undefined-var errors when the body refers to a different name.
 *
 * WHY
 * - Our enum pattern builder may choose generic names (e.g., `value`) or collision-safe
 *   variants (e.g., `ok_value`). When user code expects a semantic name in the body (like
 *   `result`), Elixir compilation fails because the binder and body references diverge.
 *
 * HOW
 * - For each case clause matching `{:ok, PVar(binder)}`, scan the body for lower-case local
 *   names. If there is exactly one undefined local reference in the body (after excluding
 *   env-like names and already-declared locals), rename the binder to that name and rewrite
 *   body references from the old binder to the new one.
 * - Skip renames when ambiguous to avoid changing semantics.
 */
class CaseOkBinderAlignTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case EDef(name, args, guards, body):
                    var argNames = argNameSet(args);
                    var newBody = alignInBody(body, argNames);
                    makeASTWithMeta(EDef(name, args, guards, newBody), node.metadata, node.pos);
                case EDefp(name, args, guards, body):
                    var argNamesForDefp = argNameSet(args);
                    var updatedBodyForDefp = alignInBody(body, argNamesForDefp);
                    makeASTWithMeta(EDefp(name, args, guards, updatedBodyForDefp), node.metadata, node.pos);
                default:
                    node;
            }
        });
    }

    static function argNameSet(args: Array<EPattern>): Map<String, Bool> {
        var s = new Map<String, Bool>();
        for (a in args) collectNames(a, s);
        return s;
    }
    static function collectNames(p: EPattern, acc: Map<String,Bool>): Void {
        switch (p) {
            case PVar(n) if (n != null): acc.set(n.toLowerCase(), true);
            case PTuple(es) | PList(es): for (e in es) collectNames(e, acc);
            case PCons(h, t): collectNames(h, acc); collectNames(t, acc);
            case PMap(kvs): for (kv in kvs) collectNames(kv.value, acc);
            case PStruct(_, fs): for (f in fs) collectNames(f.value, acc);
            case PPin(inner): collectNames(inner, acc);
            default:
        }
    }

    static inline function isEnvLike(n:String): Bool {
        return n == "socket" || n == "live_socket" || n == "livesocket" || n == "conn" || n == "params";
    }

    /**
     * WHAT (update October 2025)
     * - Tighten binder alignment to avoid renaming {:ok, binder} to names that are
     *   already declared within the clause body (e.g., updated_socket), which caused
     *   undefined-variable references when later statements relied on the original
     *   binder name.
     *
     * HOW
     * - Compute a set of body-local declared names (left-hand PVar/EVar from matches)
     *   and exclude them from candidate names when choosing the desired binder.
     * - Keep existing guards (skip env-like names such as socket/conn/params).
     */
    static function alignInBody(body: ElixirAST, funcArgs:Map<String,Bool>): ElixirAST {
        // Track sequential locals declared earlier in the same block so we never
        // rename a success binder to an outer-scope local (which would shadow and
        // change semantics). This is shape-based and avoids app-specific heuristics.
        var initialDeclared = new Map<String, Bool>();
        for (k in funcArgs.keys()) initialDeclared.set(k, true);
        return alignWithScope(body, funcArgs, initialDeclared);
    }

    static function alignWithScope(node: ElixirAST, funcArgs:Map<String,Bool>, declaredBefore:Map<String,Bool>): ElixirAST {
        if (node == null) return node;
        return switch (node.def) {
            case EBlock(stmts):
                var scope = cloneNameSet(declaredBefore);
                var out:Array<ElixirAST> = [];
                for (s in stmts) {
                    var ns = alignWithScope(s, funcArgs, scope);
                    out.push(ns);
                    collectDeclaredFromStatement(ns, scope);
                }
                makeASTWithMeta(EBlock(out), node.metadata, node.pos);
            case EDo(doStatements):
                var doScope = cloneNameSet(declaredBefore);
                var doOutput:Array<ElixirAST> = [];
                for (statement in doStatements) {
                    var rewrittenStatement = alignWithScope(statement, funcArgs, doScope);
                    doOutput.push(rewrittenStatement);
                    collectDeclaredFromStatement(rewrittenStatement, doScope);
                }
                makeASTWithMeta(EDo(doOutput), node.metadata, node.pos);
            case ECase(expr, clauses):
                var newExpr = alignWithScope(expr, funcArgs, declaredBefore);
                var outClauses:Array<ECaseClause> = [];
                for (c in clauses) outClauses.push(alignClause(c, funcArgs, declaredBefore));
                makeASTWithMeta(ECase(newExpr, outClauses), node.metadata, node.pos);
            default:
                ElixirASTTransformer.transformAST(node, function(child:ElixirAST):ElixirAST {
                    return alignWithScope(child, funcArgs, declaredBefore);
                });
        };
    }

    static function alignClause(cl:ECaseClause, funcArgs:Map<String,Bool>, declaredBefore:Map<String,Bool>): ECaseClause {
        var pattern = cl.pattern;
        var guard = cl.guard;
        var body = cl.body;

        switch (pattern) {
            case PTuple(els) if (els.length == 2):
                switch (els[0]) {
                    case PLiteral({def: EAtom(a)}) if ((a : String) == ":ok" || (a : String) == "ok"):
                        switch (els[1]) {
                            case PVar(oldName) if (oldName != null):
                                var desired = chooseDesiredName(body, oldName, funcArgs, declaredBefore);
                                if (desired != null && desired != oldName) {
                                    pattern = PTuple([els[0], PVar(desired)]);
                                    body = renameVarInBody(body, oldName, desired);
                                }
                            default:
                        }
                    default:
                }
            default:
        }

        // Recurse into guard/body with clause-local scope: outer locals + pattern binders.
        var clauseScope = cloneNameSet(declaredBefore);
        collectPatternDeclsLower(pattern, clauseScope);
        var newGuard = guard == null ? null : alignWithScope(guard, funcArgs, clauseScope);
        var newBody = alignWithScope(body, funcArgs, clauseScope);
        return { pattern: pattern, guard: newGuard, body: newBody };
    }

    static function chooseDesiredName(body: ElixirAST, current:String, funcArgs:Map<String,Bool>, declaredBefore:Map<String,Bool>): Null<String> {
        var currentLow = current.toLowerCase();

        // Declared in clause = outer declared + body LHS decls + pattern binder name
        var declaredInBody = collectDeclaredLocals(body);
        for (k in declaredBefore.keys()) declaredInBody.set(k, true);
        declaredInBody.set(currentLow, true);

        // Collect lowercase locals referenced in body that are NOT declared anywhere in-scope.
        var undefined:Array<String> = [];
        var seen = new Map<String,Bool>();
        ASTUtils.walk(body, function(n:ElixirAST) {
            switch (n.def) {
                case EVar(v) if (v != null):
                    // Only consider actual locals (lowercase start). Skip module-like refs.
                    var firstChar = v.charAt(0);
                    if (firstChar.toLowerCase() == firstChar) {
                        var vlow = v.toLowerCase();
                        if (!seen.exists(vlow) && allowLocalCandidate(vlow, currentLow, funcArgs) && !declaredInBody.exists(vlow)) {
                            seen.set(vlow, true);
                            undefined.push(vlow);
                        }
                    }
                default:
            }
        });

        // Only rename when unambiguous; otherwise skip to avoid changing semantics.
        return undefined.length == 1 ? undefined[0] : null;
    }

    static function collectDeclaredLocals(body: ElixirAST): Map<String,Bool> {
        var declared = new Map<String,Bool>();
        function collectFromPattern(p:EPattern):Void {
            switch (p) {
                case PVar(nm) if (nm != null): declared.set(nm.toLowerCase(), true);
                case PTuple(es) | PList(es): for (e in es) collectFromPattern(e);
                case PCons(h, t): collectFromPattern(h); collectFromPattern(t);
                case PMap(kvs): for (kv in kvs) collectFromPattern(kv.value);
                case PStruct(_, fs): for (f in fs) collectFromPattern(f.value);
                case PPin(inner): collectFromPattern(inner);
                default:
            }
        }
        ElixirASTTransformer.transformNode(body, function(x:ElixirAST):ElixirAST {
            switch (x.def) {
                case EMatch(p, _): collectFromPattern(p);
                case EBinary(Match, left, _):
                    switch (left.def) { case EVar(nm): if (nm != null) declared.set(nm.toLowerCase(), true); default: }
                default:
            }
            return x;
        });
        return declared;
    }

    static function renameVarInBody(body: ElixirAST, from:String, to:String): ElixirAST {
        if (from == null || to == null || from == to) return body;
        return ElixirASTTransformer.transformNode(body, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EVar(v) if (v == from): makeASTWithMeta(EVar(to), n.metadata, n.pos);
                default: n;
            }
        });
    }

    static inline function allowLocalCandidate(name:String, currentLow:String, funcArgs:Map<String,Bool>): Bool {
        if (name == null || name.length == 0) return false;
        if (name == currentLow) return false;
        if (isEnvLike(name)) return false;
        if (funcArgs.exists(name)) return false;
        var c = name.charAt(0);
        return c.toLowerCase() == c;
    }

    static function collectPatternDeclsLower(p:EPattern, out:Map<String,Bool>):Void {
        switch (p) {
            case PVar(nm) if (nm != null && nm.length > 0):
                out.set(nm.toLowerCase(), true);
            case PTuple(es) | PList(es):
                for (e in es) collectPatternDeclsLower(e, out);
            case PCons(h, t):
                collectPatternDeclsLower(h, out);
                collectPatternDeclsLower(t, out);
            case PMap(kvs):
                for (kv in kvs) collectPatternDeclsLower(kv.value, out);
            case PStruct(_, fs):
                for (f in fs) collectPatternDeclsLower(f.value, out);
            case PPin(inner):
                collectPatternDeclsLower(inner, out);
            default:
        }
    }

    static function collectDeclaredFromStatement(stmt:ElixirAST, out:Map<String,Bool>):Void {
        if (stmt == null) return;
        switch (stmt.def) {
            case EMatch(p, _):
                collectPatternDeclsLower(p, out);
            case EBinary(Match, left, _):
                switch (left.def) { case EVar(nm) if (nm != null): out.set(nm.toLowerCase(), true); default: }
            default:
        }
    }

    static function cloneNameSet(input:Map<String,Bool>): Map<String,Bool> {
        var out = new Map<String,Bool>();
        for (k in input.keys()) out.set(k, input.get(k));
        return out;
    }
}

#end
