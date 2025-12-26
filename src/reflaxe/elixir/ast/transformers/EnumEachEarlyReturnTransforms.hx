package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirAST.EPattern;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.naming.ElixirAtom;

/**
 * EnumEachEarlyReturnTransforms
 *
 * WHAT
 * - Preserves Haxe early-return semantics for `for` loops that are lowered into
 *   `Enum.each/2` calls by rewriting them to `Enum.reduce_while/3` and moving the
 *   remainder of the surrounding block into a `case`.
 *
 * WHY
 * - Haxe `return` inside a loop returns from the enclosing function.
 * - When a `for` loop is lowered to `Enum.each(list, fn item -> ... end)`, any
 *   `return` lowered to an expression becomes a return from the anonymous function,
 *   not the enclosing function, and the remainder of the enclosing block still
 *   executes.
 * - Using value-level propagation (`{:halt, ...}` + `case`) avoids try/catch-based
 *   non-local returns, which would interfere with user-authored exception handling.
 *
 * HOW
 * - Scan EBlock/EDo statement sequences for a statement whose RHS is:
 *     Enum.each(collection, fn binder -> if cond, do: <expr-from-return> end end)
 *   where the then-branch is tagged with `metadata.fromReturn` by the builder.
 * - Rewrite to:
 *     case Enum.reduce_while(collection, :__reflaxe_no_return__, fn binder, _acc ->
 *            if cond, do: {:halt, {:__reflaxe_return__, value}}, else: {:cont, :__reflaxe_no_return__}
 *          end) do
 *       {:__reflaxe_return__, v} -> v
 *       _ -> <rest-of-block>
 *     end
 *
 * EXAMPLES
 * Haxe:
 *   for (t in todos) if (t.id == id) return t;
 *   return null;
 * Elixir (before):
 *   _ = Enum.each(todos, fn t -> if t.id == id, do: t end)
 *   nil
 * Elixir (after):
 *   case Enum.reduce_while(todos, :__reflaxe_no_return__, fn t, _acc ->
 *          if t.id == id, do: {:halt, {:__reflaxe_return__, t}}, else: {:cont, :__reflaxe_no_return__}
 *        end) do
 *     {:__reflaxe_return__, v} -> v
 *     _ -> nil
 *   end
 */
