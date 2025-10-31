package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * LocalAssignDiscardIfUnusedTransforms
 *
 * WHAT
 * - Replace `var = expr` statements with `expr` when `var` is not referenced
 *   in any subsequent statement of the same block.
 *
 * WHY
 * - Avoids warnings for underscored variables that are assigned but never used
 *   (e.g., `_params = case ... end`), while preserving side effects.
 */
class LocalAssignDiscardIfUnusedTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EBlock(stmts):
                    var out:Array<ElixirAST> = [];
                    for (i in 0...stmts.length) {
                        var s = stmts[i];
                        var replaced = switch (s.def) {
                            case EMatch(PVar(v), rhs) if (!usedLater(stmts, i+1, v)):
                                // Drop the assignment; keep rhs for side effects
                                makeASTWithMeta(rhs.def, s.metadata, s.pos);
                            case EBinary(Match, {def: EVar(v)}, rhs) if (!usedLater(stmts, i+1, v)):
                                makeASTWithMeta(rhs.def, s.metadata, s.pos);
                            default:
                                s;
                        }
                        out.push(replaced);
                    }
                    makeASTWithMeta(EBlock(out), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function usedLater(stmts:Array<ElixirAST>, start:Int, name:String): Bool {
        var found = false;
        for (j in start...stmts.length) if (!found) {
            reflaxe.elixir.ast.ASTUtils.walk(stmts[j], function(x:ElixirAST){
                switch (x.def) { case EVar(v) if (v == name): found = true; default: }
            });
        }
        return found;
    }
}

#end

