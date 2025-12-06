package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.VariableUsageCollector;

/**
 * ChangesetParamUnderscoreTransforms
 *
 * WHAT
 * - For functions named `changeset`, prefix parameters with underscore when
 *   provably unused in the function body (closure-aware check).
 *
 * WHY
 * - tests (repository) expect `_user, _attrs` in stub changeset helpers.
 */
class ChangesetParamUnderscoreTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body) if (name == "changeset"):
                    #if debug_changeset_underscore
                    // DISABLED: trace('[ChangesetParamUnderscore] EDef changeset/ ' + (args != null ? args.length : 0) + ' args');
                    #end
                    var newArgs = underscoreUnused(args, body);
                    #if debug_changeset_underscore
                    inline function patToStr(p:EPattern):String return switch(p){ case PVar(nm): nm; default: Std.string(p); };
                    var before = [for (a in args) patToStr(a)].join(',');
                    var after = [for (a in newArgs) patToStr(a)].join(',');
                    // DISABLED: trace('[ChangesetParamUnderscore] args before=' + before + ' after=' + after);
                    #end
                    makeASTWithMeta(EDef(name, newArgs, guards, body), n.metadata, n.pos);
                case EDefp(functionName, functionArgs, functionGuards, functionBody) if (functionName == "changeset"):
                    #if debug_changeset_underscore
                    // DISABLED: trace('[ChangesetParamUnderscore] EDefp changeset/ ' + (functionArgs != null ? functionArgs.length : 0) + ' args');
                    #end
                    var newArgs = underscoreUnused(functionArgs, functionBody);
                    makeASTWithMeta(EDefp(functionName, newArgs, functionGuards, functionBody), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function underscoreUnused(args:Array<EPattern>, body:ElixirAST):Array<EPattern> {
        if (args == null) return args;
        if (bodyHasChangesetOps(body)) return args; // do not underscore when changeset ops present
        return [for (a in args) switch (a) {
            case PVar(nm) if (nm != null && nm.length > 0 && nm.charAt(0) != '_'):
                var used = VariableUsageCollector.usedInFunctionScope(body, nm) || usedInChangesetCalls(body, nm) || usedInRawTokens(body, nm);
                used ? a : PVar('_' + nm);
            default: a;
        }];
    }

    static function usedInChangesetCalls(body: ElixirAST, name: String): Bool {
        var found = false;
        function walk(n: ElixirAST): Void {
            if (n == null || n.def == null || found) return;
            switch (n.def) {
                case ERemoteCall(mod, fn, args) if (fn == "change" || fn == "cast"):
                    switch (mod.def) {
                        case EVar(m) if (m == "Ecto.Changeset"):
                            if (args != null) for (a in args) switch (a.def) { case EVar(v) if (v == name): found = true; default: }
                        default:
                    }
                    if (!found && args != null) for (a in args) walk(a);
                case EBlock(es): for (e in es) walk(e);
                case EIf(c,t,e): walk(c); walk(t); if (e != null) walk(e);
                case ECase(e, cs): walk(e); for (c in cs) { if (c.guard != null) walk(c.guard); walk(c.body);} 
                case ECall(t,_,as): if (t != null) walk(t); if (as != null) for (a in as) walk(a);
                case ERemoteCall(m2,_,as2): walk(m2); if (as2 != null) for (a in as2) walk(a);
                default:
            }
        }
        walk(body);
        return found;
    }

    static function usedInRawTokens(body: ElixirAST, name: String): Bool {
        var found = false;
        inline function isIdentChar(c: String): Bool {
            if (c == null || c.length == 0) return false;
            var ch = c.charCodeAt(0);
            return (ch >= '0'.code && ch <= '9'.code) || (ch >= 'A'.code && ch <= 'Z'.code) || (ch >= 'a'.code && ch <= 'z'.code) || c == '_' || c == '.';
        }
        function walk(n: ElixirAST): Void {
            if (n == null || n.def == null || found) return;
            switch (n.def) {
                case ERaw(code):
                    if (code != null) {
                        var idx = 0;
                        while (!found) {
                            var i = code.indexOf(name, idx);
                            if (i == -1) break;
                            var before = i > 0 ? code.substr(i - 1, 1) : null;
                            var afterIdx = i + name.length;
                            var after = afterIdx < code.length ? code.substr(afterIdx, 1) : null;
                            if (!isIdentChar(before) && !isIdentChar(after)) { found = true; break; }
                            idx = i + name.length;
                        }
                    }
                case EBlock(es): for (e in es) walk(e);
                case EIf(c,t,e): walk(c); walk(t); if (e != null) walk(e);
                case ECase(ex, cs): walk(ex); for (c in cs) { if (c.guard != null) walk(c.guard); walk(c.body);} 
                case ECall(t,_,as): if (t != null) walk(t); if (as != null) for (a in as) walk(a);
                case ERemoteCall(m,_,as): walk(m); if (as != null) for (a in as) walk(a);
                default:
            }
        }
        walk(body);
        return found;
    }

    static function bodyHasChangesetOps(body: ElixirAST): Bool {
        var found = false;
        function walk(n: ElixirAST): Void {
            if (n == null || n.def == null || found) return;
            switch (n.def) {
                case ERemoteCall(mod, _, args):
                    switch (mod.def) { case EVar(m) if (m == "Ecto.Changeset"): found = true; default: }
                    walk(mod);
                    if (args != null) for (a in args) walk(a);
                case ERaw(code):
                    if (code != null && code.indexOf("Ecto.Changeset.") != -1) found = true;
                case EBlock(es): for (e in es) walk(e);
                case EIf(c,t,e): walk(c); walk(t); if (e != null) walk(e);
                case ECase(ex, cs): walk(ex); for (c in cs) { if (c.guard != null) walk(c.guard); walk(c.body);} 
                case ECall(t,_,as):
                    if (t != null) walk(t);
                    if (as != null) for (a in as) walk(a);
                default:
            }
        }
        walk(body);
        return found;
    }
}

#end
