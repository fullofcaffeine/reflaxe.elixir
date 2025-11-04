package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * CaseClauseSuccessBodyBinderRewriteTransforms
 *
 * WHAT
 * - Ensures that within `{:ok, binder}` case clauses, any body references to
 *   legacy placeholders like `ok_value` or `ok_<binder>` are rewritten to `binder`.
 *
 * WHY
 * - Earlier safety/collision passes may mint placeholder names; later alignment can
 *   rename the binder but miss body references in nested closures. This pass enforces
 *   clause-local coherence deterministically without app coupling.
 */
class CaseClauseSuccessBodyBinderRewriteTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case ECase(target, clauses):
          var out = [];
          for (c in clauses) {
            var binder: Null<String> = null;
            switch (c.pattern) {
              case PTuple(els) if (els.length == 2):
                switch (els[0]) {
                  case PLiteral({def: EAtom(a)}) if ((a == ":ok" || a == "ok")):
                    switch (els[1]) { case PVar(b) if (b != null): binder = b; default: }
                  default:
                }
              default:
            }
            if (binder == null) { out.push(c); continue; }
            var b = binder;
            // Rewrite ok_value and ok_<binder> to binder
            var body2 = ElixirASTTransformer.transformNode(c.body, function(x: ElixirAST): ElixirAST {
              return switch (x.def) {
                case EVar(v) if (v == "ok_value" || v == ("ok_" + b)): makeASTWithMeta(EVar(b), x.metadata, x.pos);
                default: x;
              };
            });
            out.push({ pattern: c.pattern, guard: c.guard, body: body2 });
          }
          makeASTWithMeta(ECase(target, out), n.metadata, n.pos);
        default: n;
      }
    });
  }
}

#end

