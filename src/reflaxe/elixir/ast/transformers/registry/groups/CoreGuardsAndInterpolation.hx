package reflaxe.elixir.ast.transformers.registry.groups;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * CoreGuardsAndInterpolation
 *
 * WHAT
 * - Contiguous prelude of guard normalization and string interpolation passes, extracted verbatim.
 *
 * WHY
 * - Reduce registry file size and improve readability without behavior change.
 *
 * HOW
 * - Returns the same PassConfig entries in the same order as previously inlined.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class CoreGuardsAndInterpolation {
  public static function build():Array<ElixirASTTransformer.PassConfig> {
    var passes:Array<ElixirASTTransformer.PassConfig> = [];

    passes.push({
      name: "CaseListGuardToCons",
      description: "Rewrite [] with non-empty guard → [head|tail] with repaired guard",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.CaseListGuardToConsTransforms.pass
    });
    passes.push({
      name: "CaseGuardFreeVarToScrutinee",
      description: "Rewrite guard refs to clause-local free vars → scrutinee var",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.CaseGuardFreeVarToScrutineeTransforms.pass
    });
    passes.push({
      name: "CaseEmptyListGuardNormalize",
      description: "Rewrite [] guards implying non-empty → [first|rest] with repaired guard",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.CaseEmptyListGuardNormalizeTransforms.pass
    });
    passes.push({
      name: "ListGuardIndexToHead",
      description: "Rewrite guards: list[0] → head; length(list) > 1 → tail != []",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.ListGuardIndexToHeadTransforms.pass
    });
    passes.push({
      name: "FunctionArgBlockToIIFE_Pre",
      description: "Wrap multi-statement EBlock arguments in (fn -> ... end).() before interpolation",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.FunctionArgBlockToIIFETransforms.pass
    });
    passes.push({
      name: "FinalLocalReferenceAlign_PreInterpolation",
      description: "Map refs to declared locals (name->_name, nameN->name, camel->snake, updated->ok_*) prior to interpolation",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.FinalLocalReferenceAlignTransforms.pass
    });
    passes.push({
      name: "StringInterpolation",
      description: "Convert string concatenation to idiomatic string interpolation",
      enabled: true,
      pass: reflaxe.elixir.ast.ElixirASTTransformer.alias_stringInterpolationPass
    });
    passes.push({
      name: "InterpolateJoinArgSanitize",
      description: "Wrap Enum.join first arg as IIFE inside interpolation when it contains statements",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.InterpolateJoinArgSanitizeTransforms.pass
    });
    passes.push({
      name: "InterpolateIIFEWrap",
      description: "Force-wrap all #{...} bodies in an IIFE to ensure a single valid expression",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.InterpolateIIFEWrapTransforms.pass
    });

    return passes;
  }
}
#end
