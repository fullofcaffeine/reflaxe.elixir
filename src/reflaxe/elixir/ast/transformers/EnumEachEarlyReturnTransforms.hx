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

    static inline function debugLog(message: String): Void {
        #if debug_enum_each_early_return
        #if sys
        Sys.println('[EnumEachEarlyReturn] ' + message);
        #else
        trace('[EnumEachEarlyReturn] ' + message);
        #end
        #end
    }

    static inline function debugMetaInfo(node: ElixirAST): String {
        #if debug_enum_each_early_return
        if (node == null || node.metadata == null) return "<no-meta>";
        var file = node.metadata.sourceFile != null ? node.metadata.sourceFile : "?";
        var line = node.metadata.sourceLine != null ? Std.string(node.metadata.sourceLine) : "?";
        return file + ":" + line;
        #else
        return "";
        #end
    }

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

    static function subtreeContainsFromReturn(node: ElixirAST): Bool {
        if (node == null || node.def == null) return false;
        if (isFromReturn(node)) return true;

        var found = false;
        ElixirASTTransformer.iterateAST(node, function(child: ElixirAST): Void {
            if (found) return;
            if (subtreeContainsFromReturn(child)) found = true;
        });
        return found;
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
                debugLog('Matched Enum.each early-return pattern; binder=${extracted.binderName} prefix_len='
                    + (extracted.prefix != null ? Std.string(extracted.prefix.length) : "null")
                    + ' container_len=' + Std.string(stmts.length)
                    + ' index=' + Std.string(index)
                    + ' rest_count=' + Std.string(stmts.length - index - 1));
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

                if (extracted.prefix != null) {
                    for (p in extracted.prefix) out.push(p);
                }
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
        prefix: Array<ElixirAST>,
        collection: ElixirAST,
        binderName: String,
        condition: ElixirAST,
        returnValue: ElixirAST
    }> {
        if (stmt == null || stmt.def == null) return null;

        inline function isBareNumericSentinel(e: ElixirAST): Bool {
            return switch (e.def) {
                case EInteger(v) if (v == 0 || v == 1): true;
                case EFloat(f) if (f == 0.0): true;
                case ERaw(code) if (code != null && (StringTools.trim(code) == "0" || StringTools.trim(code) == "1")): true;
                default: false;
            };
        }

        inline function isImplicitNilElse(e: Null<ElixirAST>): Bool {
            if (e == null) return true;
            if (e.def == null) return false;
            return switch (e.def) {
                case ENil: true;
                case EBlock(stmts) if (stmts == null || stmts.length == 0): true;
                case EDo(stmts2) if (stmts2 == null || stmts2.length == 0): true;
                default: false;
            };
        }

        inline function branchSignalsReturn(branch: ElixirAST): Bool {
            if (branch == null) return false;
            var core = unwrapSingleStmtBlock(branch);
            return isFromReturn(core) || subtreeContainsFromReturn(branch);
        }

        function tryExtractSingle(singleStmt: ElixirAST): Null<{
            collection: ElixirAST,
            binderName: String,
            condition: ElixirAST,
            returnValue: ElixirAST
        }> {
            if (singleStmt == null || singleStmt.def == null) return null;

            // Some builder paths wrap single statements in a one-off block; unwrap to match
            // the canonical Enum.each statement shape.
            var stmtCore = unwrapSingleStmtBlock(singleStmt);

            var callExpr: ElixirAST = switch (stmtCore.def) {
                case EMatch(PVar("_"), rhs): rhs;
                case EBinary(Match, {def: EVar("_")}, rhs): rhs;
                default: stmtCore;
            };

            var loopContainsReturn = (singleStmt.metadata != null && singleStmt.metadata.loopContainsReturn == true)
                || (stmtCore.metadata != null && stmtCore.metadata.loopContainsReturn == true)
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
            if (fnAst == null) {
                debugLog('Found Enum.each but could not unwrap fn arg; def=' + reflaxe.elixir.util.EnumReflection.enumConstructor(eachCall.fnArg.def));
                return null;
            }

            var clause = switch (fnAst.def) {
                case EFn(clauses) if (clauses != null && clauses.length == 1):
                    clauses[0];
                default:
                    null;
            };
            if (clause == null) {
                debugLog('Found Enum.each but unexpected fn shape; def=' + reflaxe.elixir.util.EnumReflection.enumConstructor(fnAst.def));
                return null;
            }

            var binderName: Null<String> = null;
            if (clause.args != null && clause.args.length == 1) {
                switch (clause.args[0]) {
                    case PVar(name): binderName = name;
                    default:
                }
            }
            if (binderName == null) {
                debugLog('Found Enum.each but binder pattern was not PVar; args=' + (clause.args != null ? Std.string(clause.args.length) : 'null'));
                return null;
            }

            var bodyExpr = unwrapSingleStmtBlock(clause.body);

            #if debug_enum_each_early_return
            switch (bodyExpr.def) {
                case EIf(_c, thenBranch, elseBranch):
                    debugLog('Enum.each binder=' + binderName + ' meta=' + debugMetaInfo(callExpr)
                        + ' if? elseNil=' + isImplicitNilElse(elseBranch)
                        + ' loopContainsReturn=' + loopContainsReturn
                        + ' then.fromReturn=' + isFromReturn(thenBranch)
                        + ' then.subtreeFromReturn=' + subtreeContainsFromReturn(thenBranch)
                        + ' then.unwrapped.fromReturn=' + isFromReturn(unwrapSingleStmtBlock(thenBranch)));
                case EUnless(_c, body, elseBranch):
                    debugLog('Enum.each binder=' + binderName + ' meta=' + debugMetaInfo(callExpr)
                        + ' unless? elseNil=' + isImplicitNilElse(elseBranch)
                        + ' loopContainsReturn=' + loopContainsReturn
                        + ' body.fromReturn=' + isFromReturn(body)
                        + ' body.subtreeFromReturn=' + subtreeContainsFromReturn(body)
                        + ' body.unwrapped.fromReturn=' + isFromReturn(unwrapSingleStmtBlock(body)));
                default:
            }
            #end

            var earlyReturn = switch (bodyExpr.def) {
                case EIf(cond, thenBranch, elseBranch) if (isImplicitNilElse(elseBranch) && (branchSignalsReturn(thenBranch) || loopContainsReturn)):
                    {condition: cond, value: thenBranch};
                case EUnless(cond, body, elseBranch) if (isImplicitNilElse(elseBranch) && (branchSignalsReturn(body) || loopContainsReturn)):
                    {condition: cond, value: body};
                default:
                    null;
            };
            if (earlyReturn == null) {
                debugLog('Found Enum.each but body did not match early-return shape; binder=' + binderName + ' body=' + reflaxe.elixir.util.EnumReflection.enumConstructor(bodyExpr.def));
                return null;
            }

            return {
                collection: eachCall.collection,
                binderName: binderName,
                condition: earlyReturn.condition,
                returnValue: earlyReturn.value
            };
        }

        var direct = tryExtractSingle(stmt);
        if (direct != null) {
            return {
                prefix: [],
                collection: direct.collection,
                binderName: direct.binderName,
                condition: direct.condition,
                returnValue: direct.returnValue
            };
        }

        // Handle a desugared loop represented as a statement block whose last statement is the Enum.each call.
        var stmtCore = unwrapSingleStmtBlock(stmt);
        var innerStmts = switch (stmtCore.def) {
            case EBlock(stmts) | EDo(stmts): stmts;
            default: null;
        };

        if (innerStmts != null) {
            var meaningful = [for (s in innerStmts) if (s != null && s.def != null && !isBareNumericSentinel(s)) s];
            if (meaningful.length > 0) {
                var last = meaningful[meaningful.length - 1];
                var extractedLast = tryExtractSingle(last);
                if (extractedLast != null) {
                    return {
                        prefix: meaningful.slice(0, meaningful.length - 1),
                        collection: extractedLast.collection,
                        binderName: extractedLast.binderName,
                        condition: extractedLast.condition,
                        returnValue: extractedLast.returnValue
                    };
                }
            }
        }

        return null;
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
                    case EFn(clauses): clauses;
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
            case EParen(inner) if (inner != null && inner.def != null):
                switch (inner.def) {
                    case EFn(_): inner;
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
