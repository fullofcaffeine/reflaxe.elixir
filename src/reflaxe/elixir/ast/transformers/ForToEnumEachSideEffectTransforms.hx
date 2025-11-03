package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ForToEnumEachSideEffectTransforms
 *
 * WHAT
 * - Rewrites simple EFor generators into Enum.each(collection, fn var -> body end)
 *   when the loop body is used for side effects (i.e., no accumulation expected).
 *
 * WHY
 * - Certain loop optimizer paths can mis-shape for/while constructs in complex
 *   modules (e.g., LiveView + HEEx), leading to invalid enumerators. Converting
 *   directly to Enum.each yields stable, idiomatic Elixir for side-effect loops.
 *
 * HOW
 * - Matches EFor with a single generator pattern `PVar(var)`.
 * - If filters exist, fold them into a single predicate and wrap the collection
 *   with Enum.filter(collection, fn var -> predicate end).
 * - Produces: Enum.each(collection_or_filtered, fn var -> body end).
 * - Does not fire for comprehensions that return values (`into` present) or
 *   when the generator pattern is not a simple variable.
 *
 * EXAMPLES
 * Haxe (desugared):
 *   for (t in todos) if (!t.completed) Repo.update(...);
 * Elixir (after):
 *   Enum.each(todos, fn t -> if (!t.completed) do Repo.update(...) end end)
 */
class ForToEnumEachSideEffectTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EFor(generators, filters, body, into, _uniq)
          if (into == null && generators != null && generators.length == 1):
            var g = generators[0];
            // Only rewrite simple `var <- collection` patterns
            switch (g.pattern) {
              case PVar(varName):
                var collection = g.expr;
                // Fold filters, if any, into Enum.filter
                var source = (filters != null && filters.length > 0)
                  ? makeAST(ERemoteCall(
                      makeAST(EVar("Enum")),
                      "filter",
                      [
                        collection,
                        makeAST(EFn([
                          { args: [PVar(varName)], guard: null, body: foldAnd(filters) }
                        ]))
                      ]
                    ))
                  : collection;
                // Build Enum.each(source, fn varName -> body end)
                // Keep the original generator variable name for the lambda to
                // avoid drift across later hygiene passes
                var paramName = varName;
                var rewrittenBody = body;
                var each = makeAST(ERemoteCall(
                  makeAST(EVar("Enum")),
                  "each",
                  [ source, makeAST(EFn([{ args: [PVar(paramName)], guard: null, body: rewrittenBody }])) ]
                ));
                makeASTWithMeta(each.def, n.metadata, n.pos);
              default:
                n; // Non-simple generator pattern; leave as-is
            }
        default:
          n;
      }
    });
  }

  static function foldAnd(filters:Array<ElixirAST>): ElixirAST {
    if (filters == null || filters.length == 0) return makeAST(EAtom("true"));
    var acc = filters[0];
    for (i in 1...filters.length) {
      acc = makeAST(EBinary(And, acc, filters[i]));
    }
    return acc;
  }

  static function renameVar(node: ElixirAST, from:String, to:String): ElixirAST {
    if (from == to) return node;
    return ElixirASTTransformer.transformNode(node, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case EVar(v) if (v == from): makeASTWithMeta(EVar(to), x.metadata, x.pos);
        default: x;
      }
    });
  }
}

#end
