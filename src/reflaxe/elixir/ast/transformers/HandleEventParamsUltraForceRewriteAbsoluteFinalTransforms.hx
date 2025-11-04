package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HandleEventParamsUltraForceRewriteAbsoluteFinalTransforms
 *
 * WHAT
 * - Ultimate guard for handle_event/3: if the second parameter is `_params`,
 *   rename it to `params` and rewrite body references `_params` → `params`.
 *
 * WHY
 * - Earlier ordered fixes may be bypassed by late rebuilds. This pass enforces
 *   the canonical binder to eliminate WAE warnings about using underscored
 *   parameters after being set.
 */
class HandleEventParamsUltraForceRewriteAbsoluteFinalTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body) if (isHandleEvent3(name, args)):
          var newArgs = args != null ? args.copy() : args;
          if (newArgs != null && newArgs.length >= 2) newArgs[1] = PVar("params");
          var nb = rewriteBody(body);
          makeASTWithMeta(EDef(name, newArgs, guards, nb), n.metadata, n.pos);
        case EDefp(name2, args2, guards2, body2) if (isHandleEvent3(name2, args2)):
          var newArgs2 = args2 != null ? args2.copy() : args2;
          if (newArgs2 != null && newArgs2.length >= 2) newArgs2[1] = PVar("params");
          var nb2 = rewriteBody(body2);
          makeASTWithMeta(EDefp(name2, newArgs2, guards2, nb2), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static inline function isHandleEvent3(name:String, args:Array<EPattern>):Bool {
    return name == "handle_event" && args != null && args.length == 3;
  }

  static function rewriteBody(body: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case EVar(n) if (n == "_params"): makeASTWithMeta(EVar("params"), x.metadata, x.pos);
        default: x;
      }
    });
  }
}

#end
