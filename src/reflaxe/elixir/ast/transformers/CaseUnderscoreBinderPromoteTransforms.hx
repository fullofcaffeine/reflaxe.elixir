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
                // Promote any underscored binders within the tuple if the base name is used in body
                var newParts = parts.copy();
                var promoted = false;
                for (i in 0...newParts.length) {
                  switch (newParts[i]) {
                    case PVar(nm) if (nm != null && nm.length > 1 && nm.charAt(0) == '_'):
                      var used = false;
                      // Detect direct references in AST
                      ElixirASTTransformer.transformNode(cl.body, function(x: ElixirAST): ElixirAST {
                        if (used) return x;
                        switch (x.def) {
                          case EVar(v) if (v == nm || v == nm.substr(1)): used = true; return x;
                          default: return x;
                        }
                      });
                      // Also detect references via string/raw interpolations: #{...}
                      inline function markInterpolations(s:String):Void {
                        if (used || s == null) return;
                        var re = new EReg("\\#\\{([^}]*)\\}", "g");
                        var pos = 0;
                        while (!used && re.matchSub(s, pos)) {
                          var inner = re.matched(1);
                          var tok = new EReg("[A-Za-z_][A-Za-z0-9_]*", "g");
                          var tpos = 0;
                          while (!used && tok.matchSub(inner, tpos)) {
                            var id = tok.matched(0);
                            if (id == nm || id == nm.substr(1)) used = true;
                            tpos = tok.matchedPos().pos + tok.matchedPos().len;
                          }
                          pos = re.matchedPos().pos + re.matchedPos().len;
                        }
                      }
                      if (!used) {
                        ElixirASTTransformer.transformNode(cl.body, function(y: ElixirAST): ElixirAST {
                          switch (y.def) {
                            case EString(s): markInterpolations(s);
                            case ERaw(code): markInterpolations(code);
                            default:
                          }
                          return y;
                        });
                      }
                      // Also treat guard references as usage
                      if (!used && cl.guard != null) {
                        ElixirASTTransformer.transformNode(cl.guard, function(g: ElixirAST): ElixirAST {
                          switch (g.def) {
                            case EVar(vg) if (vg == nm || vg == nm.substr(1)): used = true; return g;
                            case EString(sg): markInterpolations(sg); return g;
                            case ERaw(cg): markInterpolations(cg); return g;
                            default: return g;
                          }
                        });
                      }
                      if (used) {
                        var base = nm.substr(1);
                        newParts[i] = PVar(base);
                        promoted = true;
                      }
                    default:
                  }
                }
                if (promoted) {
                  var body2 = ElixirASTTransformer.transformNode(cl.body, function(x: ElixirAST): ElixirAST {
                    return switch (x.def) {
                      case EVar(v) if (v != null && v.length > 1 && v.charAt(0) == '_'):
                        makeASTWithMeta(EVar(v.substr(1)), x.metadata, x.pos);
                      case ECase(tgt, cls) if (switch (tgt.def) { case EVar(v2) if (v2 != null && v2.length > 1 && v2.charAt(0) == '_'): true; default: false; }):
                        var trimmed = switch (tgt.def) { case EVar(v3): v3.substr(1); default: null; };
                        makeASTWithMeta(ECase(makeAST(EVar(trimmed)), cls), x.metadata, x.pos);
                      default: x;
                    }
                  });
                  c2 = { pattern: PTuple(newParts), guard: cl.guard, body: body2 };
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
