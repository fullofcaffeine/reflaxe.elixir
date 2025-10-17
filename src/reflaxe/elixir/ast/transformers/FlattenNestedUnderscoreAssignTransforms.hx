package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * FlattenNestedUnderscoreAssignTransforms
 *
 * WHAT
 * - Flattens nested underscore assignments in matches:
 *   lhs = _ = expr    ->   lhs = expr
 *   lhs <- _ <- expr  ->   lhs <- expr
 *
 * WHY
 * - Builder/optimizations may introduce `_ = expr` scaffolding. Leaving it
 *   nested inside an outer assignment yields awkward tuples and duplicate calls.
 *   Flattening is a safe, semantics-preserving cleanup.
 */
class FlattenNestedUnderscoreAssignTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EBinary(Match, left, right):
                    var flatRight = stripUnderscoreAssign(right);
                    if (flatRight != right) makeASTWithMeta(EBinary(Match, left, flatRight), n.metadata, n.pos) else n;
                case EMatch(pat, rhs):
                    var flatRhs = stripUnderscoreAssign(rhs);
                    if (flatRhs != rhs) makeASTWithMeta(EMatch(pat, flatRhs), n.metadata, n.pos) else n;
                default:
                    n;
            }
        });
    }

    static function stripUnderscoreAssign(e: ElixirAST): ElixirAST {
        return switch (e.def) {
            case EBinary(Match, {def: EVar(name)}, rhs) if (name == "_"):
                stripUnderscoreAssign(rhs);
            case EMatch(PVar(name), rhs) if (name == "_"):
                stripUnderscoreAssign(rhs);
            case EParen(inner):
                var inner2 = stripUnderscoreAssign(inner);
                if (inner2 != inner) makeASTWithMeta(EParen(inner2), e.metadata, e.pos) else e;
            default:
                e;
        }
    }
}

#end

