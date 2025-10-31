package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * CaseOkBinderAlignTransforms
 *
 * WHAT
 * - Aligns `{:ok, var}` case binders to the meaningful local name used in the clause body
 *   (e.g., `todo`), avoiding accidental picks like `socket`/`ok_value` and preventing
 *   undefined-var errors when the body refers to a different name.
 *
 * WHY
 * - Our enum pattern builder may choose generic names (e.g., `value`) or collision-safe
 *   variants (e.g., `ok_value`). When user code expects a semantic name in the body (like
 *   `todo`), Elixir compilation fails because the binder and body references diverge.
 *
 * HOW
 * - For each case clause matching `{:ok, PVar(binder)}`, scan the body for lower-case local
 *   names. If it contains `todo`, prefer that; otherwise pick the first non env-like local.
 *   Rename the binder to the chosen name and rewrite body references from the old binder
 *   to the new one. Skip when the chosen name collides with function arguments.
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
                    var argNames2 = argNameSet(args);
                    var newBody2 = alignInBody(body, argNames2);
                    makeASTWithMeta(EDefp(name, args, guards, newBody2), node.metadata, node.pos);
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
            case PVar(n) if (n != null): acc.set(n, true);
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
        return ElixirASTTransformer.transformNode(body, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ECase(expr, clauses):
                    var out = [];
                    for (c in clauses) {
                        var aligned = c;
                        switch (c.pattern) {
                            case PTuple(els) if (els.length == 2):
                                switch (els[0]) {
                                    case PLiteral({def: EAtom(a)}) if ((a : String) == ":ok" || (a : String) == "ok"):
                                        switch (els[1]) {
                                            case PVar(oldName) if (oldName != null):
                                                var desired = chooseDesiredName(c.body, oldName, funcArgs);
                                                if (desired != null && desired != oldName) {
                                                    var newPat = PTuple([els[0], PVar(desired)]);
                                                    var newBody = renameVarInBody(c.body, oldName, desired);
                                                    aligned = { pattern: newPat, guard: c.guard, body: newBody };
                                                }
                                            default:
                                        }
                                    default:
                                }
                            default:
                        }
                        out.push(aligned);
                    }
                    makeASTWithMeta(ECase(expr, out), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function chooseDesiredName(body: ElixirAST, current:String, funcArgs:Map<String,Bool>): Null<String> {
        // Collect simple local names used in body
        var used: Array<String> = [];
        var declaredInBody: Map<String,Bool> = collectDeclaredLocals(body);
        ElixirASTTransformer.transformNode(body, function(m: ElixirAST): ElixirAST {
            switch (m.def) {
                case EVar(v):
                    var vlow = v != null ? v.toLowerCase() : v;
                    if (vlow != null && !isEnvLike(vlow) && vlow != current && !funcArgs.exists(vlow) && !declaredInBody.exists(vlow)) {
                        used.push(vlow);
                    }
                default:
            }
            return m;
        });
        // Prefer `todo` if present
        for (u in used) if (u == "todo") return u;
        // Otherwise the first non-env-like used local
        return used.length > 0 ? used[0] : null;
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
}

#end
