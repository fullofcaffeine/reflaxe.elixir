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
                            Sys.println('[ChangesetChainCleanup] cs = (thisN = expr) → cs = expr');
                            #end
                            makeASTWithMeta(EBinary(Match, left, expr), x.metadata, x.pos);
                        case EBinary(Match, leftInner2, expr2):
                            var innerIsCs = switch (leftInner2.def) { case EVar(n2) if (n2 == "cs"): true; default: false; };
                            var outerIsThis = switch (left.def) { case EVar(n3) if (n3 != null && (n3.indexOf("this") == 0 || n3.indexOf("_this") == 0)): true; default: false; };
                            if (innerIsCs && outerIsThis) {
                                #if debug_hygiene
                                Sys.println('[ChangesetChainCleanup] thisN = (cs = expr) → cs = expr');
                                #end
                                makeASTWithMeta(EBinary(Match, leftInner2, expr2), x.metadata, x.pos);
                            } else x;
                        default:
                            x;
                    }
                default:
                    x;
            }
        });
    }
}

#end
