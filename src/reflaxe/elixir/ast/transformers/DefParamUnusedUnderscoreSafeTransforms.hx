package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

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
     *   in the function body.
     *
     * HOW
     * - Uses bodyUsesVar() which scans expressions, field/access targets, and ERaw
     *   snippets to avoid false “unused” detection.
     */
    static function underscoreIfUnused(p:EPattern, body:ElixirAST):EPattern {
        return switch (p) {
            case PVar(nm) if (!bodyUsesVar(body, nm) && (nm.length > 0 && nm.charAt(0) != '_')): PVar('_' + nm);
            default: p;
        }
    }

    /**
     * bodyUsesVar
     *
     * WHAT
     * - Detects usage of a parameter name anywhere in the body, including nested
     *   structures and raw/injected Elixir code.
     *
     * WHY
     * - Prevent prefixing parameters with underscore when they are referenced via
     *   `obj.field`, `obj[key]`, or inside ERaw/strings. This keeps code correct and
     *   prevents undefined-variable errors.
     */
    static function bodyUsesVar(b:ElixirAST, name:String):Bool {
        var found = false;
        inline function isIdentChar(c: String): Bool {
            if (c == null || c.length == 0) return false;
            var ch = c.charCodeAt(0);
            return (ch >= 48 && ch <= 57) || (ch >= 65 && ch <= 90) || (ch >= 97 && ch <= 122) || c == "_";
        }
        function visit(x:ElixirAST):Void {
            if (found || x == null || x.def == null) return;
            switch (x.def) {
                case EVar(v): if (v == name) { found = true; return; }
                case ERaw(code):
                    if (name != null && name.length > 0 && name.charAt(0) != '_' && code != null) {
                        var start = 0;
                        while (!found) {
                            var i = code.indexOf(name, start);
                            if (i == -1) break;
                            var before = i > 0 ? code.substr(i - 1, 1) : null;
                            var afterIdx = i + name.length;
                            var after = afterIdx < code.length ? code.substr(afterIdx, 1) : null;
                            var beforeIsIdent = isIdentChar(before);
                            var afterIsIdent = isIdentChar(after);
                            if (!beforeIsIdent && !afterIsIdent) { found = true; break; }
                            start = i + name.length;
                        }
                    }
                case EBlock(ss): for (s in ss) visit(s);
                case EIf(c,t,e): visit(c); visit(t); if (e != null) visit(e);
                case ECase(expr, cs): visit(expr); for (c in cs) visit(c.body);
                case EBinary(_, l, r): visit(l); visit(r);
                case EMatch(_, rhs): visit(rhs);
                case ECall(tgt, _, args): if (tgt != null) visit(tgt); for (a in args) visit(a);
                case ERemoteCall(tgt2, _, args2): visit(tgt2); for (a2 in args2) visit(a2);
                case EList(els): for (el in els) visit(el);
                case ETuple(els): for (el in els) visit(el);
                case EMap(pairs): for (p in pairs) { visit(p.key); visit(p.value); }
                case EKeywordList(pairs): for (p in pairs) visit(p.value);
                case EStructUpdate(base, fields): visit(base); for (f in fields) visit(f.value);
                case EField(obj, _): visit(obj);
                case EAccess(tgt3, key): visit(tgt3); visit(key);
                case EFn(clauses): for (cl in clauses) visit(cl.body);
                default: // literals and others: ignore
            }
        }
        visit(b);
        return found;
    }
}

#end
