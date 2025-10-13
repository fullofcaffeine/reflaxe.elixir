package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * LocalAssignUnderscoreLateTransforms
 *
 * WHAT
 * - In block-like contexts (EBlock/EDo/EFn bodies), underscore local assignment targets
 *   when they are not referenced later in the same block. Also handles nested assignments
 *   inside `outer = (inner = expr)` by underscoring `inner` when unused.
 *
 * WHY
 * - Removes warnings for throwaway temps (e.g., g, g3) created by intermediate rewrites.
 */
class LocalAssignUnderscoreLateTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EBlock(stmts): makeASTWithMeta(EBlock(processStmts(stmts)), n.metadata, n.pos);
                case EDo(stmts2): makeASTWithMeta(EDo(processStmts(stmts2)), n.metadata, n.pos);
                case EFn(clauses):
                    var newClauses = [];
                    for (cl in clauses) {
                        var b = cl.body;
                        var nb = switch (b.def) {
                            case EBlock(ss): makeASTWithMeta(EBlock(processStmts(ss)), b.metadata, b.pos);
                            case EDo(ss2): makeASTWithMeta(EDo(processStmts(ss2)), b.metadata, b.pos);
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

    static function processStmts(stmts:Array<ElixirAST>): Array<ElixirAST> {
        var out:Array<ElixirAST> = [];
        for (i in 0...stmts.length) {
            var s = stmts[i];
            switch (s.def) {
                case EBinary(Match, left, rhs):
                    // Nested: outer = (inner = expr) → underscore inner if unused later
                    var collapse = false;
                    var collapsedExpr:Null<ElixirAST> = null;
                    var newRhs = switch (rhs.def) {
                        case EBinary(Match, leftInner, expr):
                            var innerName:Null<String> = switch (leftInner.def) { case EVar(n): n; default: null; };
                            if (innerName != null && !usedLater(stmts, i + 1, innerName)) {
                                // Collapse nested: outer = (inner = expr) -> outer = expr
                                collapse = true;
                                collapsedExpr = expr;
                                rhs;
                            } else rhs;
                        default: rhs;
                    };
                    // Left var unused later → underscore
                    var leftName:Null<String> = switch (left.def) { case EVar(n): n; default: null; };
                    var newLeft = left;
                    if (leftName != null && !usedLater(stmts, i + 1, leftName)) {
                        newLeft = makeASTWithMeta(EVar('_' + leftName), left.metadata, left.pos);
                    }
                    if (collapse && collapsedExpr != null) {
                        #if debug_hygiene
                        Sys.println('[LocalAssignUnderscoreLate] collapsing nested assign into outer');
                        #end
                        out.push(makeASTWithMeta(EBinary(Match, newLeft, collapsedExpr), s.metadata, s.pos));
                    } else {
                        out.push(makeASTWithMeta(EBinary(Match, newLeft, newRhs), s.metadata, s.pos));
                    }
                default:
                    out.push(s);
            }
        }
        return out;
    }

    static function usedLater(stmts:Array<ElixirAST>, start:Int, name:String):Bool {
        for (j in start...stmts.length) if (stmtUsesVar(stmts[j], name)) return true; return false;
    }

    static function stmtUsesVar(n:ElixirAST, name:String):Bool {
        var found = false;
        function walk(x:ElixirAST, inPattern:Bool):Void {
            if (x == null || found) return;
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
