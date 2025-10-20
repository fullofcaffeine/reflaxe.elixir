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
        // Gate safe underscore to Phoenix contexts (Web/Live/Presence), to avoid touching stdlib and app logic
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body):
                    var isPhoenixCtx = (n.metadata?.isPhoenixWeb == true)
                        || (name != null && ((name.indexOf("Web.") >= 0) || StringTools.endsWith(name, ".Live") || StringTools.endsWith(name, ".Presence") || StringTools.endsWith(name, "Web")));
                    if (!isPhoenixCtx || (name != null && StringTools.endsWith(name, ".Gettext"))) return n;
                    var newBody = [];
                    for (b in body) newBody.push(applyToDefs(b));
                    makeASTWithMeta(EModule(name, attrs, newBody), n.metadata, n.pos);
                case EDefmodule(name, doBlock):
                    var isPhoenixCtx2 = (n.metadata?.isPhoenixWeb == true)
                        || (name != null && ((name.indexOf("Web.") >= 0) || StringTools.endsWith(name, ".Live") || StringTools.endsWith(name, ".Presence") || StringTools.endsWith(name, "Web")));
                    if (!isPhoenixCtx2 || (name != null && StringTools.endsWith(name, ".Gettext"))) return n;
                    makeASTWithMeta(EDefmodule(name, applyToDefs(doBlock)), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function applyToDefs(node: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(node, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body):
                    var newArgs:Array<EPattern> = [];
                    // Special-case LiveView mount/3: never underscore the 3rd param when it is `socket`
                    var isMount = (name == "mount") && (args != null && args.length >= 3);
                    for (i in 0...(args != null ? args.length : 0)) {
                        var a = args[i];
                        if (isMount && i == 2) {
                            switch (a) {
                                case PVar(nm) if (nm == "socket"): newArgs.push(a); // keep `socket` as-is
                                default: newArgs.push(underscoreIfUnused(a, body));
                            }
                        } else {
                            newArgs.push(underscoreIfUnused(a, body));
                        }
                    }
                    makeASTWithMeta(EDef(name, newArgs, guards, body), n.metadata, n.pos);
                case EDefp(name, args2, guards2, body2):
                    var newArgs2:Array<EPattern> = [];
                    var isMountP = (name == "mount") && (args2 != null && args2.length >= 3);
                    for (i in 0...(args2 != null ? args2.length : 0)) {
                        var a2 = args2[i];
                        if (isMountP && i == 2) {
                            switch (a2) {
                                case PVar(nm2) if (nm2 == "socket"): newArgs2.push(a2);
                                default: newArgs2.push(underscoreIfUnused(a2, body2));
                            }
                        } else {
                            newArgs2.push(underscoreIfUnused(a2, body2));
                        }
                    }
                    makeASTWithMeta(EDefp(name, newArgs2, guards2, body2), n.metadata, n.pos);
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
        // Special-case: render(assigns) must keep `assigns` when ~H is present even if not explicitly referenced
        if (name == "assigns") {
            var hasHeex = false;
            function scanHeex(n: ElixirAST): Void {
                if (n == null || n.def == null || hasHeex) return;
                switch (n.def) {
                    case ESigil(type, _, _) if (type == "H"): hasHeex = true;
                    case ERaw(code) if (code != null && code.indexOf("~H\"") != -1): hasHeex = true;
                    case EBlock(ss): for (s in ss) scanHeex(s);
                    case EDo(ss2): for (s in ss2) scanHeex(s);
                    case EIf(c,t,e): scanHeex(c); scanHeex(t); if (e != null) scanHeex(e);
                    case ECase(expr, cs): scanHeex(expr); for (c in cs) { if (c.guard != null) scanHeex(c.guard); scanHeex(c.body); }
                    case EWith(clauses, doBlock, elseBlock): for (wc in clauses) scanHeex(wc.expr); scanHeex(doBlock); if (elseBlock != null) scanHeex(elseBlock);
                    case ECall(t,_,as): if (t != null) scanHeex(t); for (a in as) scanHeex(a);
                    case ERemoteCall(t2,_,as2): scanHeex(t2); for (a2 in as2) scanHeex(a2);
                    case EField(obj,_): scanHeex(obj);
                    case EAccess(obj2,key): scanHeex(obj2); scanHeex(key);
                    case EKeywordList(pairs): for (p in pairs) scanHeex(p.value);
                    case EMap(pairs): for (p in pairs) { scanHeex(p.key); scanHeex(p.value); }
                    case EStructUpdate(base,fs): scanHeex(base); for (f in fs) scanHeex(f.value);
                    case ETuple(es) | EList(es): for (e in es) scanHeex(e);
                    case EFn(clauses): for (cl in clauses) { if (cl.guard != null) scanHeex(cl.guard); scanHeex(cl.body); }
                    default:
                }
            }
            scanHeex(b);
            if (hasHeex) return true;
        }
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
