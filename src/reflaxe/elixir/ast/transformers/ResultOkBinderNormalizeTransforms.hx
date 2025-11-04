package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ResultOkBinderNormalizeTransforms
 *
 * WHAT
 * - Normalizes {:ok, binder} case clauses to avoid leaking non-idiomatic names like
 *   `ok_value` and ensures body references are coherent with the binder.
 *
 * WHY
 * - Some upstream sources or safety passes may introduce the binder name `ok_value` or
 *   leave body references using `ok_value` while the pattern uses `value`. This results
 *   in undefined variables and non-idiomatic names.
 *
 * HOW
 * - For each ECase clause with pattern `{:ok, PVar(name)}` (or `{:ok, name}`):
 *   - If name == "ok_value", rename binder to "value".
 *   - Replace EVar("ok_value") occurrences in the clause body with the effective binder name.
 * - Applies equally when the atom is either ":ok" or "ok".
 */
class ResultOkBinderNormalizeTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case ECase(target, clauses):
          var out = [];
          for (c in clauses) {
            var newC = c;
            switch (c.pattern) {
              case PTuple(els) if (els.length == 2):
                var isOk = switch (els[0]) {
                  case PLiteral({def: EAtom(a)}): (a == ":ok" || a == "ok");
                  default: false;
                };
                if (isOk) {
                  switch (els[1]) {
                    case PVar(pname) if (pname != null):
                      var effective = (pname == "ok_value") ? "value" : pname;
                      var pat = (pname == effective) ? c.pattern : PTuple([els[0], PVar(effective)]);
                      // Rewrite body occurrences of ok_value to effective binder
                      var nb = ElixirASTTransformer.transformNode(c.body, function(x: ElixirAST): ElixirAST {
                        return switch (x.def) {
                          case EVar(v) if (v == "ok_value"): makeASTWithMeta(EVar(effective), x.metadata, x.pos);
                          default: x;
                        };
                      });
                      newC = { pattern: pat, guard: c.guard, body: nb };
                    default:
                  }
                }
              default:
            }
            out.push(newC);
          }
          makeASTWithMeta(ECase(target, out), n.metadata, n.pos);
        default:
          n;
      }
    });
  }
}

#end

