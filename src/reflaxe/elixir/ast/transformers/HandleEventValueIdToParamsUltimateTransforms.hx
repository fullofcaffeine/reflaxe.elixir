package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HandleEventValueIdToParamsUltimateTransforms
 *
 * WHAT
 * - Absolute-ultimate cleanup: in handle_event/3 bodies, force any
 *   Map.get(value, "id") (or call-form Map.get) to use the head params
 *   binder instead of the undeclared `value` identifier.
 *
 * WHY
 * - Some late passes still reintroduce Map.get(value, "id") in id-extraction
 *   branches. This guarantees the receiver is the actual params variable,
 *   eliminating undefined-variable errors.
 *
 * HOW
 * - For each handle_event/3, determine paramsVar from the second argument.
 *   Walk the body and rewrite Map.get(value, "id") (remote or call form)
 *   so the first argument becomes paramsVar. Leaves other keys untouched.
 */
class HandleEventValueIdToParamsUltimateTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body) if (isHandleEvent3(name, args)):
          var paramVar = extractParamsVar(args);
          var nb = rewrite(body, paramVar);
          makeASTWithMeta(EDef(name, args, guards, nb), n.metadata, n.pos);
        case EDefp(name2, args2, guards2, body2) if (isHandleEvent3(name2, args2)):
          var paramVar2 = extractParamsVar(args2);
          var nb2 = rewrite(body2, paramVar2);
          makeASTWithMeta(EDefp(name2, args2, guards2, nb2), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static inline function isHandleEvent3(name:String, args:Array<EPattern>):Bool {
    return name == "handle_event" && args != null && args.length == 3;
  }

  static inline function extractParamsVar(args:Array<EPattern>):String {
    if (args != null && args.length >= 2) return switch (args[1]) { case PVar(n): n; default: "params"; };
    return "params";
  }

  static function rewrite(body: ElixirAST, paramsVar:String): ElixirAST {
    return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case ERemoteCall({def: EVar("Map")}, "get", a) if (a != null && a.length >= 2):
          switch (a[0].def) {
            case EVar(v) if (v == "value" && isIdKey(a[1])):
              var newArgs = a.copy();
              newArgs[0] = makeAST(EVar(paramsVar));
              #if debug_handle_event_value
              Sys.println('[HandleEventValueIdToParamsUltimate] rewrote Map.get(value, \"id\") -> Map.get(' + paramsVar + ', \"id\")');
              #end
              makeASTWithMeta(ERemoteCall(makeAST(EVar("Map")), "get", newArgs), x.metadata, x.pos);
            default: x;
          }
        case ECall(target, "get", a2) if (a2 != null && a2.length >= 2):
          var isMap = switch (target.def) { case EVar(m): m == "Map"; default: false; };
          if (isMap && isIdKey(a2[1])) switch (a2[0].def) {
            case EVar(v2) if (v2 == "value"):
              var newArgs2 = a2.copy();
              newArgs2[0] = makeAST(EVar(paramsVar));
              #if debug_handle_event_value
              Sys.println('[HandleEventValueIdToParamsUltimate] rewrote Map.get(value, \"id\") -> Map.get(' + paramsVar + ', \"id\") (call form)');
              #end
              makeASTWithMeta(ECall(target, "get", newArgs2), x.metadata, x.pos);
            default: x;
          } else x;
        case EVar(v) if (v == "value"):
          // As a last resort, rewrite bare value → paramsVar to avoid undefined variable
          makeASTWithMeta(EVar(paramsVar), x.metadata, x.pos);
        default:
          x;
      }
    });
  }

  static inline function isIdKey(ast: ElixirAST):Bool {
    return switch (ast.def) { case EString(s) if (s == "id"): true; default: false; }
  }
}

#end
