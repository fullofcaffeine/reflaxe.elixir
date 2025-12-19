package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HandleEventDecodeValueQueryIfBinaryUltimateTransforms
 *
 * WHAT
 * - In handle_event/3, when an argument expression is `Map.get(params, "value", ...)` and the
 *   runtime value could be a URL-encoded query string, replace it with a guard that decodes the
 *   string via URI.decode_query/1, otherwise pass the original term through.
 *
 * WHY
 * - LiveView can send form payloads where `value` is a URL-encoded string. Our helpers expect a
 *   map. This pass makes the call sites resilient without app-specific knowledge.
 */
class HandleEventDecodeValueQueryIfBinaryUltimateTransforms {
  /**
   * EXAMPLES
   * Haxe (snapshot: liveview/handle_event_value_decode):
   *   @:liveview class Main {
   *     public static function handle_event(event:String, params:elixir.types.Term, socket:phoenix.Phoenix.Socket<{}>) {
   *       switch (event) {
   *         case "search_todos": performSearch(params.value, socket);
   *         default:
   *       }
   *       return {status: "noreply", socket: socket};
   *     }
   *   }
   * Elixir (before):
   *   perform_search(Map.get(params, "value"), socket)
   * Elixir (after):
   *   perform_search((if Kernel.is_binary(Map.get(params, "value")), do: URI.decode_query(Map.get(params, "value")), else: Map.get(params, "value"))), socket)
   */
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(functionName, parameters, guards, body) if (isHandleEvent3(functionName, parameters)):
          var paramsParam = secondArg(parameters);
          var newBody = rewrite(body, paramsParam);
          makeASTWithMeta(EDef(functionName, parameters, guards, newBody), n.metadata, n.pos);
        case EDefp(functionName, parameters, guards, body) if (isHandleEvent3(functionName, parameters)):
          var paramsParam = secondArg(parameters);
          var newBody = rewrite(body, paramsParam);
          makeASTWithMeta(EDefp(functionName, parameters, guards, newBody), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static inline function isHandleEvent3(name:String, args:Array<EPattern>):Bool {
    return name == "handle_event" && args != null && args.length == 3 && switch (args[0]) { case PLiteral({def: EString(_)}): true; default: false; };
  }
  static inline function secondArg(args:Array<EPattern>):String { return switch (args[1]) { case PVar(n): n; default: "params"; } }

  static function rewrite(body: ElixirAST, paramsVar:String): ElixirAST {
    return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case ECall(target, functionName, callArgs) if (callArgs != null && callArgs.length > 0):
          var remapped = mapArgs(callArgs, paramsVar);
          if (remapped == null) x else makeASTWithMeta(ECall(target, functionName, remapped), x.metadata, x.pos);
        case ERemoteCall(remoteTarget, functionName, remoteArgs) if (remoteArgs != null && remoteArgs.length > 0):
          var remapped = mapArgs(remoteArgs, paramsVar);
          if (remapped == null) x else makeASTWithMeta(ERemoteCall(remoteTarget, functionName, remapped), x.metadata, x.pos);
        default:
          x;
      }
    });
  }

  static function mapArgs(args:Array<ElixirAST>, paramsVar:String): Null<Array<ElixirAST>> {
    var changed = false;
    var out:Array<ElixirAST> = [];
    for (a in args) {
      var repl = decodeIfValueGet(a, paramsVar);
      if (repl != null) { out.push(repl); changed = true; } else out.push(a);
    }
    return changed ? out : null;
  }

  static function decodeIfValueGet(node:ElixirAST, paramsVar:String): Null<ElixirAST> {
    // Match Map.get(params, "value", …) or call-form Map.get(params, "value", …)
    var inner: Null<ElixirAST> = null;
    switch (node.def) {
      case ERemoteCall({def: EVar("Map")}, "get", a) if (a != null && a.length >= 2):
        if (isParamsVar(a[0], paramsVar) && isValueKey(a[1])) inner = makeAST(ERemoteCall(makeAST(EVar("Map")), "get", a));
      case ECall(tgt, "get", argsList):
        var isMap = switch (tgt.def) { case EVar(m): m == "Map"; default: false; };
        if (isMap && argsList != null && argsList.length >= 2) {
          if (isParamsVar(argsList[0], paramsVar) && isValueKey(argsList[1])) inner = makeAST(ECall(tgt, "get", argsList));
        }
      default:
    }
    if (inner == null) return null;
    // Build: if Kernel.is_binary(inner), do: URI.decode_query(inner), else: inner
    var isBin = makeAST(ERemoteCall(makeAST(EVar("Kernel")), "is_binary", [ inner ]));
    var decoded = makeAST(ERemoteCall(makeAST(EVar("URI")), "decode_query", [ inner ]));
    return makeAST(EIf(isBin, decoded, inner));
  }

  static inline function isParamsVar(ast:ElixirAST, paramsVar:String):Bool return switch (ast.def) { case EVar(v): v == paramsVar; default: false; }
  static inline function isValueKey(ast:ElixirAST):Bool return switch (ast.def) { case EString(s): s == "value"; default: false; }
}

#end
