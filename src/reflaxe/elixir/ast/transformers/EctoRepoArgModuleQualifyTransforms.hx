package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * EctoRepoArgModuleQualifyTransforms
 *
 * WHAT
 * - Qualify bare module names passed as the first argument to Repo.get/2 and Repo.one/2
 *   with the application prefix, e.g., `Repo.get(Todo, id)` → `Repo.get(<App>.Todo, id)`.
 *
 * WHY
 * - Phoenix/Ecto expect a proper module (MyApp.Schema) as the schema argument.
 *   Some code paths emit single‑segment module refs; this transform qualifies them
 *   using the configured app name (via -D app_name).
 *
 * HOW
 * - Match ERemoteCall(module=EVar("<App>.Repo"), func in ["get","one"]) with args[0]=EVar(Name)
 *   where Name is a single CamelCase segment without dots, and rewrite to EVar("<App>." + Name).
 */
class EctoRepoArgModuleQualifyTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
      return switch (n.def) {
        case ERemoteCall({def: EVar(repoMod)}, fun, args) if (fun == "get" || fun == "one") && args != null && args.length >= 1:
          var app = getAppPrefix();
          if (app != null && repoMod == app + ".Repo") {
            var first = args[0];
            switch (first.def) {
              case EVar(name) if (isSingleSegmentCamel(name)):
                var qualified = makeAST(EVar(app + "." + name));
                var newArgs = args.copy();
                newArgs[0] = qualified;
                makeASTWithMeta(ERemoteCall(makeAST(EVar(repoMod)), fun, newArgs), n.metadata, n.pos);
              default:
                n;
            }
          } else n;
        default:
          n;
      }
    });
  }

  static inline function isSingleSegmentCamel(name:String):Bool {
    if (name == null || name.length == 0) return false;
    return name.indexOf('.') == -1 && name.charAt(0).toUpperCase() == name.charAt(0) && name.charAt(0).toLowerCase() != name.charAt(0);
  }

  static inline function getAppPrefix():Null<String> {
    try {
      return reflaxe.elixir.PhoenixMapper.getAppModuleName();
    } catch (e:Dynamic) {
      return null;
    }
  }
}

#end

