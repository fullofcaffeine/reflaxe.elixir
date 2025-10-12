package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * TupleLhsDiscardTransforms
 *
 * WHAT
 * - Discard tuple-pattern LHS matches of arity 1 (e.g., {x} = expr) and keep expr.
 *
 * WHY
 * - Loop-lowering may introduce tuple-pattern matches solely to force evaluation order.
 *   When the LHS is not used, it creates unused-variable warnings. Keeping RHS preserves semantics.
 */
class TupleLhsDiscardTransforms {
    public static function discardPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EBlock(stmts):
                    var out = [];
                    for (s in stmts) switch (s.def) {
                        case EMatch(pat, rhs):
                            switch (pat) {
                                case PTuple(els) if (els != null && els.length == 1):
                                    out.push(makeASTWithMeta(rhs.def, rhs.metadata, rhs.pos));
                                default:
                                    out.push(s);
                            }
                        case EBinary(Match, left, rhs2):
                            switch (left.def) {
                                case ETuple(els2) if (els2 != null && els2.length == 1):
                                    out.push(makeASTWithMeta(rhs2.def, rhs2.metadata, rhs2.pos));
                                default:
                                    out.push(s);
                            }
                        default:
                            out.push(s);
                    }
                    makeASTWithMeta(EBlock(out), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }
}

#end

