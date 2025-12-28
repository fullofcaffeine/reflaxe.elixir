package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * MapKeysIteratorReduceWhileRewriteTransforms
 *
 * WHAT
 * - Rewrites the "iterator-driven" reduce_while lowering used for `for (k in map.keys())`
 *   into a direct `Enum.reduce_while(Map.keys(map), ...)` over the keys list.
 *
 * WHY
 * - `Map.keys/1` returns a list in Elixir. Driving it via `has_next/next` closures is invalid
 *   and causes runtime failures. It also produces brittle patterns that are hard for later
 *   transforms to optimize and frequently triggers `--warnings-as-errors` in examples.
 *
 * HOW
 * - Inside EBlock/EDo statement lists, detect the pair:
 *   1) `iter = Map.keys(map)` (or `iter = _ = Map.keys(map)`)
 *   2) `Enum.reduce_while(Stream.iterate(...), acc, fn _, acc -> try do if iter.has_next.() do iter = iter.next.(); ... {:cont, acc} else {:halt, acc} end catch ... end end)`
 * - Replace it with:
 *   `Enum.reduce_while(Map.keys(map), acc, fn iter, acc -> <then-branch-without-next> end)`
 * - When the reduce_while result is used only via an outer accumulator variable, rebind
 *   `{outer} = Enum.reduce_while(...)` so the mutation survives.
 *
 * EXAMPLES
 * Elixir (before):
 *   key = Map.keys(m)
 *   _ = Enum.reduce_while(Stream.iterate(0, ...), :ok, fn _, acc ->
 *     if key.has_next.() do
 *       key = key.next.()
 *       do_stuff(key)
 *       {:cont, acc}
 *     else
 *       {:halt, acc}
 *     end
 *   end)
 * Elixir (after):
 *   _ = Enum.reduce_while(Map.keys(m), :ok, fn key, acc ->
 *     do_stuff(key)
 *     {:cont, acc}
 *   end)
 */
class MapKeysIteratorReduceWhileRewriteTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EBlock(stmts):
                    var rewritten = rewriteStatementList(stmts);
                    rewritten == stmts ? n : makeASTWithMeta(EBlock(rewritten), n.metadata, n.pos);
                case EDo(stmts):
                    var rewrittenDo = rewriteStatementList(stmts);
                    rewrittenDo == stmts ? n : makeASTWithMeta(EDo(rewrittenDo), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static inline function isModuleName(mod: ElixirAST, name: String): Bool {
        if (mod == null || mod.def == null) return false;
        return switch (mod.def) {
            case EVar(n): n == name;
            case EAtom(a):
                var s: String = a;
                s == name;
            default:
                false;
        };
    }

    static function rewriteStatementList(stmts: Array<ElixirAST>): Array<ElixirAST> {
        if (stmts == null || stmts.length < 2) return stmts;

        var out: Array<ElixirAST> = [];
        var i = 0;

        while (i < stmts.length) {
            var init = extractMapKeysInit(stmts[i]);
            if (init != null && i + 1 < stmts.length) {
                var reduce = extractIteratorReduceWhile(stmts[i + 1], init.iterVar);
                if (reduce != null) {
                    // Build new reduce_while over Map.keys(mapExpr)
                    var newFn = makeAST(EFn([{
                        args: [PVar(init.iterVar), reduce.accPattern],
                        guard: null,
                        body: reduce.thenBody
                    }]));
                    var newReduceCall = makeAST(ERemoteCall(makeAST(EVar("Enum")), "reduce_while", [
                        init.keysExpr,
                        reduce.initialAcc,
                        newFn
                    ]));

                    var wrappedStmt = rebuildWrapper(stmts[i + 1], newReduceCall, reduce.maybeOuterTupleBind);
                    out.push(wrappedStmt);
                    i += 2;
                    continue;
                }
            }

            out.push(stmts[i]);
            i++;
        }

        return out;
    }

    private static function rebuildWrapper(originalStmt: ElixirAST, rewrittenReduce: ElixirAST, outerTupleBind: Null<EPattern>): ElixirAST {
        // Preserve `_ = ...` wrappers for call statements to keep surrounding shapes stable.
        if (outerTupleBind != null) {
            return makeASTWithMeta(EMatch(outerTupleBind, rewrittenReduce), originalStmt.metadata, originalStmt.pos);
        }
        return switch (originalStmt.def) {
            case EMatch(PVar("_"), _):
                makeASTWithMeta(EMatch(PVar("_"), rewrittenReduce), originalStmt.metadata, originalStmt.pos);
            case EMatch(pat, _):
                makeASTWithMeta(EMatch(pat, rewrittenReduce), originalStmt.metadata, originalStmt.pos);
            case EBinary(Match, left, _):
                switch (left.def) {
                    case EVar("_"):
                        makeASTWithMeta(EBinary(Match, left, rewrittenReduce), originalStmt.metadata, originalStmt.pos);
                    default:
                        makeASTWithMeta(EBinary(Match, left, rewrittenReduce), originalStmt.metadata, originalStmt.pos);
                }
            default:
                // Bare reduce_while call statement.
                makeASTWithMeta(rewrittenReduce.def, originalStmt.metadata, originalStmt.pos);
        };
    }

    private static function extractMapKeysInit(stmt: ElixirAST): Null<{ iterVar: String, keysExpr: ElixirAST }> {
        if (stmt == null || stmt.def == null) return null;

        var lhs: Null<String> = null;
        var rhs: Null<ElixirAST> = null;

        switch (stmt.def) {
            case EMatch(PVar(name), value):
                lhs = name;
                rhs = value;
            case EBinary(Match, left, value2):
                switch (left.def) {
                    case EVar(name2):
                        lhs = name2;
                        rhs = value2;
                    default:
                }
            default:
        }

        if (lhs == null || rhs == null) return null;

        // Unwrap `iter = _ = Map.keys(m)`
        var keysCandidate = unwrapNestedDiscard(rhs);
        if (isMapKeysCall(keysCandidate)) {
            return { iterVar: lhs, keysExpr: keysCandidate };
        }
        return null;
    }

    private static function unwrapNestedDiscard(expr: ElixirAST): ElixirAST {
        if (expr == null || expr.def == null) return expr;
        return switch (expr.def) {
            case EBinary(Match, left, rhs):
                switch (left.def) { case EVar("_"): rhs; default: expr; }
            case EMatch(PVar("_"), rhs2):
                rhs2;
            default:
                expr;
        };
    }

    private static function isMapKeysCall(expr: ElixirAST): Bool {
        if (expr == null || expr.def == null) return false;
        return switch (expr.def) {
            case ERemoteCall(mod, "keys", args) if (args != null && args.length == 1 && isModuleName(mod, "Map")):
                true;
            case ECall(target, "keys", args) if (target != null && args != null && args.length == 1 && isModuleName(target, "Map")):
                true;
            default:
                false;
        };
    }

    private static function extractIteratorReduceWhile(stmt: ElixirAST, iterVar: String): Null<{
        initialAcc: ElixirAST,
        accPattern: EPattern,
        thenBody: ElixirAST,
        maybeOuterTupleBind: Null<EPattern>
    }> {
        if (stmt == null || stmt.def == null) return null;

        var callNode: Null<ElixirAST> = null;
        // Unwrap common wrappers: `_ = Enum.reduce_while(...)` or bare call.
        switch (stmt.def) {
            case EMatch(pat, rhs):
                callNode = rhs;
            case EBinary(Match, left, rhs2):
                switch (left.def) { case EVar("_"): callNode = rhs2; default: callNode = stmt; }
            default:
                callNode = stmt;
        }

        if (callNode == null || callNode.def == null) return null;

        // Expect Enum.reduce_while(Stream.iterate(...), acc, fn _, accPat -> try do if iter.has_next.() do ... end catch ... end end)
        var initialAcc: Null<ElixirAST> = null;
        var fnNode: Null<ElixirAST> = null;

        switch (callNode.def) {
            case ERemoteCall(mod, "reduce_while", args) if (isEnum(mod) && args != null && args.length == 3):
                if (!isStreamIterate(args[0])) return null;
                initialAcc = args[1];
                fnNode = args[2];
            case ECall(target, "reduce_while", args) if (target != null && isEnum(target) && args != null && args.length == 3):
                if (!isStreamIterate(args[0])) return null;
                initialAcc = args[1];
                fnNode = args[2];
            default:
                return null;
        }

        var accPattern: Null<EPattern> = null;
        var thenBody: Null<ElixirAST> = null;

        switch (fnNode.def) {
            case EFn(clauses) if (clauses != null && clauses.length == 1):
                var clause = clauses[0];
                if (clause.args == null || clause.args.length != 2) return null;
                accPattern = clause.args[1];

                var extracted = extractTryIfThenBody(clause.body, iterVar);
                if (extracted == null) return null;
                thenBody = extracted;
            default:
                return null;
        }

        // If the reduce_while call is used as a bare statement and initialAcc is `{outer}`,
        // bind it so mutations persist: `{outer} = Enum.reduce_while(...)`.
        var outerTupleBind: Null<EPattern> = null;
        var wrapperIsDiscard = switch (stmt.def) {
            case EMatch(pattern, _):
                switch (pattern) {
                    case PWildcard | PVar("_"): true;
                    default: false;
                }
            case EBinary(Match, left, _):
                switch (left.def) { case EVar("_"): true; default: false; }
            default:
                false;
        };
        var isWrapped = switch (stmt.def) {
            case EMatch(_, _) | EBinary(Match, _, _): true;
            default: false;
        };
        // Bind when the reduce_while is a bare statement *or* wrapped in a discard assignment.
        if (!isWrapped || wrapperIsDiscard) outerTupleBind = extractSingleVarTuplePattern(initialAcc);

        return {
            initialAcc: initialAcc,
            accPattern: accPattern,
            thenBody: thenBody,
            maybeOuterTupleBind: outerTupleBind
        };
    }

    private static function extractSingleVarTuplePattern(initialAcc: ElixirAST): Null<EPattern> {
        if (initialAcc == null || initialAcc.def == null) return null;
        return switch (initialAcc.def) {
            case ETuple([ {def: EVar(name)} ]):
                PTuple([PVar(name)]);
            default:
                null;
        };
    }

    private static function extractTryIfThenBody(body: ElixirAST, iterVar: String): Null<ElixirAST> {
        if (body == null || body.def == null) return null;

        // Expect: try do if iter.has_next.() do <then> else <else> end catch ... end
        switch (body.def) {
            case ETry(tryBody, rescue, catchClauses, afterBlock, elseBlock):
                var inner = unwrapSingleStatementBlock(tryBody);
                switch (inner.def) {
                    case EIf(cond, thenBranch, _elseBranch):
                        if (!isHasNextCall(cond, iterVar)) return null;
                        var cleanedThen = dropLeadingNextAssign(thenBranch, iterVar);
                        return makeAST(ETry(cleanedThen, rescue, catchClauses, afterBlock, elseBlock));
                    default:
                        return null;
                }
            default:
                return null;
        }
    }

    private static function unwrapParen(e: ElixirAST): ElixirAST {
        return switch (e.def) {
            case EParen(inner): unwrapParen(inner);
            default: e;
        };
    }

    private static function unwrapSingleStatementBlock(e: ElixirAST): ElixirAST {
        var unwrapped = unwrapParen(e);
        return switch (unwrapped.def) {
            case EBlock(stmts) if (stmts != null && stmts.length == 1):
                unwrapSingleStatementBlock(stmts[0]);
            case EDo(stmts) if (stmts != null && stmts.length == 1):
                unwrapSingleStatementBlock(stmts[0]);
            default:
                unwrapped;
        };
    }

    private static function dropLeadingNextAssign(thenBranch: ElixirAST, iterVar: String): ElixirAST {
        if (thenBranch == null || thenBranch.def == null) return thenBranch;
        var stmts: Array<ElixirAST> = switch (unwrapParen(thenBranch).def) {
            case EBlock(ss): ss;
            case EDo(ss2): ss2;
            default: [thenBranch];
        };
        if (stmts.length == 0) return thenBranch;

        var startIndex = 0;
        // Drop `iterVar = iterVar.next.()` if it is the first statement.
        if (isNextAssign(stmts[0], iterVar)) startIndex = 1;

        var outStmts = stmts.slice(startIndex);
        return makeAST(EBlock(outStmts));
    }

    private static function isHasNextCall(expr: ElixirAST, iterVar: String): Bool {
        if (expr == null || expr.def == null) return false;
        return switch (unwrapParen(expr).def) {
            case ECall(target, "", args) if (args != null && args.length == 0):
                switch (unwrapParen(target).def) {
                    case EField({def: EVar(v)}, "has_next") if (v == iterVar):
                        true;
                    default:
                        false;
                }
            default:
                false;
        };
    }

    private static function isNextAssign(stmt: ElixirAST, iterVar: String): Bool {
        if (stmt == null || stmt.def == null) return false;
        return switch (stmt.def) {
            case EMatch(PVar(name), rhs) if (name == iterVar):
                isNextCall(rhs, iterVar);
            case EBinary(Match, left, rhs2):
                switch (left.def) {
                    case EVar(name2) if (name2 == iterVar):
                        isNextCall(rhs2, iterVar);
                    default:
                        false;
                }
            default:
                false;
        };
    }

    private static function isNextCall(expr: ElixirAST, iterVar: String): Bool {
        if (expr == null || expr.def == null) return false;
        return switch (unwrapParen(expr).def) {
            case ECall(target, "", args) if (args != null && args.length == 0):
                switch (unwrapParen(target).def) {
                    case EField({def: EVar(v)}, "next") if (v == iterVar):
                        true;
                    default:
                        false;
                }
            default:
                false;
        };
    }

    private static function isEnum(mod: ElixirAST): Bool {
        return switch (mod.def) {
            case EVar("Enum"): true;
            case EAtom(a):
                var s: String = a;
                s == "Enum";
            default: false;
        };
    }

    private static function isStreamIterate(expr: ElixirAST): Bool {
        if (expr == null || expr.def == null) return false;
        return switch (expr.def) {
            case ERemoteCall(mod, "iterate", args) if (args != null && args.length == 2 && isModuleName(mod, "Stream")):
                true;
            case ECall(target, "iterate", args) if (target != null && args != null && args.length == 2 && isModuleName(target, "Stream")):
                true;
            default:
                false;
        };
    }
}

#end
