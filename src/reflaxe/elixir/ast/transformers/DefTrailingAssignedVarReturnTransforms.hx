package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * DefTrailingAssignedVarReturnTransforms
 *
 * WHAT
 * - For function definitions (EDef), if the last statement is an assignment to a non-temp variable,
 *   append that variable as a trailing expression to count as a usage (and function result).
 *
 * WHY
 * - Elixir warns when a variable is assigned but never read; returning the var at end prevents warnings
 *   and matches expected functional style.

 *
 * HOW
 * - Walk the ElixirAST with `ElixirASTTransformer.transformNode` and rewrite matching nodes.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class DefTrailingAssignedVarReturnTransforms {
    static inline function isTemp(name:String):Bool {
        if (name == null) return false;
        if (name.indexOf("this") == 0) return true;
        if (name.indexOf("_this") == 0) return true;
        if (name == "g" || (name.charAt(0) == 'g' && name.length > 1)) return true;
        if (name.length > 0 && name.charAt(0) == '_') return true;
        return false;
    }

    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body):
                    var newBody = appendTrailingVarIfNeeded(body);
                    makeASTWithMeta(EDef(name, args, guards, newBody), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function appendTrailingVarIfNeeded(body: ElixirAST): ElixirAST {
        return switch (body.def) {
            case EBlock(stmts):
                if (stmts.length == 0) body else {
                    var last = stmts[stmts.length - 1];
                    var name:Null<String> = null;
                    switch (last.def) {
                        case EBinary(Match, left, _): switch (left.def) { case EVar(nm): name = nm; default: }
                        case EMatch(pat, _): switch (pat) { case PVar(nm2): name = nm2; default: }
                        default:
                    }
                    if (name != null && !isTemp(name)) {
                        makeASTWithMeta(EBlock(stmts.concat([makeAST(EVar(name))])), body.metadata, body.pos);
                    } else body;
                }
            default:
                body;
        }
    }
}

#end

