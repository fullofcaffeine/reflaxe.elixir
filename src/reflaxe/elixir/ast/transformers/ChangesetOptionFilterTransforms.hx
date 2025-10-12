package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ChangesetOptionFilterTransforms
 *
 * WHAT
 * - Ensures Ecto.Changeset.validate_length options keyword list contains only
 *   keys with non-nil values. Drops keys with nil by filtering the literal
 *   keyword list via Enum.filter.
 *
 * WHY
 * - Passing nil-valued options like [min: nil] or [is: nil] is non-idiomatic
 *   and can trigger warnings. Ecto expects only present options.
 *
 * HOW
 * - Find calls: ERemoteCall(Ecto.Changeset, "validate_length", [cs, field, kw])
 * - When kw is EKeywordList([...]), transform third arg to
 *     Enum.filter([kw...], fn {_, v} -> v != nil end)
 * - Field atom normalization is handled by dedicated pass; this pass only filters.
 *
 * EXAMPLES
 * Before:
 *   Ecto.Changeset.validate_length(cs, :title, [min: opts.min, max: opts.max, is: opts.is])
 * After:
 *   Ecto.Changeset.validate_length(cs, :title,
 *     Enum.filter([min: opts.min, max: opts.max, is: opts.is], fn {_, v} -> v != nil end))
 */
class ChangesetOptionFilterTransforms {
    public static function filterValidateLengthOptionsPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ERemoteCall(mod, fn, args) if (isChangesetValidateLength(mod, fn, args)):
                    var a = args.copy();
                    if (a.length >= 3) switch (a[2].def) {
                        case EKeywordList(pairs):
                            // Build Enum.filter([...], fn {_, v} -> v != nil end)
                            var listExpr = makeAST(EKeywordList(pairs));
                            var filterFn = makeAST(EFn([{
                                args: [PTuple([PWildcard, PVar("v")])],
                                body: makeAST(EBinary(NotEqual, makeAST(EVar("v")), makeAST(ENil)))
                            }]));
                            var filtered = makeAST(ERemoteCall(makeAST(EVar("Enum")), "filter", [listExpr, filterFn]));
                            a[2] = filtered;
                            makeASTWithMeta(ERemoteCall(mod, fn, a), n.metadata, n.pos);
                        default:
                            n;
                    } else n;
                default:
                    n;
            }
        });
    }

    static inline function isChangesetValidateLength(mod: ElixirAST, fn: String, args: Array<ElixirAST>): Bool {
        if (fn != "validate_length") return false;
        return switch (mod.def) {
            case EVar(name): name != null && (name == "Ecto.Changeset" || name.indexOf("Ecto.Changeset") != -1);
            default: false;
        }
    }
}

#end

