# Elixir AST Pass Registry Inventory

Generated from the validated granular registry by `tools/RegistryOrderDoc.hx`; do not edit manually.

Scope labels are executable semantic ownership. `PassScopeManifest` maps exact stable pass IDs to scopes, while `PassApplicability` derives module capabilities only from typed annotation metadata and structured ElixirAST. The verification-only `-D reflaxe_elixir_disable_pass_scopes` switch restores legacy all-pass execution for byte-parity checks.

- Effective granular passes per transformed module: **576**
- Full deterministic order: [TRANSFORM_PASS_REGISTRY_ORDER_GRANULAR.md](TRANSFORM_PASS_REGISTRY_ORDER_GRANULAR.md)
- Rebuild: `npm run docs:passes`
- Drift guard: `npm run guard:pass-inventory`
- Scoped/legacy byte parity: `npm run test:pass-scope-parity`
- Representative timing/count baseline: `npm run profile:passes:baseline`
- Checked-in reference data: [PASS_REGISTRY_BASELINE.json](PASS_REGISTRY_BASELINE.json)

## Phase Contracts

| Phase | Input invariant | Output invariant | Known downstream dependency | Representative tests |
|---|---|---|---|---|
| `bootstrap` Bootstrap normalization | Builder output after initial receiver-effect lowering. | Early returns, source binders, inline-expansion artifacts, and local names have stable AST carriers. | Framework annotation and core lowering passes consume these normalized binders and expression containers. | core/basic_syntax, regression/inline_if_g_variables |
| `framework-annotations` Framework annotations | Module metadata and normalized authored definitions are available. | Phoenix, LiveView, Ecto, OTP, and ExUnit module/callback scaffolding is represented in ElixirAST. | Guard, interpolation, and core passes assume generated callback heads and framework module forms already exist. | phoenix/router, liveview/golden_liveview_fixture, ecto/changeset, exunit/exunit_comprehensive |
| `guards-interpolation` Guards and interpolation | Case clauses and framework callbacks have their target-level heads. | Guard binders, list patterns, complex expression containers, and interpolation bodies are target-valid. | Core control-flow and collection lowering relies on valid clause binders and expression-position blocks. | core/string_interpolation_test, regression/guard_condition_grouping |
| `core-lowering` Core semantic lowering | Target-valid guards and expression containers are available. | Imperative state, loops, collections, pattern matches, stdlib calls, and framework call shapes have Elixir carriers. | HEEx conversion and late hygiene consume these stable target expressions and receiver/reducer bindings. | core/basic_syntax, stdlib/stdlib_externs, regression/non_void_tail_values |
| `hxx-heex` HXX and HEEx lowering | Core expressions and framework callback signatures are stable. | Typed HXX content is represented as valid HEEx sigils with assigns, imports, components, and control tags normalized. | Late hygiene must preserve sigil contents while repairing only target binders and warning-producing shells. | phoenix/hxx_inline_markup_basic, liveview/golden_liveview_fixture |
| `final-hygiene` Final hygiene | Semantic and template lowering is complete. | Unused binders, temporary aliases, reducer sentinels, and warning-producing assignments are normalized without changing result carriers. | Absolute-final repairs assume no new broad semantic lowering will occur. | regression/function_result_invariants, ecto/changeset, liveview/golden_liveview_fixture |
| `absolute-final` Absolute-final repairs | Only narrowly scoped late repair and warning suppression remains. | The pre-print AST is target-valid, warning-clean, and retains every authored non-Void result carrier. | The printer is the next stage; it must not repair semantics. | regression/function_result_invariants, phoenix/router, exunit/exunit_comprehensive |

## Scope Ownership

| Scope | Applicability predicate | Representative tests |
|---|---|---|
| `core` Core language | Always eligible; individual transforms still gate on typed ElixirAST shape. | core/basic_syntax, regression/non_void_tail_values |
| `stdlib` Target stdlib/runtime | Reserved for future typed stdlib ownership; current shared runtime transforms remain core until module-local eligibility is proven. | stdlib/stdlib_externs, test:haxe-exunit-stdlib |
| `phoenix` Phoenix and OTP | Phoenix/OTP annotations, compiler metadata, or structured Phoenix module references. | phoenix/router, otp/otp_supervision |
| `liveview` Phoenix LiveView | LiveView/Presence annotations or metadata, or structured Phoenix.LiveView references; also enables Phoenix and HXX capabilities. | liveview/golden_liveview_fixture, phoenix/liveview_basic |
| `ecto` Ecto | Ecto annotations/context or structured Ecto references; Phoenix/OTP-owned modules remain conservatively eligible for generated or unqualified Repo shapes. | ecto/changeset, ecto/typed_query_basic |
| `hxx` HXX and HEEx | Typed HXX metadata, HEEx fragments/sigils, assigns nodes, or an authored assigns function argument. | phoenix/hxx_inline_markup_basic, liveview/golden_liveview_fixture |
| `exunit` ExUnit | ExUnit annotation/metadata or structured ExUnit module references. | exunit/exunit_comprehensive |
| `diagnostics` Diagnostics | Compile-time define gated; production builds retain no diagnostic output. | test:result-invariant, guard:pass-inventory |
| `mixed` Mixed bundle | Lean-mode phase bundle; each contained granular pass evaluates its own typed scope before execution. | test:quick |

