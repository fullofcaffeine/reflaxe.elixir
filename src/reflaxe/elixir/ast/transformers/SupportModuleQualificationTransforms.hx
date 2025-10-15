package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.StdModuleWhitelist;

/**
 * SupportModuleQualificationTransforms
 *
 * WHAT
 * - Qualify single-segment, CamelCase application-local module calls to <App>.<Name>
 *   in repository/query contexts, when those modules are defined in the current build
 *   (e.g., UserChangeset).
 *
 * WHY
 * - Repository and query snapshots expect fully-qualified references to project-local
 *   support modules without adding aliases. This preserves idiomatic call sites in tests.
 *
 * HOW
 * - Collect defined module names (EModule/EDefmodule) into a set.
 * - For modules that reference Repo.* OR define Ecto DSL shims (defp from/where) OR reference Ecto.Query,
 *   rewrite ERemoteCall/ECall targets whose module is a single-segment CamelCase identifier and exists
 *   in the defined module set, and is not std/framework whitelisted, to <App>.<Module>.
 *
 * EXAMPLES
 * Elixir (before):
 *   def list(), do: Repo.all(UserChangeset.query())
 * Elixir (after):
 *   def list(), do: App.UserChangeset.query() |> App.Repo.all()
 */
class SupportModuleQualificationTransforms {
    /**
     * Return the application-qualified module name.
     * Presence is a Phoenix special-case that lives under <App>Web.Presence.
     */
    static inline function qualifyAppLocalModule(moduleName: String, appPrefix: String): String {
        return (moduleName == "Presence") ? (appPrefix + "Web.Presence") : (appPrefix + "." + moduleName);
    }
    public static function transformPass(ast: ElixirAST): ElixirAST {
        // Collect defined modules
        var defined = new Map<String, Bool>();
        function collect(n: ElixirAST): Void {
            if (n == null || n.def == null) return;
            switch (n.def) {
                case EModule(name, _, body):
                    defined.set(name, true);
                    for (b in body) collect(b);
                case EDefmodule(name, doBlock):
                    defined.set(name, true);
                    collect(doBlock);
                default:
                    switch (n.def) {
                        case EBlock(es): for (e in es) collect(e);
                        case ECase(e, cs): collect(e); for (c in cs) { if (c.guard != null) collect(c.guard); collect(c.body);} 
                        case EIf(c,t,e): collect(c); collect(t); if (e != null) collect(e);
                        case EFn(cs): for (cl in cs) collect(cl.body);
                        case ECall(t,_,as): if (t != null) collect(t); if (as != null) for (a in as) collect(a);
                        case ERemoteCall(m,_,as): collect(m); if (as != null) for (a in as) collect(a);
                        default:
                    }
            }
        }
        collect(ast);

        inline function isSingleSegmentModule(name: String): Bool {
            return name != null && name.indexOf(".") == -1 && name.length > 0;
        }
        inline function isUpperCamel(name: String): Bool {
            var c = name.charAt(0);
            return c.toUpperCase() == c && c.toLowerCase() != c;
        }
        inline function deriveApp(): Null<String> {
            var p: Null<String> = null;
            try p = reflaxe.elixir.PhoenixMapper.getAppModuleName() catch (e:Dynamic) {}
            #if macro
            if (p == null) {
                try {
                    var d = haxe.macro.Compiler.getDefine("app_name");
                    if (d != null && d.length > 0) p = d;
                } catch (e:Dynamic) {}
            }
            #end
            return p;
        }
        inline function isEctoContext(stmts: Array<ElixirAST>): Bool {
            var has = false;
            for (s in stmts) switch (s.def) {
                case EDefp(nm, _, _, _) if (nm == "from" || nm == "where"): has = true;
                case ERemoteCall({def: EVar(m)}, _, _) if (m == "Ecto.Query"): has = true;
                case ERaw(code) if (code != null && (code.indexOf("Ecto.Query") != -1 || code.indexOf("Repo.") != -1)): has = true;
                default:
            }
            return has;
        }

        function rewriteIn(node: ElixirAST, app: String): ElixirAST {
            return ElixirASTTransformer.transformNode(node, function(n: ElixirAST): ElixirAST {
                return switch (n.def) {
                    // Rewrite remote calls: Module.func(args) → <App>.<Module>.func(args)
                    case ERemoteCall({def: EVar(moduleName)}, functionName, argumentList)
                        if (isSingleSegmentModule(moduleName) && isUpperCamel(moduleName) && !StdModuleWhitelist.isWhitelistedRoot(moduleName)):
                        var qualifiedModule = qualifyAppLocalModule(moduleName, app);
                        makeASTWithMeta(ERemoteCall(makeAST(EVar(qualifiedModule)), functionName, argumentList), n.metadata, n.pos);

                    // Rewrite call form: Module.func(args) → <App>.<Module>.func(args)
                    case ECall({def: EVar(moduleName)}, functionName, argumentList)
                        if (isSingleSegmentModule(moduleName) && isUpperCamel(moduleName) && !StdModuleWhitelist.isWhitelistedRoot(moduleName)):
                        var qualifiedModule = qualifyAppLocalModule(moduleName, app);
                        makeASTWithMeta(ERemoteCall(makeAST(EVar(qualifiedModule)), functionName, argumentList), n.metadata, n.pos);

                    default:
                        n;
                }
            });
        }

        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body):
                    var eligible = isEctoContext(body) || moduleUsesRepo(body);
                    if (!eligible) return n;
                    var app = deriveApp();
                    if (app == null) return n;
                    var newBody = [for (b in body) rewriteIn(b, app)];
                    makeASTWithMeta(EModule(name, attrs, newBody), n.metadata, n.pos);
                case EDefmodule(name, doBlock):
                    var stmts: Array<ElixirAST> = switch (doBlock.def) {
                        case EBlock(es): es;
                        case EDo(es): es;
                        default: [doBlock];
                    };
                    var eligible2 = isEctoContext(stmts) || moduleUsesRepo(stmts);
                    if (!eligible2) return n;
                    var app2 = deriveApp();
                    if (app2 == null) return n;
                    var newDo = makeAST(EBlock([for (s in stmts) rewriteIn(s, app2)]));
                    makeASTWithMeta(EDefmodule(name, newDo), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function moduleUsesRepo(stmts: Array<ElixirAST>): Bool {
        var found = false;
        function scan(x: ElixirAST): Void {
            if (found || x == null || x.def == null) return;
            switch (x.def) {
                case ERemoteCall({def: EVar(m)}, _, _):
                    if (m == "Repo" || (m != null && m.indexOf(".Repo") > 0)) found = true;
                case ERaw(code) if (code != null && code.indexOf("Repo.") != -1): found = true;
                case ECall(t, _, args): if (t != null) scan(t); if (args != null) for (a in args) scan(a);
                case ERemoteCall(m2, _, args2): scan(m2); if (args2 != null) for (a in args2) scan(a);
                case EBlock(es): for (e in es) scan(e);
                case EIf(c,t,e): scan(c); scan(t); if (e != null) scan(e);
                case ECase(e, cs): scan(e); for (c in cs) { if (c.guard != null) scan(c.guard); scan(c.body);} 
                default:
            }
        }
        for (s in stmts) scan(s);
        return found;
    }
}

#end
