package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import StringTools;

/**
 * CaseSomeBinderNormalizeTransforms
 *
 * WHAT
 * - In case clauses that match Option-like tuples `{:some, binder}`, promote
 *   a leading-underscore binder (e.g., `_socket`) to a safe identifier and
 *   rewrite body references accordingly.
 *
 * WHY
 * - Avoids warnings "underscored variable used after being set" when the
 *   underscored binder is referenced in expression context.
 *
 * HOW
 * - For each ECase clause, if the pattern is PTuple([PLiteral(:some|"some"), PVar(name)])
 *   and name starts with `_` and is referenced in the clause body/guard, then:
 *     - Rename pattern binder to `payload` (or trimmed name if safe).
 *     - Replace EVar(old) occurrences in the clause body/guard with the new name.
 */
class CaseSomeBinderNormalizeTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case ECase(expr, clauses):
          var out:Array<ECaseClause> = [];
          for (cl in clauses) {
            var newCl = cl;
            switch (cl.pattern) {
              case PTuple(parts) if (parts.length == 2):
                var isSome = false;
                switch (parts[0]) {
                  case PLiteral(l):
                    isSome = switch (l.def) {
                      case EAtom(a) if (a == ":some" || a == "some"): true;
                      default: false;
                    };
                  default:
                }
                if (isSome) switch (parts[1]) {
                  case PVar(nm) if (nm != null && nm.length > 1 && nm.charAt(0) == '_'):
                    // Check body usage
                    var used = false;
                    ElixirASTTransformer.transformNode(cl.body, function(x: ElixirAST): ElixirAST {
                      if (used) return x; switch (x.def) {
                        case EVar(v) if (v == nm): used = true; return x;
                        default: return x;
                      }
                    });
                    if (used) {
                      // choose safe name
                      var candidate = nm.substr(1);
                      if (candidate == null || candidate == "" || candidate == "socket") candidate = "payload";
                      var pattern2 = PTuple([parts[0], PVar(candidate)]);
                      var body2 = ElixirASTTransformer.transformNode(cl.body, function(x: ElixirAST): ElixirAST {
                        return switch (x.def) {
                          case EVar(v) if (v == nm): makeASTWithMeta(EVar(candidate), x.metadata, x.pos);
                          default: x;
                        }
                      });
                      newCl = { pattern: pattern2, guard: cl.guard, body: body2 };
                    }
                  default:
                }
              default:
            }
            out.push(newCl);
          }
          makeASTWithMeta(ECase(expr, out), n.metadata, n.pos);
        default:
          n;
      }
    });
  }
}

#end

