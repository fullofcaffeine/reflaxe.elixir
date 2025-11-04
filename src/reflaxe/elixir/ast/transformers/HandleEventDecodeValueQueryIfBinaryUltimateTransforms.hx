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
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body) if (isHandleEvent3(name, args)):
          var paramsVar = secondArg(args);
          var nb = rewrite(body, paramsVar);
          makeASTWithMeta(EDef(name, args, guards, nb), n.metadata, n.pos);
        case EDefp(name2, args2, guards2, body2) if (isHandleEvent3(name2, args2)):
          var paramsVar2 = secondArg(args2);
          var nb2 = rewrite(body2, paramsVar2);
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

  static function rewrite(body: ElixirAST, paramsVar:String): ElixirAST {
    return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case ECall(target, fname, args) if (args != null && args.length > 0):
          var newArgs = mapArgs(args, paramsVar);
          if (newArgs == null) x else makeASTWithMeta(ECall(target, fname, newArgs), x.metadata, x.pos);
        case ERemoteCall(target2, fname2, args2) if (args2 != null && args2.length > 0):
          var newArgs2 = mapArgs(args2, paramsVar);
          if (newArgs2 == null) x else makeASTWithMeta(ERemoteCall(target2, fname2, newArgs2), x.metadata, x.pos);
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
      case ECall(tgt, "get", a2):
        var isMap = switch (tgt.def) { case EVar(m): m == "Map"; default: false; };
        if (isMap && a2 != null && a2.length >= 2) {
          if (isParamsVar(a2[0], paramsVar) && isValueKey(a2[1])) inner = makeAST(ECall(tgt, "get", a2));
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
