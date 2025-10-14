package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * IfConstSimplifyTransforms
 *
 * WHAT
 * - Simplify conditionals with constant conditions:
 *   if true/1 do A else B end  -> A
 *   if false/0 do A else B end -> (B || nil)
 *
 * WHY
 * - Late passes may introduce sentinel literals in conditions; removing them yields
 *   clearer and warning-free output.
 *
 * HOW
 * - For EIf nodes, if the condition is a recognized truthy literal (true, :true, 1),
 *   replace the whole if with the then-branch; if falsey (false, :false, 0),
 *   replace with else-branch or nil when else is missing.
 *
 * EXAMPLES
 * Haxe:
 *   if (true) trace(1) else trace(0);
 * Elixir (before):
 *   if true do 1 else 0 end
 * Elixir (after):
 *   1
 */
class IfConstSimplifyTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EIf(cond, thenBr, elseBr):
                    if (isTruth(cond)) thenBr
                    else if (isFalsey(cond)) (elseBr != null ? elseBr : makeASTWithMeta(ENil, n.metadata, n.pos))
                    else n;
                default:
                    n;
            }
        });
    }

    static inline function isTruth(e: ElixirAST): Bool {
        return switch (e.def) {
            case EBoolean(true): true;
            case EAtom(a) if (a == "true"): true;
            case EInteger(v) if (v == 1): true;
            default: false;
        };
    }

    static inline function isFalsey(e: ElixirAST): Bool {
        return switch (e.def) {
            case EBoolean(false): true;
            case EAtom(a) if (a == "false"): true;
            case EInteger(v) if (v == 0): true;
            default: false;
        };
    }
}

#end
