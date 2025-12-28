package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * UnusedRepoAliasCleanupFinalPass
 *
 * WHAT
 * - Removes `alias <App>.Repo, as: Repo` (or `alias <App>.Repo`) statements
 *   when `Repo` is not referenced in the module body.
 *
 * WHY
 * - Some late alias injectors may add a Repo alias even when all calls are
 *   fully-qualified (e.g., `TodoApp.Repo.update/1`). Elixir warns on unused
 *   aliases; dropping them keeps output clean.

 *
 * HOW
 * - Walk the ElixirAST with `ElixirASTTransformer.transformNode` and rewrite matching nodes.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class UnusedRepoAliasCleanupFinalPass {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body):
                    var usesRepo = aliasUsed(body, "Repo");
                    if (!usesRepo) {
                        var filtered:Array<ElixirAST> = [];
                        for (b in body) switch (b.def) {
                            case EAlias(module, as) if ((as == null || as == "Repo") && module != null && module.indexOf(".Repo") > 0):
                                // drop
                            default:
                                filtered.push(b);
                        }
                        makeASTWithMeta(EModule(name, attrs, filtered), n.metadata, n.pos);
                    } else n;
                case EDefmodule(name2, doBlock):
                    // Handle defmodule do ... end
                    var usesRepo2 = aliasUsed(doBlockToList(doBlock), "Repo");
                    if (!usesRepo2) {
                        var filtered2 = filterAliases(doBlock, "Repo");
                        makeASTWithMeta(EDefmodule(name2, filtered2), n.metadata, n.pos);
                    } else n;
                default:
                    n;
            }
        });
    }

    static function aliasUsed(body:Array<ElixirAST>, aliasName:String): Bool {
        var used = false;
        for (b in body) if (!used) {
            reflaxe.elixir.ast.ASTUtils.walk(b, function(x: ElixirAST) {
                if (used || x == null || x.def == null) return;
                switch (x.def) {
                    case ERemoteCall(mod, _, _) | ECall(mod, _, _):
                        if (mod != null) switch (mod.def) { case EVar(n) if (n == aliasName): used = true; default: }
                    case EVar(v) if (v == aliasName): used = true;
                    default:
                }
            });
        }
        return used;
    }

    static inline function doBlockToList(doBlock: ElixirAST): Array<ElixirAST> {
        return switch (doBlock.def) { case EBlock(ss): ss; default: [doBlock]; }
    }

    static function filterAliases(doBlock: ElixirAST, aliasName:String): ElixirAST {
        var ss = doBlockToList(doBlock);
        var filtered:Array<ElixirAST> = [];
        for (b in ss) switch (b.def) {
            case EAlias(module, as) if ((as == null || as == aliasName) && module != null && module.indexOf(".Repo") > 0):
                // drop
            default:
                filtered.push(b);
        }
        return makeAST(EBlock(filtered));
    }
}

#end
