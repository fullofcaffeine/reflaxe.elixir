package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HandleEventArg0FromValueToIdUltimateTransforms
 *
 * WHAT
 * - In handle_event/3 clause bodies, when a call uses `Map.get(params, "value", ...)` as its
 *   first argument and `socket` as the last argument, replace that first argument with an
 *   integer-converted id extracted from the nested value map or from the top-level params
 *   fallback.
 *
 * WHY
 * - Click events often send payload as `%{"value" => %{"id" => "123", ...}}` while form submits
 *   omit `value` entirely. Helpers that operate on a specific record typically expect an `id`,
 *   not the entire map. This pass bridges that shape generically without app-specific names.
 *
 * HOW
 * - Match inside `def handle_event(<string>, params, socket)`. For calls where first arg is
 *   `Map.get(params, "value", ...)` (or call-form Map.get)
 *   and last arg is `socket`, swap first arg with:
 *     id_raw = Map.get(Map.get(params, "value"), "id", Map.get(params, "id", params))
 *     if Kernel.is_binary(id_raw), do: String.to_integer(id_raw), else: id_raw
 * - Runs absolute-ultimate in the handle_event cluster.
 */
class HandleEventArg0FromValueToIdUltimateTransforms {
  /**
   * EXAMPLES
   * Haxe (snapshot: liveview/handle_event_value_to_id):
   *   @:liveview class Main {
   *     public static function handle_event(event:String, params:Dynamic, socket:Dynamic) {
   *       switch (event) {
   *         case "toggle_todo": toggleTodo(params.value, socket);
   *         default:
   *       }
   *       return {status: "noreply", socket: socket};
   *     }
   *   }
   * Elixir (before):
   *   toggle_todo(Map.get(params, "value"), socket)
   * Elixir (after):
   *   id_raw = (
   *     case Kernel.is_map(Map.get(params, "value")) do
   *       true -> Map.get(Map.get(params, "value"), "id", Map.get(params, "id", params))
   *       false -> case Kernel.is_binary(Map.get(params, "value")) do
   *         true -> Map.get(URI.decode_query(Map.get(params, "value")), "id", Map.get(params, "id", params))
   *         false -> Map.get(params, "id", params)
   *       end
   *     end
   *   )
   *   id = if Kernel.is_binary(id_raw), do: String.to_integer(id_raw), else: id_raw
   *   toggle_todo(id, socket)
   */
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body) if (isHandleEvent3(name, args)):
          var paramsVar = secondArg(args);
          var socketVar = thirdArg(args);
          var nb = rewrite(body, paramsVar, socketVar);
          makeASTWithMeta(EDef(name, args, guards, nb), n.metadata, n.pos);
        case EDefp(name2, args2, guards2, body2) if (isHandleEvent3(name2, args2)):
          var paramsVar2 = secondArg(args2);
          var socketVar2 = thirdArg(args2);
          var nb2 = rewrite(body2, paramsVar2, socketVar2);
          makeASTWithMeta(EDefp(name2, args2, guards2, nb2), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static inline function isHandleEvent3(name:String, args:Array<EPattern>):Bool {
    return name == "handle_event" && args != null && args.length == 3 && switch (args[0]) { case PLiteral({def: EString(_)}): true; default: false; };
  }
  static inline function secondArg(args:Array<EPattern>):String { return switch (args[1]) { case PVar(n): n; default: "params"; } }
  static inline function thirdArg(args:Array<EPattern>):String { return switch (args[2]) { case PVar(n): n; default: "socket"; } }

  static function rewrite(body: ElixirAST, paramsVar:String, socketVar:String): ElixirAST {
    return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case ECall(target, fname, args) if (args != null && args.length >= 2):
          if (!lastArgIsSocket(args, socketVar)) return x;
          var first = args[0];
          var replace = extractIdFromValueOrNull(first, paramsVar);
          if (replace == null) return x;
          var newArgs = args.copy();
          newArgs[0] = replace;
          makeASTWithMeta(ECall(target, fname, newArgs), x.metadata, x.pos);
        case ERemoteCall(target2, fname2, args2) if (args2 != null && args2.length >= 2):
          if (!lastArgIsSocket(args2, socketVar)) return x;
          var first2 = args2[0];
          var replace2 = extractIdFromValueOrNull(first2, paramsVar);
          if (replace2 == null) return x;
          var newArgs2 = args2.copy();
          newArgs2[0] = replace2;
          makeASTWithMeta(ERemoteCall(target2, fname2, newArgs2), x.metadata, x.pos);
        default:
          x;
      }
    });
  }

  static inline function lastArgIsSocket(args:Array<ElixirAST>, socketVar:String):Bool {
    return args.length >= 1 && switch (args[args.length - 1].def) { case EVar(v) if (v == socketVar): true; default: false; };
  }

  static function extractIdFromValueOrNull(node: ElixirAST, paramsVar:String): Null<ElixirAST> {
    // Match Map.get(params, "value", …) or call-form Map.get(params, "value", …)
    switch (node.def) {
      case ERemoteCall({def: EVar("Map")}, "get", a) if (a != null && a.length >= 2):
        if (isParamsVar(a[0], paramsVar) && isValueKey(a[1])) return buildIdFromNested(paramsVar);
      case ECall(tgt, "get", a2):
        var isMap = switch (tgt.def) { case EVar(m): m == "Map"; default: false; };
        if (isMap && a2 != null && a2.length >= 2) {
          if (isParamsVar(a2[0], paramsVar) && isValueKey(a2[1])) return buildIdFromNested(paramsVar);
        }
      default:
    }
    return null;
  }

  static inline function isParamsVar(ast:ElixirAST, paramsVar:String):Bool {
    return switch (ast.def) { case EVar(v) if (v == paramsVar): true; default: false; }
  }
  static inline function isValueKey(ast:ElixirAST):Bool {
    return switch (ast.def) { case EString(s): s == "value"; default: false; }
  }

  static function buildIdFromNested(paramsVar:String): ElixirAST {
    var inner = makeAST(ERemoteCall(makeAST(EVar("Map")), "get", [ makeAST(EVar(paramsVar)), makeAST(EString("value")) ]));
    var idFromParams = makeAST(ERemoteCall(makeAST(EVar("Map")), "get", [ makeAST(EVar(paramsVar)), makeAST(EString("id")), makeAST(EVar(paramsVar)) ]));
    // if is_map(inner), Map.get(inner, "id", idFromParams)
    var isMap = makeAST(ERemoteCall(makeAST(EVar("Kernel")), "is_map", [ inner ]));
    var idFromInner = makeAST(ERemoteCall(makeAST(EVar("Map")), "get", [ inner, makeAST(EString("id")), idFromParams ]));
    // else if is_binary(inner), Map.get(URI.decode_query(inner), "id", idFromParams) else idFromParams
    var isBin = makeAST(ERemoteCall(makeAST(EVar("Kernel")), "is_binary", [ inner ]));
    var decoded = makeAST(ERemoteCall(makeAST(EVar("URI")), "decode_query", [ inner ]));
    var idFromDecoded = makeAST(ERemoteCall(makeAST(EVar("Map")), "get", [ decoded, makeAST(EString("id")), idFromParams ]));
    var elseBranch = makeAST(EIf(isBin, idFromDecoded, idFromParams));
    var idRaw = makeAST(EIf(isMap, idFromInner, elseBranch));
    var isBinId = makeAST(ERemoteCall(makeAST(EVar("Kernel")), "is_binary", [ idRaw ]));
    var toInt = makeAST(ERemoteCall(makeAST(EVar("String")), "to_integer", [ idRaw ]));
    return makeAST(EIf(isBinId, toInt, idRaw));
  }
}

#end
