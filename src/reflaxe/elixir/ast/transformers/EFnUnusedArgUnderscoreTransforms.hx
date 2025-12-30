package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.VariableUsageCollector;

/**
 * EFnUnusedArgUnderscoreTransforms
 *
 * WHAT
 * - Underscore anonymous function argument binders that are not referenced in
 *   the function body. Applies to single-arg and two-arg (reduce) functions.
 *
 * WHY
 * - Prevents Elixir warnings about unused variables in anonymous functions
 *   emitted for Enum.each/map/reduce patterns. Keeps output idiomatic.
 *
 * HOW
 * - For each EFn clause, detect simple PVar/PAlias arg binders; if a binder is
 *   not used per VariableUsageCollector.usedInFunctionScope(body, name), rename
 *   it to `_name` (if not already underscored). Body rewrite is not needed as
 *   unused binders have no references.
 *
 * EXAMPLES
 * Before:
 *   Enum.each(xs, fn elem -> IO.puts("done") end)
 * After:
 *   Enum.each(xs, fn _elem -> IO.puts("done") end)
 */
class EFnUnusedArgUnderscoreTransforms {
    static inline function looksLikeDoubleQuotedStringLiteral(code: String): Bool {
        if (code == null) return false;
        var trimmed = StringTools.trim(code);
        return trimmed.length >= 2 && StringTools.startsWith(trimmed, "\"") && StringTools.endsWith(trimmed, "\"");
    }

