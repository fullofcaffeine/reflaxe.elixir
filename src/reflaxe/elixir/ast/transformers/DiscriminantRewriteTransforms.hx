package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ElixirASTBuilder;

/**
 * DiscriminantRewriteTransforms
 *
 * WHY: Haxe desugars switch into `_g = expr; case _g do ... end`. If the alias `_g` is later
 *      removed or not emitted, we get `case _g do` (undefined). Even when present, this pattern
 *      is less idiomatic than directly matching on `expr`.
 * WHAT: Rewrite adjacent `_g = expr; case _g do ...` blocks into `case expr do ...` and drop the alias.
 * HOW: Detect EBlock of two statements (EMatch PVar(temp), init) and ECase(EVar(temp), clauses),
 *      where temp is a Haxe temp (ElixirASTBuilder.isTempPatternVarName). Replace with ECase(init, clauses).
 */
class DiscriminantRewriteTransforms {
    public static function discriminantRewritePass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            if (node == null || node.def == null) return node;
            return switch(node.def) {
                case EBlock(exprs) if (exprs.length >= 1):
                    var i = 0;
                    var out = [];
                    while (i < exprs.length) {
                        if (i < exprs.length - 1) {
                            switch(exprs[i].def) {
                                case EMatch(PVar(varName), initExpr):
                                    // Only consider compiler temp vars like g/_g/g1/_g1
                                    if (ElixirASTBuilder.isTempPatternVarName(varName)) {
                                        switch(exprs[i + 1].def) {
                                            case ECase(caseExpr, clauses):
                                                switch(caseExpr.def) {
                                                    case EVar(v) if (v == varName):
                                                        // Rewrite: drop alias, replace case target with initExpr
                                                        out.push(makeASTWithMeta(ECase(initExpr, clauses), exprs[i + 1].metadata, exprs[i + 1].pos));
                                                        i += 2;
                                                        continue;
                                                    default:
                                                }
                                            default:
                                        }
                                    }
                                default:
                            }
                        }
                        out.push(exprs[i]);
                        i++;
                    }
                    // Second pass: rewrite standalone `case _g do` using earliest prior assignment in same block
                    var changed = false;
                    var finalExprs = [];
                    for (idx in 0...out.length) {
                        var e = out[idx];
                        switch(e.def) {
                            case ECase(caseExpr, clauses):
                                switch(caseExpr.def) {
                                    case EVar(v) if (ElixirASTBuilder.isTempPatternVarName(v)):
                                        // search backwards for prior assignment to v
                                        var j = idx - 1;
                                        var foundInit: Null<ElixirAST> = null;
                                        while (j >= 0) {
                                        switch(out[j].def) {
                                            case EMatch(PVar(n), init) if (namesMatch(n, v)):
                                                    foundInit = init; break;
                                                default:
                                            }
                                            if (foundInit != null) break;
                                            j--;
                                        }
                                        if (foundInit != null) {
                                            finalExprs.push(makeASTWithMeta(ECase(foundInit, clauses), e.metadata, e.pos));
                                            changed = true;
                                            continue;
                                        }
                                    default:
                                }
                            default:
                        }
                        finalExprs.push(e);
                    }
                    if (changed || out.length != exprs.length) makeASTWithMeta(EBlock(finalExprs), node.metadata, node.pos) else node;

                default:
                    node;
            }
        });
    }

    static inline function namesMatch(a: String, b: String): Bool {
        if (a == b) return true;
        // Consider leading underscore variants equivalent: g3 == _g3
        return (a.charAt(0) == '_' && a.substr(1) == b) || (b.charAt(0) == '_' && b.substr(1) == a);
    }
}

#end
