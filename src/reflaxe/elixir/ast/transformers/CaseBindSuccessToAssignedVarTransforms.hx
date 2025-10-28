package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ElixirASTPrinter;

/**
 * CaseBindSuccessToAssignedVarTransforms
 *
 * WHAT
 * - When a variable is assigned from a side-effecting call and immediately
 *   followed by a case on the same call that returns the success value, bind
 *   that success value to the variable inside the case and drop the initial
 *   assignment. This ensures subsequent uses of the variable refer to the
 *   unwrapped success value rather than a tuple.
 *
 * Pattern (shape-based):
 *   var = _ = Mod.func(args)
 *   case Mod.func(args) do
 *     {:ok, u} -> u
 *     {:error, r} -> ...
 *   end
 *
 * Rewritten to:
 *   case Mod.func(args) do
 *     {:ok, u} -> var = u; var
 *     {:error, r} -> ...
 *   end
 *
 */
class CaseBindSuccessToAssignedVarTransforms {
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
                            var varName = assignedVarFromNestedUnderscore(s1);
                            var call1 = extractRightmostCall(s1);
                            var caseOn = extractCaseHeadCall(s2);
                            if (varName != null && call1 != null && caseOn != null && callsEqual(call1, caseOn)) {
                                var boundCase = bindSuccessVarInCase(s2, varName);
                                if (boundCase != null) {
                                    out.push(boundCase);
                                    i += 2;
                                    continue;
                                }
                            }
                            // New shape: lhs = (temp = call); case temp do {:ok, u} -> u ... end
                            var tempMatch = extractVarTempCall(s1);
                            if (tempMatch.lhs != null && tempMatch.temp != null && tempMatch.call != null) {
                                var caseTempVar = extractCaseHeadVar(s2);
                                if (caseTempVar != null && caseTempVar == tempMatch.temp) {
                                    var bound = bindSuccessVarInCase(s2, tempMatch.lhs);
                                    if (bound != null) {
                                        out.push(bound);
                                        i += 2;
                                        continue;
                                    }
                                }
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

    static function assignedVarFromNestedUnderscore(n: ElixirAST): Null<String> {
        return switch (n.def) {
            case EBinary(Match, left, rhs):
                var hasNested = false;
                switch (rhs.def) {
                    case EBinary(Match, {def: EVar(nm)}, _) if (nm == "_"): hasNested = true;
                    case EMatch(PVar(nm2), _) if (nm2 == "_"): hasNested = true;
                    default:
                }
                if (hasNested) switch (left.def) { case EVar(v): v; default: null; } else null;
            case EMatch(PVar(name), rhs2):
                switch (rhs2.def) {
                    case EBinary(Match, {def: EVar(nm3)}, _) if (nm3 == "_"): name;
                    case EMatch(PVar(nm4), _) if (nm4 == "_"): name;
                    default: null;
                }
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
        return switch (n.def) { case ECase(expr, _): expr; default: null; }
    }
    static function extractCaseHeadVar(n: ElixirAST): Null<String> {
        return switch (n.def) { case ECase(expr, _): switch (expr.def) { case EVar(v): v; default: null; } default: null; }
    }
    static function extractVarTempCall(n: ElixirAST): { lhs: Null<String>, temp: Null<String>, call: Null<ElixirAST> } {
        var lhs:Null<String> = null; var temp:Null<String> = null; var call:Null<ElixirAST> = null;
        switch (n.def) {
            case EBinary(Match, left, right):
                switch (left.def) { case EVar(v): lhs = v; default: }
                switch (right.def) {
                    case EBinary(Match, {def: EVar(t)}, r): temp = t; call = extractRightmostCall(makeASTWithMeta(EBinary(Match, makeAST(EVar(t)), r), n.metadata, n.pos));
                    case EMatch(PVar(t2), r2): temp = t2; call = extractRightmostCall(makeASTWithMeta(EMatch(PVar(t2), r2), n.metadata, n.pos));
                    case EParen(inner):
                        var innerRes = extractVarTempCall(inner);
                        temp = innerRes.temp; call = innerRes.call;
                    default:
                }
            case EMatch(PVar(lh), right2):
                lhs = lh;
                switch (right2.def) {
                    case EBinary(Match, {def: EVar(t3)}, r3): temp = t3; call = extractRightmostCall(makeASTWithMeta(EBinary(Match, makeAST(EVar(t3)), r3), n.metadata, n.pos));
                    case EMatch(PVar(t4), r4): temp = t4; call = extractRightmostCall(makeASTWithMeta(EMatch(PVar(t4), r4), n.metadata, n.pos));
                    case EParen(inner2):
                        var innerRes2 = extractVarTempCall(inner2);
                        temp = innerRes2.temp; call = innerRes2.call;
                    default:
                }
            default:
        }
        return { lhs: lhs, temp: temp, call: call };
    }

    static function callsEqual(a: ElixirAST, b: ElixirAST): Bool {
        return switch [a.def, b.def] {
            case [ERemoteCall(ma, fa, aa), ERemoteCall(mb, fb, bb)]:
                if (fa != fb) return false;
                if (ElixirASTPrinter.printAST(ma) != ElixirASTPrinter.printAST(mb)) return false;
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

    static function bindSuccessVarInCase(n: ElixirAST, varName: String): Null<ElixirAST> {
        return switch (n.def) {
            case ECase(expr, clauses):
                var newClauses = [];
                var changed = false;
                for (c in clauses) {
                    var newPat = c.pattern;
                    var newBody = c.body;
                    switch (c.pattern) {
                        case PTuple(parts) if (parts.length == 2):
                            var firstOk = false;
                            switch (parts[0]) {
                                case PLiteral(lit) if (switch (lit.def) { case EAtom(v) if (v == ":ok" || v == "ok"): true; default: false; }):
                                    firstOk = true;
                                default:
                            }
                            if (firstOk) switch (parts[1]) {
                                case PVar(success):
                                    // Replace body that returns `success` with `var = success; var`
                                    // Otherwise, prepend assignment when reasonable
                                    changed = true;
                                    // Build `var = success; var`
                                    var assign = makeAST(EBinary(Match, makeAST(EVar(varName)), makeAST(EVar(success))));
                                    newBody = switch (c.body.def) {
                                        case EVar(v) if (v == success): makeAST(EBlock([assign, makeAST(EVar(varName))]));
                                        default: makeAST(EBlock([assign, c.body]));
                                    };
                                default:
                            }
                        default:
                    }
                    newClauses.push({ pattern: newPat, guard: c.guard, body: newBody });
                }
                if (changed) makeASTWithMeta(ECase(expr, newClauses), n.metadata, n.pos) else n;
            default: null;
        }
    }
}

#end
