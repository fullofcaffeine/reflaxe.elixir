package reflaxe.elixir.ast.transformers.registry.groups;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * CollectionsAndLoops
 *
 * WHAT
 * - Loop and collection passes (unrolled loop repair, iterator transforms, map set rewrite,
 *   comprehension conversion, list effect lifting, optional for→Enum.each rewrite).
 *
 * WHY
 * - Modularize registry without behavior change; preserve order.
 */
class CollectionsAndLoops {
  public static function build():Array<ElixirASTTransformer.PassConfig> {
    var passes:Array<ElixirASTTransformer.PassConfig> = [];

    passes.push({
      name: "UnrolledLoopTransform",
      description: "Transform unrolled loops (sequential statements) back to Enum.each",
      enabled: #if no_traces false #else true #end,
      pass: reflaxe.elixir.ast.transformers.LoopTransforms.unrolledLoopTransformPass
    });

    passes.push({
      name: "MapIteratorTransform",
      description: "Transform Map iterator patterns from g.next() to idiomatic Enum operations",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.MapAndCollectionTransforms.mapIteratorTransformPass
    });

    passes.push({
      name: "MapSetRewrite",
      description: "Rewrite var.set(key, value) to var = Map.put(var, :key, value)",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.MapAndCollectionTransforms.mapSetRewritePass
    });

    #if !disable_comprehension_conversion
    passes.push({
      name: "ComprehensionConversion",
      description: "Convert imperative loops to comprehensions",
      enabled: true,
      pass: ElixirASTTransformer.alias_comprehensionConversionPass
    });
    #end

    passes.push({
      name: "ListEffectLifting",
      description: "Lift side-effecting expressions out of list literals",
      enabled: true,
      pass: ElixirASTTransformer.alias_listEffectLiftingPass
    });

    passes.push({
      name: "ForToEnumEachSideEffect",
      description: "Rewrite EFor with side-effect body to Enum.each(collection, fn -> body end)",
      enabled: false,
      pass: reflaxe.elixir.ast.transformers.ForToEnumEachSideEffectTransforms.pass
    });

    return passes;
  }
}
#end
