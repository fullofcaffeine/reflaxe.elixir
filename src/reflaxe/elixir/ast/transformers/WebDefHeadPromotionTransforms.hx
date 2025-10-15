package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.VariableUsageCollector;

/**
 * WebDefHeadPromotionTransforms
 *
 * WHAT
 * - Promote underscored def/defp parameters (_id/_user_id/_editing_todo) in Web/Live modules
 *   to their base names (id/user_id/editing_todo) when the base name is used in the function body.
 *
 * WHY
 * - Prevent undefined-variable errors and underscore-usage warnings in Phoenix Web/Live modules
 *   by aligning parameter binders with actual usage (including pins and ERaw occurrences).
 *
 * HOW
 * - For EModule/EDefmodule whose names look like Web or Live modules, traverse EDef/EDefp:
 *   - If a parameter PVar("_name") exists and the body uses "name" (closure-aware) or pins ^name
 *     or contains token-bounded name in ERaw, rename PVar("_name") -> PVar("name") and rewrite
 *     body references to the new binder where needed.
 *
 * EXAMPLES
 * Elixir (before):
 *   def find(_id, todos), do: Enum.find(todos, fn t -> t.id == id end)
 * Elixir (after):
 *   def find(id, todos), do: Enum.find(todos, fn t -> t.id == id end)
 */
class WebDefHeadPromotionTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body) if (isWebOrLive(name)):
                    var nb = [for (b in body) promoteInNode(b)];
                    makeASTWithMeta(EModule(name, attrs, nb), n.metadata, n.pos);
                case EDefmodule(name2, doBlock) if (isWebOrLive(name2)):
                    makeASTWithMeta(EDefmodule(name2, promoteInNode(doBlock)), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static inline function isWebOrLive(name:String):Bool {
        if (name == null) return false;
        return name.indexOf("Web.") != -1 || StringTools.endsWith(name, "Live") || name.indexOf("Controller") != -1;
    }

    static function promoteInNode(node: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(node, function(x: ElixirAST): ElixirAST {
            return switch (x.def) {
                case EDef(fname, args, guards, body):
                    var rename = compute(args, body);
                    var newArgs = renameParams(args, rename);
                    var newBody = renameBody(body, rename);
                    makeASTWithMeta(EDef(fname, newArgs, guards, newBody), x.metadata, x.pos);
                case EDefp(functionName, functionArgs, functionGuards, functionBody):
                    var renameMap = compute(functionArgs, functionBody);
                    var newArgs = renameParams(functionArgs, renameMap);
                    var newBody = renameBody(functionBody, renameMap);
                    makeASTWithMeta(EDefp(functionName, newArgs, functionGuards, newBody), x.metadata, x.pos);
                default:
                    x;
            }
        });
    }

    static function compute(args:Array<EPattern>, body:ElixirAST):Map<String,String> {
        var have = new Map<String,Bool>();
        var rename = new Map<String,String>();
        if (args != null) for (a in args) switch (a) { case PVar(n) if (n != null): have.set(n, true); default: }
        if (args != null) for (a in args) switch (a) {
            case PVar(n) if (n != null && n.length > 1 && n.charAt(0) == '_'):
                var base = n.substr(1);
                var baseUsed = VariableUsageCollector.usedInFunctionScope(body, base) || pinUsesName(body, base) || erawUsesName(body, base) || containsVarName(body, base);
                // Also allow promotion when the underscored name itself is used, to silence warnings
                var underscoredUsed = containsVarName(body, n);
                if (!have.exists(base) && (baseUsed || underscoredUsed)) rename.set(n, base);
            default:
        }
        return rename;
    }

    static function renameParams(args:Array<EPattern>, rename:Map<String,String>):Array<EPattern> {
        if (args == null || Lambda.count(rename) == 0) return args;
        var out:Array<EPattern> = [];
        for (a in args) switch (a) { case PVar(n) if (rename.exists(n)): out.push(PVar(rename.get(n))); default: out.push(a); }
        return out;
    }

    static function renameBody(body:ElixirAST, rename:Map<String,String>):ElixirAST {
        if (Lambda.count(rename) == 0) return body;
        return ElixirASTTransformer.transformNode(body, function(n: ElixirAST): ElixirAST {
            return switch (n.def) { case EVar(v) if (rename.exists(v)): makeASTWithMeta(EVar(rename.get(v)), n.metadata, n.pos); default: n; }
        });
    }

    static function pinUsesName(body: ElixirAST, name: String): Bool {
        var found = false;
        function walk(n: ElixirAST): Void {
            if (n == null || n.def == null || found) return;
            switch (n.def) {
                case EPin(inner):
                    switch (inner.def) {
                        case EVar(v) if (v == name): found = true;
                        default: walk(inner);
                    }
                case EParen(e):
                    walk(e);
                case EBinary(_, l, r):
                    walk(l); walk(r);
                case EMatch(_, rhs):
                    walk(rhs);
                case EBlock(ss): for (s in ss) walk(s);
                case EDo(ss2): for (s in ss2) walk(s);
                case EIf(c,t,e): walk(c); walk(t); if (e != null) walk(e);
                case ECase(expr, clauses): walk(expr); for (c in clauses) { if (c.guard != null) walk(c.guard); walk(c.body); }
                case EWith(clauses, doBlock, elseBlock): for (wc in clauses) walk(wc.expr); walk(doBlock); if (elseBlock != null) walk(elseBlock);
                case ECall(t,_,as): if (t != null) walk(t); if (as != null) for (a in as) walk(a);
                case ERemoteCall(t2,_,as2): walk(t2); if (as2 != null) for (a2 in as2) walk(a2);
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
                case EWith(clauses, doBlock, elseBlock): for (wc in clauses) walk(wc.expr); walk(doBlock); if (elseBlock != null) walk(elseBlock);
                case ECall(t,_,as): if (t != null) walk(t); if (as != null) for (a in as) walk(a);
                case ERemoteCall(t2,_,as2): walk(t2); if (as2 != null) for (a2 in as2) walk(a2);
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
                case EDo(ss2): for (s in ss2) walk(s);
                case EIf(c,t,e): walk(c); walk(t); if (e != null) walk(e);
                case ECase(expr, clauses): walk(expr); for (c in clauses) { if (c.guard != null) walk(c.guard); walk(c.body); }
                case EWith(clauses, doBlock, elseBlock): for (wc in clauses) walk(wc.expr); walk(doBlock); if (elseBlock != null) walk(elseBlock);
                case ECall(t,_,as): if (t != null) walk(t); if (as != null) for (a in as) walk(a);
                case ERemoteCall(t2,_,as2): walk(t2); if (as2 != null) for (a2 in as2) walk(a2);
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
