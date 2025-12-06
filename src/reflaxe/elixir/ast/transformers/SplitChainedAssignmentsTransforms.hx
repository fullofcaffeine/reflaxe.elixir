package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * SplitChainedAssignmentsTransforms
 *
 * WHAT
 * - Splits chained assignments like `a = b = expr` into two statements:
 *   `b = expr; a = b`. This improves readability and prevents odd shapes
 *   produced by earlier inline/hoist steps (e.g., in reduce_while bodies).
 *
 * WHY
 * - Chained matches are harder to read and can confuse later hygiene passes.
 *   Tests (SwitchSideEffects) expect clean, linear assignments.
 *
 * HOW
 * - For any EBlock([...]) walk statements; when a statement is
 *   `EBinary(Match, EVar(a), EBinary(Match, EVar(b), rhs))`, rewrite it into
 *   two consecutive statements. Applies recursively within EBlock/EDo/EFn bodies.
 */
class SplitChainedAssignmentsTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case EBlock(stmts):
                    var out:Array<ElixirAST> = [];
                    var i = 0;
                    while (i < stmts.length) {
                        var s = stmts[i];
                        // New fold: [a = (b = expr); if(cond) ... else b] → [b = expr; a = if(cond) ... else b]
                        if (i + 1 < stmts.length) {
                            switch (s.def) {
                                case EBinary(Match, {def: EVar(a0)}, {def: EBinary(Match, {def: EVar(b0)}, rhs0)}):
                                    switch (stmts[i + 1].def) {
                                        case EIf(cond0, then0, else0):
                                            var elseIsB0 = switch (else0.def) { case EVar(bb) if (bb == b0): true; default: false; };
                                            if (elseIsB0) {
                                                // Emit: b = rhs; a = if ... end
                                                out.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(b0), s.metadata, s.pos), rhs0), s.metadata, s.pos));
                                                out.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(a0), s.metadata, s.pos), makeASTWithMeta(EIf(cond0, then0, else0), stmts[i + 1].metadata, stmts[i + 1].pos)), s.metadata, s.pos));
                                                i += 2;
                                                continue;
                                            }
                                        default:
                                    }
                                default:
                            }
                        }

                        // Non-adjacent fold within small window: allow one intervening statement
                        var windowEnd = Std.int(Math.min(stmts.length - 1, i + 3));
                        var matched = false;
                        switch (s.def) {
                            case EBinary(Match, {def: EVar(aW)}, {def: EBinary(Match, {def: EVar(bW)}, rhsW)}):
                                var j = i + 1;
                                while (j <= windowEnd) {
                                    switch (stmts[j].def) {
                                        case EIf(condW, thenW, elseW):
                                            var elseIsBW = switch (elseW.def) { case EVar(bb) if (bb == bW): true; default: false; };
                                            if (elseIsBW) {
                                                out.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(bW), s.metadata, s.pos), rhsW), s.metadata, s.pos));
                                                out.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(aW), s.metadata, s.pos), makeASTWithMeta(EIf(condW, thenW, elseW), stmts[j].metadata, stmts[j].pos)), s.metadata, s.pos));
                                                // Copy any intervening statements that are side-effect free EVar references
                                                for (k in i + 1...j) out.push(stmts[k]);
                                                i = j + 1;
                                                matched = true;
                                            }
                                        default:
                                    }
                                    if (matched) break;
                                    j++;
                                }
                            default:
                        }
                        if (matched) continue;
                        // First, try to fold [b = expr; a = b; if(cond) ... else b] → [b = expr; a = if(cond) ... else b]
                        var folded = false;
                        if (i + 2 < stmts.length) {
                            switch (s.def) {
                                case EBinary(Match, {def: EVar(b)}, _):
                                    switch (stmts[i + 1].def) {
                                        case EBinary(Match, {def: EVar(a)}, {def: EVar(b2)}) if (b2 == b):
                                            switch (stmts[i + 2].def) {
                                                case EIf(cond, thenExpr, elseExpr):
                                                    var elseIsB = switch (elseExpr.def) { case EVar(b3) if (b3 == b): true; default: false; };
                                                    if (elseIsB) {
                                                        out.push(s); // keep b = expr
                                                        var assignAIf = makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(a), s.metadata, s.pos), makeASTWithMeta(EIf(cond, thenExpr, elseExpr), stmts[i + 2].metadata, stmts[i + 2].pos)), stmts[i + 1].metadata, stmts[i + 1].pos);
                                                        out.push(assignAIf);
                                                        i += 3;
                                                        folded = true;
                                                    }
                                                default:
                                            }
                                        default:
                                    }
                                default:
                            }
                        }
                        if (folded) continue;
                switch (s.def) {
                    case EBinary(Match, left, right):
                                switch (left.def) {
                                    case EVar(a):
                                        switch (right.def) {
                                            case EBinary(Match, innerLeft, rhs):
                                                switch (innerLeft.def) {
                                                    case EVar(b):
                                                        // emit: b = rhs; a = b
                                                        var first = makeASTWithMeta(EBinary(Match, innerLeft, rhs), s.metadata, s.pos);
                                                        var second = makeASTWithMeta(EBinary(Match, left, makeASTWithMeta(EVar(b), right.metadata, right.pos)), s.metadata, s.pos);
                                                        out.push(first);
                                                        out.push(second);
                                                    default:
                                                        out.push(s);
                                                        i++;
                                                }
                                            default:
                                                out.push(s);
                                                i++;
                                        }
                                    case EBinary(Match, left2, mid):
                                        // Handle left-nested: (a = b) = rhs → b = rhs; a = b
                                        switch (left2.def) {
                                            case EVar(a2):
                                                switch (mid.def) {
                                                    case EVar(b):
                                                        var firstL = makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(b), mid.metadata, mid.pos), right), s.metadata, s.pos);
                                                        var secondL = makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(a2), left2.metadata, left2.pos), makeASTWithMeta(EVar(b), mid.metadata, mid.pos)), s.metadata, s.pos);
                                                        out.push(firstL);
                                                        out.push(secondL);
                                                        i++;
                                                    default:
                                                        out.push(s); i++;
                                                }
                                            default:
                                                out.push(s); i++;
                                        }
                                    default:
                                        out.push(s);
                                        i++;
                                }
                            case EMatch(pat, rhs):
                                // a = b = expr  as  EMatch(PVar(a), EBinary(Match, EVar(b), expr))
                                switch (pat) {
                                    case PVar(a):
                                        switch (rhs.def) {
                                            case EBinary(Match, innerLeft2, rhs2):
                                                switch (innerLeft2.def) {
                                                    case EVar(b2):
                                                        var first2 = makeASTWithMeta(EBinary(Match, innerLeft2, rhs2), s.metadata, s.pos);
                                                        var second2 = makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(a), rhs.metadata, rhs.pos), makeASTWithMeta(EVar(b2), rhs.metadata, rhs.pos)), s.metadata, s.pos);
                                                        out.push(first2);
                                                        out.push(second2);
                                            default:
                                                out.push(s);
                                                i++;
                                        }
                    case EMatch(pat, rhs):
                        // Handle EMatch variant: a = (b = expr) → b = expr; a = b
                        switch (pat) {
                            case PVar(a3):
                                switch (rhs.def) {
                                    case EBinary(Match, innerLeft3, rhs3):
                                        switch (innerLeft3.def) {
                                            case EVar(b3):
                                                var first3 = makeASTWithMeta(EBinary(Match, innerLeft3, rhs3), s.metadata, s.pos);
                                                var second3 = makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(a3), rhs.metadata, rhs.pos), makeASTWithMeta(EVar(b3), rhs.metadata, rhs.pos)), s.metadata, s.pos);
                                                out.push(first3);
                                                out.push(second3);
                                            default:
                                                out.push(s);
                                                i++;
                                        }
                                    default:
                                        out.push(s);
                                        i++;
                                }
                            default:
                                out.push(s);
                                i++;
                        }
                    default:
                        out.push(s);
                        i++;
                }
                                    default:
                                        out.push(s);
                                        i++;
                                }
                            default:
                                // Pattern: [i] b = expr; [i+1] a = b; [i+2] if(cond_on_b) ... else b
                                var transformed = false;
                                if (i + 2 < stmts.length) {
                                    switch (s.def) {
                                        case EBinary(Match, {def: EVar(b)}, rhs0):
                                            switch (stmts[i + 1].def) {
                                                case EBinary(Match, {def: EVar(a)}, {def: EVar(b2)}) if (b2 == b):
                                                    switch (stmts[i + 2].def) {
                                                        case EIf(cond, thenExpr, elseExpr):
                                                            // Require else branch returns b, so we can rewrite a = if ...
                                                            var elseIsB = switch (elseExpr.def) { case EVar(b3) if (b3 == b): true; default: false; };
                                                            if (elseIsB) {
                                                                var assignAIf = makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(a), s.metadata, s.pos), makeASTWithMeta(EIf(cond, thenExpr, elseExpr), stmts[i + 2].metadata, stmts[i + 2].pos)), stmts[i + 1].metadata, stmts[i + 1].pos);
                                                                out.push(s);          // keep b = expr
                                                                out.push(assignAIf);  // replace a = b with a = if ... end
                                                                i += 3;               // consume three statements
                                                                transformed = true;
                                                            }
                                                        default:
                                                    }
                                                default:
                                            }
                                        default:
                                    }
                                }
                                if (!transformed) {
                                    out.push(s);
                                    i++;
                                }
                        }
                    }
                    makeASTWithMeta(EBlock(out), node.metadata, node.pos);
                case EDo(stmts2):
                    var out2:Array<ElixirAST> = [];
                    var i2 = 0;
                    while (i2 < stmts2.length) {
                        var s = stmts2[i2];
                        // New fold for EDo: [a = (b = expr); if ... else b] → [b = expr; a = if ...]
                        if (i2 + 1 < stmts2.length) {
                            switch (s.def) {
                                case EBinary(Match, {def: EVar(a0)}, {def: EBinary(Match, {def: EVar(b0)}, rhs0)}):
                                    switch (stmts2[i2 + 1].def) {
                                        case EIf(cond0, then0, else0):
                                            var elseIsB0 = switch (else0.def) { case EVar(bb) if (bb == b0): true; default: false; };
                                            if (elseIsB0) {
                                                out2.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(b0), s.metadata, s.pos), rhs0), s.metadata, s.pos));
                                                out2.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(a0), s.metadata, s.pos), makeASTWithMeta(EIf(cond0, then0, else0), stmts2[i2 + 1].metadata, stmts2[i2 + 1].pos)), s.metadata, s.pos));
                                                i2 += 2;
                                                continue;
                                            }
                                        default:
                                    }
                                default:
                            }
                        }

                        // Non-adjacent window in EDo
                        var windowEnd2 = Std.int(Math.min(stmts2.length - 1, i2 + 3));
                        var matched2 = false;
                        switch (s.def) {
                            case EBinary(Match, {def: EVar(aW2)}, {def: EBinary(Match, {def: EVar(bW2)}, rhsW2)}):
                                var j2 = i2 + 1;
                                while (j2 <= windowEnd2) {
                                    switch (stmts2[j2].def) {
                                        case EIf(condW2, thenW2, elseW2):
                                            var elseIsBW2 = switch (elseW2.def) { case EVar(bb2) if (bb2 == bW2): true; default: false; };
                                            if (elseIsBW2) {
                                                out2.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(bW2), s.metadata, s.pos), rhsW2), s.metadata, s.pos));
                                                out2.push(makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(aW2), s.metadata, s.pos), makeASTWithMeta(EIf(condW2, thenW2, elseW2), stmts2[j2].metadata, stmts2[j2].pos)), s.metadata, s.pos));
                                                for (k2 in i2 + 1...j2) out2.push(stmts2[k2]);
                                                i2 = j2 + 1;
                                                matched2 = true;
                                            }
                                        default:
                                    }
                                    if (matched2) break;
                                    j2++;
                                }
                            default:
                        }
                        if (matched2) continue;
                        // Fold triple in EDo
                        var folded2 = false;
                        if (i2 + 2 < stmts2.length) {
                            switch (s.def) {
                                case EBinary(Match, {def: EVar(b)}, _):
                                    switch (stmts2[i2 + 1].def) {
                                        case EBinary(Match, {def: EVar(a)}, {def: EVar(b2)}) if (b2 == b):
                                            switch (stmts2[i2 + 2].def) {
                                                case EIf(cond, thenExpr, elseExpr):
                                                    var elseIsB2 = switch (elseExpr.def) { case EVar(b3) if (b3 == b): true; default: false; };
                                                    if (elseIsB2) {
                                                        out2.push(s);
                                                        var assignAIf2 = makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(a), s.metadata, s.pos), makeASTWithMeta(EIf(cond, thenExpr, elseExpr), stmts2[i2 + 2].metadata, stmts2[i2 + 2].pos)), stmts2[i2 + 1].metadata, stmts2[i2 + 1].pos);
                                                        out2.push(assignAIf2);
                                                        i2 += 3;
                                                        folded2 = true;
                                                    }
                                                default:
                                            }
                                        default:
                                    }
                                default:
                            }
                        }
                        if (folded2) continue;
                        switch (s.def) {
                            case EBinary(Match, left, right):
                                switch (left.def) {
                                    case EVar(a):
                                        switch (right.def) {
                                            case EBinary(Match, innerLeft, rhs):
                                                switch (innerLeft.def) {
                                                    case EVar(b):
                                                        var first = makeASTWithMeta(EBinary(Match, innerLeft, rhs), s.metadata, s.pos);
                                                        var second = makeASTWithMeta(EBinary(Match, left, makeASTWithMeta(EVar(b), right.metadata, right.pos)), s.metadata, s.pos);
                                                        out2.push(first);
                                                        out2.push(second);
                                                    default:
                                                        out2.push(s);
                                                        i2++;
                                                }
                                            default:
                                                out2.push(s);
                                                i2++;
                                        }
                                    default:
                                        out2.push(s);
                                        i2++;
                                }
                            case EMatch(pat, rhs):
                                switch (pat) {
                                    case PVar(a2):
                                        switch (rhs.def) {
                                            case EBinary(Match, innerLeft2, rhs2):
                                                switch (innerLeft2.def) {
                                                    case EVar(b2):
                                                        var first2 = makeASTWithMeta(EBinary(Match, innerLeft2, rhs2), s.metadata, s.pos);
                                                        var second2 = makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(a2), rhs.metadata, rhs.pos), makeASTWithMeta(EVar(b2), rhs.metadata, rhs.pos)), s.metadata, s.pos);
                                                        out2.push(first2);
                                                        out2.push(second2);
                                                    default:
                                                        out2.push(s);
                                                        i2++;
                                                }
                                            default:
                                                out2.push(s);
                                                i2++;
                                        }
                                    default:
                                        out2.push(s);
                                        i2++;
                                }
                            default:
                                var transformed = false;
                                if (i2 + 2 < stmts2.length) {
                                    switch (s.def) {
                                        case EBinary(Match, {def: EVar(b)}, rhs0):
                                            switch (stmts2[i2 + 1].def) {
                                                case EBinary(Match, {def: EVar(a)}, {def: EVar(b2)}) if (b2 == b):
                                                    switch (stmts2[i2 + 2].def) {
                                                        case EIf(cond, thenExpr, elseExpr):
                                                            var elseIsB = switch (elseExpr.def) { case EVar(b3) if (b3 == b): true; default: false; };
                                                            if (elseIsB) {
                                                                var assignAIf = makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar(a), s.metadata, s.pos), makeASTWithMeta(EIf(cond, thenExpr, elseExpr), stmts2[i2 + 2].metadata, stmts2[i2 + 2].pos)), stmts2[i2 + 1].metadata, stmts2[i2 + 1].pos);
                                                                out2.push(s);
                                                                out2.push(assignAIf);
                                                                i2 += 3;
                                                                transformed = true;
                                                            }
                                                        default:
                                                    }
                                                default:
                                            }
                                        default:
                                    }
                                }
                                if (!transformed) {
                                    out2.push(s);
                                    i2++;
                                }
                        }
                    }
                    makeASTWithMeta(EDo(out2), node.metadata, node.pos);
                case EFn(clauses):
                    var outClauses = [];
                    for (cl in clauses) {
                        // Recursively transform the body to split chained assignments
                        var newBody = transformPass(cl.body);
                        outClauses.push({ args: cl.args, guard: cl.guard, body: newBody });
                    }
                    makeASTWithMeta(EFn(outClauses), node.metadata, node.pos);
                default:
                    node;
            }
        });
    }
}

#end
