package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * WebRemoteCallModuleQualificationTransforms
 *
 * WHAT
 * - In Web modules (AppWeb.*), qualify single-segment remote call modules to
 *   the local AppWeb namespace: `Foo` → `AppWeb.Foo`.
 *
 * WHY
 * - Prevent warnings like `Foo.bar/1 undefined (did you mean AppWeb.Foo.bar/1)`
 *   when the generator emits local Web module references without full prefix.
 *
 * HOW
 * - Detect current module name like `MyAppWeb.SafeAssigns`; extract `MyAppWeb`
 *   prefix; for ERemoteCall with module = EVar("X") and no dot, rewrite to
 *   EVar(prefix + "." + X).
 */
class WebRemoteCallModuleQualificationTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EModule(name, attrs, body) if (isWeb(name)):
          var prefix = appWebPrefix(name);
          var nb = [for (b in body) qualifyInNode(b, prefix)];
          makeASTWithMeta(EModule(name, attrs, nb), n.metadata, n.pos);
        case EDefmodule(name2, doBlock) if (isWeb(name2)):
          var p2 = appWebPrefix(name2);
          makeASTWithMeta(EDefmodule(name2, qualifyInNode(doBlock, p2)), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static inline function isWeb(name:String):Bool {
    return name != null && name.indexOf("Web.") > 0;
  }
  static inline function appWebPrefix(name:String):String {
    var idx = name.indexOf("Web.");
    return idx > 0 ? name.substr(0, idx + 3) : name; // include "Web"
  }

  static function qualifyInNode(node: ElixirAST, prefix:String): ElixirAST {
    return ElixirASTTransformer.transformNode(node, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case ERemoteCall({def: EVar(mod)}, fn, args) if (mod != null && mod.indexOf(".") == -1):
          makeASTWithMeta(ERemoteCall(makeAST( EVar(prefix + "." + mod) ), fn, args), x.metadata, x.pos);
        default:
          x;
      }
    });
  }
}

#end

