package reflaxe.elixir.ast.transformers.registry;
#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST; // makeAST, makeASTWithMeta
import reflaxe.elixir.ast.ElixirASTPrinter; // for debug prints in inline passes
import reflaxe.elixir.ast.ElixirASTTransformer; // qualify local pass fns
/**
 * ElixirASTPassRegistry
 *
 * WHAT
 * - Centralizes pass registration previously embedded in ElixirASTTransformer.alias_getEnabledPasses.
 *
 * WHY
 * - Keep ElixirASTTransformer under 2000 LOC; improve maintainability and ordering clarity.
 *
 * HOW
 * - Provides getEnabledPasses() returning the exact Array<PassConfig> as before.
 * - Uses fully qualified references to ElixirASTTransformer's local pass functions.
 */
class ElixirASTPassRegistry {
    public static function getEnabledPasses(): Array<ElixirASTTransformer.PassConfig> {

        var passes: Array<reflaxe.elixir.ast.ElixirASTTransformer.PassConfig> = [];

        // Phase: Early bootstrap (extracted to group, order preserved)
        passes = passes.concat(reflaxe.elixir.ast.transformers.registry.groups.EarlyBootstrap.build());
        
        // Module dependency requires pass (for standalone scripts)
        // NOTE: This is now handled directly in ModuleBuilder.generateRequireStatements
        // when building modules with static main() functions
        
        // Annotation-based transformation passes (MUST run first to set up module structure)
        passes.push({
            name: "PhoenixWebTransform",
            description: "Transform @:phoenixWeb modules into Phoenix Web helper module",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.AnnotationTransforms.phoenixWebTransformPass
        });
        
        passes.push({
            name: "EndpointTransform",
            description: "Transform @:endpoint modules into Phoenix.Endpoint structure",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.AnnotationTransforms.endpointTransformPass
        });
        
        passes.push({
            name: "LiveViewTransform",
            description: "Transform @:liveview modules into Phoenix.LiveView structure",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.AnnotationTransforms.liveViewTransformPass
        });

        // Bridge typed handleEvent(enum, socket) → handle_event/3 callbacks
        passes.push({
            name: "LiveViewTypedEventBridge",
            description: "Generate handle_event/3 clauses that map string events + params to typed enums and delegate to handleEvent/2",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.LiveViewTypedEventBridgeTransforms.transformPass
        });
        // Immediately normalize locals camel→snake and repair/extract handler params after event generation
        passes.push({
            name: "LocalCamelToSnakeDecl_AfterEventBridge",
            description: "Rename local camelCase→snake_case in newly generated handlers",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.LocalCamelToSnakeDeclTransforms.transformPass
        });
        passes.push({
            name: "HandleEventParamRepair_AfterEventBridge",
            description: "Repair handle_event/3 discarded Map.get and insert missing binds (shape-based)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.HandleEventParamRepairTransforms.transformPass
        });
        passes.push({
            name: "HandleEventParamExtractFromBodyUse_AfterEventBridge",
            description: "Extract undefined locals from params in handle_event/3 (shape-based)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.HandleEventParamExtractFromBodyUseTransforms.transformPass
        });
        
        passes.push({
            name: "PresenceTransform",
            description: "Transform @:presence modules into Phoenix.Presence structure",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.AnnotationTransforms.presenceTransformPass
        });
        
        // Phoenix/LiveView core group (order preserved)
        passes = passes.concat(reflaxe.elixir.ast.transformers.registry.groups.PhoenixLiveCore.build());
        
        // Phoenix/Ecto annotation-driven group (order preserved)
        passes = passes.concat(reflaxe.elixir.ast.transformers.registry.groups.PhoenixAnnotations.build());
        
        // Guard condition grouping pass (must run before other pattern transformations)
        passes.push({
            name: "GuardGrouping",
            description: "Transform multiple case clauses with same pattern and guards into cond",
            enabled: true,
            pass: function(ast) return ElixirASTTransformer.alias_guardGroupingPass(ast)
        });
        
        // Constant folding pass
        // Harmonize underscore binders with the sole undefined body var (usage-driven, generic)
        // Disabled: Caused incorrect rebinding when the “undefined” name was actually
        // a function parameter or outer binding (e.g., default_value), leading to
        // wrong semantics in regression/switch_return_sanitizer. Prefer body-side
        // replacement passes (ClauseUndefinedVarToBinder) which do not change pattern binders.
        passes.push({
            name: "PatternBindingHarmonize",
            description: "Rename underscore binder in clause pattern to body’s sole undefined local (disabled: scope ambiguity)",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.PatternBindingHarmonizeTransforms.transformPass
        });

        // Pre-interpolation: normalize list-builder args and wrap multi-statement args
        // so interpolation prints valid expressions (no raw statements inside #{}).
        passes.push({
            name: "JoinArgListBuilderToMapJoin_Pre",
            description: "Rewrite Enum.join(<block temp-builder>, sep) → Enum.map(..) |> Enum.join(sep) before interpolation",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.JoinArgListBuilderToMapJoinTransforms.transformPass
        });
        // Early: ensure (fn -> ... end).() is properly parenthesized
        passes.push({
            name: "EFnCallTargetParen",
            description: "Wrap anonymous function call targets in parentheses: (fn -> ... end).()",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EFnCallTargetParenTransforms.pass
        });
        // Early: rewrite case length(list) → case list with list patterns
        passes.push({
            name: "CaseLengthToListPattern",
            description: "Rewrite case length(list) do ... end → case list do [] | [head|tail] ... end",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseLengthToListPatternTransforms.pass
        });
        // Early repair: unshadow tuple binder when case scrutinee is a function arg
        passes.push({
            name: "CaseTupleBinderUnshadow",
            description: "For case over a function argument, rename tuple binder matching the arg to 'value' and prefix-bind most-used undefined local to that value",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseTupleBinderUnshadowTransforms.pass
        });
        // Early: avoid collisions between case binders and function argument names (e.g., socket)
        // SPECIALIZED REPAIR for LiveView handle_info must run BEFORE the generic
        // collision-avoid renamer so it can see the binder equal to the function arg
        // and fix helper calls (payload first, socket last) in the clause body.
        // Disabled: This pass risks app-specific name coupling by changing helper calls.
        // Fix binder collisions via generic binder/name passes only.
        passes.push({
            name: "HandleInfoCaseBinderCollisionRepair_Pre",
            description: "Repair {:tag, socket}-style binder collisions in handle_info/2; rewrite local helper arg order (payload first, socket last)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.HandleInfoCaseBinderCollisionRepairTransforms.transformPass
        });

        // After repair, map scrutinee var references to the tuple payload binder inside clauses
        passes.push({
            name: "CaseScrutineeVarToTupleBinder",
            description: "In case scrutinee do {:tag, binder} -> ..., rewrite body EVar(scrutinee) → EVar(binder)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseScrutineeVarToTupleBinderTransforms.transformPass
        });

        // Flatten nested case-of-binder to single case, merging tuple patterns and
        // substituting outer binder references with inner payload binder.
        passes.push({
            name: "CaseNestedTupleFlatten",
            description: "Flatten outer {:tag, v} → inner case v do {:tag2, b} into single case {:tag, {:tag2, b}}",
            // Disable by default for snapshot parity; limit flattening to explicit Option/Result pass.
            enabled: #if enable_case_nested_tuple_flatten false #else false #end,
            pass: reflaxe.elixir.ast.transformers.CaseNestedTupleFlattenTransforms.transformPass
        });

        // Then apply the generic binder-avoid transform which will now be a no-op
        // for handle_info clauses already repaired above.
        passes.push({
            name: "CaseBinderArgCollisionAvoid",
            description: "Rename colliding case binders that shadow function arguments (e.g., {:tag, socket} → {:tag, payload}) and rewrite body references",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseBinderArgCollisionAvoidTransforms.pass
        });
        // Early: parenthesize case/cond/with/if when used as a side of a binary condition in if/unless
        passes.push({
            name: "IfConditionBinaryCaseParen",
            description: "Wrap case/cond/with/if sides of binary if/unless conditions in parentheses",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.IfConditionBinaryCaseParenTransforms.pass
        });
        // Early hoist: move complex constructs from binary if/unless conditions to a prior binding
        passes.push({
            name: "IfConditionComplexHoist_Early",
            description: "Hoist case/cond/with/if from binary if/unless conditions (early)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.IfConditionComplexHoistTransforms.pass
        });
        // Align body refs to snake_case binders; un-ignore binders used via camelCase body refs
        passes.push({
            name: "CaseBodyCamelRefToSnakeBinder",
            description: "Rewrite camelCase free vars in case bodies to snake_case pattern binders; drop leading underscore on binders when used",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseBodyCamelRefToSnakeBinderTransforms.pass
        });
        // Hoist non-variable list scrutinee to a local name so guards/patterns can refer to it
        passes.push({
            name: "CaseListScrutineeHoist",
            description: "Hoist non-variable list case scrutinee to a local variable",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseListScrutineeHoistTransforms.pass
        });
        // When case-with-list appears as RHS of an assignment, hoist scrutinee before assignment
        passes.push({
            name: "CaseScrutineeHoistInAssign",
            description: "Hoist list/bitstring scrutinee for var = case ... end",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseScrutineeHoistInAssignTransforms.pass
        });
        // Guard + interpolation prelude (order preserved via group)
        passes = passes.concat(reflaxe.elixir.ast.transformers.registry.groups.CoreGuardsAndInterpolation.build());

        // Canonicalize unused second binders in two-tuple patterns to `_value` (generic, shape-based)
        passes.push({
            name: "CaseSecondBinderCanonicalUnderscore",
            description: "Rewrite {:tag, binder} to {:tag, _value} when binder is unused in body/guard (gated off; handled by canonicalize+alias)",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.CaseSecondBinderCanonicalUnderscoreTransforms.pass
        });

        // Enforce canonical payload + clause-local aliasing when body uses undefined locals
        passes.push({
            name: "CasePayloadCanonicalizeThenAlias",
            description: "Canonicalize {:tag, binder} -> {:tag, _value} and prepend `u = _value` aliases for undefined locals in body",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CasePayloadCanonicalizeThenAliasTransforms.pass
        });

        // Normalize bare calls in statement position to `_ = call(...)` (effects with unused result)
        passes.push({
            name: "BareCallToUnderscoreAssign",
            description: "Rewrite bare ECall/ERemoteCall statements to `_ = <call>`",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BareCallToUnderscoreAssignTransforms.pass
        });

        // HEEx/HXX prelude group (order preserved)
        passes = passes.concat(reflaxe.elixir.ast.transformers.registry.groups.HeexPrelude.build());
        
        // Normalize trivial IIFEs returning anonymous functions before further pipeline work
        passes.push({
            name: "InlineIIFEOfFunction",
            description: "Inline (fn -> (fn args -> body end) end).() to (fn args -> body end) (disabled pending full sweep)",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.IIFEInlineTransforms.pass
        });

        // Loop variable restoration pass (must run after string interpolation)
        passes.push({
            name: "LoopVariableRestore",
            description: "Restore loop variables in string interpolations (fixes Haxe optimizer issue)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.LoopVariableRestorer.restoreLoopVariablesPass
        });

        #if !disable_constant_folding
        passes.push({
            name: "ConstantFolding",
            description: "Fold constant expressions at compile time",
            enabled: true,
            pass: reflaxe.elixir.ast.ElixirASTTransformer.alias_constantFoldingPass
        });
        #end
        
        // Conditional reassignment pass (should run before pipeline optimization)
        passes.push({
            name: "ConditionalReassignment",
            description: "Convert conditional reassignments to functional style",
            enabled: true,
            pass: reflaxe.elixir.ast.ElixirASTTransformer.alias_conditionalReassignmentPass
        });
        
        // Remove redundant nil initialization pass (should run before pipeline optimization)
        passes.push({
            name: "RemoveRedundantNilInit",
            description: "Remove redundant nil initialization when variable is immediately reassigned",
            enabled: true,
            pass: reflaxe.elixir.ast.ElixirASTTransformer.alias_removeRedundantNilInitPass
        });
        
        // String method transformation pass (before pipeline optimization)
        // NOTE: Disabled because we now use String.cross.hx to generate idiomatic code directly
        // The .cross.hx pattern is better as it generates correct code from the start
        // rather than transforming it after the fact
        /*
        passes.push({
            name: "StringMethodTransform",
            description: "Convert string method calls to String module calls",
            enabled: true,
            pass: reflaxe.elixir.ast.ElixirASTTransformer.alias_stringMethodTransformPass
        });
        */
        
        // Pipeline optimization pass
        #if !disable_pipeline_optimization
        passes.push({
            name: "PipelineOptimization",
            description: "Convert sequential operations to pipeline",
            enabled: true,
            pass: reflaxe.elixir.ast.ElixirASTTransformer.alias_pipelineOptimizationPass
        });
        #end
        
        // Instance method transformation pass for standard library types
        passes.push({
            name: "InstanceMethodTransform",
            description: "Transform instance.method() to Module.function(instance) for stdlib types",
            enabled: true,
            pass: reflaxe.elixir.ast.ElixirASTTransformer.alias_instanceMethodTransformPass
        });

        // Normalize zero-arity Module.new() to struct literals (context-aware app prefix)
        passes.push({
            name: "ModuleNewToStructLiteral",
            description: "Rewrite Module.new() → %<App>.Module{} using module context to derive <App>",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ModuleNewToStructLiteral.moduleNewToStructLiteralPass
        });
        // Ensure struct module segments are in alias case (UpperCamel) to satisfy Elixir struct naming rules
        passes.push({
            name: "StructModuleCaseNormalize",
            description: "Normalize %Module{} segments to UpperCamel (e.g., %TodoApp.todo{} → %TodoApp.Todo{})",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.StructModuleCaseNormalizeTransforms.pass
        });
        // Promote underscored arg binders to base name when body uses base (prevents undefined refs)
        passes.push({
            name: "DefArgUnderscorePromoteByBodyUse",
            description: "Rename PVar(_name) arg to name when body references name and not _name",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.DefArgUnderscorePromoteByBodyUseTransforms.pass
        });
        passes.push({
            name: "ApplicationEnsureStartLink",
            description: "Ensure Application.start/2 appends Supervisor.start_link(children, opts)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ApplicationEnsureStartLinkTransforms.transformPass
        });
        // Override problematic Haxe DS modules with minimal native implementations
        // Disabled by default: overriding std DS modules is a band-aid and breaks tests.
        // If ever needed for a specific app, gate via a define and enable conditionally.
        passes.push({
            name: "StdDsOverrides",
            description: "Override haxe.ds BalancedTree/EnumValueMap modules with minimal Elixir implementations (disabled by default)",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.StdDsOverrideTransforms.transformPass
        });
        passes.push({
            name: "StdStringBufOverride",
            description: "Override StringBuf with native parts-list implementation",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.StdStringBufOverrideTransforms.transformPass
        });
        // Final re-run for app module qualification in Web contexts
        passes.push({
            name: "ModuleQualification",
            description: "Final Web-context qualification <App>.Module after all rewrites",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.moduleQualificationPass
        });
        
        // Array method transformations are handled in ElixirASTBuilder
        // at the TCall(TField(...)) pattern to generate idiomatic Elixir directly
        
        // Collections and loops group (order preserved)
        passes = passes.concat(reflaxe.elixir.ast.transformers.registry.groups.CollectionsAndLoops.build());
        
        // Immutability transformation pass
        #if !disable_immutability_transform
        passes.push({
            name: "ImmutabilityTransform",
            description: "Convert mutable patterns to immutable",
            enabled: true,
            pass: reflaxe.elixir.ast.ElixirASTTransformer.alias_immutabilityTransformPass
        });
        #end
        
        // Null coalescing inline transformation pass
        passes.push({
            name: "NullCoalescingInline",
            description: "Convert null coalescing blocks to inline expressions",
            enabled: true,
            pass: reflaxe.elixir.ast.ElixirASTTransformer.alias_nullCoalescingInlinePass
        });
        
        // Statement context transformation pass (MUST run after immutability)
        // Map iterator transformation pass was already registered earlier (line 413)
        
        #if !disable_statement_context_transform
        passes.push({
            name: "StatementContextTransform",
            description: "Add reassignments for immutable operations in statement context",
            enabled: false,
            pass: reflaxe.elixir.ast.ElixirASTTransformer.alias_statementContextTransformPass
        });
        #end
        
        // Self reference transformation pass (should run early)
        passes.unshift({
            name: "SelfReferenceTransform",
            description: "Convert self/this references to struct parameter",
            enabled: true,
            pass: reflaxe.elixir.ast.ElixirASTTransformer.alias_selfReferenceTransformPass
        });
        
        // Struct field assignment transformation pass
        passes.push({
            name: "StructFieldAssignmentTransform",
            description: "Convert struct field assignments to struct update syntax",
            enabled: true,
            pass: reflaxe.elixir.ast.ElixirASTTransformer.alias_structFieldAssignmentTransformPass
        });

        passes.push({
            name: "MapBuilderCollapse",
            description: "Replace Map.put builder blocks with literal maps",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.MapAndCollectionTransforms.mapBuilderCollapsePass
        });

        // Cleanup redundant temp alias assignments introduced during enum extraction
        // Rewrite case discriminant from temp alias (_g/g/gN) to original expression BEFORE alias cleanup
        passes.push({
            name: "DiscriminantRewrite",
            description: "Rewrite case on temp discriminant (_g) to case on original expression",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.DiscriminantRewriteTransforms.discriminantRewritePass
        });

        passes.push({
            name: "TempAliasCleanup",
            description: "Remove redundant temp alias assignments in statement contexts",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.TempVariableTransforms.tempAliasCleanupPass
        });

        // Ensure case discriminant uses the same temp variable as the preceding assignment (g vs _g)
        passes.push({
            name: "CaseDiscriminantTempNormalize",
            description: "Rewrite case discriminant to match preceding assignment modulo leading underscore",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseDiscriminantTempNormalizeTransforms.pass,
            runAfter: [
                "LocalAssignUnusedUnderscore_Scoped_Final",
                "AlignBaseRefToUnderscoredBinder_Final",
                "LocalUnderscoreBinderPromotionWhenUsed_Final",
                "DanglingBaseRefAlign_Final",
                "FinalLocalReferenceAlign"
            ]
        });

        // Collapse nested alias chains: lhs = alias = expr → lhs = expr (when alias unused later)
        passes.push({
            name: "AssignmentChainCleanup",
            description: "Collapse nested match alias chains to eliminate unused alias binders",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.AssignmentChainCleanupTransforms.transformPass
        });

        // Assignment extraction pass (must run before underscore cleanup)
        passes.push({
            name: "AssignmentExtraction",
            description: "Extract assignments from binary operations and other expression contexts",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.AssignmentExtractionTransforms.assignmentExtractionPass
        });

        // (DiscriminantRewrite already ran before alias cleanup)
        
        // Reduce while accumulator transformation (must run after assignment extraction)
        passes.push({
            name: "ReduceWhileAccumulator",
            description: "Fix variable shadowing in reduce_while loops by proper accumulator threading",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ReduceWhileAccumulatorTransform.reduceWhileAccumulatorPass
        });

        // Ensure reduce_while results are bound back to local accumulator variables
        passes.push({
            name: "ReduceWhileResultBinding",
            description: "Bind Enum.reduce_while result to original accumulator locals",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ReduceWhileResultBindingTransforms.bindReduceWhileResultPass
        });
        // Early chain assign normalization group (order preserved)
        passes = passes.concat(reflaxe.elixir.ast.transformers.registry.groups.AssignChainEarly.build());
        
        // Struct field update transformation (removes problematic field assignments)
        passes.push({
            name: "StructUpdateTransform",
            description: "Transform instance field assignments to avoid unused variable warnings",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.StructUpdateTransform.structUpdateTransformPass
        });

        // Fluent API struct update optimization
        passes.push({
            name: "FluentApiOptimization",
            description: "Optimize fluent API patterns to avoid unused struct assignments",
            enabled: true,
            pass: reflaxe.elixir.ast.ElixirASTTransformer.alias_fluentApiOptimizationPass
        });

        // Array length field to function transformation (must run early to fix field access)
        passes.push({
            name: "ArrayLengthFieldToFunction",
            description: "Transform array.length field access to length(array) function calls",
            enabled: true,
            pass: reflaxe.elixir.ast.ElixirASTTransformer.alias_arrayLengthFieldToFunctionPass
        });

        // DateTime method rewrite: now.to_iso8601() -> DateTime.to_iso8601(now)
        passes.push({
            name: "DateTimeMethodRewrite",
            description: "Rewrite method-style DateTime calls to module calls",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.DateTimeTransforms.dateTimeMethodRewritePass
        });
        
        // Tuple element field to function transformation (must run before enum pattern matching)
        passes.push({
            name: "TupleElemFieldToFunction",
            description: "Transform tuple.elem field access to elem(tuple, index) function calls",
            enabled: true,
            pass: reflaxe.elixir.ast.ElixirASTTransformer.alias_tupleElemFieldToFunctionPass
        });
        
        // Idiomatic enum pattern matching transformation (must run before underscore cleanup)
        passes.push({
            name: "IdiomaticEnumPatternMatching",
            description: "Transform enum tuple access patterns to idiomatic pattern matching",
            enabled: true,
            pass: reflaxe.elixir.ast.ElixirASTTransformer.alias_idiomaticEnumPatternMatchingPass
        });
        
        // Pattern matching transformation pass (comprehensive switch→case conversion)
        passes.push({
            name: "PatternMatching",
            description: "Transform switch statements to idiomatic Elixir case expressions",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.PatternMatchingTransforms.patternMatchingPass
        });
        
        // Pattern matching guard optimization pass
        passes.push({
            name: "PatternMatchingGuardOptimization",
            description: "Optimize pattern matching by extracting guards from case bodies",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.PatternMatchingTransforms.guardOptimizationPass
        });

        // Rewrite case length(list) → case list with list patterns after pattern matching is materialized
        passes.push({
            name: "CaseLengthToListPattern_Post",
            description: "Rewrite case length(list) to list pattern case after PatternMatching",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseLengthToListPatternTransforms.pass
        });
        // Resolve a single free var in case guards to the other function parameter (not the scrutinee)
        passes.push({
            name: "CaseGuardFreeVarToOtherParam",
            description: "In case guards, rewrite a single free var to the other function parameter when uniquely identifiable",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseGuardFreeVarToOtherParamTransforms.pass
        });

        // Ensure case clause bodies are not empty (avoid syntax errors)
        passes.push({
            name: "CaseClauseEmptyBodyToNil",
            description: "Replace empty case arm bodies with nil to ensure valid syntax",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseClauseFixTransforms.caseClauseEmptyBodyToNilPass
        });

        // (moved later) StringBinaryMatchContainsRewrite runs AFTER StringSearchFilterNormalization

        // Guard sanitization pass (replace non-guard-safe calls with guard-safe equivalents)
        passes.push({
            name: "GuardSanitization",
            description: "Replace non-guard-safe constructs (e.g., Map.get != nil) with guard-safe guard functions",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.GuardSanitizationTransforms.guardSanitizePass
        });
        
        // Pattern variable binding pass
        passes.push({
            name: "PatternVariableBinding",
            description: "Ensure correct variable scoping in pattern matching",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.PatternMatchingTransforms.patternVariableBindingPass
        });

        // Rename preserved switch result temps to switch_result_* (avoid underscore-use warnings)
        passes.push({
            name: "RenameSwitchResultVars",
            description: "Rename __elixir_switch_result_* to switch_result_*",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.renameSwitchResultVarsPass
        });

        // Immediately normalize trailing switch_result_* returns to inline case
        // while the corresponding assignment is still present
        passes.push({
            name: "SwitchResultInlineReturnFix",
            description: "Replace trailing switch_result_* with the assigned case expression (early)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.SwitchResultInlineReturnFixTransforms.pass
        });
        passes.push({
            name: "SwitchReturnSanitizer",
            description: "Inline case into tail return when returning alias variable (sanitize direct switch returns)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.SwitchReturnSanitizerTransforms.pass
        });
        // Parenthesize case expressions in assignment RHS for consistent value form
        passes.push({
            name: "CaseExprParenthesizeInExpr",
            description: "Wrap case in parentheses when used as assignment RHS",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseExprParenthesizeInExprTransforms.transformPass
        });

        // Merge case result back into preceding assignment when split by lowering
        passes.push({
            name: "CaseResultAssignmentMerge",
            description: "Merge `x = init; case x do ... end` into `x = case init do ... end`",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseResultAssignmentMergeTransforms.pass
        });

        // Repair inner-case scrutinee that incorrectly references the outer result var
        // before it is bound (generic Option.Some → inner case on binder).
        passes.push({
            name: "SwitchInnerCaseBinderRepair",
            description: "Rewrite inner `case <lhs>` to `case <binder>` when clause pattern binds the value (avoids undefined var)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.SwitchInnerCaseBinderRepairTransforms.repairPass
        });

        // Normalize if-then branches that accidentally emit nested `do` blocks
        // Ensure any EDo in the then-branch becomes an EBlock to avoid `if ... do do ... end`
        passes.push({
            name: "IfThenDoToBlock",
            description: "Normalize EIf then-branch EDo to EBlock (prevents nested do)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.IfThenDoToBlockTransforms.normalizePass
        });

        // Remove redundant temp-to-binder assignments inside case bodies
        passes.push({
            name: "CasePatternTempAssignmentRemoval",
            description: "Drop assignments like `todo = _g` when pattern already binds `todo`",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.casePatternTempAssignmentRemovalPass
        });

        // Rename single tuple binders from case expr var (alert_level -> level)
        passes.push({
            name: "BinderRenameFromExpr",
            description: "Rename single binders based on case expr var (e.g., alert_level -> level)",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.caseClauseBinderRenameFromExprPass
        });

        // Remove numeric suffixes from binders and references within local scopes
        passes.push({
            name: "NumericSuffixVarNormalize",
            description: "Normalize variables with trailing digits to descriptive base names (no integers)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.NumericSuffixVarNormalizeTransforms.normalizePass
        });

        // Normalize camelCase binders in case patterns to snake_case and update clause bodies
        passes.push({
            name: "BinderCamelToSnake",
            description: "Rename camelCase binders in case patterns to snake_case with body rewrite",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderCamelToSnakeTransforms.binderCamelToSnakePass
        });

        // Rewrite camelCase references in clause bodies to existing snake_case binders
        passes.push({
            name: "ClauseCamelRefToSnake",
            description: "Within case arms, convert camelCase body refs to snake_case when binder exists",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ClauseCamelRefToSnakeTransforms.clauseCamelRefToSnakePass
        });

        // Early promotion: for tuple patterns, promote underscored binders to base
        // names when the base is referenced in the clause body (includes #{...}).
        passes.push({
            name: "CaseTupleMultiBinderPromoteByUse_Early",
            description: "Promote tuple binders (_a, _b, ...) to (a, b, ...) when used in body (AST or interpolation)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseTupleMultiBinderPromoteByUseTransforms.pass,
            runAfter: ["ClauseCamelRefToSnake", "CaseSecondBinderCanonicalUnderscore"]
        });

        // Prefix unused case-pattern binders with underscore to avoid warnings
        passes.push({
            name: "ClauseUnusedBinderUnderscore",
            description: "Within case arms, prefix unused binders with underscore",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.ClauseUnusedBinderUnderscoreTransforms.clauseUnusedBinderUnderscorePass
        });
        passes.push({
            name: "ClauseUnusedBinderUnderscore",
            description: "Final sweep to underscore unused binders in case arms",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.ClauseUnusedBinderUnderscoreTransforms.clauseUnusedBinderUnderscorePass
        });
        passes.push({
            name: "CaseUnderscoreBinderPromoteByUse",
            description: "Promote underscored binders (_name) to name when body uses name (disabled for parity)",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.CaseUnderscoreBinderPromoteByUseTransforms.transformPass
        });

        // If body references the underscored binder itself, promote binder and body refs to base name
        passes.push({
            name: "ClauseUnderscoreUsedPromote",
            description: "When clause body uses underscored binder (_val), rename binder and refs to base (disabled)",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.ClauseUnderscoreUsedPromoteTransforms.transformPass
        });

        /**
         * BinderRenameByTag
         *
         * WHAT
         * - Previously renamed {:tag, var} binders based on tag heuristics.
         *
         * WHY
         * - Tag-driven renames risk coupling to app/domain semantics. Keep compiler generic
         *   by avoiding tag name heuristics.
         *
         * HOW
         * - Disabled in favor of the generic SingleBinderByUsage pass which aligns binder
         *   names to actual clause body usage without relying on tags.
         */
        passes.push({
            name: "BinderRenameByTag",
            description: "Disabled: avoid tag→binder heuristics",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.caseClauseBinderRenameByTagPass
        });

        // In LiveView modules, rename {:error, _} to {:error, reason}
        passes.push({
            name: "LiveViewErrorBinderRename",
            description: "Rename LiveView error binders to reason (disabled for snapshot parity)",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.liveViewErrorBinderRenamePass
        });

        // Rename Repo result binders based on body usage (user/data/changeset/reason)
        passes.push({
            name: "ResultBinderRenameByBodyUsage",
            description: "Rename {:ok,_}/{:error,_} binder to names used in bodies (disabled for snapshot parity)",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.resultBinderRenameByBodyUsagePass
        });

        // Generic: rename single payload binder in case arms based on clause body usage
        passes.push({
            name: "SingleBinderByUsage",
            description: "Rename {:tag, value} binder to the unique undefined var used in body (e.g., todo/id/params)",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.SingleBinderByUsageTransforms.renameSingleBinderByBodyUsagePass
        });

        // Generic: replace undefined vars in clause bodies with the single bound binder when unambiguous
        passes.push({
            name: "ClauseUndefinedVarToBinder",
            description: "Within {:tag, value} arms, replace unique undefined var in body with binder",
            enabled: false, // Disabled: caused parameter shadowing in switch_return_sanitizer; rework with full scope awareness
            pass: reflaxe.elixir.ast.transformers.ClauseUndefinedVarToBinderTransforms.replaceUndefinedVarWithBinderPass
        });
        // Safer variant: rewrite undefined body var to the existing payload binder (does not rename binder)
        passes.push({
            name: "ClauseUndefinedRefRewrite",
            description: "Within {:tag, binder} arms, rewrite single undefined body var to binder (scope-aware)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ClauseUndefinedRefRewriteTransforms.transformPass
        });
        passes.push({
            name: "CasePayloadBinderAvoidReserved",
            description: "Avoid reserved binder names (socket/params); rename binder to sole undefined body var",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CasePayloadBinderAvoidReservedTransforms.transformPass
        });

        // Absolute-final safeguard: replay reserved-binder avoidance after late folds
        passes.push({
            name: "CasePayloadBinderAvoidReserved_Final",
            description: "Absolute final: avoid reserved binder names in case arms",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CasePayloadBinderAvoidReservedTransforms.transformPass
        });

        // Replace inner case on parsed_msg with the bound Some/Ok binder (value)
        passes.push({
            name: "InnerParsedMsgCaseToBinder",
            description: "Replace inner case parsed_msg with the outer bound binder (:some value)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.innerParsedMsgCaseToBinderPass
        });

        // Normalize system_alert clause binders and body variable references
        passes.push({
            name: "SystemAlertClauseNormalization",
            description: "Normalize {:system_alert, message, flash_type} and fix flashType usage",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.systemAlertClauseNormalizationPass
        });

        /**
         * LiveViewCancelEditInlinePresence
         *
         * WHAT
         * - Previously inlined Presence.update_user_editing within a specific "cancel_edit" event branch.
         *
         * WHY
         * - This was coupled to example-app behavior and event naming. We must avoid
         *   app-specific assumptions in the compiler pipeline.
         *
         * HOW
         * - Disabled in favor of generic, pattern-driven passes that do not depend on
         *   concrete event tags or helper functions.
         *
         * EXAMPLES
         * - Before: Special-cased {:cancel_edit, _} to inject Presence.update_user_editing.
         * - After: No special-casing; Presence-related logic should live in user code.
         */
        passes.push({
            name: "LiveViewCancelEditInlinePresence",
            description: "Disabled: remove app-specific Presence inline transform for cancel_edit",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.liveViewCancelEditInlinePresencePass
        });

        /**
         * EventParamAliasInjection
         *
         * WHAT
         * - Injected clause-local aliases for event payloads based on tag heuristics.
         *
         * WHY
         * - Tag→alias mapping risks coupling to app/domain semantics. Maintain target-agnostic
         *   compiler by avoiding tag-name driven behavior in the core pipeline.
         *
         * HOW
         * - Disable this pass; rely on generic binder alignment and usage-driven renaming.
         *
         * EXAMPLES
         * - Before: "delete_todo" -> alias id; "save_todo" -> alias params.
         * - After: No automatic alias injection; user code remains explicit or other
         *   generic passes align identifiers based on actual usage.
         */
        passes.push({
            name: "EventParamAliasInjection",
            description: "Disabled: remove tag→alias injection to avoid app coupling",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.eventParamAliasInjectionPass
        });

        /**
         * BinderAliasInjection
         *
         * WHAT
         * - Injected clause-local aliases to reconcile binder names with body usage,
         *   using a preferred-name list that included app/domain terms.
         *
         * WHY
         * - Preferred-name tables risk app coupling. We preserve only pattern-driven,
         *   usage-based alignment in other passes.
         *
         * HOW
         * - Disable this pass. Keep generic RefDeclAlignment/UsageAnalysis passes to
         *   ensure declarations and references converge without app-specific bias.
         */
        passes.push({
            name: "BinderAliasInjection",
            description: "Disabled: avoid alias injection based on preferred-name tables",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.caseClauseBinderAliasInjectionPass
        });

        // Normalize Repo {:ok,_}/{:error,_} result binders to canonical names in case arm bodies
        passes.push({
            name: "RepoResultBinderNormalization",
            description: "Alias Repo result binder to canonical names (user/data/changeset/reason) used in clause bodies",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.repoResultBinderNormalizationPass
        });

        // Controller-specific Repo result binder normalization
        passes.push({
            name: "ControllerResultBinderNormalization",
            description: "In controllers, rename {:ok,_}/{:error,_} binders and alias data as needed",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.controllerResultBinderNormalizationPass
        });

        // Ensure Phoenix.Controller.json bodies have aliases (user/changeset/data) from result binders
        passes.push({
            name: "ControllerPhoenixJsonAliasInjection",
            description: "Inject aliases (user/changeset/data) for Phoenix.Controller.json bodies from {:ok,_}/{:error,_}",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.controllerPhoenixJsonAliasInjectionPass
        });
        // Ensure controller actions have conn parameter when body references it
        passes.push({
            name: "ControllerEnsureConnParam",
            description: "Add `conn` param to controller action defs when body uses conn and param is missing",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ControllerEnsureConnParamTransforms.pass
        });
        // (Removed) WebParamBinderAlign(UltraFinal) merged into WebParamFinalFix
        // Re-run controller conn param normalization at the very end to avoid re-underscore by earlier passes
        passes.push({
            name: "ControllerEnsureConnParam",
            description: "Normalize _conn -> conn in controller action heads (ultra final)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ControllerEnsureConnParamTransforms.pass
        });

        // Promote underscored def/defp params in Web/Live modules based on body usage (pins/ERaw aware)
        passes.push({
            name: "WebDefHeadPromotion",
            description: "Promote _id/_user_id/_editing_todo -> id/user_id/editing_todo in Web/Live defs when body uses base",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.WebDefHeadPromotionTransforms.pass
        });

        // Late safety net for error reason aliasing in any context
        passes.push({
            name: "ErrorReasonAliasInjection",
            description: "Ensure {:error, v} arms alias reason when body uses it",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.errorReasonAliasInjectionPass
        });

        // Re-run LiveView error binder rename late to catch any newly generated case arms
        passes.push({
            name: "LiveViewErrorBinderRenameLate",
            description: "Late rename of LiveView {:error,_} -> {:error, reason}",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.liveViewErrorBinderRenamePass
        });

        // Final safety: if an error-arm body references `reason`, enforce binder name `reason`
        passes.push({
            name: "ResultErrorBinderLateNormalization",
            description: "If body uses `reason` and not `changeset`, rename error binder to `reason`",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.resultErrorBinderLateNormalizationPass
        });

        // LiveView reduce_while anonymous fn error-binder normalization
        passes.push({
            name: "LiveViewReduceWhileErrorBinderNormalization",
            description: "Within Enum.reduce_while anonymous functions, rename {:error,_} binder to reason when body uses it",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.liveViewReduceWhileErrorBinderNormalizationPass
        });

        // Rewrite bare assign(socket, map) calls in LiveView modules to Component.assign(socket, map)
        passes.push({
            name: "LiveViewAssignCallRewrite",
            description: "Rewrite assign(socket,map) to Component.assign(socket,map) in LiveView modules",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.liveViewAssignCallRewritePass
        });

        // Rewrite listVar.push(value) to listVar = Enum.concat(listVar, [value])
        passes.push({
            name: "ListPushRewrite",
            description: "Rewrite list.push(v) to list = Enum.concat(list, [v])",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.listPushRewritePass
        });

        // Qualify bare application module calls inside <App>Web.* when target module exists
        passes.push({
            name: "ModuleQualification",
            description: "Rewrite Foo.bar(...) to <App>.Foo.bar(...) inside <App>Web.* when <App>.Foo is defined",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.moduleQualificationPass
        });

        // Late replay of list push rewrite to catch push/1 introduced by later transforms
        passes.push({
            name: "ListPushRewrite",
            description: "Late rewrite of list.push(v) to assignment with Enum.concat",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.listPushRewritePass
        });

        // Qualify bare Repo.* calls to <App>.Repo.* by deriving <App> from the enclosing module name (e.g., TodoAppWeb.* -> TodoApp)
        passes.push({
            name: "RepoQualification",
            description: "Rewrite bare Repo.* calls to <App>.Repo.* using the enclosing <App>Web module shape; ensures correctness without relying on aliases",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.repoQualificationPass
        });

        // Qualify Repo.* inside ERaw strings within <App>Web.* modules (minimal safety net)
        passes.push({
            name: "ERawRepoQualification",
            description: "Qualify Repo.* tokens in ERaw within Web modules to <App>.Repo.*",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.erawRepoQualificationPass
        });
        // Qualify Ecto.Query.from ERaw snippets to use schema modules instead of table atoms
        passes.push({
            name: "ERawEctoFromQualification",
            description: "Rewrite Ecto.Query.from(... in :user, ...) to ... in <App>.User, ... in ERaw",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EctoERawTransforms.erawEctoFromQualificationPass
        });
        passes.push({
            name: "EctoFromInAtomQualification",
            description: "Rewrite Ecto.Query.from(t in :table, ...) to t in <App>.CamelCase in AST nodes",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EctoERawTransforms.fromInAtomQualificationPass
        });
        passes.push({
            name: "EctoFromInModuleQualification",
            description: "Rewrite Ecto.Query.from(t in Module, ...) to t in <App>.Module where Module is single-segment CamelCase",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EctoERawTransforms.fromInModuleQualificationPass
        });

        // Insert alias <App>.Repo as Repo in Web modules that reference Repo.*
        passes.push({
            name: "RepoAliasInjection",
            description: "Inject `alias <App>.Repo, as: Repo` when Repo.* is used in Web modules",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.repoAliasInjectionPass
        });

        // Normalize Ecto query variable usage and fix where/Repo.all first-arg to canonical binding
        passes.push({
            name: "EctoQueryVarConsistency",
            description: "Normalize Ecto query variable usage and rewrite Ecto.Query.where/Repo.all to canonical query var",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EctoTransforms.ectoQueryVarConsistencyPass
        });
        // Rewrite Ecto.Queryable.to_query(:atom) -> <App>.<CamelCase(atom)>
        passes.push({
            name: "EctoQueryableAtomToSchema",
            description: "Rewrite Ecto.Queryable.to_query(:table) to schema module <App>.<Camel>",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EctoTransforms.ectoQueryableAtomToSchemaPass
        });

        // Rewrite Repo.* calls that take an atom queryable to use the schema module
        // Ensures idiomatic Ecto usage across repository APIs without relying on atoms
        passes.push({
            name: "RepoAtomToSchema",
            description: "Rewrite Repo.all/one/get/get!/aggregate(:table, ...) to <App>.<Camel>",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.RepoAtomToSchemaTransforms.transformPass
        });

        // Unify case success vars in {:ok, v} branches to eliminate undefined placeholders
        passes.push({
            name: "CaseSuccessVarUnifier",
            description: "Rewrite undefined placeholders (todo/updated_todo) to success var in {:ok, v} clauses",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseSuccessVarUnifier.unifySuccessVarPass
        });

        // (moved later) PatternBindingHarmonize should run after HygieneConsolidated

        // Prevent {:ok, socket} style shadowing that breaks LiveView flows
        passes.push({
            name: "CaseSuccessVarRenameCollisionFix",
            description: "Rename {:ok, var} binder when it collides with function args (e.g., socket)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseSuccessVarRenameCollisionFixTransforms.transformPass
        });

        // Rename {:some, g} binder -> {:some, value} and rewrite references to avoid
        // collisions with outer temporaries (e.g., `g = case ... end`).
        passes.push({
            name: "CaseSomeBinderRename",
            description: "Rename {:some, g} binder to value and rewrite body refs to avoid shadowing",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseSomeBinderRenameTransforms.transformPass
        });

        // (moved) EqNilToIsNil should run after ChangesetNormalize so opts.* -> Map.get rewrites happen first

        // Simplify provably false is_nil checks based on prior literal assignments
        passes.push({
            name: "SimplifyIsNilFalse",
            description: "Replace is_nil(var) with false when var is known non-nil from earlier literal assignment",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.simplifyProvableIsNilFalsePass
        });

        // (temporarily disabled) Ecto query var consistency — will be addressed via assignment extraction specialization

        // (Removed) UnusedLocalAssignmentUnderscore: prefer fixing root causes and removing dead code

        // Normalize Supervisor.start_link(children, opts) to use declared local names
        // inside Application.start/2 (prevents undefined variable errors when hygiene
        // passes have prefixed binders with underscores)
        passes.push({
            name: "ApplicationStartArgNormalization",
            description: "Align start_link arg names with declared locals in start/2",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ApplicationStartTransforms.normalizeStartLinkArgsPass
        });
        passes.push({
            name: "TypeSafeChildSpecNormalize",
            description: "Normalize TypeSafeChildSpec.supervisor/3 to bind parameters and avoid undefined vars",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.TypeSafeChildSpecNormalizeTransforms.transformPass
        });

        // Normalize local var references to declared names in function scope (underscore/digit suffix cases)
        passes.push({
            name: "LocalVarReferenceFix",
            description: "Fix local references like changeset-> _changeset or query->query2 when only the latter is declared",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.LocalVarReferenceFixTransforms.localVarReferenceFixPass
        });

        // Fallback: ensure references to plain names resolve to underscored
        // locals when only the underscored variant is declared in function scope.
        passes.push({
            name: "LocalUnderscoreReferenceFallback",
            description: "Fallback renaming of EVar(name) -> EVar(_name) when only _name declared (disabled to prevent false-positive flips)",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.LocalUnderscoreReferenceFallbackTransforms.fallbackUnderscoreReferenceFixPass
        });

        // Finally, if a local is declared underscored but used later, rename declaration
        // to non-underscored to eliminate warnings and undefined refs
        passes.push({
            name: "UsedUnderscoreRename",
            description: "Rename _var to var when var is referenced and var is not declared (disabled near release to avoid drift)",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.UnderscoreVarTransforms.removeUnderscoreFromUsedLocalsPass
        });

        // Note: Avoid feature/app-specific passes. Prefer generic variable alignment transforms
        // that operate on all modules and rely on injection shaping to expose usage to AST.

        // StringTools-specific local reference fix (len/result) to match declared locals
        passes.push({
            name: "StringToolsLocalFix",
            description: "Align len/result references with declared locals in StringTools",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.StringToolsTransforms.fixLocalReferencesPass
        });

        // StringTools native trim rewrite (idiomatic)
        passes.push({
            name: "StringToolsNativeRewrite",
            description: "Rewrite ltrim/rtrim to String.trim_leading/trim_trailing",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.StringToolsNativeRewrite.rewriteTrimPass
        });
        passes.push({
            name: "StringToolsFix",
            description: "Ensure StringTools.is_space/2 uses binders s,pos (late enforcement)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.StringToolsFixTransforms.transformPass
        });

        // Stdlib overrides for Haxe runtime modules (binder-consistent, native Elixir)
        passes.push({
            name: "StdHaxeRuntimeOverride",
            description: "Override ArrayIterator/PosException with binder-consistent native implementations",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.StdHaxeRuntimeOverrideTransforms.transformPass
        });

        // Wrap parse_* helpers to return {:some, v} | :none to match caller patterns
        passes.push({
            name: "OptionWrapParseFunctions",
            description: "Wrap results of parse_* functions into {:some, v} | :none",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.OptionWrapTransforms.optionWrapParseFunctionsPass
        });

        // Introduce cs binder when validations reference cs before it is bound
        passes.push({
            name: "IntroduceChangesetBinder",
            description: "When validate_* references cs without prior binding, bind cs = <prev expr>",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.IntroduceChangesetBinderTransforms.pass
        });

        // Promote leading `_ = _ = ... = <changeset>` to `cs = <changeset>` inside changeset/2
        passes.push({
            name: "WildcardChangesetAssignPromote",
            description: "In changeset/2, rewrite nested wildcard assign chain to `cs = <expr>`",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.WildcardChangesetAssignPromoteTransforms.pass
        });
        // (moved later in pipeline, after validate_* rewrites)

        // Changeset normalization: canonicalize cs variable, opts binding, and validate_* targets
        passes.push({
            name: "ChangesetNormalize",
            description: "Normalize Ecto.Changeset pipelines (cs/opts/thisN)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ChangesetTransforms.normalizeChangesetPass
        });
        // Replace x == nil checks with Kernel.is_nil(x) AFTER Map.get(opts, :key) rewrites
        passes.push({
            name: "EqNilToIsNil",
            description: "Replace (x == nil) with Kernel.is_nil(x) (post-ChangesetNormalize)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.eqNilToIsNilPass
        });
        // Ensure validate_* field argument uses literal atom when possible
        passes.push({
            name: "ChangesetFieldAtomNormalize",
            description: "Rewrite String.to_atom(\"field\") to :field in validate_* calls",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ChangesetTransforms.normalizeValidateFieldAtomPass
        });
        // Collapse cond trees guarding validate_length into single filtered keyword list call
        passes.push({
            name: "ChangesetLengthCondCollapse",
            description: "Collapse cond-combination trees for validate_length to filtered Map.get keyword list",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ChangesetLengthCondCollapseTransforms.collapsePass
        });
        // Rewrite opts.* in validate_length keyword lists to Map.get(opts, :key)
        passes.push({
            name: "ValidateLengthOptsAccessRewrite",
            description: "In validate_length calls, rewrite opts.* to Map.get(opts, :key)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ValidateLengthOptsAccessRewrite.rewritePass
        });
        // Filter nil-valued options in validate_length keyword lists
        passes.push({
            name: "ChangesetLengthOptionFilter",
            description: "Drop nil options in validate_length by filtering keyword list",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ChangesetOptionFilterTransforms.filterValidateLengthOptionsPass
        });
        // Ensure no late-introduced validate_* fields remain as String.to_atom/strings
        passes.push({
            name: "ChangesetFieldAtomNormalize",
            description: "Late sweep to normalize validate_* field argument to literal atom",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ChangesetTransforms.normalizeValidateFieldAtomPass
        });
        // Final guarantee: normalize validate_* field atom literals at the very end
        passes.push({
            name: "ChangesetFieldAtomNormalize",
            description: "Final normalization of validate_* field args to :field",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ChangesetTransforms.normalizeValidateFieldAtomPass
        });
        // Ecto where pinned-nil guard: rewrite `field == ^var` to guarded case using Kernel.is_nil(var)
        passes.push({
            name: "EctoEqPinnedNilGuard",
            description: "Guard Ecto where comparisons with pinned vars that may be nil",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EctoEqPinnedNilGuardTransforms.transformPass
        });
        // Ensure schema changeset/2 binders align with body usage (underscore → base)
        passes.push({
            name: "EctoSchemaBinderFix",
            description: "Normalize changeset/2 binder names by dropping underscores when body uses base names",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EctoSchemaBinderFixTransforms.transformPass
        });

        // Ensure `require Ecto.Query` before late rewrites that might depend on macro availability
        passes.push({
            name: "EctoQueryRequireEnsure",
            description: "Ensure `require Ecto.Query` when Ecto.Query remote macros are present (pre-late; remote-only gating)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EctoQueryRequireEnsureTransforms.transformPass
        });

        // Normalize Ecto where query arg by inlining IIFE wrappers around from/2
        passes.push({
            name: "EctoQueryIIFEInline",
            description: "Inline (fn -> ... from(...) ... end).() used as where/2 query arg",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EctoQueryIIFEInlineTransforms.transformPass
        });

        // Ensure Phoenix channel modules are set up idiomatically
        passes.push({
            name: "ChannelSetup",
            description: "Inject `use <App>Web, :channel` for modules named like Phoenix channels",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.AnnotationTransforms.channelTransformPass
        });

        // Clean up wildcard assignments in Ecto where branches to restore idiomatic shape
        passes.push({
            name: "EctoWhereWildcardAssignCleanup",
            description: "Rewrite if-branch `_ = Ecto.Query.where(...)` to pure where(...) in expression context",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EctoWhereWildcardAssignCleanupTransforms.transformPass
        });
        // Inline local require before first Ecto.Query macro usage within function bodies
        passes.push({
            name: "EctoLocalRequireInline",
            description: "Insert `require Ecto.Query` before first from/where usage in function bodies (safety net)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EctoLocalRequireInlineTransforms.transformPass
        });

        // Final EqNilToIsNil to catch any newly introduced comparisons
        passes.push({
            name: "EqNilToIsNil",
            description: "Final replacement of (x == nil)/(x != nil) with Kernel.is_nil/1",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.eqNilToIsNilPass
        });
        // Final sweep: rewrite opts.* in validate_length keyword lists
        passes.push({
            name: "ValidateLengthOptsAccessRewrite",
            description: "Final rewrite of opts.* to Map.get(opts, :key) in validate_length",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ValidateLengthOptsAccessRewrite.rewritePass
        });
        // Broad normalization: convert opts.* inside any keyword list to Map.get(opts, :key)
        passes.push({
            name: "OptsKeywordMapGet",
            description: "Normalize opts.* in keyword lists to Map.get",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.OptsKeywordMapGetTransforms.transformPass
        });
        // Final SafePubSub alias injection
        passes.push({
            name: "SafePubSubAliasInject",
            description: "Ensure alias Phoenix.SafePubSub as SafePubSub present",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.SafePubSubAliasInjectTransforms.injectPass
        });

        // Convert stray increment statements (i + 1) into assignments (i = i + 1)
        passes.push({
            name: "IncrementToAssignment",
            description: "Rewrite standalone increments to explicit assignments in blocks and if-branches",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ArithmeticIncrementTransforms.transformPass
        });
        // NOTE: FnArgUnusedUnderscore disabled due to false-positives in LiveView filters
        // passes.push({
        //     name: "FnArgUnusedUnderscore",
        //     description: "Underscore unused anonymous function argument binders",
        //     enabled: false,
        //     pass: reflaxe.elixir.ast.transformers.FnArgUnusedUnderscoreTransforms.transformPass
        // });
        // Final sweep: convert String.to_atom("field") to :field when literal
        passes.push({
            name: "StringToAtomLiteral",
            description: "Replace String.to_atom(\"field\") with :field when argument is a string literal",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.stringToAtomLiteralPass
        });

        // Inject `use <App>Web, :live_view` for modules like <App>Web.*Live (shape-derived)
        passes.push({
            name: "LiveViewUseInjection",
            description: "Inject `use <App>Web, :live_view` into <App>Web.*Live when missing",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.liveViewUseInjectionPass
        });
        // Rename unused local assignment binders to underscore to silence warnings
        // Disabled: mis-detected usage inside nested expressions (e.g., HEEx arg maps)
        // leading to prefixing real locals with underscore and later undefined refs.
        passes.push({
            name: "UnusedLocalAssignmentUnderscore",
            description: "Prefix unused local assignment names with underscore in blocks",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.UnusedLocalAssignmentUnderscoreTransforms.transformPass
        });
        // Promote binders underscored earlier when body uses the base name
        passes.push({
            name: "LocalUnderscoreBinderPromote",
            description: "Rename EMatch(_name = ...) to name = ... when subsequent code uses name",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.LocalUnderscoreBinderPromoteTransforms.promotePass
        });
        // Generic underscore promotion: _any -> any when used later in the same body
        passes.push({
            name: "LocalUnderscoreGenericPromotion",
            description: "Promote any underscored local binder (_x) to x when referenced",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.LocalUnderscoreGenericPromotionTransforms.pass,
            runAfter: [
                "ControllerLocalUnusedUnderscore_Final",
                "MountParamsSideEffectAssignDiscard_Final",
                "HandleEventBodyAlignToHead_Final",
                "HandleEventParamsUltraFinal_Last"
            ]
        });
        passes.push({
            name: "LocalUnderscoreGenericPromotion_UltraFinal",
            description: "Ultra-final replay: promote underscored local binders when referenced (late shapes)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.LocalUnderscoreGenericPromotionFinalTransforms.pass,
            runAfter: [
                "QueryVarUltimateNormalize_UltraFinal",
                "FunctionQueryBinderSynthesis_UltraFinal",
                "SuccessBinderPrefixMostUsedUndefined_UltraFinal"
            ]
        });
        // Inline one-shot locals in Web/Controller/LiveView bodies late to remove warning temporaries
        passes.push({
            name: "InlineLocalAssignUsedOnce_Final",
            description: "Final (Controller-only): inline name = expr when name is used exactly once later in the same body (disabled)",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.InlineLocalAssignUsedOnceTransforms.pass,
            runAfter: [
                "ControllerLocalUnusedUnderscore_Final",
                "LocalUnderscoreGenericPromotion_UltraFinal"
            ]
        });
        // Web-only: underscore unused locals in Web.* modules (LiveView + Controllers)
        passes.push({
            name: "WebLocalUnusedUnderscore",
            description: "In <App>Web.*, underscore local assignment binders unused later in the body",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.WebLocalUnusedUnderscoreTransforms.pass,
            runAfter: [
                "MountSessionExtractCleanup_Final",
                "MountParamsSideEffectAssignDiscard_Final",
                "HandleEventBodyAlignToHead_Final",
                "ControllerLocalUnusedUnderscore_Final",
                "UnderscoreParamPromotion_Final"
            ]
        });

        // (moved later in pipeline; after functions are finalized)
        // Within a block, prefer consistent underscore references when only underscored binder exists
        passes.push({
            name: "BlockUnderscoreReferenceFix",
            description: "Rewrite name -> _name within a block when only _name is declared in that block",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BlockUnderscoreReferenceFixTransforms.fixPass
        });
        // Immediately fix adjacent statement references to base after underscored binder assignment
        passes.push({
            name: "AdjacentUnderscoreBinderRefFix",
            description: "In blocks, rewrite next statement references name-> _name after _name = ... assignment",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.AdjacentUnderscoreBinderRefFixTransforms.fixPass
        });

        // Inject `use Phoenix.Component` in regular modules that call assign/2 with a socket
        passes.push({
            name: "PhoenixComponentUseInjection",
            description: "Add `use Phoenix.Component` to modules that call assign/2",
            enabled: true,
            pass: function(ast: ElixirAST): ElixirAST {
                return reflaxe.elixir.ast.ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
                    return switch(n.def) {
                        case EModule(name, attrs, body):
                            // Detect free assign/2 calls with socket-like first argument
                            var hasAssign = false;
                            function scan(x: ElixirAST): Void {
                                if (hasAssign || x == null || x.def == null) return;
                                switch(x.def) {
                                    case ECall(_, func, args) if (func == "assign" && args != null && args.length == 2):
                                        switch(args[0].def) { case EVar(v) if (v.indexOf("socket") != -1): hasAssign = true; default: }
                                    case ERemoteCall(_, func, args) if (func == "assign" && args != null && args.length == 2):
                                        switch(args[0].def) { case EVar(v) if (v.indexOf("socket") != -1): hasAssign = true; default: }
                                    case EBlock(es): for (e in es) scan(e);
                                    case EIf(c,t,e): scan(c); scan(t); if (e != null) scan(e);
                                    case ECase(e, cs): scan(e); for (c in cs) { if (c.guard != null) scan(c.guard); scan(c.body);} 
                                    case EBinary(_, l, r): scan(l); scan(r);
                                    case EFn(cs): for (cl in cs) scan(cl.body);
                                    case ECall(t,_,as): if (t != null) scan(t); if (as != null) for (a in as) scan(a);
                                    case ERemoteCall(m,_,as): scan(m); if (as != null) for (a in as) scan(a);
                                    default:
                                }
                            }
                            for (b in body) scan(b);
                            if (hasAssign) {
                                // Avoid duplicate use statements
                                var hasUse = false;
                                for (b in body) switch(b.def) { case EUse(module, _ ) if (module == "Phoenix.Component"): hasUse = true; default: }
                                if (!hasUse) {
                                    var newBody = [ makeAST(EUse("Phoenix.Component", [])) ];
                                    for (b in body) newBody.push(b);
                                    makeASTWithMeta(EModule(name, attrs, newBody), n.metadata, n.pos);
                                } else n;
                            } else n;
                        default:
                            n;
                    }
                });
            }
        });

        // Late string search predicate normalization to sanitize any residual inline expansion
        // in Enum.filter predicates or anonymous functions (produces pure boolean expressions)
        passes.push({
            name: "StringSearchFilterNormalization",
            description: "Normalize string contains checks to pure boolean expressions in filter predicates",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.stringSearchFilterNormalizationPass
        });

        // Rewrite `not Kernel.is_nil(:binary.match(a, b))` to idiomatic `String.contains?(a, b)`
        // Must run AFTER StringSearchFilterNormalization which introduces the binary.match/is_nil shape
        passes.push({
            name: "StringBinaryMatchContainsRewrite",
            description: "Normalize binary.match/is_nil search predicates to String.contains?",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.StringBinaryMatchContainsRewriteTransforms.transformPass
        });

        // Normalize mixed-case variable references to existing snake_case bindings
        passes.push({
            name: "VarNameNormalization",
            description: "Normalize camelCase references to snake_case when a binding exists",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.VarNameNormalizationTransforms.varNameNormalizationPass
        });

        // Preserve camelCase registry field names in HXX component registry
        passes.push({
            name: "HXXRegistryFieldCasePreserve",
            description: "Within HXXComponentRegistry, keep camelCase field names (e.g., allowedAttributes)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.HXXRegistryFieldCasePreserveTransforms.pass
        });

        // List helpers normalization (contains/member?, conditional removal, inline filter returns)
        passes.push({
            name: "ContainsToEnumMember",
            description: "Rewrite arr.contains(v) to Enum.member?(arr, v)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ListHelpersFixTransforms.containsToEnumMemberPass
        });
        passes.push({
            name: "MemberFilterRemovalFix",
            description: "When cond uses Enum.member?(list, v), rewrite filter(list, fn x -> x != x end) to compare x != v",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ListHelpersFixTransforms.memberFilterRemovalFixPass
        });
        passes.push({
            name: "FilterReturnInlineFix",
            description: "Inline filter result into return when function otherwise returns original list",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ListHelpersFixTransforms.filterReturnInlineFixPass
        });

        // Normalize Option Some binder to safe identifier when used in body
        passes.push({
            name: "CaseSomeBinderNormalize",
            description: "For {:some, _x} used in body, rename binder to a safe name and rewrite references",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseSomeBinderNormalizeTransforms.pass
        });

        // Fix list update/remove logic in structural map/filter shapes (generic, non app-specific)
        passes.push({
            name: "ListMapReplaceFix",
            description: "Fix Enum.map replacement no-op where both branches return the mapping var (use other var from id equality)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ListMapFilterFixTransforms.mapReplaceFixPass
        });
        passes.push({
            name: "ListFilterRemoveFix",
            description: "Fix Enum.filter self-compare v.id != v by replacing with enclosing id/_id parameter",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ListMapFilterFixTransforms.filterRemoveFixPass
        });
        
        // Pattern exhaustiveness check pass
        passes.push({
            name: "PatternExhaustivenessCheck",
            description: "Add compile-time verification for pattern completeness",
            enabled: false, // Disabled by default as it may be verbose
            pass: reflaxe.elixir.ast.transformers.PatternMatchingTransforms.exhaustivenessCheckPass
        });
        
        // Underscore variable cleanup pass (should run late to catch all generated vars)
        #if !disable_underscore_cleanup
        passes.push({
            name: "UnderscoreVariableCleanup",
            description: "Remove underscore prefix from used temporary variables",
            enabled: true,
            pass: reflaxe.elixir.ast.ElixirASTTransformer.alias_underscoreVariableCleanupPass
        });
        #end
        
        // Abstract method this reference fix (should run after underscore cleanup)
        passes.push({
            name: "AbstractMethodThis",
            description: "Fix 'this' references in abstract methods",
            enabled: true,
            pass: reflaxe.elixir.ast.ElixirASTTransformer.alias_abstractMethodThisPass
        });
        
        // Supervisor options transformation pass (convert maps to keyword lists)
        #if !disable_supervisor_options_transform
        passes.push({
            name: "SupervisorOptionsTransform",
            description: "Convert supervisor option maps to keyword lists",
            enabled: true,
            pass: reflaxe.elixir.ast.ElixirASTTransformer.alias_supervisorOptionsTransformPass
        });
        #end
        
        // OTP child spec transformation pass (convert tuples to proper child specs)
        #if !disable_otp_child_spec_transform
        passes.push({
            name: "OTPChildSpecTransform",
            description: "Convert enum-based child specs to proper OTP child specifications",
            enabled: true,
            pass: reflaxe.elixir.ast.ElixirASTTransformer.alias_otpChildSpecTransformPass
        });
        #end
        
        // Prefix unused function parameters with underscore
        // DISABLED: Now handled during AST building with more accurate TypedExpr-based detection
        // The transformer approach had issues with mismatched detection logic between TypedExpr and ElixirAST
        // See ElixirASTBuilder line 2064-2070 for the proper implementation
        /*
        passes.push({
            name: "PrefixUnusedParameters", 
            description: "Prefix unused function parameters with underscore to follow Elixir conventions",
            enabled: true,
            pass: reflaxe.elixir.ast.ElixirASTTransformer.alias_prefixUnusedParametersPass
        });
        */
        
        // ===== HYGIENE TRANSFORMATION PASSES =====
        // These passes eliminate compilation warnings and ensure idiomatic Elixir
        // TEMPORARILY DISABLED: Stack overflow issues due to incomplete AST traversal
        // TODO: Fix recursive traversal to handle all AST node types properly
        
        // Hygienic variable naming pass (eliminate shadowing)
        passes.push({
            name: "HygienicNaming",
            description: "Eliminate variable shadowing with scope-aware renaming",
            enabled: false, // TEMP: Disabled due to stack overflow
            pass: reflaxe.elixir.ast.transformers.HygieneTransforms.hygienicNamingPass
        });
        
        // Usage analysis pass (detect unused variables)
        // NOW USING CONTEXTUAL VARIANT for consistent variable naming
        passes.push({
            name: "UsageAnalysis",
            description: "Detect and mark unused variables with underscore prefix (context-aware)",
            enabled: true, // RE-ENABLED: Now using contextual pass for consistency
            pass: reflaxe.elixir.ast.transformers.HygieneTransforms.usageAnalysisPass,
            contextualPass: reflaxe.elixir.ast.transformers.HygieneTransforms.usageAnalysisPassWithContext
        });
        
        // Atom normalization pass (remove unnecessary quotes)
        passes.push({
            name: "AtomNormalization",
            description: "Remove unnecessary quotes from atoms",
            enabled: false, // TEMP: Disabled - needs more testing
            pass: reflaxe.elixir.ast.transformers.HygieneTransforms.atomNormalizationPass
        });
        
        // Equality to pattern matching pass (idiomatic comparisons)
        passes.push({
            name: "EqualityToPattern",
            description: "Transform == comparisons to pattern matching",
            enabled: false, // TEMP: Disabled - needs more testing
            pass: reflaxe.elixir.ast.transformers.HygieneTransforms.equalityToPatternPass
        });
        
        // Fix bare concatenations in blocks
        passes.push({
            name: "FixBareConcatenations",
            description: "Convert bare concatenations in blocks to assignments",
            enabled: true,
            pass: reflaxe.elixir.ast.ElixirASTTransformer.alias_fixBareConcatenationsPass
        });

        // Final safeguard: rewrite any remaining free assign(socket, map) to Component.assign(socket, map)
        passes.push({
            name: "FinalAssignRewrite",
            description: "Rewrite remaining assign/2 calls to Component.assign/2",
            enabled: true,
            pass: function(ast: ElixirAST): ElixirAST {
                return reflaxe.elixir.ast.ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
                    return switch(n.def) {
                        case ECall(_, func, args) if (func == "assign" && args != null && args.length == 2):
                            makeASTWithMeta(ERemoteCall(makeAST(EVar("Phoenix.Component")), "assign", args), n.metadata, n.pos);
                        case ERemoteCall(mod, func, args) if (func == "assign" && args != null && args.length >= 2):
                            makeASTWithMeta(ERemoteCall(makeAST(EVar("Phoenix.Component")), "assign", args), n.metadata, n.pos);
                        default:
                            n;
                    }
                });
            }
        });

        // Late sweep: remove any redundant temp-to-binder assignments inside case bodies
        passes.push({
            name: "CasePatternTempAssignmentRemoval",
            description: "Final guard against `lhs = _g*` after pattern binding",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.casePatternTempAssignmentRemovalPass
        });

        // Final local reference fixes (run late to avoid being undone by later passes)
        passes.push({
            name: "LocalUnderscoreReferenceFallback",
            description: "Fallback renaming of EVar(name) -> EVar(_name) when only _name declared (late, disabled)",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.LocalUnderscoreReferenceFallbackTransforms.fallbackUnderscoreReferenceFixPass
        });

        // Late: Inline trailing return variables from their last assignments to avoid undefined vars
        passes.push({
            name: "InlineTrailingReturnVar",
            description: "Replace trailing return variable with its last assigned expression (late)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.InlineTrailingReturnVarTransforms.pass
        });
        
        // Consolidated hygiene sweep (usage-driven), orchestrating core hygiene steps in order
        passes.push({
            name: "HygieneConsolidated",
            description: "Consolidated pass: params underscore, underscore fallback, used underscore promotion, ref/decl alignment, case binder hygiene",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.HygieneConsolidatedTransforms.pass
        });
        // Late binder repair again after hygiene may rewrite locals
        passes.push({
            name: "SwitchInnerCaseBinderRepair",
            description: "Late: ensure inner case scrutinee uses bound binder, not outer result var",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.SwitchInnerCaseBinderRepairTransforms.repairPass
        });
        // Early dedicated promotion for function params (adds redundancy safety when consolidated disabled in debug)
        passes.push({
            name: "DefParamUnderscorePromote",
            description: "Promote underscored def/defp params when trimmed name is used in body",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.DefParamUnderscorePromoteTransforms.promotePass
        });
        // Unify declarations and references to a canonical local name per base
        passes.push({
            name: "RefDeclAlignment",
            description: "Align declaration/reference spellings (underscore/numeric) to canonical name",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.RefDeclAlignmentTransforms.alignLocalsPass
        });
        passes.push({
            name: "StringToolsLocalFix",
            description: "Align len/result references with declared locals in StringTools (late)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.StringToolsTransforms.fixLocalReferencesPass
        });

        // Drop redundant local copies like this1 = query and new_query = ...
        passes.push({
            name: "RedundantAssignmentCleanup",
            description: "Remove redundant assignments (thisN/new_query) that cause warnings",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.RedundantAssignmentCleanup.cleanupPass
        });

        // Remove `0 + 1` standalone statements introduced by lowerings
        passes.push({
            name: "NoOpArithmeticCleanup",
            description: "Drop standalone `0 + 1` expressions in blocks (no-op arithmetic)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.NoOpArithmeticCleanup.cleanupPass
        });
        // Drop stray numeric literals (1/0) used as placeholders in blocks
        passes.push({
            name: "DropStandaloneLiteralOne",
            description: "Remove standalone numeric literals (1/0) causing unused literal warnings",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.DropStandaloneLiteralOneTransforms.dropPass
        });

        // Run underscore rename again late to catch flows introduced by earlier passes (e.g., Presence)
        passes.push({
            name: "UsedUnderscoreRename",
            description: "Rename _var to var when var is referenced (late stage, disabled near release to avoid drift)",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.UnderscoreVarTransforms.removeUnderscoreFromUsedLocalsPass
        });

        // Final alignment after usage analysis may have prefixed underscores again
        passes.push({
            name: "RefDeclAlignment",
            description: "Final alignment of declarations and references to canonical names",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.RefDeclAlignmentTransforms.alignLocalsPass
        });

        // Late sweep: ensure any '!= nil' remaining are converted to not is_nil
        passes.push({
            name: "EqNilToIsNil",
            description: "Late replacement of (x != nil) with not Kernel.is_nil(x)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.eqNilToIsNilPass
        });
        // Drop stray numeric literals (final)
        passes.push({
            name: "DropStandaloneLiteralOne",
            description: "Final sweep to remove standalone numeric literals (1/0)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.DropStandaloneLiteralOneTransforms.dropPass
        });
        // Replace inline if assignments with discard (final)
        passes.push({
            name: "InlineIfAssignmentDiscard",
            description: "Final rewrite of inline if assignments to _ = expr (disabled: causes search-filter regressions)",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.InlineIfAssignmentDiscardTransforms.fixPass
        });
        // Inject @compile nowarn for defp main/0 so it's preserved by prune passes
        passes.push({
            name: "MainNowarnAndPreserve",
            description: "Ensure defp main/0 is annotated with @compile nowarn [main: 0] (disabled for snapshot parity)",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.MainNowarnAndPreserveTransforms.transformPass
        });

        // Prune unused defp helpers at the very end
        passes.push({
            name: "UnusedDefpPrune",
            description: "Final pruning of unused private functions",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.UnusedDefpPrune.prunePass
        });
        // Ensure functions ending with assignment return the assigned variable
        passes.push({
            name: "AssignReturnInjection",
            description: "Append var as final expression when function ends with var = expr",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.AssignReturnInjectionTransforms.injectPass
        });
        // Absolute final sweep to drop stray numeric literals reintroduced by later passes
        passes.push({
            name: "DropStandaloneLiteralOne",
            description: "Absolute final sweep to remove standalone numeric literals (1/0)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.DropStandaloneLiteralOneTransforms.dropPass
        });
        // Absolute final: convert any lingering `0 = call(...)` back to bare calls
        passes.push({
            name: "ZeroAssignCallToBareCall_Final",
            description: "Absolute final: rewrite numeric-sentinel call assignments to bare calls",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ZeroAssignCallToBareCallTransforms.pass
        });
        // Absolute final binder repair for any late-emitted shapes
        passes.push({
            name: "SwitchInnerCaseBinderRepair_Final",
            description: "Absolute final: rewrite inner case scrutinee to clause binder when needed",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.SwitchInnerCaseBinderRepairTransforms.repairPass
        });
        // Late simplification: fold is_nil(var) -> false when var provably non-nil literal
        passes.push({
            name: "SimplifyIsNilFalse",
            description: "Fold Kernel.is_nil(var) to false when var assigned literal non-nil earlier",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.simplifyProvableIsNilFalsePass
        });

        // Ensure Phoenix.Component is used in LiveView modules to make assign/2 available even in ERaw code
        passes.push({
            name: "EnsurePhoenixComponentUseInLive",
            description: "Inject `use Phoenix.Component` into modules ending with Live",
            enabled: true,
            pass: function(ast: ElixirAST): ElixirAST {
                return reflaxe.elixir.ast.ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
                    return switch(n.def) {
                        case EModule(name, attrs, body) if (name != null && (name.indexOf("Live") != -1)):
                            var hasUse = false;
                            for (b in body) switch(b.def) { case EUse(module, _) if (module == "Phoenix.Component"): hasUse = true; default: }
                            if (!hasUse) {
                                var newBody = [ makeAST(EUse("Phoenix.Component", [])) ];
                                for (b in body) newBody.push(b);
                                makeASTWithMeta(EModule(name, attrs, newBody), n.metadata, n.pos);
                            } else n;
                        case EDefmodule(name, doBlock) if (name != null && (name.indexOf("Live") != -1)):
                            // Inject at top of doBlock if missing
                            var hasUse = false;
                            switch(doBlock.def) {
                                case EBlock(stmts):
                                    for (s in stmts) switch(s.def) { case EUse(module, _) if (module == "Phoenix.Component"): hasUse = true; default: }
                                    if (!hasUse) {
                                        var newDo = makeAST(EBlock([ makeAST(EUse("Phoenix.Component", [])) ].concat(stmts)));
                                        makeASTWithMeta(EDefmodule(name, newDo), n.metadata, n.pos);
                                    } else n;
                                default: if (!hasUse) makeASTWithMeta(EDefmodule(name, makeAST(EBlock([ makeAST(EUse("Phoenix.Component", [])), doBlock ]))), n.metadata, n.pos) else n;
                            }
                        default:
                            n;
                    }
                });
            }
        });

        /**
         * EnsureAppWebHtmlUseInLayouts
         *
         * WHAT
         * - Injects `use <App>Web, :html` at the top of `<App>Web.Layouts` modules.
         *
         * WHY
         * - Layouts return ~H templates and need the full Phoenix 1.7 HTML context (HTML, VerifiedRoutes,
         *   controller helpers) without manual imports. Using the app’s `:html` macro is the idiomatic way.
         *
         * HOW
         * - Detect modules whose name ends with ".Layouts", derive `<App>Web` from the prefix before "Web",
         *   and prepend `use <App>Web, :html` when missing. Safe, shape-based; no app-specific heuristics.
         *
         * EXAMPLES
         *   Before: defmodule MyAppWeb.Layouts do; def root(assigns), do: ~H"..."; end
         *   After:  defmodule MyAppWeb.Layouts do; use MyAppWeb, :html; def root(assigns), do: ~H"..."; end
         */
        // Ensure `use <App>Web, :html` in Layouts modules so ~H helpers are available.
        passes.push({
            name: "EnsureAppWebHtmlUseInLayouts",
            description: "Inject `use <App>Web, :html` into <App>Web.Layouts modules",
            enabled: true,
            pass: function(ast: ElixirAST): ElixirAST {
                return reflaxe.elixir.ast.ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
                    function deriveWebModule(moduleName:String):Null<String> {
                        if (moduleName == null) return null;
                        var idx = moduleName.indexOf("Web");
                        return idx > 0 ? moduleName.substr(0, idx) + "Web" : null;
                    }
                    function hasHtmlUse(stmts:Array<ElixirAST>, webModule:String):Bool {
                        for (s in stmts) switch (s.def) {
                            case EUse(module, opts) if (module == webModule):
                                if (opts != null) for (o in opts) switch (o.def) { case EAtom(a) if (a == "html"): return true; default: }
                            default:
                        }
                        return false;
                    }
                    return switch (n.def) {
                        case EDefmodule(name, doBlock) if (name != null && StringTools.endsWith(name, ".Layouts")):
                            var webModule = deriveWebModule(name);
                            switch (doBlock.def) {
                                case EBlock(stmts) | EDo(stmts) if (webModule != null):
                                    if (!hasHtmlUse(stmts, webModule)) {
                                        var newDo = makeAST(EBlock([ makeAST(EUse(webModule, [ makeAST(EAtom("html")) ])) ].concat(stmts)));
                                        makeASTWithMeta(EDefmodule(name, newDo), n.metadata, n.pos);
                                    } else {
                                        n;
                                    }
                                default:
                                    n;
                            }
                        case EModule(name, attrs, body) if (name != null && StringTools.endsWith(name, ".Layouts")):
                            var webModule = deriveWebModule(name);
                            if (webModule != null && !hasHtmlUse(body, webModule)) {
                                makeASTWithMeta(EModule(name, attrs, [ makeAST(EUse(webModule, [ makeAST(EAtom("html")) ])) ].concat(body)), n.metadata, n.pos);
                            } else {
                                n;
                            }
                        default:
                            n;
                    }
                });
            }
        });

        // Rewrite Phoenix.Presence.* calls to <App>Web.Presence.* where appropriate
        passes.push({
            name: "PresenceApiModuleRewrite",
            description: "Rewrite Phoenix.Presence.track/update/list/untrack to <App>Web.Presence.*",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.presenceApiModuleRewritePass
        });

        // Rewrite <App>.Presence.* to <App>Web.Presence.* (qualified module form)
        passes.push({
            name: "PresenceQualifiedModuleRewrite",
            description: "Rewrite <App>.Presence.* calls to <App>Web.Presence.*",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.PresenceQualifiedModuleRewriteTransforms.transformPass
        });

        // Preserve effectful Presence statements even when results are unused
        passes.push({
            name: "PresenceBareCallPreserve",
            description: "Rewrite bare Presence.track/update/untrack statements to `_ = ...` to preserve effects",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.PresenceBareCallPreserveTransforms.transformPass
        });

        // Normalize bare Presence.* call before trailing `socket` to `socket = Presence.*(...)` within presence modules
        passes.push({
            name: "PresenceWithSocketAssignNormalize",
            description: "In presence modules ending with `socket`, rewrite bare Presence.* call to `socket = Presence.*(...)`",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.PresenceWithSocketAssignNormalizeTransforms.pass
        });

        // Normalize LiveView noreply return atoms
        passes.push({
            name: "LiveNoreplyAtomFix",
            description: "Rewrite {:no_reply, socket} to {:noreply, socket} (shape-based)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.LiveNoreplyAtomFixTransforms.transformPass
        });
        // Inject alias for SafePubSub if bare module is referenced
        passes.push({
            name: "SafePubSubAliasInject",
            description: "Insert alias Phoenix.SafePubSub as SafePubSub when referenced",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.SafePubSubAliasInjectTransforms.injectPass
        });

        // Normalize Presence helpers to avoid Atom.to_string on Presence string keys
        passes.push({
            name: "PresenceHelpersNormalization",
            description: "(disabled) Do not rewrite Presence key helpers; preserve original shapes",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.PresenceHelpersTransforms.presenceHelpersNormalizationPass
        });
        // Presence ERaw normalization for Reflect.fields expansion
        passes.push({
            name: "PresenceERawNormalization",
            description: "(disabled) Do not rewrite ERaw Map.keys pipelines inside Presence modules",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.PresenceERawTransforms.erawPresenceKeysNormalizePass
        });
        // Presence list-building reduce rewrite
        passes.push({
            name: "PresenceReduceRewrite",
            description: "Rewrite Presence Enum.each + Reflect.fields list construction to Enum.reduce(Map.values(map), [], ...) with conditional append",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.PresenceReduceRewriteTransforms.presenceReduceRewritePass
        });
        // Presence shadowed binder rename inside EFn clauses (entry vs item clashes)
        passes.push({
            name: "PresenceEFnShadowedBinderRename",
            description: "Rename shadowed anonymous-fn binders (e.g., item) to entry to avoid warnings",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.PresenceEFnShadowedBinderRenameTransforms.pass
        });
        // Localize Phoenix.Presence.* calls to current Presence module
        passes.push({
            name: "PresenceRouteLocalize",
            description: "Inside Presence modules, rewrite Phoenix.Presence.* to current module",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.PresenceRouteLocalizeTransforms.pass
        });
        // Safety net: qualify bare SafePubSub to Phoenix.SafePubSub
        passes.push({
            name: "SafePubSubAliasFix",
            description: "Fix bare SafePubSub references to Phoenix.SafePubSub",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.SafePubSubAliasFixTransforms.fixPass
        });
        passes.push({
            name: "SafePubSubFix",
            description: "Fix binder mismatch in Phoenix.SafePubSub.is_valid_message/1",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.SafePubSubFixTransforms.transformPass
        });
        // Fix Telemetry.start_link children var name mismatch
        passes.push({
            name: "TelemetryChildrenArgFix",
            description: "Use _children in Supervisor.start_link when assignment was underscored",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.TelemetryChildrenArgFixTransforms.fixPass
        });
        // Promote LiveView mount/3 third parameter to `socket` and rewrite body references
        passes.push({
            name: "LiveMountSocketParamPromote",
            description: "Promote mount/3 third param to `socket` (shape-based, no app coupling)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.LiveViewMountSocketParamPromoteTransforms.promotePass
        });
        // Very late fallback promotion to ensure no underscored socket leaks
        passes.push({
            name: "LiveMountLatePromote",
            description: "Late safety net: rename mount/3 third param to `socket` and rewrite body refs",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.LiveViewMountLatePromoteTransforms.pass
        });
        // LiveView mount flow normalization to restore required binders
        passes.push({
            name: "LiveMountNormalize",
            description: "Normalize LiveView mount/3: promote discards to named binders and bind updated_socket",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.LiveMountNormalizeTransforms.pass
        });
        // LiveView mount/3 return finalization
        // (registered once at the end; removed duplicate earlier registration)
        passes.push({
            name: "WildcardPromoteByUndeclaredUse",
            description: "Promote `_ = rhs` to named binder when a single undeclared var is used later",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.WildcardPromoteByUndeclaredUseTransforms.pass
        });
        // Final safety: inline [] for Supervisor.start_link(children, opts) in Telemetry modules
        passes.push({
            name: "SupervisorStartLinkChildrenInlineFix",
            description: "Inline [] for Supervisor.start_link(children, ...) in <App>Web.Telemetry",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.SupervisorStartLinkChildrenInlineFixTransforms.pass
        });
        // Fix anon fn arg binder underscore vs usage mismatch (e.g., fn _t -> t.id end)
        passes.push({
            name: "AnonFnArgBinderFix",
            description: "Rename underscore binders when body uses non-underscore variant",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.AnonFnArgBinderFixTransforms.fixPass
        });

        // Remove unused imports like Ecto.Changeset when unreferenced
        passes.push({
            name: "UnusedImportCleanup",
            description: "Remove import Ecto.Changeset when module not used",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.UnusedImportCleanup.cleanupPass
        });
        // Drop unused local assignments entirely when safe (side-effects preserved)
        passes.push({
            name: "LocalAssignDiscardIfUnused",
            description: "Replace `var = expr` with `expr` when var is never referenced later in the block",
            enabled: false, // disabled after SafeAssigns false positive; refine before enabling
            pass: reflaxe.elixir.ast.transformers.LocalAssignDiscardIfUnusedTransforms.pass
        });

        // Focused cleanup: drop unused Enum.* assigns to underscore (safe, limited scope)
        passes.push({
            name: "DropUnusedEnumAssignToUnderscore",
            description: "Rewrite unused assigns to Enum.map/filter/... into `_ = ...` (snapshot canonical)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.DropUnusedEnumAssignToUnderscoreTransforms.pass
        });

        // Drop trivial unused alias locals introduced by hygiene passes
        passes.push({
            name: "DropUnusedSimpleAliasToUnderscore",
            description: "Rewrite `tmp2 = value` style numeric-suffix aliases to `_ = value` when unused",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.DropUnusedSimpleAliasToUnderscoreTransforms.pass
        });

        // Repair invalid nested match shapes produced by earlier cleanups
        passes.push({
            name: "FlattenNestedMatchLhs",
            description: "Flatten `( _ = call1 ) = call2` to two sequential underscore assignments",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.FlattenNestedMatchLhsTransforms.pass
        });

        // Hoist nested `= name` from inside string concatenations on RHS
        passes.push({
            name: "HoistNestedAssignFromStringConcat",
            description: "Hoist `(name = expr)` out of `left <> (...)` then use `name` in concat",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.HoistNestedAssignFromStringConcatTransforms.pass
        });

        // Final safety: split illegal call=call matches into two effectful calls
        passes.push({
            name: "FixCallEqualsCall",
            description: "Rewrite `call() = call()` into two underscore-discarded calls",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.FixCallEqualsCallTransforms.pass
        });

        // Defensive: normalize any blank match LHS to underscore to avoid invalid syntax
        passes.push({
            name: "NormalizeBlankMatchLhsToUnderscore",
            description: "Replace empty LHS in match with `_`",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.NormalizeBlankMatchLhsToUnderscoreTransforms.pass,
            runBefore: ["WildcardPromoteByUndeclaredUse"]
        });

        // Absolute last safety net on assignment LHS identifiers
        passes.push({
            name: "SanitizeAssignLhsIdentifier",
            description: "Ensure LHS of match is a valid identifier; fallback to `_` otherwise",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.SanitizeAssignLhsIdentifierTransforms.pass,
            runBefore: ["WildcardPromoteByUndeclaredUse"],
            runAfter: ["NormalizeBlankMatchLhsToUnderscore"]
        });

        // Usage-driven recovery: promote `_ = rhs` to the unique undeclared variable used soon after
        passes.push({
            name: "PromoteUnderscoreAssignToUniqueUndeclared",
            description: "Promote `_` assignment to unique undeclared variable referenced in a small lookahead window",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.PromoteUnderscoreAssignToUniqueUndeclaredTransforms.pass,
            runAfter: ["SanitizeAssignLhsIdentifier"],
            runBefore: ["WildcardPromoteByUndeclaredUse"]
        });

        // Module-local: prune private functions that are not referenced
        passes.push({
            name: "UnusedDefpPrune",
            description: "Drop defp helpers not referenced within module",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.UnusedDefpPrune.prunePass
        });
        
        // Late safety net: normalize String.to_atom/1 and to_existing_atom/1 to literals where safe
        passes.push({
            name: "StringToAtomLiteral",
            description: "Convert String.to_atom(\"field\") to :field when argument is a literal string",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.stringToAtomLiteralPass
        });

        // Qualify single-segment modules inside ERaw strings within <App>Web.* (run very late to catch late ERaw injections)
        passes.push({
            name: "ERawWebModuleQualification",
            description: "Qualify single-segment modules inside ERaw within Web modules (final)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.erawWebModuleQualificationPass
        });

        // Promote underscored LiveView params where they are used (handle_event/3, mount/3)
        passes.push({
            name: "HandleEventParamsPromote",
            description: "Rename handle_event/3 `_params` to `params` when referenced and rewrite body",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.HandleEventParamsPromoteTransforms.pass,
            runAfter: ["DefParamUnusedUnderscoreSafe"]
        });
        // (Temporarily disabled) Mount param promotion can interact with local
        // temp binders in some shapes; keep handle_event promotion only.
        passes.push({
            name: "MountParamsPromote",
            description: "Rename mount/3 `_params` to `params` when referenced and rewrite body",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.MountParamsPromoteTransforms.pass
        });

        // Normalize ERaw validate_required lists, validate_length field argument, opts nil comparisons (run at the very end)
        passes.push({
            name: "ERawEctoValidateAtomNormalize",
            description: "Normalize ERaw validate_* atoms and opts nil comparisons (final)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EctoERawTransforms.erawEctoValidateAtomNormalizePass
        });

        // Absolute-final: enforce handle_event/3 second param name `params`
        // and rewrite body references from old binder (e.g., _params) → params.
        passes.push({
            name: "HandleEventParamsUltraFinal",
            description: "Ensure handle_event/3 uses `params` as second arg and align body refs (absolute-final)",
            enabled: false, // re-inserted later as absolute last
            pass: reflaxe.elixir.ast.transformers.HandleEventParamsUltraFinalTransforms.transformPass
        });
        passes.push({
            name: "MountParamsUltraFinal",
            description: "Ensure mount/3 uses `params` as first arg and align body refs (absolute-final)",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.MountParamsUltraFinalTransforms.transformPass
        });
        // Repair malformed mount heads to canonical arity and names prior to ultra-final param normalization
        passes.push({
            name: "LiveMountArityRepair",
            description: "Coerce mount heads to arity-3 and rename binders to params/_session/socket",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.LiveMountArityRepairTransforms.pass,
            runAfter: ["MountParamsPromote"]
        });
        // Ensure inline if inside containers are parenthesized to avoid parser ambiguity
        passes.push({
            name: "IfInlineInContainerParen",
            description: "Wrap inline if-expressions inside tuples/lists/maps in parentheses (absolute-final)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.IfInlineInContainerParenTransforms.pass
        });
        // Global variant for non-LiveView contexts (e.g., PubSub helpers)
        passes.push({
            name: "InlineIfInContainersGlobal",
            description: "Wrap inline if-expressions in tuples/lists/maps (global contexts)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.InlineIfInContainersGlobalTransforms.pass
        });
        // Generic: underscore unused case/with pattern vars
        passes.push({
            name: "CasePatternUnusedUnderscore",
            description: "Underscore unused variables bound in case/with patterns",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CasePatternUnusedUnderscoreTransforms.pass
        });
        passes.push({
            name: "CasePatternUnderscorePromotion",
            description: "Promote `_name` pattern binders to `name` when the body references `name`",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CasePatternUnderscorePromotionTransforms.pass
        });
        passes.push({
            name: "CaseBodyAlignToPatternUnderscore",
            description: "Rewrite body references to match underscored pattern binders in case/with clauses",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseBodyAlignToPatternUnderscoreTransforms.pass
        });
        passes.push({
            name: "LocalUnderscoreUsedPromotion",
            description: "Promote local `_name` binders to `name` when actually used (warnings cleanup)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.LocalUnderscoreUsedPromotionTransforms.pass
        });
        passes.push({
            name: "LocalUnderscoreUsedPromotion_Final",
            description: "Final replay: promote `_this` and similar underscore locals when referenced",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.LocalUnderscoreUsedPromotionTransforms.pass
        });
        passes.push({
            name: "InlineUnderscoreTempUsedOnce",
            description: "Inline `_tmp = expr` followed by single-use of `_tmp` in next statement",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.InlineUnderscoreTempUsedOnceTransforms.pass
        });
        passes.push({
            name: "InlineUnderscoreTempUsedOnce_Final",
            description: "Final replay: inline immediate-use underscore temps inside nested blocks",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.InlineUnderscoreTempUsedOnceTransforms.pass
        });
        passes.push({
            name: "MountBodyAlignToHead_Final",
            description: "Align body references (params/_params) to mount/3 head binder (absolute-final)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.MountBodyAlignToHeadTransforms.pass,
            runAfter: ["MountParamsUltraFinal", "MountParamsPromote"]
        });
        // Drop redundant `session = Map.get(params, "session")` when mount/3 already receives session
        passes.push({
            name: "MountSessionExtractCleanup",
            description: "Remove session extraction from params in mount/3; use real session arg",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.MountSessionExtractCleanupTransforms.pass
        });
        passes.push({
            name: "MountDropHeadIdentityReassign_Final",
            description: "Drop trivial head reassignments (session/socket/params) inside mount/3",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.MountDropHeadIdentityReassignTransforms.pass,
            runAfter: [
                "MountBodyAlignToHead_Final",
                "MountSessionExtractCleanup_Final",
                "MountParamsSideEffectAssignDiscard_Final"
            ]
        });
        passes.push({
            name: "HandleEventBodyAlignToHead_Final",
            description: "Align body references (params/_params) to handle_event/3 head binder (absolute-final)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.HandleEventBodyAlignToHeadTransforms.pass,
            runAfter: ["HandleEventParamsUltraFinal"]
        });
        // HandleEvent local hygiene: underscore unused local Map.get extractions
        passes.push({
            name: "HandleEventLocalUnusedUnderscore_Final",
            description: "Rename unused local binders in handle_event/3 to underscore (shape-based)",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.HandleEventLocalUnusedUnderscoreTransforms.pass,
            runAfter: [
                "HandleEventParamsUltraFinal",
                "HandleEventParamsUltraFinal_Last",
                "HandleEventBodyAlignToHead_Final",
                "ParamUnderscoreGlobalAlign_Final",
                "DefParamHeadUnderscoreWhenUnused_Final"
            ]
        });
        // Inject @compile nowarn for local Ecto DSL shims (from/3, where/3)
        passes.push({
            name: "EctoLocalShimNowarn",
            description: "Inject @compile {:nowarn_unused_function, [from: 3, where: 3]} when local DSL shims are present",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EctoLocalShimNowarnTransforms.transformPass
        });
        passes.push({
            name: "EctoQueryIfAssignSimplify",
            description: "Simplify inner `query =` inside if-branches for Ecto.Query.where",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EctoQueryIfAssignSimplifyTransforms.pass,
            runAfter: [
                "EctoQueryBranchSelfAssignUnderscore",
                "AssignWhereSelfBinderUnderscore"
            ]
        });
        passes.push({
            name: "EctoQueryBranchSelfAssignUnderscore",
            description: "In branch tails, rewrite `x = Ecto.Query.where(x, ..)` to `_x = ...`",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EctoQueryBranchSelfAssignUnderscoreTransforms.pass
        });
        passes.push({
            name: "AssignWhereSelfBinderUnderscore",
            description: "Rewrite `x = Ecto.Query.where(x, ...)` to `_x = ...` everywhere in bodies",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.AssignWhereSelfBinderUnderscoreTransforms.pass
        });
        // Safety: drop invalid self-assignments of Map.get/2 that can be introduced
        // by alignment passes; must run late after other body rewrites.
        passes.push({
            name: "DropInvalidMapGetSelfAssign",
            description: "Remove `Map.get(params, key) = Map.get(params, key)` statements in function bodies",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.DropInvalidMapGetSelfAssignTransforms.pass
        });
        // Migration: inject nowarn + stubs (scheduled in absolute-final section below for final shapes)
        passes.push({
            name: "EctoMigrationNowarnAndStubs",
            description: "(Deferred) Inject @compile nowarn and defp stubs for migration helpers at absolute-final",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.EctoMigrationNowarnAndStubTransforms.transformPass
        });
        // Qualify StringBuf usage to <App>.StringBuf inside Ecto DSL shim modules
        passes.push({
            name: "EctoStringBufQualification",
            description: "Qualify bare StringBuf.* to <App>.StringBuf.* in modules with Ecto DSL shims",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EctoStringBufQualificationTransforms.transformPass
        });
        // Normalize ERaw opts.* access in keyword lists to Map.get to avoid typing warnings
        passes.push({
            name: "ERawEctoOptsAccessNormalize",
            description: "Rewrite opts.* in ERaw keyword lists to Map.get(opts, :key)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EctoERawTransforms.erawEctoOptsAccessNormalizePass
        });
        // Rewrite ERaw Ecto.Queryable.to_query(:atom) to <App>.<CamelCase> (final sweep)
        passes.push({
            name: "ERawEctoQueryableToSchema",
            description: "Rewrite ERaw to_query(:atom) to schema module <App>.<Camel>",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EctoERawTransforms.erawEctoQueryableToSchemaPass
        });

        // Presence ERaw cleanup: remove constant-true if and trailing acc in reduce bodies
        passes.push({
            name: "PresenceERawCleanup",
            description: "Sanitize ERaw reduce bodies in Presence modules (drop if 1 and trailing acc)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.PresenceERawCleanupTransforms.transformPass
        });

        // Absolute last: ensure declarations and references agree after all prior rewrites
        passes.push({
            name: "RefDeclAlignment",
            description: "Absolute final alignment of local names to canonical spelling",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.RefDeclAlignmentTransforms.alignLocalsPass
        });
        // Align def/defp parameters with body usage before fixing underscored refs
        passes.push({
            name: "DefParamBinderAlignByBodyUse",
            description: "Promote underscored def params to base names when body uses base; rewrite body refs",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.DefParamBinderAlignByBodyUseTransforms.alignPass
        });
        // Final safety: fix references to underscored variants of function params
        passes.push({
            name: "DefParamUnderscoreRefFix",
            description: "Rewrite _param references to param when only param is declared",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.DefParamUnderscoreRefFixTransforms.fixPass
        });
        // Absolute sweep to ensure no stray numeric literals or bare increments remain anywhere
        passes.push({
            name: "ArithmeticIncrementCleanup",
            description: "Final sweep: drop bare numeric literals and normalize increments",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ArithmeticIncrementTransforms.transformPass
        });
        passes.push({
            name: "ReduceWhileSentinelCleanup",
            description: "Final sweep: drop numeric sentinels inside reduce_while bodies",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ReduceWhileSentinelCleanupTransforms.transformPass
        });
        passes.push({
            name: "UnderscoreLocalPromotion",
            description: "Promote `_name` local binders to `name` when referenced and safe",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.UnderscoreLocalPromotionTransforms.pass
        });
        // Ultra-final: underscore unused local assignments (same-block conservative)
        passes.push({
            name: "UnusedLocalAssignUnderscoreFinal",
            description: "Rename unused local assignment binders `name = expr` to `_name` (same-block only)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.UnusedLocalAssignUnderscoreFinalTransforms.pass
        });
        // Split chained assignments a = b = expr into two statements (late readability/shape cleanup)
        passes.push({
            name: "SplitChainedAssignments",
            description: "Rewrite a = b = expr into: b = expr; a = b (improves reduce_while body shapes)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.SplitChainedAssignmentsTransforms.transformPass
        });
        // Late binder harmonization for {:tag, binder} based on clause-local body usage
        // Safe after strengthening scope awareness (excludes function params and reserved names)
        passes.push({
            name: "CasePayloadBinderAlignByBodyUse",
            description: "(late) Rename {:tag, binder} to the clause's sole undefined local used in body (scope-aware)",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.CasePayloadBinderAlignByBodyUseTransforms.alignPass
        });
        passes.push({
            name: "DropStandaloneLiteralOne",
            description: "Ultra-final sweep to remove any bare numeric sentinels left by late injections",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.DropStandaloneLiteralOneTransforms.dropPass
        });

        // Simplify if-branches with constant conditions (true/false/1/0)
        passes.push({
            name: "IfConstSimplify",
            description: "Simplify if true/1 and if false/0 conditionals",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.IfConstSimplifyTransforms.transformPass
        });

        // Ultra-final: remove unused Repo alias if not referenced in module body
        passes.push({
            name: "UnusedRepoAliasCleanupFinal",
            description: "Remove `alias <App>.Repo, as: Repo` when `Repo` isn’t referenced",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.UnusedRepoAliasCleanupFinalPass.pass
        });

        // Absolute late sweep: inline HEEx content when possible, then ensure assigns capture if needed
        passes.push({
            name: "HeexContentInline",
            description: "Replace ~H raw(content|@var) using preceding literal assignment with direct ~H literal",
            enabled: true,
            pass: reflaxe.elixir.ast.ElixirASTTransformer.alias_heexContentInlinePass
        });
        passes.push({
            name: "ParamUnderscoreArgRefAlign",
            description: "Rewrite `_params` to `params` in defs that have a `params` arg",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ParamUnderscoreArgRefAlignTransforms.pass
        });
        passes.push({
            name: "ParamUnderscoreArgRefAlign_Global",
            description: "Align body references to underscored head params globally (e.g., v → _v)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ParamUnderscoreArgRefAlignGlobalTransforms.pass,
            runAfter: ["DefParamUnusedUnderscoreGlobalSafe_Final"]
        });

        // Robust inliner: works on render/1 EBlock/EDo, nested parens, any var name
        passes.push({
            name: "HeexInlineCapturedContent",
            description: "Inline string assigned to a var referenced by Phoenix.HTML.raw(var|@var) inside ~H; drop scaffolding",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.HeexInlineCapturedContentTransforms.transformPass
        });

        // Fallback inliner using simple preceding-literal heuristic
        passes.push({
            name: "HeexRawInlineFromPrecedingLiteral",
            description: "Inline preceding string literal into ~H and drop Phoenix.HTML.raw(var) usage (heuristic)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.HeexRawInlineFromPrecedingLiteralTransforms.pass
        });

        // As a last resort, capture into assigns and rewrite raw(var) → raw(@var)
        passes.push({
            name: "HeexAssignsCapture",
            description: "Ensure @var usage inside ~H and assign var into assigns when inlining isn't possible",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.HeexAssignsCaptureTransforms.transformPass
        });

        // Validate that no Phoenix.HTML.raw(content) remains in ~H after inlining
        passes.push({
            name: "HeexRawUsageValidator",
            description: "Warn on residual Phoenix.HTML.raw(content|@content) inside ~H",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.HeexRawUsageValidatorTransforms.pass,
            contextualPass: reflaxe.elixir.ast.transformers.HeexRawUsageValidatorTransforms.contextualPass
        });

        // Post-capture cleanup: inline HXX.block calls again and strip accidental dangling quotes
        passes.push({
            name: "HeexRewriteHxxBlock",
            description: "(late) Replace <%= HXX.block(...) %> residue after capture inlining",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.HeexRewriteHxxBlockTransforms.transformPass
        });
        // After inlining captured ~H content, some earlier inline-if constructs may have
        // been converted to block-if by upstream conversions. Run the block→inline pass
        // again late to normalize simple HTML branches back to inline form, matching
        // snapshot expectations and improving readability.
        passes.push({
            name: "HeexBlockIfToInline",
            description: "(late) Rewrite <%= if ... do %>HTML<% else %>HTML<% end %> to inline-if",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.HeexBlockIfToInlineTransforms.transformPass
        });
        passes.push({
            name: "HeexStripDanglingQuoteLines",
            description: "(late) Drop lines that are solely a quote in ~H",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.HeexStripDanglingQuoteLinesTransforms.transformPass
        });

        // Absolute-final: convert unused local assignments to wildcard `_ = expr`
        passes.push({
            name: "LocalAssignUnusedToWildcard_AbsoluteFinal",
            description: "Rewrite name = expr to _ = expr when name is unused later in the same block",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.LocalAssignUnusedToWildcardFinalTransforms.pass
        });

        // Ultra-final: split any remaining chained assignments
        passes.push({
            name: "SplitChainedAssignments_Final",
            description: "(ultra-final) Ensure no a = b = expr remains in blocks/EDo",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.SplitChainedAssignmentsTransforms.transformPass
        });

        // Phoenix enum modules (generated) → ensure atom-tag tuples (no numeric tags)
        passes.push({
            name: "PhoenixEnumAtomTag",
            description: "Rewrite Phoenix.* enum helpers from numeric tags to atom tags using function names",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.PhoenixEnumAtomTagTransforms.transformPass
        });

        // Flatten nested case for Option/Result-style constructs where a branch matches
        // {:some, v} and immediately switches on v. This restores single-case nested
        // tuple patterns like {:some, {:todo_created, todo}}.
        passes.push({
            name: "CaseFlattenNestedSwitch",
            description: "Flatten {:some, v} -> case v do ... end into combined nested tuple patterns",
            enabled: #if enable_case_flatten_nested_switch false #else false #end,
            pass: reflaxe.elixir.ast.transformers.CaseFlattenNestedSwitchTransforms.transformPass
        });

        // Prune completely empty defmodule bodies (post-DCE clean up noise)
        passes.push({
            name: "EmptyModulePrune",
            description: "Drop defmodule nodes with empty bodies to reduce noise",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EmptyModulePruneTransforms.transformPass
        });
        
        // Late safety net: re-run Repo qualification after all transformations
        passes.push({
            name: "RepoQualification",
            description: "Re-run Repo qualification to catch any bare Repo.* introduced by prior passes; shape-derived from <App>Web.*",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.repoQualificationPass
        });

        // Global Repo qualification (non-Web modules) using -D app_name define
        passes.push({
            name: "RepoQualification",
            description: "Qualify bare Repo.* to <App>.Repo.* in all modules based on app_name define",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.globalRepoQualificationPass
        });

        // Global Repo alias injection for any module that references Repo.*
        passes.push({
            name: "RepoAliasInjection",
            description: "Inject alias <App>.Repo as Repo in any module referencing Repo.*",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.repoAliasInjectionGlobalPass
        });

        // Qualify project-local support modules (e.g., UserChangeset) to <App>.<Name>
        // in repository/query contexts without adding aliases
        passes.push({
            name: "SupportModuleQualification",
            description: "Qualify single-segment CamelCase modules to <App>.<Name> when module is project-local and context uses Repo or Ecto DSL",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.SupportModuleQualificationTransforms.transformPass
        });

        // Global, project-local call-site module qualification to align with expected app-qualified names
        passes.push({
            name: "ProjectLocalModuleQualification",
            description: "Qualify call-sites of single-segment project-local modules to <App>.<Name>",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ProjectLocalModuleQualificationTransforms.transformPass
        });

        // Late alias injection to ensure Repo alias exists when used
        passes.push({
            name: "RepoAliasInjection",
            description: "Inject alias <App>.Repo as Repo in Web modules if Repo.* is referenced",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.repoAliasInjectionPass
        });

        // Late sweep: collapse nested aliasing chains like `lhs = g = expr` when alias is unused.
        passes.push({
            name: "AssignmentChainCleanupLate",
            description: "Late sweep to collapse nested aliasing chains (lhs = g = expr) when alias is unused",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.AssignmentChainCleanupTransforms.transformPass
        });

        // Absolute final binder promotion: ensure _name -> name when name is referenced later
        passes.push({
            name: "LocalUnderscoreBinderPromote",
            description: "Final promotion of local binders _name to name when body references name",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.LocalUnderscoreBinderPromoteTransforms.promotePass
        });

        // PRIOR to string->~H conversion, ensure string interpolations of HEEx/html vars
        // are wrapped with Phoenix.HTML.raw(var)
        passes.push({
            name: "HeexInlineRawForHeexVarsInStrings",
            description: "Rewrite \"#{var}\" to \"#{Phoenix.HTML.raw(var)}\" for vars bound from ~H/HTML",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.HeexInlineRawForHeexVarsInStringsTransforms.transformPass
        });

        // Convert LiveView render(assigns) returning HTML strings to ~H
        passes.push({
            name: "HeexRenderStringToSigil",
            description: "Ensure render(assigns) returns ~H by converting final HTML strings to ~H",
            enabled: #if hxx_string_to_sigil true #else false #end,
            pass: reflaxe.elixir.ast.transformers.HeexRenderStringToSigilTransforms.transformPass
        });

        // Prefer typed ~H emission from EFragment/EAttribute when available (guarded)
        passes.push({
            name: "HeexPreferTypedEmission",
            description: "Prefer ~H content from typed HEEx AST when safe (attributes/children)",
            enabled: #if hxx_prefer_efragment true #else false #end,
            pass: reflaxe.elixir.ast.transformers.HeexPreferTypedEmissionTransforms.transformPass
        });

        // Convert helper functions that still return HTML strings to ~H sigils so nested
        // content embedded via <%= helper(...) %> is rendered as HEEx rather than escaped.
        // NOTE: This must run BEFORE any underscore-renaming of the `assigns` parameter,
        // because HEEx requires the parameter to be named exactly `assigns`.
        // HEEx/HXX main group (order preserved)
        passes = passes.concat(reflaxe.elixir.ast.transformers.registry.groups.HeexMain.build());

        // After ~H sigils are materialized, rewrite HXX control tags to proper HEEx blocks
        passes.push({
            name: "HeexControlTagTransforms",
            description: "Rewrite HXX-style <if>/<else> control tags in ~H content to HEEx blocks",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.HeexControlTagTransforms.transformPass
        });

        // Strip unnecessary .to_string() inside HEEx interpolations

        // Simplify trivial IIFE wrappers inside HEEx interpolations for readability/snapshots

        // Qualify single-segment remote call modules inside Web.* namespaces (AppWeb prefix)

        // Rename `_assigns` parameter to `assigns` when function body contains ~H

        // After ~H materialization and control-tag normalization, wrap interpolated
        // variables that are HEEx fragments/HTML strings with Phoenix.HTML.raw(var)

        // After converting to ~H, ensure `use Phoenix.Component` is present so the
        // sigil is available. This ordering guarantees detection.

        // Transitional safety: wrap helper calls inside ~H so they render unescaped while
        // we migrate remaining helpers to return ~H. This pass targets only render_* calls
        // and will be removed once all helpers are ~H (tracked in tasks).


        // Final HEEx control tag rewrite removed; handled by main HeexControlTagTransforms earlier

        // Assigns type linter: validate @field usage in ~H against typed assigns typedef

        // Ensure assigns exists for helpers that contain ~H sigils but lack assigns parameter

        // Phoenix-scoped hygiene: underscore unused def/defp parameters in Web/Live/Presence modules
        passes.push({
            name: "DefParamUnusedUnderscore",
            description: "Prefix unused function parameters with underscore in Phoenix Web/Live/Presence modules",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.DefParamUnusedUnderscoreTransforms.transformPass
        });

        // Run parameter underscore cleanup again late to catch usage removed by prior passes
        passes.push({
            name: "DefParamUnusedUnderscore",
            description: "Late sweep: underscore unused def/defp params in Phoenix modules",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.DefParamUnusedUnderscoreTransforms.transformPass
        });

        // Final safety: rename references name -> _name when only underscored binder exists
        passes.push({
            name: "LocalUnderscoreReferenceFallback",
            description: "Fallback renaming of EVar(name) -> EVar(_name) when only _name declared (final)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.LocalUnderscoreReferenceFallbackTransforms.fallbackUnderscoreReferenceFixPass
        });
        // Ultra-final Phoenix sweeps: underscore unused case binders and params
        passes.push({
            name: "ClauseUnusedBinderUnderscore",
            description: "Ultra-final underscore of unused case binders in Phoenix modules",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.ClauseUnusedBinderUnderscoreTransforms.clauseUnusedBinderUnderscorePass
        });
        passes.push({
            name: "DefParamUnusedUnderscore",
            description: "Ultra-final underscore of unused def/defp params in Web/Live/Presence",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.DefParamUnusedUnderscoreTransforms.transformPass
        });
        // Final: discard top-level nil assignments in function bodies when unused
        passes.push({
            name: "TopLevelNilAssignDiscard",
            description: "Rewrite var = nil to _ = nil when var is not used later in function",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.TopLevelNilAssignDiscardTransforms.transformPass
        });
        // Absolutely last: promote underscore binders by use one more time
        passes.push({
            name: "CaseUnderscoreBinderPromoteByUse",
            description: "Absolute sweep: promote _name binders when body uses name (disabled for snapshot parity)",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.CaseUnderscoreBinderPromoteByUseTransforms.transformPass
        });
        // Absolutely last: unify {:ok, var} success var references in clause body
        passes.push({
            name: "CaseSuccessVarUnifier",
            description: "Absolute sweep: replace undefined refs in {:ok, var} clause bodies with var",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseSuccessVarUnifier.unifySuccessVarPass
        });
        // Extra absolute: promote underscore binders {:ok,_x} -> {:ok,x} when body references x
        passes.push({
            name: "CaseSuccessVarUnify",
            description: "Promote {:ok, _x} binder to {:ok, x} when body references x (extra absolute)",
            enabled: true, // Re-enabled with lock-aware skipping
            pass: reflaxe.elixir.ast.transformers.CaseSuccessVarUnifyTransforms.transformPass
        });
        // (Moved to absolute end): Success binder/var alignment passes run at the end of pipeline
        // Absolute: rerun Enum.each sentinel cleanup after all earlier rewrites
        passes.push({
            name: "EnumEachSentinelCleanup",
            description: "Absolute sweep: drop bare numeric sentinels in Enum.each fn bodies",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.MapAndCollectionTransforms.enumEachSentinelCleanupPass
        });
        // Ultra-final: promote underscored case binders to base name when body uses base name
        passes.push({
            name: "CaseUnderscoreBinderPromoteByUse",
            description: "Promote _name -> name in case patterns when body uses name (ultra-final) (disabled for snapshot parity)",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.CaseUnderscoreBinderPromoteByUseTransforms.transformPass
        });
        // Ultra-final: unify success vars in {:ok, v} branches again to harmonize with late renames
        passes.push({
            name: "CaseSuccessVarUnifier",
            description: "Ultra-final unification of success var in {:ok, v} clauses",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseSuccessVarUnifier.unifySuccessVarPass
        });
        // Ultra-final: ensure {:ok, var} binder does not collide with function args after all renames
        passes.push({
            name: "CaseSuccessVarRenameCollisionFix",
            description: "Ultra-final rename of {:ok, var} binder to avoid arg collisions",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseSuccessVarRenameCollisionFixTransforms.transformPass
        });
        // Absolute-final: ensure query binder promotion inside search-guarded EIf branches
        passes.push({
            name: "QueryBinderFinalization",
            description: "Promote `_ = String.downcase(search_query)` to `query = ...` in guarded then-branches when Enum.filter appears later",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.QueryBinderFinalizationTransforms.transformPass
        });
        // Discard unused assignments inside closures (EFn clause bodies)
        passes.push({
            name: "ClosureUnusedAssignmentDiscard",
            description: "Rewrite var = expr to _ = expr in EFn bodies when var unused later",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ClosureUnusedAssignmentDiscardTransforms.discardPass
        });

        // Late re-qualification of application modules in Web contexts to catch newly
        // introduced calls by previous passes (shape-derived; avoids registry dependency)
        passes.push({
            name: "ModuleQualification",
            description: "Re-run Web-context <App>.Module qualification after later transforms",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.moduleQualificationPass
        });
        // Absolute final sweep: ensure Web EFns contain qualified application module calls
        passes.push({
            name: "WebEFnModuleQualification",
            description: "Final sweep to qualify single-segment modules inside <App>Web.* EFn bodies",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.webEFnModuleQualificationPass
        });
        // Absolute-final qualification: ensure no bare app modules remain in Web contexts
        passes.push({
            name: "AbsoluteFinalWebModuleQualification",
            description: "Absolute-final: qualify single-segment CamelCase modules to <App>.<Module> inside <App>Web.*",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.AbsoluteFinalWebModuleQualificationTransforms.pass
        });
        // Insert alias <App>.<Module> for bare module calls inside Web modules (safety net)
        passes.push({
            name: "AliasAppLocalModules",
            description: "Insert alias <App>.<Name> at top of <App>Web.* when bare <Name> is used in calls and module exists",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.AliasAppLocalModulesTransforms.pass
        });
        // Targeted final pass to ensure Enum.reduce_while bodies are qualified in Web modules
        passes.push({
            name: "WebReduceWhileEFnQualification",
            description: "Explicitly qualify single-segment modules inside Enum.reduce_while EFns in <App>Web.*",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.webReduceWhileEFnQualificationPass
        });
        passes.push({
            name: "SelfAssignCompression",
            description: "Compress duplicated self-assignments x = x = expr to x = expr",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.selfAssignCompressionPass
        });
        passes.push({
            name: "AssignChainPrune",
            description: "Prune unused binders in chain assignments and drop var=nil when unused",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.AssignChainPruneTransforms.prunePass
        });
        passes.push({
            name: "AssignChainGenericSimplify",
            description: "Simplify nested match chains by dropping unused side (generic)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.AssignChainGenericSimplifyTransforms.simplifyPass
        });
        // Simplify inner reassigns inside `if` expressions assigned to the same var
        passes.push({
            name: "IfInnerAssignSimplify",
            description: "Rewrite lhs = if do lhs = expr else lhs end → lhs = if do expr else lhs end",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.IfInnerAssignSimplifyTransforms.transformPass
        });

        // Merge result-assignment if-shapes by lifting inner rebind from then-branch
        passes.push({
            name: "IfResultAssignmentSimplify",
            description: "Simplify lhs = if do lhs = expr else lhs end to lhs = if do expr else lhs end (block-aware)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.IfResultAssignmentSimplifyTransforms.transformPass
        });

        // Qualify struct literals passed to changeset/2 inside <App>Web.* modules
        passes.push({
            name: "ChangesetStructQualification",
            description: "Ensure %Module{} struct argument to changeset/2 is qualified to %<App>.Module{} in Web modules",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.changesetStructQualificationPass
        });

        // Coalesce variables to empty map after nil-guard when fields are used
        passes.push({
            name: "NilGuardCoalesceToMap",
            description: "Insert v = %{} after if Kernel.is_nil(v) when v.field is used later",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.nilGuardCoalesceToMapPass
        });

        // Rewrite Haxe Date_Impl_ helpers to Elixir forms
        passes.push({
            name: "DateImplRewrite",
            description: "Map Date_Impl_.from_string/get_time to Elixir equivalents",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.dateImplRewritePass
        });

        // Convert Module.new() (Haxe-style) to %Module{} struct literal for Ecto schemas
        // NOTE: Prefer the guarded ModuleNewToStructLiteral pass; BinderTransforms variant disabled to avoid
        // rewriting non-schema modules (e.g., BalancedTree) into struct literals.
        // passes.push({
        //     name: "ModuleNewToStructLiteral",
        //     description: "Rewrite Module.new() to %Module{}",
        //     enabled: false,
        //     pass: reflaxe.elixir.ast.transformers.BinderTransforms.moduleNewToStructLiteralPass
        // });

        // Inline ~H content by replacing Phoenix.HTML.raw(content) with the actual string literal
        // assigned to `content` earlier in render(assigns), removing the intermediate var.
        passes.push({
            name: "HeexContentInline",
            description: "Inline ~H content to avoid accessing local variables inside templates",
            enabled: true,
            pass: reflaxe.elixir.ast.ElixirASTTransformer.alias_heexContentInlinePass
        });

        // Robust inliner: supports arbitrary variable names (raw(var|@var)), EBlock/EDo bodies,
        // nested parentheses, and ERaw(~H ...) forms. Runs after legacy simple inliner and
        // before fallback/validator passes.
        passes.push({
            name: "HeexInlineCapturedContent",
            description: "Inline ~H raw(var|@var) using last string assignment to that var; drop scaffolding",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.HeexInlineCapturedContentTransforms.transformPass
        });

        // (moved earlier) HeexStringReturnToSigil & HeexRenderHelperCallWrap now run before
        // parameter underscore passes to preserve the `assigns` binder required by HEEx.
        // See earlier registration for details.

        // Fallback sweep: capture into assigns when inlining isn't possible
        passes.push({
            name: "HeexAssignsCapture",
            description: "Replace ~H raw(content) with assigns capture for @content",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.HeexAssignsCaptureTransforms.transformPass
        });

        // Cleanup numeric no-op expressions and fix missed increments
        passes.push({
            name: "NumericNoOpCleanup",
            description: "Remove standalone numeric ops like 0 + 1 and convert bare count + 1 to assignments",
            enabled: true,
            pass: reflaxe.elixir.ast.ElixirASTTransformer.alias_numericNoOpCleanupPass
        });
        // Late sweep: drop sentinels inside Enum.each bodies
        passes.push({
            name: "EnumEachSentinelCleanup",
            description: "Drop bare numeric sentinels in Enum.each anonymous function bodies (final)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.MapAndCollectionTransforms.enumEachSentinelCleanupPass
        });
        passes.push({
            name: "EnumEachLhsDiscard",
            description: "Discard tuple LHS for Enum.each matches (shape-based cleanup)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.MapAndCollectionTransforms.enumEachLhsDiscardPass
        });
        passes.push({
            name: "ReduceWhileSentinelCleanup",
            description: "Drop numeric sentinel literals inside Enum.reduce_while function bodies",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ReduceWhileSentinelCleanupTransforms.transformPass
        });
        passes.push({
            name: "ReduceWhileToEnumEach",
            description: "Rewrite trivial reduce_while(Stream.iterate ...) scans to Enum.each",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ReduceWhileToEnumEachTransforms.transformPass
        });
        // Normalize Enum.filter predicates to structured EFn for deterministic downstream passes
        passes.push({
            name: "FilterPredicateNormalize",
            description: "Ensure Enum.filter/2 uses EFn(predicate) across call shapes; wrap captures/expressions",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.FilterPredicateNormalizeTransforms.pass
        });


        // New: Clean up Enum.each bodies and rewrite common idioms
        passes.push({
            name: "EnumEachHeadExtraction",
            description: "Inside Enum.each fns, replace head extraction list[0] with binder and drop sentinels",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.MapAndCollectionTransforms.enumEachHeadExtractionPass
        });
        passes.push({
            name: "EnumEachSentinelCleanup",
            description: "Drop bare numeric sentinels in Enum.each anonymous function bodies",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.MapAndCollectionTransforms.enumEachSentinelCleanupPass
        });
        passes.push({
            name: "EnumEachBinderIntegrity",
            description: "Ensure Enum.each bodies use binder (not list[0]); promote wildcard binder when needed",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.MapAndCollectionTransforms.enumEachBinderIntegrityPass
        });

        // HEEx final tidy-up
        passes = passes.concat(reflaxe.elixir.ast.transformers.registry.groups.HeexFinal.build());
        passes.push({
            name: "CountRewrite",
            description: "Rewrite accumulator-style counting loops to Enum.count(list, &pred/1)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.MapAndCollectionTransforms.countRewritePass
        });
        passes.push({
            name: "CountBinderNormalize",
            description: "Normalize underscored binder in Enum.count/2 (rename when used)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.MapAndCollectionTransforms.countBinderNormalizePass
        });
        passes.push({
            name: "MapJoinRewrite",
            description: "Collapse temp += concat inside Enum.each + Enum.join to Enum.map |> Enum.join",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.MapAndCollectionTransforms.mapJoinRewritePass
        });
        passes.push({
            name: "JoinArgListBuilderToMapJoin",
            description: "Rewrite Enum.join(<block temp-builder>, sep) to Enum.map(list, fn -> ...) |> Enum.join(sep)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.JoinArgListBuilderToMapJoinTransforms.transformPass
        });
        passes.push({
            name: "FunctionArgBlockToIIFE",
            description: "Wrap multi-statement EBlock arguments in (fn -> ... end).()",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.FunctionArgBlockToIIFETransforms.pass
        });
        // Presence reduce rewrite (early) to catch Presence.list scans before generic rewrites
        passes.push({
            name: "PresenceReduceRewrite",
            description: "Rewrite Presence Enum.each + Reflect.fields to Enum.reduce(Map.values(map), [], ...) with conditional append (early)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.PresenceReduceRewriteTransforms.presenceReduceRewritePass
        });
        // Presence safety: ensure concat accumulators have [] initialization if removed upstream
        passes.push({
            name: "PresenceConcatAccumulatorInit",
            description: "Insert acc=[] when Enum.concat(acc, [...]) appears without prior definition (Presence only)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.PresenceConcatAccumulatorInitTransforms.pass,
            runAfter: [
                "HeexTrimTrailingBlankLines_Final",
                "HeexCollapseOverEscapedQuotes_Final",
                "ParamUnderscoreGlobalAlign_Final",
                "HandleEventParamsForceBodyRewrite_Final",
                "HandleEventParamsUltraFinal_Last"
            ]
        });
        passes.push({
            name: "PresenceReduceWhileAccumulatorRepair",
            description: "Inject acc=[] and return acc for reduce_while loops missing initialization (Presence only)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.PresenceReduceWhileAccumulatorRepairTransforms.pass,
            runAfter: [
                "PresenceConcatAccumulatorInit",
                "HeexTrimTrailingBlankLines_Final",
                "HeexCollapseOverEscapedQuotes_Final",
                "ParamUnderscoreGlobalAlign_Final",
                "HandleEventParamsForceBodyRewrite_Final",
                "HandleEventParamsUltraFinal_Last"
            ]
        });
        // Presence finalizer: ensure get_users_editing_todo/2 initializes and returns accumulator
        passes.push({
            name: "PresenceInitMetasInGetUsersEditingTodo",
            description: "Presence-only: insert metas=[]; return metas in get_users_editing_todo/2",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.PresenceInitMetasInGetUsersEditingTodoTransforms.pass,
            runAfter: [
                "PresenceReduceWhileAccumulatorRepair",
                "PresenceConcatAccumulatorInit"
            ]
        });
        // Presence final: rewrite get_users_editing_todo/2 to Enum.reduce over Map.values
        passes.push({
            name: "PresenceRewriteGetUsersEditingTodoToReduce_Final",
            description: "Presence-only: rewrite get_users_editing_todo/2 to Enum.reduce(Map.values(...), [], fn entry, acc -> ... end)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.PresenceRewriteGetUsersEditingTodoToReduceTransforms.pass,
            runAfter: [
                "PresenceInitMetasInGetUsersEditingTodo",
                "PresenceReduceWhileAccumulatorRepair",
                "PresenceConcatAccumulatorInit"
            ]
        });
        passes.push({
            name: "MapConcatEachToMapAssign",
            description: "Rewrite temp=[], Enum.each(... temp=Enum.concat(temp,[expr]) ...) → temp = Enum.map(list, fn -> expr) end",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.MapAndCollectionTransforms.mapConcatEachToMapAssignPass
        });
        passes.push({
            name: "ConcatEachToReduce",
            description: "Rewrite temp=[], Enum.each(... if cond do temp=concat(temp,[expr]) end ...) → Enum.reduce(list, [], ...)",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.MapAndCollectionTransforms.concatEachToReducePass
        });
        passes.push({
            name: "FindRewrite",
            description: "Rewrite Enum.each scans ending with nil into Enum.find(list, &pred/1)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.MapAndCollectionTransforms.findRewritePass
        });
        // Avoid duplicate side-effect calls: reuse prior assignment as case scrutinee
        passes.push({
            name: "CaseCallReuse",
            description: "Rewrite case Mod.func(args) to case tmp when tmp = Mod.func(args) was evaluated earlier in block",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseCallReuseTransforms.transformPass
        });
        passes.push({
            name: "FlattenNestedUnderscoreAssign",
            description: "Flatten nested underscore matches: lhs = _ = expr -> lhs = expr",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.FlattenNestedUnderscoreAssignTransforms.pass
        });
        // Early fold to align assigned var with case result before later hygiene
        passes.push({
            name: "DuplicateCaseAssignFold_Early",
            description: "EARLY: Fold var = _ = call; case call do ... -> var = case call do ...",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.DuplicateCaseAssignFoldTransforms.pass
        });
        passes.push({
            name: "CaseBindSuccessToAssignedVar_Early",
            description: "EARLY: Bind {:ok, u} to preceding assigned var inside case",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseBindSuccessToAssignedVarTransforms.pass
        });
        passes.push({
            name: "CamelAtomAccessToSnake",
            description: "Rewrite EAccess(_, :camelCase) to snake_case atom keys",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CamelAtomAccessToSnakeTransforms.pass
        });
        // Drop underscore-only remote call when followed by case on identical call
        passes.push({
            name: "RedundantUnderscoreCallBeforeCase",
            description: "Remove `_ = Mod.func(args)` immediately before `case Mod.func(args) do ... end`",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.RedundantUnderscoreCallBeforeCaseTransforms.transformPass
        });
        // Unify success var names when body references non-underscore variant
        passes.push({
            name: "CaseSuccessVarUnify",
            description: "Rename {:ok, _x} -> {:ok, x} when body references x",
            enabled: true, // Re-enabled with lock-aware skipping
            pass: reflaxe.elixir.ast.transformers.CaseSuccessVarUnifyTransforms.transformPass
        });
        passes.push({
            name: "FnArgBodyRefNormalize",
            description: "Normalize body references of underscored variants to declared non-underscore binder in anonymous functions",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.MapAndCollectionTransforms.fnArgBodyRefNormalizePass
        });
        passes.push({
            name: "ArithmeticIncrementCleanup",
            description: "Rewrite standalone increments to assignments; drop bare numeric literals",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ArithmeticIncrementTransforms.transformPass
        });
        // Final sweep: ensure anonymous function binders don't keep a leading underscore
        // if they are actually referenced in the body (prevents "underscored variable used" warnings)
        passes.push({
            name: "AnonFnArgBinderFix",
            description: "Rename underscored fn binders and body references when used (no ERaw rewrites)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.AnonFnArgBinderFixTransforms.fixPass
        });
        passes.push({
            name: "FnArgBodyRefNormalize",
            description: "Normalize body refs _name -> name after late binder fixes",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.MapAndCollectionTransforms.fnArgBodyRefNormalizePass
        });
        passes.push({
            name: "EFnArgCleanup",
            description: "Final cleanup of EFn arg/body underscore mismatches",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EFnArgCleanupTransforms.cleanupPass
        });
        // Convert Enum.each counting patterns to Enum.count with predicate (early)
        passes.push({
            name: "CountEachToEnumCount_Early",
            description: "Early: rewrite Enum.each(list, fn b -> if cond, do: b = b + 1 end) → Enum.count(list, fn b -> cond end)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CountEachToEnumCountTransforms.transformPass
        });
        passes.push({
            name: "EFnScopedUnderscoreRefCleanup",
            description: "Rewrite _name -> name in EFn bodies when a matching binder exists",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EFnScopedUnderscoreRefCleanup.cleanupPass
        });
        // Align single-arg anonymous fn bodies to their binder when exactly one undefined var exists
        passes.push({
            name: "EFnSingleArgUndefinedAlign",
            description: "Rewrite single free var in 1-arg EFn body to binder (shape-based, no coupling)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EFnSingleArgUndefinedAlignTransforms.alignPass
        });
        // Early: also align when binder is used; prefer binder over single free var
        passes.push({
            name: "EFnSingleFreeVarToBinder_Early",
            description: "Early: rewrite single free var in 1-arg EFn to binder even if binder used",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EFnSingleFreeVarToBinderTransforms.pass
        });
        passes.push({
            name: "EFnFieldObjectToBinder_Early",
            description: "Early: rewrite EField(free, field) -> EField(binder, field) in 1-arg EFn bodies",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EFnFieldObjectToBinderTransforms.pass
        });
        passes.push({
            name: "EFnNumericSentinelCleanup",
            description: "Drop EInteger(0|1) and EFloat(0.0) statements in EFn bodies",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EFnNumericSentinelCleanupTransforms.cleanupPass
        });
        // Underscore unused anonymous fn args for Enum.each/map/reduce patterns
        passes.push({
            name: "EFnUnusedArgUnderscore",
            description: "Prefix unused EFn binders with underscore to avoid warnings",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EFnUnusedArgUnderscoreTransforms.transformPass
        });
        passes.push({
            name: "EFnForbiddenBinderRename",
            description: "Rename forbidden EFn binders (e.g., elem -> entry) and update body references",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EFnForbiddenBinderRenameTransforms.pass
        });
        passes.push({
            name: "EFnLocalAssignDiscard",
            description: "Replace unused local rebinds in EFn bodies with wildcard assignment",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EFnLocalAssignDiscardTransforms.discardPass
        });
        // Final binder/reference alignment in EFn to prevent _arg vs arg mismatches
        passes.push({
            name: "EFnBinderReferenceAlign",
            description: "Align EFn binders with body references: _name -> name when binder exists",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EFnBinderReferenceAlignTransforms.fixPass
        });
        // Replay forbidden binder rename very late to catch any newly generated anonymous fns
        passes.push({
            name: "EFnForbiddenBinderRename_Final",
            description: "Late pass: rename forbidden EFn binders (e.g., elem -> entry) post-normalization",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EFnForbiddenBinderRenameTransforms.pass
        });

        // Safety replay: ensure any late-emitted underscored refs are normalized
        passes.push({
            name: "EFnScopedUnderscoreRefCleanup",
            description: "Replay _name -> name rewrite in EFn bodies based on binders (late)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EFnScopedUnderscoreRefCleanup.cleanupPass
        });

        // Replay compression of x = x = expr at the very end to catch late-emitted chains
        passes.push({
            name: "SelfAssignCompression",
            description: "Final replay: compress duplicated self-assignments x = x = expr to x = expr",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.selfAssignCompressionPass
        });

        // Replay numeric sentinel cleanup inside EFn bodies (drop bare 1/0 literals)
        passes.push({
            name: "EFnNumericSentinelCleanup",
            description: "Replay: drop numeric sentinel literals in EFn bodies (1,0,0.0)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EFnNumericSentinelCleanupTransforms.cleanupPass
        });

        // Absolute last safety replays for EFn alignment and binder/body agreement
        passes.push({
            name: "EFnBinderReferenceAlign",
            description: "Absolute last: align EFn binders with body refs (_name -> name)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EFnBinderReferenceAlignTransforms.fixPass
        });
        passes.push({
            name: "EFnScopedUnderscoreRefCleanup",
            description: "Absolute last: rewrite _name -> name in EFn bodies when binder exists",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EFnScopedUnderscoreRefCleanup.cleanupPass
        });
        passes.push({
            name: "EFnSingleArgUndefinedAlign",
            description: "Absolute last: rewrite single free var in 1-arg EFn body to binder",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EFnSingleArgUndefinedAlignTransforms.alignPass
        });
        // Absolute last: align single free var to binder even if binder is used
        passes.push({
            name: "EFnSingleFreeVarToBinder",
            description: "Absolute last: rewrite single free var in 1-arg EFn to binder (binder may be used)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EFnSingleFreeVarToBinderTransforms.pass
        });
        passes.push({
            name: "EFnFieldObjectToBinder",
            description: "Absolute last: rewrite EField(free, field) -> EField(binder, field) in 1-arg EFn bodies",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EFnFieldObjectToBinderTransforms.pass
        });
        // Convert Enum.each counting patterns to Enum.count with predicate (very late)
        passes.push({
            name: "CountEachToEnumCount",
            description: "Rewrite Enum.each(list, fn b -> if cond, do: b = b + 1 end) to Enum.count(list, fn b -> cond end)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CountEachToEnumCountTransforms.transformPass
        });
        passes.push({
            name: "EFnLastChanceFix",
            description: "Absolute last-chance EFn binder/body fix: _binder -> binder, single free var -> binder",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EFnLastChanceFixTransforms.pass
        });
        passes.push({
            name: "EFnEnumClosureAlign",
            description: "Final alignment of Enum.* anonymous function closures (primary binder repairs)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EFnEnumClosureAlignTransforms.pass
        });
        // Replay: promote underscored def/defp arg binders to base name when body (or ERaw) uses base
        passes.push({
            name: "DefArgUnderscorePromoteByBodyUse_Final",
            description: "Late: rename PVar(_name) arg to name when body/ERaw references name",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.DefArgUnderscorePromoteByBodyUseTransforms.pass
        });
        passes.push({
            name: "EFnNumericSentinelCleanup",
            description: "Absolute last: drop numeric sentinel literals (0,1,0.0) inside EFn bodies",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EFnNumericSentinelCleanupTransforms.cleanupPass
        });
        // Run def/defp binder alignment late to catch newly synthesized modules/functions
        passes.push({
            name: "DefParamBinderAlignByBodyUse",
            description: "Late promotion of underscored def params to base names when body uses base",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.DefParamBinderAlignByBodyUseTransforms.alignPass
        });
        // Repair `query` binder name after early hygiene when later filter uses it
        passes.push({
            name: "QueryBinderRescue",
            description: "Rename _query/_ = downcase to query = downcase when later Enum.filter uses query",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.QueryBinderRescueTransforms.transformPass
        });
        // Promote `_ = String.downcase(search_query)` preceding Enum.filter(...) that uses `query` to a named binder
        passes.push({
            name: "PromoteQueryFromWildcard",
            description: "Promote wildcard downcase to `query = String.downcase(search_query)` when next filter uses `query`",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.PromoteQueryFromWildcardTransforms.pass
        });
        // Consolidate query handling after EFn arg/body normalizations so predicate shapes are stable
        passes.push({
            name: "FilterQueryConsolidate",
            description: "Ensure `query` availability: promote `_ = String.downcase(search_query)` or bind/inline deterministically",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.FilterQueryConsolidateTransforms.pass
        });
        // Normalize Phoenix assign/2 map argument by inlining preceding literal map
        // Removed to avoid app-specific coupling; rely on hygiene hardening instead
        // Simplify chained assignments in def/defp when inner var is unused later in block
        passes.push({
            name: "BlockAssignChainSimplify",
            description: "Rewrite outer = inner = expr → outer = expr when inner is unused later in function block",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.FunctionHygieneTransforms.blockAssignChainSimplifyPass
        });
        // Late sanitation of reduce bodies after most rewrites
        passes.push({
            name: "ReduceBodySanitize",
            description: "Fix head extraction and accumulator rebinds inside Enum.reduce bodies; drop stray arithmetic (late)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ReduceBodySanitizeTransforms.transformPass
        });
        // After reduce bodies are sanitized, rewrite trivial list-building reduces to comprehensions
        passes.push({
            name: "ReduceToComprehension",
            description: "Rewrite Enum.reduce(range, [], fn iter, acc -> Enum.concat(acc, [v]) end) to for-comprehension",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ReduceToComprehensionTransforms.rewritePass
        });
        // Sanitize any leftover push(...) sentinels to nil to avoid invalid syntax in non-reduce contexts
        passes.push({
            name: "PushSentinelSanitize",
            description: "Replace stray push(...) sentinel calls with nil in non-reduce contexts",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.PushSentinelSanitizeTransforms.transformPass
        });
        // Late cleanup: unwrap Map.values(coll) in Enum.reduce when reducer does not use Presence metas
        passes.push({
            name: "ReduceInputValuesCleanup",
            description: "Unwrap Map.values(coll) in Enum.reduce when iterating lists (no binder.metas usage)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ReduceInputValuesCleanupTransforms.pass
        });
        // Replay: ensure multi-statement function arguments are IIFEs after late rewrites
        passes.push({
            name: "FunctionArgBlockToIIFE_Post",
            description: "Wrap multi-statement EBlock/EDo args in (fn -> ... end).() after late transforms",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.FunctionArgBlockToIIFETransforms.pass
        });
        // Last-resort: force-wrap Enum.join first arg as IIFE when complex
        passes.push({
            name: "JoinArgForceIIFE",
            description: "Ensure Enum.join first argument is a single expression by IIFE wrapping complex shapes",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.JoinArgForceIIFETransforms.pass
        });
        // Replay join-arg list-builder → Enum.map rewrite late to catch stabilized shapes
        passes.push({
            name: "JoinArgListBuilderToMapJoin_Post",
            description: "Rewrite Enum.join(<builder block>, sep) to Enum.map |> Enum.join late",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.JoinArgListBuilderToMapJoinTransforms.transformPass
        });
        // Block-scoped fixer: if Enum.join receives a temp accumulator variable that was
        // built in the same block (init -> Enum.each(concat) -> return acc), rewrite the
        // argument to Enum.map(list, fn -> value end) and remove the builder window when safe.
        passes.push({
            name: "JoinArgBlockScopedFix",
            description: "Rewrite block-scoped temp-list builder to Enum.map |> Enum.join and prune builder",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.JoinArgBlockScopedFixTransforms.pass
        });
        // Absolute last: always IIFE-wrap Enum.join first arg unless simple/safe
        passes.push({
            name: "JoinArgAlwaysIIFE",
            description: "Force Enum.join first arg to be a single expression by IIFE wrapping",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.JoinArgAlwaysIIFETransforms.pass
        });
        // Ensure binary operands are single expressions (wrap multi-stmt blocks)
        passes.push({
            name: "BinaryOperandBlockToIIFE",
            description: "Wrap multi-statement operands of binary operators in IIFE",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinaryOperandBlockToIIFETransforms.pass
        });
        // Parenthesize if/unless conditions when they include complex constructs
        passes.push({
            name: "IfConditionComplexToParen",
            description: "Wrap if/unless conditions in parentheses when containing case/cond/with/if",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.IfConditionComplexToParenTransforms.pass
        });
        // Hoist complex constructs from within binary if/unless conditions into a prior binding
        passes.push({
            name: "IfConditionComplexHoist",
            description: "Hoist case/cond/with/if out of binary conditions: value = <complex>; if value <op> rhs do ...",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.IfConditionComplexHoistTransforms.pass
        });
        // Ensure complex expressions used as binary operands are parenthesized
        passes.push({
            name: "BinaryOperandComplexToParen",
            description: "Wrap case/cond/with/if operands of binary ops in parentheses",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinaryOperandComplexToParenTransforms.pass
        });
        // Unwrap (fn -> (fn ... end) end).() → (fn ... end) to keep proper anonymous function args
        passes.push({
            name: "EFnIIFEUnwrap",
            description: "Unwrap IIFE that returns an anonymous function to the function itself",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EFnIIFEUnwrapTransforms.pass
        });
        // Sanitize reserved-word variable names (e.g., fn → fn_)
        passes.push({
            name: "ReservedWordVarSanitize",
            description: "Rename variables colliding with Elixir reserved words to safe variants",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ReservedWordVarSanitizeTransforms.pass
        });
        // Drop top-level numeric sentinel literals in function bodies
        passes.push({
            name: "FunctionTopLevelSentinelCleanup",
            description: "Remove bare 1/0/0.0 statements at top-level in def/defp bodies",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.FunctionHygieneTransforms.functionTopLevelSentinelCleanupPass
        });
        // Normalize numeric sentinel assignment to calls: `0 = call(...)` → `call(...)`
        passes.push({
            name: "ZeroAssignCallToBareCall",
            description: "Rewrite `0 = call(...)` or `0 = Mod.call(...)` back to bare calls (idiomatic)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ZeroAssignCallToBareCallTransforms.pass
        });
        // Rewrite %{struct | field: struct.field ++ rhs} → field = field ++ rhs
        passes.push({
            name: "StructUpdateListAppendRewrite",
            description: "Rewrite struct update list append into local list append assignment",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.StructUpdateListAppendRewriteTransforms.transformPass
        });
        // Drop stray non-final struct update statements that would cause invalid code
        passes.push({
            name: "StructUpdateStandaloneDiscard",
            description: "Discard standalone %{struct | ...} when not final in a block",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.StructUpdateStandaloneDiscardTransforms.transformPass
        });
        passes.push({
            name: "TupleLhsDiscard",
            description: "Discard {x} = expr (arity-1 tuple LHS) and keep expr",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.TupleLhsDiscardTransforms.discardPass
        });
        
        
        // Pattern variable origin analysis pass
        // TODO: Temporarily disabled - needs proper implementation
        // passes.push({
        //     name: "PatternVariableOriginAnalysis",
        //     description: "Use VarOrigin metadata to properly handle pattern variables vs temp extraction variables",
        //     enabled: false,
        //     pass: reflaxe.elixir.ast.ElixirASTTransformer.alias_null // patternVariableOriginAnalysisPass
        // });

        // Safety net: ensure `require Ecto.Query` after all late passes
        passes.push({
            name: "EctoQueryRequireInjection",
            description: "Final sweep to inject `require Ecto.Query` in modules using Ecto.Query macros",
            enabled: false,
            pass: reflaxe.elixir.ast.ElixirASTTransformer.alias_ectoQueryRequirePass
        });
        // Absolute-final ensure for Ecto.Query require after any late rewrites
        passes.push({
            name: "EctoQueryRequireEnsure",
            description: "Ensure `require Ecto.Query` when Ecto.Query remote macros are present",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.EctoQueryRequireEnsureTransforms.transformPass
        });
        // Absolute Final 3: if pin operator exists anywhere in the module and require is missing, inject it
        passes.push({
            name: "PinnedVarRequireEctoQuery",
            description: "Inject `require Ecto.Query` based on EPin presence as a deterministic safeguard",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.PinnedVarRequireEctoQueryTransforms.transformPass
        });
        // Post-process: hoist any in-body requires to module top and deduplicate
        passes.push({
            name: "EctoRequireHoist",
            description: "Hoist local `require Ecto.Query` to module top and remove duplicates",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EctoRequireHoistTransforms.transformPass
        });

        // PostFinal: Repair Gettext module params/arity to match Phoenix idioms
        passes.push({
            name: "GettextArityAndParamRepair",
            description: "In *.Gettext modules, add arity shims and de-underscore used params like count",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.GettextArityAndParamRepairTransforms.transformPass
        });

        // PostFinal: underscore unused params in changeset/2 helpers for repository tests (moved later)
        passes.push({
            name: "ChangesetParamUnderscore",
            description: "(Disabled here; moved to AbsoluteFinal8 after Ecto.Changeset injection)",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.ChangesetParamUnderscoreTransforms.pass
        });

        // Absolute success-case alignment: must run as the very last shape-affecting passes
        // Align success binder to the single undefined var used in body (usage-driven, shape-based)
        passes.push({
            name: "SuccessBinderAlignByBodyUse",
            description: "Rename {:ok, binder} binder to the single undefined var used in body, if unambiguous",
            enabled: true, // Re-enabled with lock-aware skipping
            pass: reflaxe.elixir.ast.transformers.SuccessBinderAlignByBodyUseTransforms.alignPass
        });
        // Final safety: replace undefined lowercase refs in {:ok, binder} clause bodies with binder
        passes.push({
            name: "SuccessVarAbsoluteReplaceUndefined",
            description: "Final safety: replace any undefined lower-case var in {:ok, binder} clause body with binder",
            enabled: true, // Re-enabled with lock-aware skipping
            pass: reflaxe.elixir.ast.transformers.SuccessVarAbsoluteReplaceUndefinedTransforms.replacePass
        });
        // Final: promote underscored second binders ({:tag, _x}) to the clause's sole undefined var used in body
        passes.push({
            name: "UnderscoreBinderAlignByBodyUse_Final",
            description: "Rename {:tag, _x} binder to unique undefined lower-case var used in body (scope-aware)",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.UnderscoreBinderAlignByBodyUseTransforms.transformPass
        });

        // Final reducer alias normalization (absolute end): fix lingering alias concat -> acc concat and unify aliases
        passes.push({
            name: "ReduceAliasConcatToAcc",
            description: "Normalize alias-based accumulator concat to canonical acc concat inside Enum.reduce (absolute)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ReduceAliasConcatToAccTransforms.transformPass
        });
        passes.push({
            name: "ReduceAccAliasUnify",
            description: "Unify reduce accumulator alias to acc across reducer body (absolute)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ReduceAccAliasUnifyTransforms.unifyPass
        });
        // Unified structural canonicalization (non-destructive alongside existing passes)
        passes.push({
            name: "ReduceCanonicalize",
            description: "Canonicalize alias self-append and head extraction within two-arg reducers",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ReduceCanonicalize.pass
        });
        passes.push({
            name: "EFnAliasConcatToAcc",
            description: "Normalize alias concat -> acc concat inside any two-arg anonymous function (safety net)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EFnAliasConcatToAccTransforms.transformPass
        });
        passes.push({
            name: "ReduceAppendCanonicalize",
            description: "Canonicalize append inside Enum.reduce: alias concat -> acc concat; alias element -> binder",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ReduceAppendCanonicalizeTransforms.transformPass
        });

        // Ultra-final guard: ensure any lingering alias self-append inside two-arg anonymous functions
        // are rewritten to canonical acc = Enum.concat(acc, list)
        // Ultra-late hygiene/safety/sweep passes (modularized; order preserved)
        passes = passes.concat(reflaxe.elixir.ast.transformers.registry.groups.HygieneFinal.build());
        passes.push({
            name: "HandleInfoDropUnusedAssign",
            description: "In handle_info/2, drop v = case ... when v is unused",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.HandleInfoDropUnusedAssignTransforms.pass
        });
        passes.push({
            name: "HandleEventParamsValueRewrite",
            description: "Forward specific SafeAssigns values directly from params to avoid ephemeral local mismatches",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.HandleEventParamsValueRewriteTransforms.pass
        });
        passes.push({
            name: "HandleEventDropUnusedParamExtract_Final",
            description: "Drop name = Map.get(params, key) in handle_event/3 when name is unused later",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.HandleEventDropUnusedParamExtractTransforms.pass
        });
        passes.push({
            name: "MountCaseSocketAssignDrop",
            description: "In mount/3 case clauses, drop `socket = put_flash(socket, ...)` assignment to avoid warnings",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.MountCaseSocketAssignDropTransforms.pass
        });
        passes.push({
            name: "ControllerLocalAssignUnusedUnderscore_Final",
            description: "In conn actions, underscore unused local assignment binders",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ControllerLocalAssignUnusedUnderscoreTransforms.pass,
            runAfter: ["LocalAssignUnusedUnderscore_Global_Final"]
        });
        passes.push({
            name: "AlignBaseRefToUnderscoredBinder_Final",
            description: "Rewrite base name refs to existing underscored local binders in the same block",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.AlignBaseRefToUnderscoredBinderTransforms.pass,
            runAfter: ["LocalAssignUnusedUnderscore_Scoped_Final"]
        });
        passes.push({
            name: "LocalUnderscoreBinderPromotionWhenUsed_Final",
            description: "Promote underscored local binders to base name when the underscored name is read later and base is free",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.LocalUnderscoreBinderPromotionWhenUsedTransforms.pass,
            runAfter: ["AlignBaseRefToUnderscoredBinder_Final"]
        });
        passes.push({
            name: "DanglingBaseRefAlign_Final",
            description: "Rewrite bare refs to corresponding earlier _name binder when base is undefined",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.DanglingBaseRefAlignTransforms.pass,
            runAfter: [
                "LocalAssignUnusedUnderscore_Scoped_Final",
                "LocalUnderscoreBinderPromotionWhenUsed_Final",
                "LocalAssignUnusedUnderscore_Global_Final"
            ]
        });
        // Absolute-final local reference alignment (safe, shape-based)
        passes.push({
            name: "FinalLocalReferenceAlign",
            description: "Map refs to declared locals: name-> _name, nameN->name, updated->ok_* (unique)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.FinalLocalReferenceAlignTransforms.pass
        });
        // Ultra-final: replace stray ok_value references with value when only value is declared
        passes.push({
            name: "OkValueGlobalCleanup_AbsoluteFinal",
            description: "Ultra-final: rewrite free ok_value refs to value when value is declared",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.OkValueGlobalCleanupTransforms.pass
        });
        // Repair single-arg closures where a single undefined body var drifts from the binder name
        passes.push({
            name: "EFnUndefinedRefToArg_Final",
            description: "In fn arg -> ... end with one undefined body var, rewrite it to arg",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EFnUndefinedRefToArgTransforms.pass
        });
        passes.push({
            name: "EFnBinderAlignToUndefinedRef_Final",
            description: "If a single undefined var exists in fn body, rename binder to that var",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EFnBinderAlignToUndefinedRefTransforms.pass
        });
        // Replay success-var unifier late to catch placeholders introduced by later rewrites
        passes.push({
            name: "CaseSuccessVarUnifier_Replay_Final",
            description: "Replay unifier to rewrite undefined placeholders to {:ok, v} binder (late)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseSuccessVarUnifier.unifySuccessVarPass
        });
        // Ultra-final replay: replace any lingering undefined lower-case refs in {:ok, binder}
        // clause bodies with the bound success binder. This runs after all other late passes
        // to catch any constructs introduced by them.
        passes.push({
            name: "SuccessVarAbsoluteReplaceUndefined_Replay_Final",
            description: "Ultra-final: map undefined lower-case vars in {:ok, binder} bodies to binder",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.SuccessVarAbsoluteReplaceUndefinedTransforms.replacePass
        });
        // Ultra-late: normalize {:some, _x} binder if used in body
        passes.push({
            name: "CaseSomeBinderNormalize_Final",
            description: "Rename {:some, _x} binder to safe name and rewrite references (late)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseSomeBinderNormalizeTransforms.pass
        });
        // Rename underscored locals that are later used in expressions
        passes.push({
            name: "UnderscoreVarUsageFix_AbsoluteFinal",
            description: "Rename _name to name when used in expression context to avoid warnings",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.UnderscoreVarUsageFixTransforms.pass,
            runAfter: [
                "FinalLocalReferenceAlign",
                "OkValueGlobalCleanup_AbsoluteFinal",
                "SuccessVarAbsoluteReplaceUndefined_Replay_Final"
            ]
        });
        // (Removed) StrictBlockDiscardUnused_Final — too aggressive for public defs; handled by earlier scoped passes
        // Drop any lingering `nil = _var` statements inside case bodies
        passes.push({
            name: "CaseNilAssignCleanup_Final",
            description: "Remove `nil = _var` statements from case clause bodies (ultra-final)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseNilAssignCleanupTransforms.pass
        });
        passes.push({
            name: "CaseClauseHygieneCleanup_Final",
            description: "Drop `nil = _var` and rewrite `socket = put_flash(socket, ...)` inside case clauses",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseClauseHygieneCleanupTransforms.pass
        });
        // Promote {:error,_x} -> {:error,x} in clause bodies when x is used; also map undefined refs to binder
        passes.push({
            name: "CaseErrorVarUnify_Final",
            description: "Promote {:error, _x} to {:error, x} when body uses x; map undefined to binder",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseErrorVarUnifyTransforms.transformPass
        });
        // Align case binder names in {:ok, binder}/{:error, binder} to the single undefined
        // lower-case name used within the clause body (usage-driven, no app coupling)
        passes.push({
            name: "CaseBinderAlignByBodyUse_Final",
            description: "Rename case tuple binder to the single undefined lower-case var used in body",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.CaseBinderAlignByBodyUseTransforms.pass
        });
        // Controller-only cleanup: drop json/data/conn alias chains before Phoenix.Controller.json calls
        passes.push({
            name: "ControllerJsonCallCleanup_Final",
            description: "Remove json/data/conn alias chains before Phoenix.Controller.json and use original conn",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ControllerJsonCallCleanupTransforms.pass
        });
        passes.push({
            name: "ControllerAliasChainDrop_Final",
            description: "Drop contiguous json/data/conn alias-chains to the same RHS var in controllers",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ControllerAliasChainDropTransforms.pass
        });
        passes.push({
            name: "ControllerResultBinderNormalize_Final",
            description: "Normalize {:ok,_}/{:error,_} binders to value/reason in controllers (final)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ControllerResultBinderNormalizeTransforms.pass,
            runAfter: ["ControllerJsonCallCleanup_Final"]
        });
        passes.push({
            name: "ControllerAliasAssignDrop_AbsoluteFinal",
            description: "Absolute-final: drop assignments to json/data/conn in controller bodies and case arms",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ControllerAliasAssignDropTransforms.pass
        });
        passes.push({
            name: "WebDropUnusedSimpleAssign_AbsoluteFinal",
            description: "Absolute-final: in Web modules, drop simple unused assignments (pure RHS)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.WebDropUnusedSimpleAssignTransforms.pass
        });
        // Web.* scope (controllers, LiveView, components): drop simple unused assigns anywhere
        passes.push({
            name: "WebDropUnusedSimpleAssignAny_AbsoluteFinal",
            description: "Absolute-final: in Web.* modules, drop simple unused assignments (pure RHS) in all bodies",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.WebDropUnusedSimpleAssignAnyTransforms.pass
        });
        passes.push({
            name: "ControllerAliasAssignDrop_Replay_Ultimate",
            description: "Ultimate replay: drop alias assigns json/data/conn in controllers after all rewrites",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ControllerAliasAssignDropTransforms.pass
        });

        // Absolute-final global hygiene: drop `nil = _var` anywhere in bodies
        passes.push({
            name: "NilUnderscoreAssignGlobal_AbsoluteFinal",
            description: "Absolute-final: remove `nil = _var` (and :nil) assignments anywhere in bodies",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.NilUnderscoreAssignGlobalTransforms.pass,
            runAfter: [
                "CaseClauseHygieneCleanup_Final",
                "CaseNilAssignCleanup_Final",
                "ControllerAliasAssignDrop_Replay_Ultimate",
                "CaseBinderAlignFinal",
                "CaseBinderAlignByBodyUse_Final",
                "SuccessVarAbsoluteReplaceUndefined_Replay_Final",
                "HandleEventParamsUltraFinal_Last"
            ]
        });

        // Absolute‑last: clause-local success body binder rewrite (ok_value/ok_<binder> → binder)
        passes.push({
            name: "CaseClauseSuccessBodyBinderRewrite_AbsoluteLast",
            description: "Absolute-last: in {:ok,binder} clauses, rewrite ok_value/ok_<binder> refs in bodies to binder",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseClauseSuccessBodyBinderRewriteTransforms.pass,
            runAfter: [
                "NilUnderscoreAssignGlobal_AbsoluteFinal",
                "FinalLocalReferenceAlign",
                "ParamUnderscoreArgRefAlign_Global_Final"
            ]
        });

        // Absolute‑last replay: ensure case discriminant uses same temp as nearest assignment (g vs _g)
        passes.push({
            name: "CaseDiscriminantTempNormalize_Replay_AbsoluteLast",
            description: "Absolute-last replay: rewrite case discriminant to match nearest prior assignment modulo underscore",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseDiscriminantTempNormalizeTransforms.pass,
            runAfter: [
                "CaseClauseSuccessBodyBinderRewrite_AbsoluteLast",
                "OkValueGlobalCleanup_AbsoluteLast",
                "FinalLocalReferenceAlign",
                "ParamUnderscoreArgRefAlign_Global_Final"
            ]
        });

        // Final: underscore unused case payload binders (e.g., {:error, reason} -> {:error, _reason})
        passes.push({
            name: "CasePatternUnusedBinderUnderscore_Final",
            description: "Underscore case payload binder when not referenced in the clause body",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.CasePatternUnusedBinderUnderscoreTransforms.pass
        });

        // Scoped unused local assignment drop for Web modules (controllers, LiveView)
        passes.push({
            name: "WebDropUnusedLocalAssignment_AbsoluteFinal",
            description: "Absolute-final: in Web.* modules, drop local assigns unused later in the same block",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.WebDropUnusedLocalAssignmentTransforms.pass
        });

        // Absolute-final, Web.* scope: drop alias chains before Phoenix.Controller.json and rewrite arg2
        passes.push({
            name: "WebJsonCallAliasRewrite_AbsoluteFinal",
            description: "Absolute-final: in Web.* modules, remove json/data/conn alias lines and rewrite json(conn, data) to use RHS var",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.WebJsonCallAliasRewriteAbsoluteFinalTransforms.pass,
            runBefore: [
                "ControllerAliasAssignDrop_Replay_Ultimate",
                "ControllerAliasChainDrop_Final"
            ]
        });

        // Absolute-last controller-specific finalizer to force correct json/2 shape in case arms
        passes.push({
            name: "ControllerJsonFinalize_AbsoluteFinal",
            description: "Absolute-last: in controllers, map json(conn, data) arg2 to case binder and drop alias lines",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ControllerJsonFinalizeAbsoluteTransforms.pass,
            runAfter: [
                "WebJsonCallAliasRewrite_AbsoluteFinal",
                "ControllerAliasAssignDrop_Replay_Ultimate",
                "ControllerResultBinderNormalize_Final",
                "ControllerCaseRenameBinderIfBodyRefsBase_Final",
                "ControllerJsonDataArgToBinder_Final",
                "ControllerJsonDataArgPickSingleVar_Final",
                "HandleEventParamsUltraFinal_Last"
            ]
        });

        // Ultimate sweep: drop json/data/conn alias assigns in all Web.* modules
        passes.push({
            name: "WebDropAliasAssign_Ultimate",
            description: "Ultimate: drop alias assigns to json/data/conn in Web.* modules",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.WebDropAliasAssignUltimateTransforms.pass,
            runAfter: [
                "ControllerJsonFinalize_AbsoluteFinal",
                "ControllerAliasAssignDrop_Replay_Ultimate"
            ]
        });

        // As a last resort, underscore remaining alias assigns (json/data/conn) to silence WAE
        passes.push({
            name: "WebAliasAssignUnderscore_Ultimate",
            description: "Ultimate: rewrite json/data/conn alias binders to underscored variants in Web.*",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.WebAliasAssignUnderscoreTransforms.pass,
            runAfter: [
                "WebDropAliasAssign_Ultimate"
            ]
        });
        // ABSOLUTE-LAST hygiene: remove lingering ok_value/_g in any function/EFn bodies
        passes.push({
            name: "OkValueGlobalCleanup_AbsoluteLast",
            description: "Absolute-last: rewrite ok_value->value and _g->g when only value/g are declared (def/defp and EFn)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.OkValueGlobalCleanupTransforms.pass,
            runAfter: [
                "WebAliasAssignUnderscore_Ultimate",
                "ControllerJsonSecondArgUndefinedRewrite_Ultimate",
                "CaseBinderRefNormalizeByFlattenUnderscores_Final",
                "FunctionArgMultiStmtIIFE_Final",
                "AssertArgIIFE_Final",
                "StringIndexOf_Normalize_Final",
                "BinaryMatchCaseArgNormalize_Final",
                "ParamUnderscoreArgRefAlign_Global_Final"
            ]
        });

        // Ultimate: ensure Phoenix.Controller.json second arg is a real local (binder/value)
        passes.push({
            name: "WebJsonSecondArgRewrite_Ultimate",
            description: "Ultimate: rewrite Phoenix.Controller.json(conn, data|json) to binder/value in Web.*",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.WebJsonSecondArgRewriteFinalTransforms.pass,
            runAfter: [
                "WebDropAliasAssign_Ultimate",
                "WebAliasAssignUnderscore_Ultimate",
                "ControllerJsonFinalize_AbsoluteFinal"
            ]
        });

        // Ultimate replay: remove lingering ok_value/_g references inside any bodies and closures
        passes.push({
            name: "OkValueGlobalCleanup_Replay_Ultimate",
            description: "Ultimate replay: rewrite ok_value->value and _g->g when only value/g are declared (def/defp and EFn)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.OkValueGlobalCleanupTransforms.pass,
            runAfter: [
                "WebJsonSecondArgRewrite_Ultimate",
                "FinalLocalReferenceAlign"
            ]
        });

        // Ultimate controller safety: replace dangling json(conn, data) when `data` is undefined
        passes.push({
            name: "ControllerJsonSecondArgUndefinedRewrite_Ultimate",
            description: "Ultimate: in controllers, if json(conn, data) remains with undefined `data`, rewrite to binder/safe expr",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ControllerJsonSecondArgUndefinedRewriteUltimateTransforms.pass,
            runAfter: [
                "WebJsonSecondArgRewrite_Ultimate",
                "ControllerAliasAssignDrop_Replay_Ultimate"
            ]
        });

        // Normalize case payload binder references to the declared binder when they differ
        // only by underscores (e.g., okvalue -> ok_value). Run late to repair accidental
        // renames from previous passes without app coupling.
        passes.push({
            name: "CaseBinderRefNormalizeByFlattenUnderscores_Final",
            description: "Unify clause body refs that flatten to the binder name (remove underscores)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseBinderRefNormalizeByFlattenUnderscoresTransforms.pass,
            runAfter: [
                "ControllerJsonSecondArgUndefinedRewrite_Ultimate",
                "ControllerJsonFinalize_AbsoluteFinal",
                "CaseBinderAlignByBodyUse_Final"
            ]
        });

        // Ensure multi-statement argument blocks are safe in function calls by wrapping them
        // into immediately-invoked anonymous functions. This is target-generic and prevents
        // printer-level line break issues at call sites.
        passes.push({
            name: "FunctionArgMultiStmtIIFE_Final",
            description: "Wrap multi-statement argument blocks in IIFE: (fn -> ... end).()",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.FunctionArgMultiStmtIIFETransforms.pass,
            runAfter: [
                "CaseBinderRefNormalizeByFlattenUnderscores_Final"
            ]
        });

        // Stabilize Assert boolean arguments by isolating complex expressions in IIFEs
        passes.push({
            name: "AssertArgIIFE_Final",
            description: "Wrap Assert.is_true/false first arg in IIFE when complex (assignments/case)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.AssertArgIIFETransforms.pass,
            runAfter: [
                "FunctionArgMultiStmtIIFE_Final"
            ]
        });

        // Normalize String.indexOf comparisons into boolean :binary.match checks
        passes.push({
            name: "StringIndexOf_Normalize_Final",
            description: "Rewrite str.indexOf(sub) >= 0 to :binary.match(str, sub) != :nomatch",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.StringIndexOfTransforms.pass,
            runAfter: [
                "AssertArgIIFE_Final"
            ]
        });

        // Normalize assignment + case(:binary.match) comparison argument blocks to boolean match check
        passes.push({
            name: "BinaryMatchCaseArgNormalize_Final",
            description: "Normalize arg blocks: (v = expr; case :binary.match(v, sub) ...) >= 0 → :binary.match(expr, sub) != :nomatch",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinaryMatchCaseArgNormalizeTransforms.pass,
            runAfter: [
                "StringIndexOf_Normalize_Final",
                "FunctionArgMultiStmtIIFE_Final"
            ]
        });

        // Inline a preceding assignment into the first argument of the immediate call when
        // that argument only uses the assigned var for a :binary.match comparison shape.
        passes.push({
            name: "InlinePrevAssignIntoArg_Final",
            description: "Inline `v = expr` into next call arg if it compares case :binary.match(v, sub)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.InlinePrevAssignIntoArgTransforms.pass,
            runAfter: [
                "BinaryMatchCaseArgNormalize_Final"
            ]
        });

        // Debug only: print json/2 arg kinds inside controllers (guarded by -D debug_controller_json)
        passes.push({
            name: "DebugControllerJsonArgs",
            description: "Debug: log json(conn, ...) arg kinds in controllers when -D debug_controller_json is set",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.DebugControllerJsonArgsPass.pass
        });

        // Ensure controller case binders promote from _value/_reason -> value/reason when body references base
        passes.push({
            name: "ControllerCaseRenameBinderIfBodyRefsBase_Final",
            description: "Promote case binder _name -> name in controllers when body references base name",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ControllerCaseRenameBinderIfBodyRefsBaseTransforms.pass,
            runAfter: [
                "CaseBinderAlignByBodyUse_Final",
                "CaseErrorVarUnify_Final",
                "ControllerJsonCallCleanup_Final"
            ]
        });

        passes.push({
            name: "ControllerJsonDataArgToBinder_Final",
            description: "In controllers, rewrite Phoenix.Controller.json(conn, data) to binder inside case arms",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ControllerJsonDataArgToBinderTransforms.pass,
            runAfter: [
                "ControllerCaseRenameBinderIfBodyRefsBase_Final",
                "WebJsonCallAliasRewrite_AbsoluteFinal"
            ]
        });

        passes.push({
            name: "ControllerJsonDataArgPickSingleVar_Final",
            description: "When json(conn, data) and exactly one lower-case var used in body, rewrite arg2 to it",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ControllerJsonDataArgPickSingleVarTransforms.pass,
            runAfter: [
                "ControllerJsonDataArgToBinder_Final",
                "ControllerCaseRenameBinderIfBodyRefsBase_Final"
            ]
        });
        passes.push({
            name: "DropUnusedAssignToCase",
            description: "Replace v = case ... end with case ... end when v is unused later",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.DropUnusedAssignToCaseTransforms.pass
        });
        passes.push({
            name: "DropUnusedLocalAssignment",
            description: "Remove local assignments to variables unused later in the same block",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.DropUnusedLocalAssignmentTransforms.pass
        });
        passes.push({
            name: "ListIndexAccessToEnumAt",
            description: "Rewrite list index access (entry.metas[0]) to Enum.at(entry.metas, 0)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ListIndexAccessToEnumAtTransforms.transformPass
        });
        passes.push({
            name: "SafePubSubModuleRewrite",
            description: "Rewrite SafePubSub.* to Phoenix.SafePubSub.* (ultimate fallback)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.SafePubSubModuleRewriteTransforms.rewritePass
        });
        passes.push({
            name: "GlobalNumericSentinelCleanup",
            description: "Global sweep to drop standalone numeric sentinel literals (0,1,0.0) in any block",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.GlobalNumericSentinelCleanupTransforms.cleanupPass
        });
        // Very last: drop nil = _var no-ops that only trigger underscored-variable warnings
        passes.push({
            name: "DropNilAssignFromUnderscoredVar_Final",
            description: "Remove statements like `nil = _g` which cause WAE warnings",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.DropNilAssignFromUnderscoredVarTransforms.pass
        });
        // General guard: drop `socket = Phoenix.LiveView.put_flash(socket, ...)` anywhere
        passes.push({
            name: "SocketPutFlashAssignDrop_Final",
            description: "Rewrite socket = put_flash(socket, ...) to just put_flash(socket, ...)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.SocketPutFlashAssignDropTransforms.pass
        });
        // Ensure socket is used after put_flash assignment to silence branch-local unused var warnings
        passes.push({
            name: "SocketPutFlashBranchUse_Final",
            description: "Append bare `socket` after put_flash assignment when not immediately used",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.SocketPutFlashBranchUseTransforms.pass
        });

        // Post3: remove immediate duplicate downcase after query binder
        passes.push({
            name: "RemoveDuplicateDowncaseAfterQuery",
            description: "If `query = downcase(...)` is immediately followed by `_ = downcase(...)`, drop the wildcard line",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.RemoveDuplicateDowncaseAfterQueryPostTransforms.transformPass
        });

        // UltraFinal2: As a last step, ensure changeset/2 binders match Ecto.Changeset usages
        passes.push({
            name: "EctoSchemaBinderFix",
            description: "Infer changeset/2 parameter names from Ecto.Changeset.change/cast shapes and drop underscores",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EctoSchemaBinderFixTransforms.transformPass
        });
        // Migration: inject nowarn + stubs (absolute final to see final call shapes)
        passes.push({
            name: "EctoMigrationNowarnAndStubs",
            description: "Inject @compile nowarn and defp stubs for migration helpers (absolute final)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EctoMigrationNowarnAndStubTransforms.transformPass
        });
        // Absolute last controller normalization to ensure conn is present and not underscored
        passes.push({
            name: "ControllerEnsureConnParam",
            description: "Ensure controller action heads use conn (final)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ControllerEnsureConnParamTransforms.pass
        });
        // Absolute-final safety net for Web/Live binder/param alignment and anon fn args
        passes.push({
            name: "WebParamFinalFix",
            description: "Guarantee def-head and anon-fn binder/body agreement in Web/Live modules (pins-aware)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.WebParamFinalFixTransforms.transformPass
        });
        // LiveView handle_info Option Some clause normalization (shape-based)
        passes.push({
            name: "HandleInfoSomeClauseNormalize_Final",
            description: "Normalize {:some, b} clause: drop leading alias, promote binder, and fix noreply payload",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.HandleInfoSomeClauseNormalizeTransforms.pass,
            runAfter: [
                "WebParamFinalFix",
                "ListUpdateAndFilterFix",
                "UnderscoreParamPromotion_Final",
                "GlobalNumericSentinelCleanup",
                "DropStandaloneLiteralOne"
            ]
        });
        // As a final generic guard for handle_info/2, normalize _socket usage
        passes.push({
            name: "HandleInfoUnderscoreSocketFix_Final",
            description: "Rewrite _socket refs to socket and alias assignments to discard in handle_info/2",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.HandleInfoUnderscoreSocketFixTransforms.pass
        });
        // Generic: if a function has a `socket` param, fix `_socket` refs and alias lines
        passes.push({
            name: "UnderscoreToParamSocketFix_Final",
            description: "In defs with socket param, replace _socket -> socket and alias `x = _socket` -> `_ = socket`",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.UnderscoreToParamFixTransforms.pass
        });
        // handle_info alias cleanup: drop `alias = _socket` and rewrite noreply payload
        passes.push({
            name: "HandleInfoAliasCleanup_Final",
            description: "In handle_info/2, remove alias lines `x = _socket` and replace `{:noreply, _socket|x}` with `{:noreply, socket}`",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.HandleInfoAliasCleanupTransforms.pass
        });

        // Final LiveView message arg normalization for list helpers in {:tag, id} tuples
        passes.push({
            name: "HandleInfoTupleArgToSecondElem",
            description: "In case msg of {:tag, v}, pass v instead of msg to *_from_list/*_in_list helpers",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ListHelpersFixTransforms.handleInfoTupleArgToSecondElemPass
        });
        // Late promote of underscored case binders used in body
        passes.push({
            name: "CaseUnderscoreBinderPromote_Final",
            description: "Promote tuple second-element binder _x -> x (when used) and rewrite body references (disabled for snapshot parity)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseUnderscoreBinderPromoteTransforms.pass
        });

        // Late: drop self-rebinds inside anonymous functions (avoid warnings)
        passes.push({
            name: "ClosureSelfRebindDiscard_Final",
            description: "In anon fns, rewrite binder rebinding to discard (_ = expr)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ClosureSelfRebindDiscardTransforms.pass
        });
        // Late: promote underscored params even when only underscored variant is used in body (duplicate re-run removed)

        // Duplicate final re-runs of ListHelpersFix and FilterWildcardAssignToVar removed

        // Duplicate final IfThenDoToBlock removed (handled earlier by domain pass)

        // Duplicate final SwitchResultInlineReturnFix removed (handled earlier by domain pass)


        // Reorder handle_event/3 clauses to be grouped contiguously and place catch-alls last
        passes.push({
            name: "HandleEventGroupingReorder",
            description: "Group def handle_event/3 clauses and place catch-all immediately after event clauses",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.HandleEventGroupingReorderTransforms.pass
        });


        // Absolute-final: rewrite self-compare predicates to param in any remaining anon fns
        passes.push({
            name: "SelfCompareToParamFix",
            description: "Rewrite (t.id != t) and (t != t) to compare against id/_id function param",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.SelfCompareToParamFixTransforms.paramSelfCompareFixPass
        });

        // Absolute final: fix list update/remove logic shapes (run after WebParamFinalFix)
        passes.push({
            name: "ListUpdateAndFilterFix",
            description: "Repair map-then-replace and filter-remove-by-id logic patterns (absolute final)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ListUpdateAndFilterFixTransforms.transformPass
        });

        // Absolute-final: promote underscored def/defp parameters when referenced in body
        passes.push({
            name: "UnderscoreParamPromotion_Final",
            description: "Promote underscored parameters to base names when referenced in body and no conflict exists",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.UnderscoreParamPromotionFinalTransforms.pass
        });

        // Absolute-final: promote underscored case binders when body references them (controller/result cases)
        passes.push({
            name: "ClauseUnderscoreUsedPromote",
            description: "If clause body uses underscored binder (_v), rename pattern binder and body refs to base (v)",
            enabled: true, // Re-enabled with _value guard in pass
            pass: reflaxe.elixir.ast.transformers.ClauseUnderscoreUsedPromoteTransforms.transformPass
        });

        // Absolutely final: ensure no stray numeric sentinels remain anywhere
        passes.push({
            name: "GlobalNumericSentinelCleanup",
            description: "Run a last global sweep to drop standalone 0/1/0.0 literals in any block/do",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.GlobalNumericSentinelCleanupTransforms.cleanupPass
        });

        // Final cleanup: inline trivial IIFEs that only return an anonymous function
        passes.push({
            name: "InlineIIFEOfFunction_Final",
            description: "Final sweep to inline (fn -> (fn args -> ... end) end).() to (fn args -> ... end) (disabled pending full sweep)",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.IIFEInlineTransforms.pass
        });

        // As the very last guard, drop any remaining standalone literal 1/0 occurrences
        passes.push({
            name: "DropStandaloneLiteralOne",
            description: "Drop any last bare numeric literals (1/0/0.0) in blocks, do, EFn, if/case bodies",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.DropStandaloneLiteralOneTransforms.dropPass
        });

        // Absolute-final: replace the single undefined var in clause body with the binder (or rename binder)
        passes.push({
            name: "ClauseUndefinedVarToBinder_Final",
            description: "(absolute final) Harmonize clause payload binder with the sole undefined local used in body (disabled here; re-added later for ordering)",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.ClauseUndefinedVarToBinderTransforms.replaceUndefinedVarWithBinderPass
        });
        // Absolute-final: alternatively, bind the undefined local to the binder (safer when binder name collides with env)
        passes.push({
            name: "ClauseUndefinedVarBindToBinder_Final",
            description: "(absolute final) Prefix-bind u=binder when clause body uses a single undefined local u (disabled here; re-added later for ordering)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ClauseUndefinedVarBindToBinderTransforms.bindPass
        });
        // Ensure tuple binder does not shadow function arguments in late-built patterns
        passes.push({
            name: "CaseTupleBinderUnshadow_PreFinal",
            description: "Rename tuple binder colliding with function arg to 'value' and, if exactly one undefined lower-case var exists in body, prefix-bind it to value (pre-final)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseTupleBinderUnshadowTransforms.pass
        });
        // Pre-final nested repair: when an inner case immediately matches on the outer bound var with {:tag, var}
        passes.push({
            name: "NestedCaseTupleUnshadow_PreFinal",
            description: "When clause body starts with case V do {:tag, V} -> ..., rename to {:tag, value} and prefix-bind sole undefined local to value",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.NestedCaseTupleUnshadowTransforms.pass
        });
        // Inject clause‑local aliases u = _u when pattern binds _u and body uses u (shape‑based)
        passes.push({
            name: "CaseClauseAliasFromUnderscoreBinder",
            description: "Prefix‑bind undefined local u to its underscored pattern binder _u inside case clause bodies",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseClauseAliasFromUnderscoreBinderTransforms.aliasPass
        });

        // Now apply the binding form (u = binder) so body can use meaningful names
        passes.push({
            name: "ClauseUndefinedVarBindToBinder_Replay_Final",
            description: "Replay ultra-final: prefix-bind sole undefined local to the (now unshadowed) binder",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ClauseUndefinedVarBindToBinderTransforms.bindPass
        });
        // Late: when interpolation carries camelCase and pattern has snake binder, alias camel to snake
        passes.push({
            name: "CaseClauseCamelAliasToSnakeBinder",
            description: "Prepend camelCase=snake aliases for clause bodies when pattern binds snake and body references only camel",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseClauseCamelAliasToSnakeBinderTransforms.aliasPass
        });
        // One more absolute-last alignment to ensure {:tag, binder} matches the sole undefined body var
        passes.push({
            name: "CaseBinderAlignFinal",
            description: "(absolute final) Rename {:tag, binder} pattern to match the body’s sole undefined local (disabled here; re-added later)",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.CaseBinderAlignFinalTransforms.pass
        });

        // Very last replay to collapse duplicate self-assignments that might be reintroduced late
        passes.push({
            name: "SelfAssignCompression",
            description: "Collapse x = x = expr (paren/block-wrapped, EMatch/EBinary combos) at the very end",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.selfAssignCompressionPass
        });
        passes.push({
            name: "DropSelfAssignNoop",
            description: "Remove no-op self assignments v = v in clause bodies (late)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.DropSelfAssignNoopTransforms.pass
        });

        // Repair assigns binding in render/1 after late hygiene changes
        passes.push({
            name: "HeexAssignsBindRepair",
            description: "Convert `_ = Phoenix.Component.assign(assigns, map)` back to `assigns = ...` in render/1",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.HeexAssignsBindRepairTransforms.transformPass
        });

        // Repair temp alias chains like: varX = this1; _ = this1; this1 = expr -> varX = expr
        passes.push({
            name: "TempAliasChainRepair",
            description: "Fix use-before-assign chains involving thisN temps by dropping the temp and assigning the final RHS",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.TempAliasChainRepairTransforms.pass
        });

        // Normalize LiveView event names in HEEx (phx-*) to lowercase snake_case and validate
        passes.push({
            name: "HeexEventNameNormalization",
            description: "Normalize phx-* event attribute values to lowercase snake_case; validate & warn on invalid names",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.HeexEventNameNormalizationTransforms.transformPass,
            contextualPass: reflaxe.elixir.ast.transformers.HeexEventNameNormalizationTransforms.contextualPass
        });

        // Restore helper call arg after Repo.delete: prefer id param over deleted record binder
        // Normalize success binder names before restoring call arguments
        passes.push({
            name: "RepoCaseBinderNormalize",
            description: "Normalize {:ok, binder} binder names for Repo.delete cases: g3/s2 → deleted/_deleted",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.RepoCaseBinderNormalizeTransforms.pass
        });
        passes.push({
            name: "RepoDeleteCaseArgRestore",
            description: "Inside case Repo.delete, rewrite (binder, socket) helper calls to (id, socket)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.RepoDeleteCaseArgRestoreTransforms.pass
        });

        // Presence module hygienics: underscore unused params and normalize simple helpers to return `socket`
        passes.push({
            name: "PresenceModuleFix",
            description: "Underscore unused params and normalize trivial presence helpers to return `socket`",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.PresenceModuleFixTransforms.pass
        });

        // Absolute final: ensure LiveView mount/3 has proper {:ok, socket} return
        passes.push({
            name: "LiveMountReturnFinalize",
            description: "Ensure mount/3 ends with {:ok, socket}; assign assigns inline when present",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.LiveMountReturnFinalizeTransforms.pass
        });
        // Duplicate final BareGetterRepoGetRepair removed (handled earlier by domain pass)

        // Absolute-final HEEx assigns textual scan removed; earlier HEEx passes guarantee assigns handling

        // Removed absolute final ~H conversion; ensured earlier by HeexRenderStringToSigil/HeexStringReturnToSigil
        // Presence localization runs earlier in the Presence section

        // Removed duplicate absolute final mount promotion; covered by LiveMountLatePromote earlier
        // Final section kept lean; mount and presence fixes are handled in their domain passes

        // Return only enabled passes (names carry no scheduling semantics)
        // Extra-late binder alignment for {:tag, binder} (safety net)
        passes.push({
            name: "CasePayloadBinderAlignByBodyUse_Final",
            description: "Run CasePayloadBinderAlignByBodyUse as absolute last safety net (scope-aware)",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.CasePayloadBinderAlignByBodyUseTransforms.alignPass
        });

        // Absolute-last heuristic: when usage lives only in string interpolation, infer binder from it
        passes.push({
            name: "CaseBinderNameFromStringUsage",
            description: "Infer {:tag, binder} name from identifiers inside string interpolation in clause bodies (disabled)",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.CaseBinderNameFromStringUsageTransforms.transformPass
        });

        // Absolute last: split chained assignments again to catch any reintroduced by late passes
        passes.push({
            name: "SplitChainedAssignments_AbsoluteFinal",
            description: "(absolute final) Split a = b = expr into two statements (blocks/do/fn bodies)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.SplitChainedAssignmentsTransforms.transformPass
        });
        // Absolute-final, idempotent replays to crush leftover `query` refs when *_query param exists
        passes.push({
            name: "VarRefQueryInlineDowncaseFromSuffixParam_AbsoluteFinal",
            description: "Absolute-final: inline `query` to String.downcase(<*_query param>) across function body",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.VarRefQueryInlineDowncaseFromSuffixParamTransforms.pass
        });
        passes.push({
            name: "VarRefSuffixParamNormalize_AbsoluteFinal",
            description: "Absolute-final: map short refs to a unique param that ends with _<short> (e.g., query -> search_query)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.VarRefSuffixParamNormalizeTransforms.pass
        });
        passes.push({
            name: "VarRefQueryToSuffixParam_AbsoluteFinal",
            description: "Absolute-final: rewrite query -> <*_query param> across function bodies",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.VarRefQueryToSuffixParamTransforms.pass
        });
        passes.push({
            name: "FilterPredicateMissingQueryFix_AbsoluteFinal",
            description: "Absolute-final: inside Enum.filter EFns, rewrite query -> String.downcase(<*_query>)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.FilterPredicateMissingQueryFixTransforms.pass
        });
        passes.push({
            name: "DowncaseParamThenFilterPredicateNormalize_AbsoluteFinal",
            description: "Absolute-final: after `p = String.downcase(p)`, rewrite predicate `query` -> `p` in following Enum.filter",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.DowncaseParamThenFilterPredicateNormalizeTransforms.pass
        });
        passes.push({
            name: "DowncaseAssignLhsNormalize_AbsoluteFinal",
            description: "Absolute-final: normalize malformed LHS String.downcase(p) = String.downcase(p) to p = String.downcase(p)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.DowncaseAssignLhsNormalizeTransforms.pass
        });
        passes.push({
            name: "DebugDumpQueryFunctionBodies",
            description: "Debug-only: dump bodies of *_query functions to verify final shapes",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.DebugDumpQueryFunctionBodiesTransforms.pass
        });
        passes.push({
            name: "CaseOkBinderPrefixBindAllUndefined_AbsoluteFinal",
            description: "Absolute-final: in {:ok, binder} clauses, prefix-bind all undefined simple locals to binder",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseOkBinderPrefixBindAllUndefinedTransforms.pass
        });
        // Replay collision fix at the very end to prevent {:ok, socket} from leaking
        passes.push({
            name: "CaseSuccessVarRenameCollisionFix_AbsoluteFinal",
            description: "Absolute-final: rename {:ok, var} binder when it collides with function args (e.g., socket)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseSuccessVarRenameCollisionFixTransforms.transformPass
        });
        passes.push({
            name: "CaseOkBinderPrefixBindAllUndefined_Replay_AbsoluteFinal",
            description: "Absolute-final replay: after binder collision renames, prefix-bind all undefined locals to {:ok, binder}",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseOkBinderPrefixBindAllUndefinedTransforms.pass
        });
        passes.push({
            name: "DowncaseParamThenFilterPredicateNormalize_Replay_AbsoluteFinal",
            description: "Absolute-final replay: after LHS normalization, rewrite predicate query→param following downcase assign",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.DowncaseParamThenFilterPredicateNormalizeTransforms.pass
        });
        passes.push({
            name: "DebugPredicateQueryScan",
            description: "Debug-only: print Enum.filter predicates that still reference `query` in *_query functions",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.DebugPredicateQueryScanTransforms.pass
        });
        // Absolute final: inline undefined camelCase refs to prior discarded Map.get(_, "snake_key")
        passes.push({
            name: "UndefinedRefInlineDiscardedMapGet_Final",
            description: "Inline EVar(camel) to Map.get(_, \"snake\") when only discarded fetch exists earlier",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.UndefinedRefInlineDiscardedMapGetTransforms.transformPass
        });
        // Absolute final: re-run camelCase→snake_case for local declarations after event generation
        passes.push({
            name: "LocalCamelToSnakeDecl_Final",
            description: "Re-apply local camelCase→snake_case renames post event synthesis",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.LocalCamelToSnakeDeclTransforms.transformPass
        });
        // Absolute final: for handle_event/3, synthesize param extracts for any undefined locals used in body
        passes.push({
            name: "HandleEventParamExtractFromBodyUse_Final",
            description: "Prepend var = Map.get(params, snake(var)) for undefined body locals in handle_event/3",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.HandleEventParamExtractFromBodyUseTransforms.transformPass
        });
        // Final handle_info normalizations
        passes.push({
            name: "HandleInfoReturnSocketNormalize_Final",
            description: "In handle_info/2, ensure helper calls end with socket and {:noreply, socket} shapes",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.HandleInfoReturnSocketNormalizeTransforms.transformPass
        });
        passes.push({
            name: "HandleInfoScrutineeToPayloadRef_Final",
            description: "Rewrite scrutinee references to payload binder within handle_info case clauses",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.HandleInfoScrutineeToPayloadRefTransforms.transformPass
        });
        // Ultra-final: for toggle_* events, replace helper first-arg `params` with Map.get(params, suffix)
        passes.push({
            name: "HandleEventToggleKeyExtract_Final",
            description: "For handle_event(\"toggle_*\"), replace helper first arg `params` with Map.get(params, key)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.HandleEventToggleKeyExtractFinalTransforms.transformPass
        });
        passes.push({
            name: "HandleEventParamRepair_Final",
            description: "Repair handle_event/3: turn discarded Map.get into named binds and insert any missing binds",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.HandleEventParamRepairTransforms.transformPass
        });
        passes.push({
            name: "UndefinedLocalExtractFromParams_Final",
            description: "For any def with params/_params arg, bind undefined locals from params generically",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.UndefinedLocalExtractFromParamsTransforms.transformPass
        });
        passes.push({
            name: "InlineUndefinedFromParams_Final",
            description: "Inline undefined locals from params where prefix binding was not possible",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.InlineUndefinedFromParamsTransforms.transformPass
        });
        // Re-add clause binder harmonization after handler param extractions, before wrapper repair
        passes.push({
            name: "ClauseUndefinedVarBindToBinder_Final",
            description: "(absolute final) Prefix-bind u=binder when clause body uses a single undefined local u",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ClauseUndefinedVarBindToBinderTransforms.bindPass
        });
        // Generic success-binder recovery: when a clause is {:ok, b} and a two-element
        // tuple literal {:tag, v} appears in the body with undefined v, bind v = b.
        passes.push({
            name: "ClauseSuccessBinderTupleSecondBind_Final",
            description: "Prefix-bind tuple second element var to {:ok, binder} within clause bodies",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ClauseSuccessBinderTupleSecondBindTransforms.pass
        });
        passes.push({
            name: "SuccessBinderPrefixMostUsedUndefined_Final",
            description: "(absolute final) In {:ok, binder} clauses, prefix-bind the most-frequent undefined var to binder",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.SuccessBinderPrefixMostUsedUndefinedTransforms.pass
        });
        passes.push({
            name: "ClauseUndefinedVarToBinder_Final",
            description: "(absolute final) Harmonize clause payload binder with the sole undefined local used in body (disabled for snapshot parity)",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.ClauseUndefinedVarToBinderTransforms.replaceUndefinedVarWithBinderPass
        });
        passes.push({
            name: "CaseBinderAlignFinal",
            description: "(absolute final) Rename {:tag, binder} pattern to match the body’s sole undefined local (disabled for snapshot parity)",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.CaseBinderAlignFinalTransforms.pass
        });

        // Absolute final: upgrade wildcard Map.get assigns to named snake_case variables
        passes.push({
            name: "UpgradeWildcardMapGetToNamed_Final",
            description: "Rewrite `_ = Map.get(params, \"key\")` to `key = Map.get(params, \"key\")` (enables VarNameNormalization)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.UpgradeWildcardMapGetToNamedTransforms.transformPass
        });

        // Debug: dump Main.main body shape to diagnose hoist window (flag-gated)
        passes.push({
            name: "DebugDumpMainBody",
            description: "Debug-only: print Main.main body AST when -D debug_case_hoist is set",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.DebugDumpMainBodyTransforms.transformPass
        });

        // One more absolute-last attempt to harmonize {:tag, value/_x} binders using string interpolation hints
        passes.push({
            name: "CaseBinderNameFromStringUsage_Final",
            description: "Absolute last: infer binder name from string interpolation identifiers in clause bodies (disabled)",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.CaseBinderNameFromStringUsageTransforms.transformPass
        });

        // Very late: simplify inspect(Map.get(obj, :field)) → obj.field for readability/idiomatic output
        passes.push({
            name: "InterpolationInspectMapGetSimplify",
            description: "Rewrite inspect(Map.get(obj, :field)) to obj.field",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.InterpolationInspectMapGetSimplifyTransforms.transformPass
        });

        // Normalize chained assignments + if-else inside reduce_while lambda bodies
        passes.push({
            name: "ReduceWhileIfAssignmentNormalize",
            description: "Inside Enum.reduce_while EFns, rewrite a=(b=expr); if ... else b → b=expr; a=if ...",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ReduceWhileIfAssignmentNormalizeTransforms.transformPass
        });

        // Late shape-only readability improvement for parse_* flows (final replay below as safeguard)
        passes.push({
            name: "CaseScrutineeHoist",
            description: "Hoist case parse_*(args) scrutinee to parsed_result = parse_*(args); case parsed_result do",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseScrutineeHoistTransforms.transformPass
        });

        // Absolute final replay: ensure hoist after any late rewrites
        passes.push({
            name: "CaseScrutineeHoist_Final",
            description: "Absolute final: replay hoist of case parse_* scrutinee",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseScrutineeHoistTransforms.transformPass
        });
        passes.push({
            name: "CaseUnderscoreCaseHoistBlock_Final",
            description: "Absolute final: convert `_ = case <call>` to named var + case in blocks",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseUnderscoreCaseHoistBlockTransforms.transformPass
        });
        // Ultra-final: generic safety net for `_ = case <scrut>` anywhere
        passes.push({
            name: "CaseUnderscoreAssignHoistAny_Final",
            description: "Ultra-final: rewrite `_ = case <scrut>` into named assignment + case",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseUnderscoreAssignHoistAnyTransforms.transformPass
        });
        // Ultra-final: fold a=(b=rhs); if ... else b → b=rhs; a=if ...
        passes.push({
            name: "DoubleAssignIfFold_Final",
            description: "Ultra-final: normalize chained assign + trailing if into two linear assigns",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.DoubleAssignIfFoldTransforms.transformPass
        });

        // Ultra-final: fold node-level RHS blocks [b=rhs; if ... else b] under assignment
        passes.push({
            name: "AssignIfFoldInRhs_Final",
            description: "Ultra-final: fold a = (b=rhs; if … else b) into b=rhs; a=if … else b",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.AssignIfFoldInRhsTransforms.transformPass
        });
        passes.push({
            name: "AssignChainGenericSimplify_Final",
            description: "Ultra-final: split a = (b = rhs) into b = rhs; a = b",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.AssignChainGenericSimplifyTransforms.transformPass
        });
        passes.push({
            name: "AssignmentIfElseCombine_Final",
            description: "Ultra-final: combine `a = b; if ... else b` into `a = if ... else b`",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.AssignmentIfElseCombineTransforms.transformPass
        });
        passes.push({
            name: "AssignAliasIfPromote_Final",
            description: "Ultra-final: promote a=b; if cond(a) … else b -> a=if cond(b) …",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.AssignAliasIfPromoteTransforms.transformPass
        });
        // Place split before combine so a=(b=rhs); if … becomes b=rhs; a=b; if … → a=if …
        passes.push({
            name: "SplitChainAssign_Final",
            description: "Ultra-final: split a=(b=rhs) into b=rhs; a=b",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.SplitChainAssignTransforms.pass
        });
        passes.push({
            name: "ReduceWhileThenBranchNormalize_Final",
            description: "Ultra-final: normalize then-branch windows a=(b=rhs); if ... else b",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ReduceWhileThenBranchNormalizeTransforms.transformPass
        });
        // Ultra-final: ensure {:ok, _x} binders are aligned to body usage after all rewrites
        // (We will replay this again later after collision-fix)
        passes.push({
            name: "SuccessBinderAlignByBodyUse_Final",
            description: "Ultra-final: rename {:ok, binder} to the single undefined body var (usage-driven)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.SuccessBinderAlignByBodyUseTransforms.alignPass
        });
        passes.push({
            name: "SwitchReturnSanitizer_Final",
            description: "Ultra-final: ensure tail return inlines prior case alias",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.SwitchReturnSanitizerTransforms.pass
        });
        passes.push({
            name: "ChainAssignIfPromote_Final",
            description: "Ultra-final: promote a=(b=rhs); if ... else b → b=rhs; a=if ... else b",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ChainAssignIfPromoteTransforms.transformPass
        });
        // Ultra-final: repair handle_event/3 wrappers arg ordering and inline any missing param locals
        passes.push({
            name: "HandleEventWrapperFinalRepair",
            description: "Ultra-final: ensure helper calls use (params, socket) and inline missing locals from params",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.HandleEventWrapperFinalRepairTransforms.transformPass
        });
        passes.push({
            name: "HandleEventCamelRefInlineFromParams_Final",
            description: "Absolute final: inline camelCase refs in handle_event/3 from params (snake key, id int conversion)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.HandleEventCamelRefInlineFromParamsFinalTransforms.pass
        });
        // Ultra-final: if first arg remains params in helper calls, pass extracted id instead
        passes.push({
            name: "HandleEventArg0FromParamsId_UltraFinal",
            description: "Ultra-final: rewrite helper(arg0=params, ..., socket) to pass id extracted from params",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.HandleEventArg0FromParamsIdUltraFinalTransforms.transformPass
        });
        // (Skip replaying underscore param repairs at absolute-final; existing ordering preserves compilation stability.)
        // Replay: resolve binder collision (socket param etc.) before final binder-use alignment
        passes.push({
            name: "CaseSuccessVarRenameCollisionFix_AbsoluteFinal",
            description: "Absolute final: rename {:ok, socket} binder to avoid arg shadowing",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseSuccessVarRenameCollisionFixTransforms.transformPass
        });
        passes.push({
            name: "SuccessBinderAlignByBodyUse_Replay_Final",
            description: "Replay ultra-final: align {:ok, binder} to single undefined body var after collision fix",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.SuccessBinderAlignByBodyUseTransforms.alignPass
        });

        // Late replay: map scrutinee var refs to tuple payload binder inside case clauses
        // Some passes rebuild case bodies or rename binders after the early run; replay here ensures
        // guards like `if (todo.user_id == ...)` use the tuple payload (e.g., `value.user_id`).
        passes.push({
            name: "CaseScrutineeVarToTupleBinder_Replay_Final",
            description: "Replay ultra-final: rewrite EVar(scrutinee) → EVar(binder) inside case clause bodies",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseScrutineeVarToTupleBinderTransforms.transformPass
        });
        // Absolute-final safety: unshadow tuple binder when case scrutinee is a function arg
        passes.push({
            name: "CaseTupleBinderUnshadow_Final",
            description: "Final pass: rename tuple binder colliding with function arg to 'value' and prefix-bind most-used undefined local",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseTupleBinderUnshadowTransforms.pass
        });
        // Replay var name normalization very late so camel refs map to newly created snake_case binds
        passes.push({
            name: "VarNameNormalization_Final",
            description: "Absolute final: normalize camelCase references to existing snake_case variables",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.VarNameNormalizationTransforms.varNameNormalizationPass
        });
        passes.push({
            name: "VarRefSuffixParamNormalize_Final",
            description: "Absolute final: map short refs to a unique param that ends with _<short> (e.g., query -> search_query)",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.VarRefSuffixParamNormalizeTransforms.pass
        });
        passes.push({
            name: "VarRefSuffixParamNormalize_UltraFinal",
            description: "Ultra-final: rewrite free `query` refs to the single *_query param (e.g., search_query)",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.VarRefSuffixParamNormalizeUltraFinalTransforms.pass
        });
        passes.push({
            name: "VarRefQueryInlineDowncaseFromSuffixParam_UltraFinal",
            description: "Ultra-final: inline `query` to String.downcase(<*_query param>) across function body",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.VarRefQueryInlineDowncaseFromSuffixParamTransforms.pass
        });
        // Ultra-final: last-resort normalization to eliminate stray `query` refs
        passes.push({
            name: "QueryVarUltimateNormalize_UltraFinal",
            description: "Ultra-final: rewrite free `query` to normalized *_query param (prefers param if param = String.downcase(param) exists)",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.QueryVarUltimateNormalizeTransforms.pass
        });
        passes.push({
            name: "FunctionQueryBinderSynthesis_UltraFinal",
            description: "Ultra-final: prepend `query = String.downcase(<*_query>)` if body uses query and no binder exists",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.FunctionQueryBinderSynthesisTransforms.pass
        });
        // Derive local `query` from a discovered `<_.>.search_query` field when referenced and unbound
        passes.push({
            name: "SearchFieldQueryBinderSynthesis_UltraFinal",
            description: "Ultra-final: synthesize `query` from `<x>.search_query` when body references it without a binder",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.SearchFieldQueryBinderSynthesisTransforms.pass
        });
        // Re-run binder safety for {:ok, binder} after all late ref/name rewrites
        passes.push({
            name: "SuccessBinderPrefixMostUsedUndefined_UltraFinal",
            description: "Ultra-final: prefix-bind most-used undefined var to {:ok, binder} after late rewrites",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.SuccessBinderPrefixMostUsedUndefinedTransforms.pass
        });
        // Repair handle_info tuple-binder collisions before normalizing call tails
        // (Moved earlier as HandleInfoCaseBinderCollisionRepair_Pre)
        passes.push({
            name: "HandleInfoCaseBinderCollisionRepair_PreFinal",
            description: "(disabled; pass now runs earlier)",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.HandleInfoCaseBinderCollisionRepairTransforms.transformPass
        });
        // Normalize handle_info helper call tails to pass the function-parameter socket
        passes.push({
            name: "HandleInfoReturnSocketNormalize_UltraFinal",
            description: "Ultra-final: in handle_info/2, rewrite calls with duplicated first/last arg to end with socket",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.HandleInfoReturnSocketNormalizeTransforms.transformPass
        });
        // Absolute final: ensure handle_info nested case bodies refer to tuple payload binder
        passes.push({
            name: "HandleInfoScrutineeToPayloadRef_AbsoluteFinal",
            description: "Absolute final: rewrite handle_info/2 nested case scrutinee refs to tuple payload binder (value)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.HandleInfoScrutineeToPayloadRefTransforms.transformPass
        });
        // One more binder safety replay at the very end (covers any late ref/name rewrites)
        passes.push({
            name: "CaseOkBinderPrefixBindAllUndefined_Replay2_UltraFinal",
            description: "Ultra-final replay: prefix-bind any remaining undefineds in {:ok, binder} clauses",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseOkBinderPrefixBindAllUndefinedTransforms.pass
        });
        passes.push({
            name: "DebugScanAssignChains",
            description: "Debug-only: scan and print nested assignment chains",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.DebugScanAssignChainsTransforms.transformPass
        });
        passes.push({
            name: "DebugDumpReduceWhileEFn",
            description: "Debug-only: dump reduce_while EFn clause bodies",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.DebugDumpReduceWhileEFnTransforms.transformPass
        });
        passes.push({
            name: "CaseAtomPatternTupleNormalize_Final",
            description: "Absolute final: normalize sibling :tag patterns to {:tag} when tuple tag patterns exist",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseAtomPatternTupleNormalizeTransforms.transformPass
        });
        // Replay list guard/cons fixes at the very end to catch any late rewrites
        passes.push({
            name: "CaseListGuardToCons_Replay_Final",
            description: "Absolute final replay: [] with non-empty guard → [head|tail]",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseListGuardToConsTransforms.pass
        });
        passes.push({
            name: "ListGuardIndexToHead_Replay_Final",
            description: "Absolute final replay: list[0]→head; length(list)>1→tail!=[] in cons clauses",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ListGuardIndexToHeadTransforms.pass
        });

        // Ultra-Ultimate: replay query normalizer and binder prefix-all at the very end to ensure landing
        passes.push({
            name: "QueryVarUltimateNormalize_Replay_Last",
            description: "Last: rewrite free `query` to normalized *_query param or String.downcase(param)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.QueryVarUltimateNormalizeTransforms.pass
        });
        passes.push({
            name: "CaseOkBinderPrefixBindAllUndefined_Replay_Last",
            description: "Last: prefix-bind any remaining undefineds in {:ok, binder} clauses (conservative)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseOkBinderPrefixBindAllUndefinedTransforms.pass
        });
        // Last replay: promote any remaining a=(b=rhs); if ... else b → b=rhs; a=if ...
        passes.push({
            name: "ChainAssignIfPromote_Replay_Last",
            description: "Last: promote chained assign + if window in any block/do",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ChainAssignIfPromoteTransforms.transformPass
        });

        // ABSOLUTE FINAL (must be after any chain/underscore replay):
        passes.push({
            name: "MountParamsUltraFinal",
            description: "Ensure mount/3 uses `params` as first arg and align body refs (absolute-final)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.MountParamsUltraFinalTransforms.transformPass,
            runAfter: ["ChainAssignIfPromote_Replay_Last"]
        });
        passes.push({
            name: "HandleEventParamsUltraFinal",
            description: "Ensure handle_event/3 uses `params` as second arg and align body refs (absolute-final)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.HandleEventParamsUltraFinalTransforms.transformPass,
            runAfter: ["MountParamsUltraFinal"]
        });
        passes.push({
            name: "ParamUnderscoreArgRefAlign_Final",
            description: "Final sweep: rewrite `_params` to `params` in bodies of defs that have a `params` arg (after promotions)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ParamUnderscoreArgRefAlignTransforms.pass,
            runAfter: ["HandleEventParamsUltraFinal", "MountParamsUltraFinal"]
        });
        passes.push({
            name: "ParamUnderscoreGlobalAlign_Final",
            description: "Absolute final safety: rewrite `_params` to `params` inside handle_event/3 and mount/3 bodies",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ParamUnderscoreGlobalAlignFinalTransforms.pass,
            runAfter: ["ParamUnderscoreArgRefAlign_Final"]
        });
        passes.push({
            name: "HandleEventParamsForceBodyRewrite_Final",
            description: "Absolute final: force `_params` → `params` inside handle_event/3 bodies",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.HandleEventParamsForceBodyRewriteFinalTransforms.pass,
            runAfter: [
                "ParamUnderscoreGlobalAlign_Final",
                "DefParamUnusedUnderscoreGlobalSafe_Final",
                "DropInvalidMapGetSelfAssign_Final",
                "MountSessionExtractCleanup_Final",
                "EctoQueryBranchSelfAssignUnderscore_Final",
                "AssignWhereSelfBinderUnderscore_Final"
            ]
        });
        passes.push({
            name: "DefParamUsedBaseNamePromotion_Final",
            description: "Promote underscored def params to base name when body uses base name (absolute final)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.DefParamUsedBaseNamePromotionFinalTransforms.pass,
            // Make this truly last across hygiene by running after all late underscore/align replays
            runAfter: [
                "ParamUnderscoreArgRefAlign_Final",
                "ParamUnderscoreGlobalAlign_Final",
                "HandleEventParamsForceBodyRewrite_Final",
                "DefParamUnusedUnderscoreGlobalSafe_Final",
                "DropInvalidMapGetSelfAssign_Final",
                "MountSessionExtractCleanup_Final",
                "EctoQueryBranchSelfAssignUnderscore_Final",
                "AssignWhereSelfBinderUnderscore_Final",
                "LocalAssignUnusedUnderscore_Final"
            ]
        });
        // Re-run safe unused-def-param underscore promotion at the very end
        passes.push({
            name: "DefParamUnusedUnderscoreGlobalSafe_Final",
            description: "Final replay: underscore unused def params (safe, global) [disabled due to false positives in Web helpers]",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.DefParamUnusedUnderscoreGlobalSafeTransforms.pass,
            runAfter: ["ParamUnderscoreGlobalAlign_Final"]
        });
        // Absolute-final sanitizer: drop any self-assign Map.get artifacts
        passes.push({
            name: "DropInvalidMapGetSelfAssign_Final",
            description: "Absolute final: remove Map.get(params, key) = Map.get(params, key) statements in defs",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.DropInvalidMapGetSelfAssignTransforms.pass,
            runAfter: ["DefParamUnusedUnderscoreGlobalSafe_Final", "ParamUnderscoreGlobalAlign_Final", "HandleEventParamsUltraFinal", "MountParamsUltraFinal"]
        });
        // Absolute-final: ensure mount/3 session extraction is dropped if still present
        passes.push({
            name: "MountSessionExtractCleanup_Final",
            description: "Absolute final: drop `session = Map.get(params, \"session\")` inside mount/3",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.MountSessionExtractCleanupTransforms.pass,
            runAfter: ["DropInvalidMapGetSelfAssign_Final"]
        });
        // Absolute-final: underscore/discard mount/3 local reassign of params when unused later
        passes.push({
            name: "MountParamsUnusedReassignUnderscore_Final",
            description: "Rename `params = ...` to `_` in mount/3 when unused later (preserve RHS)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.MountParamsUnusedReassignUnderscoreTransforms.pass,
            runAfter: [
                "MountSessionExtractCleanup_Final",
                "MountParamsSideEffectAssignDiscard_Final",
                "ParamUnderscoreGlobalAlign_Final",
                "HandleEventParamsUltraFinal_Last",
                "VarNameNormalization_Final",
                "VarRefSuffixParamNormalize_Final",
                "VarRefSuffixParamNormalize_UltraFinal",
                "VarRefQueryInlineDowncaseFromSuffixParam_UltraFinal",
                "QueryVarUltimateNormalize_UltraFinal",
                "FunctionQueryBinderSynthesis_UltraFinal",
                "SuccessBinderPrefixMostUsedUndefined_UltraFinal"
            ]
        });
        // Absolute final: discard `params = expr` side-effect-only assignments in mount/3
        passes.push({
            name: "MountParamsSideEffectAssignDiscard_Final",
            description: "Drop head-binder reassignments of params in mount/3 when unused later",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.MountParamsSideEffectAssignDiscardTransforms.pass,
            runAfter: [
                "MountSessionExtractCleanup_Final",
                "DefParamUnusedUnderscoreGlobalSafe_Final",
                "ParamUnderscoreArgRefAlign_Final",
                "ParamUnderscoreGlobalAlign_Final",
                "MountBodyAlignToHead_Final",
                "HandleEventParamsUltraFinal",
                "HandleEventParamsUltraFinal_Last",
                "HandleEventBodyAlignToHead_Final",
                "DefParamHeadUnderscoreWhenUnused_Final",
                "EctoRepoFinalArgFromLatestQueryVar",
                "EctoQueryBranchSelfAssignUnderscore_Final",
                "AssignWhereSelfBinderUnderscore_Final"
            ]
        });
        // Absolute-final replay: underscore unused locals in Controller modules (late shapes)
        passes.push({
            name: "ControllerLocalUnusedUnderscore_Final",
            description: "Final replay: underscore unused local assignment binders in controllers",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ControllerLocalUnusedUnderscoreTransforms.pass,
            runAfter: [
                "MountSessionExtractCleanup_Final",
                "VarNameNormalization_Final",
                "VarRefSuffixParamNormalize_Final",
                "VarRefSuffixParamNormalize_UltraFinal",
                "VarRefQueryInlineDowncaseFromSuffixParam_UltraFinal",
                "QueryVarUltimateNormalize_UltraFinal",
                "FunctionQueryBinderSynthesis_UltraFinal",
                "SuccessBinderPrefixMostUsedUndefined_UltraFinal"
            ]
        });
        // Absolute-final: drop pure var-copy assignments in <App>Web.* when binder unused later
        passes.push({
            name: "WebDropUnusedPureAssign_Final",
            description: "Drop `x = y` when x unused later in Web.* modules",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.WebDropUnusedPureAssignTransforms.pass,
            runAfter: ["ControllerLocalUnusedUnderscore_Final"]
        });
        // Replay controller result binder normalization very late to ensure clause bodies align with Phoenix.Controller.json usage
        passes.push({
            name: "ControllerResultBinderNormalization_Replay_Final",
            description: "Late replay: rename {:ok,_}/{:error,_} binders (user/changeset) and alias `data` when referenced",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.controllerResultBinderNormalizationPass
        });
        passes.push({
            name: "ControllerPhoenixJsonAliasInjection_Replay_Final",
            description: "Late replay: inject `data = <binder>` when Phoenix.Controller.json(conn, data) is used",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.controllerPhoenixJsonAliasInjectionPass
        });
        // Absolute-final: underscore self-assign concat binders to avoid overshadow warnings
        passes.push({
            name: "ConcatSelfAssignBinderUnderscore_Final",
            description: "Rewrite `x = Enum.concat(x, ...)` → `_x = Enum.concat(x, ...)` in blocks",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ConcatSelfAssignBinderUnderscoreTransforms.pass,
            runAfter: ["WebDropUnusedPureAssign_Final"]
        });
        passes.push({
            name: "EctoQueryBranchSelfAssignUnderscore_Final",
            description: "Absolute final replay: underscore trailing self-assign where/3 in branches",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EctoQueryBranchSelfAssignUnderscoreTransforms.pass,
            runAfter: ["ControllerLocalUnusedUnderscore_Final"]
        });
        passes.push({
            name: "AssignWhereSelfBinderUnderscore_Final",
            description: "Absolute final replay: rewrite `x = Ecto.Query.where(x, ...)` to `_x = ...` everywhere",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.AssignWhereSelfBinderUnderscoreTransforms.pass,
            runAfter: ["EctoQueryBranchSelfAssignUnderscore_Final"]
        });
        // Late: fix Repo.all/Repo.one(query) to use last refined binder from query if/where chain
        passes.push({
            name: "EctoRepoFinalArgFromLatestQueryVar",
            description: "Rewrite Repo.*(query) to use last refinement binder when present in the same block",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EctoRepoFinalArgFromLatestQueryVarTransforms.pass,
            runAfter: ["AssignWhereSelfBinderUnderscore_Final"]
        });
        passes.push({
            name: "EctoRepoArgModuleQualify_Final",
            description: "Qualify schema arg in Repo.get/one to <App>.<Name> when bare CamelCase is used",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EctoRepoArgModuleQualifyTransforms.pass,
            runAfter: ["EctoRepoFinalArgFromLatestQueryVar"]
        });
        // Absolute-final: ensure Phoenix component functions using ~H have `assigns` as the first arg
        passes.push({
            name: "HeexAssignsParamRename_Final",
            description: "Absolute final safety: rename _assigns → assigns when ~H is present in body",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.HeexAssignsParamRenameFinalTransforms.pass,
            runAfter: ["AssignWhereSelfBinderUnderscore_Final", "DefParamUnusedUnderscoreGlobalSafe_Final"]
        });
        // Absolute-final: underscore `params` head binder in mount/3 and handle_event/3
        // when unused in the body to silence warnings
        passes.push({
            name: "DefParamHeadUnderscoreWhenUnused_Final",
            description: "Rename params→_params in mount/3 & handle_event/3 when body does not reference params",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.DefParamHeadUnderscoreWhenUnusedTransforms.pass,
            runAfter: [
                "MountBodyAlignToHead_Final",
                "MountSessionExtractCleanup_Final",
                "MountDropHeadIdentityReassign_Final",
                "HandleEventParamsForceBodyRewrite_Final"
            ]
        });
        // Absolute-last: guarantee no `_params` uses remain in handle_event/3
        passes.push({
            name: "HandleEventParamsUltraFinal_Last",
            description: "Last guard: if body uses _params, set head to params and rewrite body",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.HandleEventParamsUltraFinalLastTransforms.pass,
            runAfter: [
                "DefParamHeadUnderscoreWhenUnused_Final",
                "DefParamUnusedUnderscoreGlobalSafe_Final",
                "DropInvalidMapGetSelfAssign_Final",
                "MountSessionExtractCleanup_Final",
                "EctoRepoFinalArgFromLatestQueryVar",
                "AssignWhereSelfBinderUnderscore_Final"
            ]
        });
        passes.push({
            name: "HandleEventParamsHeadToParams_Final",
            description: "Absolute-final: force handle_event/3 second arg to params when referenced; rewrite _params to params in body",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.HandleEventParamsHeadToParamsFinalTransforms.pass,
            runAfter: [
                "HandleEventParamsUltraFinal_Last",
                "HandleEventValueVarNormalizeForceFinal_Last2",
                "LocalAssignUnusedUnderscore_Scoped_Final",
                "ParamUnderscoreArgRefAlign_Final",
                "ParamUnderscoreGlobalAlign_Final",
                "HandleEventParamsForceBodyRewrite_Final"
            ]
        });
        // Absolute-last safety for Map.get(value, …) inside handle_event/3 when no `value` binding exists
        passes.push({
            name: "HandleEventValueVarNormalize_AbsoluteLast",
            description: "Rewrite Map.get(value, key) → Map.get(params/_params, key) when `value` is undefined in handle_event/3",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.HandleEventValueVarNormalizeTransforms.pass,
            runAfter: [
                "HandleEventParamExtractFromBodyUse_Final",
                "HandleEventParamRepair_Final",
                "HandleEventParamsUltraFinal",
                "HandleEventParamsUltraFinal_Last"
            ]
        });
        // Ultra-absolute last (will be re-added at footer with stronger constraints)
        passes.push({
            name: "HandleEventValueVarNormalizeForceFinal_Last",
            description: "Force Map.get(value, …) → Map.get(params/_params, …) in handle_event/3 (last pass)",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.HandleEventValueVarNormalizeForceFinalTransforms.pass
        });
        passes.push({
            name: "LocalAssignUnusedUnderscore_Scoped_Final",
            description: "Final (scoped): underscore local assigns not used later in defs except mount/3",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.LocalAssignUnusedUnderscoreScopedTransforms.pass,
            runAfter: ["EctoQueryBranchSelfAssignUnderscore_Final"]
        });

        // Absolute final replay to fix any remaining param/body mismatches for underscored head params
        passes.push({
            name: "ParamUnderscoreArgRefAlign_Global_Final",
            description: "Final replay: align body refs (v→_v) when head params are underscored",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ParamUnderscoreArgRefAlignGlobalTransforms.pass,
            runAfter: [
                "DefParamUnusedUnderscoreGlobalSafe_Final",
                "DefParamHeadUnderscoreWhenUnused_Final",
                "HeexAssignsParamRename_Final"
            ]
        });

        // FINAL guard: force fix any Map.get(value, …) that survived all prior passes
        passes.push({
            name: "HandleEventValueVarNormalizeForceFinal_Last2",
            description: "Ultimate guard: Force Map.get(value, …) → Map.get(params/_params, …) inside handle_event/3",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.HandleEventValueVarNormalizeForceFinalTransforms.pass,
            runAfter: [
                "ChainAssignIfPromote_Replay_Last",
                "QueryVarUltimateNormalize_Replay_Last",
                "CaseOkBinderPrefixBindAllUndefined_Replay_Last",
                "MountParamsUltraFinal",
                "HandleEventParamsUltraFinal",
                "ParamUnderscoreArgRefAlign_Final",
                "ParamUnderscoreGlobalAlign_Final",
                "HandleEventParamsForceBodyRewrite_Final",
                "DefParamHeadUnderscoreWhenUnused_Final",
                "HandleEventParamsUltraFinal_Last",
                "ParamUnderscoreArgRefAlign_Global_Final"
            ]
        });
        // Normalize assign_multiple assignment pattern outside mount (late, app-agnostic)
        passes.push({
            name: "AssignMultipleNormalize_Final",
            description: "Rewrite left = (assigns = map); Phoenix.Component.assign(socket, assigns) → left = Phoenix.Component.assign(socket, map)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.AssignMultipleNormalizeTransforms.pass,
            runAfter: [
                "HandleEventValueVarNormalizeForceFinal_Last2",
                "HandleEventParamsHeadToParams_Ultimate",
                "HandleEventMapGetUnderscoreParams_Final"
            ]
        });
        // Re-introduce: ensure head binder is `params` when body uses it, but BEFORE
        // DefParamHeadUnderscoreWhenUnused_Final so unused flows can still underscore.
        passes.push({
            name: "HandleEventParamsUltraForceRewrite_PreUnderscoreFinal",
            description: "Force handle_event/3 second arg to params and rewrite body (pre-underscore-final)",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.HandleEventParamsUltraForceRewriteAbsoluteFinalTransforms.pass
        });
        passes.push({
            name: "HandleEventMapGetUnderscoreParams_Final",
            description: "Absolute-last: rewrite Map.get(_params, key) → Map.get(params, key) in handle_event/3 bodies",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.HandleEventMapGetUnderscoreParamsFinalTransforms.pass,
            runAfter: [
                // Ensure the head binder has been promoted decisively to `params`
                // before rewriting Map.get(_params, …) in the body.
                "HandleEventParamsHeadToParams_Ultimate",
                "HandleEventParamsHeadToParams_Final",
                "HandleEventValueVarNormalize_AbsoluteLast",
                "HandleEventValueVarNormalizeForceFinal_Last2"
            ]
        });
        // Final: promote handle_info {:some, _x} binder to `payload` and rewrite refs
        passes.push({
            name: "HandleInfoUnderscoreBinderPromote_Final",
            description: "Promote {:some, _x} binder to payload in handle_info/2 and rewrite refs",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.HandleInfoUnderscoreBinderPromoteFinalTransforms.pass,
            runAfter: [
                "HandleInfoUnderscoreSocketFix_Final",
                "HandleInfoAliasCleanup_Final",
                "HandleInfoReturnSocketNormalize_Final",
                "HandleInfoScrutineeToPayloadRef_Final"
            ]
        });
        // LiveView-only: discard local assignments never read later (var = expr -> _ = expr)
        passes.push({
            name: "LocalAssignDiscardIfUnused_LiveView_Final",
            description: "In <App>Web.Live modules, replace unused local assigns with `_ = expr` (final)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.LocalAssignDiscardIfUnusedLiveViewFinalTransforms.pass,
            runAfter: [
                "ListUpdateAndFilterFix",
                "WebParamFinalFix",
                "HandleEventParamRepair_Final"
            ]
        });
        // Ultimate: if body references `params`, ensure head binder is params
        passes.push({
            name: "HandleEventParamsHeadToParams_Ultimate",
            description: "Absolute-ultimate: when body uses params, force head binder to params",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.HandleEventParamsHeadToParamsUltimateTransforms.pass,
            runAfter: [
                "LocalAssignDiscardIfUnused_LiveView_Final",
                "ParamUnderscoreArgRefAlign_Global_Final",
                "HandleEventParamExtractFromBodyUse_Final",
                "HandleEventParamRepair_Final",
                "HandleEventParamsUltraFinal",
                "HandleEventParamsUltraFinal_Last",
                "HandleEventValueVarNormalize_AbsoluteLast",
                "HandleEventValueVarNormalizeForceFinal_Last2"
            ]
        });
        passes.push({
            name: "IfBranchDowncaseTempInline_Final",
            description: "Inline `_tmp = rhs; String.downcase(_tmp)` inside if/else branches",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.IfBranchDowncaseTempInlineFinalTransforms.pass,
            runAfter: [
                "UnderscoreTempInlineDowncase",
                "DowncaseInlineFromPriorAssign_Final"
            ]
        });
        // Removed: FunctionParamUnusedUnderscore_Scoped_Final — rely on existing DefParamHeadUnderscoreWhenUnused_Final
        // Penultimate after force Map.get rewrite: replace any remaining bare `value` with param var
        passes.push({
            name: "HandleEventUndefinedValueToParam_AbsoluteLast",
            description: "In handle_event/3, if `value` is not declared, rewrite EVar(value) → EVar(params/_params)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.HandleEventUndefinedValueToParamTransforms.pass,
            runAfter: ["HandleEventValueVarNormalizeForceFinal_Last2", "HandleEventParamsUltraFinal_Last"]
        });
        passes.push({
            name: "HandleEventIdExtractNormalize_AbsoluteLast",
            description: "Normalize id extract branches to use the same params var instead of `value` in handle_event/3",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.HandleEventIdExtractNormalizeTransforms.pass,
            runAfter: [
                "HandleEventUndefinedValueToParam_AbsoluteLast",
                "HandleEventValueVarNormalizeForceFinal_Last2",
                "HandleEventParamExtractFromBodyUse_Final",
                "HandleEventParamRepair_Final",
                "HandleEventParamsUltraFinal_Last"
            ]
        });
        passes.push({
            name: "HandleEventArg0FromValueToId_Ultimate",
            description: "When a helper call uses Map.get(params, \"value\", …) as first arg, replace with integer id from nested value map (or params id fallback)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.HandleEventArg0FromValueToIdUltimateTransforms.pass,
            runAfter: [
                "HandleEventParamsHeadToParams_Ultimate",
                "HandleEventMapGetUnderscoreParams_Final",
                "HandleEventMapGetValueDefaultToParams_Final",
                "HandleEventUndefinedValueToParam_AbsoluteLast",
                "HandleEventIdExtractNormalize_AbsoluteLast",
                "HandleEventValueVarNormalizeForceFinal_Last2"
            ]
        });
        passes.push({
            name: "HandleEventDecodeValueQueryIfBinary_Ultimate",
            description: "Decode Map.get(params, \"value\") when it is a URL-encoded query string (URI.decode_query)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.HandleEventDecodeValueQueryIfBinaryUltimateTransforms.pass,
            runAfter: [
                "HandleEventParamsHeadToParams_Ultimate",
                "HandleEventMapGetUnderscoreParams_Final",
                "HandleEventMapGetValueDefaultToParams_Final"
            ]
        });
        // Very late: ensure Map.get(<payload>, "value") uses `<payload>` as default when missing (forms)
        passes.push({
            name: "HandleEventMapGetValueDefaultToParams_Final",
            description: "In handle_event/3, rewrite Map.get(params|_params, \"value\") → Map.get(params|_params, \"value\", params|_params)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.HandleEventMapGetValueDefaultToParamsFinalTransforms.pass,
            runAfter: [
                "HandleEventParamsHeadToParams_Ultimate",
                "HandleEventMapGetUnderscoreParams_Final",
                "HandleEventValueVarNormalize_AbsoluteLast",
                "HandleEventValueVarNormalizeForceFinal_Last2",
                "HandleEventUndefinedValueToParam_AbsoluteLast",
                "HandleEventIdExtractNormalize_AbsoluteLast"
            ]
        });
        passes.push({
            name: "FunctionParamUnusedUnderscore_Final",
            description: "Underscore unused def/defp parameters (absolute-final)",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.FunctionParamUnusedUnderscoreFinalTransforms.pass
        });
        passes.push({
            name: "CaseClauseUnusedBinderUnderscore_Final",
            description: "In case clauses, underscore unused binders (absolute-final)",
            enabled: false,
            pass: reflaxe.elixir.ast.transformers.CaseClauseUnusedBinderUnderscoreFinalTransforms.pass
        });

        // Final replay: ensure tuple binders promoted when base is used (body or guard)
        passes.push({
            name: "CaseTupleMultiBinderPromoteByUse_Final",
            description: "(final) Promote tuple binders _name -> name when used; second pass to catch late changes",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseTupleMultiBinderPromoteByUseTransforms.pass
        });
        // Absolute-final: clean handle_info clause artifacts (drop socket alias; normalize noreply payload)
        passes.push({
            name: "HandleInfoAliasAndNoreply_AbsoluteFinal",
            description: "Absolute-final: in handle_info/2, drop leading alias to socket and rewrite {:noreply, _socket} → {:noreply, socket}",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.HandleInfoAliasAndNoreplyAbsoluteFinalTransforms.pass,
            runAfter: [
                "HandleInfoReturnSocketNormalize_Final",
                "HandleInfoScrutineeToPayloadRef_Final",
                "UnderscoreToParamSocketFix_Final",
                "HandleInfoAliasCleanup_Final"
            ]
        });

        // Filter disabled passes first
        var enabled = passes.filter(p -> p.enabled);
        // Validate current list (unique names, missing deps, cycles report only)
        enabled = reflaxe.elixir.ast.transformers.registry.RegistryCore.validate(enabled);
        // Apply lightweight topological sort based on optional runAfter/runBefore
        enabled = sortPassesByConstraints(enabled);
        return enabled;
    
    }

    /**
     * sortPassesByConstraints
     * WHAT: Stable topological sort honoring optional runAfter/runBefore metadata.
     * WHY: Provide deterministic ordering without hard-coded indices; allow passes to declare
     *      minimal dependencies while keeping default order stable.
     * HOW: Kahn’s algorithm; unknown pass names are ignored; on cycles, fall back to the
     *      original order (debug warns when -D debug_pass_order is enabled).
     */
    static function sortPassesByConstraints(passes: Array<ElixirASTTransformer.PassConfig>): Array<ElixirASTTransformer.PassConfig> {
        var indexByName = new Map<String, Int>();
        for (i in 0...passes.length) indexByName.set(passes[i].name, i);

        var adj = new Map<String, Array<String>>();
        var indeg = new Map<String, Int>();
        for (p in passes) { adj.set(p.name, []); indeg.set(p.name, 0); }

        inline function addEdge(from:String, to:String):Void {
            if (!adj.exists(from) || !adj.exists(to)) return;
            var lst = adj.get(from);
            var dup = false; for (x in lst) if (x == to) { dup = true; break; }
            if (!dup) { lst.push(to); adj.set(from, lst); indeg.set(to, indeg.get(to) + 1); }
        }

        for (p in passes) {
            if (p.runAfter != null) for (q in p.runAfter) addEdge(q, p.name);
            if (p.runBefore != null) for (q in p.runBefore) addEdge(p.name, q);
        }

        var ready:Array<String> = [];
        for (p in passes) if (indeg.get(p.name) == 0) ready.push(p.name);
        // stable by original index
        ready.sort(function(a,b) return indexByName.get(a) - indexByName.get(b));

        var out:Array<String> = [];
        while (ready.length > 0) {
            var n = ready.shift();
            out.push(n);
            for (m in adj.get(n)) {
                var v = indeg.get(m) - 1; indeg.set(m, v);
                if (v == 0) {
                    ready.push(m);
                    ready.sort(function(a,b) return indexByName.get(a) - indexByName.get(b));
                }
            }
        }

        if (out.length != passes.length) {
            #if debug_pass_order
            Sys.println('[PassOrder] Cycle or unresolved constraint; falling back to original order');
            #end
            return passes;
        }
        var byName = new Map<String, ElixirASTTransformer.PassConfig>();
        for (p in passes) byName.set(p.name, p);
        var sorted:Array<ElixirASTTransformer.PassConfig> = [];
        for (n in out) sorted.push(byName.get(n));
        #if debug_pass_order
        Sys.println('[PassOrder] ' + out.join(' → '));
        #end
        return sorted;
    }
}
#end
