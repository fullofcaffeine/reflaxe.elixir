package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * AssignmentChainCleanupTransforms
 *
 * WHAT
 * - Collapse nested aliasing chains like `lhs = g = expr` into `lhs = expr` when
 *   the intermediate alias (e.g., `g`) is not used later in the same block.
 *
 * WHY
 * - Enum extraction and earlier passes may introduce nested matches that bind
 *   temporary aliases (`g`, `g1`, etc.) which are never referenced. Keeping them
 *   produces unused variable warnings. Removing unused inner matches is safe and
 *   yields idiomatic Elixir.
 *
 * HOW
 * - For each EBlock, scan statements. When a statement is a match whose RHS is
 *   another match `EMatch(PVar(alias), expr)` or `EBinary(Match, EVar(alias), expr)` and `alias`
 *   is not referenced in subsequent statements of the same block, rewrite the
 *   outer statement to bind directly to `expr`, removing the alias binding.
 */
class AssignmentChainCleanupTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case EBlock(stmts):
                    var out:Array<ElixirAST> = [];
                    var n = stmts.length;
                    for (i in 0...n) {
                        var s = stmts[i];
                        switch (s.def) {
                            case EBinary(Match, leftOuter, rightOuter):
                                var aliasName:Null<String> = null;
                                var innerExpr:Null<ElixirAST> = null;
                                switch (rightOuter.def) {
                                    case EBinary(Match, leftInner, deepExpr):
                                        switch (leftInner.def) { case EVar(a): aliasName = a; default: }
                                        innerExpr = deepExpr;
                                    case EMatch(patInner, deepExpr2):
                                        switch (patInner) { case PVar(a2): aliasName = a2; default: }
                                        innerExpr = deepExpr2;
                                    default:
                                }
                                if (aliasName != null && innerExpr != null && !nameUsedLater(stmts, i+1, aliasName)) {
                                    // Rewrite to lhs = innerExpr
                                    out.push(makeASTWithMeta(EBinary(Match, leftOuter, innerExpr), s.metadata, s.pos));
                                } else {
                                    out.push(s);
                                }
                            case EMatch(patOuter, rhsOuter):
                                var alias2:Null<String> = null;
                                var deep2:Null<ElixirAST> = null;
                                switch (rhsOuter.def) {
                                    case EBinary(Match, leftI2, expr2):
                                        switch (leftI2.def) { case EVar(a): alias2 = a; default: }
                                        deep2 = expr2;
                                    case EMatch(patI2, expr3):
                                        switch (patI2) { case PVar(a2): alias2 = a2; default: }
                                        deep2 = expr3;
                                    default:
                                }
                                if (alias2 != null && deep2 != null && !nameUsedLater(stmts, i+1, alias2)) {
                                    out.push(makeASTWithMeta(EMatch(patOuter, deep2), s.metadata, s.pos));
                                } else {
                                    out.push(s);
                                }
                            default:
                                out.push(s);
                        }
                    }
                    makeASTWithMeta(EBlock(out), node.metadata, node.pos);
                case EDo(stmts):
                    var out2:Array<ElixirAST> = [];
                    var n2 = stmts.length;
                    for (i in 0...n2) {
                        var s = stmts[i];
                        switch (s.def) {
                            case EBinary(Match, leftOuter, rightOuter):
                                var aliasName:Null<String> = null;
                                var innerExpr:Null<ElixirAST> = null;
                                switch (rightOuter.def) {
                                    case EBinary(Match, leftInner, deepExpr):
                                        switch (leftInner.def) { case EVar(a): aliasName = a; default: }
                                        innerExpr = deepExpr;
                                    case EMatch(patInner, deepExpr2):
                                        switch (patInner) { case PVar(a2): aliasName = a2; default: }
                                        innerExpr = deepExpr2;
                                    default:
                                }
                                if (aliasName != null && innerExpr != null && !nameUsedLater(stmts, i+1, aliasName)) {
                                    out2.push(makeASTWithMeta(EBinary(Match, leftOuter, innerExpr), s.metadata, s.pos));
                                } else {
                                    out2.push(s);
                                }
                            case EMatch(patOuter, rhsOuter):
                                var alias2:Null<String> = null;
                                var deep2:Null<ElixirAST> = null;
                                switch (rhsOuter.def) {
                                    case EBinary(Match, leftI2, expr2):
                                        switch (leftI2.def) { case EVar(a): alias2 = a; default: }
                                        deep2 = expr2;
                                    case EMatch(patI2, expr3):
                                        switch (patI2) { case PVar(a2): alias2 = a2; default: }
                                        deep2 = expr3;
                                    default:
                                }
                                if (alias2 != null && deep2 != null && !nameUsedLater(stmts, i+1, alias2)) {
                                    out2.push(makeASTWithMeta(EMatch(patOuter, deep2), s.metadata, s.pos));
                                } else {
                                    out2.push(s);
                                }
                            default:
                                out2.push(s);
                        }
                    }
                    makeASTWithMeta(EDo(out2), node.metadata, node.pos);
                default:
                    node;
            }
        });
    }

    static function nameUsedLater(stmts:Array<ElixirAST>, start:Int, name:String):Bool {
        for (j in start...stmts.length) if (statementUsesName(stmts[j], name)) return true;
        return false;
    }

    static function statementUsesName(s: ElixirAST, name:String):Bool {
        var used = false;
        function visit(n: ElixirAST):Void {
            if (used || n == null || n.def == null) return;
            switch (n.def) {
                case EVar(v) if (v == name): used = true;
                case EBlock(ss): for (x in ss) visit(x);
                case EIf(c,t,e): visit(c); visit(t); if (e != null) visit(e);
                case ECase(expr, cs): visit(expr); for (c in cs) visit(c.body);
                case EBinary(_, l, r): visit(l); visit(r);
                case EMatch(_, rhs): visit(rhs);
                case ECall(t,_,as): if (t != null) visit(t); if (as != null) for (a in as) visit(a);
                case ERemoteCall(t2,_,as2): visit(t2); if (as2 != null) for (a2 in as2) visit(a2);
                case EFn(clauses): for (cl in clauses) visit(cl.body);
                case ERaw(code):
                    if (code != null && code.indexOf("#{" + name) != -1) used = true;
                case EString(s):
                    if (s != null && s.indexOf("#{" + name) != -1) used = true;
                default:
            }
        }
        visit(s);
        return used;
    }
}

#end
