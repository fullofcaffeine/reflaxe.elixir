package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HandleEventParamsValueRewriteTransforms
 *
 * WHAT
 * - In `def handle_event/3`, rewrites common arg forwarding to use values
 *   directly from `params` map to avoid mismatches with ephemeral locals.
 *
 * HOW
 * - `SafeAssigns.set_filter(socket, filter)` → `SafeAssigns.set_filter(socket, Map.get(params, "filter"))`
 * - `SafeAssigns.set_search_query(socket, query)` → `SafeAssigns.set_search_query(socket, Map.get(params, "query"))`
 */
class HandleEventParamsValueRewriteTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body) if (name == "handle_event" && args != null && args.length == 3):
          var nb = rewriteInBody(body);
          makeASTWithMeta(EDef(name, args, guards, nb), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function rewriteInBody(body: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case ERemoteCall({def: EVar("SafeAssigns")}, fun, args) if (fun == "set_filter" && args != null && args.length == 2):
          var repl = makeASTWithMeta(ERemoteCall(makeAST(EVar("Map")), "get", [makeAST(EVar("params")), makeAST(EString("filter"))]), x.metadata, x.pos);
          makeASTWithMeta(ERemoteCall(makeAST(EVar("SafeAssigns")), fun, [args[0], repl]), x.metadata, x.pos);
        case ERemoteCall({def: EVar("SafeAssigns")}, fun2, args2) if (fun2 == "set_search_query" && args2 != null && args2.length == 2):
          var repl2 = makeASTWithMeta(ERemoteCall(makeAST(EVar("Map")), "get", [makeAST(EVar("params")), makeAST(EString("query"))]), x.metadata, x.pos);
          makeASTWithMeta(ERemoteCall(makeAST(EVar("SafeAssigns")), fun2, [args2[0], repl2]), x.metadata, x.pos);
        default: x;
      }
    });
  }
}

#end

