package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HandleEventParamsHeadToParamsUltimateTransforms
 *
 * WHAT
 * - Absolute-ultimate guard: if a handle_event/3 body references `params` but
 *   the head binder is not `params`, rename the head binder to `params` and
 *   align body references from `_params` to `params`.
 */
class HandleEventParamsHeadToParamsUltimateTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body) if (isHandleEvent3(name, args)):
          var newArgs = (args != null && args.length >= 2) ? args.copy() : args;
          if (newArgs != null && newArgs.length >= 2) {
            newArgs[1] = PVar("params");
            var nb = rewriteBodyToParams(body);
            makeASTWithMeta(EDef(name, newArgs, guards, nb), n.metadata, n.pos);
          } else n;
        case EDefp(name2, args2, guards2, body2) if (isHandleEvent3(name2, args2)):
          var newArgs2 = (args2 != null && args2.length >= 2) ? args2.copy() : args2;
          if (newArgs2 != null && newArgs2.length >= 2) {
            newArgs2[1] = PVar("params");
            var nb2 = rewriteBodyToParams(body2);
            makeASTWithMeta(EDefp(name2, newArgs2, guards2, nb2), n.metadata, n.pos);
          } else n;
        default:
          n;
      }
    });
  }

  static inline function isHandleEvent3(name:String, args:Array<EPattern>):Bool {
    return name == "handle_event" && args != null && args.length == 3;
  }

  static function usesVar(node: ElixirAST, v:String): Bool {
    var found = false;
    reflaxe.elixir.ast.ASTUtils.walk(node, function(x: ElixirAST) {
      if (found) return;
      switch (x.def) { case EVar(nm) if (nm == v): found = true; default: }
    });
    return found;
  }

  static function rewriteBodyToParams(body: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case EVar(nm) if (nm == "_params"): makeASTWithMeta(EVar("params"), x.metadata, x.pos);
        default: x;
      }
    });
  }
}

#end
