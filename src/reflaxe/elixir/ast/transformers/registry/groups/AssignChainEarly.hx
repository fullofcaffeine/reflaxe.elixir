package reflaxe.elixir.ast.transformers.registry.groups;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * AssignChainEarly
 *
 * WHAT
 * - EARLY assign-chain normalization passes that simplify chained assignments and
 *   fold simple RHS control-flow shapes before later rewrites.
 *
 * WHY
 * - Keep the registry small and readable without changing behavior or order.
 *
 * HOW
 * - Returns the exact pass list and order that previously lived inline in the registry.
 */
class AssignChainEarly {
  public static function build():Array<ElixirASTTransformer.PassConfig> {
    var passes:Array<ElixirASTTransformer.PassConfig> = [];

    passes.push({
      name: "AssignChainGenericSimplify_Early",
      description: "EARLY: split a = (b = rhs) into b = rhs; a = b (reduce_while bodies)",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.AssignChainGenericSimplifyTransforms.transformPass
    });
    passes.push({
      name: "AssignAliasIfPromote_Early",
      description: "EARLY: promote a=b; if cond(a) … else b -> a=if cond(b) …",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.AssignAliasIfPromoteTransforms.transformPass
    });
    passes.push({
      name: "ChainAssignIfPromote_Early",
      description: "EARLY: promote a=(b=rhs); if … else b → b=rhs; a=if … else b",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.ChainAssignIfPromoteTransforms.transformPass
    });
    passes.push({
      name: "AssignIfFoldInRhs_Early",
      description: "EARLY: fold a = (b=rhs; if … else b) into b=rhs; a=if … else b (statement contexts)",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.AssignIfFoldInRhsTransforms.transformPass
    });

    return passes;
  }
}
#end

