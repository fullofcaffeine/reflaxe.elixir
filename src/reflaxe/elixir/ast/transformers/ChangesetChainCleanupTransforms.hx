package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ChangesetChainCleanupTransforms
 *
 * WHAT
 * - Clean up double/nested assignment artifacts in changeset functions:
 *     cs = thisN = Ecto.Changeset.change(...)          → cs = Ecto.Changeset.change(...)
 *     thisN = cs = Ecto.Changeset.validate_*(cs, ...)  → cs = Ecto.Changeset.validate_*(cs, ...)
 *     cs = thisN                                       → cs (drop alias)
 *
 * WHY
 * - Avoids redundant temps and restores idiomatic pipeline-like shapes inside
 *   changeset functions, preventing warnings and improving readability.
 *
 * HOW
 * - Within any function named `changeset`, collapse nested assignments where the inner or outer
 *   assigns to `cs` or a `thisN` temp.
 *
 * EXAMPLES
 * Elixir (before):
 *   cs = this1 = Ecto.Changeset.change(user, attrs)
 *   this2 = cs = Ecto.Changeset.validate_required(cs, [:name])
 * Elixir (after):
 *   cs = Ecto.Changeset.change(user, attrs)
 *   cs = Ecto.Changeset.validate_required(cs, [:name])
 */
class ChangesetChainCleanupTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body) if (name == "changeset"):
                    var nb = collapseNested(body);
                    nb = dropTrailingCsAlias(nb);
                    makeASTWithMeta(EDef(name, args, guards, nb), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function collapseNested(b: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(b, function(x: ElixirAST): ElixirAST {
            return switch (x.def) {
                case EBinary(Match, left, rhs):
                    var isCs = switch (left.def) { case EVar(nm) if (nm == "cs"): true; default: false; };
                    switch (rhs.def) {
                        case EBinary(Match, leftInner, expr) if (isCs):
                            #if debug_hygiene
                            // DEBUG: Sys.println('[ChangesetChainCleanup] cs = (thisN = expr) → cs = expr');
                            #end
                            makeASTWithMeta(EBinary(Match, left, expr), x.metadata, x.pos);
                        case EBinary(Match, leftInner2, expr2):
                            var innerIsCs = switch (leftInner2.def) { case EVar(n2) if (n2 == "cs"): true; default: false; };
                            var outerIsThis = switch (left.def) { case EVar(n3) if (n3 != null && (n3.indexOf("this") == 0 || n3.indexOf("_this") == 0)): true; default: false; };
                            if (innerIsCs && outerIsThis) {
                                #if debug_hygiene
                                // DEBUG: Sys.println('[ChangesetChainCleanup] thisN = (cs = expr) → cs = expr');
                                #end
                                makeASTWithMeta(EBinary(Match, leftInner2, expr2), x.metadata, x.pos);
                            } else x;
                        case EVar(n) if (isCs):
                            // cs = thisN  → drop alias, keep cs
                            makeASTWithMeta(EVar("cs"), x.metadata, x.pos);
                        default:
                            x;
                    }
                default:
                    x;
            }
        });
    }

    /**
     * dropTrailingCsAlias
     *
     * WHAT
     * - Remove trailing statements of the form `cs = thisN` left after earlier
     *   cleanup inside changeset functions.
     */
    static function dropTrailingCsAlias(b: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(b, function(x: ElixirAST): ElixirAST {
            return switch (x.def) {
                case EBlock(stmts):
                    var trimmed = stmts;
                    while (trimmed.length > 0) {
                        var last = trimmed[trimmed.length - 1];
                        var isAlias = switch (last.def) {
                            case EBinary(Match, {def: EVar("cs")}, {def: EVar(name)}):
                                // any alias to temp; drop
                                true;
                            default: false;
                        };
                        if (isAlias) trimmed = trimmed.slice(0, trimmed.length - 1); else break;
                    }
                    makeASTWithMeta(EBlock(trimmed), x.metadata, x.pos);
                case EDo(stmts):
                    var trimmedDo = stmts;
                    while (trimmedDo.length > 0) {
                        var lastDo = trimmedDo[trimmedDo.length - 1];
                        var isAliasDo = switch (lastDo.def) {
                            case EBinary(Match, {def: EVar("cs")}, {def: EVar(name)}):
                                true;
                            default: false;
                        };
                        if (isAliasDo) trimmedDo = trimmedDo.slice(0, trimmedDo.length - 1); else break;
                    }
                    makeASTWithMeta(EDo(trimmedDo), x.metadata, x.pos);
                default:
                    x;
            }
        });
    }
}

#end
