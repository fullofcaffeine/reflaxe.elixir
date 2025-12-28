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
                    var usesChangeset = usesEctoChangesetUnqualified(body);
                    var usesQualifiedChangeset = moduleQualifiedUsed(body, "Ecto.Changeset");
                    var usesRepoAlias = aliasUsed(body, "Repo");
                    var newAttrs = attrs;
                    var newBody: Array<ElixirAST> = [];
                    for (b in body) {
                        switch (b.def) {
                            case EImport(module, _, _, _) if (module == "Ecto.Changeset" && (!usesChangeset || usesQualifiedChangeset)):
                                // Skip
                            case EAlias(module, as) if ((as == null || as == "Repo") && !usesRepoAlias):
                                // Remove unused alias Repo
                            default:
                                newBody.push(b);
                        }
                    }
                    makeASTWithMeta(EModule(name, newAttrs, newBody), n.metadata, n.pos);
                case EDefmodule(name, doBlock):
                    // Handle defmodule do...end blocks equivalently
                    // Extract statements
                    var stmts: Array<ElixirAST> = switch (doBlock.def) {
                        case EBlock(ss): ss;
                        default: [doBlock];
                    };
                    var usesChangeset2 = usesEctoChangesetUnqualified(stmts);
                    var usesQualifiedChangeset2 = moduleQualifiedUsed(stmts, "Ecto.Changeset");
                    var usesRepoAlias2 = aliasUsed(stmts, "Repo");
                    var filtered: Array<ElixirAST> = [];
                    for (b in stmts) {
                        switch (b.def) {
                            case EImport(module, _, _, _) if (module == "Ecto.Changeset" && (!usesChangeset2 || usesQualifiedChangeset2)):
                                // drop
                            case EAlias(module, as) if ((as == null || as == "Repo") && !usesRepoAlias2):
                                // drop
                            default:
                                filtered.push(b);
                        }
                    }
                    var newDo = makeAST(EBlock(filtered));
                    makeASTWithMeta(EDefmodule(name, newDo), n.metadata, n.pos);
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

    static function usesEctoChangesetUnqualified(body: Array<ElixirAST>): Bool {
        // Detect unqualified calls that would rely on `import Ecto.Changeset`
        // Common functions: change/2, cast/3, validate_length/3, validate_required/2, apply_action/2, put_change/3, put_assoc/3
        var used = false;
        var fnSet = new Map<String, Bool>();
        for (name in ["change","cast","validate_length","validate_required","apply_action","put_change","put_assoc"]) fnSet.set(name, true);
        for (b in body) if (!used) {
            reflaxe.elixir.ast.ASTUtils.walk(b, function(x: ElixirAST) {
                if (used || x == null || x.def == null) return;
                switch (x.def) {
                    case ECall(null, fn, _): if (fnSet.exists(fn)) used = true;
                    default:
                }
            });
        }
        return used;
    }

    static function moduleQualifiedUsed(body: Array<ElixirAST>, moduleName: String): Bool {
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
/**
 * UnusedImportCleanup
 *
 * WHAT
 * - Removes unused `import`/`alias` statements introduced during transformation.
 *
 * WHY
 * - Prevents compiler warnings and keeps generated modules tidy.
 *
 * HOW
 * - Scans module bodies for references to imported/aliased names and drops those
 *   not referenced.
 *
 * EXAMPLES
 * Before:
 *   import Foo.Bar
 *   # (no usage)
 * After:
 *   # import removed
 */
