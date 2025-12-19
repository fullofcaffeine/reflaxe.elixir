package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * RepoAtomToSchemaTransforms
 *
 * WHAT
 * - Rewrites Repo calls that accept a queryable (first arg) when given a plain
 *   table atom (e.g., :user) to the corresponding schema module
 *   (<App>.User), ensuring idiomatic Ecto usage.
 *
 * WHY
 * - Passing non-module atoms to Repo APIs (all/one/get/get!/aggregate) relies on
 *   Ecto.Queryable implementations that are not valid for arbitrary atoms and
 *   lead to Protocol.UndefinedError. The intended usage in Phoenix/Ecto code is
 *   to pass the schema module or a proper Ecto.Query.
 *
 * HOW
 * - Detect ERemoteCall(MOD, FUNC, ARGS) where:
 *   - MOD is `Repo` or `<App>.Repo` (after global qualification)
 *   - FUNC ∈ {"all","one","get","get!","aggregate"}
 *   - The first argument is an EAtom(table)
 * - Replace the first arg with EVar("<App>." + CamelCase(table))
 * - App prefix is derived from PhoenixMapper.getAppModuleName(); no app-specific
 *   name heuristics are used beyond this configured prefix.
 *
 * EXAMPLES
 * Before:
 *   MyApp.Repo.all(:user)
 *   Repo.get(:user, id)
 * After:
 *   MyApp.Repo.all(MyApp.User)
 *   Repo.get(MyApp.User, id)
 */
class RepoAtomToSchemaTransforms {
    static inline function camelize(s: String): String {
        var parts = s.split("_");
        var out = [];
        for (p in parts) if (p.length > 0) out.push(p.charAt(0).toUpperCase() + p.substr(1));
        return out.join("");
    }

    static inline function isRepoModule(modAst: ElixirAST): Bool {
        return switch (modAst.def) {
            case EVar(m):
                // Allow "Repo" (will be qualified by other passes) or any *.<App>.Repo
                (m == "Repo") || (m != null && m.indexOf(".Repo") > 0);
            default:
                false;
        }
    }

    static inline function eligibleFunc(func: String): Bool {
        return switch (func) {
            case "all" | "one" | "get" | "get!" | "aggregate": true;
            default: false;
        }
    }

    public static function transformPass(ast: ElixirAST): ElixirAST {
        var app: Null<String> = null;
        try app = reflaxe.elixir.PhoenixMapper.getAppModuleName() catch (e) {}

        // Helper: detect whether a subtree uses Ecto.Query macros (remote calls)
        function usesEctoQuery(node: ElixirAST): Bool {
            var found = false;
            ElixirASTTransformer.transformNode(node, function(x: ElixirAST): ElixirAST {
                if (found || x == null || x.def == null) return x;
                switch (x.def) {
                    case ERemoteCall(mod, _, _):
                        switch (mod.def) { case EVar(m) if (m == "Ecto.Query"): found = true; default: }
                    default:
                }
                return x;
            });
            return found;
        }

        // Rewrite only inside modules/functions that also use Ecto.Query macros.
        // This avoids altering minimal Repo wrappers (e.g., repository snapshots) that intentionally use atoms.
        function rewriteIn(node: ElixirAST): ElixirAST {
            return ElixirASTTransformer.transformNode(node, function(n: ElixirAST): ElixirAST {
                return switch (n.def) {
                    case ERemoteCall(mod, func, args) if (eligibleFunc(func) && isRepoModule(mod) && args != null && args.length >= 1):
                        if (!usesEctoQuery(node)) return n;
                        switch (args[0].def) {
                            case EAtom(table) if (app != null):
                                var newArgs = args.copy();
                                newArgs[0] = makeAST(EVar(app + "." + camelize(table)));
                                makeASTWithMeta(ERemoteCall(mod, func, newArgs), n.metadata, n.pos);
                            default:
                                n;
                        }
                    case EMatch(pat, {def: ERemoteCall(mod2, func2, args2)}):
                        if (!(eligibleFunc(func2) && isRepoModule(mod2) && args2 != null && args2.length >= 1)) return n;
                        if (!usesEctoQuery(node)) return n;
                        switch (args2[0].def) {
                            case EAtom(table2) if (app != null):
                                var na = args2.copy();
                                na[0] = makeAST(EVar(app + "." + camelize(table2)));
                                makeASTWithMeta(EMatch(pat, makeAST(ERemoteCall(mod2, func2, na))), n.metadata, n.pos);
                            default:
                                n;
                        }
                    default:
                        n;
                }
            });
        }

        return ElixirASTTransformer.transformNode(ast, function(top: ElixirAST): ElixirAST {
            return switch (top.def) {
                case EModule(name, attrs, body):
                    // Only rewrite within this module’s subtree
                    var newBody = [for (b in body) rewriteIn(b)];
                    makeASTWithMeta(EModule(name, attrs, newBody), top.metadata, top.pos);
                case EDefmodule(name2, doBlock):
                    var newDo = rewriteIn(doBlock);
                    makeASTWithMeta(EDefmodule(name2, newDo), top.metadata, top.pos);
                default:
                    // Outside modules, leave unchanged
                    top;
            }
        });
    }
}

#end
