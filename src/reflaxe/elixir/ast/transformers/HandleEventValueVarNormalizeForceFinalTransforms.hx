package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HandleEventValueVarNormalizeForceFinalTransforms
 *
 * WHAT
 * - Absolute-last guard: in def handle_event/3, forcibly rewrite any
 *   Map.get(value, key) to Map.get(params/_params, key) using the head
 *   payload binder, regardless of prior declarations.
 *
 * WHY
 * - Some late passes may re-introduce Map.get(value, …) forms around
 *   id conversions. This ensures no undefined "value" remains.
 */
class HandleEventValueVarNormalizeForceFinalTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body) if (isHandleEvent3(name, args)):
          var payloadVar = extractParamsVarName(args);
          var nb = rewriteBody(body, payloadVar);
          makeASTWithMeta(EDef(name, args, guards, nb), n.metadata, n.pos);
        case EDefp(name2, args2, guards2, body2) if (isHandleEvent3(name2, args2)):
          var payloadVar2 = extractParamsVarName(args2);
          var nb2 = rewriteBody(body2, payloadVar2);
          makeASTWithMeta(EDefp(name2, args2, guards2, nb2), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static inline function isHandleEvent3(name:String, args:Array<EPattern>):Bool {
    if (name != "handle_event" || args == null || args.length != 3) return false;
    return switch (args[0]) {
      case PLiteral({def: EString(_)}): true;
      default: false;
    }
  }

  static inline function extractParamsVarName(args:Array<EPattern>):String {
    if (args == null || args.length < 2) return "params";
    return switch (args[1]) { case PVar(nm): nm; default: "params"; }
  }

  static function rewriteBody(body: ElixirAST, payloadVar:String): ElixirAST {
    /**
     * WHAT
     * - Absolute-last sweep that forcibly replaces Map.get(value, "…") with
     *   Map.get(<payloadVar>, "…") inside handle_event/3 bodies.
     * WHY
     * - Guarantees no late-introduced `value` leaks survive ordering of earlier
     *   transforms (e.g., id conversion branches).
     * HOW
     * - Matches ERemoteCall(Map.get, [EVar("value"), key]) and rewrites to use
     *   the actual payload binder. No dependency on body-declared names here.
     * DEBUG
     * - Enable logs with `-D debug_handle_event_value` to print each forced
     *   replacement; these logs are emitted by the compiler, not the app.
     */
    return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case ERemoteCall({def: EVar("Map")}, "get", a) if (a != null && a.length == 2):
          switch (a[0].def) {
            case EVar(v) if (v == "value"):
              var newArgs = [ makeAST(EVar(payloadVar)), a[1] ];
              #if debug_handle_event_value
              Sys.println('[HandleEventValueVarNormalizeForceFinal] rewrite Map.get(value, ...) -> Map.get(' + payloadVar + ', ... )');
              #end
              makeASTWithMeta(ERemoteCall(makeAST(EVar("Map")), "get", newArgs), x.metadata, x.pos);
            default: x;
          }
        case ECall(target, funcName, a2) if (funcName == "get" && a2 != null && a2.length == 2):
          var isMap = switch (target.def) { case EVar(m): m == "Map"; default: false; };
          if (isMap) switch (a2[0].def) {
            case EVar(v2) if (v2 == "value"):
              var newArgs2 = [ makeAST(EVar(payloadVar)), a2[1] ];
              #if debug_handle_event_value
              Sys.println('[HandleEventValueVarNormalizeForceFinal] rewrite Map.get(value, ...) -> Map.get(' + payloadVar + ', ... )');
              #end
              makeASTWithMeta(ECall(target, funcName, newArgs2), x.metadata, x.pos);
            default: x;
          } else x;
        case ERaw(code) if (code != null && (code.indexOf("Map.get(value,") != -1)):
          try {
            var replaced = StringTools.replace(code, "Map.get(value,", 'Map.get(' + payloadVar + ',');
            if (replaced != code) {
              #if debug_handle_event_value
              Sys.println('[HandleEventValueVarNormalizeForceFinal] rewrite raw Map.get(value, ...) -> Map.get(' + payloadVar + ', ... )');
              #end
              makeASTWithMeta(ERaw(replaced), x.metadata, x.pos);
            } else x;
          } catch (_) {
            x;
          }
        default: x;
      }
    });
  }
}

#end
