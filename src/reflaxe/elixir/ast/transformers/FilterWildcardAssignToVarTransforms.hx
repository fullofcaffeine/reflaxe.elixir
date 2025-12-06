package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * FilterWildcardAssignToVarTransforms
 *
 * WHAT
 * - Repairs shapes like:
 *     if cond do
 *       _ = Enum.filter(var, fn ... -> ... end)
 *     end
 *     var
 *   by rewriting the wildcard assignment to rebind the same variable:
 *     var = Enum.filter(var, ...)
 *
 * WHY
 * - Some hygiene passes may conservatively discard assignments in if-branches.
 *   When the surrounding block returns the original variable, the intended
 *   behavior is to update the variable and then return it. This pass restores
 *   that intent without introducing app-specific logic.
 */
class FilterWildcardAssignToVarTransforms {
    public static function fixPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body):
                    var nb = fixBlock(body);
                    #if debug_filter_wildcard_assign
                    if (nb != body) trace('[FilterWildcardAssign] Rewrote in def ' + name + '/' + (args != null ? args.length : 0));
                    #end
                    makeASTWithMeta(EDef(name, args, guards, nb), n.metadata, n.pos);
                case EDefp(name, args, guards, body):
                    var nbp = fixBlock(body);
                    #if debug_filter_wildcard_assign
                    if (nbp != body) trace('[FilterWildcardAssign] Rewrote in defp ' + name + '/' + (args != null ? args.length : 0));
                    #end
                    makeASTWithMeta(EDefp(name, args, guards, nbp), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function fixBlock(node: ElixirAST): ElixirAST {
        return switch (node.def) {
            case EBlock(stmts) if (stmts != null && stmts.length >= 2):
                var retVar: Null<String> = switch (stmts[stmts.length - 1].def) { case EVar(v): v; default: null; };
                if (retVar == null) return node;
                var out:Array<ElixirAST> = [];
                for (i in 0...stmts.length - 1) {
                    switch (stmts[i].def) {
                        case EMatch(PWildcard, rhs):
                            if (isEnumFilterOfVar(rhs, retVar))
                                out[i] = makeASTWithMeta(EBinary(Match, makeAST(EVar(retVar)), rhs), stmts[i].metadata, stmts[i].pos);
                        case EBinary(Match, left, rhs2):
                            // Handle `_ = Enum.filter(var, ...)` represented as binary with left var "_"
                            switch (left.def) {
                                case EVar(n) if (n == "_"):
                                    if (isEnumFilterOfVar(rhs2, retVar))
                                        out[i] = makeASTWithMeta(EBinary(Match, makeAST(EVar(retVar)), rhs2), stmts[i].metadata, stmts[i].pos);
                                default:
                            }
                            // Handle `retVar = if ... do ... end` shapes: fix then-branch EDo and wildcard assigns
                            switch (left.def) {
                                case EVar(lhs) if (rhs2 != null && Type.enumConstructor(rhs2.def) == "EIf"):
                                    switch (rhs2.def) {
                                        case EIf(cond, thenBr, elseBr):
                                            var newThen = fixThenBranch(thenBr, lhs);
                                            if (newThen != thenBr) {
                                                #if debug_filter_wildcard_assign
                                                // DISABLED: trace('[FilterWildcardAssign] Rebinding in if-then branch for ' + lhs);
                                                #end
                                                out[i] = makeASTWithMeta(EBinary(Match, left, makeASTWithMeta(EIf(cond, newThen, elseBr), rhs2.metadata, rhs2.pos)), stmts[i].metadata, stmts[i].pos);
                                            }
                                        default:
                                    }
                                default:
                            }
                        case EIf(cond, thenBr, elseBr):
                            // Always normalize EDo inside then-branch to EBlock to avoid `if ... do do ... end` output
                            var normalizedThen = switch (thenBr.def) { case EDo(inner) if (inner != null): makeASTWithMeta(EBlock(inner), thenBr.metadata, thenBr.pos); default: thenBr; };
                            var newThen = retVar != null ? fixThenBranch(normalizedThen, retVar) : normalizedThen;
                            if (newThen != thenBr) {
                                #if debug_filter_wildcard_assign
                                // DISABLED: trace('[FilterWildcardAssign] Rebinding in standalone if-then to ' + retVar);
                                #end
                                out[i] = makeASTWithMeta(EIf(cond, newThen, elseBr), stmts[i].metadata, stmts[i].pos);
                            }
                        default:
                    }
                }
                // Also process the final statement for EDo-in-if normalization when present
                var lastIdx = stmts.length - 1;
                switch (stmts[lastIdx].def) {
                    case EIf(condF, thenF, elseF):
                        var normalizedThenF = switch (thenF.def) {
                            case EDo(innerF) if (innerF != null): makeASTWithMeta(EBlock(innerF), thenF.metadata, thenF.pos);
                            default: thenF;
                        };
                        if (normalizedThenF != thenF) out.push(makeASTWithMeta(EIf(condF, normalizedThenF, elseF), stmts[lastIdx].metadata, stmts[lastIdx].pos));
                        else out.push(stmts[lastIdx]);
                    default:
                        out.push(stmts[lastIdx]);
                }

                makeASTWithMeta(EBlock(out), node.metadata, node.pos);
            default:
                node;
        }
    }

    static function fixThenBranch(thenBr: ElixirAST, retVar:String): ElixirAST {
        // Broad rewrite inside then-branch: any `_ = Enum.filter(retVar, ...)` or
        // bare `Enum.filter(retVar, ...)` becomes `retVar = Enum.filter(retVar, ...)`.
        // We handle EDo/EBlock and single-expression branches.
        return switch (thenBr.def) {
            case EMatch(PWildcard, rhs):
                if (isEnumFilterOfVar(rhs, retVar))
                    makeASTWithMeta(EBinary(Match, makeAST(EVar(retVar)), rhs), thenBr.metadata, thenBr.pos) else thenBr;
            case EBinary(Match, left, rhs) :
                switch (left.def) {
                    case EVar(n) if (n == "_" && isEnumFilterOfVar(rhs, retVar)):
                        makeASTWithMeta(EBinary(Match, makeAST(EVar(retVar)), rhs), thenBr.metadata, thenBr.pos);
                    default: thenBr;
                }
            // Direct bare call inside then-branch (rare): replace with assignment
            case ERemoteCall({def: EVar("Enum")}, "filter", [_l, _p]) if (isEnumFilterOfVar(thenBr, retVar)):
                makeASTWithMeta(EBinary(Match, makeAST(EVar(retVar)), thenBr), thenBr.metadata, thenBr.pos);
            // Handle do-blocks produced by the printer (EDo) with multiple statements
            case EDo(inner) if (inner != null && inner.length > 0):
                var changedDo = false;
                var outDo = inner.copy();
                for (k in 0...inner.length) switch (outDo[k].def) {
                    case EMatch(PWildcard, rhs2) if (isEnumFilterOfVar(rhs2, retVar)):
                        outDo[k] = makeASTWithMeta(EBinary(Match, makeAST(EVar(retVar)), rhs2), outDo[k].metadata, outDo[k].pos);
                        changedDo = true;
                    case EBinary(Match, left2, rhs3):
                        switch (left2.def) {
                            case EVar(n2) if (n2 == "_" && isEnumFilterOfVar(rhs3, retVar)):
                                outDo[k] = makeASTWithMeta(EBinary(Match, makeAST(EVar(retVar)), rhs3), outDo[k].metadata, outDo[k].pos);
                                changedDo = true;
                            default:
                        }
                    case ERemoteCall({def: EVar("Enum")}, "filter", [l4, _]) if (switch (l4.def) { case EVar(v4) if (v4 == retVar): true; default: false; }):
                        outDo[k] = makeASTWithMeta(EBinary(Match, makeAST(EVar(retVar)), outDo[k]), outDo[k].metadata, outDo[k].pos);
                        changedDo = true;
                    default:
                }
                // IMPORTANT: When fixing then-branch content, emit EBlock so the outer
                // `if ... do` does not become `if ... do do ... end`. EDo here would
                // introduce a nested do/end which is invalid Elixir syntax.
                changedDo ? makeASTWithMeta(EBlock(outDo), thenBr.metadata, thenBr.pos) : thenBr;
            case EBlock(inner) if (inner != null && inner.length > 0):
                var changed = false;
                var outInner = inner.copy();
                for (k in 0...inner.length) switch (inner[k].def) {
                    case EMatch(PWildcard, rhs2) if (isEnumFilterOfVar(rhs2, retVar)):
                        outInner[k] = makeASTWithMeta(EBinary(Match, makeAST(EVar(retVar)), rhs2), inner[k].metadata, inner[k].pos);
                        changed = true;
                    case EBinary(Match, left2, rhs3):
                        switch (left2.def) {
                            case EVar(n2) if (n2 == "_" && isEnumFilterOfVar(rhs3, retVar)):
                                outInner[k] = makeASTWithMeta(EBinary(Match, makeAST(EVar(retVar)), rhs3), inner[k].metadata, inner[k].pos);
                                changed = true;
                            default:
                        }
                    case ERemoteCall({def: EVar("Enum")}, "filter", [l5, _]) if (switch (l5.def) { case EVar(v5) if (v5 == retVar): true; default: false; }):
                        outInner[k] = makeASTWithMeta(EBinary(Match, makeAST(EVar(retVar)), inner[k]), inner[k].metadata, inner[k].pos);
                        changed = true;
                    default:
                }
                changed ? makeASTWithMeta(EBlock(outInner), thenBr.metadata, thenBr.pos) : thenBr;
            default:
                thenBr;
        }
    }

    static function isEnumFilterOfVar(expr: ElixirAST, varName:String): Bool {
        return switch (expr.def) {
            case ERemoteCall({def: EVar("Enum")}, "filter", [l, _]):
                switch (l.def) { case EVar(v) if (v == varName): true; default: false; }
            default:
                false;
        }
    }
}

#end
