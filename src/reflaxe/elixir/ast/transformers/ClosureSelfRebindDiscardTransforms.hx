package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ClosureSelfRebindDiscardTransforms
 *
 * WHAT
 * - Inside anonymous functions, replace rebinds of the closure's own single
 *   binder variable (e.g., `item = expr`) with a discard assignment `_ = expr`.
 *
 * WHY
 * - Prevents warnings where the rebind of the binder is unused and flagged under
 *   MIX_ENV=test --warnings-as-errors. Semantics are preserved because these
 *   rebinds were not read afterwards; the expression side effects remain.
 *
 * HOW
 * - For each EFn clause with exactly one argument PVar(name), rewrite in the
 *   clause body any top-level or nested `EMatch(PVar(name), rhs)` or
 *   `EBinary(Match, EVar(name), rhs)` to use `_` instead of the binder name.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class ClosureSelfRebindDiscardTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EFn(clauses):
          var out = [];
          for (cl in clauses) {
            var binder: Null<String> = switch (cl.args.length == 1 ? cl.args[0] : null) {
              case PVar(v): v;
              default: null;
            };
            if (binder == null) { out.push(cl); continue; }
            var newBody = ElixirASTTransformer.transformNode(cl.body, function(x: ElixirAST): ElixirAST {
              return switch (x.def) {
                case EBinary(Match, left, rhs):
                  switch (left.def) {
                    case EVar(v) if (v == binder): makeASTWithMeta(EBinary(Match, makeASTWithMeta(EVar("_"), left.metadata, left.pos), rhs), x.metadata, x.pos);
                    default: x;
                  }
                case EMatch(pat, rhs2):
                  switch (pat) {
                    case PVar(v2) if (v2 == binder): makeASTWithMeta(EMatch(PVar("_"), rhs2), x.metadata, x.pos);
                    default: x;
                  }
                default:
                  x;
              }
            });
            out.push({ args: cl.args, guard: cl.guard, body: newBody });
          }
          makeASTWithMeta(EFn(out), n.metadata, n.pos);
        default:
          n;
      }
    });
  }
}

#end