    static inline function stripOuterQuotes(code: String): String {
        var trimmed = StringTools.trim(code);
        if (looksLikeDoubleQuotedStringLiteral(trimmed)) {
            return trimmed.substr(1, trimmed.length - 2);
        }
        return trimmed;
    }

    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EFn(clauses):
                    var newClauses = [];
                    for (cl in clauses) {
                        var newArgs:Array<EPattern> = [];
                        var i = 0;
                        inline function isUsed(name:String):Bool {
                            if (name == null) return false;
                            var underscored = '_' + name;
                            return VariableUsageCollector.usedInFunctionScope(cl.body, name)
                                || VariableUsageCollector.usedInFunctionScope(cl.body, underscored)
                                || erawUsesName(cl.body, name)
                                || erawUsesName(cl.body, underscored)
                                || containsVarName(cl.body, name)
                                || containsVarName(cl.body, underscored);
                        }
                        function normalizedBinder(name:String):String {
                            if (name == null) return name;

                            // If a binder is already underscored but the body references the base
                            // name (without underscore), prefer de-underscoring to avoid undefined
                            // variable errors (e.g., `_sel` binder but body uses `sel` inside nested fns).
                            //
                            // We only do this when the underscored name itself is not referenced.
                            if (name.length > 1 && name.charAt(0) == '_') {
                                var base = name.substr(1);
                                var usesBase = VariableUsageCollector.usedInFunctionScope(cl.body, base)
                                    || erawUsesName(cl.body, base)
                                    || containsVarName(cl.body, base);
                                var usesUnderscored = VariableUsageCollector.usedInFunctionScope(cl.body, name)
                                    || erawUsesName(cl.body, name)
                                    || containsVarName(cl.body, name);
                                if (usesBase && !usesUnderscored) {
                                    return base;
                                }
                            }

                            var needsUnderscore = !isUsed(name) && (name.length == 0 || name.charAt(0) != '_');
                            return needsUnderscore ? ('_' + name) : name;
                        }
                        for (a in cl.args) {
                            switch (a) {
                                case PVar(name):
                                    var nn = normalizedBinder(name);
#if debug_efn_unused_arg_underscore
                                    if (name != nn) {
                                        try {
                                            trace('[EFnUnusedArgUnderscore] ' + name + ' -> ' + nn);
                                        } catch (_: Dynamic) {}
                                    }
#end
                                    newArgs.push(PVar(nn));
                                case PAlias(name, pat):
                                    var nn = normalizedBinder(name);
#if debug_efn_unused_arg_underscore
                                    if (name != nn) {
                                        try {
                                            trace('[EFnUnusedArgUnderscore] ' + name + ' -> ' + nn);
                                        } catch (_: Dynamic) {}
                                    }
#end
                                    newArgs.push(PAlias(nn, pat));
                                default:
                                    newArgs.push(a);
                            }
                            i++;
                        }
                        newClauses.push({args: newArgs, guard: cl.guard, body: cl.body});
                    }
                    makeASTWithMeta(EFn(newClauses), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    // ERaw token-bound scan for name usage
    static function erawUsesName(body: ElixirAST, name: String): Bool {
        var found = false;
        inline function isIdentChar(c: String): Bool {
            if (c == null || c.length == 0) return false;
            var ch = c.charCodeAt(0);
            return (ch >= '0'.code && ch <= '9'.code) || (ch >= 'A'.code && ch <= 'Z'.code) || (ch >= 'a'.code && ch <= 'z'.code) || c == "_" || c == ".";
        }
        inline function scanInterpolationInner(inner: String, needle: String): Void {
            if (inner == null || needle == null || needle.length == 0) return;
            var start = 0;
            while (!found) {
                var i = inner.indexOf(needle, start);
                if (i == -1) break;
                var before = i > 0 ? inner.substr(i - 1, 1) : null;
                var afterIdx = i + needle.length;
                var after = afterIdx < inner.length ? inner.substr(afterIdx, 1) : null;
                if (!isIdentChar(before) && !isIdentChar(after)) { found = true; break; }
                start = i + needle.length;
            }
        }
        function walk(n: ElixirAST): Void {
            if (n == null || n.def == null || found) return;
            switch (n.def) {
                case ERaw(code):
                    if (code != null && name != null && name.length > 0 && name.charAt(0) != '_') {
                        if (looksLikeDoubleQuotedStringLiteral(code)) {
                            var str = stripOuterQuotes(code);
                            var cursor = 0;
                            while (!found && str != null && cursor < str.length) {
                                var open = str.indexOf("#{", cursor);
                                if (open == -1) break;
                                var close = str.indexOf("}", open + 2);
                                if (close == -1) break;
                                var inner = str.substr(open + 2, close - (open + 2));
                                scanInterpolationInner(inner, name);
                                cursor = close + 1;
                            }
                        } else {
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
                    }
                case EParen(e):
                    walk(e);
                case EPin(inner):
                    walk(inner);
                case EUnary(_, e):
                    walk(e);
                case EBinary(_, l, r):
                    walk(l); walk(r);
                case EMatch(_, rhs):
                    walk(rhs);
                case EPipe(l, r):
                    walk(l); walk(r);
                case EBlock(ss): for (s in ss) walk(s);
                case EDo(statements): for (s in statements) walk(s);
                case EIf(c,t,e): walk(c); walk(t); if (e != null) walk(e);
                case EUnless(c, b, e2): walk(c); walk(b); if (e2 != null) walk(e2);
                case ECase(expr, clauses): walk(expr); for (c in clauses) { if (c.guard != null) walk(c.guard); walk(c.body); }
                case ECond(clauses):
                    for (c in clauses) { walk(c.condition); walk(c.body); }
                case EWith(clauses, doBlock, elseBlock): for (wc in clauses) walk(wc.expr); walk(doBlock); if (elseBlock != null) walk(elseBlock);
                case ETry(body, rescue, catchClauses, afterBlock, elseBlock):
                    walk(body);
                    for (rc in rescue) {
                        walk(rc.body);
                    }
                    for (cc in catchClauses) {
                        walk(cc.body);
                    }
                    if (afterBlock != null) walk(afterBlock);
                    if (elseBlock != null) walk(elseBlock);
                case ERaise(ex, attrs):
                    walk(ex);
                    if (attrs != null) walk(attrs);
                case EThrow(v):
                    walk(v);
                case ECall(t,_,as): if (t != null) walk(t); for (a in as) walk(a);
                case EMacroCall(_, args, doBlock):
                    for (a in args) walk(a);
                    walk(doBlock);
                case ERemoteCall(targetExpr,_,argsList): walk(targetExpr); for (argNode in argsList) walk(argNode);
                case ECapture(expr, _):
                    walk(expr);
                case EField(obj,_): walk(obj);
                case EAccess(objectExpr,key): walk(objectExpr); walk(key);
                case ERange(start, end, _, step):
                    walk(start); walk(end); if (step != null) walk(step);
                case EKeywordList(pairs): for (p in pairs) walk(p.value);
                case EMap(pairs): for (p in pairs) { walk(p.key); walk(p.value); }
                case EStructUpdate(base,fs): walk(base); for (f in fs) walk(f.value);
                case EStruct(_, fs2): for (f2 in fs2) walk(f2.value);
                case EModule(_, _, body): for (b in body) walk(b);
                case EDef(_, _, guards, body): if (guards != null) walk(guards); walk(body);
                case EDefp(_, _, guards, body): if (guards != null) walk(guards); walk(body);
                case EDefmacro(_, _, guards, body): if (guards != null) walk(guards); walk(body);
                case EDefmacrop(_, _, guards, body): if (guards != null) walk(guards); walk(body);
                case EReceive(clauses, afterClause):
                    for (cl in clauses) { if (cl.guard != null) walk(cl.guard); walk(cl.body); }
                    if (afterClause != null) walk(afterClause.body);
                case ESend(target, message):
                    walk(target); walk(message);
                case EFor(generators, filters, body, into, _):
                    for (g in generators) walk(g.expr);
                    for (f in filters) walk(f);
                    walk(body);
                    if (into != null) walk(into);
                case ETuple(es) | EList(es): for (e in es) walk(e);
                case EFn(clauses): for (cl in clauses) { if (cl.guard != null) walk(cl.guard); walk(cl.body); }
                default:
            }
        }
        walk(body);
        return found;
    }

    static function containsVarName(body: ElixirAST, name: String): Bool {
        var found = false;
        function walk(n: ElixirAST): Void {
            if (n == null || n.def == null || found) return;
            switch (n.def) {
                case EVar(v) if (v == name):
                    found = true;
                case EPin(inner):
                    walk(inner);
                case EParen(e):
                    walk(e);
                case EBinary(_, l, r):
                    walk(l); walk(r);
                case EMatch(_, rhs):
                    walk(rhs);
                case EBlock(ss): for (s in ss) walk(s);
                case EDo(statements): for (s in statements) walk(s);
                case EIf(c,t,e): walk(c); walk(t); if (e != null) walk(e);
                case ECase(expr, clauses): walk(expr); for (c in clauses) { if (c.guard != null) walk(c.guard); walk(c.body); }
                case EWith(clauses, doBlock, elseBlock): for (wc in clauses) walk(wc.expr); walk(doBlock); if (elseBlock != null) walk(elseBlock);
                case ECall(t,_,as): if (t != null) walk(t); for (a in as) walk(a);
                case ERemoteCall(targetExpr,_,argsList): walk(targetExpr); for (argNode in argsList) walk(argNode);
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
        walk(body);
        return found;
    }
}

#end
