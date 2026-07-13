package reflaxe.elixir.ast.transformers.registry;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.PassApplicability.PassScope;

/**
 * Explicit semantic ownership for framework-specific registry entries.
 *
 * WHAT
 * - Maps exact stable pass IDs to Phoenix/OTP, LiveView, Ecto, HXX, or ExUnit.
 *
 * WHY
 * - Ownership belongs in audited registry data. Inferring it from fragments such
 *   as `Live`, `Repo`, or `Test` silently misclassifies shared semantic passes.
 *
 * HOW
 * - `apply()` writes a typed `PassScope` onto every validated pass config.
 *   Unlisted passes remain core/global. `RegistryOrderDoc` rejects declarations
 *   that no longer resolve to an effective pass, and `PassApplicability` decides
 *   whether each scope is relevant to the current typed module.
 *
 * EXAMPLE
 * - `LiveViewTransform` is declared as `PassScope.LiveView`; a pass called
 *   `LiveNoreplyAtomFix` stays core because OTP code also produces that shape.
 */
@:nullSafety(Off)
class PassScopeManifest {
	public static function apply(passes:Array<ElixirASTTransformer.PassConfig>):Void {
		var scopes = declarations();
		for (pass in passes)
			pass.scope = scopes.exists(pass.name) ? scopes.get(pass.name) : PassScope.Core;
	}

