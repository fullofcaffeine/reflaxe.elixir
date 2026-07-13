# Transform Pass Registry Order

Generated from the validated registry by `tools/RegistryOrderDoc.hx`; do not edit manually.

Mode: granular (`-D hxx_granular_pass_registry`)

Effective pass count: **576**

| # | Pass | Phase | Scope | Family | Ordering | Description |
|---:|---|---|---|---|---|---|
| 1 | `EnumEachEarlyReturn` | `bootstrap` | `core` | `bootstrap.core` | source order | Preserve Haxe return semantics for loops lowered to Enum.each/2 (rewrite to Enum.reduce_while + case) |
| 2 | `EnumEachEarlyReturnRemainderLift` | `bootstrap` | `core` | `bootstrap.core` | source order | Lift outer remainder statements into reflaxe return-tagged reduce_while case else-branch |
| 3 | `SelfReferenceTransform` | `bootstrap` | `core` | `bootstrap.core` | source order | Convert self/this references to struct parameter |
| 4 | `Identity` | `bootstrap` | `core` | `bootstrap.core` | source order | Pass-through transformation (no changes) |
| 5 | `EarlyReturnIfElse` | `bootstrap` | `core` | `bootstrap.core` | source order | Preserve Haxe early-return semantics by moving remainder-of-block into if/else branches |
| 6 | `ResolveClauseLocals` | `bootstrap` | `core` | `bootstrap.core` | source order | Resolve variable references in case clauses using varIdToName metadata |
| 7 | `LocalVarNameNormalize` | `bootstrap` | `core` | `bootstrap.core` | source order | Normalize local variable and pattern binder names to snake_case |
| 8 | `RemoveRedundantEnumExtraction` | `bootstrap` | `core` | `bootstrap.core` | source order | Remove redundant elem() calls after pattern extraction in case clauses |
| 9 | `CaseOkBinderAlign` | `bootstrap` | `core` | `bootstrap.core` | source order | Rename {:ok, var} binder to match body local (todo) and rewrite body refs |
| 10 | `ResultOkBinderNormalize` | `bootstrap` | `core` | `bootstrap.core` | source order | Normalize {:ok, binder} to avoid ok_value leaks; align body to binder |
| 11 | `ThrowStatementTransform` | `bootstrap` | `core` | `bootstrap.core` | source order | Transform complex throw expressions to avoid syntax errors |
| 12 | `InlineMethodCallCombiner` | `bootstrap` | `core` | `bootstrap.core` | source order | Combine split inline expansion patterns from stdlib |
| 13 | `ExtractTupleInlineAssignments` | `bootstrap` | `core` | `bootstrap.core` | source order | Extract inline assignments from tuple constructors to fix syntax errors |
| 14 | `ExtractLiteralValueInlineAssignments` | `bootstrap` | `core` | `bootstrap.core` | source order | Hoist inline assignments out of map/keyword/struct literal values to preceding block |
| 15 | `FunctionReferenceTransform` | `bootstrap` | `core` | `bootstrap.core` | source order | Transform function references to use capture operator (&Module.func/arity) |
| 16 | `DefParamCamelToSnake` | `bootstrap` | `core` | `bootstrap.core` | source order | Rename function parameters camelCase→snake_case and update body references |
| 17 | `LocalCamelToSnakeDecl` | `bootstrap` | `core` | `bootstrap.core` | source order | Rename local EMatch/EVar declarations from camelCase to snake_case and update refs |
| 18 | `InlineTempBindingInExpr` | `bootstrap` | `core` | `bootstrap.core` | source order | Collapse EBlock([tmp = exprA, exprB(tmp)]) to exprB(exprA) in expression positions |
| 19 | `PhoenixWebTransform` | `framework-annotations` | `core` | `framework-annotations.core` | source order | Transform @:phoenixWeb modules into Phoenix Web helper module |
| 20 | `EndpointTransform` | `framework-annotations` | `phoenix` | `framework-annotations.phoenix` | source order | Transform @:endpoint modules into Phoenix.Endpoint structure |
| 21 | `SocketTransform` | `framework-annotations` | `core` | `framework-annotations.core` | source order | Transform @:socket modules into Phoenix.Socket structure |
| 22 | `LiveViewTransform` | `framework-annotations` | `liveview` | `framework-annotations.liveview` | source order | Transform @:liveview modules into Phoenix.LiveView structure |
| 23 | `LocalCamelToSnakeDecl_AfterEventBridge` | `framework-annotations` | `core` | `framework-annotations.core` | source order | Rename local camelCase→snake_case in newly generated handlers |
| 24 | `HandleEventParamRepair_AfterEventBridge` | `framework-annotations` | `liveview` | `framework-annotations.liveview` | source order | Repair handle_event/3 discarded Map.get and insert missing binds (shape-based) |
| 25 | `HandleEventParamExtractFromBodyUse_AfterEventBridge` | `framework-annotations` | `liveview` | `framework-annotations.liveview` | source order | Extract undefined locals from params in handle_event/3 (shape-based) |
| 26 | `PresenceTransform` | `framework-annotations` | `core` | `framework-annotations.core` | source order | Transform @:presence modules into Phoenix.Presence structure |
| 27 | `LiveViewCoreComponentsImport` | `framework-annotations` | `hxx` | `framework-annotations.hxx` | source order | Add CoreComponents import for LiveView modules that use components |
| 28 | `PhoenixFunctionMapping` | `framework-annotations` | `phoenix` | `framework-annotations.phoenix` | source order | Map custom function names to Phoenix conventions |
| 29 | `EctoQueryRequireInjection` | `framework-annotations` | `ecto` | `framework-annotations.ecto` | source order | Add `require Ecto.Query` to modules that use Ecto.Query macros |
| 30 | `ControllerTransform` | `framework-annotations` | `phoenix` | `framework-annotations.phoenix` | source order | Transform @:controller modules into Phoenix.Controller structure |
| 31 | `ControllerLocalUnusedUnderscore` | `framework-annotations` | `phoenix` | `framework-annotations.phoenix` | source order | In Controller modules, underscore unused local binders introduced by intermediate chains |
| 32 | `RouterTransform` | `framework-annotations` | `phoenix` | `framework-annotations.phoenix` | source order | Transform @:router modules into Phoenix.Router structure |
| 33 | `SchemaTransform` | `framework-annotations` | `ecto` | `framework-annotations.ecto` | source order | Transform @:schema modules into Ecto.Schema structure |
| 34 | `RepoTransform` | `framework-annotations` | `ecto` | `framework-annotations.ecto` | source order | Transform @:repo modules into Ecto.Repo structure |
| 35 | `PostgrexTypesTransform` | `framework-annotations` | `ecto` | `framework-annotations.ecto` | source order | Transform @:postgrexTypes modules into Postgrex types definition |
| 36 | `DbTypesTransform` | `framework-annotations` | `ecto` | `framework-annotations.ecto` | source order | Transform @:dbTypes modules into DB adapter types definition |
| 37 | `ApplicationTransform` | `framework-annotations` | `phoenix` | `framework-annotations.phoenix` | source order | Transform @:application modules into OTP Application structure |
| 38 | `ExUnitTransform` | `framework-annotations` | `exunit` | `framework-annotations.exunit` | source order | Transform @:exunit modules into ExUnit.Case test structure |
| 39 | `SupervisorTransform` | `framework-annotations` | `phoenix` | `framework-annotations.phoenix` | source order | Preserve supervisor functions from dead code elimination |
| 40 | `GuardGrouping` | `guards-interpolation` | `core` | `guards-interpolation.core` | source order | Transform multiple case clauses with same pattern and guards into cond |
| 41 | `JoinArgListBuilderToMapJoin_Pre` | `guards-interpolation` | `core` | `guards-interpolation.core` | source order | Rewrite Enum.join(<block temp-builder>, sep) → Enum.map(..) \|> Enum.join(sep) before interpolation |
| 42 | `EFnCallTargetParen` | `guards-interpolation` | `core` | `guards-interpolation.core` | source order | Wrap anonymous function call targets in parentheses: (fn -> ... end).() |
| 43 | `CaseLengthToListPattern` | `guards-interpolation` | `core` | `guards-interpolation.core` | source order | Rewrite case length(list) do ... end → case list do [] \| [head\|tail] ... end |
| 44 | `CaseTupleBinderUnshadow` | `guards-interpolation` | `core` | `guards-interpolation.core` | source order | For case over a function argument, rename tuple binder matching the arg to 'value' and prefix-bind most-used undefined local to that value |
| 45 | `HandleInfoCaseBinderCollisionRepair_Pre` | `guards-interpolation` | `liveview` | `guards-interpolation.liveview` | source order | Repair {:tag, socket}-style binder collisions in handle_info/2; rewrite local helper arg order (payload first, socket last) |
| 46 | `CaseScrutineeVarToTupleBinder` | `guards-interpolation` | `core` | `guards-interpolation.core` | source order | In case scrutinee do {:tag, binder} -> ..., rewrite body EVar(scrutinee) → EVar(binder) |
| 47 | `CaseBinderArgCollisionAvoid` | `guards-interpolation` | `core` | `guards-interpolation.core` | source order | Rename colliding case binders that shadow function arguments (e.g., {:tag, socket} → {:tag, payload}) and rewrite body references |
| 48 | `IfConditionBinaryCaseParen` | `guards-interpolation` | `core` | `guards-interpolation.core` | source order | Wrap case/cond/with/if sides of binary if/unless conditions in parentheses |
| 49 | `IfConditionComplexHoist_Early` | `guards-interpolation` | `core` | `guards-interpolation.core` | source order | Hoist case/cond/with/if from binary if/unless conditions (early) |
| 50 | `CaseBodyCamelRefToSnakeBinder` | `guards-interpolation` | `core` | `guards-interpolation.core` | source order | Rewrite camelCase free vars in case bodies to snake_case pattern binders; drop leading underscore on binders when used |
| 51 | `CaseListScrutineeHoist` | `guards-interpolation` | `core` | `guards-interpolation.core` | source order | Hoist non-variable list case scrutinee to a local variable |
| 52 | `CaseScrutineeHoistInAssign` | `guards-interpolation` | `core` | `guards-interpolation.core` | source order | Hoist list/bitstring scrutinee for var = case ... end |
| 53 | `CaseListGuardToCons` | `guards-interpolation` | `core` | `guards-interpolation.core` | source order | Rewrite [] with non-empty guard → [head\|tail] with repaired guard |
| 54 | `CaseGuardFreeVarToScrutinee` | `guards-interpolation` | `core` | `guards-interpolation.core` | source order | Rewrite guard refs to clause-local free vars → scrutinee var |
| 55 | `CaseEmptyListGuardNormalize` | `guards-interpolation` | `core` | `guards-interpolation.core` | source order | Rewrite [] guards implying non-empty → [first\|rest] with repaired guard |
| 56 | `ListGuardIndexToHead` | `guards-interpolation` | `core` | `guards-interpolation.core` | source order | Rewrite guards: list[0] → head; length(list) > 1 → tail != [] |
| 57 | `FunctionArgBlockToIIFE_Pre` | `guards-interpolation` | `core` | `guards-interpolation.core` | source order | Wrap multi-statement EBlock arguments in (fn -> ... end).() before interpolation |
| 58 | `FinalLocalReferenceAlign_PreInterpolation` | `guards-interpolation` | `core` | `guards-interpolation.core` | source order | Map refs to declared locals (name->_name, nameN->name, camel->snake, updated->ok_*) prior to interpolation |
| 59 | `StringInterpolation` | `guards-interpolation` | `core` | `guards-interpolation.core` | source order | Convert string concatenation to idiomatic string interpolation |
| 60 | `InterpolateJoinArgSanitize` | `guards-interpolation` | `core` | `guards-interpolation.core` | source order | Wrap Enum.join first arg as IIFE inside interpolation when it contains statements |
| 61 | `InterpolateIIFEWrap` | `guards-interpolation` | `core` | `guards-interpolation.core` | source order | Force-wrap all #{...} bodies in an IIFE to ensure a single valid expression |
| 62 | `LoopVariableRestore` | `core-lowering` | `core` | `core-lowering.core` | source order | Restore loop variables in string interpolations (fixes Haxe optimizer issue) |
| 63 | `ConstantFolding` | `core-lowering` | `core` | `core-lowering.core` | source order | Fold constant expressions at compile time |
| 64 | `ConditionalReassignment` | `core-lowering` | `core` | `core-lowering.core` | source order | Convert conditional reassignments to functional style |
| 65 | `RemoveRedundantNilInit` | `core-lowering` | `core` | `core-lowering.core` | source order | Remove redundant nil initialization when variable is immediately reassigned |
| 66 | `InstanceFieldLowering` | `core-lowering` | `core` | `core-lowering.core` | source order | Rewrite instance field locals to struct/map updates |
| 67 | `ListConcatUpdateRebind` | `core-lowering` | `core` | `core-lowering.core` | source order | Rewrite statement-position list ++/Enum.concat updates to explicit rebindings |
| 68 | `ControlFlowStateHoist` | `core-lowering` | `core` | `core-lowering.core` | source order | Hoist stateful rebinds from if/case/cond statements into outer matches |
| 69 | `PipelineOptimization` | `core-lowering` | `core` | `core-lowering.core` | source order | Convert sequential operations to pipeline |
| 70 | `InstanceMethodTransform` | `core-lowering` | `core` | `core-lowering.core` | source order | Transform instance.method() to Module.function(instance) for stdlib types |
| 71 | `StructModuleCaseNormalize` | `core-lowering` | `core` | `core-lowering.core` | source order | Normalize %Module{} segments to UpperCamel (e.g., %TodoApp.todo{} → %TodoApp.Todo{}) |
| 72 | `DefArgUnderscorePromoteByBodyUse` | `core-lowering` | `core` | `core-lowering.core` | source order | Rename PVar(_name) arg to name when body references name and not _name |
| 73 | `ApplicationEnsureStartLink` | `core-lowering` | `phoenix` | `core-lowering.phoenix` | source order | Ensure Application.start/2 appends Supervisor.start_link(children, opts) |
| 74 | `StdStringBufOverride` | `core-lowering` | `core` | `core-lowering.core` | source order | Override StringBuf with native parts-list implementation |
| 75 | `ModuleQualification` | `core-lowering` | `core` | `core-lowering.core` | source order | Final Web-context qualification <App>.Module after all rewrites |
| 76 | `UnrolledLoopTransform` | `core-lowering` | `core` | `core-lowering.core` | source order | Transform unrolled loops (sequential statements) back to Enum.each |
| 77 | `HaxeMapModuleCallRewrite` | `core-lowering` | `core` | `core-lowering.core` | source order | Rewrite IntMap/StringMap calls to native Map operations |
| 78 | `MapIteratorTransform` | `core-lowering` | `core` | `core-lowering.core` | source order | Transform Map iterator patterns from g.next() to idiomatic Enum operations |
| 79 | `MapSetRewrite` | `core-lowering` | `core` | `core-lowering.core` | source order | Rewrite var.set(key, value) to var = Map.put(var, :key, value) |
| 80 | `ComprehensionConversion` | `core-lowering` | `core` | `core-lowering.core` | source order | Convert imperative loops to comprehensions |
| 81 | `ListEffectLifting` | `core-lowering` | `core` | `core-lowering.core` | source order | Lift side-effecting expressions out of list literals |
| 82 | `ImmutabilityTransform` | `core-lowering` | `core` | `core-lowering.core` | source order | Convert mutable patterns to immutable |
| 83 | `StatementContextTransform` | `core-lowering` | `core` | `core-lowering.core` | source order | In statement position, rebind immutable ops to their first-arg variable (Map.put, ++, etc.) |
| 84 | `NullCoalescingInline` | `core-lowering` | `core` | `core-lowering.core` | source order | Convert null coalescing blocks to inline expressions |
| 85 | `StructFieldAssignmentTransform` | `core-lowering` | `core` | `core-lowering.core` | source order | Convert struct field assignments to struct update syntax |
| 86 | `MapBuilderCollapse` | `core-lowering` | `core` | `core-lowering.core` | source order | Replace Map.put builder blocks with literal maps |
| 87 | `DiscriminantRewrite` | `core-lowering` | `core` | `core-lowering.core` | source order | Rewrite case on temp discriminant (_g) to case on original expression |
| 88 | `TempAliasCleanup` | `core-lowering` | `core` | `core-lowering.core` | source order | Remove redundant temp alias assignments in statement contexts |
| 89 | `AssignmentChainCleanup` | `core-lowering` | `core` | `core-lowering.core` | source order | Collapse nested match alias chains to eliminate unused alias binders |
| 90 | `AssignmentExtraction` | `core-lowering` | `core` | `core-lowering.core` | source order | Extract assignments from binary operations and other expression contexts |
| 91 | `ListPushRewrite_Early` | `core-lowering` | `core` | `core-lowering.core` | source order | Early rewrite of list.push(v) to list = Enum.concat(list, [v]) (pre-reduce_while) |
| 92 | `AssignChainGenericSimplify_Early` | `core-lowering` | `core` | `core-lowering.core` | source order | EARLY: split a = (b = rhs) into b = rhs; a = b (reduce_while bodies) |
| 93 | `AssignAliasIfPromote_Early` | `core-lowering` | `core` | `core-lowering.core` | source order | EARLY: promote a=b; if cond(a) … else b -> a=if cond(b) … |
| 94 | `ChainAssignIfPromote_Early` | `core-lowering` | `core` | `core-lowering.core` | source order | EARLY: promote a=(b=rhs); if … else b → b=rhs; a=if … else b |
| 95 | `AssignIfFoldInRhs_Early` | `core-lowering` | `core` | `core-lowering.core` | source order | EARLY: fold a = (b=rhs; if … else b) into b=rhs; a=if … else b (statement contexts) |
| 96 | `StructUpdateTransform` | `core-lowering` | `core` | `core-lowering.core` | source order | Transform instance field assignments to avoid unused variable warnings |
| 97 | `ReduceWhileOuterAssignToAccumulator` | `core-lowering` | `core` | `core-lowering.core` | after: AssignmentExtraction, StructUpdateTransform; before: ReduceWhileAccumulator | Rewrite reduce_while loops that assign outer vars into accumulator threading |
| 98 | `ReduceWhileAccumulator` | `core-lowering` | `core` | `core-lowering.core` | after: ReduceWhileOuterAssignToAccumulator | Fix variable shadowing in reduce_while loops by proper accumulator threading |
| 99 | `ReduceWhileResultBinding` | `core-lowering` | `core` | `core-lowering.core` | after: ReduceWhileAccumulator | Bind Enum.reduce_while result to original accumulator locals (required in fast_boot) |
| 100 | `FluentApiOptimization` | `core-lowering` | `core` | `core-lowering.core` | source order | Optimize fluent API patterns to avoid unused struct assignments |
| 101 | `ArrayLengthFieldToFunction` | `core-lowering` | `core` | `core-lowering.core` | source order | Transform array.length field access to length(array) function calls |
| 102 | `KnownStringLengthFieldRewrite` | `core-lowering` | `core` | `core-lowering.core` | after: ArrayLengthFieldToFunction | Transform .length on locals proven to hold strings into String.length/1 |
| 103 | `FPHelperDoubleToI64FieldAccessRewrite` | `core-lowering` | `core` | `core-lowering.core` | source order | Rewrite i64.high/low from FPHelper.double_to_i64 to Bitwise ops (WAE) |
| 104 | `DateTimeMethodRewrite` | `core-lowering` | `core` | `core-lowering.core` | source order | Rewrite method-style DateTime calls to module calls |
| 105 | `TupleElemFieldToFunction` | `core-lowering` | `core` | `core-lowering.core` | source order | Transform tuple.elem field access to elem(tuple, index) function calls |
| 106 | `IdiomaticEnumPatternMatching` | `core-lowering` | `core` | `core-lowering.core` | source order | Transform enum tuple access patterns to idiomatic pattern matching |
| 107 | `IdiomaticEnumReplay` | `core-lowering` | `core` | `core-lowering.core` | source order | Reapply idiomatic enum conversion on residual tagged tuples |
| 108 | `PatternMatching` | `core-lowering` | `core` | `core-lowering.core` | source order | Transform switch statements to idiomatic Elixir case expressions |
| 109 | `CaseLengthToListPattern_Post` | `core-lowering` | `core` | `core-lowering.core` | source order | Rewrite case length(list) to list pattern case after PatternMatching |
| 110 | `CaseGuardFreeVarToOtherParam` | `core-lowering` | `core` | `core-lowering.core` | source order | In case guards, rewrite a single free var to the other function parameter when uniquely identifiable |
| 111 | `CaseClauseEmptyBodyToNil` | `core-lowering` | `core` | `core-lowering.core` | source order | Replace empty case arm bodies with nil to ensure valid syntax |
| 112 | `GuardSanitization` | `core-lowering` | `core` | `core-lowering.core` | source order | Replace non-guard-safe constructs (e.g., Map.get != nil) with guard-safe guard functions |
| 113 | `PatternVariableBinding` | `core-lowering` | `core` | `core-lowering.core` | source order | Ensure correct variable scoping in pattern matching |
| 114 | `RenameSwitchResultVars` | `core-lowering` | `core` | `core-lowering.core` | source order | Rename __elixir_switch_result_* to switch_result_* |
| 115 | `SwitchResultInlineReturnFix` | `core-lowering` | `core` | `core-lowering.core` | source order | Replace trailing switch_result_* with the assigned case expression (early) |
| 116 | `SwitchReturnSanitizer` | `core-lowering` | `core` | `core-lowering.core` | source order | Inline case into tail return when returning alias variable (sanitize direct switch returns) |
| 117 | `CaseExprParenthesizeInExpr` | `core-lowering` | `core` | `core-lowering.core` | source order | Wrap case in parentheses when used as assignment RHS |
| 118 | `CaseResultAssignmentMerge` | `core-lowering` | `core` | `core-lowering.core` | source order | Merge `x = init; case x do ... end` into `x = case init do ... end` |
| 119 | `SwitchInnerCaseBinderRepair` | `core-lowering` | `core` | `core-lowering.core` | source order | Rewrite inner `case <lhs>` to `case <binder>` when clause pattern binds the value (avoids undefined var) |
| 120 | `IfThenDoToBlock` | `core-lowering` | `core` | `core-lowering.core` | source order | Normalize EIf then-branch EDo to EBlock (prevents nested do) |
| 121 | `CasePatternTempAssignmentRemoval` | `core-lowering` | `core` | `core-lowering.core` | source order | Drop assignments like `todo = _g` when pattern already binds `todo` |
| 122 | `NumericSuffixVarNormalize` | `core-lowering` | `core` | `core-lowering.core` | source order | Normalize variables with trailing digits to descriptive base names (no integers) |
| 123 | `BinderCamelToSnake` | `core-lowering` | `core` | `core-lowering.core` | source order | Rename camelCase binders in case patterns to snake_case with body rewrite |
| 124 | `ClauseCamelRefToSnake` | `core-lowering` | `core` | `core-lowering.core` | source order | Within case arms, convert camelCase body refs to snake_case when binder exists |
| 125 | `CaseTupleMultiBinderPromoteByUse_Early` | `core-lowering` | `core` | `core-lowering.core` | after: ClauseCamelRefToSnake | Promote tuple binders (_a, _b, ...) to (a, b, ...) when used in body (AST or interpolation) |
| 126 | `ClauseUndefinedRefRewrite` | `core-lowering` | `core` | `core-lowering.core` | source order | Within {:tag, binder} arms, rewrite single undefined body var to binder (scope-aware) |
| 127 | `CasePayloadBinderAvoidReserved` | `core-lowering` | `core` | `core-lowering.core` | source order | Avoid reserved binder names (socket/params); rename binder to sole undefined body var |
| 128 | `CasePayloadBinderAvoidReserved_Final` | `core-lowering` | `core` | `core-lowering.core` | source order | Absolute final: avoid reserved binder names in case arms |
| 129 | `InnerParsedMsgCaseToBinder` | `core-lowering` | `core` | `core-lowering.core` | source order | Replace inner case parsed_msg with the outer bound binder (:some value) |
| 130 | `SystemAlertClauseNormalization` | `core-lowering` | `core` | `core-lowering.core` | source order | Normalize {:system_alert, message, flash_type} and fix flashType usage |
| 131 | `ControllerEnsureConnParam` | `core-lowering` | `phoenix` | `core-lowering.phoenix` | source order | Add `conn` param to controller action defs when body uses conn and param is missing |
| 132 | `WebDefHeadPromotion` | `core-lowering` | `phoenix` | `core-lowering.phoenix` | source order | Promote _id/_user_id/_editing_todo -> id/user_id/editing_todo in Web/Live defs when body uses base |
| 133 | `ErrorReasonAliasInjection` | `core-lowering` | `core` | `core-lowering.core` | source order | Ensure {:error, v} arms alias reason when body uses it |
| 134 | `LiveViewErrorBinderRenameLate` | `core-lowering` | `liveview` | `core-lowering.liveview` | source order | Late rename of LiveView {:error,_} -> {:error, reason} |
| 135 | `ResultErrorBinderLateNormalization` | `core-lowering` | `core` | `core-lowering.core` | source order | If body uses `reason` and not `changeset`, rename error binder to `reason` |
| 136 | `LiveViewReduceWhileErrorBinderNormalization` | `core-lowering` | `liveview` | `core-lowering.liveview` | source order | Within Enum.reduce_while anonymous functions, rename {:error,_} binder to reason when body uses it |
| 137 | `LiveViewAssignCallRewrite` | `core-lowering` | `liveview` | `core-lowering.liveview` | source order | Rewrite assign(socket,map) to Component.assign(socket,map) in LiveView modules |
| 138 | `ListPushRewrite` | `core-lowering` | `core` | `core-lowering.core` | source order | Rewrite list.push(v) to list = Enum.concat(list, [v]) |
| 139 | `StaticVarMutationRewrite` | `core-lowering` | `core` | `core-lowering.core` | source order | Persist static var mutations by calling static accessor setters |
| 140 | `RepoQualification` | `core-lowering` | `ecto` | `core-lowering.ecto` | source order | Rewrite bare Repo.* calls to <App>.Repo.* using the enclosing <App>Web module shape; ensures correctness without relying on aliases |
| 141 | `ERawRepoQualification` | `core-lowering` | `ecto` | `core-lowering.ecto` | source order | Qualify Repo.* tokens in ERaw within Web modules to <App>.Repo.* |
| 142 | `ERawEctoFromQualification` | `core-lowering` | `ecto` | `core-lowering.ecto` | source order | Rewrite Ecto.Query.from(... in :user, ...) to ... in <App>.User, ... in ERaw |
| 143 | `EctoFromInAtomQualification` | `core-lowering` | `ecto` | `core-lowering.ecto` | source order | Rewrite Ecto.Query.from(t in :table, ...) to t in <App>.CamelCase in AST nodes |
| 144 | `EctoFromInModuleQualification` | `core-lowering` | `ecto` | `core-lowering.ecto` | source order | Rewrite Ecto.Query.from(t in Module, ...) to t in <App>.Module where Module is single-segment CamelCase |
| 145 | `EctoQueryVarConsistency` | `core-lowering` | `ecto` | `core-lowering.ecto` | source order | Normalize Ecto query variable usage and rewrite Ecto.Query.where/Repo.all to canonical query var |
| 146 | `EctoQueryableAtomToSchema` | `core-lowering` | `ecto` | `core-lowering.ecto` | source order | Rewrite Ecto.Queryable.to_query(:table) to schema module <App>.<Camel> |
| 147 | `RepoAtomToSchema` | `core-lowering` | `ecto` | `core-lowering.ecto` | source order | Rewrite Repo.all/one/get/get!/aggregate(:table, ...) to <App>.<Camel> |
| 148 | `CaseSuccessVarUnifier` | `core-lowering` | `core` | `core-lowering.core` | source order | Rewrite undefined placeholder locals to the success var in {:ok, v} clauses |
| 149 | `CaseSuccessVarRenameCollisionFix` | `core-lowering` | `core` | `core-lowering.core` | source order | Rename {:ok, var} binder when it collides with function args (e.g., socket) |
| 150 | `CaseSomeBinderRename` | `core-lowering` | `core` | `core-lowering.core` | source order | Rename {:some, g} binder to value and rewrite body refs to avoid shadowing |
| 151 | `SimplifyIsNilFalse` | `core-lowering` | `core` | `core-lowering.core` | source order | Replace is_nil(var) with false when var is known non-nil from earlier literal assignment |
| 152 | `ApplicationStartArgNormalization` | `core-lowering` | `phoenix` | `core-lowering.phoenix` | source order | Align start_link arg names with declared locals in start/2 |
| 153 | `TypeSafeChildSpecNormalize` | `core-lowering` | `core` | `core-lowering.core` | source order | Normalize TypeSafeChildSpec.supervisor/3 to bind parameters and avoid undefined vars |
| 154 | `LocalVarReferenceFix` | `core-lowering` | `core` | `core-lowering.core` | source order | Fix local references like changeset-> _changeset or query->query2 when only the latter is declared |
| 155 | `StringToolsLocalFix` | `core-lowering` | `core` | `core-lowering.core` | source order | Align len/result references with declared locals in StringTools |
| 156 | `StringToolsNativeRewrite` | `core-lowering` | `core` | `core-lowering.core` | source order | Rewrite ltrim/rtrim to String.trim_leading/trim_trailing |
| 157 | `StringToolsFix` | `core-lowering` | `core` | `core-lowering.core` | source order | Ensure StringTools.is_space/2 uses binders s,pos (late enforcement) |
| 158 | `StdHaxeRuntimeOverride` | `core-lowering` | `core` | `core-lowering.core` | source order | Override select Haxe runtime modules with binder-consistent native implementations |
| 159 | `EqNilToIsNil` | `core-lowering` | `core` | `core-lowering.core` | source order | Replace (x == nil) with Kernel.is_nil(x) (post opts rewrites) |
| 160 | `ChangesetSequentialValidateThread` | `core-lowering` | `ecto` | `core-lowering.ecto` | source order | Thread sequential Ecto.Changeset validate calls through one changeset binder |
| 161 | `ChangesetFieldAtomNormalize` | `core-lowering` | `ecto` | `core-lowering.ecto` | source order | Rewrite String.to_atom("field") to :field in validate_* calls |
| 162 | `ChangesetLengthCondCollapse` | `core-lowering` | `ecto` | `core-lowering.ecto` | source order | Collapse cond-combination trees for validate_length to filtered Map.get keyword list |
| 163 | `ValidateLengthOptsAccessRewrite` | `core-lowering` | `ecto` | `core-lowering.ecto` | source order | In validate_length calls, rewrite opts.* to Map.get(opts, :key) |
| 164 | `ChangesetLengthOptionFilter` | `core-lowering` | `ecto` | `core-lowering.ecto` | source order | Drop nil options in validate_length by filtering keyword list |
| 165 | `EctoEqPinnedNilGuard` | `core-lowering` | `ecto` | `core-lowering.ecto` | source order | Guard Ecto where comparisons with pinned vars that may be nil |
| 166 | `EctoSchemaBinderFix` | `core-lowering` | `ecto` | `core-lowering.ecto` | source order | Normalize changeset/2 binder names by dropping underscores when body uses base names |
| 167 | `EctoQueryRequireEnsure` | `core-lowering` | `ecto` | `core-lowering.ecto` | source order | Ensure `require Ecto.Query` when Ecto.Query remote macros are present (pre-late; remote-only gating) |
| 168 | `EctoQueryIIFEInline` | `core-lowering` | `ecto` | `core-lowering.ecto` | source order | Inline (fn -> ... from(...) ... end).() used as where/2 query arg |
| 169 | `ChannelSetup` | `core-lowering` | `core` | `core-lowering.core` | source order | Inject `use <App>Web, :channel` for modules named like Phoenix channels |
| 170 | `EctoWhereWildcardAssignCleanup` | `core-lowering` | `ecto` | `core-lowering.ecto` | source order | Rewrite if-branch `_ = Ecto.Query.where(...)` to pure where(...) in expression context |
| 171 | `EctoLocalRequireInline` | `core-lowering` | `ecto` | `core-lowering.ecto` | source order | Insert `require Ecto.Query` before first from/where usage in function bodies (safety net) |
| 172 | `OptsKeywordMapGet` | `core-lowering` | `core` | `core-lowering.core` | source order | Normalize opts.* in keyword lists to Map.get |
| 173 | `SafePubSubAliasInject` | `core-lowering` | `core` | `core-lowering.core` | source order | Ensure alias Phoenix.SafePubSub as SafePubSub present |
| 174 | `IncrementToAssignment` | `core-lowering` | `core` | `core-lowering.core` | source order | Rewrite standalone increments to explicit assignments in blocks and if-branches |
| 175 | `StringToAtomLiteral` | `core-lowering` | `core` | `core-lowering.core` | source order | Replace String.to_atom("field") with :field when argument is a string literal |
| 176 | `LiveViewUseInjection` | `core-lowering` | `core` | `core-lowering.core` | source order | Inject `use <App>Web, :live_view` into <App>Web.*Live when missing |
| 177 | `LocalUnderscoreBinderPromote` | `core-lowering` | `core` | `core-lowering.core` | source order | Rename EMatch(_name = ...) to name = ... when subsequent code uses name |
| 178 | `BlockUnderscoreReferenceFix` | `core-lowering` | `core` | `core-lowering.core` | source order | Rewrite name -> _name within a block when only _name is declared in that block |
| 179 | `AdjacentUnderscoreBinderRefFix` | `core-lowering` | `core` | `core-lowering.core` | source order | In blocks, rewrite next statement references name-> _name after _name = ... assignment |
| 180 | `PhoenixComponentUseInjection` | `core-lowering` | `hxx` | `core-lowering.hxx` | source order | Add `use Phoenix.Component` to modules that call assign/2 |
| 181 | `SuppressHXXRuntimeModule` | `core-lowering` | `core` | `core-lowering.core` | source order | Mark HXX module as suppressEmission to avoid generating hxx.ex |
| 182 | `StringSearchFilterNormalization` | `core-lowering` | `core` | `core-lowering.core` | source order | Normalize string contains checks to pure boolean expressions in filter predicates |
| 183 | `StringBinaryMatchContainsRewrite` | `core-lowering` | `core` | `core-lowering.core` | source order | Normalize binary.match/is_nil search predicates to String.contains? |
| 184 | `VarNameNormalization` | `core-lowering` | `core` | `core-lowering.core` | source order | Normalize camelCase references to snake_case when a binding exists |
| 185 | `HXXRegistryFieldCasePreserve` | `core-lowering` | `core` | `core-lowering.core` | source order | Within HXXComponentRegistry, keep camelCase field names (e.g., allowedAttributes) |
| 186 | `ContainsToEnumMember` | `core-lowering` | `core` | `core-lowering.core` | source order | Rewrite arr.contains(v) to Enum.member?(arr, v) |
| 187 | `MemberFilterRemovalFix` | `core-lowering` | `core` | `core-lowering.core` | source order | When cond uses Enum.member?(list, v), rewrite filter(list, fn x -> x != x end) to compare x != v |
| 188 | `FilterReturnInlineFix` | `core-lowering` | `core` | `core-lowering.core` | source order | Inline filter result into return when function otherwise returns original list |
| 189 | `CaseSomeBinderNormalize` | `core-lowering` | `core` | `core-lowering.core` | source order | For {:some, _x} used in body, rename binder to a safe name and rewrite references |
| 190 | `ListMapReplaceFix` | `core-lowering` | `core` | `core-lowering.core` | source order | Fix Enum.map replacement no-op where both branches return the mapping var (use other var from id equality) |
| 191 | `ListFilterRemoveFix` | `core-lowering` | `core` | `core-lowering.core` | source order | Fix list self-compare bugs: Enum.filter v.id != v and Enum.find v.id == v (replace with enclosing id/_id param) |
| 192 | `UnderscoreVariableCleanup` | `core-lowering` | `core` | `core-lowering.core` | source order | Remove underscore prefix from used temporary variables |
| 193 | `AbstractMethodThis` | `core-lowering` | `core` | `core-lowering.core` | source order | Fix 'this' references in abstract methods |
| 194 | `SupervisorOptionsTransform` | `core-lowering` | `phoenix` | `core-lowering.phoenix` | source order | Convert supervisor option maps to keyword lists |
| 195 | `OTPChildSpecTransform` | `core-lowering` | `core` | `core-lowering.core` | source order | Convert enum-based child specs to proper OTP child specifications |
| 196 | `PrefixUnusedParameters` | `core-lowering` | `core` | `core-lowering.core` | source order | Prefix unused function parameters with underscore to follow Elixir conventions |
| 197 | `UsageAnalysis` | `core-lowering` | `core` | `core-lowering.core` | source order | Detect and mark unused variables with underscore prefix (context-aware) |
| 198 | `FixBareConcatenations` | `core-lowering` | `core` | `core-lowering.core` | source order | Convert bare concatenations in blocks to assignments |
| 199 | `FinalAssignRewrite` | `core-lowering` | `core` | `core-lowering.core` | source order | Rewrite remaining assign/2 calls to Component.assign/2 |
| 200 | `InlineTrailingReturnVar` | `core-lowering` | `core` | `core-lowering.core` | source order | Replace trailing return variable with its last assigned expression (late) |
| 201 | `DefParamUnderscorePromote` | `core-lowering` | `core` | `core-lowering.core` | source order | Promote underscored def/defp params when trimmed name is used in body |
| 202 | `RedundantAssignmentCleanup` | `core-lowering` | `core` | `core-lowering.core` | source order | Remove redundant assignments (thisN/new_query) that cause warnings |
| 203 | `NoOpArithmeticCleanup` | `core-lowering` | `core` | `core-lowering.core` | source order | Drop standalone `0 + 1` expressions in blocks (no-op arithmetic) |
| 204 | `DropStandaloneLiteralOne` | `core-lowering` | `core` | `core-lowering.core` | source order | Remove standalone numeric literals (1/0) causing unused literal warnings |
| 205 | `RefDeclAlignment` | `core-lowering` | `core` | `core-lowering.core` | source order | Final alignment of declarations and references to canonical names |
| 206 | `UnderscorePromoteByUse_Late` | `core-lowering` | `core` | `core-lowering.core` | source order | Promote underscored locals to base name when base is referenced (late, O(n)) |
| 207 | `UnusedDefpPrune` | `core-lowering` | `core` | `core-lowering.core` | source order | Final pruning of unused private functions |
| 208 | `EnsurePhoenixComponentUseInLive` | `core-lowering` | `core` | `core-lowering.core` | source order | Inject `use Phoenix.Component` into modules ending with Live |
| 209 | `EnsureAppWebHtmlUseInLayouts` | `core-lowering` | `hxx` | `core-lowering.hxx` | source order | Inject `use <App>Web, :html` into <App>Web.Layouts modules |
| 210 | `PresenceQualifiedModuleRewrite` | `core-lowering` | `core` | `core-lowering.core` | source order | Rewrite <App>.Presence.* calls to <App>Web.Presence.* |
| 211 | `PresenceWithSocketAssignNormalize` | `core-lowering` | `liveview` | `core-lowering.liveview` | source order | In presence modules ending with `socket`, rewrite bare Presence.* call to `socket = Presence.*(...)` |
| 212 | `LiveNoreplyAtomFix` | `core-lowering` | `core` | `core-lowering.core` | source order | Rewrite {:no_reply, socket} to {:noreply, socket} (shape-based) |
| 213 | `PresenceEFnShadowedBinderRename` | `core-lowering` | `liveview` | `core-lowering.liveview` | source order | Rename shadowed anonymous-fn binders (e.g., item) to entry to avoid warnings |
| 214 | `PresenceRouteLocalize` | `core-lowering` | `liveview` | `core-lowering.liveview` | source order | Inside Presence modules, rewrite Phoenix.Presence.* to current module |
| 215 | `SafePubSubAliasFix` | `core-lowering` | `core` | `core-lowering.core` | source order | Fix bare SafePubSub references to Phoenix.SafePubSub |
| 216 | `SafePubSubFix` | `core-lowering` | `core` | `core-lowering.core` | source order | Fix binder mismatch in Phoenix.SafePubSub.is_valid_message/1 |
| 217 | `TelemetryChildrenArgFix` | `core-lowering` | `phoenix` | `core-lowering.phoenix` | source order | Use _children in Supervisor.start_link when assignment was underscored |
| 218 | `LiveMountSocketParamPromote` | `core-lowering` | `liveview` | `core-lowering.liveview` | source order | Promote mount/3 third param to `socket` (shape-based, no app coupling) |
| 219 | `LiveMountLatePromote` | `core-lowering` | `liveview` | `core-lowering.liveview` | source order | Late safety net: rename mount/3 third param to `socket` and rewrite body refs |
| 220 | `LiveMountNormalize` | `core-lowering` | `liveview` | `core-lowering.liveview` | source order | Normalize LiveView mount/3: promote discards to named binders and bind updated_socket |
| 221 | `SupervisorStartLinkChildrenInlineFix` | `core-lowering` | `phoenix` | `core-lowering.phoenix` | source order | Inline [] for Supervisor.start_link(children, ...) in <App>Web.Telemetry |
| 222 | `AnonFnArgBinderFix` | `core-lowering` | `core` | `core-lowering.core` | source order | Rename underscore binders when body uses non-underscore variant |
| 223 | `KernelImportExceptThen` | `core-lowering` | `core` | `core-lowering.core` | source order | Inject `import Kernel, except: [then: 2]` when a module defines local then/2 |
| 224 | `UnusedImportCleanup` | `core-lowering` | `core` | `core-lowering.core` | source order | Remove import Ecto.Changeset when module not used |
| 225 | `DropUnusedSimpleAliasToUnderscore` | `core-lowering` | `core` | `core-lowering.core` | source order | Rewrite `tmp2 = value` style numeric-suffix aliases to `_ = value` when unused |
| 226 | `FlattenNestedMatchLhs` | `core-lowering` | `core` | `core-lowering.core` | source order | Flatten `( _ = call1 ) = call2` to two sequential underscore assignments |
| 227 | `HoistNestedAssignFromStringConcat` | `core-lowering` | `core` | `core-lowering.core` | source order | Hoist `(name = expr)` out of `left <> (...)` then use `name` in concat |
| 228 | `FixCallEqualsCall` | `core-lowering` | `core` | `core-lowering.core` | source order | Rewrite `call() = call()` into two underscore-discarded calls |
| 229 | `NormalizeBlankMatchLhsToUnderscore` | `core-lowering` | `core` | `core-lowering.core` | before: WildcardPromoteByUndeclaredUse | Replace empty LHS in match with `_` |
| 230 | `SanitizeAssignLhsIdentifier` | `core-lowering` | `core` | `core-lowering.core` | after: NormalizeBlankMatchLhsToUnderscore; before: WildcardPromoteByUndeclaredUse | Ensure LHS of match is a valid identifier; fallback to `_` otherwise |
| 231 | `WildcardPromoteByUndeclaredUse` | `core-lowering` | `core` | `core-lowering.core` | source order | Promote `_ = rhs` to named binder when a single undeclared var is used later |
| 232 | `ERawWebModuleQualification` | `core-lowering` | `phoenix` | `core-lowering.phoenix` | source order | Qualify single-segment modules inside ERaw within Web modules (final) |
| 233 | `HandleEventParamsPromote` | `core-lowering` | `liveview` | `core-lowering.liveview` | source order | Rename handle_event/3 `_params` to `params` when referenced and rewrite body |
| 234 | `MountParamsPromote` | `core-lowering` | `liveview` | `core-lowering.liveview` | source order | Rename mount/3 `_params` to `params` when referenced and rewrite body |
| 235 | `ERawEctoValidateAtomNormalize` | `core-lowering` | `ecto` | `core-lowering.ecto` | source order | Normalize ERaw validate_* atoms and opts nil comparisons (final) |
| 236 | `LiveMountArityRepair` | `core-lowering` | `liveview` | `core-lowering.liveview` | after: MountParamsPromote | Coerce mount heads to arity-3 and rename binders to params/_session/socket |
| 237 | `IfInlineInContainerParen` | `core-lowering` | `core` | `core-lowering.core` | source order | Wrap inline if-expressions inside tuples/lists/maps in parentheses (absolute-final) |
| 238 | `InlineIfInContainersGlobal` | `core-lowering` | `core` | `core-lowering.core` | source order | Wrap inline if-expressions in tuples/lists/maps (global contexts) |
| 239 | `CasePatternUnusedUnderscore` | `core-lowering` | `core` | `core-lowering.core` | source order | Underscore unused variables bound in case/with patterns |
| 240 | `CasePatternUnderscorePromotion` | `core-lowering` | `core` | `core-lowering.core` | source order | Promote `_name` pattern binders to `name` when the body references `name` |
| 241 | `CaseBodyAlignToPatternUnderscore` | `core-lowering` | `core` | `core-lowering.core` | source order | Rewrite body references to match underscored pattern binders in case/with clauses |
| 242 | `LocalUnderscoreUsedPromotion` | `core-lowering` | `core` | `core-lowering.core` | source order | Promote local `_name` binders to `name` when actually used (warnings cleanup) |
| 243 | `LocalUnderscoreUsedPromotion_Final` | `core-lowering` | `core` | `core-lowering.core` | source order | Final replay: promote `_this` and similar underscore locals when referenced |
| 244 | `InlineUnderscoreTempUsedOnce` | `core-lowering` | `core` | `core-lowering.core` | source order | Inline `_tmp = expr` followed by single-use of `_tmp` in next statement |
| 245 | `InlineUnderscoreTempUsedOnce_Final` | `core-lowering` | `core` | `core-lowering.core` | source order | Final replay: inline immediate-use underscore temps inside nested blocks |
| 246 | `InlineUnderscoreTempFromNullCheck` | `core-lowering` | `core` | `core-lowering.core` | source order | Replace _this in if-expr then-branch with expression from null check condition |
| 247 | `MountSessionExtractCleanup` | `core-lowering` | `liveview` | `core-lowering.liveview` | source order | Remove session extraction from params in mount/3; use real session arg |
| 248 | `EctoLocalShimNowarn` | `core-lowering` | `ecto` | `core-lowering.ecto` | source order | Inject @compile {:nowarn_unused_function, [from: 3, where: 3]} when local DSL shims are present |
| 249 | `EctoQueryBranchSelfAssignUnderscore` | `core-lowering` | `ecto` | `core-lowering.ecto` | source order | In branch tails, rewrite `x = Ecto.Query.where(x, ..)` to `_x = ...` |
| 250 | `AssignWhereSelfBinderUnderscore` | `core-lowering` | `core` | `core-lowering.core` | source order | Rewrite `x = Ecto.Query.where(x, ...)` to `_x = ...` everywhere in bodies |
| 251 | `EctoQueryIfAssignSimplify` | `core-lowering` | `ecto` | `core-lowering.ecto` | after: EctoQueryBranchSelfAssignUnderscore, AssignWhereSelfBinderUnderscore | Simplify inner `query =` inside if-branches for Ecto.Query.where |
| 252 | `DropInvalidMapGetSelfAssign` | `core-lowering` | `core` | `core-lowering.core` | source order | Remove `Map.get(params, key) = Map.get(params, key)` statements in function bodies |
| 253 | `EctoStringBufQualification` | `core-lowering` | `ecto` | `core-lowering.ecto` | source order | Qualify bare StringBuf.* to <App>.StringBuf.* in modules with Ecto DSL shims |
| 254 | `ERawEctoOptsAccessNormalize` | `core-lowering` | `ecto` | `core-lowering.ecto` | source order | Rewrite opts.* in ERaw keyword lists to Map.get(opts, :key) |
| 255 | `ERawEctoQueryableToSchema` | `core-lowering` | `ecto` | `core-lowering.ecto` | source order | Rewrite ERaw to_query(:atom) to schema module <App>.<Camel> |
| 256 | `PresenceERawCleanup` | `core-lowering` | `liveview` | `core-lowering.liveview` | source order | Sanitize ERaw reduce bodies in Presence modules (drop if 1 and trailing acc) |
| 257 | `DefParamBinderAlignByBodyUse` | `core-lowering` | `core` | `core-lowering.core` | source order | Promote underscored def params to base names when body uses base; rewrite body refs |
| 258 | `DefParamUnderscoreRefFix` | `core-lowering` | `core` | `core-lowering.core` | source order | Rewrite _param references to param when only param is declared |
| 259 | `ArithmeticIncrementCleanup` | `core-lowering` | `core` | `core-lowering.core` | source order | Final sweep: drop bare numeric literals and normalize increments |
| 260 | `ReduceWhileSentinelCleanup` | `core-lowering` | `core` | `core-lowering.core` | source order | Final sweep: drop numeric sentinels inside reduce_while bodies |
| 261 | `UnderscoreLocalPromotion` | `core-lowering` | `core` | `core-lowering.core` | source order | Promote `_name` local binders to `name` when referenced and safe |
| 262 | `UnusedLocalAssignUnderscoreFinal` | `core-lowering` | `core` | `core-lowering.core` | source order | Rename unused local assignment binders `name = expr` to `_name` (same-block only) |
| 263 | `DropTempNilAssign` | `core-lowering` | `core` | `core-lowering.core` | source order | Drop compiler-generated `thisN = nil` sentinel assignments from blocks/EFn bodies |
| 264 | `SplitChainedAssignments` | `core-lowering` | `core` | `core-lowering.core` | source order | Rewrite a = b = expr into: b = expr; a = b (improves reduce_while body shapes) |
| 265 | `IfConstSimplify` | `core-lowering` | `core` | `core-lowering.core` | source order | Simplify if true/1 and if false/0 conditionals |
| 266 | `UnusedRepoAliasCleanupFinal` | `core-lowering` | `ecto` | `core-lowering.ecto` | source order | Remove `alias <App>.Repo, as: Repo` when `Repo` isn’t referenced |
| 267 | `HeexContentInline` | `core-lowering` | `hxx` | `core-lowering.hxx` | source order | Replace ~H raw(content\|@var) using preceding literal assignment with direct ~H literal |
| 268 | `ParamUnderscoreArgRefAlign` | `core-lowering` | `core` | `core-lowering.core` | source order | Rewrite `_params` to `params` in defs that have a `params` arg |
| 269 | `ParamUnderscoreArgRefAlign_Global` | `core-lowering` | `core` | `core-lowering.core` | source order | Align body references to underscored head params globally (e.g., v → _v) |
| 270 | `HeexRawInlineFromPrecedingLiteral` | `core-lowering` | `hxx` | `core-lowering.hxx` | source order | Inline preceding string literal into ~H and drop Phoenix.HTML.raw(var) usage (heuristic) |
| 271 | `HeexAssignsCapture` | `core-lowering` | `hxx` | `core-lowering.hxx` | source order | Ensure @var usage inside ~H and assign var into assigns when inlining isn't possible |
| 272 | `HeexRawUsageValidator` | `core-lowering` | `hxx` | `core-lowering.hxx` | source order | Warn on residual Phoenix.HTML.raw(content\|@content) inside ~H |
| 273 | `HeexRewriteHxxBlock` | `core-lowering` | `hxx` | `core-lowering.hxx` | source order | (late) Replace <%= HXX.block(...) %> residue after capture inlining |
| 274 | `HeexNestedSigilFlattenFinal` | `core-lowering` | `hxx` | `core-lowering.hxx` | source order | Flatten `<%= ~H... %>` inside ~H content to avoid invalid heredoc nesting (final) |
| 275 | `HeexStabilizeFinal` | `core-lowering` | `hxx` | `core-lowering.hxx` | source order | Final ~H stabilization (bounded, idempotent sequence) |
| 276 | `HeexBlockIfToInline` | `core-lowering` | `hxx` | `core-lowering.hxx` | source order | (late) Rewrite <%= if ... do %>HTML<% else %>HTML<% end %> to inline-if |
| 277 | `HeexStripDanglingQuoteLines` | `core-lowering` | `hxx` | `core-lowering.hxx` | source order | (late) Drop lines that are solely a quote in ~H |
| 278 | `SplitChainedAssignments_Final` | `core-lowering` | `core` | `core-lowering.core` | source order | (ultra-final) Ensure no a = b = expr remains in blocks/EDo |
| 279 | `PhoenixEnumAtomTag` | `core-lowering` | `core` | `core-lowering.core` | source order | Rewrite Phoenix.* enum helpers from numeric tags to atom tags using function names |
| 280 | `EmptyModulePrune` | `core-lowering` | `core` | `core-lowering.core` | source order | Drop defmodule nodes with empty bodies to reduce noise |
| 281 | `SupportModuleQualification` | `core-lowering` | `core` | `core-lowering.core` | source order | Qualify single-segment CamelCase modules to <App>.<Name> when module is project-local and context uses Repo or Ecto DSL |
| 282 | `ProjectLocalModuleQualification` | `core-lowering` | `core` | `core-lowering.core` | source order | Qualify call-sites of single-segment project-local modules to <App>.<Name> |
| 283 | `AssignmentChainCleanupLate` | `core-lowering` | `core` | `core-lowering.core` | source order | Late sweep to collapse nested aliasing chains (lhs = g = expr) when alias is unused |
| 284 | `HeexInlineRawForHeexVarsInStrings` | `core-lowering` | `hxx` | `core-lowering.hxx` | source order | Rewrite "#{var}" to "#{Phoenix.HTML.raw(var)}" for vars bound from ~H/HTML |
| 285 | `HeexRenderStringToSigil` | `core-lowering` | `hxx` | `core-lowering.hxx` | source order | Ensure render(assigns) returns ~H by converting final HTML strings to ~H |
| 286 | `HeexStringReturnToSigil` | `hxx-heex` | `hxx` | `hxx-heex.hxx` | source order | Rewrite EDef/EDefp bodies with final HTML strings to ~H sigils |
| 287 | `HeexControlTagTransforms` | `hxx-heex` | `hxx` | `hxx-heex.hxx` | source order | Rewrite HXX-style <if>/<else> control tags in ~H content to HEEx blocks |
| 288 | `HeexInlineMarkupConstStringRefs` | `hxx-heex` | `hxx` | `hxx-heex.hxx` | source order | Rewrite brace attribute refs (HookName.X/EventName.Y) to string literals inside ~H |
| 289 | `HeexStripToStringInSigils` | `hxx-heex` | `hxx` | `hxx-heex.hxx` | source order | Remove trailing .to_string() in <%= ... %> within ~H |
| 290 | `HeexSimplifyIIFEInInterpolations` | `hxx-heex` | `hxx` | `hxx-heex.hxx` | source order | Rewrite <%= (fn -> expr end).() %> → <%= expr %> inside ~H |
| 291 | `HeexLetUnusedBinderUnderscore` | `hxx-heex` | `hxx` | `hxx-heex.hxx` | source order | Prefix unused :let binders in ~H with `_` to prevent Elixir warnings |
| 292 | `WebRemoteCallModuleQualification` | `hxx-heex` | `phoenix` | `hxx-heex.phoenix` | source order | Rewrite Foo.bar(...) → AppWeb.Foo.bar(...) inside Web modules |
| 293 | `HeexAssignsParamRename` | `hxx-heex` | `hxx` | `hxx-heex.hxx` | source order | Rename _assigns → assigns in functions that contain ~H |
| 294 | `HeexVariableRawWrap` | `hxx-heex` | `hxx` | `hxx-heex.hxx` | source order | Inside ~H, rewrite <%= var %> to raw(var) when var was bound from ~H or HTML string |
| 295 | `PhoenixComponentImport` | `hxx-heex` | `hxx` | `hxx-heex.hxx` | source order | Add Phoenix.Component import when ~H sigil is used (unless LiveView already includes it) |
| 296 | `HeexAssignsTypeLinter` | `hxx-heex` | `hxx` | `hxx-heex.hxx` | source order | Validate @assigns fields and literal comparisons in ~H against the Haxe typedef |
| 297 | `DefParamUnusedUnderscore` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Prefix unused function parameters with underscore in Phoenix Web/Live/Presence modules |
| 298 | `LocalUnderscoreReferenceFallback` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Fallback renaming of EVar(name) -> EVar(_name) when only _name declared (final) |
| 299 | `TopLevelNilAssignDiscard` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Rewrite var = nil to _ = nil when var is not used later in function |
| 300 | `CaseSuccessVarUnify` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Promote {:ok, _x} binder to {:ok, x} when body references x (extra absolute) |
| 301 | `EnumEachSentinelCleanup` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Absolute sweep: drop bare numeric sentinels in Enum.each fn bodies |
| 302 | `ClosureUnusedAssignmentDiscard` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Rewrite var = expr to _ = expr in EFn bodies when var unused later |
| 303 | `WebEFnModuleQualification` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Final sweep to qualify single-segment modules inside <App>Web.* EFn bodies |
| 304 | `AbsoluteFinalWebModuleQualification` | `hxx-heex` | `phoenix` | `hxx-heex.phoenix` | source order | Absolute-final: qualify single-segment CamelCase modules to <App>.<Module> inside <App>Web.* |
| 305 | `AliasAppLocalModules` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Insert alias <App>.<Name> at top of <App>Web.* when bare <Name> is used in calls and module exists |
| 306 | `WebReduceWhileEFnQualification` | `hxx-heex` | `phoenix` | `hxx-heex.phoenix` | source order | Explicitly qualify single-segment modules inside Enum.reduce_while EFns in <App>Web.* |
| 307 | `SelfAssignCompression` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Compress duplicated self-assignments x = x = expr to x = expr |
| 308 | `AssignChainPrune` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Prune unused binders in chain assignments and drop var=nil when unused |
| 309 | `AssignChainGenericSimplify` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Simplify nested match chains by dropping unused side (generic) |
| 310 | `IfInnerAssignSimplify` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Rewrite lhs = if do lhs = expr else lhs end → lhs = if do expr else lhs end |
| 311 | `IfResultAssignmentSimplify` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Simplify lhs = if do lhs = expr else lhs end to lhs = if do expr else lhs end (block-aware) |
| 312 | `StatementBlockFlatten` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Flatten nested EBlock/EDo in statement position to a single statement list (scope-transparent) |
| 313 | `CaseTupleResultBinding` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Bind case-returned tuples to real vars and drop nil pre-binds (WAE + idiomaticity) |
| 314 | `ShadowedInitAssignPrune` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Prune trivial initializers overwritten later in the same block (WAE hygiene) |
| 315 | `NilGuardFieldAccessCaseNarrow` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Rewrite if/or-nil guards to case-narrowed patterns for safe field access under WAE |
| 316 | `ChangesetStructQualification` | `hxx-heex` | `ecto` | `hxx-heex.ecto` | source order | Ensure %Module{} struct argument to changeset/2 is qualified to %<App>.Module{} in Web modules |
| 317 | `NilGuardCoalesceToMap` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Insert v = %{} after if Kernel.is_nil(v) when v.field is used later |
| 318 | `DateImplRewrite` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Map Date_Impl_.from_time/from_string/get_time/get_timezone_offset to Elixir equivalents |
| 319 | `NumericNoOpCleanup` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Remove standalone numeric ops like 0 + 1 and convert bare count + 1 to assignments |
| 320 | `EnumEachLhsDiscard` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Discard tuple LHS for Enum.each matches (shape-based cleanup) |
| 321 | `ReduceWhileToEnumEach` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Rewrite trivial reduce_while(Stream.iterate ...) scans to Enum.each |
| 322 | `EnumEachOuterAssignToReduce` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Rewrite Enum.each outer-var assignments to Enum.reduce accumulator threading |
| 323 | `FilterPredicateNormalize` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Ensure Enum.filter/2 uses EFn(predicate) across call shapes; wrap captures/expressions |
| 324 | `EnumEachHeadExtraction` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Inside Enum.each fns, replace head extraction list[0] with binder and drop sentinels |
| 325 | `EnumEachBinderIntegrity` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Ensure Enum.each bodies use binder (not list[0]); promote wildcard binder when needed |
| 326 | `HeexCollapseOverEscapedQuotes_Final` | `hxx-heex` | `hxx` | `hxx-heex.hxx` | source order | Final normalization of escaped quotes inside ~H inline strings |
| 327 | `HeexTrimTrailingBlankLines_Final` | `hxx-heex` | `hxx` | `hxx-heex.hxx` | source order | Final collapse of trailing blank lines in ~H content to match snapshot style |
| 328 | `CountRewrite` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Rewrite accumulator-style counting loops to Enum.count(list, &pred/1) |
| 329 | `CountBinderNormalize` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Normalize underscored binder in Enum.count/2 (rename when used) |
| 330 | `JoinArgListBuilderToMapJoin` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Rewrite Enum.join(<block temp-builder>, sep) to Enum.map(list, fn -> ...) \|> Enum.join(sep) |
| 331 | `FunctionArgBlockToIIFE` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Wrap multi-statement EBlock arguments in (fn -> ... end).() |
| 332 | `ListFindByIdFix` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Fix Enum.find self-compare v.id == v using enclosing id/_id param |
| 333 | `CamelAtomAccessToSnake` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Rewrite EAccess(_, :camelCase) to snake_case atom keys |
| 334 | `RedundantUnderscoreCallBeforeCase` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Remove `_ = Mod.func(args)` immediately before `case Mod.func(args) do ... end` |
| 335 | `FnArgBodyRefNormalize` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Normalize body references of underscored variants to declared non-underscore binder in anonymous functions |
| 336 | `EFnArgCleanup` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Final cleanup of EFn arg/body underscore mismatches |
| 337 | `CountEachToEnumCount_Early` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Early: rewrite Enum.each(list, fn b -> if cond, do: b = b + 1 end) → Enum.count(list, fn b -> cond end) |
| 338 | `EFnScopedUnderscoreRefCleanup` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Rewrite _name -> name in EFn bodies when a matching binder exists |
| 339 | `EFnNumericSentinelCleanup` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Drop EInteger(0\|1) and EFloat(0.0) statements in EFn bodies |
| 340 | `EFnUnusedArgUnderscore` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Prefix unused EFn binders with underscore to avoid warnings |
| 341 | `EFnForbiddenBinderRename` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Rename forbidden EFn binders (e.g., elem -> entry) and update body references |
| 342 | `EFnLocalAssignDiscard` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Replace unused local rebinds in EFn bodies with wildcard assignment |
| 343 | `EFnBinderReferenceAlign` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Align EFn binders with body references: _name -> name when binder exists |
| 344 | `EFnForbiddenBinderRename_Final` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Late pass: rename forbidden EFn binders (e.g., elem -> entry) post-normalization |
| 345 | `CountEachToEnumCount` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Rewrite Enum.each(list, fn b -> if cond, do: b = b + 1 end) to Enum.count(list, fn b -> cond end) |
| 346 | `DefArgUnderscorePromoteByBodyUse_Final` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Late: rename PVar(_name) arg to name when body/ERaw references name |
| 347 | `BlockAssignChainSimplify` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Rewrite outer = inner = expr → outer = expr when inner is unused later in function block |
| 348 | `FunctionArgBlockToIIFE_Post` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Wrap multi-statement EBlock/EDo args in (fn -> ... end).() after late transforms |
| 349 | `JoinArgForceIIFE` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Ensure Enum.join first argument is a single expression by IIFE wrapping complex shapes |
| 350 | `JoinArgListBuilderToMapJoin_Post` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Rewrite Enum.join(<builder block>, sep) to Enum.map \|> Enum.join late |
| 351 | `JoinArgBlockScopedFix` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Rewrite block-scoped temp-list builder to Enum.map \|> Enum.join and prune builder |
| 352 | `JoinArgAlwaysIIFE` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Force Enum.join first arg to be a single expression by IIFE wrapping |
| 353 | `BinaryOperandBlockToIIFE` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Wrap multi-statement operands of binary operators in IIFE |
| 354 | `IfConditionComplexToParen` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Wrap if/unless conditions in parentheses when containing case/cond/with/if |
| 355 | `IfConditionComplexHoist` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Hoist case/cond/with/if out of binary conditions: value = <complex>; if value <op> rhs do ... |
| 356 | `BinaryOperandComplexToParen` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Wrap case/cond/with/if operands of binary ops in parentheses |
| 357 | `EFnIIFEUnwrap` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Unwrap IIFE that returns an anonymous function to the function itself |
| 358 | `ReservedWordVarSanitize` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Rename variables colliding with Elixir reserved words to safe variants |
| 359 | `FunctionTopLevelSentinelCleanup` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Remove bare 1/0/0.0 statements at top-level in def/defp bodies |
| 360 | `ZeroAssignCallToBareCall` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Rewrite `0 = call(...)` or `0 = Mod.call(...)` back to bare calls (idiomatic) |
| 361 | `StructUpdateListAppendRewrite` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Rewrite struct update list append into local list append assignment |
| 362 | `StructUpdateStandaloneDiscard` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Discard standalone %{struct \| ...} when not final in a block |
| 363 | `TupleLhsDiscard` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Discard {x} = expr (arity-1 tuple LHS) and keep expr |
| 364 | `PinnedVarRequireEctoQuery` | `hxx-heex` | `ecto` | `hxx-heex.ecto` | source order | Inject `require Ecto.Query` based on EPin presence as a deterministic safeguard |
| 365 | `EctoRequireHoist` | `hxx-heex` | `ecto` | `hxx-heex.ecto` | source order | Hoist local `require Ecto.Query` to module top and remove duplicates |
| 366 | `GettextArityAndParamRepair` | `hxx-heex` | `phoenix` | `hxx-heex.phoenix` | source order | In *.Gettext modules, add arity shims and de-underscore used params like count |
| 367 | `SuccessBinderAlignByBodyUse` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Rename {:ok, binder} binder to the single undefined var used in body, if unambiguous |
| 368 | `SuccessVarAbsoluteReplaceUndefined` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Final safety: replace any undefined lower-case var in {:ok, binder} clause body with binder |
| 369 | `UnderscoreBinderAlignByBodyUse_Final` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Rename {:tag, _x} binder to unique undefined lower-case var used in body (scope-aware) |
| 370 | `ReduceAliasConcatToAcc` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Normalize alias-based accumulator concat to canonical acc concat inside Enum.reduce (absolute) |
| 371 | `ReduceAccAliasUnify` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Unify reduce accumulator alias to acc across reducer body (absolute) |
| 372 | `ReduceCanonicalize` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Canonicalize alias self-append and head extraction within two-arg reducers |
| 373 | `EFnAliasConcatToAcc` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Normalize alias concat -> acc concat inside any two-arg anonymous function (safety net) |
| 374 | `ReduceAppendCanonicalize` | `hxx-heex` | `core` | `hxx-heex.core` | source order | Canonicalize append inside Enum.reduce: alias concat -> acc concat; alias element -> binder |
| 375 | `AccAliasLateRewrite` | `final-hygiene` | `core` | `final-hygiene.core` | source order | Rewrite accumulator alias self-append to canonical acc updates (ultra-final safety) |
| 376 | `CaseBinderRebindUnderscore` | `final-hygiene` | `core` | `final-hygiene.core` | source order | In case arms, underscore binders that are immediately rebound before use |
| 377 | `CaseClausePinExistingBindings` | `final-hygiene` | `core` | `final-hygiene.core` | source order | Pin variables in case clause patterns when matching existing in-scope bindings |
| 378 | `DropStandaloneVarRef` | `final-hygiene` | `core` | `final-hygiene.core` | source order | Drop standalone var references in statement position inside blocks/do-blocks (ultra-final) |
| 379 | `EFnTempChainSimplify` | `final-hygiene` | `core` | `final-hygiene.core` | source order | Inside EFn, rewrite var=nil; var=expr; var → expr |
| 380 | `TrailingTempReturnSimplify` | `final-hygiene` | `core` | `final-hygiene.core` | source order | Replace trailing temp returns with the rhs expression |
| 381 | `DefTrailingAssignedVarReturn` | `final-hygiene` | `core` | `final-hygiene.core` | source order | Append trailing var when last statement is assignment to non-temp |
| 382 | `ChangesetChainCleanup` | `final-hygiene` | `ecto` | `final-hygiene.ecto` | source order | Collapse changeset nested assigns cs/thisN → direct cs assign |
| 383 | `ChangesetEnsureReturn` | `final-hygiene` | `core` | `final-hygiene.core` | source order | Ensure functions building Ecto.Changeset return last assigned var |
| 384 | `ChangesetBareCsRepair` | `final-hygiene` | `ecto` | `final-hygiene.ecto` | source order | Repair changeset/2 bodies reduced to bare cs by reconstructing change(p1, p2) |
| 385 | `LateEnsureCsBinder` | `final-hygiene` | `core` | `final-hygiene.core` | source order | Ensure `cs` binder exists by rewriting earliest cast/change producer to `cs = ...` (late) |
| 386 | `ChangesetSequentialValidateThread_Final` | `final-hygiene` | `ecto` | `final-hygiene.ecto` | source order | Finalize sequential Ecto.Changeset validate calls through one changeset binder |
| 387 | `TempAssignFlattenGlobal` | `final-hygiene` | `core` | `final-hygiene.core` | source order | Flatten temp alias chains globally: outer=(temp=expr) → outer=expr |
| 388 | `RepoGetBinderRepair` | `final-hygiene` | `ecto` | `final-hygiene.ecto` | source order | Rewrite bodies that return an undeclared var v to Repo.get(schema(v), firstParam) |
| 389 | `PinnedVarBinderPromote` | `final-hygiene` | `core` | `final-hygiene.core` | source order | Promote `_ = <literal>` to `<name> = <literal>` when a unique ^(name) is used later |
| 390 | `EctoWherePinnedBinderRepair` | `final-hygiene` | `ecto` | `final-hygiene.ecto` | source order | Repair wildcard literal binder before where/2 that pins its value later |
| 391 | `EFnUnusedArgUnderscore_Final` | `final-hygiene` | `core` | `final-hygiene.core` | source order | Absolute-final: underscore unused EFn binders (Enum.reduce/map/each) after all rewrites |
| 392 | `ReduceWhileSentinelCleanup_Final` | `final-hygiene` | `core` | `final-hygiene.core` | source order | Late: drop numeric sentinel literals inside reduce_while bodies |
| 393 | `NestedAssignCollapseGlobal_Final` | `final-hygiene` | `core` | `final-hygiene.core` | source order | Absolute-final: collapse nested assignments outer=(inner=expr) → outer=expr across all nodes |
| 394 | `EFnTempChainSimplify_AlwaysRun` | `absolute-final` | `core` | `absolute-final.core` | source order | Inside EFn, rewrite var=nil; var=expr; var → expr (runs even with fast_boot) |
| 395 | `AbstractNilDefaultSpecialization_AlwaysRun` | `absolute-final` | `core` | `absolute-final.core` | after: EFnTempChainSimplify_AlwaysRun | Collapse nil-default temps emitted by inlined multi-type abstract specialization helpers |
| 396 | `AbstractImplIdentityStub_AlwaysRun` | `absolute-final` | `core` | `absolute-final.core` | source order | Ensure empty abstract-impl stubs (_new/from_string) return their single argument (prevents unused-arg warnings) |
| 397 | `HandleInfoDropUnusedAssign` | `absolute-final` | `liveview` | `absolute-final.liveview` | source order | In handle_info/2, drop v = case ... when v is unused |
| 398 | `MountCaseSocketAssignDrop` | `absolute-final` | `liveview` | `absolute-final.liveview` | source order | In mount/3 case clauses, drop `socket = put_flash(socket, ...)` assignment to avoid warnings |
| 399 | `FinalLocalReferenceAlign` | `absolute-final` | `core` | `absolute-final.core` | source order | Map refs to declared locals: name-> _name, nameN->name, updated->ok_* (unique) |
| 400 | `ResultOkBinderNormalize_Replay_Ultimate` | `absolute-final` | `core` | `absolute-final.core` | after: FinalLocalReferenceAlign | Ultimate replay of {:ok, binder} normalization inside def/defp and EFn |
| 401 | `OkValueGlobalCleanup_AbsoluteFinal` | `absolute-final` | `core` | `absolute-final.core` | source order | Ultra-final: rewrite free ok_value refs to value when value is declared |
| 402 | `EFnUndefinedRefToArg_Final` | `absolute-final` | `core` | `absolute-final.core` | source order | In fn arg -> ... end with one undefined body var, rewrite it to arg |
| 403 | `EFnBinderAlignToUndefinedRef_Final` | `absolute-final` | `core` | `absolute-final.core` | source order | If a single undefined var exists in fn body, rename binder to that var |
| 404 | `CaseSuccessVarUnifier_Replay_Final` | `absolute-final` | `core` | `absolute-final.core` | source order | Replay unifier to rewrite undefined placeholders to {:ok, v} binder (late) |
| 405 | `SuccessVarAbsoluteReplaceUndefined_Replay_Final` | `absolute-final` | `core` | `absolute-final.core` | source order | Ultra-final: map undefined lower-case vars in {:ok, binder} bodies to binder |
| 406 | `CaseSomeBinderNormalize_Final` | `absolute-final` | `core` | `absolute-final.core` | source order | Rename {:some, _x} binder to safe name and rewrite references (late) |
| 407 | `UnderscoreVarUsageFix_AbsoluteFinal` | `absolute-final` | `core` | `absolute-final.core` | after: FinalLocalReferenceAlign, OkValueGlobalCleanup_AbsoluteFinal, SuccessVarAbsoluteReplaceUndefined_Replay_Final | Rename _name to name when used in expression context to avoid warnings |
| 408 | `CaseNilAssignCleanup_Final` | `absolute-final` | `core` | `absolute-final.core` | source order | Remove `nil = _var` statements from case clause bodies (ultra-final) |
| 409 | `CaseClauseHygieneCleanup_Final` | `absolute-final` | `core` | `absolute-final.core` | source order | Drop `nil = _var` and rewrite `socket = put_flash(socket, ...)` inside case clauses |
| 410 | `CaseErrorVarUnify_Final` | `absolute-final` | `core` | `absolute-final.core` | source order | Promote {:error, _x} to {:error, x} when body uses x; map undefined to binder |
| 411 | `CaseBinderUnderscoreAlign_Final` | `absolute-final` | `core` | `absolute-final.core` | source order | Rename {:ok, _value} back to {:ok, value} when body uses `value` and no other binder exists |
| 412 | `ControllerJsonCallCleanup_Final` | `absolute-final` | `phoenix` | `absolute-final.phoenix` | source order | Remove json/data/conn alias chains before Phoenix.Controller.json and use original conn |
| 413 | `ControllerResultBinderNormalize_Final` | `absolute-final` | `phoenix` | `absolute-final.phoenix` | after: ControllerJsonCallCleanup_Final | Normalize {:ok,_}/{:error,_} binders to value/reason in controllers (final) |
| 414 | `ControllerAliasAssignDrop_AbsoluteFinal` | `absolute-final` | `phoenix` | `absolute-final.phoenix` | source order | Absolute-final: drop assignments to json/data/conn in controller bodies and case arms |
| 415 | `WebDropUnusedSimpleAssign_AbsoluteFinal` | `absolute-final` | `phoenix` | `absolute-final.phoenix` | source order | Absolute-final: in Web modules, drop simple unused assignments (pure RHS) |
| 416 | `WebJsonCallAliasRewrite_AbsoluteFinal` | `absolute-final` | `phoenix` | `absolute-final.phoenix` | before: ControllerAliasAssignDrop_Replay_Ultimate, ControllerAliasChainDrop_Final | Absolute-final: in Web.* modules, remove json/data/conn alias lines and rewrite json(conn, data) to use RHS var |
| 417 | `ControllerAliasChainDrop_Final` | `absolute-final` | `phoenix` | `absolute-final.phoenix` | source order | Drop contiguous json/data/conn alias-chains to the same RHS var in controllers |
| 418 | `ControllerAliasAssignDrop_Replay_Ultimate` | `absolute-final` | `phoenix` | `absolute-final.phoenix` | source order | Ultimate replay: drop alias assigns json/data/conn in controllers after all rewrites |
| 419 | `DebugControllerJsonArgs` | `absolute-final` | `core` | `absolute-final.core` | source order | Debug: log json(conn, ...) arg kinds in controllers when -D debug_controller_json is set |
| 420 | `ControllerCaseRenameBinderIfBodyRefsBase_Final` | `absolute-final` | `phoenix` | `absolute-final.phoenix` | after: CaseErrorVarUnify_Final, ControllerJsonCallCleanup_Final | Promote case binder _name -> name in controllers when body references base name |
| 421 | `ControllerJsonDataArgToBinder_Final` | `absolute-final` | `phoenix` | `absolute-final.phoenix` | after: ControllerCaseRenameBinderIfBodyRefsBase_Final, WebJsonCallAliasRewrite_AbsoluteFinal | In controllers, rewrite Phoenix.Controller.json(conn, data) to binder inside case arms |
| 422 | `ControllerJsonDataArgPickSingleVar_Final` | `absolute-final` | `phoenix` | `absolute-final.phoenix` | after: ControllerJsonDataArgToBinder_Final, ControllerCaseRenameBinderIfBodyRefsBase_Final | When json(conn, data) and exactly one lower-case var used in body, rewrite arg2 to it |
| 423 | `ReduceMetasHeadRepair` | `absolute-final` | `core` | `absolute-final.core` | source order | Repair accidental meta=binder in reduce branches that check entry.metas |
| 424 | `ListIndexAccessToEnumAt` | `absolute-final` | `core` | `absolute-final.core` | source order | Rewrite list index access (entry.metas[0]) to Enum.at(entry.metas, 0) |
| 425 | `SafePubSubModuleRewrite` | `absolute-final` | `core` | `absolute-final.core` | source order | Rewrite SafePubSub.* to Phoenix.SafePubSub.* (ultimate fallback) |
| 426 | `PubSubModuleRewrite` | `absolute-final` | `core` | `absolute-final.core` | source order | Rewrite PubSub.* to Phoenix.PubSub.* (ultimate fallback for native extern calls) |
| 427 | `GlobalNumericSentinelCleanup` | `absolute-final` | `core` | `absolute-final.core` | source order | Global sweep to drop standalone numeric sentinel literals (0,1,0.0) in any block |
| 428 | `DropNilAssignFromUnderscoredVar_Final` | `absolute-final` | `core` | `absolute-final.core` | source order | Remove statements like `nil = _g` which cause WAE warnings |
| 429 | `SocketPutFlashAssignDrop_Final` | `absolute-final` | `liveview` | `absolute-final.liveview` | source order | Rewrite socket = put_flash(socket, ...) to just put_flash(socket, ...) |
| 430 | `SocketPutFlashBranchUse_Final` | `absolute-final` | `liveview` | `absolute-final.liveview` | source order | Append bare `socket` after put_flash assignment when not immediately used |
| 431 | `EctoMigrationExs` | `absolute-final` | `ecto` | `absolute-final.ecto` | source order | Rewrite @:migration builder chains into runnable Ecto.Migration DSL when ecto_migrations_exs |
| 432 | `WebParamFinalFix` | `absolute-final` | `phoenix` | `absolute-final.phoenix` | source order | Guarantee def-head and anon-fn binder/body agreement in Web/Live modules (pins-aware) |
| 433 | `HandleInfoUnderscoreSocketFix_Final` | `absolute-final` | `liveview` | `absolute-final.liveview` | source order | Rewrite _socket refs to socket and alias assignments to discard in handle_info/2 |
| 434 | `UnderscoreToParamSocketFix_Final` | `absolute-final` | `core` | `absolute-final.core` | source order | In defs with socket param, replace _socket -> socket and alias `x = _socket` -> `_ = socket` |
| 435 | `CaseUnderscoreBinderPromote_Final` | `absolute-final` | `core` | `absolute-final.core` | source order | Promote tuple second-element binder _x -> x (when used) and rewrite body references (disabled for snapshot parity) |
| 436 | `ClosureSelfRebindDiscard_Final` | `absolute-final` | `core` | `absolute-final.core` | source order | In anon fns, rewrite binder rebinding to discard (_ = expr) |
| 437 | `HandleEventGroupingReorder` | `absolute-final` | `liveview` | `absolute-final.liveview` | source order | Group def handle_event/3 clauses and place catch-all immediately after event clauses |
| 438 | `SelfCompareToParamFix` | `absolute-final` | `core` | `absolute-final.core` | source order | Rewrite (t.id != t) and (t != t) to compare against id/_id function param |
| 439 | `ListUpdateAndFilterFix` | `absolute-final` | `core` | `absolute-final.core` | source order | Repair map-then-replace and filter-remove-by-id logic patterns (absolute final) |
| 440 | `UnderscoreParamPromotion_Final` | `absolute-final` | `core` | `absolute-final.core` | source order | Promote underscored parameters to base names when referenced in body and no conflict exists |
| 441 | `HandleInfoSomeClauseNormalize_Final` | `absolute-final` | `liveview` | `absolute-final.liveview` | after: WebParamFinalFix, ListUpdateAndFilterFix, UnderscoreParamPromotion_Final, GlobalNumericSentinelCleanup, DropStandaloneLiteralOne | Normalize {:some, b} clause: drop leading alias, promote binder, and fix noreply payload |
| 442 | `ClauseUnderscoreUsedPromote` | `absolute-final` | `core` | `absolute-final.core` | source order | If clause body uses underscored binder (_v), rename pattern binder and body refs to base (v) |
| 443 | `ClauseUndefinedVarBindToBinder_Final` | `absolute-final` | `core` | `absolute-final.core` | source order | (absolute final) Prefix-bind u=binder when clause body uses a single undefined local u (disabled here; re-added later for ordering) |
| 444 | `CaseTupleBinderUnshadow_PreFinal` | `absolute-final` | `core` | `absolute-final.core` | source order | Rename tuple binder colliding with function arg to 'value' and, if exactly one undefined lower-case var exists in body, prefix-bind it to value (pre-final) |
| 445 | `NestedCaseTupleUnshadow_PreFinal` | `absolute-final` | `core` | `absolute-final.core` | source order | When clause body starts with case V do {:tag, V} -> ..., rename to {:tag, value} and prefix-bind sole undefined local to value |
| 446 | `CaseClauseAliasFromUnderscoreBinder` | `absolute-final` | `core` | `absolute-final.core` | source order | Prefix‑bind undefined local u to its underscored pattern binder _u inside case clause bodies |
| 447 | `ClauseUndefinedVarBindToBinder_Replay_Final` | `absolute-final` | `core` | `absolute-final.core` | source order | Replay ultra-final: prefix-bind sole undefined local to the (now unshadowed) binder |
| 448 | `CaseClauseCamelAliasToSnakeBinder` | `absolute-final` | `core` | `absolute-final.core` | source order | Prepend camelCase=snake aliases for clause bodies when pattern binds snake and body references only camel |
| 449 | `DropSelfAssignNoop` | `absolute-final` | `core` | `absolute-final.core` | source order | Remove no-op self assignments v = v in clause bodies (late) |
| 450 | `HeexAssignsBindRepair` | `absolute-final` | `hxx` | `absolute-final.hxx` | source order | Convert `_ = Phoenix.Component.assign(assigns, map)` back to `assigns = ...` in render/1 |
| 451 | `TempAliasChainRepair` | `absolute-final` | `core` | `absolute-final.core` | source order | Fix use-before-assign chains involving thisN temps by dropping the temp and assigning the final RHS |
| 452 | `HeexEventNameNormalization` | `absolute-final` | `hxx` | `absolute-final.hxx` | source order | Normalize phx-* event attribute values to lowercase snake_case; validate & warn on invalid names |
| 453 | `RepoCaseBinderNormalize` | `absolute-final` | `ecto` | `absolute-final.ecto` | source order | Normalize {:ok, binder} binder names for Repo.delete cases: g3/s2 → deleted/_deleted |
| 454 | `RepoDeleteCaseArgRestore` | `absolute-final` | `ecto` | `absolute-final.ecto` | source order | Inside case Repo.delete, rewrite (binder, socket) helper calls to (id, socket) |
| 455 | `PresenceModuleFix` | `absolute-final` | `liveview` | `absolute-final.liveview` | source order | Underscore unused params and normalize trivial presence helpers to return `socket` |
| 456 | `LiveMountReturnFinalize` | `absolute-final` | `liveview` | `absolute-final.liveview` | source order | Ensure mount/3 ends with {:ok, socket}; assign assigns inline when present |
| 457 | `SplitChainedAssignments_AbsoluteFinal` | `absolute-final` | `core` | `absolute-final.core` | source order | (absolute final) Split a = b = expr into two statements (blocks/do/fn bodies) |
| 458 | `VarRefSuffixParamNormalize_AbsoluteFinal` | `absolute-final` | `core` | `absolute-final.core` | source order | Absolute-final: map short refs to a unique param that ends with _<short> (e.g., query -> search_query) |
| 459 | `DowncaseAssignLhsNormalize_AbsoluteFinal` | `absolute-final` | `core` | `absolute-final.core` | source order | Absolute-final: normalize malformed LHS String.downcase(p) = String.downcase(p) to p = String.downcase(p) |
| 460 | `CaseOkBinderPrefixBindAllUndefined_AbsoluteFinal` | `absolute-final` | `core` | `absolute-final.core` | source order | Absolute-final: in {:ok, binder} clauses, prefix-bind all undefined simple locals to binder |
| 461 | `CaseSuccessVarRenameCollisionFix_AbsoluteFinal` | `absolute-final` | `core` | `absolute-final.core` | source order | Absolute-final: rename {:ok, var} binder when it collides with function args (e.g., socket) |
| 462 | `CaseOkBinderPrefixBindAllUndefined_Replay_AbsoluteFinal` | `absolute-final` | `core` | `absolute-final.core` | source order | Absolute-final replay: after binder collision renames, prefix-bind all undefined locals to {:ok, binder} |
| 463 | `UndefinedRefInlineDiscardedMapGet_Final` | `absolute-final` | `core` | `absolute-final.core` | source order | Inline EVar(camel) to Map.get(_, "snake") when only discarded fetch exists earlier |
| 464 | `LocalCamelToSnakeDecl_Final` | `absolute-final` | `core` | `absolute-final.core` | source order | Re-apply local camelCase→snake_case renames post event synthesis |
| 465 | `HandleInfoReturnSocketNormalize_Final` | `absolute-final` | `liveview` | `absolute-final.liveview` | source order | In handle_info/2, ensure helper calls end with socket and {:noreply, socket} shapes |
| 466 | `HandleEventToggleKeyExtract_Final` | `absolute-final` | `liveview` | `absolute-final.liveview` | source order | For handle_event("toggle_*"), replace helper first arg `params` with Map.get(params, key) |
| 467 | `HandleEventParamRepair_Final` | `absolute-final` | `liveview` | `absolute-final.liveview` | source order | Repair handle_event/3: turn discarded Map.get into named binds and insert any missing binds |
| 468 | `ClauseSuccessBinderTupleSecondBind_Final` | `absolute-final` | `core` | `absolute-final.core` | source order | Prefix-bind tuple second element var to {:ok, binder} within clause bodies |
| 469 | `SuccessBinderPrefixMostUsedUndefined_Final` | `absolute-final` | `core` | `absolute-final.core` | source order | (absolute final) In {:ok, binder} clauses, prefix-bind the most-frequent undefined var to binder |
| 470 | `LocalUnderscoreGenericPromotion_UltraFinal` | `absolute-final` | `core` | `absolute-final.core` | after: SuccessBinderPrefixMostUsedUndefined_Final | Ultra-final replay: promote underscored local binders when referenced (late shapes) |
| 471 | `UpgradeWildcardMapGetToNamed_Final` | `absolute-final` | `core` | `absolute-final.core` | source order | Rewrite `_ = Map.get(params, "key")` to `key = Map.get(params, "key")` (enables VarNameNormalization) |
| 472 | `DebugDumpMainBody` | `absolute-final` | `core` | `absolute-final.core` | source order | Debug-only: print Main.main body AST when -D debug_case_hoist is set |
| 473 | `InterpolationInspectMapGetSimplify` | `absolute-final` | `core` | `absolute-final.core` | source order | Rewrite inspect(Map.get(obj, :field)) to obj.field |
| 474 | `ReduceWhileIfAssignmentNormalize` | `absolute-final` | `core` | `absolute-final.core` | source order | Inside Enum.reduce_while EFns, rewrite a=(b=expr); if ... else b → b=expr; a=if ... |
| 475 | `CaseScrutineeHoist` | `absolute-final` | `core` | `absolute-final.core` | source order | Hoist case parse_*(args) scrutinee to parsed_result = parse_*(args); case parsed_result do |
| 476 | `CaseScrutineeHoist_Final` | `absolute-final` | `core` | `absolute-final.core` | source order | Absolute final: replay hoist of case parse_* scrutinee |
| 477 | `CaseUnderscoreCaseHoistBlock_Final` | `absolute-final` | `core` | `absolute-final.core` | source order | Absolute final: convert `_ = case <call>` to named var + case in blocks |
| 478 | `CaseUnderscoreAssignHoistAny_Final` | `absolute-final` | `core` | `absolute-final.core` | source order | Ultra-final: rewrite `_ = case <scrut>` into named assignment + case |
| 479 | `DoubleAssignIfFold_Final` | `absolute-final` | `core` | `absolute-final.core` | source order | Ultra-final: normalize chained assign + trailing if into two linear assigns |
| 480 | `AssignIfFoldInRhs_Final` | `absolute-final` | `core` | `absolute-final.core` | source order | Ultra-final: fold a = (b=rhs; if … else b) into b=rhs; a=if … else b |
| 481 | `AssignChainGenericSimplify_Final` | `absolute-final` | `core` | `absolute-final.core` | source order | Ultra-final: split a = (b = rhs) into b = rhs; a = b |
| 482 | `AssignmentIfElseCombine_Final` | `absolute-final` | `core` | `absolute-final.core` | source order | Ultra-final: combine `a = b; if ... else b` into `a = if ... else b` |
| 483 | `AssignAliasIfPromote_Final` | `absolute-final` | `core` | `absolute-final.core` | source order | Ultra-final: promote a=b; if cond(a) … else b -> a=if cond(b) … |
| 484 | `SplitChainAssign_Final` | `absolute-final` | `core` | `absolute-final.core` | source order | Ultra-final: split a=(b=rhs) into b=rhs; a=b |
| 485 | `ReduceWhileThenBranchNormalize_Final` | `absolute-final` | `core` | `absolute-final.core` | source order | Ultra-final: normalize then-branch windows a=(b=rhs); if ... else b |
| 486 | `SuccessBinderAlignByBodyUse_Final` | `absolute-final` | `core` | `absolute-final.core` | source order | Ultra-final: rename {:ok, binder} to the single undefined body var (usage-driven) |
| 487 | `SwitchReturnSanitizer_Final` | `absolute-final` | `core` | `absolute-final.core` | source order | Ultra-final: ensure tail return inlines prior case alias |
| 488 | `ChainAssignIfPromote_Final` | `absolute-final` | `core` | `absolute-final.core` | source order | Ultra-final: promote a=(b=rhs); if ... else b → b=rhs; a=if ... else b |
| 489 | `HandleEventWrapperFinalRepair` | `absolute-final` | `liveview` | `absolute-final.liveview` | source order | Ultra-final: ensure helper calls use (params, socket) and inline missing locals from params |
| 490 | `HandleEventCamelRefInlineFromParams_Final` | `absolute-final` | `liveview` | `absolute-final.liveview` | source order | Absolute final: inline camelCase refs in handle_event/3 from params (snake key, id int conversion) |
| 491 | `HandleEventArg0FromParamsId_UltraFinal` | `absolute-final` | `liveview` | `absolute-final.liveview` | source order | Ultra-final: rewrite helper(arg0=params, ..., socket) to pass id extracted from params |
| 492 | `SuccessBinderAlignByBodyUse_Replay_Final` | `absolute-final` | `core` | `absolute-final.core` | source order | Replay ultra-final: align {:ok, binder} to single undefined body var after collision fix |
| 493 | `CaseScrutineeVarToTupleBinder_Replay_Final` | `absolute-final` | `core` | `absolute-final.core` | source order | Replay ultra-final: rewrite EVar(scrutinee) → EVar(binder) inside case clause bodies |
| 494 | `CaseTupleBinderUnshadow_Final` | `absolute-final` | `core` | `absolute-final.core` | source order | Final pass: rename tuple binder colliding with function arg to 'value' and prefix-bind most-used undefined local |
| 495 | `HandleInfoReturnSocketNormalize_UltraFinal` | `absolute-final` | `liveview` | `absolute-final.liveview` | source order | Ultra-final: in handle_info/2, rewrite calls with duplicated first/last arg to end with socket |
| 496 | `CaseOkBinderPrefixBindAllUndefined_Replay2_UltraFinal` | `absolute-final` | `core` | `absolute-final.core` | source order | Ultra-final replay: prefix-bind any remaining undefineds in {:ok, binder} clauses |
| 497 | `DebugScanAssignChains` | `absolute-final` | `core` | `absolute-final.core` | source order | Debug-only: scan and print nested assignment chains |
| 498 | `DebugDumpReduceWhileEFn` | `absolute-final` | `core` | `absolute-final.core` | source order | Debug-only: dump reduce_while EFn clause bodies |
| 499 | `CaseAtomPatternTupleNormalize_Final` | `absolute-final` | `core` | `absolute-final.core` | source order | Absolute final: normalize sibling :tag patterns to {:tag} when tuple tag patterns exist |
| 500 | `CaseListGuardToCons_Replay_Final` | `absolute-final` | `core` | `absolute-final.core` | source order | Absolute final replay: [] with non-empty guard → [head\|tail] |
| 501 | `ListGuardIndexToHead_Replay_Final` | `absolute-final` | `core` | `absolute-final.core` | source order | Absolute final replay: list[0]→head; length(list)>1→tail!=[] in cons clauses |
| 502 | `CaseOkBinderPrefixBindAllUndefined_Replay_Last` | `absolute-final` | `core` | `absolute-final.core` | source order | Last: prefix-bind any remaining undefineds in {:ok, binder} clauses (conservative) |
| 503 | `ChainAssignIfPromote_Replay_Last` | `absolute-final` | `core` | `absolute-final.core` | source order | Last: promote chained assign + if window in any block/do |
| 504 | `MountParamsUltraFinal` | `absolute-final` | `liveview` | `absolute-final.liveview` | after: ChainAssignIfPromote_Replay_Last | Ensure mount/3 uses `params` as first arg and align body refs (absolute-final) |
| 505 | `MountBodyAlignToHead_Final` | `absolute-final` | `liveview` | `absolute-final.liveview` | after: MountParamsUltraFinal, MountParamsPromote | Align body references (params/_params) to mount/3 head binder (absolute-final) |
| 506 | `HandleEventParamsUltraFinal` | `absolute-final` | `liveview` | `absolute-final.liveview` | after: MountParamsUltraFinal | Ensure handle_event/3 uses `params` as second arg and align body refs (absolute-final) |
| 507 | `HandleEventBodyAlignToHead_Final` | `absolute-final` | `liveview` | `absolute-final.liveview` | after: HandleEventParamsUltraFinal | Align body references (params/_params) to handle_event/3 head binder (absolute-final) |
| 508 | `ParamUnderscoreArgRefAlign_Final` | `absolute-final` | `core` | `absolute-final.core` | after: HandleEventParamsUltraFinal, MountParamsUltraFinal | Final sweep: rewrite `_params` to `params` in bodies of defs that have a `params` arg (after promotions) |
| 509 | `ParamUnderscoreGlobalAlign_Final` | `absolute-final` | `core` | `absolute-final.core` | after: ParamUnderscoreArgRefAlign_Final | Absolute final safety: rewrite `_params` to `params` inside handle_event/3 and mount/3 bodies |
| 510 | `DropInvalidMapGetSelfAssign_Final` | `absolute-final` | `core` | `absolute-final.core` | after: ParamUnderscoreGlobalAlign_Final, HandleEventParamsUltraFinal, MountParamsUltraFinal | Absolute final: remove Map.get(params, key) = Map.get(params, key) statements in defs |
| 511 | `MountSessionExtractCleanup_Final` | `absolute-final` | `liveview` | `absolute-final.liveview` | after: DropInvalidMapGetSelfAssign_Final | Absolute final: drop `session = Map.get(params, "session")` inside mount/3 |
| 512 | `ControllerLocalUnusedUnderscore_Final` | `absolute-final` | `phoenix` | `absolute-final.phoenix` | after: MountSessionExtractCleanup_Final | Final replay: underscore unused local assignment binders in controllers |
| 513 | `ConcatSelfAssignBinderUnderscore_Final` | `absolute-final` | `core` | `absolute-final.core` | after: ControllerLocalUnusedUnderscore_Final | Rewrite `x = Enum.concat(x, ...)` → `_x = Enum.concat(x, ...)` in blocks |
| 514 | `EctoQueryBranchSelfAssignUnderscore_Final` | `absolute-final` | `ecto` | `absolute-final.ecto` | after: ControllerLocalUnusedUnderscore_Final | Absolute final replay: underscore trailing self-assign where/3 in branches |
| 515 | `AssignWhereSelfBinderUnderscore_Final` | `absolute-final` | `core` | `absolute-final.core` | after: EctoQueryBranchSelfAssignUnderscore_Final | Absolute final replay: rewrite `x = Ecto.Query.where(x, ...)` to `_x = ...` everywhere |
| 516 | `HandleEventParamsForceBodyRewrite_Final` | `absolute-final` | `liveview` | `absolute-final.liveview` | after: ParamUnderscoreGlobalAlign_Final, DropInvalidMapGetSelfAssign_Final, MountSessionExtractCleanup_Final, EctoQueryBranchSelfAssignUnderscore_Final, AssignWhereSelfBinderUnderscore_Final | Absolute final: force `_params` → `params` inside handle_event/3 bodies |
| 517 | `EctoRepoFinalArgFromLatestQueryVar` | `absolute-final` | `ecto` | `absolute-final.ecto` | after: AssignWhereSelfBinderUnderscore_Final | Rewrite Repo.*(query) to use last refinement binder when present in the same block |
| 518 | `EctoRepoArgModuleQualify_Final` | `absolute-final` | `ecto` | `absolute-final.ecto` | after: EctoRepoFinalArgFromLatestQueryVar | Qualify schema arg in Repo.get/one to <App>.<Name> when bare CamelCase is used |
| 519 | `HeexAssignsParamRename_Final` | `absolute-final` | `hxx` | `absolute-final.hxx` | after: AssignWhereSelfBinderUnderscore_Final | Absolute final safety: rename _assigns → assigns when ~H is present in body |
| 520 | `DefParamHeadUnderscoreWhenUnused_Final` | `absolute-final` | `core` | `absolute-final.core` | after: MountBodyAlignToHead_Final, MountSessionExtractCleanup_Final, HandleEventParamsForceBodyRewrite_Final | Rename params→_params in mount/3 & handle_event/3 when body does not reference params |
| 521 | `HandleEventParamsUltraFinal_Last` | `absolute-final` | `liveview` | `absolute-final.liveview` | after: DefParamHeadUnderscoreWhenUnused_Final, DropInvalidMapGetSelfAssign_Final, MountSessionExtractCleanup_Final, EctoRepoFinalArgFromLatestQueryVar, AssignWhereSelfBinderUnderscore_Final | Last guard: if body uses _params, set head to params and rewrite body |
| 522 | `PresenceConcatAccumulatorInit` | `absolute-final` | `liveview` | `absolute-final.liveview` | after: HeexTrimTrailingBlankLines_Final, HeexCollapseOverEscapedQuotes_Final, ParamUnderscoreGlobalAlign_Final, HandleEventParamsForceBodyRewrite_Final, HandleEventParamsUltraFinal_Last | Insert acc=[] when Enum.concat(acc, [...]) appears without prior definition (Presence only) |
| 523 | `PresenceReduceWhileAccumulatorRepair` | `absolute-final` | `liveview` | `absolute-final.liveview` | after: PresenceConcatAccumulatorInit, HeexTrimTrailingBlankLines_Final, HeexCollapseOverEscapedQuotes_Final, ParamUnderscoreGlobalAlign_Final, HandleEventParamsForceBodyRewrite_Final, HandleEventParamsUltraFinal_Last | Inject acc=[] and return acc for reduce_while loops missing initialization (Presence only) |
| 524 | `NilUnderscoreAssignGlobal_AbsoluteFinal` | `absolute-final` | `core` | `absolute-final.core` | after: CaseClauseHygieneCleanup_Final, CaseNilAssignCleanup_Final, ControllerAliasAssignDrop_Replay_Ultimate, SuccessVarAbsoluteReplaceUndefined_Replay_Final, HandleEventParamsUltraFinal_Last | Absolute-final: remove `nil = _var` (and :nil) assignments anywhere in bodies |
| 525 | `ControllerJsonFinalize_AbsoluteFinal` | `absolute-final` | `phoenix` | `absolute-final.phoenix` | after: WebJsonCallAliasRewrite_AbsoluteFinal, ControllerAliasAssignDrop_Replay_Ultimate, ControllerResultBinderNormalize_Final, ControllerCaseRenameBinderIfBodyRefsBase_Final, ControllerJsonDataArgToBinder_Final, ControllerJsonDataArgPickSingleVar_Final, HandleEventParamsUltraFinal_Last | Absolute-last: in controllers, map json(conn, data) arg2 to case binder and drop alias lines |
| 526 | `WebDropAliasAssign_Ultimate` | `absolute-final` | `phoenix` | `absolute-final.phoenix` | after: ControllerJsonFinalize_AbsoluteFinal, ControllerAliasAssignDrop_Replay_Ultimate | Ultimate: drop alias assigns to json/data/conn in Web.* modules |
| 527 | `WebAliasAssignUnderscore_Ultimate` | `absolute-final` | `phoenix` | `absolute-final.phoenix` | after: WebDropAliasAssign_Ultimate | Ultimate: rewrite json/data/conn alias binders to underscored variants in Web.* |
| 528 | `WebJsonSecondArgRewrite_Ultimate` | `absolute-final` | `phoenix` | `absolute-final.phoenix` | after: WebDropAliasAssign_Ultimate, WebAliasAssignUnderscore_Ultimate, ControllerJsonFinalize_AbsoluteFinal | Ultimate: rewrite Phoenix.Controller.json(conn, data\|json) to binder/value in Web.* |
| 529 | `OkValueGlobalCleanup_Replay_Ultimate` | `absolute-final` | `core` | `absolute-final.core` | after: WebJsonSecondArgRewrite_Ultimate, FinalLocalReferenceAlign | Ultimate replay: rewrite ok_value->value and _g->g when only value/g are declared (def/defp and EFn) |
| 530 | `ControllerJsonSecondArgUndefinedRewrite_Ultimate` | `absolute-final` | `phoenix` | `absolute-final.phoenix` | after: WebJsonSecondArgRewrite_Ultimate, ControllerAliasAssignDrop_Replay_Ultimate | Ultimate: in controllers, if json(conn, data) remains with undefined `data`, rewrite to binder/safe expr |
| 531 | `CaseBinderRefNormalizeByFlattenUnderscores_Final` | `absolute-final` | `core` | `absolute-final.core` | after: ControllerJsonSecondArgUndefinedRewrite_Ultimate, ControllerJsonFinalize_AbsoluteFinal | Unify clause body refs that flatten to the binder name (remove underscores) |
| 532 | `FunctionArgMultiStmtIIFE_Final` | `absolute-final` | `core` | `absolute-final.core` | after: CaseBinderRefNormalizeByFlattenUnderscores_Final | Wrap multi-statement argument blocks in IIFE: (fn -> ... end).() |
| 533 | `ExUnitAssert_Final` | `absolute-final` | `exunit` | `absolute-final.exunit` | after: FunctionArgMultiStmtIIFE_Final | Rewrite Assert.* to ExUnit assert/refute/assert_raise/etc inside ExUnit modules |
| 534 | `AssertArgIIFE_Final` | `absolute-final` | `exunit` | `absolute-final.exunit` | after: ExUnitAssert_Final | Wrap Assert.is_true/false first arg in IIFE when complex (assignments/case) |
| 535 | `StringIndexOf_Normalize_Final` | `absolute-final` | `core` | `absolute-final.core` | after: AssertArgIIFE_Final | Rewrite str.indexOf(sub) >= 0 to :binary.match(str, sub) != :nomatch |
| 536 | `BinaryMatchCaseArgNormalize_Final` | `absolute-final` | `core` | `absolute-final.core` | after: StringIndexOf_Normalize_Final, FunctionArgMultiStmtIIFE_Final | Normalize arg blocks: (v = expr; case :binary.match(v, sub) ...) >= 0 → :binary.match(expr, sub) != :nomatch |
| 537 | `InlinePrevAssignIntoArg_Final` | `absolute-final` | `core` | `absolute-final.core` | after: BinaryMatchCaseArgNormalize_Final | Inline `v = expr` into next call arg if it compares case :binary.match(v, sub) |
| 538 | `MountParamsSideEffectAssignDiscard_Final` | `absolute-final` | `liveview` | `absolute-final.liveview` | after: MountSessionExtractCleanup_Final, ParamUnderscoreArgRefAlign_Final, ParamUnderscoreGlobalAlign_Final, MountBodyAlignToHead_Final, HandleEventParamsUltraFinal, HandleEventParamsUltraFinal_Last, HandleEventBodyAlignToHead_Final, DefParamHeadUnderscoreWhenUnused_Final, EctoRepoFinalArgFromLatestQueryVar, EctoQueryBranchSelfAssignUnderscore_Final, AssignWhereSelfBinderUnderscore_Final | Drop head-binder reassignments of params in mount/3 when unused later |
| 539 | `LocalUnderscoreGenericPromotion` | `absolute-final` | `core` | `absolute-final.core` | after: ControllerLocalUnusedUnderscore_Final, MountParamsSideEffectAssignDiscard_Final, HandleEventBodyAlignToHead_Final, HandleEventParamsUltraFinal_Last | Promote any underscored local binder (_x) to x when referenced |
| 540 | `MountParamsUnusedReassignUnderscore_Final` | `absolute-final` | `liveview` | `absolute-final.liveview` | after: MountSessionExtractCleanup_Final, MountParamsSideEffectAssignDiscard_Final, ParamUnderscoreGlobalAlign_Final, HandleEventParamsUltraFinal_Last | Rename `params = ...` to `_` in mount/3 when unused later (preserve RHS) |
| 541 | `LocalAssignUnusedUnderscore_Scoped_Final` | `absolute-final` | `core` | `absolute-final.core` | after: EctoQueryBranchSelfAssignUnderscore_Final | Final (scoped): underscore local assigns not used later in defs except mount/3 |
| 542 | `ControllerLocalAssignUnusedUnderscore_Final` | `absolute-final` | `phoenix` | `absolute-final.phoenix` | after: LocalAssignUnusedUnderscore_Scoped_Final | In conn actions, underscore unused local assignment binders |
| 543 | `AlignBaseRefToUnderscoredBinder_Final` | `absolute-final` | `core` | `absolute-final.core` | after: LocalAssignUnusedUnderscore_Scoped_Final | Rewrite base name refs to existing underscored local binders in the same block |
| 544 | `LocalUnderscoreBinderPromotionWhenUsed_Final` | `absolute-final` | `core` | `absolute-final.core` | after: AlignBaseRefToUnderscoredBinder_Final | Promote underscored local binders to base name when the underscored name is read later and base is free |
| 545 | `CaseDiscriminantTempNormalize` | `absolute-final` | `core` | `absolute-final.core` | after: LocalAssignUnusedUnderscore_Scoped_Final, AlignBaseRefToUnderscoredBinder_Final, LocalUnderscoreBinderPromotionWhenUsed_Final, FinalLocalReferenceAlign | Rewrite case discriminant to match preceding assignment modulo leading underscore |
| 546 | `DefParamUsedBaseNamePromotion_Final` | `absolute-final` | `core` | `absolute-final.core` | after: ParamUnderscoreArgRefAlign_Final, ParamUnderscoreGlobalAlign_Final, HandleEventParamsForceBodyRewrite_Final, DropInvalidMapGetSelfAssign_Final, MountSessionExtractCleanup_Final, EctoQueryBranchSelfAssignUnderscore_Final, AssignWhereSelfBinderUnderscore_Final, LocalAssignUnusedUnderscore_Scoped_Final | Promote underscored def params to base name when body uses base name (absolute final) |
| 547 | `HandleEventParamsHeadToParams_Final` | `absolute-final` | `liveview` | `absolute-final.liveview` | after: HandleEventParamsUltraFinal_Last, LocalAssignUnusedUnderscore_Scoped_Final, ParamUnderscoreArgRefAlign_Final, ParamUnderscoreGlobalAlign_Final, HandleEventParamsForceBodyRewrite_Final | Absolute-final: force handle_event/3 second arg to params when referenced; rewrite _params to params in body |
| 548 | `DropUnusedPureUnderscoreAssign_AbsoluteFinal` | `absolute-final` | `core` | `absolute-final.core` | after: LocalAssignUnusedUnderscore_Scoped_Final | Drop non-final unused `_name = <pure literal/container>` assignments |
| 549 | `ParamUnderscoreArgRefAlign_Global_Final` | `absolute-final` | `core` | `absolute-final.core` | after: DefParamHeadUnderscoreWhenUnused_Final, HeexAssignsParamRename_Final | Final replay: align body refs (v→_v) when head params are underscored |
| 550 | `CaseClauseSuccessBodyBinderRewrite_AbsoluteLast` | `absolute-final` | `core` | `absolute-final.core` | after: NilUnderscoreAssignGlobal_AbsoluteFinal, FinalLocalReferenceAlign, ParamUnderscoreArgRefAlign_Global_Final | Absolute-last: in {:ok,binder} clauses, rewrite ok_value/ok_<binder> refs in bodies to binder |
| 551 | `OkValueGlobalCleanup_AbsoluteLast` | `absolute-final` | `core` | `absolute-final.core` | after: WebAliasAssignUnderscore_Ultimate, ControllerJsonSecondArgUndefinedRewrite_Ultimate, CaseBinderRefNormalizeByFlattenUnderscores_Final, FunctionArgMultiStmtIIFE_Final, AssertArgIIFE_Final, StringIndexOf_Normalize_Final, BinaryMatchCaseArgNormalize_Final, ParamUnderscoreArgRefAlign_Global_Final | Absolute-last: rewrite ok_value->value and _g->g when only value/g are declared (def/defp and EFn) |
| 552 | `CaseDiscriminantTempNormalize_Replay_AbsoluteLast` | `absolute-final` | `core` | `absolute-final.core` | after: CaseClauseSuccessBodyBinderRewrite_AbsoluteLast, OkValueGlobalCleanup_AbsoluteLast, FinalLocalReferenceAlign, ParamUnderscoreArgRefAlign_Global_Final | Absolute-last replay: rewrite case discriminant to match nearest prior assignment modulo underscore |
| 553 | `HandleEventMapGetUnderscoreParams_Final` | `absolute-final` | `liveview` | `absolute-final.liveview` | after: HandleEventParamsHeadToParams_Final, HandleEventParamsUltraFinal_Last | Absolute-last: rewrite Map.get(_params, key) → Map.get(params, key) in handle_event/3 bodies |
| 554 | `AssignMultipleNormalize_Final` | `absolute-final` | `core` | `absolute-final.core` | after: HandleEventMapGetUnderscoreParams_Final | Rewrite left = (assigns = map); Phoenix.Component.assign(socket, assigns) → left = Phoenix.Component.assign(socket, map) |
| 555 | `HandleInfoUnderscoreBinderPromote_Final` | `absolute-final` | `liveview` | `absolute-final.liveview` | after: HandleInfoUnderscoreSocketFix_Final, HandleInfoReturnSocketNormalize_Final | Promote {:some, _x} binder to payload in handle_info/2 and rewrite refs |
| 556 | `LocalAssignDiscardIfUnused_LiveView_Final` | `absolute-final` | `liveview` | `absolute-final.liveview` | after: ListUpdateAndFilterFix, WebParamFinalFix, HandleEventParamRepair_Final | In <App>Web.Live modules, replace unused local assigns with `_ = expr` (final) |
| 557 | `IfBranchDowncaseTempInline_Final` | `absolute-final` | `core` | `absolute-final.core` | source order | Inline `_tmp = rhs; String.downcase(_tmp)` inside if/else branches |
| 558 | `HandleEventMapGetValueDefaultToParams_Final` | `absolute-final` | `liveview` | `absolute-final.liveview` | after: HandleEventParamsHeadToParams_Final, HandleEventParamsUltraFinal_Last, HandleEventMapGetUnderscoreParams_Final | In handle_event/3, rewrite Map.get(params\|_params, "value") → params\|_params (value is Haxe default, not a Phoenix key) |
| 559 | `MatchBlockRhsExtractLast_Final` | `absolute-final` | `core` | `absolute-final.core` | source order | Expand `pat = <block>` into block prefix statements + `pat = last_expr` (semantic fix) |
| 560 | `MapKeysIteratorReduceWhileRewrite` | `absolute-final` | `core` | `absolute-final.core` | after: ReduceWhileResultBinding, MatchBlockRhsExtractLast_Final | Rewrite iterator-driven reduce_while loops over Map.keys/1 into direct Enum.reduce_while |
| 561 | `CaseClauseUnusedBinderUnderscore_Final` | `absolute-final` | `core` | `absolute-final.core` | source order | In case clauses, underscore unused binders (absolute-final) |
| 562 | `CaseTupleMultiBinderPromoteByUse_Final` | `absolute-final` | `core` | `absolute-final.core` | source order | (final) Promote tuple binders _name -> name when used; second pass to catch late changes |
| 563 | `HandleInfoAliasAndNoreply_AbsoluteFinal` | `absolute-final` | `liveview` | `absolute-final.liveview` | after: HandleInfoReturnSocketNormalize_Final, UnderscoreToParamSocketFix_Final, HandleInfoUnderscoreSocketFix_Final | Absolute-final: in handle_info/2, drop leading alias to socket and rewrite {:noreply, _socket} → {:noreply, socket} |
| 564 | `FinalUnderscoreRepair` | `absolute-final` | `core` | `absolute-final.core` | after: HandleInfoAliasAndNoreply_AbsoluteFinal | Absolute-final: repair underscore-prefixed variables that are actually used (Phase 1.3 of 1.0 roadmap) |
| 565 | `CaseBinderUnderscoreAlign_AbsoluteFinal_Replay` | `absolute-final` | `core` | `absolute-final.core` | after: FinalUnderscoreRepair | Absolute-final replay: align underscored case binders with body references (avoid undefined vars) |
| 566 | `PhoenixComponentModuleNormalize_AbsoluteLast` | `absolute-final` | `hxx` | `absolute-final.hxx` | after: CaseBinderUnderscoreAlign_AbsoluteFinal_Replay | Absolute-last: rewrite Component.assign/assign_new/update to Phoenix.Component |
| 567 | `HeexEnsureAssignsForNestedSigils` | `absolute-final` | `hxx` | `absolute-final.hxx` | after: PhoenixComponentModuleNormalize_AbsoluteLast | Absolute-last: insert local assigns map for ~H helpers without assigns param |
| 568 | `HeexAssignsLocalVarRename_AbsoluteLast` | `absolute-final` | `hxx` | `absolute-final.hxx` | after: HeexEnsureAssignsForNestedSigils | Absolute-last: rename _assigns → assigns inside function bodies containing ~H |
| 569 | `EnumEachEarlyReturnTrailingNilCleanup_AbsoluteLast` | `absolute-final` | `core` | `absolute-final.core` | after: HeexAssignsLocalVarRename_AbsoluteLast | Absolute-last: drop redundant trailing nil after reflaxe return-tagged reduce_while case |
| 570 | `EFnUnusedArgUnderscore_AbsoluteLast` | `absolute-final` | `core` | `absolute-final.core` | after: EnumEachEarlyReturnTrailingNilCleanup_AbsoluteLast | Absolute-last: underscore unused EFn binders to avoid warnings |
| 571 | `RemoteCallModuleAliasCaseNormalize_AbsoluteLast` | `absolute-final` | `core` | `absolute-final.core` | after: EFnUnusedArgUnderscore_AbsoluteLast | Absolute-last: normalize lowercase remote-call module targets to valid aliases |
| 572 | `PubSubModuleRewrite_AbsoluteLastReplay` | `absolute-final` | `core` | `absolute-final.core` | after: RemoteCallModuleAliasCaseNormalize_AbsoluteLast | Absolute-last: rewrite PubSub API calls back to Phoenix.PubSub after alias normalization |
| 573 | `CaseClauseUnusedBinderUnderscore_AbsoluteLastReplay` | `absolute-final` | `core` | `absolute-final.core` | after: PubSubModuleRewrite_AbsoluteLastReplay | Absolute-last: underscore unused case/with/receive binders (replay) |
| 574 | `ChangesetAssignedWildcardValidateCollapse_AbsoluteLast` | `absolute-final` | `ecto` | `absolute-final.ecto` | after: CaseClauseUnusedBinderUnderscore_AbsoluteLastReplay | Absolute-last: collapse assigned Ecto.Changeset validation wildcard wrappers |
| 575 | `DropSelfAssignNoop_AbsoluteLastReplay` | `absolute-final` | `core` | `absolute-final.core` | after: ChangesetAssignedWildcardValidateCollapse_AbsoluteLast | Absolute-last: remove no-op self-assignments v = v (replay) |
| 576 | `BareLiteralDrop_AbsoluteLast` | `absolute-final` | `core` | `absolute-final.core` | after: DropSelfAssignNoop_AbsoluteLastReplay | Absolute-last: remove non-final literal statements in EBlock/EDo |
