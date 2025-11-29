package reflaxe.elixir.ast.transformers.registry.groups;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HeexMain
 *
 * WHAT
 * - Main HEEx/HXX transforms executed after interpolation/Prelude, including
 *   string→~H conversion, quote normalizations, assigns handling, and required imports.
 *
 * WHY
 * - Modularize registry with no behavior change; preserve exact ordering.
 */
class HeexMain {
  public static function build():Array<ElixirASTTransformer.PassConfig> {
    var passes:Array<ElixirASTTransformer.PassConfig> = [];

    passes.push({
      name: "HeexStringReturnToSigil",
      description: "Rewrite EDef/EDefp bodies with final HTML strings to ~H sigils",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.HeexStringReturnToSigilTransforms.transformPass
    });

    passes.push({
      name: "HeexControlTagTransforms",
      description: "Rewrite HXX-style <if>/<else> control tags in ~H content to HEEx blocks",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.HeexControlTagTransforms.transformPass
    });

    passes.push({
      name: "HeexStripToStringInSigils",
      description: "Remove trailing .to_string() in <%= ... %> within ~H",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.HeexStripToStringInSigilsTransforms.transformPass
    });

    passes.push({
      name: "HeexSimplifyIIFEInInterpolations",
      description: "Rewrite <%= (fn -> expr end).() %> → <%= expr %> inside ~H",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.HeexSimplifyIIFEInInterpolations.transformPass
    });

    passes.push({
      name: "WebRemoteCallModuleQualification",
      description: "Rewrite Foo.bar(...) → AppWeb.Foo.bar(...) inside Web modules",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.WebRemoteCallModuleQualificationTransforms.pass
    });

    passes.push({
      name: "HeexAssignsParamRename",
      description: "Rename _assigns → assigns in functions that contain ~H",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.HeexAssignsParamRenameTransforms.transformPass
    });

    passes.push({
      name: "HeexVariableRawWrap",
      description: "Inside ~H, rewrite <%= var %> to raw(var) when var was bound from ~H or HTML string",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.HeexVariableRawWrapTransforms.transformPass
    });

    passes.push({
      name: "PhoenixComponentImport",
      description: "Add Phoenix.Component import when ~H sigil is used (unless LiveView already includes it)",
      enabled: true,
      pass: ElixirASTTransformer.alias_phoenixComponentImportPass
    });

    passes.push({
      name: "HeexRenderHelperCallWrap",
      description: "Wrap <%= render_* %> calls inside ~H with Phoenix.HTML.raw(...) (transitional safety)",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.HeexRenderHelperCallWrapTransforms.transformPass
    });

    passes.push({
      name: "HeexAssignsTypeLinter",
      description: "Validate @assigns fields and literal comparisons in ~H against the Haxe typedef",
      enabled: #if fast_boot false #else true #end,
      pass: reflaxe.elixir.ast.transformers.HeexAssignsTypeLinterTransforms.transformPass,
      contextualPass: reflaxe.elixir.ast.transformers.HeexAssignsTypeLinterTransforms.contextualPass
    });

    passes.push({
      name: "HeexEnsureAssignsForNestedSigils",
      description: "Wrap functions containing ~H without assigns param with assigns = %{}",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.HeexEnsureAssignsForNestedSigilsTransforms.transformPass
    });

    return passes;
  }
}
#end
