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
                                var innerAliasName:Null<String> = null;
                                var innerRightExpr:Null<ElixirAST> = null;
                                var innerIsWildcard:Bool = false;
                                switch (rightOuter.def) {
                                    case EBinary(Match, leftInner, innerExpr):
                                        switch (leftInner.def) {
                                            case EVar(varName): innerAliasName = varName;
                                            case EUnderscore: innerIsWildcard = true;
                                            default:
                                        }
                                        innerRightExpr = innerExpr;
                                    case EMatch(innerPattern, innerPatExpr):
                                        switch (innerPattern) {
                                            case PVar(variableName): innerAliasName = variableName;
                                            case PWildcard: innerIsWildcard = true;
                                            default:
                                        }
                                        innerRightExpr = innerPatExpr;
                                    default:
                                }
                                if ((innerIsWildcard || (innerAliasName != null && !nameUsedLater(stmts, i+1, innerAliasName))) && innerRightExpr != null) {
                                    // Rewrite to leftOuter = innerRightExpr (underscore or unused alias)
                                    out.push(makeASTWithMeta(EBinary(Match, leftOuter, innerRightExpr), s.metadata, s.pos));
                                } else {
                                    out.push(s);
                                }
                            case EMatch(patOuter, rhsOuter):
                                var innerAliasName:Null<String> = null;
                                var innerRightExpr:Null<ElixirAST> = null;
                                var innerIsWildcard:Bool = false;
                                switch (rhsOuter.def) {
                                    case EBinary(Match, aliasLeft, aliasRightExpr):
                                        switch (aliasLeft.def) {
                                            case EVar(variableName): innerAliasName = variableName;
                                            case EUnderscore: innerIsWildcard = true;
                                            default:
                                        }
                                        innerRightExpr = aliasRightExpr;
                                    case EMatch(matchPattern, matchExpr):
                                        switch (matchPattern) {
                                            case PVar(variableName): innerAliasName = variableName;
                                            case PWildcard: innerIsWildcard = true;
                                            default:
                                        }
                                        innerRightExpr = matchExpr;
                                    default:
                                }
                                if ((innerIsWildcard || (innerAliasName != null && !nameUsedLater(stmts, i+1, innerAliasName))) && innerRightExpr != null) {
                                    out.push(makeASTWithMeta(EMatch(patOuter, innerRightExpr), s.metadata, s.pos));
                                } else {
                                    out.push(s);
                                }
                            default:
                                out.push(s);
                        }
                    }
                    makeASTWithMeta(EBlock(out), node.metadata, node.pos);
                case EDo(stmts):
                    var doOut:Array<ElixirAST> = [];
                    var doCount = stmts.length;
                    for (i in 0...doCount) {
                        var s = stmts[i];
                        switch (s.def) {
                            case EBinary(Match, leftOuter, rightOuter):
                                var innerAliasNameDo:Null<String> = null;
                                var innerRightExprDo:Null<ElixirAST> = null;
                                switch (rightOuter.def) {
                                    case EBinary(Match, leftInner, innerExpr):
                                        switch (leftInner.def) { case EVar(variableName): innerAliasNameDo = variableName; default: }
                                        innerRightExprDo = innerExpr;
                                    case EMatch(innerPattern, innerMatchExpr):
                                        switch (innerPattern) { case PVar(variableName): innerAliasNameDo = variableName; default: }
                                        innerRightExprDo = innerMatchExpr;
                                    default:
                                }
                                if (innerAliasNameDo != null && innerRightExprDo != null && !nameUsedLater(stmts, i+1, innerAliasNameDo)) {
                                    doOut.push(makeASTWithMeta(EBinary(Match, leftOuter, innerRightExprDo), s.metadata, s.pos));
                                } else {
                                    doOut.push(s);
                                }
                            case EMatch(patOuter, rhsOuter):
                                var innerAliasNameDoMatch:Null<String> = null;
                                var innerRightExprDoMatch:Null<ElixirAST> = null;
                                switch (rhsOuter.def) {
                                    case EBinary(Match, aliasLeft, aliasRightExpr):
                                        switch (aliasLeft.def) { case EVar(variableName): innerAliasNameDoMatch = variableName; default: }
                                        innerRightExprDoMatch = aliasRightExpr;
                                    case EMatch(matchPattern, matchExpr):
                                        switch (matchPattern) { case PVar(variableName): innerAliasNameDoMatch = variableName; default: }
                                        innerRightExprDoMatch = matchExpr;
                                    default:
                                }
                                if (innerAliasNameDoMatch != null && innerRightExprDoMatch != null && !nameUsedLater(stmts, i+1, innerAliasNameDoMatch)) {
                                    doOut.push(makeASTWithMeta(EMatch(patOuter, innerRightExprDoMatch), s.metadata, s.pos));
                                } else {
                                    doOut.push(s);
                                }
                            default:
                                doOut.push(s);
                        }
                    }
                    makeASTWithMeta(EDo(doOut), node.metadata, node.pos);
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
                case ERemoteCall(remoteTarget,_,remoteArgs): visit(remoteTarget); if (remoteArgs != null) for (arg in remoteArgs) visit(arg);
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
