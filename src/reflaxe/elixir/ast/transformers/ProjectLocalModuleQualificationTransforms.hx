package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.StdModuleWhitelist;

/**
 * ProjectLocalModuleQualificationTransforms
 *
 * WHAT
 * - Qualify call-site references to project-local, single-segment CamelCase
 *   modules to <App>.<Name> across the codebase.
 *
 * WHY
 * - Some generated modules are emitted at the project root (e.g., UserChangeset),
 *   while call-sites are expected to reference them with an app-qualified module
 *   name in tests (e.g., MyApp.UserChangeset). This keeps output consistent and
 *   idiomatic without adding aliases.
 *
 * HOW
 * - Collect all module names defined in the current AST (EModule/EDefmodule) that
 *   are single-segment CamelCase and not whitelisted std/framework roots.
 * - Transform ERemoteCall/ECall targets using those names to <App>.<Name>.
 * - Shape-based: no app-specific heuristics beyond the configured app prefix.
 */
class ProjectLocalModuleQualificationTransforms {
    /**
     * Return the application-qualified module name.
     * Presence is a Phoenix special-case that lives under <App>Web.Presence.
     */
    static inline function qualifyAppLocalModule(moduleName: String, appPrefix: String): String {
        return (moduleName == "Presence") ? (appPrefix + "Web.Presence") : (appPrefix + "." + moduleName);
    }
    static inline function isSingleSegmentModule(name: String): Bool {
        return name != null && name.indexOf(".") == -1 && name.length > 0;
    }
    static inline function isUpperCamel(name: String): Bool {
        var c = name.charAt(0);
        return c.toUpperCase() == c && c.toLowerCase() != c;
    }

    public static function transformPass(ast: ElixirAST): ElixirAST {
        var defined = new Map<String,Bool>();
        function collect(n: ElixirAST): Void {
            if (n == null || n.def == null) return;
            switch (n.def) {
                case EModule(name, _, body): defined.set(name, true); for (b in body) collect(b);
                case EDefmodule(name, doBlock): defined.set(name, true); collect(doBlock);
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

        var app: Null<String> = null;
        try app = reflaxe.elixir.PhoenixMapper.getAppModuleName() catch (e:Dynamic) {}
        if (app == null) return ast;

        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                // Rewrite Module.func(args) → <App>.<Module>.func(args)
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
}

#end