class EnumEachEarlyReturnTransforms {
    static inline var RETURN_TAG: ElixirAtom = ElixirAtom.raw("__reflaxe_return__");
    static inline var NO_RETURN_TAG: ElixirAtom = ElixirAtom.raw("__reflaxe_no_return__");

    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case EBlock(stmts):
                    rewriteSequenceAsSameKind(
                        stmts,
                        exprs -> makeASTWithMeta(EBlock(exprs), node.metadata, node.pos),
                        node.metadata,
                        node.pos
                    );
                case EDo(stmts):
                    rewriteSequenceAsSameKind(
                        stmts,
                        exprs -> makeASTWithMeta(EDo(exprs), node.metadata, node.pos),
                        node.metadata,
                        node.pos
                    );
                default:
                    node;
            }
        });
    }

    static inline function isFromReturn(n: ElixirAST): Bool {
        return n != null && n.metadata != null && n.metadata.fromReturn == true;
    }

    static function rewriteSequenceAsSameKind(
        stmts: Array<ElixirAST>,
        wrap: Array<ElixirAST> -> ElixirAST,
        meta: ElixirMetadata,
        pos: haxe.macro.Expr.Position
    ): ElixirAST {
        if (stmts == null || stmts.length == 0) return wrap([]);

        var out: Array<ElixirAST> = [];
        var index = 0;
        while (index < stmts.length) {
            var stmt = stmts[index];

            var extracted = extractEarlyReturnEnumEach(stmt);
            if (extracted != null) {
                var elseExpr = (index < stmts.length - 1)
                    ? buildRestExpr(stmts.slice(index + 1), meta, pos)
                    : makeAST(ENil);

                var reduceWhileExpr = buildReduceWhile(
                    extracted.collection,
                    extracted.binderName,
                    extracted.condition,
                    extracted.returnValue,
                    stmt.metadata,
                    stmt.pos
                );

                var returnVarName = "reflaxe_return_value";
                var returnTagAst = makeAST(EAtom(RETURN_TAG));
                var caseExpr = makeASTWithMeta(
                    ECase(reduceWhileExpr, [
                        {
                            pattern: PTuple([PLiteral(returnTagAst), PVar(returnVarName)]),
                            guard: null,
                            body: makeAST(EVar(returnVarName))
                        },
                        {
                            pattern: PWildcard,
                            guard: null,
                            body: elseExpr
                        }
                    ]),
                    stmt.metadata,
                    stmt.pos
                );

                out.push(caseExpr);
                return wrap(out);
            }

            out.push(stmt);
            index++;
        }

        return wrap(out);
    }

    static function buildRestExpr(rest: Array<ElixirAST>, meta: ElixirMetadata, pos: haxe.macro.Expr.Position): ElixirAST {
        // Recursively rewrite nested early-return patterns within the remainder.
        var rewritten = rewriteSequenceAsSameKind(rest, exprs -> makeASTWithMeta(EBlock(exprs), meta, pos), meta, pos);
        return switch (rewritten.def) {
            case EBlock(exprs) if (exprs != null && exprs.length == 1):
                exprs[0];
            default:
                rewritten;
        };
    }

    static function extractEarlyReturnEnumEach(stmt: ElixirAST): Null<{
        collection: ElixirAST,
        binderName: String,
        condition: ElixirAST,
        returnValue: ElixirAST
    }> {
        if (stmt == null || stmt.def == null) return null;

        var callExpr: ElixirAST = switch (stmt.def) {
            case EMatch(PVar("_"), rhs): rhs;
            case EBinary(Match, {def: EVar("_")}, rhs): rhs;
            default: stmt;
        };

        var loopContainsReturn = (stmt.metadata != null && stmt.metadata.loopContainsReturn == true)
            || (callExpr != null && callExpr.metadata != null && callExpr.metadata.loopContainsReturn == true);

        var eachCall = switch (callExpr.def) {
            case ERemoteCall({def: EVar("Enum")}, "each", args) if (args != null && args.length == 2):
                {collection: args[0], fnArg: args[1]};
            case ECall({def: EVar("Enum")}, "each", args) if (args != null && args.length == 2):
                {collection: args[0], fnArg: args[1]};
            default:
                null;
        };
        if (eachCall == null) return null;

        var fnAst = unwrapFnArg(eachCall.fnArg);
        if (fnAst == null) return null;

        var clause = switch (fnAst.def) {
            case EFn(clauses) if (clauses != null && clauses.length == 1):
                clauses[0];
            default:
                null;
        };
        if (clause == null) return null;

        var binderName: Null<String> = null;
        if (clause.args != null && clause.args.length == 1) {
            switch (clause.args[0]) {
                case PVar(name): binderName = name;
                default:
            }
        }
        if (binderName == null) return null;

        var bodyExpr = unwrapSingleStmtBlock(clause.body);

        var earlyReturn = switch (bodyExpr.def) {
            case EIf(cond, thenBranch, null) if (isFromReturn(thenBranch) || loopContainsReturn):
                {condition: cond, value: thenBranch};
            case EUnless(cond, body, null) if (isFromReturn(body) || loopContainsReturn):
                {condition: cond, value: body};
            default:
                null;
        };
        if (earlyReturn == null) return null;

        return {
            collection: eachCall.collection,
            binderName: binderName,
            condition: earlyReturn.condition,
            returnValue: earlyReturn.value
        };
    }

    static function unwrapFnArg(arg: ElixirAST): Null<ElixirAST> {
        if (arg == null || arg.def == null) return null;
        return switch (arg.def) {
            case EFn(_):
                arg;
            case EParen(inner):
                unwrapFnArg(inner);
            // (fn -> (fn ... end) end).() wrapper
            case ECall(target, "", []) if (target != null):
                unwrapIifeReturningFn(target);
            default:
                null;
        };
    }

    static function unwrapSingleStmtBlock(body: ElixirAST): ElixirAST {
        if (body == null || body.def == null) return body;
        return switch (body.def) {
            case EBlock(stmts) | EDo(stmts):
                unwrapSingleEffectiveStmt(stmts, body);
            default:
                body;
        };
    }

    static function unwrapSingleEffectiveStmt(stmts: Array<ElixirAST>, original: ElixirAST): ElixirAST {
        if (stmts == null || stmts.length == 0) return original;

        inline function isBareNumericSentinel(e: ElixirAST): Bool {
            return switch (e.def) {
                case EInteger(v) if (v == 0 || v == 1): true;
                case EFloat(f) if (f == 0.0): true;
                case ERaw(code) if (code != null && (StringTools.trim(code) == "0" || StringTools.trim(code) == "1")): true;
                default: false;
            };
        }

        var filtered: Array<ElixirAST> = [for (s in stmts) if (!isBareNumericSentinel(s)) s];
        if (filtered.length == 1) return filtered[0];
        return original;
    }

    static function unwrapIifeReturningFn(target: ElixirAST): Null<ElixirAST> {
        var outerFn = switch (target.def) {
            case EFn(clauses): clauses;
            case EParen(inner) if (inner != null && inner.def != null):
                switch (inner.def) {
                    case EFn(clauses2): clauses2;
                    default: null;
                }
            default:
                null;
        };
        if (outerFn == null || outerFn.length != 1) return null;

        var cl = outerFn[0];
        if (cl.args != null && cl.args.length != 0) return null;

        // Only unwrap when the IIFE body is directly an anonymous function.
        return switch (cl.body.def) {
            case EFn(_):
                cl.body;
            case EParen(inner2) if (inner2 != null && inner2.def != null):
                switch (inner2.def) {
                    case EFn(_): inner2;
                    default: null;
                }
            default:
                null;
        };
    }

    static function buildReduceWhile(
        collection: ElixirAST,
        binderName: String,
        condition: ElixirAST,
        returnValue: ElixirAST,
        meta: ElixirMetadata,
        pos: haxe.macro.Expr.Position
    ): ElixirAST {
        var returnTagAst = makeAST(EAtom(RETURN_TAG));
        var noReturnAst = makeAST(EAtom(NO_RETURN_TAG));

        var haltValue = makeAST(ETuple([returnTagAst, returnValue]));
        var haltTuple = makeAST(ETuple([makeAST(EAtom(ElixirAtom.raw("halt"))), haltValue]));
        var contTuple = makeAST(ETuple([makeAST(EAtom(ElixirAtom.raw("cont"))), noReturnAst]));

        var fnBody = makeAST(EIf(condition, haltTuple, contTuple));
        var reducerFn = makeAST(EFn([{
            args: [PVar(binderName), PWildcard],
            guard: null,
            body: fnBody
        }]));

        return makeASTWithMeta(
            ERemoteCall(makeAST(EVar("Enum")), "reduce_while", [collection, noReturnAst, reducerFn]),
            meta,
            pos
        );
    }
}

#end
