package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HandleEventParamsHeadToParamsFinalTransforms
 *
 * WHAT
 * - Absolute-final guard to ensure handle_event/3 second arg is `params` when
 *   referenced in the body, rewriting `_params` occurrences to `params`.
 */
class HandleEventParamsHeadToParamsFinalTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body) if (isHandleEvent3(name, args)):
          var usedParams = bodyUsesVar(body, "_params") || bodyUsesVar(body, "params");
          var newArgs = (args != null && args.length >= 2) ? args.copy() : args;
          if (newArgs != null && newArgs.length >= 2) {
            if (usedParams) {
              newArgs[1] = PVar("params");
              var nb = rewriteBody(body);
              makeASTWithMeta(EDef(name, newArgs, guards, nb), n.metadata, n.pos);
            } else {
              // Body does not reference params; prefer _params to avoid WAE
              newArgs[1] = PVar("_params");
              makeASTWithMeta(EDef(name, newArgs, guards, body), n.metadata, n.pos);
            }
          } else n;
        case EDefp(name2, args2, guards2, body2) if (isHandleEvent3(name2, args2)):
          var usedParams2 = bodyUsesVar(body2, "_params") || bodyUsesVar(body2, "params");
          var newArgs2 = (args2 != null && args2.length >= 2) ? args2.copy() : args2;
          if (newArgs2 != null && newArgs2.length >= 2) {
            if (usedParams2) {
              newArgs2[1] = PVar("params");
              var nb2 = rewriteBody(body2);
              makeASTWithMeta(EDefp(name2, newArgs2, guards2, nb2), n.metadata, n.pos);
            } else {
              newArgs2[1] = PVar("_params");
              makeASTWithMeta(EDefp(name2, newArgs2, guards2, body2), n.metadata, n.pos);
            }
          } else n;
        default: n;
      }
    });
  }

  static inline function isHandleEvent3(name:String, args:Array<EPattern>):Bool {
    if (name != "handle_event" || args == null || args.length != 3) return false;
    return switch (args[0]) { case PLiteral({def: EString(_)}): true; default: false; }
  }

  static function bodyUsesVar(body: ElixirAST, v:String): Bool {
    var found = false;
    reflaxe.elixir.ast.ASTUtils.walk(body, function(x: ElixirAST) {
      if (found) return;
      switch (x.def) { case EVar(n) if (n == v): found = true; default: }
    });
    return found;
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
