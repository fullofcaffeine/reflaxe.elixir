package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HandleEventIdValueToParamsFixTransforms
 *
 * WHAT
 * - Final shape repair for handle_event/3 clauses that still carry
 *   `Map.get(value, "id")` in id-extraction branches. Rewrites those
 *   receivers to the head params binder.
 *
 * WHY
 * - Some late passes can reintroduce `value` receivers; this ensures
 *   the id extraction is always based on params, preventing undefined
 *   variable errors and keeping semantics correct.
 *
 * HOW
 * - Determine paramsVar from the second argument of handle_event/3.
 *   Rewrite any Map.get(value, "id") (remote or call form) to use
 *   paramsVar. Also rewrites bare EVar("value") to paramsVar inside
 *   handle_event/3 bodies.
 */
class HandleEventIdValueToParamsFixTransforms {
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
        case ERemoteCall({def: EVar("Map")}, "get", a) if (a != null && a.length >= 2):
          switch (a[0].def) {
            case EVar(v) if (v == "value"):
              var newArgs = a.copy();
              newArgs[0] = makeAST(EVar(pv));
              #if debug_handle_event_value
              Sys.println('[HandleEventIdValueToParamsFix] rewrite Map.get(value, ...) -> Map.get(' + pv + ', ...)');
              #end
              makeASTWithMeta(ERemoteCall(makeAST(EVar("Map")), "get", newArgs), x.metadata, x.pos);
            default: x;
          }
        case ECall(target, "get", a2) if (a2 != null && a2.length >= 2):
          var isMap = switch (target.def) { case EVar(m): m == "Map"; default: false; };
          if (isMap) switch (a2[0].def) {
            case EVar(v2) if (v2 == "value"):
              var newArgs2 = a2.copy();
              newArgs2[0] = makeAST(EVar(pv));
              #if debug_handle_event_value
              Sys.println('[HandleEventIdValueToParamsFix] rewrite Map.get(value, ...) call-form -> Map.get(' + pv + ', ...)');
              #end
              makeASTWithMeta(ECall(target, "get", newArgs2), x.metadata, x.pos);
            default: x;
          } else x;
        case ERaw(code) if (code != null && code.indexOf("Map.get(value,") != -1):
          try {
            var replaced = StringTools.replace(code, "Map.get(value,", 'Map.get(' + pv + ',');
            #if debug_handle_event_value
            Sys.println('[HandleEventIdValueToParamsFix] rewrite raw Map.get(value, ...) -> Map.get(' + pv + ', ...)');
            #end
            makeASTWithMeta(ERaw(replaced), x.metadata, x.pos);
          } catch (_:Dynamic) {
            x;
          }
        case EVar(v3) if (v3 == "value"):
          makeASTWithMeta(EVar(pv), x.metadata, x.pos);
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
