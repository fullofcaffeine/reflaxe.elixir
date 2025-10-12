package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;

/**
 * EctoEqPinnedNilGuardTransforms
 *
 * WHAT
 * - Rewrites Ecto.Query.where/2 conditions comparing a schema field to a
 *   pinned variable that may be nil into a guarded expression that uses
 *   Kernel.is_nil/1 to produce valid and idiomatic Ecto conditions.
 *
 * WHY
 * - Ecto forbids comparing fields directly to nil (e.g., t.user_id == nil).
 *   When a pinned variable resolves to nil at runtime, expressions like
 *   `t.user_id == ^user_id` raise at query build time. We must emit
 *   `is_nil(t.user_id)` (or its negation) when the pinned variable is nil.
 *
 * HOW
 * - Within ERemoteCall(_, "where", ...), locate the condition argument and
 *   detect comparisons of the form `field == ^var` or `field != ^var` (in any
 *   order). Replace with:
 *
 *   case Kernel.is_nil(var) do
 *     true  -> (is_nil(field)         | not is_nil(field))
 *     false ->  field == ^var (as-is) | field != ^var (as-is)
 *   end
 *
 * - Field detection is shape-based (EField over a binding), variable pin is
 *   EPin(EVar(_)) or EPin(EParen(EVar(_))).
 * - Runs late, before EqNilToIsNil(Final), so remaining literal-nil cases are
 *   still normalized.
 *
 * EXAMPLES
 * Haxe:
 *   where(users, (t) -> t.userId == userId)
 * Elixir (before):
 *   Ecto.Query.where(query, [t], t.user_id == ^(user_id))
 * Elixir (after):
 *   Ecto.Query.where(query, [t],
 *     case Kernel.is_nil(user_id) do
 *       true  -> Kernel.is_nil(t.user_id)
 *       false -> t.user_id == ^(user_id)
 *     end)
 */
class EctoEqPinnedNilGuardTransforms {
    static inline function isWhereCall(module: ElixirAST, func: String): Bool {
        return func == "where"; // allow both Ecto.Query.where and imported where
    }

    static function unwrapParen(e: ElixirAST): ElixirAST {
        return switch (e.def) {
            case EParen(inner): unwrapParen(inner);
            default: e;
        }
    }

    static function extractPinnedVar(expr: ElixirAST): Null<ElixirAST> {
        return switch (expr.def) {
            case EPin(inner):
                var u = unwrapParen(inner);
                switch (u.def) {
                    case EVar(_): u;
                    default: null;
                }
            default: null;
        }
    }

    static function isFieldExpr(e: ElixirAST): Bool {
        return switch (e.def) {
            case EField(_, _): true;
            default: false;
        };
    }

    static function makeIsNil(e: ElixirAST): ElixirAST {
        // Kernel.is_nil/1 - use in plain Elixir contexts (outside Ecto DSL)
        return makeAST(ERemoteCall(makeAST(EVar("Kernel")), "is_nil", [e]));
    }

    static function guardCompare(op: EBinaryOp, left: ElixirAST, right: ElixirAST): ElixirAST {
        // try left pinned, right field
        var pinned = extractPinnedVar(left);
        var field  = isFieldExpr(right) ? right : null;
        if (pinned == null || field == null) {
            // try right pinned, left field
            pinned = extractPinnedVar(right);
            field  = isFieldExpr(left) ? left : null;
        }
        if (pinned == null || field == null) return null;

        // Build branch selection outside of the query macro: if is_nil(^var) do where(..., is_nil(field)) else where(..., original) end
        // We return a special sentinel EIf body here; the caller will stitch in the correct args around it.
        // Outside the query macro (in the surrounding if), we must not use the pin operator.
        var isNilPinned = makeIsNil(pinned);
        // In Ecto DSL conditions, prefer unqualified is_nil(field)
        var isNilField  = makeAST(ECall(null, "is_nil", [field]));
        var thenBody: ElixirAST = switch (op) {
            case Equal: isNilField;
            case NotEqual: makeAST(EUnary(Not, isNilField));
            default: return null;
        };
        // Use EIf with placeholder bodies; the caller will replace with full where calls
        return makeAST(EIf(isNilPinned, thenBody, makeAST(EBinary(op, left, right))));
    }

    public static function transformPass(ast: ElixirAST): ElixirAST {
        return reflaxe.elixir.ast.ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ERemoteCall(module, func, args) if (isWhereCall(module, func) && args != null && args.length >= 2):
                    var idx = args.length - 1;
                    var cond = args[idx];
                    switch (cond.def) {
                        case EBinary(op, l, r):
                            var branchExpr = guardCompare(op, l, r);
                            if (branchExpr == null) return n;
                            // branchExpr is EIf(is_nil(^var), <thenCond>, <elseCond>)
                            switch (branchExpr.def) {
                                case EIf(isNilPinned, thenCond, elseCond):
                                    var thenArgs = args.copy();
                                    thenArgs[idx] = thenCond;
                                    var elseArgs = args.copy();
                                    elseArgs[idx] = elseCond;
                                    var thenWhere = makeAST(ERemoteCall(module, func, thenArgs));
                                    var elseWhere = makeAST(ERemoteCall(module, func, elseArgs));
                                    makeASTWithMeta(EIf(isNilPinned, thenWhere, elseWhere), n.metadata, n.pos);
                                default:
                                    n;
                            }
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
