package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * DefParamUnusedUnderscoreTransforms
 *
 * WHAT
 * - Prefix unused function parameters with underscore in Phoenix Web/Live/Presence
 *   modules to eliminate warnings-as-errors without altering semantics.
 *
 * WHY
 * - Phoenix callbacks and helpers often accept parameters that are not always used
 *   in all shapes. Elixir warns on unused parameters; prefixing with underscore is
 *   idiomatic and explicit.
 *
 * HOW
 * - Scope to modules whose names indicate Phoenix context: contain "Web.", end
 *   with ".Live" or ".Presence". Within such modules, for each EDef/EDefp, compute
 *   the set of variable names referenced in the body (including occurrences inside
 *   ERaw/EString interpolations) and rewrite PVar(name) parameters to PVar("_"+name)
 *   when the name is not referenced.
 *
 * EXAMPLES
 * Before:
 *   def get_users_editing_todo(socket, todo_id) do ... end  # when todo_id unused
 * After:
 *   def get_users_editing_todo(socket, _todo_id) do ... end
 */
/**
 * DefParamUnusedUnderscoreTransforms
 *
 * WHAT
 * - Prefixes unused function parameters with underscore in Phoenix Web/Live/Presence
 *   contexts to silence warnings without changing semantics.
 *
 * WHY (PHOENIX GATING)
 * - Phoenix callbacks often include parameters that are unused in some clauses; we
 *   restrict this transformation to Phoenix-shaped modules to avoid touching
 *   framework-agnostic code and stdlib.
 */
class DefParamUnusedUnderscoreTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body):
                    // Gate to Phoenix contexts only (shape-based + metadata)
                    var isPhoenixCtx = (n.metadata?.isPhoenixWeb == true)
                        || (name != null && ((name.indexOf("Web.") >= 0) || StringTools.endsWith(name, ".Live") || StringTools.endsWith(name, ".Presence") || StringTools.endsWith(name, "Web")));
                    if (!isPhoenixCtx) return n;
                    var newBody = [];
                    for (b in body) newBody.push(rewriteDefs(b));
                    makeASTWithMeta(EModule(name, attrs, newBody), n.metadata, n.pos);
                case EDefmodule(name, doBlock):
                    var isPhoenixCtx2 = (n.metadata?.isPhoenixWeb == true)
                        || (name != null && ((name.indexOf("Web.") >= 0) || StringTools.endsWith(name, ".Live") || StringTools.endsWith(name, ".Presence") || StringTools.endsWith(name, "Web")));
                    if (!isPhoenixCtx2) return n;
                    makeASTWithMeta(EDefmodule(name, rewriteDefs(doBlock)), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function rewriteDefs(node: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(node, function(x: ElixirAST): ElixirAST {
            return switch (x.def) {
                case EDef(name, args, guards, body):
                    var paramNames = extractParamNames(args);
                    var used = collectUsedNames(body, paramNames);
                    var newArgs = underscoreUnusedParams(args, used);
                    makeASTWithMeta(EDef(name, newArgs, guards, body), x.metadata, x.pos);
                case EDefp(name, args2, guards2, body2):
                    var paramNames2 = extractParamNames(args2);
                    var used2 = collectUsedNames(body2, paramNames2);
                    var newArgs2 = underscoreUnusedParams(args2, used2);
                    makeASTWithMeta(EDefp(name, newArgs2, guards2, body2), x.metadata, x.pos);
                default:
                    x;
            }
        });
    }

    static function extractParamNames(args: Array<EPattern>): Array<String> {
        var names: Array<String> = [];
        function visit(p: EPattern): Void {
            switch (p) {
                case PVar(n): if (n != null && n.length > 0) names.push(n);
                case PTuple(es): for (e in es) visit(e);
                case PList(es): for (e in es) visit(e);
                case PCons(h, t): visit(h); visit(t);
                case PMap(kvs): for (kv in kvs) visit(kv.value);
                case PStruct(_, fs): for (f in fs) visit(f.value);
                case PPin(inner): visit(inner);
                default:
            }
        }
        if (args != null) for (a in args) visit(a);
        return names;
    }

    static function underscoreUnusedParams(args: Array<EPattern>, used: Map<String, Bool>): Array<EPattern> {
        if (args == null) return args;
        return [for (a in args) underscorePattern(a, used)];
    }

    static function underscorePattern(p: EPattern, used: Map<String, Bool>): EPattern {
        return switch (p) {
            case PVar(name):
                // Never underscore Phoenix-idiomatic parameter names that are commonly used indirectly
                var preserve = (name == "assigns" || name == "opts" || name == "args");
                if (!preserve && name != null && name.length > 0 && name.charAt(0) != '_' && !used.exists(name)) PVar("_" + name) else p;
            case PTuple(es): PTuple([for (e in es) underscorePattern(e, used)]);
            case PList(es): PList([for (e in es) underscorePattern(e, used)]);
            case PCons(h, t): PCons(underscorePattern(h, used), underscorePattern(t, used));
            case PMap(kvs): PMap([for (kv in kvs) { key: kv.key, value: underscorePattern(kv.value, used) }]);
            case PStruct(nm, fs): PStruct(nm, [for (f in fs) { key: f.key, value: underscorePattern(f.value, used) }]);
            case PPin(inner): PPin(underscorePattern(inner, used));
            default: p;
        }
    }

    static function collectUsedNames(body: ElixirAST, paramNames: Array<String>): Map<String, Bool> {
        var names = new Map<String, Bool>();
        var paramSet = new Map<String, Bool>();
        if (paramNames != null) for (pn in paramNames) if (pn != null && pn.length > 0) paramSet.set(pn, true);

        inline function isIdentChar(c: String): Bool {
            if (c == null || c.length == 0) return false;
            var ch = c.charCodeAt(0);
            return (ch >= 48 && ch <= 57) || (ch >= 65 && ch <= 90) || (ch >= 97 && ch <= 122) || c == "_";
        }

        inline function markTokenUsage(text: String): Void {
            if (text == null) return;
            for (pn in paramSet.keys()) {
                if (pn == null || pn.length == 0 || pn.charAt(0) == '_') continue;
                var start = 0;
                while (true) {
                    var i = text.indexOf(pn, start);
                    if (i == -1) break;
                    var before = i > 0 ? text.substr(i - 1, 1) : null;
                    var afterIdx = i + pn.length;
                    var after = afterIdx < text.length ? text.substr(afterIdx, 1) : null;
                    if (!isIdentChar(before) && !isIdentChar(after)) {
                        names.set(pn, true);
                        break;
                    }
                    start = i + pn.length;
                }
            }
        }
        function visit(n: ElixirAST): Void {
            if (n == null || n.def == null) return;
            switch (n.def) {
                case EVar(v): names.set(v, true);
                case EString(s):
                    // Naive interpolation check
                    if (s != null) scanInterpolation(s, names);
                case ERaw(code):
                    if (code != null) {
                        scanInterpolation(code, names);
                        // Also consider bare token usage of parameters in ERaw code
                        markTokenUsage(code);
                    }
                case EList(els): for (el in els) visit(el);
                case ETuple(els): for (el in els) visit(el);
                case EMap(pairs): for (p in pairs) { visit(p.key); visit(p.value); }
                case EKeywordList(pairs): for (p in pairs) visit(p.value);
                case EStructUpdate(base, fields): visit(base); for (f in fields) visit(f.value);
                case EField(obj, _): visit(obj);
                case EAccess(tgt, key): visit(tgt); visit(key);
                case EBlock(ss): for (s in ss) visit(s);
                case EIf(c,t,e): visit(c); visit(t); if (e != null) visit(e);
                case ECase(expr, cs): visit(expr); for (c in cs) visit(c.body);
                case EBinary(_, l, r): visit(l); visit(r);
                case EMatch(_, rhs): visit(rhs);
                case ECall(t,_,as): if (t != null) visit(t); if (as != null) for (a in as) visit(a);
                case ERemoteCall(t2,_,as2): visit(t2); if (as2 != null) for (a2 in as2) visit(a2);
                case EFn(clauses): for (cl in clauses) visit(cl.body);
                default:
            }
        }
        visit(body);
        return names;
    }

    static inline function scanInterpolation(text:String, out:Map<String,Bool>):Void {
        // Very small helper: mark #{name} occurrences as used
        var i = 0;
        while (i < text.length) {
            var idx = text.indexOf("#{", i);
            if (idx == -1) break;
            var j = idx + 2;
            var buf = new StringBuf();
            while (j < text.length) {
                var c = text.charAt(j);
                if (c == '}') break;
                if (~/[A-Za-z0-9_]/.match(c)) buf.add(c);
                j++;
            }
            var name = buf.toString();
            if (name.length > 0) out.set(name, true);
            i = j + 1;
        }
    }
}

#end