## Effective Families

A family is the intersection of a phase contract and semantic ownership scope. Each effective pass is assigned exactly one family in the granular order document.

| Family | Effective passes |
|---|---:|
| `absolute-final.core` | 117 |
| `absolute-final.ecto` | 7 |
| `absolute-final.exunit` | 2 |
| `absolute-final.hxx` | 6 |
| `absolute-final.liveview` | 33 |
| `absolute-final.phoenix` | 18 |
| `bootstrap.core` | 18 |
| `core-lowering.core` | 162 |
| `core-lowering.ecto` | 27 |
| `core-lowering.hxx` | 13 |
| `core-lowering.liveview` | 14 |
| `core-lowering.phoenix` | 8 |
| `final-hygiene.core` | 14 |
| `final-hygiene.ecto` | 5 |
| `framework-annotations.core` | 4 |
| `framework-annotations.ecto` | 5 |
| `framework-annotations.exunit` | 1 |
| `framework-annotations.hxx` | 1 |
| `framework-annotations.liveview` | 3 |
| `framework-annotations.phoenix` | 7 |
| `guards-interpolation.core` | 21 |
| `guards-interpolation.liveview` | 1 |
| `hxx-heex.core` | 70 |
| `hxx-heex.ecto` | 3 |
| `hxx-heex.hxx` | 12 |
| `hxx-heex.phoenix` | 4 |

## Replay And Repair Families

These are naming-related candidates for later consolidation, not proof that a pass is redundant. Replays remain required until shape and idempotence tests prove otherwise.

