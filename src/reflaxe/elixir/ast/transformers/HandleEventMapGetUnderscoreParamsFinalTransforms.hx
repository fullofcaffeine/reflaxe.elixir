package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HandleEventMapGetUnderscoreParamsFinalTransforms
 *
 * WHAT
 * - Absolute-final sweep in handle_event/3 bodies: rewrite Map.get(_params, key)
 *   → Map.get(params, key).
 *
 * WHY
 * - Guarantees no references to `_params` remain in Map.get calls after head
 *   promotions and other repairs, avoiding WAE.
 */
class HandleEventMapGetUnderscoreParamsFinalTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body) if (isHandleEvent3(name, args)):
          var payloadVar = extractPayloadVar(args);
          var nb = rewrite(body, payloadVar);
          makeASTWithMeta(EDef(name, args, guards, nb), n.metadata, n.pos);
        case EDefp(name2, args2, guards2, body2) if (isHandleEvent3(name2, args2)):
          var payloadVar2 = extractPayloadVar(args2);
          var nb2 = rewrite(body2, payloadVar2);
          makeASTWithMeta(EDefp(name2, args2, guards2, nb2), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static inline function isHandleEvent3(name:String, args:Array<EPattern>):Bool {
    return name == "handle_event" && args != null && args.length == 3;
  }

  static inline function extractPayloadVar(args:Array<EPattern>): String {
    if (args == null || args.length < 2) return "params";
    return switch (args[1]) { case PVar(nm): nm; default: "params"; }
  }

  static function rewrite(body: ElixirAST, payloadVar:String): ElixirAST {
    return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case ERemoteCall({def: EVar("Map")}, "get", a) if (a != null && a.length == 2):
          switch (a[0].def) {
            case EVar(v) if (v == "_params"):
              var newArgs = [ makeAST(EVar(payloadVar)), a[1] ];
              makeASTWithMeta(ERemoteCall(makeAST(EVar("Map")), "get", newArgs), x.metadata, x.pos);
            default: x;
          }
        case ECall(target, funcName, a2) if (funcName == "get" && a2 != null && a2.length == 2):
          var isMap = switch (target.def) { case EVar(m): m == "Map"; default: false; };
          if (isMap) switch (a2[0].def) {
            case EVar(v2) if (v2 == "_params"):
              var newArgs2 = [ makeAST(EVar(payloadVar)), a2[1] ];
              makeASTWithMeta(ECall(target, funcName, newArgs2), x.metadata, x.pos);
            default: x;
          } else x;
        default: x;
      }
    });
  }
}

#end
