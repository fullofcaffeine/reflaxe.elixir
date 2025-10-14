package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * EctoLocalShimNowarnTransforms
 *
 * WHAT
 * - Injects @compile {:nowarn_unused_function, [from: 3, where: 3]} into modules
 *   that define local Ecto Query DSL shim functions (defp from/3 and/or defp where/3).
 *
 * WHY
 * - Typed Ecto DSL snapshots expect an explicit nowarn attribute for these shims to
 *   keep warnings-as-errors clean without name-heuristic pruning. The functions may
 *   be referenced conditionally; this attribute preserves idiomatic output.
 *
 * HOW
 * - For each module, scan body for defp named "from" or "where" and collect their arities.
 * - If any are present, ensure a single @compile {:nowarn_unused_function, [..]} attribute
 *   exists at the top of the module body, merging names/arity if the attribute already exists.
 * - Shape-based guard: only acts when these exact DSL shim names are declared in module scope.
 *
 * EXAMPLES
 * Before:
 *   defmodule UserQueries do
 *     defp from(_t, _a, _opts), do: nil
 *     defp where(_q, _a, _cond), do: nil
 *   end
 * After:
 *   defmodule UserQueries do
 *     @compile {:nowarn_unused_function, [from: 3, where: 3]}
 *     defp from(_t, _a, _opts), do: nil
 *     defp where(_q, _a, _cond), do: nil
 *   end
 */
class EctoLocalShimNowarnTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body):
                    var updated = injectNowarn(attrs, body);
                    if (updated != null) makeASTWithMeta(EModule(name, attrs, updated), n.metadata, n.pos) else n;
                case EDefmodule(name, doBlock):
                    var stmts: Array<ElixirAST> = switch (doBlock.def) {
                        case EBlock(ss): ss;
                        case EDo(ss): ss;
                        default: [doBlock];
                    };
                    var updated2 = injectNowarn([], stmts);
                    if (updated2 != null) {
                        makeASTWithMeta(EDefmodule(name, makeAST(EBlock(updated2))), n.metadata, n.pos);
                    } else n;
                default:
                    n;
            }
        });
    }

    static function injectNowarn(attrs: Array<EAttribute>, body: Array<ElixirAST>): Null<Array<ElixirAST>> {
        // Collect arities of local defp from/where
        var arities = new Map<String, Int>();
        for (b in body) switch (b.def) {
            case EDefp(fname, args, _, _):
                if (fname == "from" || fname == "where") {
                    arities.set(fname, args != null ? args.length : 0);
                }
            default:
        }
        if (!arities.keys().hasNext()) return null; // no shims present

        // Build compile value: {:nowarn_unused_function, [from: 3, where: 3]}
        var pairs: Array<EKeywordPair> = [];
        // consistent order
        if (arities.exists("from")) pairs.push({key: "from", value: makeAST(EInteger(arities.get("from")))});
        if (arities.exists("where")) pairs.push({key: "where", value: makeAST(EInteger(arities.get("where")))});
        var value = makeAST(ETuple([
            makeAST(EAtom("nowarn_unused_function")),
            makeAST(EKeywordList(pairs))
        ]));

        // If an existing @compile {:nowarn_unused_function, ...} exists, do not duplicate
        var hasNowarn = false;
        for (b in body) switch (b.def) {
            case EModuleAttribute(an, v) if (an == "compile"):
                switch (v.def) {
                    case ETuple(es) if (es.length == 2):
                        switch (es[0].def) {
                            case EAtom(a) if (a == "nowarn_unused_function"): hasNowarn = true;
                            default:
                        }
                    default:
                }
            default:
        }

        var newBody: Array<ElixirAST> = [];
        if (!hasNowarn) newBody.push(makeAST(EModuleAttribute("compile", value)));
        for (b in body) newBody.push(b);
        return newBody;
    }
}

#end