| Canonical family | Effective registrations |
|---|---|
| `AssignAliasIfPromote` | AssignAliasIfPromote_Early, AssignAliasIfPromote_Final |
| `AssignChainGenericSimplify` | AssignChainGenericSimplify_Early, AssignChainGenericSimplify, AssignChainGenericSimplify_Final |
| `AssignIfFoldInRhs` | AssignIfFoldInRhs_Early, AssignIfFoldInRhs_Final |
| `AssignWhereSelfBinderUnderscore` | AssignWhereSelfBinderUnderscore, AssignWhereSelfBinderUnderscore_Final |
| `CaseBinderUnderscoreAlign` | CaseBinderUnderscoreAlign_Final, CaseBinderUnderscoreAlign_AbsoluteFinal_Replay |
| `CaseClauseUnusedBinderUnderscore` | CaseClauseUnusedBinderUnderscore_Final, CaseClauseUnusedBinderUnderscore_AbsoluteLastReplay |
| `CaseDiscriminantTempNormalize` | CaseDiscriminantTempNormalize, CaseDiscriminantTempNormalize_Replay_AbsoluteLast |
| `CaseLengthToListPattern` | CaseLengthToListPattern, CaseLengthToListPattern_Post |
| `CaseListGuardToCons` | CaseListGuardToCons, CaseListGuardToCons_Replay_Final |
| `CaseOkBinderPrefixBindAllUndefined` | CaseOkBinderPrefixBindAllUndefined_AbsoluteFinal, CaseOkBinderPrefixBindAllUndefined_Replay_AbsoluteFinal, CaseOkBinderPrefixBindAllUndefined_Replay2_UltraFinal, CaseOkBinderPrefixBindAllUndefined_Replay_Last |
| `CasePayloadBinderAvoidReserved` | CasePayloadBinderAvoidReserved, CasePayloadBinderAvoidReserved_Final |
| `CaseScrutineeHoist` | CaseScrutineeHoist, CaseScrutineeHoist_Final |
| `CaseScrutineeVarToTupleBinder` | CaseScrutineeVarToTupleBinder, CaseScrutineeVarToTupleBinder_Replay_Final |
| `CaseSomeBinderNormalize` | CaseSomeBinderNormalize, CaseSomeBinderNormalize_Final |
| `CaseSuccessVarRenameCollisionFix` | CaseSuccessVarRenameCollisionFix, CaseSuccessVarRenameCollisionFix_AbsoluteFinal |
| `CaseSuccessVarUnifier` | CaseSuccessVarUnifier, CaseSuccessVarUnifier_Replay_Final |
| `CaseTupleBinderUnshadow` | CaseTupleBinderUnshadow, CaseTupleBinderUnshadow_PreFinal, CaseTupleBinderUnshadow_Final |
| `CaseTupleMultiBinderPromoteByUse` | CaseTupleMultiBinderPromoteByUse_Early, CaseTupleMultiBinderPromoteByUse_Final |
| `ChainAssignIfPromote` | ChainAssignIfPromote_Early, ChainAssignIfPromote_Final, ChainAssignIfPromote_Replay_Last |
| `ChangesetSequentialValidateThread` | ChangesetSequentialValidateThread, ChangesetSequentialValidateThread_Final |
| `ClauseUndefinedVarBindToBinder` | ClauseUndefinedVarBindToBinder_Final, ClauseUndefinedVarBindToBinder_Replay_Final |
| `ControllerAliasAssignDrop` | ControllerAliasAssignDrop_AbsoluteFinal, ControllerAliasAssignDrop_Replay_Ultimate |
| `ControllerLocalUnusedUnderscore` | ControllerLocalUnusedUnderscore, ControllerLocalUnusedUnderscore_Final |
| `CountEachToEnumCount` | CountEachToEnumCount_Early, CountEachToEnumCount |
| `DefArgUnderscorePromoteByBodyUse` | DefArgUnderscorePromoteByBodyUse, DefArgUnderscorePromoteByBodyUse_Final |
| `DropInvalidMapGetSelfAssign` | DropInvalidMapGetSelfAssign, DropInvalidMapGetSelfAssign_Final |
| `DropSelfAssignNoop` | DropSelfAssignNoop, DropSelfAssignNoop_AbsoluteLastReplay |
| `EFnForbiddenBinderRename` | EFnForbiddenBinderRename, EFnForbiddenBinderRename_Final |
| `EFnTempChainSimplify` | EFnTempChainSimplify, EFnTempChainSimplify_AlwaysRun |
| `EFnUnusedArgUnderscore` | EFnUnusedArgUnderscore, EFnUnusedArgUnderscore_Final, EFnUnusedArgUnderscore_AbsoluteLast |
| `EctoQueryBranchSelfAssignUnderscore` | EctoQueryBranchSelfAssignUnderscore, EctoQueryBranchSelfAssignUnderscore_Final |
| `FunctionArgBlockToIIFE` | FunctionArgBlockToIIFE_Pre, FunctionArgBlockToIIFE, FunctionArgBlockToIIFE_Post |
| `HandleInfoReturnSocketNormalize` | HandleInfoReturnSocketNormalize_Final, HandleInfoReturnSocketNormalize_UltraFinal |
| `HeexAssignsParamRename` | HeexAssignsParamRename, HeexAssignsParamRename_Final |
| `IfConditionComplexHoist` | IfConditionComplexHoist_Early, IfConditionComplexHoist |
| `InlineUnderscoreTempUsedOnce` | InlineUnderscoreTempUsedOnce, InlineUnderscoreTempUsedOnce_Final |
| `JoinArgListBuilderToMapJoin` | JoinArgListBuilderToMapJoin_Pre, JoinArgListBuilderToMapJoin, JoinArgListBuilderToMapJoin_Post |
| `ListGuardIndexToHead` | ListGuardIndexToHead, ListGuardIndexToHead_Replay_Final |
| `ListPushRewrite` | ListPushRewrite_Early, ListPushRewrite |
| `LocalCamelToSnakeDecl` | LocalCamelToSnakeDecl, LocalCamelToSnakeDecl_Final |
| `LocalUnderscoreGenericPromotion` | LocalUnderscoreGenericPromotion_UltraFinal, LocalUnderscoreGenericPromotion |
| `LocalUnderscoreUsedPromotion` | LocalUnderscoreUsedPromotion, LocalUnderscoreUsedPromotion_Final |
| `MountSessionExtractCleanup` | MountSessionExtractCleanup, MountSessionExtractCleanup_Final |
| `OkValueGlobalCleanup` | OkValueGlobalCleanup_AbsoluteFinal, OkValueGlobalCleanup_Replay_Ultimate, OkValueGlobalCleanup_AbsoluteLast |
| `ParamUnderscoreArgRefAlign` | ParamUnderscoreArgRefAlign, ParamUnderscoreArgRefAlign_Final |
| `ParamUnderscoreArgRefAlign_Global` | ParamUnderscoreArgRefAlign_Global, ParamUnderscoreArgRefAlign_Global_Final |
| `PubSubModuleRewrite` | PubSubModuleRewrite, PubSubModuleRewrite_AbsoluteLastReplay |
| `ReduceWhileSentinelCleanup` | ReduceWhileSentinelCleanup, ReduceWhileSentinelCleanup_Final |
| `ResultOkBinderNormalize` | ResultOkBinderNormalize, ResultOkBinderNormalize_Replay_Ultimate |
| `SplitChainedAssignments` | SplitChainedAssignments, SplitChainedAssignments_Final, SplitChainedAssignments_AbsoluteFinal |
| `SuccessBinderAlignByBodyUse` | SuccessBinderAlignByBodyUse, SuccessBinderAlignByBodyUse_Final, SuccessBinderAlignByBodyUse_Replay_Final |
| `SuccessVarAbsoluteReplaceUndefined` | SuccessVarAbsoluteReplaceUndefined, SuccessVarAbsoluteReplaceUndefined_Replay_Final |
| `SwitchReturnSanitizer` | SwitchReturnSanitizer, SwitchReturnSanitizer_Final |

## Registry Diagnostics

`RegistryCore` validates registrations before execution and still deduplicates defensively. The inventory guard requires zero duplicate registrations and zero ordering cycles.

- Duplicate registrations removed: **0** across **0** names
- Missing ordering dependencies: **0**
- Detected ordering cycle nodes: **0**
