package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

/**
 * CaseClauseFixTransforms
 *
 * WHAT
 * - Repairs clause bodies after enum/tuple pattern extraction, removing redundant
 *   elem(...) calls and fixing references to bound variables.
 *
 * WHY
 * - Earlier extraction may leave artifacts like elem(_g, 1) even after binding.
 *   Cleaning them improves readability and avoids unused temp warnings.
 *
 * HOW
 * - Detect assigns like v = elem(_g, i) where v is already pattern-bound, and drop them.
 *   Replace remaining elem(_g, i) with the bound variable.
 *
 * EXAMPLES
 * Before:
 *   case _g do
 *     {_, id} -> id1 = elem(_g, 1); id1
 *   end
 * After:
 *   case tuple do
 *     {_, id} -> id
 *   end
 */
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ElixirASTBuilder;

/**
 * CaseClauseFixTransforms
 *
 * WHY: Elixir requires a valid expression on the right side of `->` in case/cond.
 *      Our builder can produce empty blocks in case arm bodies (printing nothing),
 *      which results in syntax errors like "syntax error before: '->'".
 * WHAT: Ensure every case clause body is non-empty by replacing empty bodies with `nil`.
 * HOW: For each ECase clause, if body is EBlock([]) or effectively empty, replace with ENil.
 */
class CaseClauseFixTransforms {
    public static function caseClauseEmptyBodyToNilPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            if (node == null || node.def == null) return node;
            return switch(node.def) {
                case ECase(target, clauses):
                    var fixed = clauses.map(c -> {
                        var body = c.body;
                        var newBody = isEmptyBody(body) ? makeAST(ENil) : body;
                        return { pattern: c.pattern, guard: c.guard, body: newBody };
                    });
                    makeASTWithMeta(ECase(target, fixed), node.metadata, node.pos);
                default:
                    node;
            }
        });
    }

    static function isEmptyBody(body: ElixirAST): Bool {
        if (body == null || body.def == null) return true;
        return switch(body.def) {
            case EBlock(exprs):
                if (exprs == null || exprs.length == 0) return true;
                // Consider blocks consisting only of self-assignments that print empty
                // E.g., `v = v` for non-temp vars
                for (e in exprs) {
                    switch(e.def) {
                        case EMatch(PVar(name), {def: EVar(rhs)}):
                            if (name == rhs && !ElixirASTBuilder.isTempPatternVarName(name)) {
                                // continue checking
                            } else {
                                return false;
                            }
                        default:
                            return false;
                    }
                }
                // All expressions were no-op self-assignments
                true;
            default: false;
        }
    }
}

#end
