package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * AssignChainGenericSimplifyTransforms
 *
 * WHAT
 * - Simplify nested match chains `outer = inner = expr` inside blocks/EFn bodies by
 *   dropping the unused side of the chain based on forward usage.
 *
 * WHY
 * - Codegen sometimes emits chained assignments to thread values; intermediate temps
 *   (e.g., g, this1) often go unused and produce warnings.
 *
 * HOW
 * - For each EBlock/EDo/EFn body, scan statements. If a statement is
 *     EBinary(Match, leftOuter, EBinary(Match, leftInner, expr))
 *   and `inner` is not used later, rewrite to `leftOuter = expr`.
 *   Else if `outer` is not used later, rewrite to `leftInner = expr`.
 */
class AssignChainGenericSimplifyTransforms {
    public static function simplifyPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EBlock(stmts): makeASTWithMeta(EBlock(simplifyStmts(stmts)), n.metadata, n.pos);
                case EDo(stmts2): makeASTWithMeta(EDo(simplifyStmts(stmts2)), n.metadata, n.pos);
                case EFn(clauses):
                    var newClauses = [];
                    for (cl in clauses) {
                        var b = cl.body;
                        var nb = switch (b.def) {
                            case EBlock(ss): makeASTWithMeta(EBlock(simplifyStmts(ss)), b.metadata, b.pos);
                            case EDo(ss2): makeASTWithMeta(EDo(simplifyStmts(ss2)), b.metadata, b.pos);
                            default: b;
                        };
                        newClauses.push({ args: cl.args, guard: cl.guard, body: nb });
                    }
                    makeASTWithMeta(EFn(newClauses), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function simplifyStmts(stmts:Array<ElixirAST>): Array<ElixirAST> {
        var out:Array<ElixirAST> = [];
        var i = 0;
        while (i < stmts.length) {
            var s = stmts[i];
            switch (s.def) {
                case EBinary(Match, leftOuter, rhsOuter):
                    // Pattern: outer = inner ; inner = expr  → outer = expr
                    var collapsed = false;
                    switch (rhsOuter.def) {
                        case EVar(aliasName) if (i + 1 < stmts.length):
                            switch (stmts[i + 1].def) {
                                case EBinary(Match, left2, exprX):
                                    switch (left2.def) {
                                        case EVar(nm2) if (nm2 == aliasName):
                                            out.push(makeASTWithMeta(EBinary(Match, leftOuter, exprX), s.metadata, s.pos));
                                            i += 2; // skip next
                                            collapsed = true;
                                        default:
                                    }
                                default:
                            }
                        default:
                    }
                    if (collapsed) continue;
                    switch (rhsOuter.def) {
                        case EBinary(Match, leftInner, expr):
                            var innerName:Null<String> = switch (leftInner.def) { case EVar(n): n; default: null; };
                            var outerName:Null<String> = switch (leftOuter.def) { case EVar(n2): n2; default: null; };
                            if (innerName != null && !usedLater(stmts, i + 1, innerName)) {
                                out.push(makeASTWithMeta(EBinary(Match, leftOuter, expr), s.metadata, s.pos));
                                continue;
                            }
                            if (outerName != null && !usedLater(stmts, i + 1, outerName)) {
                                out.push(makeASTWithMeta(EBinary(Match, leftInner, expr), s.metadata, s.pos));
                                continue;
                            }
                            out.push(s);
                        case EMatch(patInner, expr2):
                            var innerName2:Null<String> = switch (patInner) { case PVar(n3): n3; default: null; };
                            var outerName2:Null<String> = switch (leftOuter.def) { case EVar(n4): n4; default: null; };
                            if (innerName2 != null && !usedLater(stmts, i + 1, innerName2)) {
                                out.push(makeASTWithMeta(EBinary(Match, leftOuter, expr2), s.metadata, s.pos));
                                continue;
                            }
                            if (outerName2 != null && !usedLater(stmts, i + 1, outerName2)) {
                                out.push(makeASTWithMeta(EMatch(patInner, expr2), s.metadata, s.pos));
                                continue;
                            }
                            out.push(s);
                        default:
                            out.push(s);
                    }
                    i++;
                default:
                    out.push(s);
                    i++;
            }
        }
        return out;
    }

    static function usedLater(stmts:Array<ElixirAST>, startIdx:Int, name:String):Bool {
        for (j in startIdx...stmts.length) if (stmtUsesVar(stmts[j], name)) return true; return false;
    }

    static function stmtUsesVar(n: ElixirAST, name: String): Bool {
        var found = false;
        function walk(x: ElixirAST, inPattern: Bool): Void {
            if (found || x == null) return;
            switch (x.def) {
                case EVar(v) if (!inPattern && v == name): found = true;
                case EBinary(Match, left, rhs): walk(rhs, false);
                case EMatch(pat, rhs2): walk(rhs2, false);
                case EBlock(ss): for (s in ss) walk(s, false);
                case EDo(ss2): for (s in ss2) walk(s, false);
                case EIf(c,t,e): walk(c, false); walk(t, false); if (e != null) walk(e, false);
                case EBinary(_, l, r): walk(l, false); walk(r, false);
                case ECall(tgt, _, args): if (tgt != null) walk(tgt, false); for (a in args) walk(a, false);
                case ERemoteCall(tgt2, _, args2): walk(tgt2, false); for (a2 in args2) walk(a2, false);
                case ECase(expr, cs): walk(expr, false); for (c in cs) walk(c.body, false);
                default:
            }
        }
        walk(n, false);
        return found;
    }
}

#end
