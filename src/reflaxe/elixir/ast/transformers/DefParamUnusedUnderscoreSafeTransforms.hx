package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ASTUtils;
import reflaxe.elixir.ast.analyzers.VariableUsageCollector;

/**
 * DefParamUnusedUnderscoreSafeTransforms
 *
 * WHAT
 * - For function definitions, underscore unused parameters safely (only when not referenced in the body).
 *   No renaming is performed when the name is used; when rename occurs, no body rewrite is needed because it is unused.
 */
class DefParamUnusedUnderscoreSafeTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body):
                    var newArgs:Array<EPattern> = [];
                    for (a in args) newArgs.push(underscoreIfUnused(a, body));
                    makeASTWithMeta(EDef(name, newArgs, guards, body), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    /**
     * underscoreIfUnused
     *
     * WHAT
     * - For function parameters, convert `name` → `_name` when that name is not used
     *   in the function body or as a free variable inside nested closures.
     *
     * HOW
     * - Uses VariableUsageCollector to perform closure-aware usage detection so
     *   that inner anonymous function binders like `fn name -> ... end` do not
     *   count as a use of the outer parameter.
     */
    static function underscoreIfUnused(p:EPattern, body:ElixirAST):EPattern {
        return switch (p) {
            case PVar(nm) if (!usedInBodyOrRaw(body, nm) && (nm.length > 0 && nm.charAt(0) != '_')): PVar('_' + nm);
            default: p;
        }
    }

    // Closure-aware + ERaw-aware usage check
    static function usedInBodyOrRaw(b: ElixirAST, name: String): Bool {
        if (name == null || name.length == 0) return false;
        if (VariableUsageCollector.usedInFunctionScope(b, name)) return true;
        // Scan ERaw with token boundaries and metadata rawVarRefs
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
                    if (code != null && name.charAt(0) != '_') {
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
                    if (!found && n.metadata != null) {
                        var provided:Array<String> = cast Reflect.field(n.metadata, "rawVarRefs");
                        if (provided != null) for (v in provided) if (v == name) { found = true; break; }
                    }
                case EBlock(ss): for (s in ss) walk(s);
                case EDo(ss2): for (s in ss2) walk(s);
                case EIf(c,t,e): walk(c); walk(t); if (e != null) walk(e);
                case ECase(expr, clauses): walk(expr); for (c in clauses) { if (c.guard != null) walk(c.guard); walk(c.body); }
                case EWith(clauses, doBlock, elseBlock): for (wc in clauses) walk(wc.expr); walk(doBlock); if (elseBlock != null) walk(elseBlock);
                case ECall(t,_,as): if (t != null) walk(t); for (a in as) walk(a);
                case ERemoteCall(t2,_,as2): walk(t2); for (a2 in as2) walk(a2);
                case EField(obj,_): walk(obj);
                case EAccess(obj2,key): walk(obj2); walk(key);
                case EKeywordList(pairs): for (p in pairs) walk(p.value);
                case EMap(pairs): for (p in pairs) { walk(p.key); walk(p.value); }
                case EStructUpdate(base,fs): walk(base); for (f in fs) walk(f.value);
                case ETuple(es) | EList(es): for (e in es) walk(e);
                case EFn(clauses): for (cl in clauses) { if (cl.guard != null) walk(cl.guard); walk(cl.body); }
                default:
            }
        }
        walk(b);
        return found;
    }
}

#end
