package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HandleInfoUnderscoreBinderPromoteFinalTransforms
 *
 * WHAT
 * - In handle_info/2, promote {:some, _x} tuple binder to a safe name (payload)
 *   and rewrite clause body references `_x` → `payload`. Also fixes inner
 *   `case _x do ... end` scrutinee to use `payload`.
 */
class HandleInfoUnderscoreBinderPromoteFinalTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body) if (isHandleInfo2(name, args)):
          var nb = rewrite(body);
          makeASTWithMeta(EDef(name, args, guards, nb), n.metadata, n.pos);
        case EDefp(name2, args2, guards2, body2) if (isHandleInfo2(name2, args2)):
          var nb2 = rewrite(body2);
          makeASTWithMeta(EDefp(name2, args2, guards2, nb2), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static inline function isHandleInfo2(name:String, args:Array<EPattern>):Bool {
    return name == "handle_info" && args != null && args.length == 2;
  }

  static function rewrite(body: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case ECase(tgt, clauses):
          var out = [];
          for (cl in clauses) {
            var newCl = cl;
            switch (cl.pattern) {
              case PTuple(ps) if (ps.length == 2):
                var tagOk = switch (ps[0]) {
                  case PLiteral({def: EAtom(a)}): (a == ":some" || a == "some");
                  default: false;
                };
                switch (ps[1]) {
                  case PVar(nm) if (tagOk && nm != null && nm.length > 1 && nm.charAt(0) == "_"):
                    var promoted = "payload";
                    var ps2 = ps.copy();
                    ps2[1] = PVar(promoted);
                    var body2 = renameVar(cl.body, nm, promoted);
                    // Also fix inner case _x do -> case payload do
                    body2 = fixInnerCaseScrutinee(body2, nm, promoted);
                    newCl = { pattern: PTuple(ps2), guard: cl.guard, body: body2 };
                  default:
                }
              default:
            }
            out.push(newCl);
          }
          makeASTWithMeta(ECase(tgt, out), x.metadata, x.pos);
        default: x;
      }
    });
  }

  static function renameVar(node: ElixirAST, from:String, to:String): ElixirAST {
    return ElixirASTTransformer.transformNode(node, function(z: ElixirAST): ElixirAST {
      return switch (z.def) {
        case EVar(v) if (v == from): makeASTWithMeta(EVar(to), z.metadata, z.pos);
        default: z;
      }
    });
  }

  static function fixInnerCaseScrutinee(node: ElixirAST, oldV:String, newV:String): ElixirAST {
    return ElixirASTTransformer.transformNode(node, function(z: ElixirAST): ElixirAST {
      return switch (z.def) {
        case ECase(t, cs):
          var t2 = switch (t.def) { case EVar(v) if (v == oldV): makeASTWithMeta(EVar(newV), t.metadata, t.pos); default: t; };
          makeASTWithMeta(ECase(t2, cs), z.metadata, z.pos);
        default: z;
      }
    });
  }
}

#end