	public static function declarations():Map<String, PassScope> {
		var scopes = new Map<String, PassScope>();
		assign(scopes, PassScope.Phoenix, [
			"EndpointTransform",
			"PhoenixFunctionMapping",
			"ControllerTransform",
			"ControllerLocalUnusedUnderscore",
			"RouterTransform",
			"ApplicationTransform",
			"SupervisorTransform",
			"ApplicationEnsureStartLink",
			"ControllerEnsureConnParam",
			"WebDefHeadPromotion",
			"ApplicationStartArgNormalization",
			"SupervisorOptionsTransform",
			"TelemetryChildrenArgFix",
			"SupervisorStartLinkChildrenInlineFix",
			"ERawWebModuleQualification",
			"WebRemoteCallModuleQualification",
			"AbsoluteFinalWebModuleQualification",
			"WebReduceWhileEFnQualification",
			"GettextArityAndParamRepair",
			"ControllerJsonCallCleanup_Final",
			"ControllerResultBinderNormalize_Final",
			"ControllerAliasAssignDrop_AbsoluteFinal",
			"WebDropUnusedSimpleAssign_AbsoluteFinal",
			"WebJsonCallAliasRewrite_AbsoluteFinal",
			"ControllerAliasChainDrop_Final",
			"ControllerAliasAssignDrop_Replay_Ultimate",
			"ControllerCaseRenameBinderIfBodyRefsBase_Final",
			"ControllerJsonDataArgToBinder_Final",
			"ControllerJsonDataArgPickSingleVar_Final",
			"WebParamFinalFix",
			"ControllerLocalUnusedUnderscore_Final",
			"ControllerJsonFinalize_AbsoluteFinal",
			"WebDropAliasAssign_Ultimate",
			"WebAliasAssignUnderscore_Ultimate",
			"WebJsonSecondArgRewrite_Ultimate",
			"ControllerJsonSecondArgUndefinedRewrite_Ultimate",
			"ControllerLocalAssignUnusedUnderscore_Final"
		]);
		assign(scopes, PassScope.LiveView, [
			"LiveViewTransform",
			"HandleEventParamRepair_AfterEventBridge",
			"HandleEventParamExtractFromBodyUse_AfterEventBridge",
			"HandleInfoCaseBinderCollisionRepair_Pre",
			"LiveViewErrorBinderRenameLate",
			"LiveViewReduceWhileErrorBinderNormalization",
			"LiveViewAssignCallRewrite",
			"PresenceBareCallPreserve",
			"PresenceWithSocketAssignNormalize",
			"PresenceEFnShadowedBinderRename",
			"PresenceRouteLocalize",
			"LiveMountSocketParamPromote",
			"LiveMountLatePromote",
			"LiveMountNormalize",
			"HandleEventParamsPromote",
			"MountParamsPromote",
			"LiveMountArityRepair",
			"MountSessionExtractCleanup",
			"PresenceERawCleanup",
			"HandleInfoDropUnusedAssign",
			"MountCaseSocketAssignDrop",
			"SocketPutFlashAssignDrop_Final",
			"SocketPutFlashBranchUse_Final",
			"HandleInfoUnderscoreSocketFix_Final",
			"HandleEventGroupingReorder",
			"HandleInfoSomeClauseNormalize_Final",
			"PresenceModuleFix",
			"LiveMountReturnFinalize",
			"HandleInfoReturnSocketNormalize_Final",
			"HandleEventToggleKeyExtract_Final",
			"HandleEventParamRepair_Final",
			"HandleEventWrapperFinalRepair",
			"HandleEventCamelRefInlineFromParams_Final",
			"HandleEventArg0FromParamsId_UltraFinal",
			"HandleInfoReturnSocketNormalize_UltraFinal",
			"MountParamsUltraFinal",
			"MountBodyAlignToHead_Final",
			"HandleEventParamsUltraFinal",
			"HandleEventBodyAlignToHead_Final",
			"MountSessionExtractCleanup_Final",
			"HandleEventParamsForceBodyRewrite_Final",
			"HandleEventParamsUltraFinal_Last",
			"PresenceConcatAccumulatorInit",
			"PresenceReduceWhileAccumulatorRepair",
			"MountParamsSideEffectAssignDiscard_Final",
			"MountParamsUnusedReassignUnderscore_Final",
			"HandleEventParamsHeadToParams_Final",
			"HandleEventMapGetUnderscoreParams_Final",
			"HandleInfoUnderscoreBinderPromote_Final",
			"LocalAssignDiscardIfUnused_LiveView_Final",
			"HandleEventMapGetValueDefaultToParams_Final",
			"HandleInfoAliasAndNoreply_AbsoluteFinal"
		]);
		assign(scopes, PassScope.Ecto, [
			"EctoQueryRequireInjection",
			"SchemaTransform",
			"RepoTransform",
			"PostgrexTypesTransform",
			"DbTypesTransform",
			"RepoQualification",
			"ERawRepoQualification",
			"ERawEctoFromQualification",
			"EctoFromInAtomQualification",
			"EctoFromInModuleQualification",
			"EctoQueryVarConsistency",
			"EctoQueryableAtomToSchema",
			"RepoAtomToSchema",
			"ChangesetSequentialValidateThread",
			"ChangesetFieldAtomNormalize",
			"ChangesetLengthCondCollapse",
			"ValidateLengthOptsAccessRewrite",
			"ChangesetLengthOptionFilter",
			"EctoEqPinnedNilGuard",
			"EctoSchemaBinderFix",
			"EctoQueryRequireEnsure",
			"EctoQueryIIFEInline",
			"EctoWhereWildcardAssignCleanup",
			"EctoLocalRequireInline",
			"ERawEctoValidateAtomNormalize",
			"EctoLocalShimNowarn",
			"EctoQueryBranchSelfAssignUnderscore",
			"EctoQueryIfAssignSimplify",
			"EctoStringBufQualification",
			"ERawEctoOptsAccessNormalize",
			"ERawEctoQueryableToSchema",
			"UnusedRepoAliasCleanupFinal",
			"ChangesetStructQualification",
			"PinnedVarRequireEctoQuery",
			"EctoRequireHoist",
			"ChangesetChainCleanup",
			"ChangesetBareCsRepair",
			"ChangesetSequentialValidateThread_Final",
			"RepoGetBinderRepair",
			"EctoWherePinnedBinderRepair",
			"EctoMigrationExs",
			"RepoCaseBinderNormalize",
			"RepoDeleteCaseArgRestore",
			"EctoQueryBranchSelfAssignUnderscore_Final",
			"EctoRepoFinalArgFromLatestQueryVar",
			"EctoRepoArgModuleQualify_Final",
			"ChangesetAssignedWildcardValidateCollapse_AbsoluteLast"
		]);
		assign(scopes, PassScope.Hxx, [
			"PhoenixComponentUseInjection",
			"EnsureAppWebHtmlUseInLayouts",
			"LiveViewCoreComponentsImport",
			"HeexContentInline",
			"HeexRawInlineFromPrecedingLiteral",
			"HeexAssignsCapture",
			"HeexRawUsageValidator",
			"HeexRewriteHxxBlock",
			"HeexNestedSigilFlattenFinal",
			"HeexStabilizeFinal",
			"HeexBlockIfToInline",
			"HeexStripDanglingQuoteLines",
			"HeexInlineRawForHeexVarsInStrings",
			"HeexRenderStringToSigil",
			"HeexStringReturnToSigil",
			"HeexControlTagTransforms",
			"HeexInlineMarkupConstStringRefs",
			"HeexStripToStringInSigils",
			"HeexSimplifyIIFEInInterpolations",
			"HeexLetUnusedBinderUnderscore",
			"HeexAssignsParamRename",
			"HeexVariableRawWrap",
			"PhoenixComponentImport",
			"HeexAssignsTypeLinter",
			"HeexCollapseOverEscapedQuotes_Final",
			"HeexTrimTrailingBlankLines_Final",
			"HeexAssignsBindRepair",
			"HeexEventNameNormalization",
			"HeexAssignsParamRename_Final",
			"PhoenixComponentModuleNormalize_AbsoluteLast",
			"HeexEnsureAssignsForNestedSigils",
			"HeexAssignsLocalVarRename_AbsoluteLast"
		]);
		assign(scopes, PassScope.ExUnit, ["ExUnitTransform", "ExUnitAssert_Final", "AssertArgIIFE_Final"]);
		return scopes;
	}

	static function assign(scopes:Map<String, PassScope>, scope:PassScope, passNames:Array<String>):Void {
		for (passName in passNames) {
			if (scopes.exists(passName))
				throw 'Pass scope declared more than once: $passName';
			scopes.set(passName, scope);
		}
	}
}
#end
