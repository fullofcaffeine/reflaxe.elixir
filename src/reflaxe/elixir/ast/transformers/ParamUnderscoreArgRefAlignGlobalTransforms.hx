package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ParamUnderscoreArgRefAlignGlobalTransforms
 *
 * WHAT
 * - If a function parameter is declared with an underscored name (e.g., `_v`),
 *   but the body references the non-underscored name (`v`), rewrite those body
 *   references to the underscored binder.
 *
 * WHY
 * - Other hygiene passes may underscore unused head parameters without updating
 *   all body references. This fixes mismatches that cause undefined variable
 *   errors in modules like `Log` or small helper modules.
 */
class ParamUnderscoreArgRefAlignGlobalTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body):
          var map = collect(args);
          if (!hasEntries(map)) n else makeASTWithMeta(EDef(name, args, guards, rewrite(body, map)), n.metadata, n.pos);
        case EDefp(name2, args2, guards2, body2):
          var map2 = collect(args2);
          if (!hasEntries(map2)) n else makeASTWithMeta(EDefp(name2, args2, guards2, rewrite(body2, map2)), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function collect(args:Array<EPattern>):Map<String,String> {
    var m = new Map<String,String>();
    if (args == null) return m;
    for (a in args) switch (a) {
      case PVar(nm) if (nm != null && nm.length > 1 && nm.charAt(0) == '_'):
        var base = nm.substr(1);
        if (base.length > 0) m.set(base, nm);
      default:
    }
    return m;
  }

  static function hasEntries(m:Map<String,String>):Bool {
    for (_ in m.keys()) return true;
    return false;
  }

  static function rewrite(body:ElixirAST, m:Map<String,String>):ElixirAST {
    return ElixirASTTransformer.transformNode(body, function(x:ElixirAST):ElixirAST {
      return switch (x.def) {
        case EVar(v) if (v != null && m.exists(v)):
          makeASTWithMeta(EVar(m.get(v)), x.metadata, x.pos);
        default:
          x;
      }
    });
  }
}

#end
