package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * CaseUnderscoreBinderPromoteTransforms
 *
 * WHAT
 * - In any case clause with a tuple pattern whose second element is a variable
 *   starting with underscore (e.g., `{tag, _x}`), promote the binder by removing
 *   the underscore and rewrite the clause body references accordingly.
 *
 * WHY
 * - Elixir warns when underscored variables are later used. This pass fixes the
 *   root by promoting the binder name when it is actually referenced.
 */
class CaseUnderscoreBinderPromoteTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case ECase(expr, clauses):
          var out:Array<ECaseClause> = [];
          for (cl in clauses) {
            var c2 = cl;
            var oldName: Null<String> = null;
            var newName: Null<String> = null;
            switch (cl.pattern) {
              case PTuple(parts) if (parts.length >= 2):
                switch (parts[1]) {
                  case PVar(nm) if (nm != null && nm.length > 1 && nm.charAt(0) == '_'):
                    // Only promote if used in body
                    var used = false;
                    ElixirASTTransformer.transformNode(cl.body, function(x: ElixirAST): ElixirAST {
                      if (used) return x; switch (x.def) { case EVar(v) if (v == nm): used = true; return x; default: return x; } });
                    if (used) {
                      oldName = nm; newName = nm.substr(1);
                      var np = parts.copy();
                      np[1] = PVar(newName);
                      var body2 = ElixirASTTransformer.transformNode(cl.body, function(x: ElixirAST): ElixirAST {
                        return switch (x.def) {
                          case EVar(v) if (v == oldName): makeASTWithMeta(EVar(newName), x.metadata, x.pos);
                          case ECase(tgt, cls) if (switch (tgt.def) { case EVar(v2) if (v2 == oldName): true; default: false; }):
                            makeASTWithMeta(ECase(makeAST(EVar(newName)), cls), x.metadata, x.pos);
                          default: x;
                        }
                      });
                      c2 = { pattern: PTuple(np), guard: cl.guard, body: body2 };
                    }
                  default:
                }
              default:
            }
            out.push(c2);
          }
          makeASTWithMeta(ECase(expr, out), n.metadata, n.pos);
        default:
          n;
      }
    });
  }
}

#end

