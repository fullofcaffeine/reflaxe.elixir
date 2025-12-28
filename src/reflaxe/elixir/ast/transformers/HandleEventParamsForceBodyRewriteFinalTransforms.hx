package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HandleEventParamsForceBodyRewriteFinalTransforms
 *
 * WHAT
 * - Absolute safety net that rewrites any `_params` occurrences inside
 *   `def handle_event/3` bodies to `params` regardless of head binder state.

 *
 * WHY
 * - Avoid warnings and keep generated Elixir output idiomatic.

 *
 * HOW
 * - Walk the ElixirAST with `ElixirASTTransformer.transformNode` and rewrite matching nodes.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class HandleEventParamsForceBodyRewriteFinalTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body) if (name == "handle_event" && args != null && args.length == 3):
          var nb = rewrite(body);
          makeASTWithMeta(EDef(name, args, guards, nb), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function rewrite(body: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(body, function(x: ElixirAST): ElixirAST {
      return switch (x.def) {
        case EVar(v) if (v == "_params"): makeASTWithMeta(EVar("params"), x.metadata, x.pos);
        default: x;
      }
    });
  }
}

#end

