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
        
        // Identity pass (always first - ensures pass-through functionality)
        passes.push({
            name: "Identity",
            description: "Pass-through transformation (no changes)",
            enabled: true,
            pass: reflaxe.elixir.ast.ElixirASTTransformer.alias_identityPass
        });
        
        // Resolve clause locals pass (must run very early to fix variable references)
        passes.push({
            name: "ResolveClauseLocals",
            description: "Resolve variable references in case clauses using varIdToName metadata",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.TempVariableTransforms.resolveClauseLocalsPass
        });

        // Remove redundant enum extraction pass (must run early to fix pattern matching)
        passes.push({
            name: "RemoveRedundantEnumExtraction",
            description: "Remove redundant elem() calls after pattern extraction in case clauses",
            enabled: true,
            pass: reflaxe.elixir.ast.ElixirASTTransformer.alias_removeRedundantEnumExtractionPass
        });

        // Throw statement transformation (must run early to fix complex expressions)
        passes.push({
            name: "ThrowStatementTransform",
            description: "Transform complex throw expressions to avoid syntax errors",
            enabled: true,
            pass: reflaxe.elixir.ast.ElixirASTTransformer.alias_throwStatementTransformPass
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
            pass: reflaxe.elixir.ast.ElixirASTTransformer.alias_functionReferenceTransformPass
        });
        
        // Bitwise import pass (should run early to add imports)
        passes.push({
            name: "BitwiseImport",
            description: "Add Bitwise import when bitwise operators are used",
            enabled: true,
            pass: reflaxe.elixir.ast.ElixirASTTransformer.alias_bitwiseImportPass
        });
        
        // Loop transformation pass (convert reduce_while patterns to idiomatic loops)
        passes.push({
            name: "LoopTransformation",
            description: "Transform non-idiomatic loop patterns (reduce_while with Stream.iterate) to idiomatic Enum operations and comprehensions",
            enabled: true,
            pass: reflaxe.elixir.ast.ElixirASTTransformer.alias_loopTransformationPass
        });

        // Collapse simple temp-binding blocks in expression contexts
        passes.push({
            name: "InlineTempBindingInExpr",
            description: "Collapse EBlock([tmp = exprA, exprB(tmp)]) to exprB(exprA) in expression positions",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.TempVariableTransforms.inlineTempBindingInExprPass
        });

        // Presence reduce rewrite very early to catch Enum.each over presence maps before other list rewrites
        passes.push({
            name: "PresenceReduceRewrite(VeryEarly)",
            description: "Rewrite Presence Enum.each + Reflect.fields/Map.get scans to Enum.reduce(Map.values(map), [], ...) with conditional append",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.PresenceReduceRewriteTransforms.presenceReduceRewritePass
        });

        // Debug: XRay map field values that contain EBlock
        passes.push({
            name: "XRayMapBlocks",
            description: "Debug pass to log map fields containing EBlock values",
            enabled: #if debug_temp_binding true #else false #end,
            pass: function(ast) {
                return reflaxe.elixir.ast.ElixirASTTransformer.transformNode(ast, function(node) {
                    switch(node.def) {
                        case EMap(pairs):
                            for (p in pairs) {
                                switch(p.value.def) {
                                    case EBlock(exprs):
                                        trace('[XRayMapBlocks] Found EBlock in map value with ' + exprs.length + ' exprs');
                                        for (i in 0...exprs.length) trace('  expr[' + i + ']: ' + ElixirASTPrinter.print(exprs[i], 0));
                                    default:
                                }
                            }
                            return node;
                        default:
                            return node;
                    }
                });
            }
        });
        
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
        
        passes.push({
            name: "PresenceTransform",
            description: "Transform @:presence modules into Phoenix.Presence structure",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.AnnotationTransforms.presenceTransformPass
        });
        
        // Phoenix Component import pass (MUST run AFTER LiveViewTransform to detect LiveView use statements)
        passes.push({
            name: "PhoenixComponentImport",
            description: "Add Phoenix.Component import when ~H sigil is used (unless LiveView already includes it)",
            enabled: true,
            pass: reflaxe.elixir.ast.ElixirASTTransformer.alias_phoenixComponentImportPass
        });
        
        // LiveView CoreComponents import pass (should run after Phoenix Component)
        passes.push({
            name: "LiveViewCoreComponentsImport",
            description: "Add CoreComponents import for LiveView modules that use components",
            enabled: true,
            pass: reflaxe.elixir.ast.ElixirASTTransformer.alias_liveViewCoreComponentsImportPass
        });
        
        // Phoenix function name mapping pass (transforms assign_multiple to assign, etc.)
        passes.push({
            name: "PhoenixFunctionMapping",
            description: "Map custom function names to Phoenix conventions",
            enabled: true,
            pass: reflaxe.elixir.ast.ElixirASTTransformer.alias_phoenixFunctionMappingPass
        });

        // Inject `require Ecto.Query` in modules that call Ecto.Query macros (from/where/order_by/preload)
        passes.push({
            name: "EctoQueryRequireInjection",
            description: "Add `require Ecto.Query` to modules that use Ecto.Query macros",
            enabled: true,
            pass: reflaxe.elixir.ast.ElixirASTTransformer.alias_ectoQueryRequirePass
        });
        
        passes.push({
            name: "ControllerTransform",
            description: "Transform @:controller modules into Phoenix.Controller structure",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.AnnotationTransforms.controllerTransformPass
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
        
        // Guard condition grouping pass (must run before other pattern transformations)
        passes.push({
            name: "GuardGrouping",
            description: "Transform multiple case clauses with same pattern and guards into cond",
            enabled: true,
            pass: function(ast) return ElixirASTTransformer.alias_guardGroupingPass(ast)
        });
        
        // Constant folding pass
        // String interpolation transformation (should run before constant folding)
        passes.push({
            name: "StringInterpolation",
            description: "Convert string concatenation to idiomatic string interpolation",
            enabled: true,
            pass: reflaxe.elixir.ast.ElixirASTTransformer.alias_stringInterpolationPass
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
        passes.push({
            name: "ApplicationEnsureStartLink",
            description: "Ensure Application.start/2 appends Supervisor.start_link(children, opts)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ApplicationEnsureStartLinkTransforms.transformPass
        });
        // Override problematic Haxe DS modules with minimal native implementations
        passes.push({
            name: "StdDsOverrides",
            description: "Override haxe.ds BalancedTree/EnumValueMap modules with minimal Elixir implementations",
            enabled: true,
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
            name: "ModuleQualification(Final)",
            description: "Final Web-context qualification <App>.Module after all rewrites",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.moduleQualificationPass
        });
        
        // Array method transformations are handled in ElixirASTBuilder
        // at the TCall(TField(...)) pattern to generate idiomatic Elixir directly
        
        // Unrolled loop transformation pass (should run early to fix unrolled patterns)
        passes.push({
            name: "UnrolledLoopTransform",
            description: "Transform unrolled loops (sequential statements) back to Enum.each",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.LoopTransforms.unrolledLoopTransformPass
        });
        
        // Map iterator transformation pass (transforms g.next() patterns to idiomatic Elixir)
        passes.push({
            name: "MapIteratorTransform",
            description: "Transform Map iterator patterns from g.next() to idiomatic Enum operations",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.MapAndCollectionTransforms.mapIteratorTransformPass
        });
        
        // Rewrite imperative var.set(key, value) calls to Map.put var rebinding
        passes.push({
            name: "MapSetRewrite",
            description: "Rewrite var.set(key, value) to var = Map.put(var, :key, value)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.MapAndCollectionTransforms.mapSetRewritePass
        });
        
        // Loop to comprehension pass
        #if !disable_comprehension_conversion
        passes.push({
            name: "ComprehensionConversion",
            description: "Convert imperative loops to comprehensions",
            enabled: true,
            pass: reflaxe.elixir.ast.ElixirASTTransformer.alias_comprehensionConversionPass
        });
        #end
        
        // Unrolled comprehension optimization pass (MUST run before effect lifting)
        // TODO: Fix implementation - functions need to be moved before this reference
        /*
        passes.push({
            name: "UnrolledComprehensionOptimization",
            description: "Optimize unrolled array comprehensions with bare concatenations",
            enabled: true,
            pass: reflaxe.elixir.ast.ElixirASTTransformer.alias_unrolledComprehensionOptimizationPass
        });
        */
        
        // Effect lifting for list literals pass
        passes.push({
            name: "ListEffectLifting",
            description: "Lift side-effecting expressions out of list literals",
            enabled: true,
            pass: reflaxe.elixir.ast.ElixirASTTransformer.alias_listEffectLiftingPass
        });
        
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
            enabled: true,
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

        // Ensure case clause bodies are not empty (avoid syntax errors)
        passes.push({
            name: "CaseClauseEmptyBodyToNil",
            description: "Replace empty case arm bodies with nil to ensure valid syntax",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseClauseFixTransforms.caseClauseEmptyBodyToNilPass
        });

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
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.caseClauseBinderRenameFromExprPass
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

        // Prefix unused case-pattern binders with underscore to avoid warnings
        passes.push({
            name: "ClauseUnusedBinderUnderscore",
            description: "Within case arms, prefix unused binders with underscore",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ClauseUnusedBinderUnderscoreTransforms.clauseUnusedBinderUnderscorePass
        });
        passes.push({
            name: "ClauseUnusedBinderUnderscore(Final)",
            description: "Final sweep to underscore unused binders in case arms",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ClauseUnusedBinderUnderscoreTransforms.clauseUnusedBinderUnderscorePass
        });
        passes.push({
            name: "CaseUnderscoreBinderPromoteByUse(Final)",
            description: "Promote underscored binders (_name) to name when body uses name and no conflict exists",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseUnderscoreBinderPromoteByUseTransforms.transformPass
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
            description: "Rename LiveView error binders to reason",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.liveViewErrorBinderRenamePass
        });

        // Rename Repo result binders based on body usage (user/data/changeset/reason)
        passes.push({
            name: "ResultBinderRenameByBodyUsage",
            description: "Rename {:ok,_}/{:error,_} binder to names used in bodies",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.resultBinderRenameByBodyUsagePass
        });

        // Generic: rename single payload binder in case arms based on clause body usage
        passes.push({
            name: "SingleBinderByUsage",
            description: "Rename {:tag, value} binder to the unique undefined var used in body (e.g., todo/id/params)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.SingleBinderByUsageTransforms.renameSingleBinderByBodyUsagePass
        });

        // Generic: replace undefined vars in clause bodies with the single bound binder when unambiguous
        passes.push({
            name: "ClauseUndefinedVarToBinder",
            description: "Within {:tag, value} arms, replace unique undefined var in body with binder",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ClauseUndefinedVarToBinderTransforms.replaceUndefinedVarWithBinderPass
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
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.repoResultBinderNormalizationPass
        });

        // Controller-specific Repo result binder normalization
        passes.push({
            name: "ControllerResultBinderNormalization",
            description: "In controllers, rename {:ok,_}/{:error,_} binders and alias data as needed",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.controllerResultBinderNormalizationPass
        });

        // Ensure Phoenix.Controller.json bodies have aliases (user/changeset/data) from result binders
        passes.push({
            name: "ControllerPhoenixJsonAliasInjection",
            description: "Inject aliases (user/changeset/data) for Phoenix.Controller.json bodies from {:ok,_}/{:error,_}",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.controllerPhoenixJsonAliasInjectionPass
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
            name: "ListPushRewrite(Late)",
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

        // Insert alias <App>.Repo as Repo in Web modules that reference Repo.*
        passes.push({
            name: "RepoAliasInjection",
            description: "Inject `alias <App>.Repo, as: Repo` when Repo.* is used in Web modules",
            enabled: true,
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

        // Unify case success vars in {:ok, v} branches to eliminate undefined placeholders
        passes.push({
            name: "CaseSuccessVarUnifier",
            description: "Rewrite undefined placeholders (todo/updated_todo) to success var in {:ok, v} clauses",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseSuccessVarUnifier.unifySuccessVarPass
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
            description: "Fallback renaming of EVar(name) -> EVar(_name) when only _name declared",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.LocalUnderscoreReferenceFallbackTransforms.fallbackUnderscoreReferenceFixPass
        });

        // Finally, if a local is declared underscored but used later, rename declaration
        // to non-underscored to eliminate warnings and undefined refs
        passes.push({
            name: "UsedUnderscoreRename",
            description: "Rename _var to var when var is referenced and var is not declared",
            enabled: true,
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
            name: "StringToolsFix(Final)",
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
            name: "ChangesetFieldAtomNormalize(Late)",
            description: "Late sweep to normalize validate_* field argument to literal atom",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ChangesetTransforms.normalizeValidateFieldAtomPass
        });
        // Final guarantee: normalize validate_* field atom literals at the very end
        passes.push({
            name: "ChangesetFieldAtomNormalize(Final)",
            description: "Final normalization of validate_* field args to :field",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ChangesetTransforms.normalizeValidateFieldAtomPass
        });
        // Ecto where pinned-nil guard: rewrite `field == ^var` to guarded case using Kernel.is_nil(var)
        passes.push({
            name: "EctoEqPinnedNilGuard(Late)",
            description: "Guard Ecto where comparisons with pinned vars that may be nil",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EctoEqPinnedNilGuardTransforms.transformPass
        });
        // Ensure schema changeset/2 binders align with body usage (underscore → base)
        passes.push({
            name: "EctoSchemaBinderFix(Final)",
            description: "Normalize changeset/2 binder names by dropping underscores when body uses base names",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EctoSchemaBinderFixTransforms.transformPass
        });

        // Normalize Ecto where query arg by inlining IIFE wrappers around from/2
        passes.push({
            name: "EctoQueryIIFEInline(Late)",
            description: "Inline (fn -> ... from(...) ... end).() used as where/2 query arg",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EctoQueryIIFEInlineTransforms.transformPass
        });

        // Final EqNilToIsNil to catch any newly introduced comparisons
        passes.push({
            name: "EqNilToIsNil(Final)",
            description: "Final replacement of (x == nil)/(x != nil) with Kernel.is_nil/1",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.eqNilToIsNilPass
        });
        // Final sweep: rewrite opts.* in validate_length keyword lists
        passes.push({
            name: "ValidateLengthOptsAccessRewrite(Final)",
            description: "Final rewrite of opts.* to Map.get(opts, :key) in validate_length",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ValidateLengthOptsAccessRewrite.rewritePass
        });
        // Broad normalization: convert opts.* inside any keyword list to Map.get(opts, :key)
        passes.push({
            name: "OptsKeywordMapGet(Final)",
            description: "Normalize opts.* in keyword lists to Map.get",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.OptsKeywordMapGetTransforms.transformPass
        });
        // Final SafePubSub alias injection
        passes.push({
            name: "SafePubSubAliasInject(Final)",
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
            name: "StringToAtomLiteral(Late)",
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
        passes.push({
            name: "UnusedLocalAssignmentUnderscore",
            description: "Prefix unused local assignment names with underscore in blocks",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.UnusedLocalAssignmentUnderscoreTransforms.transformPass
        });
        // Promote binders underscored earlier when body uses the base name
        passes.push({
            name: "LocalUnderscoreBinderPromote",
            description: "Rename EMatch(_name = ...) to name = ... when subsequent code uses name",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.LocalUnderscoreBinderPromoteTransforms.promotePass
        });
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

        // Normalize mixed-case variable references to existing snake_case bindings
        passes.push({
            name: "VarNameNormalization",
            description: "Normalize camelCase references to snake_case when a binding exists",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.VarNameNormalizationTransforms.varNameNormalizationPass
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
            name: "CasePatternTempAssignmentRemoval(Late)",
            description: "Final guard against `lhs = _g*` after pattern binding",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.casePatternTempAssignmentRemovalPass
        });

        // Final local reference fixes (run late to avoid being undone by later passes)
        passes.push({
            name: "LocalUnderscoreReferenceFallback(Late)",
            description: "Fallback renaming of EVar(name) -> EVar(_name) when only _name declared (late)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.LocalUnderscoreReferenceFallbackTransforms.fallbackUnderscoreReferenceFixPass
        });
        
        // Consolidated hygiene sweep (usage-driven), orchestrating core hygiene steps in order
        passes.push({
            name: "HygieneConsolidated(Late)",
            description: "Consolidated pass: params underscore, underscore fallback, used underscore promotion, ref/decl alignment, case binder hygiene",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.HygieneConsolidatedTransforms.pass
        });
        // Unify declarations and references to a canonical local name per base
        passes.push({
            name: "RefDeclAlignment",
            description: "Align declaration/reference spellings (underscore/numeric) to canonical name",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.RefDeclAlignmentTransforms.alignLocalsPass
        });
        passes.push({
            name: "StringToolsLocalFix(Late)",
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
            name: "UsedUnderscoreRename(Late)",
            description: "Rename _var to var when var is referenced (late stage)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.UnderscoreVarTransforms.removeUnderscoreFromUsedLocalsPass
        });

        // Final alignment after usage analysis may have prefixed underscores again
        passes.push({
            name: "RefDeclAlignment(Late)",
            description: "Final alignment of declarations and references to canonical names",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.RefDeclAlignmentTransforms.alignLocalsPass
        });

        // Late sweep: ensure any '!= nil' remaining are converted to not is_nil
        passes.push({
            name: "EqNilToIsNil(Late)",
            description: "Late replacement of (x != nil) with not Kernel.is_nil(x)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.eqNilToIsNilPass
        });
        // Drop stray numeric literals (final)
        passes.push({
            name: "DropStandaloneLiteralOne(Final)",
            description: "Final sweep to remove standalone numeric literals (1/0)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.DropStandaloneLiteralOneTransforms.dropPass
        });
        // Replace inline if assignments with discard (final)
        passes.push({
            name: "InlineIfAssignmentDiscard(Final)",
            description: "Final rewrite of inline if assignments to _ = expr",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.InlineIfAssignmentDiscardTransforms.fixPass
        });
        // Prune unused defp helpers at the very end
        passes.push({
            name: "UnusedDefpPrune(Final)",
            description: "Final pruning of unused private functions",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.UnusedDefpPrune.prunePass
        });
        // Ensure functions ending with assignment return the assigned variable
        passes.push({
            name: "AssignReturnInjection(Final)",
            description: "Append var as final expression when function ends with var = expr",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.AssignReturnInjectionTransforms.injectPass
        });
        // Absolute final sweep to drop stray numeric literals reintroduced by later passes
        passes.push({
            name: "DropStandaloneLiteralOne(AbsoluteFinal)",
            description: "Absolute final sweep to remove standalone numeric literals (1/0)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.DropStandaloneLiteralOneTransforms.dropPass
        });
        // Late simplification: fold is_nil(var) -> false when var provably non-nil literal
        passes.push({
            name: "SimplifyIsNilFalse(Late)",
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

        // Rewrite Phoenix.Presence.* calls to <App>Web.Presence.* where appropriate
        passes.push({
            name: "PresenceApiModuleRewrite",
            description: "Rewrite Phoenix.Presence.track/update/list/untrack to <App>Web.Presence.*",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.presenceApiModuleRewritePass
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
            description: "Collapse Enum.map(Map.keys(..), &Atom.to_string/1) to Map.keys(..) in Presence modules",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.PresenceHelpersTransforms.presenceHelpersNormalizationPass
        });
        // Presence ERaw normalization for Reflect.fields expansion
        passes.push({
            name: "PresenceERawNormalization",
            description: "Within Presence modules, collapse ERaw Map.keys |> Enum.map(&Atom.to_string/1) to Map.keys",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.PresenceERawTransforms.erawPresenceKeysNormalizePass
        });
        // Presence list-building reduce rewrite
        passes.push({
            name: "PresenceReduceRewrite",
            description: "Rewrite Presence Enum.each + Reflect.fields list construction to Enum.reduce(Map.values(map), [], ...) with conditional append",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.PresenceReduceRewriteTransforms.presenceReduceRewritePass
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
        // LiveView mount flow normalization to restore required binders
        passes.push({
            name: "LiveMountNormalize(UltraFinal)",
            description: "Normalize LiveView mount/3: promote discards to named binders and bind updated_socket",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.LiveMountNormalizeTransforms.pass
        });
        passes.push({
            name: "WildcardPromoteByUndeclaredUse(UltraFinal)",
            description: "Promote `_ = rhs` to named binder when a single undeclared var is used later",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.WildcardPromoteByUndeclaredUseTransforms.pass
        });
        // Final safety: inline [] for Supervisor.start_link(children, opts) in Telemetry modules
        passes.push({
            name: "SupervisorStartLinkChildrenInlineFix(UltraFinal)",
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

        // Module-local: prune private functions that are not referenced
        passes.push({
            name: "UnusedDefpPrune",
            description: "Drop defp helpers not referenced within module",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.UnusedDefpPrune.prunePass
        });
        
        // Late safety net: normalize String.to_atom/1 and to_existing_atom/1 to literals where safe
        passes.push({
            name: "StringToAtomLiteral(Late)",
            description: "Convert String.to_atom(\"field\") to :field when argument is a literal string",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.stringToAtomLiteralPass
        });

        // Qualify single-segment modules inside ERaw strings within <App>Web.* (run very late to catch late ERaw injections)
        passes.push({
            name: "ERawWebModuleQualification(Final)",
            description: "Qualify single-segment modules inside ERaw within Web modules (final)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.erawWebModuleQualificationPass
        });

        // Normalize ERaw validate_required lists, validate_length field argument, opts nil comparisons (run at the very end)
        passes.push({
            name: "ERawEctoValidateAtomNormalize(Final)",
            description: "Normalize ERaw validate_* atoms and opts nil comparisons (final)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EctoERawTransforms.erawEctoValidateAtomNormalizePass
        });
        // Normalize ERaw opts.* access in keyword lists to Map.get to avoid typing warnings
        passes.push({
            name: "ERawEctoOptsAccessNormalize(Final)",
            description: "Rewrite opts.* in ERaw keyword lists to Map.get(opts, :key)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EctoERawTransforms.erawEctoOptsAccessNormalizePass
        });
        // Rewrite ERaw Ecto.Queryable.to_query(:atom) to <App>.<CamelCase> (final sweep)
        passes.push({
            name: "ERawEctoQueryableToSchema(Final)",
            description: "Rewrite ERaw to_query(:atom) to schema module <App>.<Camel>",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EctoERawTransforms.erawEctoQueryableToSchemaPass
        });

        // Presence ERaw cleanup: remove constant-true if and trailing acc in reduce bodies
        passes.push({
            name: "PresenceERawCleanup(Final)",
            description: "Sanitize ERaw reduce bodies in Presence modules (drop if 1 and trailing acc)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.PresenceERawCleanupTransforms.transformPass
        });

        // Absolute last: ensure declarations and references agree after all prior rewrites
        passes.push({
            name: "RefDeclAlignment(Final)",
            description: "Absolute final alignment of local names to canonical spelling",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.RefDeclAlignmentTransforms.alignLocalsPass
        });
        // Align def/defp parameters with body usage before fixing underscored refs
        passes.push({
            name: "DefParamBinderAlignByBodyUse(Final)",
            description: "Promote underscored def params to base names when body uses base; rewrite body refs",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.DefParamBinderAlignByBodyUseTransforms.alignPass
        });
        // Final safety: fix references to underscored variants of function params
        passes.push({
            name: "DefParamUnderscoreRefFix(Final)",
            description: "Rewrite _param references to param when only param is declared",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.DefParamUnderscoreRefFixTransforms.fixPass
        });
        // Absolute sweep to ensure no stray numeric literals or bare increments remain anywhere
        passes.push({
            name: "ArithmeticIncrementCleanup(AbsoluteFinal)",
            description: "Final sweep: drop bare numeric literals and normalize increments",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ArithmeticIncrementTransforms.transformPass
        });
        passes.push({
            name: "ReduceWhileSentinelCleanup(AbsoluteFinal)",
            description: "Final sweep: drop numeric sentinels inside reduce_while bodies",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ReduceWhileSentinelCleanupTransforms.transformPass
        });
        passes.push({
            name: "DropStandaloneLiteralOne(UltraFinal)",
            description: "Ultra-final sweep to remove any bare numeric sentinels left by late injections",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.DropStandaloneLiteralOneTransforms.dropPass
        });

        // Simplify if-branches with constant conditions (true/false/1/0)
        passes.push({
            name: "IfConstSimplify(Final)",
            description: "Simplify if true/1 and if false/0 conditionals",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.IfConstSimplifyTransforms.transformPass
        });

        // Absolute late sweep: ensure HEEx raw(content) uses assigns and assigns has :content
        passes.push({
            name: "HeexAssignsCapture(Final)",
            description: "Ensure @content usage inside ~H and assign content into assigns",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.HeexAssignsCaptureTransforms.transformPass
        });
        
        // Late safety net: re-run Repo qualification after all transformations
        passes.push({
            name: "RepoQualification(Late)",
            description: "Re-run Repo qualification to catch any bare Repo.* introduced by prior passes; shape-derived from <App>Web.*",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.repoQualificationPass
        });

        // Global Repo qualification (non-Web modules) using -D app_name define
        passes.push({
            name: "RepoQualification(Global)",
            description: "Qualify bare Repo.* to <App>.Repo.* in all modules based on app_name define",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.globalRepoQualificationPass
        });

        // Global Repo alias injection for any module that references Repo.*
        passes.push({
            name: "RepoAliasInjection(Global)",
            description: "Inject alias <App>.Repo as Repo in any module referencing Repo.*",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.repoAliasInjectionGlobalPass
        });

        // Late alias injection to ensure Repo alias exists when used
        passes.push({
            name: "RepoAliasInjection(Late)",
            description: "Inject alias <App>.Repo as Repo in Web modules if Repo.* is referenced",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.repoAliasInjectionPass
        });

        // Absolute final binder promotion: ensure _name -> name when name is referenced later
        passes.push({
            name: "LocalUnderscoreBinderPromote(Final)",
            description: "Final promotion of local binders _name to name when body references name",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.LocalUnderscoreBinderPromoteTransforms.promotePass
        });

        // Phoenix-scoped hygiene: underscore unused def/defp parameters in Web/Live/Presence modules
        passes.push({
            name: "DefParamUnusedUnderscore(Phoenix)",
            description: "Prefix unused function parameters with underscore in Phoenix Web/Live/Presence modules",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.DefParamUnusedUnderscoreTransforms.transformPass
        });

        // Run parameter underscore cleanup again late to catch usage removed by prior passes
        passes.push({
            name: "DefParamUnusedUnderscore(Phoenix Final)",
            description: "Late sweep: underscore unused def/defp params in Phoenix modules",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.DefParamUnusedUnderscoreTransforms.transformPass
        });

        // Final safety: rename references name -> _name when only underscored binder exists
        passes.push({
            name: "LocalUnderscoreReferenceFallback(Final)",
            description: "Fallback renaming of EVar(name) -> EVar(_name) when only _name declared (final)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.LocalUnderscoreReferenceFallbackTransforms.fallbackUnderscoreReferenceFixPass
        });
        // Ultra-final Phoenix sweeps: underscore unused case binders and params
        passes.push({
            name: "ClauseUnusedBinderUnderscore(Phoenix UltraFinal)",
            description: "Ultra-final underscore of unused case binders in Phoenix modules",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ClauseUnusedBinderUnderscoreTransforms.clauseUnusedBinderUnderscorePass
        });
        passes.push({
            name: "DefParamUnusedUnderscore(Phoenix UltraFinal)",
            description: "Ultra-final underscore of unused def/defp params in Web/Live/Presence",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.DefParamUnusedUnderscoreTransforms.transformPass
        });
        // Final: discard top-level nil assignments in function bodies when unused
        passes.push({
            name: "TopLevelNilAssignDiscard(Final)",
            description: "Rewrite var = nil to _ = nil when var is not used later in function",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.TopLevelNilAssignDiscardTransforms.transformPass
        });
        // Absolutely last: promote underscore binders by use one more time
        passes.push({
            name: "CaseUnderscoreBinderPromoteByUse(Absolute)",
            description: "Absolute sweep: promote _name binders when body uses name",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseUnderscoreBinderPromoteByUseTransforms.transformPass
        });
        // Absolutely last: unify {:ok, var} success var references in clause body
        passes.push({
            name: "CaseSuccessVarUnifier(Absolute)",
            description: "Absolute sweep: replace undefined refs in {:ok, var} clause bodies with var",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseSuccessVarUnifier.unifySuccessVarPass
        });
        // Extra absolute: promote underscore binders {:ok,_x} -> {:ok,x} when body references x
        passes.push({
            name: "CaseSuccessVarUnify(Absolute2)",
            description: "Promote {:ok, _x} binder to {:ok, x} when body references x (extra absolute)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseSuccessVarUnifyTransforms.transformPass
        });
        // (Moved to absolute end): Success binder/var alignment passes run at the end of pipeline
        // Absolute: rerun Enum.each sentinel cleanup after all earlier rewrites
        passes.push({
            name: "EnumEachSentinelCleanup(Absolute)",
            description: "Absolute sweep: drop bare numeric sentinels in Enum.each fn bodies",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.MapAndCollectionTransforms.enumEachSentinelCleanupPass
        });
        // Ultra-final: promote underscored case binders to base name when body uses base name
        passes.push({
            name: "CaseUnderscoreBinderPromoteByUse(UltraFinal)",
            description: "Promote _name -> name in case patterns when body uses name (ultra-final)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseUnderscoreBinderPromoteByUseTransforms.transformPass
        });
        // Ultra-final: unify success vars in {:ok, v} branches again to harmonize with late renames
        passes.push({
            name: "CaseSuccessVarUnifier(UltraFinal)",
            description: "Ultra-final unification of success var in {:ok, v} clauses",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseSuccessVarUnifier.unifySuccessVarPass
        });
        // Absolute-final: ensure query binder promotion inside search-guarded EIf branches
        passes.push({
            name: "QueryBinderFinalization(AbsoluteFinal)",
            description: "Promote `_ = String.downcase(search_query)` to `query = ...` in guarded then-branches when Enum.filter appears later",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.QueryBinderFinalizationTransforms.transformPass
        });
        // Discard unused assignments inside closures (EFn clause bodies)
        passes.push({
            name: "ClosureUnusedAssignmentDiscard(Final)",
            description: "Rewrite var = expr to _ = expr in EFn bodies when var unused later",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ClosureUnusedAssignmentDiscardTransforms.discardPass
        });

        // Late re-qualification of application modules in Web contexts to catch newly
        // introduced calls by previous passes (shape-derived; avoids registry dependency)
        passes.push({
            name: "ModuleQualification(Late)",
            description: "Re-run Web-context <App>.Module qualification after later transforms",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.moduleQualificationPass
        });
        // Absolute final sweep: ensure Web EFns contain qualified application module calls
        passes.push({
            name: "WebEFnModuleQualification(Final)",
            description: "Final sweep to qualify single-segment modules inside <App>Web.* EFn bodies",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.webEFnModuleQualificationPass
        });
        // Targeted final pass to ensure Enum.reduce_while bodies are qualified in Web modules
        passes.push({
            name: "WebReduceWhileEFnQualification(Final)",
            description: "Explicitly qualify single-segment modules inside Enum.reduce_while EFns in <App>Web.*",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.webReduceWhileEFnQualificationPass
        });
        passes.push({
            name: "SelfAssignCompression(Final)",
            description: "Compress duplicated self-assignments x = x = expr to x = expr",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.selfAssignCompressionPass
        });
        passes.push({
            name: "AssignChainPrune(Final)",
            description: "Prune unused binders in chain assignments and drop var=nil when unused",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.AssignChainPruneTransforms.prunePass
        });
        passes.push({
            name: "AssignChainGenericSimplify(Final)",
            description: "Simplify nested match chains by dropping unused side (generic)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.AssignChainGenericSimplifyTransforms.simplifyPass
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

        // Robust sweep: inline when raw(content) pattern wasn't caught by structural match
        passes.push({
            name: "HeexAssignsCapture",
            description: "Replace ~H raw(content) with literal html and drop local var",
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
            name: "EnumEachSentinelCleanup(Final)",
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
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.MapAndCollectionTransforms.mapJoinRewritePass
        });
        // Presence reduce rewrite (early) to catch Presence.list scans before generic rewrites
        passes.push({
            name: "PresenceReduceRewrite(Early)",
            description: "Rewrite Presence Enum.each + Reflect.fields to Enum.reduce(Map.values(map), [], ...) with conditional append (early)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.PresenceReduceRewriteTransforms.presenceReduceRewritePass
        });
        passes.push({
            name: "MapConcatEachToMapAssign",
            description: "Rewrite temp=[], Enum.each(... temp=Enum.concat(temp,[expr]) ...) → temp = Enum.map(list, fn -> expr) end",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.MapAndCollectionTransforms.mapConcatEachToMapAssignPass
        });
        passes.push({
            name: "ConcatEachToReduce",
            description: "Rewrite temp=[], Enum.each(... if cond do temp=concat(temp,[expr]) end ...) → Enum.reduce(list, [], ...)",
            enabled: true,
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
        // Unify success var names when body references non-underscore variant
        passes.push({
            name: "CaseSuccessVarUnify",
            description: "Rename {:ok, _x} -> {:ok, x} when body references x",
            enabled: true,
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
            name: "AnonFnArgBinderFix(Final)",
            description: "Rename underscored fn binders and body references when used (no ERaw rewrites)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.AnonFnArgBinderFixTransforms.fixPass
        });
        passes.push({
            name: "FnArgBodyRefNormalize(Final)",
            description: "Normalize body refs _name -> name after late binder fixes",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.MapAndCollectionTransforms.fnArgBodyRefNormalizePass
        });
        passes.push({
            name: "EFnArgCleanup(Final)",
            description: "Final cleanup of EFn arg/body underscore mismatches",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EFnArgCleanupTransforms.cleanupPass
        });
        passes.push({
            name: "EFnScopedUnderscoreRefCleanup(Final)",
            description: "Rewrite _name -> name in EFn bodies when a matching binder exists",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EFnScopedUnderscoreRefCleanup.cleanupPass
        });
        // Align single-arg anonymous fn bodies to their binder when exactly one undefined var exists
        passes.push({
            name: "EFnSingleArgUndefinedAlign(Final)",
            description: "Rewrite single free var in 1-arg EFn body to binder (shape-based, no coupling)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EFnSingleArgUndefinedAlignTransforms.alignPass
        });
        passes.push({
            name: "EFnNumericSentinelCleanup(Final)",
            description: "Drop EInteger(0|1) and EFloat(0.0) statements in EFn bodies",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EFnNumericSentinelCleanupTransforms.cleanupPass
        });
        // Underscore unused anonymous fn args for Enum.each/map/reduce patterns
        passes.push({
            name: "EFnUnusedArgUnderscore(Final2)",
            description: "Prefix unused EFn binders with underscore to avoid warnings",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EFnUnusedArgUnderscoreTransforms.transformPass
        });
        passes.push({
            name: "EFnLocalAssignDiscard(Final)",
            description: "Replace unused local rebinds in EFn bodies with wildcard assignment",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EFnLocalAssignDiscardTransforms.discardPass
        });
        // Final binder/reference alignment in EFn to prevent _arg vs arg mismatches
        passes.push({
            name: "EFnBinderReferenceAlign(Final2)",
            description: "Align EFn binders with body references: _name -> name when binder exists",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EFnBinderReferenceAlignTransforms.fixPass
        });
        // Run def/defp binder alignment late to catch newly synthesized modules/functions
        passes.push({
            name: "DefParamBinderAlignByBodyUse(UltraFinal)",
            description: "Late promotion of underscored def params to base names when body uses base",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.DefParamBinderAlignByBodyUseTransforms.alignPass
        });
        // Repair `query` binder name after early hygiene when later filter uses it
        passes.push({
            name: "QueryBinderRescue(Late)",
            description: "Rename _query/_ = downcase to query = downcase when later Enum.filter uses query",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.QueryBinderRescueTransforms.transformPass
        });
        // Promote `_ = String.downcase(search_query)` preceding Enum.filter(...) that uses `query` to a named binder
        passes.push({
            name: "PromoteQueryFromWildcard",
            description: "Promote wildcard downcase to `query = String.downcase(search_query)` when next filter uses `query`",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.PromoteQueryFromWildcardTransforms.pass
        });
        // Consolidate query handling after EFn arg/body normalizations so predicate shapes are stable
        passes.push({
            name: "FilterQueryConsolidate",
            description: "Ensure `query` availability: promote `_ = String.downcase(search_query)` or bind/inline deterministically",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.FilterQueryConsolidateTransforms.pass
        });
        // Normalize Phoenix assign/2 map argument by inlining preceding literal map
        // Removed to avoid app-specific coupling; rely on hygiene hardening instead
        // Simplify chained assignments in def/defp when inner var is unused later in block
        passes.push({
            name: "BlockAssignChainSimplify(Final)",
            description: "Rewrite outer = inner = expr → outer = expr when inner is unused later in function block",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.FunctionHygieneTransforms.blockAssignChainSimplifyPass
        });
        // Late sanitation of reduce bodies after most rewrites
        passes.push({
            name: "ReduceBodySanitize(Final)",
            description: "Fix head extraction and accumulator rebinds inside Enum.reduce bodies; drop stray arithmetic (late)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ReduceBodySanitizeTransforms.transformPass
        });
        // Drop top-level numeric sentinel literals in function bodies
        passes.push({
            name: "FunctionTopLevelSentinelCleanup(Final)",
            description: "Remove bare 1/0/0.0 statements at top-level in def/defp bodies",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.FunctionHygieneTransforms.functionTopLevelSentinelCleanupPass
        });
        passes.push({
            name: "TupleLhsDiscard(Final)",
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
            name: "EctoQueryRequireInjection(Final)",
            description: "Final sweep to inject `require Ecto.Query` in modules using Ecto.Query macros",
            enabled: true,
            pass: reflaxe.elixir.ast.ElixirASTTransformer.alias_ectoQueryRequirePass
        });
        // Absolute-final ensure for Ecto.Query require after any late rewrites
        passes.push({
            name: "EctoQueryRequireEnsure(AbsoluteFinal2)",
            description: "Ensure `require Ecto.Query` when Ecto.Query remote macros are present",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EctoQueryRequireEnsureTransforms.transformPass
        });

        // Absolute success-case alignment: must run as the very last shape-affecting passes
        // Align success binder to the single undefined var used in body (usage-driven, shape-based)
        passes.push({
            name: "SuccessBinderAlignByBodyUse(Absolute)",
            description: "Rename {:ok, binder} binder to the single undefined var used in body, if unambiguous",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.SuccessBinderAlignByBodyUseTransforms.alignPass
        });
        // Final safety: replace undefined lowercase refs in {:ok, binder} clause bodies with binder
        passes.push({
            name: "SuccessVarAbsoluteReplaceUndefined(Absolute)",
            description: "Final safety: replace any undefined lower-case var in {:ok, binder} clause body with binder",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.SuccessVarAbsoluteReplaceUndefinedTransforms.replacePass
        });

        // Final reducer alias normalization (absolute end): fix lingering alias concat -> acc concat and unify aliases
        passes.push({
            name: "ReduceAliasConcatToAcc(Absolute)",
            description: "Normalize alias-based accumulator concat to canonical acc concat inside Enum.reduce (absolute)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ReduceAliasConcatToAccTransforms.transformPass
        });
        passes.push({
            name: "ReduceAccAliasUnify(Absolute)",
            description: "Unify reduce accumulator alias to acc across reducer body (absolute)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ReduceAccAliasUnifyTransforms.unifyPass
        });
        // Unified structural canonicalization (non-destructive alongside existing passes)
        passes.push({
            name: "ReduceCanonicalize(Absolute)",
            description: "Canonicalize alias self-append and head extraction within two-arg reducers",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ReduceCanonicalize.pass
        });
        passes.push({
            name: "EFnAliasConcatToAcc(Absolute)",
            description: "Normalize alias concat -> acc concat inside any two-arg anonymous function (safety net)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EFnAliasConcatToAccTransforms.transformPass
        });
        passes.push({
            name: "ReduceAppendCanonicalize(Absolute)",
            description: "Canonicalize append inside Enum.reduce: alias concat -> acc concat; alias element -> binder",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ReduceAppendCanonicalizeTransforms.transformPass
        });

        // Ultra-final guard: ensure any lingering alias self-append inside two-arg anonymous functions
        // are rewritten to canonical acc = Enum.concat(acc, list)
        passes.push({
            name: "AccAliasLateRewrite(UltraFinal)",
            description: "Rewrite alias self-append to acc within any two-arg EFn (ultra-final safety)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.AccAliasLateRewriteTransforms.transformPass
        });

        // Ultra-final strict reduce fixer: if a reduce body still contains alias self-append,
        // rebuild it to canonical acc concat + acc return (structural, name-agnostic)
        passes.push({
            name: "ReduceStrictSelfAppendRewrite(UltraFinal)",
            description: "Rebuild reduce body to acc concat when alias self-append detected (structural)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ReduceStrictSelfAppendRewriteTransforms.transformPass
        });

        // ERaw reduce canonicalization: normalize alias concat and binder alias inside ERaw reduce bodies
        passes.push({
            name: "ReduceERawAliasCanonicalize(UltraFinal)",
            description: "Canonicalize alias concat and binder alias inside ERaw Enum.reduce bodies (ultra-final)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ReduceERawAliasCanonicalizeTransforms.transformPass
        });

        // Ultra-final hygiene: underscore case binders immediately rebound before any use
        passes.push({
            name: "CaseBinderRebindUnderscore(UltraFinal)",
            description: "In case arms, underscore binders that are immediately rebound before use",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.CaseBinderRebindUnderscoreTransforms.pass
        });

        // Ultra-final numeric sentinel dropper to ensure removal after late rewrites
        passes.push({
            name: "DropStandaloneLiteralOne(UltraFinal)",
            description: "Drop stray 1/0/0.0 literals in blocks, do-blocks, EFn bodies (ultra-final)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.DropStandaloneLiteralOneTransforms.dropPass
        });
        passes.push({
            name: "DropTempNilAssign(UltraFinal)",
            description: "Drop thisN/_thisN = nil sentinel assignments",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.DropTempNilAssignTransforms.pass
        });
        // Ultra-final again: underscore unused reduce results, then drop any reintroduced temp nil assigns
        passes.push({
            name: "ReduceResultUnusedUnderscore(AbsoluteFinal)",
            description: "Underscore binders in reduce/reduce_while result match when unused later in block",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ReduceResultUnusedUnderscoreTransforms.transformPass
        });
        passes.push({
            name: "ReduceWhileSentinelCleanup(AbsoluteFinal2)",
            description: "Final sweep: drop numeric sentinel literals inside reduce_while bodies",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ReduceWhileSentinelCleanupTransforms.transformPass
        });
        passes.push({
            name: "DropTempNilAssign(AbsoluteFinal2)",
            description: "Last guard: drop thisN/_thisN = nil sentinels if any got reintroduced",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.DropTempNilAssignTransforms.pass
        });
        passes.push({
            name: "LocalAssignUnderscoreLate(UltraFinal)",
            description: "Underscore local assigns when unused later; also nested inner assigns",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.LocalAssignUnderscoreLateTransforms.pass
        });
        // Consolidation removed legacy query guards; see FilterQueryConsolidate
        passes.push({
            name: "EFnTempChainSimplify(UltraFinal)",
            description: "Inside EFn, rewrite var=nil; var=expr; var → expr",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EFnTempChainSimplifyTransforms.pass
        });
        passes.push({
            name: "TrailingTempReturnSimplify(UltraFinal)",
            description: "Replace trailing temp returns with the rhs expression",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.TrailingTempReturnSimplifyTransforms.pass
        });
        passes.push({
            name: "NestedAssignCollapseGlobal(UltraFinal)",
            description: "Collapse nested chain assignments outer=(inner=expr) → outer=expr",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.NestedAssignCollapseGlobalTransforms.pass
        });
        passes.push({
            name: "DefTrailingAssignedVarReturn(UltraFinal)",
            description: "Append trailing var when last statement is assignment to non-temp",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.DefTrailingAssignedVarReturnTransforms.pass
        });
        passes.push({
            name: "EctoChangesetReturnFix(UltraFinal)",
            description: "Ensure changeset/2 returns cs at the end",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EctoChangesetReturnFixTransforms.pass
        });
        passes.push({
            name: "ChangesetChainCleanup(UltraFinal)",
            description: "Collapse changeset nested assigns cs/thisN → direct cs assign",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ChangesetChainCleanupTransforms.pass
        });
        // Ultra-late: synthesize missing `query` binder before Enum.filter when predicate uses `query`
        // and earlier promotion/insertion did not occur due to block segmentation or ERaw
        passes.push({
            name: "QueryBinderSynthesisLate(UltraFinal)",
            description: "Insert `query = String.downcase(search_query)` before Enum.filter when predicate uses `query` and no prior binder exists",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.QueryBinderSynthesisLateTransforms.transformPass
        });
        // Inline query inside filter predicates (absolute final fallback)
        passes.push({
            name: "FilterPredicateInlineQuery(AbsoluteFinal)",
            description: "Inline `query` to `String.downcase(search_query)` inside Enum.filter predicates",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.FilterPredicateInlineQueryTransforms.transformPass
        });
        passes.push({
            name: "BlockUnusedAssignmentDiscard(UltraFinal)",
            description: "Rewrite var = expr to _ = expr in function bodies when var unused later",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BlockUnusedAssignmentDiscardTransforms.pass
        });
        // Drop stray `_ = String.downcase(search_query)`
        passes.push({
            name: "DropUnusedDowncaseWildcardAssign(AbsoluteFinal)",
            description: "Drop `_ = String.downcase(search_query)` in blocks (pure, unused)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.DropUnusedDowncaseWildcardAssignTransforms.transformPass
        });
        passes.push({
            name: "ChangesetEnsureReturn(UltraFinal)",
            description: "Ensure functions building Ecto.Changeset return last assigned var",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ChangesetEnsureReturnTransforms.pass
        });
        passes.push({
            name: "TempAssignFlattenGlobal(UltraFinal)",
            description: "Flatten temp alias chains globally: outer=(temp=expr) → outer=expr",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.TempAssignFlattenGlobalTransforms.pass
        });
        passes.push({
            name: "DefParamUnusedUnderscoreSafe(UltraFinal)",
            description: "Underscore unused def parameters when truly unused (safe)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.DefParamUnusedUnderscoreSafeTransforms.pass
        });
        passes.push({
            name: "ApplicationEnsureStartLink(UltraFinal)",
            description: "Ensure Application.start/2 appends Supervisor.start_link(children, opts) (ultra final)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ApplicationEnsureStartLinkTransforms.transformPass
        });

        // Absolute final: promote `_ = rhs` to named binder using targeted usage detection
        // WHY: Some late hygiene passes may discard necessary binders; restore them at the end
        // SCOPE: Live modules and helpers; shape/usage-based, Phoenix-idiomatic only
        passes.push({
            name: "WildcardPromoteByUndeclaredUse(AbsoluteFinal)",
            description: "Final promotion of `_ = rhs` to binder by targeted usage (length/assign/DateTime)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.WildcardPromoteByUndeclaredUseTransforms.pass
        });

        // Post-absolute finalization: enforce `query` binder for downcase(search_query)
        // after all promotions to avoid late wildcard promotions picking the wrong name.
        passes.push({
            name: "QueryBinderFinalization(Post)",
            description: "Enforce `query = String.downcase(search_query)` at the very end when a different binder name slipped through",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.QueryBinderFinalizationTransforms.transformPass
        });

        passes.push({
            name: "DropResidualWildcardDowncase(Post2)",
            description: "Drop stray `_ = String.downcase(search_query)` after establishing `query` binder (post-final)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.DropResidualWildcardDowncasePostTransforms.transformPass
        });

        // Post3: remove immediate duplicate downcase after query binder
        passes.push({
            name: "RemoveDuplicateDowncaseAfterQuery(Post3)",
            description: "If `query = downcase(...)` is immediately followed by `_ = downcase(...)`, drop the wildcard line",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.RemoveDuplicateDowncaseAfterQueryPostTransforms.transformPass
        });

        // UltraFinal2: As a last step, ensure changeset/2 binders match Ecto.Changeset usages
        passes.push({
            name: "EctoSchemaBinderFix(UltraFinal2)",
            description: "Infer changeset/2 parameter names from Ecto.Changeset.change/cast shapes and drop underscores",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EctoSchemaBinderFixTransforms.transformPass
        });

        // Return only enabled passes
        return passes.filter(p -> p.enabled);
    
    }
}
#end
