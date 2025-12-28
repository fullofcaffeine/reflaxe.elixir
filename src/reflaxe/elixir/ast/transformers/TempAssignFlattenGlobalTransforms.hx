package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * TempAssignFlattenGlobalTransforms
 *
 * WHAT
 * - Flatten temp alias chains globally:
 *     outer = (temp = expr)  → outer = expr     when temp is a compiler temp (thisN/_thisN/g...)
 *     temp  = (outer = expr) → outer = expr

 *
 * WHY
 * - Avoid warnings and keep generated Elixir output idiomatic.

 *
 * HOW
 * - Walk the ElixirAST with `ElixirASTTransformer.transformNode` and rewrite matching nodes.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class TempAssignFlattenGlobalTransforms {
    static inline function isTempName(nm:String):Bool {
        if (nm == null) return false;
        if (nm.indexOf("this") == 0 || nm.indexOf("_this") == 0) return true;
        if (nm == "g" || (nm.charAt(0) == 'g' && nm.length > 1)) return true;
        return false;
    }

    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EBinary(Match, left, rhs):
                    switch (rhs.def) {
                        case EBinary(Match, leftInner, expr):
                            var innerName:Null<String> = switch (leftInner.def) { case EVar(nm): nm; default: null; };
                            if (innerName != null && isTempName(innerName)) {
                                return makeASTWithMeta(EBinary(Match, left, expr), n.metadata, n.pos);
                            }
                            n;
                        case EMatch(patInner, expr2):
                            var innerName2:Null<String> = switch (patInner) { case PVar(nm2): nm2; default: null; };
                            if (innerName2 != null && isTempName(innerName2)) {
                                return makeASTWithMeta(EBinary(Match, left, expr2), n.metadata, n.pos);
                            }
                            n;
                        default:
                            n;
                    }
                default:
                    n;
            }
        });
    }
}

#end

