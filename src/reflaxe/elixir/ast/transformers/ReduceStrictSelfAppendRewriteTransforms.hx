package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ReduceStrictSelfAppendRewriteTransforms
 *
 * WHAT
 * - As a final structural safety-net for Enum.reduce/3 reducers, if the reducer body contains
 *   a self-append alias rebind of the form `alias = Enum.concat(alias, list)` or `alias ++ list`,
 *   rewrite the reducer body to canonical form using the declared accumulator name:
 *     acc = Enum.concat(acc, list)
 *     acc
 *
 * WHY
 * - Late-stage pipelines may still leak a temporary alias for the accumulator. This pass removes
 *   that possibility without relying on names, ensuring idiomatic and valid output.
 *
 * HOW
 * - Match ERemoteCall(_, "reduce", [_, _, fn]) where fn is a single-clause EFn with two params `(binder, acc)`.
 * - Scan the body statements for a top-level assignment where RHS structurally self-appends the LHS.
 * - Extract the list argument from RHS and rebuild the body with a single `acc = Enum.concat(acc, list)` plus trailing `acc`.
 */
class ReduceStrictSelfAppendRewriteTransforms {
    static function selfAppendListArg(rhs: ElixirAST, lhs: String): Null<ElixirAST> {
        return switch (rhs.def) {
            case ERemoteCall(_, "concat", args) if (args.length == 2):
                switch (args[0].def) { case EVar(nm) if (nm == lhs): args[1]; default: null; }
            case ECall(_, "concat", argsC) if (argsC.length == 2):
                switch (argsC[0].def) { case EVar(nm2) if (nm2 == lhs): argsC[1]; default: null; }
            case EBinary(Concat, l, r):
                switch (l.def) { case EVar(nm3) if (nm3 == lhs): r; default: null; }
            default: null;
        }
    }
    static function findAnyConcatListArg(rhs: ElixirAST): Null<ElixirAST> {
        var found:Null<ElixirAST> = null;
        ElixirASTTransformer.transformNode(rhs, function(n: ElixirAST): ElixirAST {
            if (found != null) return n;
            switch (n.def) {
                case ERemoteCall(_, "concat", args) if (args.length == 2): found = args[1];
                case ECall(_, "concat", argsC) if (argsC.length == 2): found = argsC[1];
                case EBinary(Concat, _, r): found = r;
                default:
            }
            return n;
        });
        return found;
    }

    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ERemoteCall(modRef, "reduce", args) if (args.length == 3):
                    #if debug_reduce_unify
                    #end
                    var fnNode = args[2];
                    switch (fnNode.def) {
                        case EFn(clauses) if (clauses.length == 1):
                            var cl = clauses[0];
                            if (cl.args.length < 2) return n;
                            var binderName:Null<String> = switch (cl.args[0]) { case PVar(b): b; default: null; };
                            var accName:Null<String> = switch (cl.args[1]) { case PVar(a): a; default: null; };
                            #if debug_reduce_unify
                            // DEBUG: Sys.println('[ReduceStrictSelfAppendRewrite] binder=' + (binderName == null ? 'null' : binderName) + ', acc=' + (accName == null ? 'null' : accName));
                            #end
                            if (accName == null) return n;
                            var bodyStmts:Array<ElixirAST> = switch (cl.body.def) { case EBlock(ss): ss; default: [cl.body]; };
                            #if debug_reduce_unify
                            for (i in 0...bodyStmts.length) {
                                var st = bodyStmts[i];
                                // DEBUG: Sys.println('[ReduceStrictSelfAppendRewrite] stmt[' + i + '] repr=' + reflaxe.elixir.ast.ElixirASTPrinter.print(st, 0));
                            }
                            #end
                            // Find a self-append alias assignment
                            var listArg:Null<ElixirAST> = null;
                            for (stmt in bodyStmts) switch (stmt.def) {
                                case EBinary(Match, left, rhs):
                                    var lhs:Null<String> = switch (left.def) { case EVar(nm): nm; default: null; };
                                    if (lhs != null) {
                                        var la = selfAppendListArg(rhs, lhs);
                                        if (la != null) { listArg = la; }
                                    }
                                case EMatch(pat, rhs2):
                                    var lhs2:Null<String> = switch (pat) { case PVar(nm2): nm2; default: null; };
                                    if (lhs2 != null) {
                                        var la2 = selfAppendListArg(rhs2, lhs2);
                                        if (la2 != null) { listArg = la2; }
                                    }
                                default:
                            }
                            if (listArg == null) {
                                // Extremely defensive: if no strict self-append detected, but any concat exists, use it
                                for (stmt in bodyStmts) switch (stmt.def) {
                                    case EBinary(Match, _, rhsX):
                                        if (listArg == null) listArg = findAnyConcatListArg(rhsX);
                                    case EMatch(_, rhsY):
                                        if (listArg == null) listArg = findAnyConcatListArg(rhsY);
                                    default:
                                }
                            }
                            // If still not found, attempt ERaw-based detection on RHS strings
                            if (listArg == null) {
                                for (stmt in bodyStmts) switch (stmt.def) {
                                    case EBinary(Match, leftE, rhsE):
                                        var lhsName:Null<String> = switch (leftE.def) { case EVar(n): n; default: null; };
                                        switch (rhsE.def) {
                                            case ERaw(code) if (lhsName != null && code != null && code.indexOf("Enum.concat(") != -1):
                                                // Look for pattern Enum.concat(<lhs>, <list>) and capture <list>
                                                var needle = 'Enum.concat(' + lhsName + ', ';
                                                var idx = code.indexOf(needle);
                                                if (idx != -1) {
                                                    var rest = code.substr(idx + needle.length);
                                                    // rest should end with ')' (possibly with whitespace)
                                                    var rtrim = rest;
                                                    // naive trim of trailing spaces/newlines
                                                    while (rtrim.length > 0 && (rtrim.charCodeAt(rtrim.length - 1) == 32 || rtrim.charCodeAt(rtrim.length - 1) == 10 || rtrim.charCodeAt(rtrim.length - 1) == 13)) {
                                                        rtrim = rtrim.substr(0, rtrim.length - 1);
                                                    }
                                                    // drop a single trailing ')'
                                                    if (rtrim.length > 0 && rtrim.charAt(rtrim.length - 1) == ')') {
                                                        rtrim = rtrim.substr(0, rtrim.length - 1);
                                                    }
                                                    // Construct new ERaw for RHS and rebuild entire reducer body
                                                    var newRhsCode = 'Enum.concat(' + accName + ', ' + rtrim + ')';
                                                    var newBody2 = makeAST(EBlock([
                                                        makeAST(EBinary(Match, makeAST(EVar(accName)), makeAST(ERaw(newRhsCode)))),
                                                        makeAST(EVar(accName))
                                                    ]));
                                                    var newFn2 = makeAST( EFn([{ args: cl.args, guard: cl.guard, body: newBody2 }]) );
                                                    #if debug_reduce_unify
                                                    #end
                                                    return makeASTWithMeta(ERemoteCall(modRef, "reduce", [args[0], args[1], newFn2]), n.metadata, n.pos);
                                                }
                                            default:
                                        }
                                        // Printer-based fallback: stringify RHS and rewrite prefix
                                        if (lhsName != null) {
                                            var rhsStr = reflaxe.elixir.ast.ElixirASTPrinter.print(rhsE, 0);
                                            #if debug_reduce_unify
                                            #end
                                            var needle = 'Enum.concat(' + lhsName + ', ';
                                            var idx = rhsStr.indexOf(needle);
                                            if (idx != -1) {
                                                var rest = rhsStr.substr(idx + needle.length);
                                                var rtrim = rest;
                                                while (rtrim.length > 0 && (rtrim.charCodeAt(rtrim.length - 1) == 32 || rtrim.charCodeAt(rtrim.length - 1) == 10 || rtrim.charCodeAt(rtrim.length - 1) == 13)) {
                                                    rtrim = rtrim.substr(0, rtrim.length - 1);
                                                }
                                                if (rtrim.length > 0 && rtrim.charAt(rtrim.length - 1) == ')') {
                                                    rtrim = rtrim.substr(0, rtrim.length - 1);
                                                }
                                                var newRhsCode2 = 'Enum.concat(' + accName + ', ' + rtrim + ')';
                                                var newBody3 = makeAST(EBlock([
                                                    makeAST(EBinary(Match, makeAST(EVar(accName)), makeAST(ERaw(newRhsCode2)))),
                                                    makeAST(EVar(accName))
                                                ]));
                                                var newFn3 = makeAST( EFn([{ args: cl.args, guard: cl.guard, body: newBody3 }]) );
                                                #if debug_reduce_unify
                                                #end
                                                return makeASTWithMeta(ERemoteCall(modRef, "reduce", [args[0], args[1], newFn3]), n.metadata, n.pos);
                                            }
                                        }
                                    default:
                                }
                            }
                            #if debug_reduce_unify
                            // DEBUG: Sys.println('[ReduceStrictSelfAppendRewrite] listArg found? ' + (listArg != null));
                            #end
                            if (listArg == null) {
                                // Last-resort statement-string based rewrite
                                for (stmt in bodyStmts) {
                                    var sstr = reflaxe.elixir.ast.ElixirASTPrinter.print(stmt, 0);
                                    var idxEq = sstr.indexOf('= Enum.concat(');
                                    if (idxEq != -1) {
                                        var idxComma = sstr.indexOf(', ', idxEq + 14);
                                        var idxClose = sstr.lastIndexOf(')');
                                        if (idxComma != -1 && idxClose != -1 && idxComma < idxClose) {
                                            var listText = sstr.substr(idxComma + 2, idxClose - (idxComma + 2));
                                            var newRhsCode4 = 'Enum.concat(' + accName + ', ' + listText + ')';
                                            var newBody4 = makeAST(EBlock([
                                                makeAST(EBinary(Match, makeAST(EVar(accName)), makeAST(ERaw(newRhsCode4)))),
                                                makeAST(EVar(accName))
                                            ]));
                                            var newFn4 = makeAST( EFn([{ args: cl.args, guard: cl.guard, body: newBody4 }]) );
                                            #if debug_reduce_unify
                                            #end
                                            return makeASTWithMeta(ERemoteCall(modRef, "reduce", [args[0], args[1], newFn4]), n.metadata, n.pos);
                                        }
                                    }
                                }
                                return n;
                            }
                            // Rebuild reducer body with canonical acc concat
                            var newBody = makeAST(EBlock([
                                makeAST(EBinary(Match, makeAST(EVar(accName)), makeAST(ERemoteCall(makeAST(EVar("Enum")), "concat", [makeAST(EVar(accName)), listArg])))),
                                makeAST(EVar(accName))
                            ]));
                            #if debug_reduce_unify
                            #end
                            var newFn = makeAST( EFn([{ args: cl.args, guard: cl.guard, body: newBody }]) );
                            makeASTWithMeta(ERemoteCall(modRef, "reduce", [args[0], args[1], newFn]), n.metadata, n.pos);
                        default:
                            n;
                    }
                default:
                    n;
            }
        });
    }
}

#end
