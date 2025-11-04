package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HandleEventMapGetValueDefaultToParamsFinalTransforms
 *
 * WHAT
 * - In handle_event/3 wrappers, rewrite Map.get(params|_params, "value") to
 *   Map.get(params|_params, "value", params|_params), i.e. provide a default
 *   of the full params payload when the "value" key is absent.
 *
 * WHY
 * - Phoenix form submissions (phx-submit) send the form fields as the params
 *   map, without a "value" key. Click events commonly use phx-value-* and a
 *   single "value" entry. This transform preserves existing click semantics
 *   while making form handlers receive the full params map without relying on
 *   app-specific heuristics.
 *
 * HOW
 * - For each def handle_event/3, capture the payload var name from the second
 *   parameter (typically `params` or `_params`). Inside the body, replace:
 *     Map.get(payloadVar, "value")
 *   with:
 *     Map.get(payloadVar, "value", payloadVar)
 * - Applies to both ERemoteCall(Map.get, …) and ECall forms, and performs a
 *   conservative ERaw textual patch as a last resort.
 * - Runs very late, after head/binder alignment and other value/param repairs.
 *
 * EXAMPLES
 *   def handle_event("create_todo", params, socket) do
 *     {:noreply, create_todo(Map.get(params, "value"), socket)}
 *   end
 *   →
 *   def handle_event("create_todo", params, socket) do
 *     {:noreply, create_todo(Map.get(params, "value", params), socket)}
 *   end
 */
class HandleEventMapGetValueDefaultToParamsFinalTransforms {
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
        // Map.get(payloadVar, "value") → Map.get(payloadVar, "value", Map.get(payloadVar, "id", payloadVar))
        case ERemoteCall({def: EVar("Map")}, "get", a) if (a != null && a.length == 2):
          var isPayload = switch (a[0].def) { case EVar(v) if (v == payloadVar): true; default: false; };
          var isValueKey = switch (a[1].def) { case EString(s): s == "value"; default: false; };
          if (isPayload && isValueKey) {
            var idRaw = makeAST(ERemoteCall(makeAST(EVar("Map")), "get", [ a[0], makeAST(EString("id")), makeAST(EVar(payloadVar)) ]));
            var isBin = makeAST(ERemoteCall(makeAST(EVar("Kernel")), "is_binary", [ idRaw ]));
            var idToInt = makeAST(ERemoteCall(makeAST(EVar("String")), "to_integer", [ idRaw ]));
            var idCoerced = makeAST(EIf(isBin, idToInt, idRaw));
            var newArgs = [ a[0], a[1], idCoerced ];
            makeASTWithMeta(ERemoteCall(makeAST(EVar("Map")), "get", newArgs), x.metadata, x.pos);
          } else x;
        case ECall(target, funcName, a2) if (funcName == "get" && a2 != null && a2.length == 2):
          var isMap = switch (target.def) { case EVar(m): m == "Map"; default: false; };
          var isPayload2 = isMap && switch (a2[0].def) { case EVar(v2) if (v2 == payloadVar): true; default: false; };
          var isValueKey2 = isMap && switch (a2[1].def) { case EString(s2): s2 == "value"; default: false; };
          if (isPayload2 && isValueKey2) {
            var idRaw2 = makeAST(ERemoteCall(makeAST(EVar("Map")), "get", [ a2[0], makeAST(EString("id")), makeAST(EVar(payloadVar)) ]));
            var isBin2 = makeAST(ERemoteCall(makeAST(EVar("Kernel")), "is_binary", [ idRaw2 ]));
            var idToInt2 = makeAST(ERemoteCall(makeAST(EVar("String")), "to_integer", [ idRaw2 ]));
            var idCoerced2 = makeAST(EIf(isBin2, idToInt2, idRaw2));
            var newArgs2 = [ a2[0], a2[1], idCoerced2 ];
            makeASTWithMeta(ECall(target, funcName, newArgs2), x.metadata, x.pos);
          } else x;
        case ERaw(code) if (code != null && code.indexOf("Map.get(" + payloadVar + ", \"value\")") != -1):
          var replaced = StringTools.replace(code, 
            "Map.get(" + payloadVar + ", \"value\")",
            "Map.get(" + payloadVar + ", \"value\", (if Kernel.is_binary(Map.get(" + payloadVar + ", \"id\", " + payloadVar + ")), do: String.to_integer(Map.get(" + payloadVar + ", \"id\", " + payloadVar + ")), else: Map.get(" + payloadVar + ", \"id\", " + payloadVar + ")) )"
          );
          if (replaced != code) makeASTWithMeta(ERaw(replaced), x.metadata, x.pos) else x;
        default: x;
      }
    });
  }
}

#end
