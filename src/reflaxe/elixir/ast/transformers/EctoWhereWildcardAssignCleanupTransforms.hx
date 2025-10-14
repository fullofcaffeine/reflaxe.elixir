package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * EctoWhereWildcardAssignCleanupTransforms
 *
 * WHAT
 * - Clean up patterns where `if ... do _ = Ecto.Query.where(query, [t], cond) else query end`
 *   appears inside an assignment. Rewrites the then-branch to the pure where/2 call,
 *   removing the throwaway wildcard assignment.
 *
 * WHY
 * - Some hygiene passes convert unused branch results to wildcard assignments. For
 *   Ecto.Query.where/2 this produces non-idiomatic code and can interfere with
 *   require detection. Rewriting restores the intended query-chaining shape.
 *
 * HOW
 * - Detect EIf nodes whose then-branch is either EMatch(PWildcard, expr) or
 *   EBinary(Match, EUnderscore/_ var, expr) and where expr is an ERemoteCall to
 *   Ecto.Query.where. Replace then-branch with expr.
 *
 * EXAMPLES
 * Haxe:
 *   if (apply) query = Ecto.Query.where(query, function(t) return t.active);
 * Elixir (before):
 *   if apply do
 *     _ = Ecto.Query.where(query, [t], t.active)
 *   else
 *     query
 *   end
 * Elixir (after):
 *   if apply do
 *     Ecto.Query.where(query, [t], t.active)
 *   else
 *     query
 *   end
  */
class EctoWhereWildcardAssignCleanupTransforms {
    static inline function isEctoWhereCall(e: ElixirAST): Bool {
        return switch (e.def) {
            case ERemoteCall(mod, func, _):
                if (func != "where") return false;
                switch (mod.def) {
                    case EVar(m) if (m == "Ecto.Query"): true;
                    default: false;
                }
            default: false;
        };
    }

    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EIf(cond, thenBr, elseBr):
                    var newThen = switch (thenBr.def) {
                        case EMatch(_, rhs) if (isEctoWhereCall(rhs)): rhs;
                        case EBinary(Match, left, rhs2):
                            var isWild = switch (left.def) {
                                case EVar(v) if (v == "_"): true;
                                case EUnderscore: true;
                                default: false;
                            };
                            (isWild && isEctoWhereCall(rhs2)) ? rhs2 : thenBr;
                        default: thenBr;
                    };
                    if (newThen != thenBr) {
                        makeASTWithMeta(EIf(cond, newThen, elseBr), n.metadata, n.pos);
                    } else n;
                default:
                    n;
            }
        });
    }
}

#end
