package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;

/**
 * UnusedImportCleanup
 *
 * WHAT
 * - Remove unused `import` directives such as `import Ecto.Changeset` when the
 *   module isn’t actually referenced in the file (remote calls).
 *
 * WHY
 * - Avoid compiler warnings and keep generated code idiomatic.
 *
 * HOW
 * - For EModule bodies: scan for ERemoteCall with module "Ecto.Changeset" (or
 *   other modules we target). If not found, drop EImport("Ecto.Changeset", ...).
 */
class UnusedImportCleanup {
    public static function cleanupPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body):
                    var usesChangeset = moduleUsed(body, "Ecto.Changeset");
                    var usesRepoAlias = aliasUsed(body, "Repo");
                    var newAttrs = attrs;
                    var newBody: Array<ElixirAST> = [];
                    for (b in body) {
                        switch (b.def) {
                            case EImport(module, _, _) if (module == "Ecto.Changeset" && !usesChangeset):
                                // Skip
                            case EAlias(module, as) if ((as == null || as == "Repo") && !usesRepoAlias):
                                // Remove unused alias Repo
                            default:
                                newBody.push(b);
                        }
                    }
                    makeASTWithMeta(EModule(name, newAttrs, newBody), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function moduleUsed(body: Array<ElixirAST>, moduleName: String): Bool {
        var used = false;
        for (b in body) if (!used) {
            reflaxe.elixir.ast.ASTUtils.walk(b, function(x: ElixirAST) {
                if (used || x == null || x.def == null) return;
                switch (x.def) {
                    case ERemoteCall(mod, _, _):
                        switch (mod.def) {
                            case EVar(n) if (n == moduleName): used = true;
                            default:
                        }
                    default:
                }
            });
        }
        return used;
    }

    static function aliasUsed(body: Array<ElixirAST>, aliasName: String): Bool {
        var used = false;
        for (b in body) if (!used) {
            reflaxe.elixir.ast.ASTUtils.walk(b, function(x: ElixirAST) {
                if (used || x == null || x.def == null) return;
                switch (x.def) {
                    case ERemoteCall(mod, _, _) | ECall(mod, _, _):
                        if (mod != null) {
                            switch (mod.def) {
                                case EVar(n) if (n == aliasName): used = true;
                                default:
                            }
                        }
                    case EVar(v) if (v == aliasName):
                        used = true;
                    default:
                }
            });
        }
        return used;
    }
}

#end
