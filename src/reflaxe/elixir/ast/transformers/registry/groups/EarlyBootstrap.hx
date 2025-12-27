package reflaxe.elixir.ast.transformers.registry.groups;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTPrinter;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * EarlyBootstrap
 *
 * WHAT
 * - First-wave, order-preserving pass bundle that must execute at the very start
 *   of the transformation pipeline. These passes normalize identifiers, inline
 *   artifacts and critical shapes so later phases can rely on consistent AST.
 *
 * WHY
 * - Keep ElixirASTPassRegistry maintainable by modularizing into domain/phase
 *   groups without changing behavior or order.
 *
 * HOW
 * - Returns the exact same PassConfig list (and order) that previously lived
 *   at the top of ElixirASTPassRegistry.getEnabledPasses(). No behavior change.
 */
class EarlyBootstrap {
  public static function build():Array<ElixirASTTransformer.PassConfig> {
    var passes:Array<ElixirASTTransformer.PassConfig> = [];

    // Identity pass (always first - ensures pass-through functionality)
    passes.push({
      name: "Identity",
      description: "Pass-through transformation (no changes)",
      enabled: true,
      pass: ElixirASTTransformer.alias_identityPass
    });

    // Early-return reconstruction: convert `if cond return x; rest` into `if cond do x else rest end`
    passes.push({
      name: "EarlyReturnIfElse",
      description: "Preserve Haxe early-return semantics by moving remainder-of-block into if/else branches",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.EarlyReturnIfElseTransforms.pass
    });

    // Resolve clause locals pass (must run very early to fix variable references)
    passes.push({
      name: "ResolveClauseLocals",
      description: "Resolve variable references in case clauses using varIdToName metadata",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.TempVariableTransforms.resolveClauseLocalsPass
    });

    // Normalize camelCase locals/patterns to snake_case (prevents casing drift before binder alignment)
    passes.push({
      name: "LocalVarNameNormalize",
      description: "Normalize local variable and pattern binder names to snake_case",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.LocalVarNameNormalizeTransforms.pass
    });

    // Remove redundant enum extraction pass (must run early to fix pattern matching)
    passes.push({
      name: "RemoveRedundantEnumExtraction",
      description: "Remove redundant elem() calls after pattern extraction in case clauses",
      enabled: true,
      pass: ElixirASTTransformer.alias_removeRedundantEnumExtractionPass
    });

    // Align {:ok, binder} names to meaningful locals used in body (e.g., `todo`)
    passes.push({
      name: "CaseOkBinderAlign",
      description: "Rename {:ok, var} binder to match body local (todo) and rewrite body refs",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.CaseOkBinderAlignTransforms.transformPass
    });

    // Normalize {:ok, ok_value} → {:ok, value} and fix body references; prevent ok_value leaks
    passes.push({
      name: "ResultOkBinderNormalize",
      description: "Normalize {:ok, binder} to avoid ok_value leaks; align body to binder",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.ResultOkBinderNormalizeTransforms.pass
    });

    // Replay near the end to catch late-introduced ok_value in nested closures
    passes.push({
      name: "ResultOkBinderNormalize_Replay_Ultimate",
      description: "Ultimate replay of {:ok, binder} normalization inside def/defp and EFn",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.ResultOkBinderNormalizeTransforms.pass,
      runAfter: ["FinalLocalReferenceAlign"]
    });

    // Throw statement transformation (must run early to fix complex expressions)
    passes.push({
      name: "ThrowStatementTransform",
      description: "Transform complex throw expressions to avoid syntax errors",
      enabled: true,
      pass: ElixirASTTransformer.alias_throwStatementTransformPass
    });

    // Inline expansion fixes (should run very early to fix AST structure)
    passes.push({
      name: "InlineMethodCallCombiner",
      description: "Combine split inline expansion patterns from stdlib",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.InlineExpansionTransforms.inlineMethodCallCombinerPass
    });

    // Extract inline assignments from tuple constructors (must run early)
    passes.push({
      name: "ExtractTupleInlineAssignments",
      description: "Extract inline assignments from tuple constructors to fix syntax errors",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.InlineExpansionTransforms.extractTupleInlineAssignmentsPass
    });

    // Extract inline assignments from map/keyword/struct literal values (must run early)
    passes.push({
      name: "ExtractLiteralValueInlineAssignments",
      description: "Hoist inline assignments out of map/keyword/struct literal values to preceding block",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.InlineExpansionTransforms.extractLiteralValueInlineAssignmentsPass
    });

    // Function reference transformation (must run early to add capture operators)
    passes.push({
      name: "FunctionReferenceTransform",
      description: "Transform function references to use capture operator (&Module.func/arity)",
      enabled: true,
      pass: ElixirASTTransformer.alias_functionReferenceTransformPass
    });

    // Normalize def/defp parameter names from camelCase to snake_case and rewrite body refs
    passes.push({
      name: "DefParamCamelToSnake",
      description: "Rename function parameters camelCase→snake_case and update body references",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.DefParamCamelToSnakeTransforms.transformPass
    });

    // Normalize local declarations camelCase→snake_case and rewrite references
    passes.push({
      name: "LocalCamelToSnakeDecl",
      description: "Rename local EMatch/EVar declarations from camelCase to snake_case and update refs",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.LocalCamelToSnakeDeclTransforms.transformPass
    });

    // Collapse simple temp-binding blocks in expression contexts
    passes.push({
      name: "InlineTempBindingInExpr",
      description: "Collapse EBlock([tmp = exprA, exprB(tmp)]) to exprB(exprA) in expression positions",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.TempVariableTransforms.inlineTempBindingInExprPass
    });

    return passes;
  }
}
#end
