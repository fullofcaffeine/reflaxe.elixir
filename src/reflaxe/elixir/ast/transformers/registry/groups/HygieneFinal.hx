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

    passes.push({
      name: "ReduceStrictSelfAppendRewrite",
      description: "Rebuild reduce body to acc concat when alias self-append detected (structural)",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.ReduceStrictSelfAppendRewriteTransforms.transformPass
    });

    // ERaw reduce canonicalization
    passes.push({
      name: "ReduceERawAliasCanonicalize",
      description: "Canonicalize alias concat and binder alias inside ERaw Enum.reduce bodies (ultra-final)",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.ReduceERawAliasCanonicalizeTransforms.transformPass
    });

    // Case binder hygiene
    passes.push({
      name: "CaseBinderRebindUnderscore",
      description: "In case arms, underscore binders that are immediately rebound before use",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.CaseBinderRebindUnderscoreTransforms.pass
    });

    // Numeric sentinel and temp-nil cleanup
    passes.push({
      name: "DropStandaloneLiteralOne",
      description: "Drop stray 1/0/0.0 literals in blocks, do-blocks, EFn bodies (ultra-final)",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.DropStandaloneLiteralOneTransforms.dropPass
    });
    passes.push({
      name: "DropTempNilAssign",
      description: "Drop thisN/_thisN = nil sentinel assignments",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.DropTempNilAssignTransforms.pass
    });
    passes.push({
      name: "ReduceResultUnusedUnderscore",
      description: "Underscore binders in reduce/reduce_while result match when unused later in block",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.ReduceResultUnusedUnderscoreTransforms.transformPass
    });
    passes.push({
      name: "ReduceWhileSentinelCleanup",
      description: "Final sweep: drop numeric sentinel literals inside reduce_while bodies",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.ReduceWhileSentinelCleanupTransforms.transformPass
    });
    passes.push({
      name: "DropTempNilAssign",
      description: "Last guard: drop thisN/_thisN = nil sentinels if any got reintroduced",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.DropTempNilAssignTransforms.pass
    });

    // Late scoped underscore (disabled; keep for parity)
    passes.push({
      name: "LocalAssignUnderscoreLate",
      description: "Underscore local assigns when unused later; also nested inner assigns",
      enabled: false,
      pass: reflaxe.elixir.ast.transformers.LocalAssignUnderscoreLateTransforms.pass
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
      name: "NestedAssignCollapseGlobal",
      description: "Collapse nested chain assignments outer=(inner=expr) → outer=expr",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.NestedAssignCollapseGlobalTransforms.pass
    });
    passes.push({
      name: "DefTrailingAssignedVarReturn",
      description: "Append trailing var when last statement is assignment to non-temp",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.DefTrailingAssignedVarReturnTransforms.pass
    });
    passes.push({
      name: "EctoChangesetReturnFix",
      description: "(disabled) Legacy fix that appended cs; superseded by ChangesetEnsureReturn",
      enabled: false,
      pass: reflaxe.elixir.ast.transformers.EctoChangesetReturnFixTransforms.pass
    });
    passes.push({
      name: "ChangesetChainCleanup",
      description: "Collapse changeset nested assigns cs/thisN → direct cs assign",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.ChangesetChainCleanupTransforms.pass
    });

    // Late query binder handling
    passes.push({
      name: "QueryBinderSynthesisLate",
      description: "Insert `query = String.downcase(search_query)` before Enum.filter when predicate uses `query` and no prior binder exists",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.QueryBinderSynthesisLateTransforms.transformPass
    });
    passes.push({
      name: "FilterPredicateInlineQuery",
      description: "Inline `query` to `String.downcase(search_query)` inside Enum.filter predicates",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.FilterPredicateInlineQueryTransforms.transformPass
    });
    passes.push({
      name: "FilterPredicateQueryInline_UltraFinal",
      description: "Ultra-final safeguard to inline `query` in Enum.filter predicates when only search_query exists",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.FilterPredicateQueryInlineUltraFinalTransforms.pass
    });
    passes.push({
      name: "QueryBinderSynthesis_UltraFinal",
      description: "Ultra-final: insert `query = String.downcase(search_query)` before Enum.filter when predicate uses `query` and no prior binder exists",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.QueryBinderSynthesisUltraFinalTransforms.pass
    });

    // Debug (kept enabled as in registry)
    passes.push({
      name: "DebugCaseBinderUndefScan",
      description: "Debug-only: log binder and undefined locals in case clauses",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.DebugCaseBinderUndefScanTransforms.pass
    });

    // Optional discards
    passes.push({
      name: "BlockUnusedAssignmentDiscard",
      description: "Rewrite var = expr to _ = expr in function bodies when var unused later",
      enabled: false,
      pass: reflaxe.elixir.ast.transformers.BlockUnusedAssignmentDiscardTransforms.pass
    });

    // Changeset return/binder repairs
    passes.push({
      name: "DropUnusedDowncaseWildcardAssign",
      description: "Drop `_ = String.downcase(search_query)` in blocks (pure, unused)",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.DropUnusedDowncaseWildcardAssignTransforms.transformPass
    });
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
      name: "DefParamUnusedUnderscoreGlobalSafe",
      description: "Globally underscore unused function params when provably unused (disabled)",
      enabled: false,
      pass: reflaxe.elixir.ast.transformers.DefParamUnusedUnderscoreGlobalSafeTransforms.pass
    });
    passes.push({
      name: "ParamUnderscoreUsedRepair",
      description: "Rename `_name` to `name` for parameters used in function body (disabled for runtime stabilization)",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.ParamUnderscoreUsedRepairTransforms.pass
    });
    passes.push({
      name: "ChangesetParamUsedRepair",
      description: "In changeset/2, rename underscored params to base names when body uses base (disabled for stabilization)",
      enabled: false,
      pass: reflaxe.elixir.ast.transformers.ChangesetParamUsedRepairTransforms.pass
    });
    passes.push({
      name: "ChangesetBodyAlignToParam",
      description: "Rewrite body vars user/attrs to _user/_attrs when params are underscored (disabled for stabilization)",
      enabled: false,
      pass: reflaxe.elixir.ast.transformers.ChangesetBodyAlignToParamTransforms.pass
    });
    passes.push({
      name: "ChangesetParamUnderscore",
      description: "Prefix unused params with underscore in changeset functions (final order)",
      enabled: false,
      pass: reflaxe.elixir.ast.transformers.ChangesetParamUnderscoreTransforms.pass
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

    // Post-final query binder enforcement and cleanup
    passes.push({
      name: "QueryBinderFinalization",
      description: "Enforce `query = String.downcase(search_query)` at the very end when a different binder name slipped through",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.QueryBinderFinalizationTransforms.transformPass
    });
    passes.push({
      name: "DropResidualWildcardDowncase",
      description: "Drop stray `_ = String.downcase(search_query)` after establishing `query` binder (post-final)",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.DropResidualWildcardDowncasePostTransforms.transformPass
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
      name: "DuplicateCaseAssignFold",
      description: "Fold var = _ = call; case call do ... end -> var = case call do ... end",
      enabled: false,
      pass: reflaxe.elixir.ast.transformers.DuplicateCaseAssignFoldTransforms.pass
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
    passes.push({
      name: "DowncaseInlineFromPriorAssign_Final",
      description: "Inline prior assignments into String.downcase(var) and drop the assignment when safe",
      enabled: true,
      pass: reflaxe.elixir.ast.transformers.DowncaseInlineFromPriorAssignTransforms.pass,
      runAfter: ["UnderscoreTempInlineDowncase"]
    });
    passes.push({
      name: "LocalAssignUnusedUnderscore_Global_Final",
      description: "Absolute-final: underscore unused local assignment binders across blocks/functions",
      enabled: false,
      pass: reflaxe.elixir.ast.transformers.LocalAssignUnusedUnderscoreGlobalFinalTransforms.pass,
      runAfter: ["DowncaseInlineFromPriorAssign_Final"]
    });

    return passes;
  }
}
#end

