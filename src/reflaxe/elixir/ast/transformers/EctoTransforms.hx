package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ASTUtils;

/**
 * EctoTransforms: Normalize Ecto query variable usage within function scope.
 *
 * WHY: Generated code for dynamic Ecto queries may introduce temp variables
 * (e.g., `query2`, `_value`) while references in subsequent calls still use
 * base names (`query`, `value`). This leads to undefined variable errors at
 * Mix compile time.
 *
 * WHAT: Within each function (EDef/EDefp),
 * - Detect the variable bound to Ecto.Queryable.to_query/1 and consistently
 *   use it as the query arg for Ecto.Query.where/2 and Repo.all/1.
 * - If a reference to an undeclared var exists and its underscore-prefixed
 *   counterpart is declared (e.g., `empty_params` vs `_empty_params`), rewrite
 *   the reference to the declared underscore name.
 *
 * HOW: Collect declared var names from pattern bindings. Track the first
 * encountered binding of Ecto.Queryable.to_query and use that as canonical
 * query var. Rewrite relevant ERemoteCall arguments and Repo.all call sites.
 */
class EctoTransforms {
    public static function ectoQueryVarConsistencyPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case EDef(name, args, guards, body):
                    var newBody = normalizeInBody(body);
                    makeASTWithMeta(EDef(name, args, guards, newBody), node.metadata, node.pos);
                case EDefp(name, args, guards, body):
                    var newBody = normalizeInBody(body);
                    makeASTWithMeta(EDefp(name, args, guards, newBody), node.metadata, node.pos);
                default:
                    node;
            }
        });
    }

    static function normalizeInBody(body: ElixirAST): ElixirAST {
        // Collect declared vars and pick canonical query var
        var declared = new Map<String, Bool>();
        var canonicalQuery: Null<String> = null;

        function collect(n: ElixirAST): Void {
            if (n == null || n.def == null) return;
            switch (n.def) {
                case EMatch(pattern, expr):
                    // Collect declared names
                    collectPatternVars(pattern, declared);
                    // Detect Ecto.Queryable.to_query binding
                    switch (expr.def) {
                        case ERemoteCall(mod, func, _):
                            if (canonicalQuery == null
                                && func == "to_query"
                                && isModuleName(mod, "Ecto.Queryable")) {
                                switch (pattern) {
                                    case PVar(v): canonicalQuery = v;
                                    default:
                                }
                            }
                        default:
                    }
                default:
                    ASTUtils.walk(n, collect);
            }
        }

        function isModuleName(mod: ElixirAST, name: String): Bool {
            return switch (mod.def) {
                case EVar(n): n == name;
                default: false;
            }
        }

        collect(body);

        // Rewrite visitors
        function rewrite(n: ElixirAST): ElixirAST {
            if (n == null || n.def == null) return n;
            return switch (n.def) {
                // Rewrite Repo.all(query) → Repo.all(canonicalQuery)
                case ERemoteCall(mod, func, args) if (func == "all" && isModuleName(mod, "Repo") && args.length == 1 && canonicalQuery != null):
                    switch (args[0].def) {
                        case EVar(arg) if (arg != canonicalQuery):
                            makeASTWithMeta(ERemoteCall(mod, func, [makeAST(EVar(canonicalQuery))]), n.metadata, n.pos);
                        default:
                            n;
                    }
                // Rewrite Ecto.Query.where(query, ...) → Ecto.Query.where(canonicalQuery, ...)
                case ERemoteCall(mod2, func2, args2) if (func2 == "where" && isModuleName(mod2, "Ecto.Query") && args2.length >= 1 && canonicalQuery != null):
                    switch (args2[0].def) {
                        case EVar(arg0) if (arg0 != canonicalQuery):
                            var newArgs = args2.copy();
                            newArgs[0] = makeAST(EVar(canonicalQuery));
                            makeASTWithMeta(ERemoteCall(mod2, func2, newArgs), n.metadata, n.pos);
                        default:
                            n;
                    }
                // If referencing an undeclared var, but declared has underscore-prefixed version, rewrite
                case EVar(name):
                    if (!declared.exists(name)) {
                        var alt = "_" + name;
                        if (declared.exists(alt)) {
                            makeASTWithMeta(EVar(alt), n.metadata, n.pos);
                        } else {
                            n;
                        }
                    } else {
                        n;
                    }
                // Recursively visit children for other nodes
                default:
                    return ElixirASTTransformer.transformNode(n, rewrite);
            }
        }

        return ElixirASTTransformer.transformNode(body, rewrite);
    }
}

#end
