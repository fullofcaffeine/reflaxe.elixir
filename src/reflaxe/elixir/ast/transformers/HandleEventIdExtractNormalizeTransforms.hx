package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HandleEventIdExtractNormalizeTransforms
 *
 * WHAT
 * - Normalizes the common id-extraction pattern inside handle_event/3 wrappers:
 *     id = if Kernel.is_binary(Map.get(value, "id")) do
 *             String.to_integer(Map.get(value, "id"))
 *           else
 *             Map.get(paramsVar, "id")
 *           end
 *   so that both branches read from the same `paramsVar` (params or _params)
 *   instead of the undefined `value` identifier.
 *
 * WHY
 * - Some upstream repairs can accidentally introduce `Map.get(value, "id")` in
 *   the true-branch/condition while the else branch correctly uses paramsVar.
 *   This transform removes the mismatch without name heuristics.
 */
class HandleEventIdExtractNormalizeTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body) if (isHandleEvent3(name, args)):
          var nb = normalizeIdExtract(body);
          makeASTWithMeta(EDef(name, args, guards, nb), n.metadata, n.pos);
        case EDefp(name2, args2, guards2, body2) if (isHandleEvent3(name2, args2)):
          var nb2 = normalizeIdExtract(body2);
          makeASTWithMeta(EDefp(name2, args2, guards2, nb2), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static inline function isHandleEvent3(name:String, args:Array<EPattern>):Bool {
    if (name != "handle_event" || args == null || args.length != 3) return false;
    return switch (args[0]) { case PLiteral({def: EString(_)}): true; default: false; }
  }

  static inline function isMapGetId(expr: ElixirAST): Null<ElixirAST> {
    // returns the receiver (first arg) when expression is Map.get(receiver, "id")
    return switch (expr.def) {
      case ERemoteCall(mod, "get", a) if (a != null && a.length >= 2):
        switch (mod.def) { case EVar(m) if (m == "Map"): switch (a[1].def) { case EString(s) if (s == "id"): a[0]; default: null; } default: null; }
      case ECall(target, funcName, a2) if (funcName == "get" && a2 != null && a2.length >= 2):
        switch (target.def) { case EVar(m2) if (m2 == "Map"): switch (a2[1].def) { case EString(s2) if (s2 == "id"): a2[0]; default: null; } default: null; }
      default: null;
    }
  }

  static function normalizeIdExtract(body: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case EIf(cond, thenE, elseE):
          var recvCond = isKernelIsBinaryOnMapGetId(cond);
          var recvThen = isStringToIntegerOnMapGetId(thenE);
          var recvElse = isMapGetId(elseE);
          if (recvCond != null && recvThen != null && recvElse != null) {
            // Force both cond and then to use recvElse
            var fixedCond = replaceMapGetReceiver(cond, recvElse);
            var fixedThen = replaceMapGetReceiver(thenE, recvElse);
            makeASTWithMeta(EIf(fixedCond, fixedThen, elseE), x.metadata, x.pos);
          } else x;
        default: x;
      }
    });
  }

  static inline function isKernelIsBinaryOnMapGetId(e: ElixirAST): Null<ElixirAST> {
    // returns the Map.get(receiver, "id") receiver when cond matches
    return switch (e.def) {
      case ERemoteCall({def: EVar("Kernel")}, "is_binary", [arg]) | ECall({def: EVar("Kernel")}, "is_binary", [arg]):
        isMapGetId(arg);
      default: null;
    }
  }

  static inline function isStringToIntegerOnMapGetId(e: ElixirAST): Null<ElixirAST> {
    // returns the Map.get(receiver, "id") receiver when then matches
    return switch (e.def) {
      case ERemoteCall({def: EVar("String")}, "to_integer", [arg]) | ECall({def: EVar("String")}, "to_integer", [arg]):
        isMapGetId(arg);
      default: null;
    }
  }

  static function replaceMapGetReceiver(tree: ElixirAST, newRecv: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(tree, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case ERemoteCall({def: EVar("Map")}, "get", a) if (a != null && a.length >= 2):
          switch (a[1].def) {
            case EString(s) if (s == "id"): makeASTWithMeta(ERemoteCall(makeAST(EVar("Map")), "get", [ newRecv, a[1] ]), n.metadata, n.pos);
            default: n;
          }
        case ECall(target, "get", a2) if (a2 != null && a2.length >= 2):
          switch (target.def) {
            case EVar(m) if (m == "Map"): switch (a2[1].def) {
              case EString(s2) if (s2 == "id"): makeASTWithMeta(ECall(target, "get", [ newRecv, a2[1] ]), n.metadata, n.pos);
              default: n;
            }
            default: n;
          }
        default: n;
      }
    });
  }
}

#end
