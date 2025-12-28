package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HandleEventToggleKeyExtractFinalTransforms
 *
 * WHAT
 * - In handle_event("toggle_*", params, socket) wrappers, replace helper calls that
 *   pass the entire `params` map as first argument with a specific key extraction
 *   from params using the suffix after "toggle_" as the key.
 *
 * WHY
 * - Generic ultra-final repair to avoid passing the whole params map to helpers
 *   that expect a concrete value (e.g., toggle_tag_filter expects a tag string).
 *   This is shape-based and does not depend on app-specific module names.
 *
 * HOW
 * - Detect def handle_event("toggle_...", params, socket) do <body> end
 * - Compute key = suffix after "toggle_" (e.g., "tag")
 * - Within the body, rewrite any ECall/ERemoteCall whose first arg is the
 *   `params` var to use Map.get(params, key) instead.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class HandleEventToggleKeyExtractFinalTransforms {
  public static function transformPass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body) if (isToggleHandler(name, args)):
          var paramVar = secondArgVar(args);
          var key = toggleKey(args);
          var rewritten = rewriteBody(body, paramVar, key);
          makeASTWithMeta(EDef(name, args, guards, rewritten), n.metadata, n.pos);
        case EDefp(name, args, guards, body) if (isToggleHandler(name, args)):
          var paramVar2 = secondArgVar(args);
          var key2 = toggleKey(args);
          var rewritten2 = rewriteBody(body, paramVar2, key2);
          makeASTWithMeta(EDefp(name, args, guards, rewritten2), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static inline function isToggleHandler(name:String, args:Array<EPattern>):Bool {
    if (name != "handle_event" || args == null || args.length != 3) return false;
    return switch (args[0]) { case PLiteral({def: EString(ev)}): StringTools.startsWith(ev, "toggle_"); default: false; };
  }

  static inline function secondArgVar(args:Array<EPattern>):String {
    return switch (args[1]) { case PVar(n): n; default: "params"; }
  }

  static inline function toggleKey(args:Array<EPattern>):String {
    return switch (args[0]) { case PLiteral({def: EString(ev)}): ev.substr("toggle_".length); default: "id"; }
  }

  static function mapGet(paramVar:String, key:String): ElixirAST {
    return makeAST(ERemoteCall(makeAST(EVar("Map")), "get", [ makeAST(EVar(paramVar)), makeAST(EString(key)) ]));
  }

  static function rewriteBody(body: ElixirAST, paramVar:String, key:String): ElixirAST {
    return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case ECall(target, fname, args) if (args != null && args.length >= 1):
          switch (args[0].def) { case EVar(v) if (v == paramVar):
            var newArgs = args.copy(); newArgs[0] = mapGet(paramVar, key);
            makeASTWithMeta(ECall(target, fname, newArgs), x.metadata, x.pos);
          default: x; }
        case ERemoteCall(mod, fname, args) if (args != null && args.length >= 1):
          switch (args[0].def) { case EVar(v2) if (v2 == paramVar):
            var newArgs2 = args.copy(); newArgs2[0] = mapGet(paramVar, key);
            makeASTWithMeta(ERemoteCall(mod, fname, newArgs2), x.metadata, x.pos);
          default: x; }
        default:
          x;
      }
    });
  }
}

#end

