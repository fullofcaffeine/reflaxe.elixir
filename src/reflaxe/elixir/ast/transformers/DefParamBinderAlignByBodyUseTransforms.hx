package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.VariableUsageCollector;

/**
 * DefParamBinderAlignByBodyUseTransforms
 *
 * WHAT
 * - Aligns def/defp parameter binders with actual body usage by promoting
 *   underscored parameters to their base names when the base name is referenced
 *   in the body (including as a free variable inside nested closures).
 * - Also rewrites body references to the underscored variant to the promoted
 *   base name to avoid mixed naming.
 *
 * WHY
 * - Safety/idiom: Generated stdlib modules may introduce `_param` binders to
 *   silence unused warnings, but later transformations/reference in the body
 *   may use `param`. This causes undefined-variable errors under
 *   warnings-as-errors. Aligning binders to usage keeps code correct and clean.
 *
 * HOW
 * - For each EDef/EDefp:
 *   1) Collect parameter names and compute a rename map for PVar("_name")
 *      when VariableUsageCollector.usedInFunctionScope(body, "name") is true
 *      and no PVar("name") parameter exists.
 *   2) Apply rename map to parameter patterns (only PVar positions affected).
 *   3) Apply rename map to body variable references EVar("_name") → EVar("name").
 *
 * EXAMPLES
 * Before:
 *   def trace(_v, _infos) do
 *     IO.inspect(v)
 *   end
 * After:
 *   def trace(v, infos) do
 *     IO.inspect(v)
 *   end
 */
class DefParamBinderAlignByBodyUseTransforms {
    public static function alignPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case EDef(name, params, guards, body):
                    var rename = computeParamPromotions(params, body);
                    #if debug_ast_transformer
                    if (Lambda.count(rename) > 0) trace('[DefParamBinderAlignByBodyUse] ' + [for (k in rename.keys()) k + '->' + rename.get(k)].join(', '));
                    #end
                    if (Lambda.count(rename) == 0) return node;
                    var newParams = renameParams(params, rename);
                    var newBody = renameBodyVars(body, rename);
                    makeASTWithMeta(EDef(name, newParams, guards, newBody), node.metadata, node.pos);
                case EDefp(name, params2, guards2, body2):
                    var rename2 = computeParamPromotions(params2, body2);
                    #if debug_ast_transformer
                    if (Lambda.count(rename2) > 0) trace('[DefParamBinderAlignByBodyUse] ' + [for (k in rename2.keys()) k + '->' + rename2.get(k)].join(', '));
                    #end
                    if (Lambda.count(rename2) == 0) return node;
                    var newParams2 = renameParams(params2, rename2);
                    var newBody2 = renameBodyVars(body2, rename2);
                    makeASTWithMeta(EDefp(name, newParams2, guards2, newBody2), node.metadata, node.pos);
                default:
                    node;
            }
        });
    }

    static function computeParamPromotions(params: Array<EPattern>, body: ElixirAST): Map<String, String> {
        var have = new Map<String, Bool>();
        var rename = new Map<String, String>();
        // Collect existing parameter names
        function collect(p: EPattern): Void {
            switch (p) {
                case PVar(n) if (n != null && n.length > 0): have.set(n, true);
                case PTuple(es): for (e in es) collect(e);
                case PList(es): for (e in es) collect(e);
                case PCons(h, t): collect(h); collect(t);
                case PMap(kvs): for (kv in kvs) collect(kv.value);
                case PStruct(_, fs): for (f in fs) collect(f.value);
                case PPin(inner): collect(inner);
                default:
            }
        }
        if (params != null) for (p in params) collect(p);
        // Promote underscored param when base is used (AST or ERaw) in function scope and base param not present
        if (params != null) for (p in params) switch (p) {
            case PVar(n) if (n != null && n.length > 1 && n.charAt(0) == '_'):
                var base = n.substr(1);
                var used = VariableUsageCollector.usedInFunctionScope(body, base) || erawUsesName(body, base);
                if (!have.exists(base) && used) {
                    rename.set(n, base);
                }
            default:
        }
        return rename;
    }

    static function renameParams(params: Array<EPattern>, rename: Map<String, String>): Array<EPattern> {
        function tx(p: EPattern): EPattern {
            return switch (p) {
                case PVar(n) if (rename.exists(n)): PVar(rename.get(n));
                case PTuple(es): PTuple([for (e in es) tx(e)]);
                case PList(es): PList([for (e in es) tx(e)]);
                case PCons(h, t): PCons(tx(h), tx(t));
                case PMap(kvs): PMap([for (kv in kvs) { key: kv.key, value: tx(kv.value) }]);
                case PStruct(m, fs): PStruct(m, [for (f in fs) { key: f.key, value: tx(f.value) }]);
                case PPin(inner): PPin(tx(inner));
                default: p;
            }
        }
        return [for (p in params) tx(p)];
    }

    static function renameBodyVars(body: ElixirAST, rename: Map<String, String>): ElixirAST {
        return ElixirASTTransformer.transformNode(body, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EVar(v) if (rename.exists(v)):
                    makeASTWithMeta(EVar(rename.get(v)), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function erawUsesName(body: ElixirAST, name: String): Bool {
        var found = false;
        inline function isIdentChar(c: String): Bool {
            if (c == null || c.length == 0) return false;
            var ch = c.charCodeAt(0);
            return (ch >= '0'.code && ch <= '9'.code) || (ch >= 'A'.code && ch <= 'Z'.code) || (ch >= 'a'.code && ch <= 'z'.code) || c == "_" || c == ".";
        }
        function walk(n: ElixirAST): Void {
            if (n == null || n.def == null || found) return;
            switch (n.def) {
                case ERaw(code):
                    if (code != null && name != null && name.length > 0 && name.charAt(0) != '_') {
                        var start = 0;
                        while (!found) {
                            var i = code.indexOf(name, start);
                            if (i == -1) break;
                            var before = i > 0 ? code.substr(i - 1, 1) : null;
                            var afterIdx = i + name.length;
                            var after = afterIdx < code.length ? code.substr(afterIdx, 1) : null;
                            if (!isIdentChar(before) && !isIdentChar(after)) { found = true; break; }
                            start = i + name.length;
                        }
                    }
                case EBlock(ss): for (s in ss) walk(s);
                case EDo(ss2): for (s in ss2) walk(s);
                case EIf(c,t,e): walk(c); walk(t); if (e != null) walk(e);
                case ECase(expr, clauses): walk(expr); for (c in clauses) { if (c.guard != null) walk(c.guard); walk(c.body); }
                case EWith(clauses, doBlock, elseBlock):
                    for (wc in clauses) walk(wc.expr); walk(doBlock); if (elseBlock != null) walk(elseBlock);
                case ECall(t,_,as): if (t != null) walk(t); if (as != null) for (a in as) walk(a);
                case ERemoteCall(t2,_,as2): walk(t2); if (as2 != null) for (a2 in as2) walk(a2);
                case EField(obj,_): walk(obj);
                case EAccess(obj2,key): walk(obj2); walk(key);
                case EKeywordList(pairs): for (p in pairs) walk(p.value);
                case EMap(pairs): for (p in pairs) { walk(p.key); walk(p.value); }
                case EStructUpdate(base, fs): walk(base); for (f in fs) walk(f.value);
                case ETuple(es) | EList(es): for (e in es) walk(e);
                case EFn(clauses): for (cl in clauses) { if (cl.guard != null) walk(cl.guard); walk(cl.body); }
                default:
            }
        }
        walk(body);
        return found;
    }
}

#end
