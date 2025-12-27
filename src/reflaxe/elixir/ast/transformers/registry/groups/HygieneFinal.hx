package reflaxe.elixir.ast.transformers.registry.groups;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HygieneFinal
 *
 * WHAT
 * - Ultra-late hygiene/safety/sweep passes extracted from the registry with no behavior change.
 * - Includes numeric-sentinel cleanup, assignment-chain simplifications, usage-driven binder fixes,
 *   late query binder handling, and small runtime-safe normalizations.
 *
 * WHY
 * - Keep the central registry readable by modularizing large late-stage cleanup logic while preserving order.
 * - Makes the deterministic registry order document easier to audit.
 *
 * HOW
 * - Returns the exact PassConfig list previously pushed inline, in the identical order.
 * - Some passes reference runAfter constraints that remain valid across groups; ordering is preserved
 *   by the registry’s stable topological sort.
 */
class HygieneFinal {
  public static function build():Array<ElixirASTTransformer.PassConfig> {
    var passes:Array<ElixirASTTransformer.PassConfig> = [];

    passes.push({
      name: "AccAliasLateRewrite",
      description: "Rewrite alias self-append to acc within any two-arg EFn (ultra-final safety)",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.AccAliasLateRewriteTransforms.transformPass
    });

    // Case binder hygiene
    passes.push({
      name: "CaseBinderRebindUnderscore",
      description: "In case arms, underscore binders that are immediately rebound before use",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.CaseBinderRebindUnderscoreTransforms.pass
    });

    // Pin existing bindings in case patterns to avoid shadowing
    passes.push({
      name: "CaseClausePinExistingBindings",
      description: "Pin variables in case clause patterns when matching existing in-scope bindings",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.CaseClausePinExistingBindingsTransforms.pass
    });

    // Normalize list concat into direct list literal for nested match patterns
    passes.push({
      name: "ConcatListLiteralNormalize",
      description: "Rewrite lhs = _ = [] ++ [expr] and lhs = [] ++ [expr] into lhs = [expr]",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.ConcatListLiteralNormalizeTransforms.pass
    });

    // Numeric sentinel and temp-nil cleanup
    passes.push({
      name: "DropStandaloneLiteralOne",
      description: "Drop stray 1/0/0.0 literals in blocks, do-blocks, EFn bodies (ultra-final)",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.DropStandaloneLiteralOneTransforms.dropPass
    });
    passes.push({
      name: "DropStandaloneVarRef",
      description: "Drop standalone var references in statement position inside blocks/do-blocks (ultra-final)",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.DropStandaloneVarRefTransforms.pass
    });
    passes.push({
      name: "DropTempNilAssign",
      description: "Drop thisN/_thisN = nil sentinel assignments",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.DropTempNilAssignTransforms.pass
    });

    // EFn and assignment-chain simplifications
    passes.push({
      name: "EFnTempChainSimplify",
      description: "Inside EFn, rewrite var=nil; var=expr; var → expr",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.EFnTempChainSimplifyTransforms.pass
    });
    passes.push({
      name: "TrailingTempReturnSimplify",
      description: "Replace trailing temp returns with the rhs expression",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.TrailingTempReturnSimplifyTransforms.pass
    });
    passes.push({
      name: "DefTrailingAssignedVarReturn",
      description: "Append trailing var when last statement is assignment to non-temp",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.DefTrailingAssignedVarReturnTransforms.pass
    });
    passes.push({
      name: "ChangesetChainCleanup",
      description: "Collapse changeset nested assigns cs/thisN → direct cs assign",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.ChangesetChainCleanupTransforms.pass
    });

    // Changeset return/binder repairs
    passes.push({
      name: "ChangesetEnsureReturn",
      description: "Ensure functions building Ecto.Changeset return last assigned var",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.ChangesetEnsureReturnTransforms.pass
    });
    passes.push({
      name: "ChangesetBareCsRepair",
      description: "Repair changeset/2 bodies reduced to bare cs by reconstructing change(p1, p2)",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.ChangesetBareCsRepairTransforms.pass
    });
    passes.push({
      name: "LateEnsureCsBinder",
      description: "Ensure `cs` binder exists by rewriting earliest cast/change producer to `cs = ...` (late)",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.LateEnsureCsBinderTransforms.pass
    });

    // Global temp/Repo helpers
    passes.push({
      name: "TempAssignFlattenGlobal",
      description: "Flatten temp alias chains globally: outer=(temp=expr) → outer=expr",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.TempAssignFlattenGlobalTransforms.pass
    });
    passes.push({
      name: "RepoGetBinderRepair",
      description: "Rewrite bodies that return an undeclared var v to Repo.get(schema(v), firstParam)",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.RepoGetBinderRepairTransforms.pass
    });
    passes.push({
      name: "BareGetterRepoGetRepair",
      description: "For bare-var function bodies in Repo modules, rewrite to Repo.get(:var, id)",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.BareGetterRepoGetRepairTransforms.pass
    });

    // Param hygiene
    passes.push({
      name: "DefParamUnusedUnderscoreSafe",
      description: "Underscore unused def parameters when truly unused (safe)",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.DefParamUnusedUnderscoreSafeTransforms.pass
    });
    passes.push({
      name: "ParamUnderscoreUsedRepair",
      description: "Rename `_name` to `name` for parameters used in function body (disabled for runtime stabilization)",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.ParamUnderscoreUsedRepairTransforms.pass
    });

    // App start helper
    passes.push({
      name: "ApplicationEnsureStartLink",
      description: "Ensure Application.start/2 appends Supervisor.start_link(children, opts) (ultra final)",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.ApplicationEnsureStartLinkTransforms.transformPass
    });

    // Wildcard and pinned var promotions
    passes.push({
      name: "WildcardPromoteByUndeclaredUse",
      description: "Final promotion of `_ = rhs` to binder by targeted usage (length/assign/DateTime)",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.WildcardPromoteByUndeclaredUseTransforms.pass
    });
    passes.push({
      name: "PinnedVarBinderPromote",
      description: "Promote `_ = <literal>` to `<name> = <literal>` when a unique ^(name) is used later",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.PinnedVarBinderPromoteTransforms.pass
    });
    passes.push({
      name: "EctoWherePinnedBinderRepair",
      description: "Repair wildcard literal binder before where/2 that pins its value later",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.EctoWherePinnedBinderRepairTransforms.pass
    });

    // Ultimate EFns and small global safety helpers
    passes.push({
      name: "EFnNumericSentinelCleanup",
      description: "Ultimate pass to remove 0/1/0.0 numeric sentinel statements inside EFns",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.EFnNumericSentinelCleanupTransforms.cleanupPass
    });
    passes.push({
      name: "SelfAssignCompression",
      description: "Ultimate replay: compress duplicated self-assignments x = x = expr to x = expr",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.BinderTransforms.selfAssignCompressionPass
    });
    passes.push({
      name: "DuplicateEffectfulCallPrune",
      description: "Remove immediately duplicated effectful calls prior to case on same call",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.DuplicateEffectfulCallPruneTransforms.pass
    });
    passes.push({
      name: "SafePubSubAliasInject",
      description: "Ultimate alias injection for Phoenix.SafePubSub as SafePubSub",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.SafePubSubAliasInjectTransforms.injectPass
    });
    passes.push({
      name: "SafePubSubConverterCapture",
      description: "Ensure parse_with_converter/2 receives a function capture (&mod.func/1)",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.SafePubSubConverterCaptureTransforms.pass
    });
    passes.push({
      name: "UnderscoreTempInlineDowncase",
      description: "Inline _tmp followed by String.downcase(_tmp) to String.downcase(rhs)",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.UnderscoreTempInlineDowncaseTransforms.pass,
      runAfter: ["LocalUnderscoreBinderPromotionWhenUsed_Final"]
    });
    // (Concat identity normalization folded into existing loop transforms; no extra pass here)
    passes.push({
      name: "DowncaseInlineFromPriorAssign_Final",
      description: "Inline prior assignments into String.downcase(var) and drop the assignment when safe",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.DowncaseInlineFromPriorAssignTransforms.pass,
      runAfter: ["UnderscoreTempInlineDowncase"]
    });

    // Absolute-final replay: underscore unused anonymous fn args.
    //
    // WHY
    // - Some late hygiene/promotions can adjust binder shapes in EFns. Re-running this check
    //   at the end guarantees we don't ship unused-arg warnings (WAE) after all rewrites.
    passes.push({
      name: "EFnUnusedArgUnderscore_Final",
      description: "Absolute-final: underscore unused EFn binders (Enum.reduce/map/each) after all rewrites",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.EFnUnusedArgUnderscoreTransforms.transformPass
    });

    // Reduce-result and reduce_while final sweeps must run late.
    //
    // WHY
    // - Some late passes (e.g. trailing-return simplifiers) can add new uses of variables after
    //   a reduce binding, which changes whether a binder is truly "unused".
    // - Running these earlier risks underscoring a state-carrying binder and breaking semantics.
    passes.push({
      name: "ReduceWhileSentinelCleanup_Final",
      description: "Late: drop numeric sentinel literals inside reduce_while bodies",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.ReduceWhileSentinelCleanupTransforms.transformPass
    });

    // Re-add NestedAssignCollapseGlobal as absolute-final cleanup
    passes.push({
      name: "NestedAssignCollapseGlobal_Final",
      description: "Absolute-final: collapse nested assignments outer=(inner=expr) → outer=expr across all nodes",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.NestedAssignCollapseGlobalTransforms.pass
    });

    // NOTE: FinalUnderscoreRepair is registered in ElixirASTPassRegistry.hx (outside fast_boot guard)
    // to ensure it runs even in fast_boot mode since it's a critical Phase 1.3 fix

    return passes;
  }
}
#end
