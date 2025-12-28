package reflaxe.elixir.ast.transformers.registry.groups;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * PhoenixAnnotations
 *
 * WHAT
 * - Phoenix/Ecto annotation-driven transforms (controller/router/schema/repo/etc.).
 *
 * WHY
 * - Keep registry modular while preserving exact order from the monolith.

 *
 * HOW
 * - Walk the ElixirAST with `ElixirASTTransformer.transformNode` and rewrite matching nodes.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class PhoenixAnnotations {
  public static function build():Array<ElixirASTTransformer.PassConfig> {
    var passes:Array<ElixirASTTransformer.PassConfig> = [];

    passes.push({
      name: "ControllerTransform",
      description: "Transform @:controller modules into Phoenix.Controller structure",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.AnnotationTransforms.controllerTransformPass
    });

    passes.push({
      name: "ControllerLocalUnusedUnderscore",
      description: "In Controller modules, underscore unused local binders introduced by intermediate chains",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.ControllerLocalUnusedUnderscoreTransforms.pass
    });

    passes.push({
      name: "RouterTransform",
      description: "Transform @:router modules into Phoenix.Router structure",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.AnnotationTransforms.routerTransformPass
    });

    passes.push({
      name: "SchemaTransform",
      description: "Transform @:schema modules into Ecto.Schema structure",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.AnnotationTransforms.schemaTransformPass
    });

    passes.push({
      name: "RepoTransform",
      description: "Transform @:repo modules into Ecto.Repo structure",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.AnnotationTransforms.repoTransformPass
    });

    passes.push({
      name: "PostgrexTypesTransform",
      description: "Transform @:postgrexTypes modules into Postgrex types definition",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.AnnotationTransforms.postgrexTypesTransformPass
    });

    passes.push({
      name: "DbTypesTransform",
      description: "Transform @:dbTypes modules into DB adapter types definition",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.AnnotationTransforms.dbTypesTransformPass
    });

    passes.push({
      name: "ApplicationTransform",
      description: "Transform @:application modules into OTP Application structure",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.AnnotationTransforms.applicationTransformPass
    });

    passes.push({
      name: "ExUnitTransform",
      description: "Transform @:exunit modules into ExUnit.Case test structure",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.AnnotationTransforms.exunitTransformPass
    });

    passes.push({
      name: "SupervisorTransform",
      description: "Preserve supervisor functions from dead code elimination",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.AnnotationTransforms.supervisorTransformPass
    });

    return passes;
  }
}
#end

