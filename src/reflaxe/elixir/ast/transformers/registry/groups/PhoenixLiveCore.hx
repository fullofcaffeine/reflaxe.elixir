package reflaxe.elixir.ast.transformers.registry.groups;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * PhoenixLiveCore
 *
 * WHAT
 * - Core Phoenix/LiveView transforms that sit early in the pipeline to align
 *   naming and structure (component imports, handle_event bridging, API mapping,
 *   and Ecto.Query require injection).
 *
 * WHY
 * - Keep the registry modular and readable without altering behavior.
 *
 * HOW
 * - Returns the exact PassConfig entries previously inlined in the registry,
 *   preserving order.
 */
class PhoenixLiveCore {
  public static function build():Array<ElixirASTTransformer.PassConfig> {
    var passes:Array<ElixirASTTransformer.PassConfig> = [];

    passes.push({
      name: "LiveViewCoreComponentsImport",
      description: "Add CoreComponents import for LiveView modules that use components",
      enabled: true,
      pass: ElixirASTTransformer.alias_liveViewCoreComponentsImportPass
    });

    passes.push({
      name: "PhoenixFunctionMapping",
      description: "Map custom function names to Phoenix conventions",
      enabled: true,
      pass: ElixirASTTransformer.alias_phoenixFunctionMappingPass
    });

    passes.push({
      name: "EctoQueryRequireInjection",
      description: "Add `require Ecto.Query` to modules that use Ecto.Query macros",
      enabled: true,
      pass: ElixirASTTransformer.alias_ectoQueryRequirePass
    });

    return passes;
  }
}
#end
