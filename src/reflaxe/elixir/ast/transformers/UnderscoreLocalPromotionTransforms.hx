package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * UnderscoreLocalPromotionTransforms
 *
 * WHAT
 * - Promote local variables assigned with an underscored name (e.g., `_this = ...`)
 *   to the base name (`this`) when the base is not otherwise declared in scope
 *   and the variable is referenced later in the same block.
 *
 * WHY
 * - Avoids warnings like "the underscored variable `_this` is used after being set".
 */
class UnderscoreLocalPromotionTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EBlock(stmts):
                    var out:Array<ElixirAST> = [];
                    var renameMap:Map<String,String> = new Map();
                    for (i in 0...stmts.length) {
                        var s = stmts[i];
                        // Apply existing renames to current statement first
                        var s0 = applyRenames(s, renameMap);
                        var s1 = switch (s0.def) {
                            case EMatch(PVar(varName), rhs) if (shouldPromote(varName, stmts, i)):
                                var base = varName.substr(1);
                                renameMap.set(varName, base);
                                makeASTWithMeta(EMatch(PVar(base), rhs), s0.metadata, s0.pos);
                            case EBinary(Match, left, right):
                                switch (left.def) {
                                    case EVar(vname) if (shouldPromote(vname, stmts, i)):
                                        var base2 = vname.substr(1);
                                        renameMap.set(vname, base2);
                                        makeASTWithMeta(EBinary(Match, makeAST(EVar(base2)), right), s0.metadata, s0.pos);
                                    default: s0;
                                }
                            default:
                                s0;
                        };
                        out.push(s1);
                    }
                    makeASTWithMeta(EBlock(out), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static inline function shouldPromote(varName:String, stmts:Array<ElixirAST>, idx:Int):Bool {
        return varName != null && varName.length > 0 && varName.charAt(0) == '_' && usedLater(stmts, idx+1, varName) && !declaredLater(stmts, idx+1, varName.substr(1));
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

    static function declaredLater(stmts:Array<ElixirAST>, start:Int, name:String): Bool {
        var found = false;
        for (j in start...stmts.length) if (!found) switch (stmts[j].def) {
            case EMatch(PVar(v), _): if (v == name) found = true;
            default:
        }
        return found;
    }

    static function applyRenames(node: ElixirAST, rename: Map<String,String>): ElixirAST {
        if (Lambda.count(rename) == 0) return node;
        return ElixirASTTransformer.transformNode(node, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EVar(v) if (rename.exists(v)):
                    makeASTWithMeta(EVar(rename.get(v)), n.metadata, n.pos);
                default: n;
            }
        });
    }
}

#end
