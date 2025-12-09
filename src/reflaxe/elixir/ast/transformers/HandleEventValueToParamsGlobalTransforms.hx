package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HandleEventValueToParamsGlobalTransforms
 *
 * WHAT
 * - Absolute-final guard that rewrites any bare `value` identifier inside
 *   handle_event/3 bodies to the head params binder.
 *
 * WHY
 * - Some pipelines still emit `value` without a binding. Rewriting to params
 *   avoids undefined-variable errors and keeps receivers consistent.
 *
 * HOW
 * - For each handle_event/3, determine paramsVar from the second argument and
 *   replace EVar("value") with EVar(paramsVar) throughout the body.
 */
class HandleEventValueToParamsGlobalTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body) if (isHandleEvent3(name, args)):
          var pv = paramsVar(args);
          makeASTWithMeta(EDef(name, args, guards, rewrite(body, pv)), n.metadata, n.pos);
        case EDefp(name2, args2, guards2, body2) if (isHandleEvent3(name2, args2)):
          var pv2 = paramsVar(args2);
          makeASTWithMeta(EDefp(name2, args2, guards2, rewrite(body2, pv2)), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static inline function isHandleEvent3(name:String, args:Array<EPattern>):Bool {
    return name == "handle_event" && args != null && args.length == 3;
  }

  static inline function paramsVar(args:Array<EPattern>):String {
    if (args != null && args.length >= 2) return switch (args[1]) { case PVar(n): n; default: "params"; };
    return "params";
  }

  static function rewrite(body: ElixirAST, pv:String): ElixirAST {
    return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case EVar(v) if (v == "value"): makeASTWithMeta(EVar(pv), x.metadata, x.pos);
        default: x;
      }
    });
  }
}

#end
