package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import haxe.ds.StringMap;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
#if debug_case_tuple_result_binding
import reflaxe.elixir.ast.ElixirASTPrinter;
#end

/**
 * CaseTupleResultBindingTransforms
 *
 * WHAT
 * - Collapses a common Haxe→Elixir lowering artifact where a `case` expression returns a tuple
 *   of updated locals, but that tuple is bound to underscore temps and the real locals are
 *   pre-initialized to `nil` and mutated as side effects inside the clauses.
 *
 * WHY
 * - Elixir 1.18+ type warnings often infer the *first* binding as authoritative. Patterns like:
 *     validated_email = nil
 *     {_errors, _validated_email} = case ... do
 *       {:ok, result} ->
 *         validated_email = result
 *         {errors, validated_email}
 *       {:error, _} ->
 *         {errors, validated_email}
 *     end
 *   can lead to WAE warnings later because `validated_email` is inferred as `nil`.
 * - The tuple result already carries the correct values; binding it directly is more idiomatic
 *   and removes the need for `var = nil` "pre-bind" initializers.
 *
 * HOW
 * - Within EBlock/EDo statement lists:
 *   1) Track `name = nil` initializer statements (top-level simple assigns).
 *   2) When encountering a tuple match to a `case` expression whose clauses all end with
 *      a tuple of consistent variable names:
 *      - Rewrite the match pattern to bind those variables directly (instead of underscored temps).
 *      - For any tuple element variable that had a prior `name = nil` initializer:
 *        - Replace per-clause tuple element with the RHS of the last assignment to `name` in that clause,
 *          or `nil` if the clause never assigns it.
 *        - Remove those `name = <expr>` assignments from the clause body (the tuple binding becomes authoritative).
 *      - Drop the original `name = nil` initializer statement.
 *
 * EXAMPLES
 * Elixir (before):
 *   validated_email = nil
 *   {_errors, _validated_email} =
 *     case g do
 *       {:ok, result} ->
 *         validated_email = result
 *         {errors, validated_email}
 *       {:error, reason} ->
 *         errors = errors ++ ["Email: " <> reason]
 *         {errors, validated_email}
 *     end
 *
 * Elixir (after):
 *   {errors, validated_email} =
 *     case g do
 *       {:ok, result} ->
 *         {errors, result}
 *       {:error, reason} ->
 *         {errors ++ ["Email: " <> reason], nil}
 *     end
 */
class CaseTupleResultBindingTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EBlock(stmts):
                    var rewritten = rewriteSeq(stmts);
                    rewritten == stmts ? n : makeASTWithMeta(EBlock(rewritten), n.metadata, n.pos);
                case EDo(statements):
                    var rewrittenStatements = rewriteSeq(statements);
                    rewrittenStatements == statements ? n : makeASTWithMeta(EDo(rewrittenStatements), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function rewriteSeq(stmts: Array<ElixirAST>): Array<ElixirAST> {
        if (stmts == null || stmts.length < 2) return stmts;

        var nilInitLocations: StringMap<{ out: Array<Null<ElixirAST>>, idx: Int }> = new StringMap();
        return rewriteSeqWithContext(stmts, nilInitLocations);
    }

    static function rewriteSeqWithContext(stmts: Array<ElixirAST>, nilInitLocations: StringMap<{ out: Array<Null<ElixirAST>>, idx: Int }>): Array<ElixirAST> {
        if (stmts == null || stmts.length < 2) return stmts;

        var out: Array<Null<ElixirAST>> = [];

        for (stmt in stmts) {
            // Nested blocks in statement position are scope-transparent; keep the nil-init
            // environment so later tuple bindings can remove/replace initializers.
            switch (stmt.def) {
                case EBlock(innerStmts):
                    var rewrittenInner = rewriteSeqWithContext(innerStmts, nilInitLocations);
                    out.push(makeASTWithMeta(EBlock(rewrittenInner), stmt.metadata, stmt.pos));
                    continue;
                case EDo(innerStatements):
                    var rewrittenInnerStatements = rewriteSeqWithContext(innerStatements, nilInitLocations);
                    out.push(makeASTWithMeta(EDo(rewrittenInnerStatements), stmt.metadata, stmt.pos));
                    continue;
                default:
            }

            var nilInitName = extractNilInitVar(stmt);
            if (nilInitName != null && !nilInitLocations.exists(nilInitName)) {
#if debug_case_tuple_result_binding
                trace('[CaseTupleResultBinding] nil init name=' + nilInitName + ' stmt=' + ElixirASTPrinter.printAST(stmt));
#end
                nilInitLocations.set(nilInitName, { out: out, idx: out.length });
                out.push(stmt);
                continue;
            }

            var rewritten = tryRewriteTupleCaseMatch(stmt, nilInitLocations);
            out.push(rewritten);
        }

        var compact: Array<ElixirAST> = [];
        for (s in out) if (s != null) compact.push(s);
        return compact;
    }

    static function extractNilInitVar(stmt: ElixirAST): Null<String> {
        if (stmt == null || stmt.def == null) return null;
        return switch (stmt.def) {
            case EMatch(PVar(name), rhs) if (rhs != null && rhs.def != null):
                switch (rhs.def) { case ENil: name; default: null; }
            case EBinary(Match, left, rhs) if (rhs != null && rhs.def != null):
                switch (rhs.def) {
                    case ENil:
                        var unwrappedLeft = unwrapParen(left);
                        switch (unwrappedLeft.def) { case EVar(varName): varName; default: null; }
                    default:
                        null;
                }
            default:
                null;
        };
    }

    static function unwrapParen(e: ElixirAST): ElixirAST {
        return switch (e.def) {
            case EParen(inner): unwrapParen(inner);
            default: e;
        };
    }

    static function tryRewriteTupleCaseMatch(stmt: ElixirAST, nilInitLocations: StringMap<{ out: Array<Null<ElixirAST>>, idx: Int }>): ElixirAST {
        var tupleMatch = extractTupleMatchCase(stmt);
        if (tupleMatch == null) return stmt;

#if debug_case_tuple_result_binding
        trace('[CaseTupleResultBinding] tuple match stmt=' + ElixirASTPrinter.printAST(stmt));
#end

        var resultVarNames = extractConsistentTupleVarNames(tupleMatch.caseExpr);
        if (resultVarNames == null) return stmt;

        // Only useful if at least one of the result vars was nil-initialized earlier.
        var nilInitNames: Array<String> = [];
        var nilInitSet: StringMap<Bool> = new StringMap();
        for (nm in resultVarNames) {
            if (nilInitLocations.exists(nm)) {
                nilInitNames.push(nm);
                nilInitSet.set(nm, true);
            }
        }
        if (nilInitNames.length == 0) return stmt;

#if debug_case_tuple_result_binding
        trace('[CaseTupleResultBinding] hit stmt=' + ElixirASTPrinter.printAST(stmt));
        trace('[CaseTupleResultBinding] resultVars=' + resultVarNames.join(",") + ' nilInit=' + nilInitNames.join(","));
#end

        // Rewrite case clauses to return explicit values for nil-initialized vars, and drop clause-side assigns.
        var newClauses: Array<ECaseClause> = [];
        for (cl in tupleMatch.caseExpr.clauses) {
            var rewrittenBody = rewriteClauseBody(cl.body, resultVarNames, nilInitSet);
            newClauses.push({
                pattern: cl.pattern,
                guard: cl.guard,
                body: rewrittenBody
            });
        }

        var newCaseExpr = makeASTWithMeta(ECase(tupleMatch.caseExpr.expr, newClauses), tupleMatch.caseNode.metadata, tupleMatch.caseNode.pos);

        // Bind the tuple result to the real variable names.
        var rewrittenStmt = tupleMatch.build(resultVarNames, newCaseExpr);

        // Drop the original nil initializers now that the tuple binding is authoritative.
        for (name in nilInitNames) {
            var loc = nilInitLocations.get(name);
            if (loc != null && loc.out != null && loc.idx >= 0 && loc.idx < loc.out.length) {
                loc.out[loc.idx] = null;
            }
            nilInitLocations.remove(name);
        }

        return rewrittenStmt;
    }

    private static function extractTupleMatchCase(stmt: ElixirAST): Null<{
        build: (Array<String>, ElixirAST) -> ElixirAST,
        caseNode: ElixirAST,
        caseExpr: { expr: ElixirAST, clauses: Array<ECaseClause> }
    }> {
        if (stmt == null || stmt.def == null) return null;
        return switch (stmt.def) {
            case EMatch(PTuple(_), rhs):
                var rhsUnwrapped = unwrapParen(rhs);
                switch (rhsUnwrapped.def) {
                    case ECase(expr, clauses):
                        {
                            build: function(resultVarNames: Array<String>, newCaseExpr: ElixirAST): ElixirAST {
                                return makeASTWithMeta(
                                    EMatch(PTuple([for (nm in resultVarNames) PVar(nm)]), newCaseExpr),
                                    stmt.metadata,
                                    stmt.pos
                                );
                            },
                            caseNode: rhsUnwrapped,
                            caseExpr: { expr: expr, clauses: clauses }
                        };
                    default:
                        null;
                }
            case EBinary(Match, left, rhs):
                // Some builders encode tuple patterns as ETuple expressions on the LHS of Match.
                var lhsUnwrapped = unwrapParen(left);
                var isTuplePattern = switch (lhsUnwrapped.def) {
                    case ETuple(elems) if (elems != null && elems.length > 0):
                        var ok = true;
                        for (el in elems) {
                            switch (unwrapParen(el).def) {
                                case EVar(_):
                                default:
                                    ok = false;
                            }
                        }
                        ok;
                    default:
                        false;
                };
                if (!isTuplePattern) {
                    null;
                } else {
                    var rhsUnwrapped = unwrapParen(rhs);
                    switch (rhsUnwrapped.def) {
                        case ECase(expr, clauses):
                            {
                                build: function(resultVarNames: Array<String>, newCaseExpr: ElixirAST): ElixirAST {
                                    var lhsTuple = makeAST(ETuple([for (name in resultVarNames) makeAST(EVar(name))]));
                                    return makeASTWithMeta(EBinary(Match, lhsTuple, newCaseExpr), stmt.metadata, stmt.pos);
                                },
                                caseNode: rhsUnwrapped,
                                caseExpr: { expr: expr, clauses: clauses }
                            };
                        default:
                            null;
                    }
                }
            default:
                null;
        };
    }

    private static function extractConsistentTupleVarNames(caseExpr: { expr: ElixirAST, clauses: Array<ECaseClause> }): Null<Array<String>> {
        if (caseExpr == null || caseExpr.clauses == null || caseExpr.clauses.length == 0) return null;

        var names: Null<Array<String>> = null;

        for (cl in caseExpr.clauses) {
            var tupleElems = extractTrailingTupleElems(cl.body);
            if (tupleElems == null) return null;

            var clauseNames: Array<String> = [];
            for (e in tupleElems) {
                var v = switch (unwrapParen(e).def) { case EVar(nm): nm; default: null; };
                if (v == null || v.length == 0) return null;
                clauseNames.push(v);
            }

            if (names == null) {
                names = clauseNames;
            } else {
                if (names.length != clauseNames.length) return null;
                for (i in 0...names.length) if (names[i] != clauseNames[i]) return null;
            }
        }

        return names;
    }

    private static function extractTrailingTupleElems(body: ElixirAST): Null<Array<ElixirAST>> {
        if (body == null || body.def == null) return null;
        return switch (body.def) {
            case EBlock(stmts) if (stmts != null && stmts.length > 0):
                extractTrailingTupleElems(stmts[stmts.length - 1]);
            case EDo(statements) if (statements != null && statements.length > 0):
                extractTrailingTupleElems(statements[statements.length - 1]);
            case EParen(inner):
                extractTrailingTupleElems(inner);
            case ETuple(elems) if (elems != null && elems.length > 0):
                elems;
            default:
                null;
        };
    }

    private static function rewriteClauseBody(body: ElixirAST, resultVarNames: Array<String>, nilInitNames: StringMap<Bool>): ElixirAST {
        var bodyStmts = unwrapBodyStatements(body);
        if (bodyStmts == null) return body;

        var tupleElems = extractTrailingTupleElems(body);
        if (tupleElems == null) return body;

        var stmtList = bodyStmts.stmts;
        // Drop the trailing tuple expression; we will rebuild it.
        stmtList = stmtList.slice(0, stmtList.length - 1);

        // For nil-initialized vars, replace the tuple element with RHS of last assignment in the clause, or nil.
        var tupleOut: Array<ElixirAST> = [];
        for (idx in 0...resultVarNames.length) {
            var name = resultVarNames[idx];
            if (nilInitNames.exists(name)) {
                var rhs = extractLastAssignRhs(stmtList, name);
                tupleOut.push(rhs != null ? rhs : makeASTWithMeta(ENil, null, body.pos));
                // Remove all top-level assigns to this name (the tuple binding becomes authoritative).
                stmtList = [for (s in stmtList) if (!isTopLevelAssignTo(s, name)) s];
            } else {
                // Keep the original element (variable).
                tupleOut.push(tupleElems[idx]);
            }
        }

        var rebuilt = stmtList.copy();
        rebuilt.push(makeASTWithMeta(ETuple(tupleOut), null, body.pos));

        return makeASTWithMeta(
            bodyStmts.wrapper == "do" ? EDo(rebuilt) : EBlock(rebuilt),
            body.metadata,
            body.pos
        );
    }

    private static function unwrapBodyStatements(body: ElixirAST): Null<{ wrapper: String, stmts: Array<ElixirAST> }> {
        if (body == null || body.def == null) return null;
        return switch (body.def) {
            case EBlock(stmts) if (stmts != null && stmts.length > 0):
                { wrapper: "block", stmts: stmts };
            case EDo(statements) if (statements != null && statements.length > 0):
                { wrapper: "do", stmts: statements };
            case EParen(inner):
                unwrapBodyStatements(inner);
            default:
                null;
        };
    }

    private static function isTopLevelAssignTo(stmt: ElixirAST, name: String): Bool {
        if (stmt == null || stmt.def == null) return false;
        return switch (stmt.def) {
            case EMatch(PVar(nm), _): nm == name;
            case EBinary(Match, left, _):
                switch (unwrapParen(left).def) { case EVar(varName): varName == name; default: false; }
            default:
                false;
        };
    }

    private static function extractLastAssignRhs(stmts: Array<ElixirAST>, name: String): Null<ElixirAST> {
        if (stmts == null) return null;
        var rhs: Null<ElixirAST> = null;
        for (s in stmts) {
            if (s == null || s.def == null) continue;
            switch (s.def) {
                case EMatch(PVar(nm), r) if (nm == name):
                    rhs = r;
                case EBinary(Match, left, rhsCandidate):
                    switch (unwrapParen(left).def) {
                        case EVar(varName) if (varName == name):
                            rhs = rhsCandidate;
                        default:
                    }
                default:
            }
        }
        return rhs;
    }
}

#end
