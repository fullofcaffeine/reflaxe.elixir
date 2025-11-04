package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ASTUtils;

/**
 * HandleEventValueVarNormalizeTransforms
 *
 * WHAT
 * - In def handle_event/3 bodies, rewrite Map.get(value, "…") to
 *   Map.get(params, "…") (or Map.get(_params, "…")) when no local
 *   binding for the variable name "value" exists in the function.
 *
 * WHY
 * - Some pipelines reference a payload variable named "value" in the
 *   body while the head binder is `params` or `_params`. When no local
 *   binding for "value" exists, Elixir compilation fails with
 *   "undefined variable value". This transform removes that mismatch
 *   without app-specific heuristics, purely by shape and scope.
 *
 * HOW
 * - Detect handle_event/3 definitions; collect declared locals from LHS
 *   of matches and patterns within the body. If "value" is not among
 *   them, traverse the body and rewrite ERremoteCall(Map, "get",
 *   [EVar("value"), key]) so that the first argument becomes the head
 *   payload binder (second def arg), preserving `_params` if present.
 * - Runs very late to catch near-final shapes and avoid being undone by
 *   subsequent passes. Strictly limited to the Map.get(value, …) shape.
 */
class HandleEventValueVarNormalizeTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body) if (isHandleEvent3(name, args)):
          var payloadVar = extractParamsVarName(args);
          var declared = new Map<String,Bool>();
          collectDecls(body, declared);
          if (!declared.exists("value")) {
            var nb = rewriteBody(body, payloadVar);
            makeASTWithMeta(EDef(name, args, guards, nb), n.metadata, n.pos);
          } else {
            n;
          }
        case EDefp(name2, args2, guards2, body2) if (isHandleEvent3(name2, args2)):
          var payloadVar2 = extractParamsVarName(args2);
          var declared2 = new Map<String,Bool>();
          collectDecls(body2, declared2);
          if (!declared2.exists("value")) {
            var nb2 = rewriteBody(body2, payloadVar2);
            makeASTWithMeta(EDefp(name2, args2, guards2, nb2), n.metadata, n.pos);
          } else {
            n;
          }
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
     * - Traverses a handle_event/3 body and replaces Map.get(value, "…") with
     *   Map.get(<payloadVar>, "…") when no local binding named `value` exists.
     *
     * WHY
     * - Prevents "undefined variable value" compile errors in generated Elixir
     *   when earlier passes or bridge steps referenced a non-existent `value`.
     *
     * HOW
     * - Matches ERemoteCall(Map.get, [EVar("value"), key]) and rewrites the first
     *   argument to the actual head binder (`payloadVar` is either `params` or
     *   `_params`). Also applies a conservative ERaw textual patch for rare raw
     *   segments that contain the same shape.
     *
     * DEBUG
     * - The following Sys.println is wrapped in `#if debug_handle_event_value` so
     *   it only logs when you opt in:
     *     npx haxe build.hxml -D debug_handle_event_value
     *   It runs in the compiler (macro) process, never in generated Elixir.
     *
     * EXAMPLE
     *   Before: Map.get(value, "id")
     *   After:  Map.get(params, "id")   // or _params depending on head binder
     */
    return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case ERemoteCall({def: EVar("Map")}, "get", a) if (a != null && a.length == 2):
          switch (a[0].def) {
            case EVar(v) if (v == "value"):
              var newArgs = [ makeAST(EVar(payloadVar)), a[1] ];
              #if debug_handle_event_value
              #if sys Sys.println('[HandleEventValueVarNormalize] Map.get(value, …) → Map.get(' + payloadVar + ', …)'); #end
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
              #if sys Sys.println('[HandleEventValueVarNormalize] call-form Map.get(value, …) → Map.get(' + payloadVar + ', …)'); #end
              #end
              makeASTWithMeta(ECall(target, funcName, newArgs2), x.metadata, x.pos);
            default: x;
          } else x;
        case ERaw(code) if (code != null && (code.indexOf("Map.get(value,") != -1)):
          try {
            var replaced = code;
            // Conservative textual patch inside raw segments
            replaced = StringTools.replace(replaced, "Map.get(value,", 'Map.get(' + payloadVar + ',');
            if (replaced != code) {
              #if debug_handle_event_value
              #if sys Sys.println('[HandleEventValueVarNormalize] ERaw: Map.get(value, …) → Map.get(' + payloadVar + ', …)'); #end
              #end
              makeASTWithMeta(ERaw(replaced), x.metadata, x.pos);
            } else {
              x;
            }
          } catch (_:Dynamic) {
            x;
          }
        default: x;
      }
    });
  }

  static function collectDecls(ast: ElixirAST, out: Map<String,Bool>): Void {
    ASTUtils.walk(ast, function(n: ElixirAST) {
      if (n == null || n.def == null) return;
      switch (n.def) {
        case EMatch(p, _): collectPattern(p, out);
        case EBinary(Match, l, _): collectLhs(l, out);
        case ECase(_, cs): for (c in cs) collectPattern(c.pattern, out);
        default:
      }
    });
  }

  static function collectPattern(p: EPattern, out: Map<String,Bool>): Void {
    switch (p) {
      case PVar(n): out.set(n, true);
      case PTuple(es) | PList(es): for (e in es) collectPattern(e, out);
      case PCons(h,t): collectPattern(h, out); collectPattern(t, out);
      case PMap(kvs): for (kv in kvs) collectPattern(kv.value, out);
      case PStruct(_, fs): for (f in fs) collectPattern(f.value, out);
      case PPin(inner): collectPattern(inner, out);
      default:
    }
  }

  static function collectLhs(lhs: ElixirAST, out: Map<String,Bool>): Void {
    switch (lhs.def) {
      case EVar(n): out.set(n, true);
      case EBinary(Match, l2, _): collectLhs(l2, out);
      default:
    }
  }
}

#end
