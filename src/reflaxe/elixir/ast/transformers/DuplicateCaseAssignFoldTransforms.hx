package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ElixirASTPrinter;

/**
 * DuplicateCaseAssignFoldTransforms
 *
 * WHAT
 * - Folds the common pattern:
 *     var = _ = Mod.func(args)
 *     case Mod.func(args) do ... end
 *   into a single assignment:
 *     var = case Mod.func(args) do ... end
 *
 * WHY
 * - Avoids duplicate side effects and ensures subsequent references to `var`
 *   receive the case result (typically the {:ok, v} value), fixing patterns
 *   like broadcasting with a tuple instead of the unwrapped value.
 *
 * HOW
 * - Scan adjacent statement pairs in EBlock. If s1 is an assignment whose RHS
 *   ultimately unwraps to the same remote call as the ECase scrutinee in s2,
 *   replace the pair with a single match assigning the case result to the var.
 */
class DuplicateCaseAssignFoldTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EBlock(stmts):
                    var out:Array<ElixirAST> = [];
                    var i = 0;
                    while (i < stmts.length) {
                        if (i + 1 < stmts.length) {
                            var s1 = stmts[i];
                            var s2 = stmts[i+1];
                            var lhsVar = extractAssignedVar(s1);
                            var s1Call = extractRightmostCall(s1);
                            var s2CaseCall = extractCaseHeadCall(s2);
                            if (lhsVar != null && s1Call != null && s2CaseCall != null && callsEqual(s1Call, s2CaseCall)) {
                                // Fold into: lhsVar = case ... end
                                var folded = makeASTWithMeta(EBinary(Match, makeAST(EVar(lhsVar)), s2), s2.metadata, s2.pos);
                                out.push(folded);
                                i += 2;
                                continue;
                            }
                        }
                        out.push(stmts[i]);
                        i++;
                    }
                    makeASTWithMeta(EBlock(out), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function extractAssignedVar(n: ElixirAST): Null<String> {
        return switch (n.def) {
            case EBinary(Match, left, _):
                switch (left.def) {
                    case EVar(name) if (name != "_"): name;
                    default: null;
                }
            case EMatch(pat, _):
                switch (pat) { case PVar(name) if (name != "_"): name; default: null; }
            default: null;
        }
    }

    static function extractRightmostCall(n: ElixirAST): Null<ElixirAST> {
        function unwrap(e: ElixirAST): ElixirAST {
            return switch (e.def) {
                case EBinary(Match, _, r): unwrap(r);
                case EMatch(_, r2): unwrap(r2);
                case EParen(inner): unwrap(inner);
                default: e;
            }
        }
        var e = unwrap(n);
        return switch (e.def) {
            case ERemoteCall(_, _, _): e;
            case ECall(_, _, _): e;
            default: null;
        }
    }

    static function extractCaseHeadCall(n: ElixirAST): Null<ElixirAST> {
        return switch (n.def) {
            case ECase(expr, _):
                var ex = expr;
                while (ex != null && ex.def != null) switch (ex.def) {
                    case EParen(inner): ex = inner; continue;
                    default: break;
                }
                ex;
            default: null;
        }
    }

    static function callsEqual(a: ElixirAST, b: ElixirAST): Bool {
        return switch [a.def, b.def] {
            case [ERemoteCall(ma, fa, aa), ERemoteCall(mb, fb, bb)]:
                if (fa != fb) return false;
                var maS = ElixirASTPrinter.printAST(ma);
                var mbS = ElixirASTPrinter.printAST(mb);
                if (maS != mbS) return false;
                if (aa.length != bb.length) return false;
                for (i in 0...aa.length) if (ElixirASTPrinter.printAST(aa[i]) != ElixirASTPrinter.printAST(bb[i])) return false;
                true;
            case [ECall(ta, fa, aa), ECall(tb, fb, bb)]:
                if (fa != fb) return false;
                if (ElixirASTPrinter.printAST(ta) != ElixirASTPrinter.printAST(tb)) return false;
                if (aa.length != bb.length) return false;
                for (i in 0...aa.length) if (ElixirASTPrinter.printAST(aa[i]) != ElixirASTPrinter.printAST(bb[i])) return false;
                true;
            default: false;
        }
    }
}

#end
