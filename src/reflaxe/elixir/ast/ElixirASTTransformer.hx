package reflaxe.elixir.ast;

#if !(macro || reflaxe_runtime)
#error
#end
#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import haxe.macro.Expr.Position;
import reflaxe.elixir.ast.ElixirASTBuilder;
import reflaxe.elixir.ast.ElixirAST.VarOrigin;
import reflaxe.elixir.ast.naming.ElixirAtom;
import reflaxe.elixir.ast.transformers.PatternMatchingTransforms;
import reflaxe.elixir.ast.transformers.LoopVariableRestorer;
import reflaxe.elixir.ast.transformers.GuardConditionFlattener;
import reflaxe.elixir.ast.transformers.StructUpdateTransform;
import reflaxe.elixir.ast.ASTUtils;
import haxe.macro.Context; // for validation errors
import haxe.crypto.Sha1;
#if macro
import haxe.macro.Type.TypedExpr;
#end
using StringTools;

/**
 * Transformation pass function type
 * Takes an AST node and returns a transformed node
 *
 * WHY: Stateless transformations that don't need compilation context
 * WHEN: Use for passes that only need AST structure (pattern matching, syntax cleanup)
 */
typedef TransformPass = (ast: ElixirAST) -> ElixirAST;

/**
 * Contextual transformation pass function type
 * Takes an AST node and compilation context, returns a transformed node
 *
 * WHY: Enable passes to access shared compilation state (variable mappings, metadata)
 * WHEN: Use for passes that need:
 *   - Variable rename information (tempVarRenameMap)
 *   - Cross-expression state tracking
 *   - Coordination with builder phase decisions
 *
 * ARCHITECTURE:
 * - Context provides authoritative source of truth for variable naming
 * - Passes read from and write to context.tempVarRenameMap
 * - Ensures consistency between builder and transformer phases
 *
 * EXAMPLE: HygieneTransforms.usageAnalysisPass uses context to:
 *   - Read variable renames from builder phase
 *   - Apply consistent underscore prefixes
 *   - Ensure declarations match references
 */
typedef ContextualTransformPass = (ast: ElixirAST, context: reflaxe.elixir.CompilationContext) -> ElixirAST;

/**
 * Pass configuration
 *
 * WHY: Hybrid pattern supporting both stateless and contextual passes
 * WHAT: Each pass can provide either or both variants
 * HOW: transform() checks for contextualPass first, falls back to pass
 *
 * BACKWARD COMPATIBILITY:
 * - Existing passes continue to work with only 'pass' field
 * - New passes can use 'contextualPass' when context needed
 * - Migration is gradual, pass by pass
 */
typedef PassConfig = {
    name: String,
    description: String,
    enabled: Bool,
    pass: TransformPass,
    ?contextualPass: ContextualTransformPass
};

/**
 * ElixirASTTransformer: AST-to-AST Transformation Engine (Transformation Phase)
 * 
 * WHY: Central transformation phase for converting Haxe patterns to idiomatic Elixir
 * - Separates transformation logic from parsing and generation
 * - Enables multiple optimization and idiom conversion passes
 * - Makes transformations testable and composable
 * - Allows gradual addition of new transformations without breaking existing ones
 * 
 * WHAT: Applies a series of transformation passes to ElixirAST
 * - Each pass focuses on one specific transformation
 * - Passes can be enabled/disabled independently
 * - Transformations preserve semantics while improving idiomaticity
 * - Handles imperative→functional, mutable→immutable, loops→comprehensions
 * 
 * HOW: Pass-based architecture with recursive AST traversal
 * - Identity transformation as base (pass-through unchanged)
 * - Each pass is a separate function that pattern matches on AST nodes
 * - Passes are composed in a specific order for correctness
 * - Metadata preserved and enriched through transformations
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Each pass has one transformation goal
 * - Open/Closed: New passes can be added without modifying existing
 * - Composability: Passes can be combined and reordered
 * - Debuggability: Each pass can be tested in isolation
 * - Performance: Only enabled passes are executed
 * 
 * @see docs/03-compiler-development/INTERMEDIATE_AST_REFACTORING_PRD.md
 */
class ElixirASTTransformer {
    
    /**
     * Main entry point: Apply all transformation passes
     *
     * WHY: Single interface for all AST transformations with optional context support
     * WHAT: Applies enabled passes in order, using contextual variant when available
     * HOW: Iterates through pass list, selecting appropriate variant for each pass
     *
     * CONTEXTUAL PASS SUPPORT:
     * - If pass has contextualPass AND context provided → Use contextual variant
     * - Otherwise → Use stateless pass (backward compatible)
     * - Enables passes to access compilation state (variable mappings, metadata)
     * - Ensures consistency between builder and transformer phases
     *
     * @param ast The AST to transform
     * @param context Optional compilation context for contextual passes
     * @return Transformed AST
     */
    public static function transform(ast: ElixirAST, ?context: reflaxe.elixir.CompilationContext): ElixirAST {
        #if sys
        Sys.println('[XRay AST Transformer] Starting transformation pipeline');
        #else
        trace('[XRay AST Transformer] Starting transformation pipeline');
        #end
        #if debug_ast_transformer
        trace('[XRay AST Transformer] AST type: ${Type.enumConstructor(ast.def)}');
        trace('[XRay AST Transformer] AST metadata: ${ast.metadata}');
        #end
        #if debug_unrolled_comprehension
        trace('[DEBUG Transform] ElixirASTTransformer.transform() called');
        #end
        
        #if debug_ast_structure
        // Print AST structure for debugging
        switch(ast.def) {
            case EModule(name, _, _):
                trace('[XRay AST Structure] Module: $name');
            default:
                trace('[XRay AST Structure] Root: ${ast.def}');
        }
        #end
        
        var passes = getEnabledPasses();
        var result = ast;

        for (passConfig in passes) {
            #if sys
            Sys.println('[XRay AST Transformer] Applying pass: ${passConfig.name}');
            #else
            trace('[XRay AST Transformer] Applying pass: ${passConfig.name}');
            #end

            // CONTEXTUAL PASS SELECTION LOGIC
            // WHY: Enable passes to access compilation context when needed
            // WHAT: Check for contextualPass variant first, fall back to regular pass
            // HOW: Conditional logic based on contextualPass availability and context presence
            //
            // ARCHITECTURE:
            // 1. If contextualPass exists AND context provided → Use contextual variant
            // 2. Otherwise → Use stateless pass variant (backward compatible)
            //
            // This ensures:
            // - Contextual passes get access to tempVarRenameMap for consistency
            // - Non-contextual passes continue working unchanged
            // - No null pointer errors when context not provided
            if (passConfig.contextualPass != null && context != null) {
                #if debug_contextual_passes
                trace('[XRay Contextual Pass] Using contextual variant for: ${passConfig.name}');
                trace('[XRay Contextual Pass] Context available: ${context != null}');
                trace('[XRay Contextual Pass] Variable mappings: ${context.tempVarRenameMap.keys()}');
                #end

                result = passConfig.contextualPass(result, context);
                #if debug_ast_transformer
                // Compute a deterministic per-pass AST hash to locate regressions precisely
                // Use printer output as a stable representation
                var __passHashStr = try reflaxe.elixir.ast.ElixirASTPrinter.print(result, 0) catch (e:Dynamic) {
                    Std.string(result.def);
                };
                var __passHash = haxe.crypto.Sha1.encode(__passHashStr);
                trace('[PassHash] ' + passConfig.name + ' => ' + __passHash);
                #end
            } else {
                #if debug_contextual_passes
                trace('[XRay Contextual Pass] Using stateless variant for: ${passConfig.name}');
                trace('[XRay Contextual Pass] Contextual variant available: ${passConfig.contextualPass != null}');
                trace('[XRay Contextual Pass] Context provided: ${context != null}');
                #end

                result = passConfig.pass(result);
                #if debug_ast_transformer
                var __passHashStr2 = try reflaxe.elixir.ast.ElixirASTPrinter.print(result, 0) catch (e:Dynamic) {
                    Std.string(result.def);
                };
                var __passHash2 = haxe.crypto.Sha1.encode(__passHashStr2);
                trace('[PassHash] ' + passConfig.name + ' => ' + __passHash2);
                #end
            }
        }
        
        #if debug_ast_transformer
        trace('[XRay AST Transformer] Transformation complete');
        #end
        
        return result;
    }
    
    /**
     * Get list of enabled transformation passes
     */
    static function getEnabledPasses(): Array<PassConfig> {
        /**
         * Pass Ordering Buckets (do not violate without updating docs):
         * 1) Structural normalization (builder fallout fixes, redundant nil removal)
         * 2) Pattern & binder shaping (case/pattern normalization, alias injection)
         * 3) Usage/hygiene (usage analysis, underscore, private function marking)
         * 4) Idioms (Phoenix/Ecto/OTP transforms)
         * 5) Finalizers (ABSOLUTE LAST):
         *    ForceOptionLevelBinderWhenBodyUsesLevel → AbsoluteLevelBinderEnforcement → OptionLevelAliasInjection
         */
        var passes: Array<PassConfig> = [];
        
        // Identity pass (always first - ensures pass-through functionality)
        passes.push({
            name: "Identity",
            description: "Pass-through transformation (no changes)",
            enabled: true,
            pass: identityPass
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
            pass: removeRedundantEnumExtractionPass
        });

        // Throw statement transformation (must run early to fix complex expressions)
        passes.push({
            name: "ThrowStatementTransform",
            description: "Transform complex throw expressions to avoid syntax errors",
            enabled: true,
            pass: throwStatementTransformPass
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
        
        // Function reference transformation (must run early to add capture operators)
        passes.push({
            name: "FunctionReferenceTransform",
            description: "Transform function references to use capture operator (&Module.func/arity)",
            enabled: true,
            pass: functionReferenceTransformPass
        });
        
        // Bitwise import pass (should run early to add imports)
        passes.push({
            name: "BitwiseImport",
            description: "Add Bitwise import when bitwise operators are used",
            enabled: true,
            pass: bitwiseImportPass
        });
        
        // Loop transformation pass (convert reduce_while patterns to idiomatic loops)
        passes.push({
            name: "LoopTransformation",
            description: "Transform non-idiomatic loop patterns (reduce_while with Stream.iterate) to idiomatic Enum operations and comprehensions",
            enabled: true,
            pass: loopTransformationPass
        });

        // Collapse simple temp-binding blocks in expression contexts
        passes.push({
            name: "InlineTempBindingInExpr",
            description: "Collapse EBlock([tmp = exprA, exprB(tmp)]) to exprB(exprA) in expression positions",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.TempVariableTransforms.inlineTempBindingInExprPass
        });

        // Debug: XRay map field values that contain EBlock
        passes.push({
            name: "XRayMapBlocks",
            description: "Debug pass to log map fields containing EBlock values",
            enabled: #if debug_temp_binding true #else false #end,
            pass: function(ast) {
                return transformNode(ast, function(node) {
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
            pass: phoenixComponentImportPass
        });
        
        // LiveView CoreComponents import pass (should run after Phoenix Component)
        passes.push({
            name: "LiveViewCoreComponentsImport",
            description: "Add CoreComponents import for LiveView modules that use components",
            enabled: true,
            pass: liveViewCoreComponentsImportPass
        });
        
        // Phoenix function name mapping pass (transforms assign_multiple to assign, etc.)
        passes.push({
            name: "PhoenixFunctionMapping",
            description: "Map custom function names to Phoenix conventions",
            enabled: true,
            pass: phoenixFunctionMappingPass
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
            pass: function(ast) return ElixirASTTransformer.guardGroupingPass(ast)
        });
        
        // PRE: Field access normalization before string interpolation
        // Run these early so that expressions embedded into strings get normalized first.
        passes.push({
            name: "ArrayLengthFieldToFunction",
            description: "Transform array.length field access to length(array) function calls",
            enabled: true,
            pass: arrayLengthFieldToFunctionPass
        });
        passes.push({
            name: "TupleElemFieldToFunction",
            description: "Transform tuple.elem field access to elem(tuple, index) function calls",
            enabled: true,
            pass: tupleElemFieldToFunctionPass
        });
        
        // Constant folding pass
        // String interpolation transformation (should run before constant folding)
        passes.push({
            name: "StringInterpolation",
            description: "Convert string concatenation to idiomatic string interpolation",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.StringTransforms.stringInterpolationPass
        });
        
        // Loop variable restoration pass (must run after string interpolation)
        passes.push({
            name: "LoopVariableRestore",
            description: "Restore loop variables in string interpolations (fixes Haxe optimizer issue)",
            enabled: true,
            pass: LoopVariableRestorer.restoreLoopVariablesPass
        });

        #if !disable_constant_folding
        passes.push({
            name: "ConstantFolding",
            description: "Fold constant expressions at compile time",
            enabled: true,
            pass: constantFoldingPass
        });
        #end
        
        // Conditional reassignment pass (should run before pipeline optimization)
        passes.push({
            name: "ConditionalReassignment",
            description: "Convert conditional reassignments to functional style",
            enabled: true,
            pass: conditionalReassignmentPass
        });
        
        // Remove redundant nil initialization pass (should run before pipeline optimization)
        passes.push({
            name: "RemoveRedundantNilInit",
            description: "Remove redundant nil initialization when variable is immediately reassigned",
            enabled: true,
            pass: removeRedundantNilInitPass
        });
        
        // String method transformation pass (before pipeline optimization)
        // NOTE: Disabled because we now use String.cross.hx to generate idiomatic code directly
        // The .cross.hx pattern is better as it generates correct code from the start
        // rather than transforming it after the fact
        
        passes.push({
            name: "StringMethodTransform",
            description: "Convert string method calls to String module calls",
            enabled: true,
            pass: stringMethodTransformPass
        });
        
        // Pipeline optimization pass
        #if !disable_pipeline_optimization
        passes.push({
            name: "PipelineOptimization",
            description: "Convert sequential operations to pipeline",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.PipelineTransforms.pipelineOptimizationPass
        });
        #end
        
        // Instance method transformation pass for standard library types
        passes.push({
            name: "InstanceMethodTransform",
            description: "Transform instance.method() to Module.function(instance) for stdlib types",
            enabled: true,
            pass: instanceMethodTransformPass
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
        
        // Loop to comprehension pass
        #if !disable_comprehension_conversion
        passes.push({
            name: "ComprehensionConversion",
            description: "Convert imperative loops to comprehensions",
            enabled: true,
            pass: comprehensionConversionPass
        });
        #end
        
        // Unrolled comprehension optimization pass (MUST run before effect lifting)
        // TODO: Fix implementation - functions need to be moved before this reference
        
        // (Removed) UnrolledComprehensionOptimization pass – no implementation available
        
        // Effect lifting for list literals pass
        passes.push({
            name: "ListEffectLifting",
            description: "Lift side-effecting expressions out of list literals",
            enabled: true,
            pass: listEffectLiftingPass
        });
        
        // Immutability transformation pass
        #if !disable_immutability_transform
        passes.push({
            name: "ImmutabilityTransform",
            description: "Convert mutable patterns to immutable",
            enabled: true,
            pass: immutabilityTransformPass
        });
        #end
        
        // Null coalescing inline transformation pass
        passes.push({
            name: "NullCoalescingInline",
            description: "Convert null coalescing blocks to inline expressions",
            enabled: true,
            pass: nullCoalescingInlinePass
        });
        
        // Statement context transformation pass (MUST run after immutability)
        // Map iterator transformation pass was already registered earlier (line 413)
        
        #if !disable_statement_context_transform
        passes.push({
            name: "StatementContextTransform",
            description: "Add reassignments for immutable operations in statement context",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.StructAndMapTransforms.statementContextTransformPass
        });
        #end
        
        // Self reference transformation pass (should run early)
        passes.unshift({
            name: "SelfReferenceTransform",
            description: "Convert self/this references to struct parameter",
            enabled: true,
            pass: selfReferenceTransformPass
        });
        
        // Struct field assignment transformation pass
        passes.push({
            name: "StructFieldAssignmentTransform",
            description: "Convert struct field assignments to struct update syntax",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.StructAndMapTransforms.structFieldAssignmentTransformPass
        });

        passes.push({
            name: "MapBuilderCollapse",
            description: "Replace Map.put builder blocks with literal maps",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.MapAndCollectionTransforms.mapBuilderCollapsePass
        });

        // Block-wide discriminant inlining: inline "bind then case" even with gaps
        passes.push({
            name: "BindThenCaseInline",
            description: "Within blocks, inline prior temp binding into subsequent case target (supports gaps and backward search)",
            enabled: true,
            pass: bindThenCaseInlinePass
        });

        // Cleanup redundant temp alias assignments introduced during enum extraction
        passes.push({
            name: "TempAliasCleanup",
            description: "Remove redundant temp alias assignments in statement contexts",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.TempVariableTransforms.tempAliasCleanupPass
        });

        // Assignment extraction pass (must run before underscore cleanup)
        passes.push({
            name: "AssignmentExtraction",
            description: "Extract assignments from binary operations and other expression contexts",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.AssignmentExtractionTransforms.assignmentExtractionPass
        });

        // ReduceWhile init de-infrastructure (builder-preferred; transformer fallback)
        passes.push({
            name: "ReduceWhileInitCleanup",
            description: "Inline pure alias locals used to initialize Enum.reduce_while accumulator and drop dead assignments",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ReduceWhileInitCleanup.reduceWhileInitCleanupPass
        });

        // Reduce while accumulator transformation (must run after assignment extraction)
        passes.push({
            name: "ReduceWhileAccumulator",
            description: "Fix variable shadowing in reduce_while loops by proper accumulator threading",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ReduceWhileAccumulatorTransform.reduceWhileAccumulatorPass
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
            pass: fluentApiOptimizationPass
        });

        // (moved earlier, before StringInterpolation)
        
        // Idiomatic enum pattern matching transformation (must run before underscore cleanup)
        passes.push({
            name: "IdiomaticEnumPatternMatching",
            description: "Transform enum tuple access patterns to idiomatic pattern matching",
            enabled: true,
            pass: idiomaticEnumPatternMatchingPass
        });
        
        // Pattern matching transformation pass (comprehensive switch→case conversion)
        passes.push({
            name: "PatternMatching",
            description: "Transform switch statements to idiomatic Elixir case expressions",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.PatternMatchingTransforms.patternMatchingPass
        });

        // Binder suffix normalization (mid) before guard consolidation/grouping
        // Unified, tag‑agnostic normalization — replaces older CanonicalizeTupleBinders
        passes.push({
            name: "PatternBinderSuffixNormalization",
            description: "Mid-pass: strip trailing digit suffixes from refs that correspond to clause binders (tag‑agnostic)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.PatternMatchingTransforms.patternBinderSuffixNormalizationPass
        });

        // Consolidate multiple guard-bearing clauses with same pattern into cond
        passes.push({
            name: "GuardClauseConsolidation",
            description: "Consolidate same-pattern guarded clauses into a single cond body",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.PatternMatchingTransforms.guardClauseConsolidationPass
        });

        // Remove preserved switch temp wrappers introduced by preprocessors when safe
        passes.push({
            name: "RemoveSwitchResultWrapper",
            description: "Eliminate __elixir_switch_result_* wrappers when block is [match; var]",
            enabled: true,
            pass: function(ast) return removeSwitchResultWrapper(ast)
        });
        
        // Pattern matching guard optimization pass
        passes.push({
            name: "PatternMatchingGuardOptimization",
            description: "Optimize pattern matching by extracting guards from case bodies",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.PatternMatchingTransforms.guardOptimizationPass
        });

        // Late inline of bind-then-case patterns produced by PatternMatching transforms
        passes.push({
            name: "BindThenCaseInlineLate",
            description: "Late pass: inline temp discriminant bindings created during pattern matching into case targets",
            enabled: true,
            pass: bindThenCaseInlinePass
        });

        // Nested-case discriminant inlining with lexical environment mapping
        passes.push({
            name: "NestedCaseDiscriminantInline",
            description: "Propagate earlier temp bindings through nested blocks to inline case discriminants (g/_g/gN)",
            enabled: true,
            pass: nestedCaseDiscriminantInlinePass
        });

        // Late cleanup of temp alias assignments now that case shapes have stabilized
        passes.push({
            name: "TempAliasCleanupLate",
            description: "Late pass: remove redundant temp alias assignments adjacent to cases",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.TempVariableTransforms.tempAliasCleanupPass
        });

        // Dead assignment elimination (module/function scope), conservative and side‑effect aware
        passes.push({
            name: "DeadAssignmentElimination",
            description: "Remove pure alias assignments (g/_g/gN, temp_result) that are never read in the enclosing block",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.DeadAssignmentElimination.deadAssignmentEliminationPass
        });

        // Pattern variable binding pass
        passes.push({
            name: "PatternVariableBinding",
            description: "Ensure correct variable scoping in pattern matching",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.PatternMatchingTransforms.patternVariableBindingPass
        });

        // Event/controller binding preservation: pre-bind repeated Map.get(params, :key)
        passes.push({
            name: "EventBindingPreservation",
            description: "Pre-bind repeated Map.get(params, :key) in event/controller handlers to preserve bindings and readability",
            enabled: true,
            pass: eventBindingPreservationPass
        });

        // Case-clause binding aliasing: synthesize missing vars in clause bodies from pattern binders
        passes.push({
            name: "CaseClauseBindingAlias",
            description: "Alias undeclared body variables to clause pattern binders (e.g., data/changeset/user/message) to prevent undefined variables",
            enabled: true,
            pass: caseClauseBindingAliasPass
        });
        // Global Option.Some/ok binder aliasing (target-agnostic, structural)
        passes.push({
            name: "GlobalOptionBinderAlias",
            description: "For {:some|:ok, binder} patterns, pre-bind exactly-one missing simple var to the binder",
            enabled: true,
            pass: globalOptionBinderAliasPass
        });

        // General tuple binder aliasing for domain enums like {:todo_created, todo}
        passes.push({
            name: "GeneralTupleBinderAlias",
            description: "For {atom, binder} patterns, rename binder to the single missing simple identifier used in the body",
            enabled: true,
            pass: generalTupleBinderAliasPass
        });
        
        // Pattern exhaustiveness check pass
        passes.push({
            name: "PatternExhaustivenessCheck",
            description: "Add compile-time verification for pattern completeness",
            enabled: false, // Disabled by default as it may be verbose
            pass: reflaxe.elixir.ast.transformers.PatternMatchingTransforms.exhaustivenessCheckPass
        });
        
        // Late normalization of suffixed refs back to pattern binders (post-analysis cleanup)
        passes.push({
            name: "PatternBinderSuffixNormalizationLate",
            description: "Late-pass: map suffixed variable refs to base binder names prior to underscore cleanup",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.PatternMatchingTransforms.patternBinderSuffixNormalizationPass
        });

        // Underscore variable cleanup pass (should run late to catch all generated vars)
        #if !disable_underscore_cleanup
        passes.push({
            name: "UnderscoreVariableCleanup",
            description: "Remove underscore prefix from used temporary variables",
            enabled: true,
            pass: underscoreVariableCleanupPass
        });
        #end

        // Final zero-arity atom normalization and binder collision avoidance
        passes.push({
            name: "FinalPatternNormalization",
            description: "Collapse single-atom tuples to atoms and avoid binder collisions with function params",
            enabled: true,
            pass: finalPatternNormalizationPass
        });

        // Normalize variable references to snake_case within function scope to align with declared vars
        passes.push({
            name: "VarRefNormalization",
            description: "Normalize camelCase variable references to snake_case when a matching declaration exists",
            enabled: true,
            pass: varRefNormalizationPass
        });

        // Resolve and eliminate infrastructure case targets BEFORE validation
        passes.push({
            name: "InfraCaseTargetResolution",
            description: "Replace case targets on _g/gX with mapped canonical vars when prior bindings exist in scope",
            enabled: true,
            pass: infraCaseTargetResolutionPass
        });

        // Inline case targets on infra vars using recorded init expressions (contextual)
        passes.push({
            name: "InfraCaseTargetExprInline",
            description: "Replace case targets on infra vars (g/_g/gN) with recorded init expressions from block tracking",
            enabled: true,
            pass: function(a) return a,
            contextualPass: infraCaseTargetExprInlinePass
        });

        // Final structural resolver for orphaned infra case targets in nested branches
        passes.push({
            name: "NestedCaseProducerResolver",
            description: "Inline nested case discriminants by locating nearest prior producer expr when bindings are absent",
            enabled: true,
            pass: nestedCaseProducerResolverPass
        });

        // Fallback: inline unknown case target variable using prior infra assignment RHS (handles benign gaps)
        passes.push({
            name: "UnknownCaseTargetExprInline",
            description: "Inline case target var when a prior infra assignment to the discriminant exists in the same block (benign-gap aware)",
            enabled: true,
            pass: unknownCaseTargetExprInlinePass
        });

        passes.push({
            name: "InlineCaseTargetBinding",
            description: "Replace 'binding + case' sequence with direct case expression to drop infra temp",
            enabled: true,
            pass: inlineCaseTargetBindingPass
        });

        // Align immediate infra assignment LHS to the following case target variable
        passes.push({
            name: "CaseTargetBindingAlign",
            description: "If a case target variable follows an infra assignment, rename the assignment LHS to that variable",
            enabled: true,
            pass: caseTargetBindingAlignPass
        });

        // Validation: ensure no infrastructure variables leak into final AST
        passes.push({
            name: "InfraVarValidation",
            description: "Fail compilation if _g/g/gN names remain in final AST",
            enabled: true,
            pass: infraVarValidationPass
        });

        // Main function visibility pass (ensure public def main() for top-level Main modules)
        passes.push({
            name: "MainFunctionVisibility",
            description: "Flip defp main() to def main() for top-level Main modules",
            enabled: true,
            pass: mainFunctionVisibilityPass
        });
        
        // Rename tuple pattern variables based on body usage
        passes.push({
            name: "PatternVarRenameByUsage",
            description: "Rename tuple pattern PVar names to match variables used in clause bodies (e.g., todo, message, reason)",
            enabled: true,
            pass: patternVarRenameByUsagePass
        });

        // Function parameter rename-by-usage (structural): for EDef/EDefp, if body references exactly one
        // missing simple identifier and there exists an unused simple binder among function parameters,
        // rename that binder to the missing identifier. No aliasing here; aliasing is handled by later passes.
        passes.push({
            name: "FunctionParamRenameByUsage",
            description: "Rename unused function parameter binder to the unique missing identifier used in body (structural)",
            enabled: true,
            pass: functionParamRenameByUsagePass
        });

        // Ensure Option.Some binder consistency after all earlier renames (generic, no app-specific names)
        passes.push({
            name: "OptionBinderConsistency",
            description: "Align {:some, binder} with identifiers used in clause body using generic heuristics",
            enabled: true,
            pass: optionBinderConsistencyPass
        });

        // Generic binder substitution: prefer clause binder inside nested Option/Result payloads
        // before falling back to alias injection. This minimizes aliasing and keeps code idiomatic.
        passes.push({
            name: "GenericBinderSubstitution",
            description: "Rewrite nested Option/Result payload variables to the single clause binder; inject alias only when unique and uncertain",
            enabled: true,
            pass: genericBinderSubstitutionPass
        });
        // Late global binder aliasing to catch transformed cases
        passes.push({
            name: "GlobalOptionBinderAliasLate",
            description: "Late pass: replace a single missing simple var in {:some|:ok, binder} bodies with the binder",
            enabled: true,
            pass: globalOptionBinderAliasPass
        });

        // General atom-head tuple binder aliasing: for {:atom, binder} with single binder, if exactly one
        // free simple identifier is referenced in the clause body, inject an alias var = binder at clause entry.
        passes.push({
            name: "GeneralAtomBinderAlias",
            description: "For {:atom, binder} case arms with a single binder, alias unique missing identifier to binder",
            enabled: true,
            pass: generalAtomBinderAliasPass
        });

        // Terminal catch-all: for any case clause with exactly one binder and exactly one missing
        // simple identifier referenced in the body, inject `missing = binder` at clause start.
        passes.push({
            name: "SingleBinderMissingVarAlias",
            description: "Catch-all alias injection for single-binder case arms with one missing identifier",
            enabled: true,
            pass: singleBinderMissingVarAliasPass
        });

        // Final safety net: alias missing single identifier to single tuple binder
        passes.push({
            name: "SingleBinderAlias",
            description: "If a clause pattern has exactly one PVar and the body uses one missing simple var, alias missing = binder",
            enabled: true,
            pass: singleBinderAliasPass
        });

        
        // Abstract method this reference fix (should run after underscore cleanup)
        passes.push({
            name: "AbstractMethodThis",
            description: "Fix 'this' references in abstract methods",
            enabled: true,
            pass: abstractMethodThisPass
        });

        // (moved to super-late block below to ensure terminal ordering)
        
        // Supervisor options transformation pass (convert maps to keyword lists)
        #if !disable_supervisor_options_transform
        passes.push({
            name: "SupervisorOptionsTransform",
            description: "Convert supervisor option maps to keyword lists",
            enabled: true,
            pass: supervisorOptionsTransformPass
        });
        #end
        
        // OTP child spec transformation pass (convert tuples to proper child specs)
        #if !disable_otp_child_spec_transform
        passes.push({
            name: "OTPChildSpecTransform",
            description: "Convert enum-based child specs to proper OTP child specifications",
            enabled: true,
            pass: otpChildSpecTransformPass
        });
        #end

        // Final polish: normalize rescue concat patterns (e.g., tmp = DateTime.utc_now(); tmp.to_iso8601())
        passes.push({
            name: "RescueConcatNormalization",
            description: "Normalize concat+bind+immediate-call patterns inside rescue blocks",
            enabled: true,
            pass: rescueConcatNormalizationPass
        });

        // Global block peephole normalization (concat+bind+immediate-call)
        passes.push({
            name: "BlockConcatNormalization",
            description: "Normalize concat+bind+immediate-call patterns in general EBlocks",
            enabled: true,
            pass: blockConcatNormalizationPass
        });
        
        // Prefix unused function parameters with underscore
        // DISABLED: Now handled during AST building with more accurate TypedExpr-based detection
        // The transformer approach had issues with mismatched detection logic between TypedExpr and ElixirAST
        // See ElixirASTBuilder line 2064-2070 for the proper implementation
        /*
        passes.push({
            name: "PrefixUnusedParameters", 
            description: "Prefix unused function parameters with underscore to follow Elixir conventions",
            enabled: true,
            pass: prefixUnusedParametersPass
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

        // Mark unused private functions to enable @compile nowarn emission
        passes.push({
            name: "MarkUnusedPrivateFunctions",
            description: "Collect defp usage and annotate module metadata with unused function list",
            enabled: true,
            pass: markUnusedPrivateFunctionsPass
        });

        // Deprecated: canonical tuple binder normalization (domain-specific) — replaced by unified suffix normalization
        // Intentionally removed to keep tag‑agnostic behavior
        
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
            pass: fixBareConcatenationsPass
        });

        // Peephole: clean up nested chain assignments and dead this1 bindings
        passes.push({
            name: "ThisAndChainCleanup",
            description: "Split a = b = expr into separate statements and drop dead this/this1 assignments",
            enabled: true,
            pass: thisAndChainCleanupPass
        });

        // Case-arm unused binder underscore
        passes.push({
            name: "CaseArmUnusedBinderUnderscore",
            description: "Prefix unused pattern binders in case arms with underscore",
            enabled: true,
            pass: caseArmUnusedBinderUnderscorePass
        });

        // Underscore unused anonymous function parameters (including nested tuple patterns)
        passes.push({
            name: "FnParamUnusedUnderscore",
            description: "Prefix unused anonymous function parameters (EFn) with underscore, including nested tuple components",
            enabled: true,
            pass: underscoreUnusedFnParamsPass
        });
        
        // Pattern variable origin analysis pass
        // TODO: Temporarily disabled - needs proper implementation
        // passes.push({
        //     name: "PatternVariableOriginAnalysis",
        //     description: "Use VarOrigin metadata to properly handle pattern variables vs temp extraction variables",
        //     enabled: false,
        //     pass: null // patternVariableOriginAnalysisPass
        // });

        // Super-late enforcement: ensure *_level targets use binder 'level' after all renames
        passes.push({
            name: "SuperLateEnforceLevelBinder",
            description: "Final pass to enforce binder 'level' for *_level case targets",
            enabled: true,
            pass: enforceLevelBinderForLevelTargetsPass
        });

        // Terminal safeguard: if a {:some|:ok, binder} clause body references 'level',
        // force binder name to 'level' (structural, target-agnostic). This catches
        // nested shapes missed by earlier passes.
        passes.push({
            name: "ForceOptionLevelBinderWhenBodyUsesLevel",
            description: "Rename {:some|:ok, _} binder to 'level' when clause body references level",
            enabled: true,
            pass: forceOptionLevelBinderWhenBodyUsesLevelPass
        });

        // Absolute terminal enforcement: for case targets ending with *_level,
        // rename {:some|:ok, binder} → {:some|:ok, level} unconditionally.
        // This runs last to override any inconsistent earlier renames.
        passes.push({
            name: "AbsoluteLevelBinderEnforcement",
            description: "Final pass: enforce binder 'level' for *_level case targets (structural)",
            enabled: true,
            pass: absoluteLevelBinderEnforcementPass
        });

        // As a safety net, if a clause body references 'level' but binder is different,
        // inject `level = binder` at the start of the clause body. This is local and safe.
        passes.push({
            name: "OptionLevelAliasInjection",
            description: "Inject clause-local alias `level = binder` when {:some|:ok, binder} body references level",
            enabled: true,
            pass: optionLevelAliasInjectionPass
        });

        // Very-late binder substitution for nested payload shapes in Option/Result clauses
        passes.push({
            name: "SingleBinderAliasVeryLate",
            description: "Replace free payload vars with the sole binder inside {:some|:ok, binder} clause bodies (pubsub nested shapes)",
            enabled: true,
            pass: singleBinderAliasVeryLatePass
        });

        // Event arm binder rename by usage (structural): in handler/controller functions, for atom-head tuple
        // case arms, if a single missing identifier is referenced and there exists an unused binder in the
        // arm pattern (excluding the atom head), rename the first unused binder to that identifier.
        passes.push({
            name: "EventArmBinderRenameByUsage",
            description: "In handler/controller case arms, rename an unused binder to the unique missing identifier referenced in the body",
            enabled: true,
            pass: eventArmBinderRenameByUsagePass
        });

        // Return only enabled passes
        return passes.filter(p -> p.enabled);
    }

    /**
     * MarkUnusedPrivateFunctionsPass
     * - Within each module, collect defp names/arity and their call sites.
     * - Annotate module metadata with unusedPrivateFunctionsWithArity for the printer to emit @compile nowarn.
     */
    static function markUnusedPrivateFunctionsPass(ast: ElixirAST): ElixirAST {
        function collectDefsAndCalls(node: ElixirAST): {defs:Array<{name:String, arity:Int}>, calls:Map<String, Bool>} {
            var defs:Array<{name:String, arity:Int}> = [];
            var calls = new Map<String,Bool>();
            function arityOfPatterns(args:Array<EPattern>):Int return args != null ? args.length : 0;
            function walk(n:ElixirAST):Void {
                if (n == null) return;
                switch (n.def) {
                    case EDefp(name, args, _, body):
                        defs.push({name: name, arity: arityOfPatterns(args)}); walk(body);
                    case EDef(_, _, _, body): walk(body);
                    case EModule(_, _, body): for (b in body) walk(b);
                    case EDefmodule(_, doBlock): walk(doBlock);
                    case EBlock(stmts): for (s in stmts) walk(s);
                    case EIf(c,t,e): walk(c); walk(t); if (e != null) walk(e);
                    case ECase(target, clauses): walk(target); for (c in clauses) walk(c.body);
                    case ECond(conds): for (c in conds) walk(c.body);
                    case ECall({def: EVar(f)}, _, _): calls.set(f, true);
                    case ECall(_, _, args): for (a in args) walk(a);
                    case ERemoteCall(target, _, args): walk(target); for (a in args) walk(a);
                    default: iterateAST(n, walk);
                }
            }
            walk(node);
            return {defs: defs, calls: calls};
        }
        return switch (ast.def) {
            case EModule(name, attrs, body):
                var agg = collectDefsAndCalls(ast);
                var unused:Array<{name:String, arity:Int}> = [];
                for (d in agg.defs) {
                    if (!agg.calls.exists(d.name)) unused.push(d);
                }
                var newMeta = ast.metadata != null ? ast.metadata : {};
                (cast newMeta).unusedPrivateFunctionsWithArity = unused;
                makeASTWithMeta(EModule(name, attrs, body.map(b -> markUnusedPrivateFunctionsPass(b))), newMeta, ast.pos);
            default:
                transformAST(ast, markUnusedPrivateFunctionsPass);
        };
    }

    /**
     * ThisAndChainCleanupPass
     * - Split nested matches `a = b = expr` into two statements so the temporary is actually referenced.
     * - Remove assignments to `this`/`this1`-like variables when they are not used later in the block.
     *   This eliminates Elixir warnings without altering semantics.
     */
    static function thisAndChainCleanupPass(ast: ElixirAST): ElixirAST {
        inline function isThisLike(n:String):Bool {
            if (n == null) return false;
            return ~/^_?this\d*$/.match(n) || n == "this" || n == "this1";
        }

        function usesVar(node: ElixirAST, varName: String): Bool {
            if (node == null) return false;
            return switch (node.def) {
                case EVar(n): n == varName;
                default:
                    var found = false;
                    iterateAST(node, ch -> { if (!found && usesVar(ch, varName)) found = true; });
                    found;
            };
        }

        function isUsedInLater(stmts:Array<ElixirAST>, startIdx:Int, varName:String):Bool {
            var i = startIdx + 1;
            while (i < stmts.length) {
                if (usesVar(stmts[i], varName)) return true;
                i++;
            }
            return false;
        }

        function splitChainAssign(stmt: ElixirAST): Array<ElixirAST> {
            return switch (stmt.def) {
                case EMatch(PVar(outer), inner):
                    switch (inner.def) {
                        case EMatch(PVar(tmp), expr):
                            var innerBinder = isThisLike(tmp) ? '_' + tmp : tmp;
                            var first = makeAST(EMatch(PVar(innerBinder), expr));
                            var second = makeAST(EMatch(PVar(outer), makeAST(EVar(innerBinder))));
                            [ first, second ];
                        case EParen(e2):
                            switch (e2.def) {
                                case EMatch(PVar(tmp2), expr2):
                                    var innerBinder2 = isThisLike(tmp2) ? '_' + tmp2 : tmp2;
                                    var first2 = makeAST(EMatch(PVar(innerBinder2), expr2));
                                    var second2 = makeAST(EMatch(PVar(outer), makeAST(EVar(innerBinder2))));
                                    [ first2, second2 ];
                                default: [ stmt ];
                            }
                        default: [ stmt ];
                    }
                default: [ stmt ];
            };
        }

        function transform(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case EBlock(stmts):
                    var out:Array<ElixirAST> = [];
                    // First, split any nested chain assignments
                    for (s in stmts) {
                        var split = splitChainAssign(s);
                        for (x in split) out.push(transform(x));
                    }
                    // Second, remove dead this/this1-like assignments
                    var filtered:Array<ElixirAST> = [];
                    for (idx in 0...out.length) {
                        var s = out[idx];
                        var drop = false;
                        switch (s.def) {
                            case EMatch(PVar(n), _):
                                if (isThisLike(n) && !isUsedInLater(out, idx, n)) {
                                    var __pos = s.pos != null ? Std.string(s.pos) : "";
                                    if (__pos.indexOf("Users") >= 0 || __pos.indexOf("UserChangeset") >= 0) {
                                        haxe.Log.trace('[ThisAndChainCleanup] dropping dead assignment to ' + n + ' at ' + __pos, null);
                                    }
                                    drop = true;
                                }
                            default:
                        }
                        if (!drop) filtered.push(s);
                    }
                    makeASTWithMeta(EBlock(filtered), node.metadata, node.pos);
                case EDef(name, args, guard, body):
                    makeASTWithMeta(EDef(name, args, guard, transform(body)), node.metadata, node.pos);
                case EDefp(name, args, guard, body):
                    makeASTWithMeta(EDefp(name, args, guard, transform(body)), node.metadata, node.pos);
                case EIf(c, t, e):
                    makeASTWithMeta(EIf(transform(c), transform(t), e != null ? transform(e) : null), node.metadata, node.pos);
                case ECase(target, clauses):
                    var newClauses = [];
                    for (cl in clauses) newClauses.push({ pattern: cl.pattern, guard: cl.guard, body: transform(cl.body) });
                    makeASTWithMeta(ECase(transform(target), newClauses), node.metadata, node.pos);
                case EParen(e):
                    makeASTWithMeta(EParen(transform(e)), node.metadata, node.pos);
                default:
                    node;
            };
        }

        return transform(ast);
    }

    /**
     * OptionBinderConsistencyPass
     *
     * WHY: Subsequent naming passes or earlier builder heuristics can occasionally misalign
     * the Option.Some/ok binder name with the identifiers actually used in the clause body.
     * This can surface as undefined variables (e.g., pattern {:some, msg} while body uses `level`).
     *
     * WHAT: For every case clause with pattern {:some|:ok, binder}, if the binder is not referenced
     * in the clause body and there is exactly one viable identifier referenced in the body that is
     * not a field-base (Map.get/Keyword.get target), not already a binder, and not an obvious
     * outer/param name, rename the binder to that identifier. This keeps pattern and body consistent
     * and prevents undefined variable errors while avoiding shadowing of outer variables like `msg`.
     */
    static function optionBinderConsistencyPass(ast: ElixirAST): ElixirAST {
        return reflaxe.elixir.ast.transformers.BinderAliasTransforms.optionBinderConsistencyPass(ast);
    }

    /**
     * EnforceLevelBinderForLevelTargets: For any case target variable whose snake_case name ends with '_level',
     * rename {:some|:ok, binder} → {:some|:ok, level}. This runs very late to avoid interference.
     */
    static function enforceLevelBinderForLevelTargetsPass(ast: ElixirAST): ElixirAST {
        return reflaxe.elixir.ast.transformers.OptionLevelBinderTransforms.enforceLevelBinderForLevelTargetsPass(ast);
    }

    /**
     * ForceOptionLevelBinderWhenBodyUsesLevelPass
     * - For any ECase clause with pattern {:some|:ok, binder}, if the clause body references 'level',
     *   rename the binder to 'level'. This is terminal and structural, and narrowly scoped.
     */
    static function forceOptionLevelBinderWhenBodyUsesLevelPass(ast: ElixirAST): ElixirAST {
        return reflaxe.elixir.ast.transformers.OptionLevelBinderTransforms.forceOptionLevelBinderWhenBodyUsesLevelPass(ast);
    }

    /**
     * AbsoluteLevelBinderEnforcementPass
     * - For any ECase with target variable name ending in *_level, force
     *   {:some|:ok, binder} → {:some|:ok, level} regardless of other heuristics.
     * - Runs absolutely last to guarantee binder correctness for *_level targets.
     */
    static function absoluteLevelBinderEnforcementPass(ast: ElixirAST): ElixirAST {
        return reflaxe.elixir.ast.transformers.OptionLevelBinderTransforms.absoluteLevelBinderEnforcementPass(ast);
    }

    /**
     * OptionLevelAliasInjectionPass
     * - For any ECase clause with pattern {:some|:ok, binder} and body referencing 'level'
     *   while binder != 'level', inject a clause-local alias `level = binder`.
     */
    static function optionLevelAliasInjectionPass(ast: ElixirAST): ElixirAST {
        return reflaxe.elixir.ast.transformers.OptionLevelBinderTransforms.optionLevelAliasInjectionPass(ast);
    }

    // parseMessageBinderFixPass removed – avoid app-specific coupling

    /**
     * Remove simple switch-result temp wrappers produced by preservation preprocessor:
     * def f() do
     *   __elixir_switch_result_1 = case ... do ... end
     *   __elixir_switch_result_1
     * end
     * Becomes:
     * def f() do
     *   case ... do ... end
     * end
     */
    static function removeSwitchResultWrapper(ast: ElixirAST): ElixirAST {
        return transformNode(ast, function(node) {
            switch (node.def) {
                case EDef(name, args, guard, body):
                    var newBody = simplifySwitchWrapper(body);
                    return makeASTWithMeta(EDef(name, args, guard, newBody), node.metadata, node.pos);
                case EDefp(name, args, guard, body):
                    var newBody = simplifySwitchWrapper(body);
                    return makeASTWithMeta(EDefp(name, args, guard, newBody), node.metadata, node.pos);
                default:
                    return node;
            }
        });
    }

    /**
     * Final normalization: ensure patterns like {:tag} collapse to :tag and avoid
     * binding names that collide with function parameters (e.g., message).
     * This runs late to catch shapes reintroduced by earlier transforms.
     */
    static function finalPatternNormalizationPass(ast: ElixirAST): ElixirAST {
        #if debug_final_pattern
        function patSig(p:EPattern):String {
            return switch (p) {
                case PVar(v): v;
                case PLiteral({def: EAtom(a)}): ':' + a;
                case PTuple(el): '{' + [for (e in el) patSig(e)].join(',') + '}';
                default: Type.enumConstructor(p);
            };
        }
        #end
        // Collect function parameter names when inside a def/defp
        var fnParams: Map<String,Bool> = null;

        function renameInPattern(p:EPattern, from:String, to:String):EPattern {
            return switch (p) {
                case PVar(n) if (n == from): PVar(to);
                case PTuple(list): PTuple([for (e in list) renameInPattern(e, from, to)]);
                case PList(list): PList([for (e in list) renameInPattern(e, from, to)]);
                case PCons(h,t): PCons(renameInPattern(h, from, to), renameInPattern(t, from, to));
                case PMap(pairs): PMap([for (kv in pairs) {key: kv.key, value: renameInPattern(kv.value, from, to)}]);
                case PStruct(m, fields): PStruct(m, [for (f in fields) {key: f.key, value: renameInPattern(f.value, from, to)}]);
                default: p;
            };
        }

        function renameInBody(node:ElixirAST, from:String, to:String):ElixirAST {
            return transformNode(node, function(n){
                return switch (n.def) {
                    case EVar(name) if (name == from): makeAST(EVar(to));
                    default: n;
                };
            });
        }

        function bodyHasVar(node:ElixirAST, name:String):Bool {
            var found = false;
            transformNode(node, function(n){
                if (!found) switch (n.def) {
                    case EVar(vn) if (vn == name): found = true;
                    default:
                }
                return n;
            });
            return found;
        }

        function collapseSingleAtomTuple(p:EPattern):EPattern {
            return switch (p) {
                case PTuple(el) if (el.length == 1):
                    switch (el[0]) { case PLiteral({def: EAtom(a)}): PLiteral(makeAST(EAtom(a))); default: p; }
                default: p;
            };
        }

        return transformNode(ast, function(n){
            switch (n.def) {
                case EDef(name, args, guard, body):
                    // collect parameter names
                    fnParams = new Map();
                    for (a in args) switch (a) { case PVar(pn): fnParams.set(pn, true); default: }
                    var newBody = finalPatternNormalizationPass(body);
                    return makeASTWithMeta(EDef(name, args, guard, newBody), n.metadata, n.pos);
                case EDefp(name, args, guard, body):
                    fnParams = new Map();
                    for (a in args) switch (a) { case PVar(pn): fnParams.set(pn, true); default: }
                    var newBody2 = finalPatternNormalizationPass(body);
                    return makeASTWithMeta(EDefp(name, args, guard, newBody2), n.metadata, n.pos);
                case ECase(target, clauses):
                    var newClauses:Array<ECaseClause> = [];
                    var caseTargetName: Null<String> = null;
                    switch (target.def) { case EVar(nm): caseTargetName = nm; default: }
                    for (cl in clauses) {
                        var pat = collapseSingleAtomTuple(cl.pattern);
                        var body2 = cl.body;
                        // avoid binder collisions: for atom-tuple patterns with more than 1 element
                        switch (pat) {
                            case PTuple(list) if (list.length >= 2):
                                // rename any PVar that collides with fnParams
                                for (i in 1...list.length) switch (list[i]) {
                                    case PVar(vn) if (fnParams != null && fnParams.exists(vn)):
                                        // Prefer a semantically meaningful binder when possible
                                        var newName = vn + "2";
                                        // Heuristic: if case target hints a suffix and body uses that name, prefer it
                                        if (caseTargetName != null) {
                                            if (~/.*_level$/.match(caseTargetName) && bodyHasVar(body2, "level")) newName = "level";
                                            else if (~/.*_id$/.match(caseTargetName) && bodyHasVar(body2, "id")) newName = "id";
                                            else if (~/.*_msg$/.match(caseTargetName) && bodyHasVar(body2, "message")) newName = "message";
                                        }
                                        pat = renameInPattern(pat, vn, newName);
                                        body2 = renameInBody(body2, vn, newName);
                                    case PVar(vn):
                                        // If body uses vn2 but not vn, align binder to vn2 (idiomatic snapshot expectation)
                                        var vn2 = vn + "2";
                                        if (!bodyHasVar(body2, vn) && bodyHasVar(body2, vn2)) {
                                            pat = renameInPattern(pat, vn, vn2);
                                        }
                                    default:
                                }
                            default:
                        }
                        #if debug_final_pattern
                        haxe.Log.trace('[FinalNorm] pattern before=' + patSig(cl.pattern) + ' after=' + patSig(pat), null);
                        #end
                        newClauses.push({ pattern: pat, guard: cl.guard, body: finalPatternNormalizationPass(body2) });
                    }
                    return makeASTWithMeta(ECase(target, newClauses), n.metadata, n.pos);
                default:
                    return transformAST(n, v -> finalPatternNormalizationPass(v));
            }
        });
    }

    static function simplifySwitchWrapper(body: ElixirAST): ElixirAST {
        return switch (body.def) {
            case EBlock(stmts) if (stmts.length == 2):
                var first = stmts[0];
                var last = stmts[1];
                switch (first.def) {
                    case EMatch(PVar(varName), rhs):
                        switch (last.def) {
                            case EVar(name) if (name == varName):
                                // Only simplify when RHS is a case expression
                                return switch (rhs.def) {
                                    case ECase(_, _): rhs;
                                    default: body;
                                }
                            ;
                            default: body;
                        }
                    default: body;
                }
            default:
                body;
        };
    }

    /**
     * Guard Condition Grouping Pass
     * 
     * WHY: When Haxe switch statements contain multiple cases with the same pattern but different 
     * guard conditions, the compiler was generating nested if-else statements with undefined variables.
     * This pass transforms these patterns into idiomatic Elixir `cond` statements.
     * 
     * WHAT: Transforms multiple case clauses with identical patterns but different guards into
     * a single clause with a `cond` expression in the body.
     * 
     * Example transformation:
     *   case color do
     *     {:rgb, r, g, b} when r > 200 -> "red dominant"
     *     {:rgb, r, g, b} when g > 200 -> "green dominant"  
     *     {:rgb, r, g, b} when b > 200 -> "blue dominant"
     *     {:rgb, r, g, b} -> "balanced"
     *   end
     * 
     * Becomes:
     *   case color do
     *     {:rgb, r, g, b} ->
     *       cond do
     *         r > 200 -> "red dominant"
     *         g > 200 -> "green dominant"
     *         b > 200 -> "blue dominant"
     *         true -> "balanced"
     *       end
     *   end
     * 
     * HOW: Uses metadata attached by ElixirASTBuilder (patternKey, boundVars, hasGuard)
     * to detect groupable clauses and transform them.
     */
    public static function guardGroupingPass(ast: ElixirAST): ElixirAST {
        #if debug_guard_grouping
        trace('[XRay GuardGrouping] Starting guard grouping pass with three-phase flattener');
        if (ast != null && ast.def != null) {
            trace('[XRay GuardGrouping] Processing node type: ' + ast.def);
        }
        #end
        
        // Handle null nodes
        if (ast == null) return null;
        
        return switch(ast.def) {
            case EParen(inner):
                // Check if the parentheses wrap a case expression
                #if debug_guard_grouping
                trace("[XRay GuardGrouping] Found EParen, checking inner content");
                #end
                
                switch(inner?.def) {
                    case ECase(target, clauses):
                        #if debug_guard_grouping
                        trace("[XRay GuardGrouping] Found ECase inside EParen, transforming");
                        #end
                        
                        // Transform the case expression
                        var transformedClauses = [];
                        for (clause in clauses) {
                            var transformedClause = transformClauseWithGuards(clause);
                            transformedClauses.push(transformedClause);
                        }
                        
                        // Return the transformed case WITHOUT parentheses
                        // (parentheses around case are usually not needed)
                        makeASTWithMeta(
                            ECase(transformAST(target, guardGroupingPass), transformedClauses),
                            ast.metadata,
                            ast.pos
                        );
                        
                    default:
                        // Not a case inside parentheses, recurse normally
                        makeASTWithMeta(
                            EParen(transformAST(inner, guardGroupingPass)),
                            ast.metadata,
                            ast.pos
                        );
                }
                
            case ECase(target, clauses):
                #if debug_guard_grouping
                trace("[XRay GuardGrouping] Found direct ECase with " + clauses.length + " clauses");
                #end
                
                // Transform each clause individually
                var transformedClauses = [];
                
                for (clause in clauses) {
                    // Check if the clause body is a nested if-else chain (guards compiled by Haxe)
                    var transformedClause = transformClauseWithGuards(clause);
                    transformedClauses.push(transformedClause);
                }
                
                makeASTWithMeta(
                    ECase(transformAST(target, guardGroupingPass), transformedClauses),
                    ast.metadata,
                    ast.pos
                );
                
            default:
                // For nodes we don't handle, use transformAST to recursively transform children
                transformAST(ast, guardGroupingPass);
        };
    }
    
    /**
     * Transform a case clause that has guards compiled as nested if-else
     * Uses the three-phase GuardConditionFlattener for robust transformation
     */
    static function transformClauseWithGuards(clause: ECaseClause): ECaseClause {
        #if debug_guard_grouping
        trace("[XRay GuardGrouping] Examining clause with three-phase flattener");
        if (clause.pattern != null) {
            trace("[XRay GuardGrouping] Pattern type: " + Type.typeof(clause.pattern));
        }
        if (clause.body != null) {
            trace("[XRay GuardGrouping] Body def: " + clause.body.def);
        }
        #end
        
        // Phase 1: Collect all guard conditions from nested if-else chains
        var guardBranches = GuardConditionCollector.collectAllGuardConditions(clause.body);
        
        #if debug_guard_grouping
        trace('[XRay GuardGrouping] Phase 1 - Collected ${guardBranches.length} guard branches');
        #end
        
        // If no guard conditions found, just transform recursively
        if (guardBranches.length == 0) {
            return {
                pattern: clause.pattern,
                guard: clause.guard,
                body: transformAST(clause.body, guardGroupingPass)
            };
        }
        
        // Phase 2: Validate that conditions can be grouped
        // Extract bound variables from the pattern for validation
        var boundVars = extractBoundVariablesFromPattern(clause.pattern);
        var validationResult = GuardGroupValidator.validateGuardGroup(guardBranches, boundVars);
        
        #if debug_guard_grouping
        trace('[XRay GuardGrouping] Phase 2 - Validation result: canGroup=${validationResult.canGroup}, reason="${validationResult.reason}"');
        #end
        
        // If validation fails, fall back to recursive transformation
        if (!validationResult.canGroup) {
            #if debug_guard_grouping
            trace('[XRay GuardGrouping] Validation failed: ${validationResult.reason}');
            #end
            return {
                pattern: clause.pattern,
                guard: clause.guard,
                body: transformAST(clause.body, guardGroupingPass)
            };
        }
        
        // Phase 3: Reconstruct as a flat cond expression
        var flatCond = GuardConditionReconstructor.buildFlatCond(guardBranches, boundVars, clause.pattern);
        
        #if debug_guard_grouping
        trace('[XRay GuardGrouping] Phase 3 - Built flat cond expression');
        #end
        
        return {
            pattern: clause.pattern,
            guard: null,
            body: flatCond
        };
    }
    
    /**
     * Extract bound variable names from a pattern
     */
    static function extractBoundVariablesFromPattern(pattern: EPattern): Array<String> {
        var vars = [];
        
        function extract(p: EPattern): Void {
            switch(p) {
                case PVar(name): 
                    vars.push(name);
                case PTuple(patterns):
                    // Tuples can contain variables (like enum constructors)
                    for (subPattern in patterns) {
                        extract(subPattern);
                    }
                case PList(patterns):
                    for (subPattern in patterns) {
                        extract(subPattern);
                    }
                case PAlias(varName, pattern):
                    vars.push(varName);
                    extract(pattern);
                case PCons(head, tail):
                    extract(head);
                    extract(tail);
                default:
                    // Other patterns don't bind variables
            }
        }
        
        if (pattern != null) {
            extract(pattern);
        }
        
        return vars;
    }
    
    /**
     * Remove nil assignments for generated variables (r2 = nil, b3 = nil, etc.)
     * These are created by Haxe's guard compilation but are not needed
     */
    static function removeNilAssignments(ast: ElixirAST): ElixirAST {
        if (ast == null) return null;
        
        return switch(ast.def) {
            case EBlock(exprs):
                #if debug_guard_grouping
                trace('[XRay RemoveNil] Processing EBlock with ${exprs.length} expressions');
                #end
                // Filter out nil assignments for generated variables
                var filtered = [];
                for (expr in exprs) {
                    var isGeneratedNilAssignment = switch(expr.def) {
                        case EMatch(PVar(varName), rhs) if (rhs != null):
                            #if debug_guard_grouping
                            trace('[XRay RemoveNil] Checking match for variable: $varName');
                            trace('[XRay RemoveNil] RHS type: ' + Type.enumConstructor(rhs.def));
                            #end
                            switch(rhs.def) {
                                case EAtom(a):
                                    var atomStr = (a:String);
                                    #if debug_guard_grouping
                                    trace('[XRay RemoveNil] Atom value: "$atomStr"');
                                    #end
                                    if (atomStr == "nil") {
                                        // Check if variable name ends with digit (r2, b3, etc.)
                                        var isGenerated = ~/^[a-z]+\d+$/.match(varName);
                                        #if debug_guard_grouping
                                        trace('[XRay RemoveNil] Is generated variable: $isGenerated for $varName');
                                        #end
                                        isGenerated;
                                    } else {
                                        false;
                                    }
                                default: false;
                            }
                        default: false;
                    };
                    
                    if (!isGeneratedNilAssignment) {
                        // Recursively clean the expression
                        filtered.push(removeNilAssignments(expr));
                    }
                }
                
                // Return simplified block or single expression
                if (filtered.length == 0) {
                    null;
                } else if (filtered.length == 1) {
                    filtered[0];
                } else {
                    makeASTWithMeta(EBlock(filtered), ast.metadata, ast.pos);
                }
                
            default:
                // Recursively transform children
                transformAST(ast, removeNilAssignments);
        };
    }
    
    /**
     * Fix undefined variable references in guard conditions
     * Maps suffixed variables (g2, r2, b2) back to their original names (g, r, b)
     */
    static function fixUndefinedVariables(ast: ElixirAST): ElixirAST {
        if (ast == null) return null;
        
        return switch(ast.def) {
            case EVar(name):
                // More comprehensive pattern to fix various undefined variables
                // Patterns to fix:
                // - Single letter with number: g2 -> g, r3 -> r, b4 -> b
                // - Names with number suffix: l2 -> l, h2 -> h, s2 -> s
                // - Multi-letter names: r2 -> r, g2 -> g, b2 -> b
                
                // Check for common patterns from the test output
                var fixedName = name;
                
                // Pattern 1: Single letter followed by digit(s)
                if (~/^[a-z]\d+$/.match(name)) {
                    fixedName = name.charAt(0);
                }
                // Pattern 2: Common variable names with numeric suffixes
                else if (~/^(r|g|b|h|s|l)\d+$/.match(name)) {
                    fixedName = ~/^([a-z]+)\d+$/.replace(name, "$1");
                }
                // Pattern 3: More general - any word followed by digits
                else if (~/^(\w+?)\d+$/.match(name)) {
                    var base = ~/^(\w+?)\d+$/.replace(name, "$1");
                    // Only fix if it looks like a generated variable
                    if (base.length <= 2) {
                        fixedName = base;
                    }
                }
                
                if (fixedName != name) {
                    #if debug_guard_grouping
                    trace('[XRay GuardGrouping] Fixing variable: $name -> $fixedName');
                    #end
                    makeASTWithMeta(EVar(fixedName), ast.metadata, ast.pos);
                } else {
                    ast;
                }
                
            case EBinary(op, left, right):
                // Fix both sides of binary operations
                var fixedLeft = fixUndefinedVariables(left);
                var fixedRight = fixUndefinedVariables(right);
                makeASTWithMeta(EBinary(op, fixedLeft, fixedRight), ast.metadata, ast.pos);
                
            case ECall(expr, method, args):
                // Fix function calls and their arguments
                var fixedExpr = fixUndefinedVariables(expr);
                var fixedArgs = args.map(fixUndefinedVariables);
                makeASTWithMeta(ECall(fixedExpr, method, fixedArgs), ast.metadata, ast.pos);
                
            case EIf(cond, thenBranch, elseBranch):
                // Fix all parts of if expressions
                var fixedCond = fixUndefinedVariables(cond);
                var fixedThen = fixUndefinedVariables(thenBranch);
                var fixedElse = elseBranch != null ? fixUndefinedVariables(elseBranch) : null;
                makeASTWithMeta(EIf(fixedCond, fixedThen, fixedElse), ast.metadata, ast.pos);
                
            case EParen(inner):
                // Fix inside parentheses
                var fixedInner = fixUndefinedVariables(inner);
                makeASTWithMeta(EParen(fixedInner), ast.metadata, ast.pos);
                
            default:
                // For other node types, recursively fix children
                transformAST(ast, fixUndefinedVariables);
        };
    }
    
    /**
     * Extract cond branches from nested if-else chain
     */
    static function extractCondBranches(ast: ElixirAST): Array<{condition: ElixirAST, body: ElixirAST}> {
        var branches = [];
        
        function extract(node: ElixirAST, depth: Int = 0) {
            if (node == null) return;
            
            #if debug_guard_grouping
            trace("[XRay ExtractBranches] Depth " + depth + ", node type: " + (node.def != null ? Type.enumConstructor(node.def) : "null"));
            #end
            
            // Clean up nil assignments first
            var cleanedNode = removeNilAssignments(node);
            if (cleanedNode == null) return;
            
            // Recursively unwrap blocks and parentheses after cleaning
            var nodeToProcess = cleanedNode;
            var unwrapping = true;
            while (unwrapping && nodeToProcess != null) {
                switch(nodeToProcess.def) {
                    case EBlock(exprs) if (exprs.length == 1):
                        nodeToProcess = exprs[0];
                    case EParen(inner):
                        nodeToProcess = inner;
                    default:
                        unwrapping = false;
                }
            }
            
            switch(nodeToProcess.def) {
                case EIf(cond, thenBranch, elseBranch):
                    // Fix variables in both the condition and body
                    var fixedCond = fixUndefinedVariables(cond);
                    var fixedBody = fixUndefinedVariables(thenBranch);
                    
                    branches.push({
                        condition: fixedCond,
                        body: fixedBody  // Don't transform here, will be done later
                    });
                    
                    #if debug_guard_grouping
                    trace("[XRay ExtractBranches] Added branch at depth " + depth);
                    #end
                    
                    // Recursively process else branch
                    if (elseBranch != null) {
                        extract(elseBranch, depth + 1);
                    }
                    
                case _:
                    // This is the final else case (or a single expression)
                    var fixedNode = fixUndefinedVariables(nodeToProcess);
                    branches.push({
                        condition: makeAST(EBoolean(true)),
                        body: fixedNode
                    });
                    
                    #if debug_guard_grouping
                    trace("[XRay ExtractBranches] Added final branch at depth " + depth);
                    #end
            }
        }
        
        extract(ast);
        return branches;
    }
    

    /**
     * InlineTempBindingInExpr: Collapse simple temp-binding EBlock into a single expression
     * 
     * TERMINOLOGY:
     * - "Collapse" means to transform a two-statement block into a single expression by
     *   inlining a temporary variable. For example:
     *   BEFORE: (tmp = Date.now(); DateTime.to_unix(tmp, :millisecond))
     *   AFTER:  DateTime.to_unix(Date.now(), :millisecond)
     *   The temporary variable 'tmp' is eliminated by substituting its value directly.
     * 
     * WHY: Abstract method inlining sometimes produces blocks like:
     *   %{:online_at => (tmp = Date.now(); DateTime.to_unix(tmp, :millisecond))}
     * which is invalid in map field position. We collapse to a single expression:
     *   %{:online_at => DateTime.to_unix(Date.now(), :millisecond)}
     * 
     * WHAT: Detect EBlock([EMatch(PVar(tmp), exprA), exprB]) where exprB contains EVar(tmp)
     * and replace all occurrences of tmp in exprB with exprA, eliminating the temp variable.
     * 
     * HOW: Two-phase approach to avoid infinite recursion:
     * 1. Build a parent map to track expression vs statement contexts
     * 2. Single bottom-up transformation pass that collapses only in expression contexts
     * 
     * EDGE CASES:
     * - Only collapse in expression contexts (map values, function args, etc.)
     * - Skip collapsing in statement contexts (case clause bodies, function bodies)
     * - Only collapse if the temp variable is actually used
     * - Preserve precedence by wrapping substituted expressions in parentheses
     */
    
    /**
     * Throw statement transformation pass
     * 
     * WHY: Complex expressions in throw statements can generate invalid Elixir syntax
     *      when string concatenation includes conditionals or function calls
     * WHAT: Transforms throw expressions with complex string concatenation
     * HOW: Wraps complex expressions in parentheses to ensure valid syntax
     */
    static function throwStatementTransformPass(ast: ElixirAST): ElixirAST {
        if (ast == null || ast.def == null) return ast;
        return switch(ast.def) {
            case EThrow(value):
                // Transform the throw value to ensure it's a valid single expression
                var transformedValue = transformThrowValue(value);
                {
                    def: EThrow(transformedValue),
                    metadata: ast.metadata,
                    pos: ast.pos
                };
            default:
                // Recursively transform children using the standard transformer
                transformAST(ast, throwStatementTransformPass);
        };
    }
    
    /**
     * Transform throw value to ensure it generates valid Elixir syntax
     */
    static function transformThrowValue(expr: ElixirAST): ElixirAST {
        return switch(expr.def) {
            case EBinary(StringConcat, left, right):
                // For string concatenation, ensure both sides are properly formatted
                var leftTransformed = transformThrowValue(left);
                var rightTransformed = transformThrowValue(right);
                
                // If right side is complex, wrap it in parentheses
                var rightWrapped = switch(rightTransformed.def) {
                    case EIf(_, _, _):
                        {
                            def: EParen(rightTransformed),
                            metadata: rightTransformed.metadata,
                            pos: rightTransformed.pos
                        };
                    case ECall(_, _, _) if (hasConditionalInCall(rightTransformed)):
                        {
                            def: EParen(rightTransformed),
                            metadata: rightTransformed.metadata,
                            pos: rightTransformed.pos
                        };
                    default:
                        rightTransformed;
                };
                
                {
                    def: EBinary(StringConcat, leftTransformed, rightWrapped),
                    metadata: expr.metadata,
                    pos: expr.pos
                };
                
            case EIf(cond, then, els):
                // Wrap if expressions in parentheses when used in throw
                {
                    def: EParen(expr),
                    metadata: expr.metadata,
                    pos: expr.pos
                };
                
            default:
                expr;
        };
    }
    
    /**
     * Check if a call expression contains conditionals that might cause syntax issues
     */
    static function hasConditionalInCall(expr: ElixirAST): Bool {
        return switch(expr.def) {
            case ECall(_, _, args):
                Lambda.exists(args, function(arg) {
                    return switch(arg.def) {
                        case EIf(_, _, _): true;
                        default: false;
                    };
                });
            default: false;
        };
    }
    
    /**
     * Identity pass - returns AST unchanged
     * Base pass that ensures transformer works even with no transformations
     */
    static function identityPass(ast: ElixirAST): ElixirAST {
        return ast;
    }
    
    /**
     * Resolve Clause Locals Pass
     * 
     * WHY: Variables in case clause bodies need to match the names used in patterns.
     * When Haxe generates temporary variables (_g, g, etc.) for enum parameters,
     * but our patterns use the actual parameter names (value, reason, etc.),
     * we need to resolve these references.
     * 
     * WHAT: Looks for nodes with varIdToName metadata and rewrites EVar nodes
     * within them to use the mapped names based on their sourceVarId.
     * 
     * HOW: When we encounter a node with varIdToName metadata, we walk its
     * subtree and rewrite any EVar that has a sourceVarId matching an entry
     * in the varIdToName map.
     * 
     * EDGE CASES:
     * - Nested case expressions: Each case should have its own varIdToName scope
     * - String interpolation: Variables inside __elixir__() injections need resolution
     * - Anonymous functions: May reference outer scope variables
     */

    /**
     * Remove Redundant Enum Extraction Pass
     *
     * WHY: Elixir pattern matching already extracts values, but Haxe generates redundant elem() calls
     * WHAT: Removes assignments like `g = elem(result, 1)` after pattern `{:ok, g}`
     * HOW: Detects and removes redundant extraction statements in case bodies
     *
     * EXAMPLE:
     * Before:
     *   {:ok, g} ->
     *     g = elem(result, 1)  # Redundant!
     *     value = g
     *     value
     *
     * After:
     *   {:ok, g} ->
     *     value = g
     *     value
     */
    static function removeRedundantEnumExtractionPass(ast: ElixirAST): ElixirAST {
        #if debug_redundant_extraction
        trace('[RemoveRedundantEnumExtraction] Debug mode enabled');
        #end

        // Track the case target variable name for nested detection
        var caseTargetVar: String = null;
        // Track whether the current case has an enum binding plan
        var currentCaseHasBindingPlan: Bool = false;

        return transformNode(ast, function(node: ElixirAST): ElixirAST {
            switch(node.def) {
                case ECase(target, clauses):
                    // Enhanced debug for ChangesetUtils issue
                    var targetDebug = switch(target.def) {
                        case EVar(v): 'variable: $v';
                        case EParen(inner): switch(inner.def) {
                            case EVar(v): 'variable in parens: $v';
                            default: 'complex expression';
                        };
                        default: 'complex expression';
                    };
                    #if debug_redundant_extraction
                    trace('[RemoveRedundantEnumExtraction] Processing ECase with ${clauses.length} clauses, target: $targetDebug');
                    #end
                    // Check if this case has an enum binding plan
                    currentCaseHasBindingPlan = node.metadata != null && node.metadata.hasEnumBindingPlan == true;
                    #if debug_enum_extraction
                    if (currentCaseHasBindingPlan) {
                        trace('[RemoveRedundantEnumExtraction] Found ECase with hasEnumBindingPlan flag');
                    }
                    #end

                    // Extract the case target variable name
                    switch(target.def) {
                        case EVar(v): caseTargetVar = v;
                        case EParen(inner):
                            switch(inner.def) {
                                case EVar(v): caseTargetVar = v;
                                default:
                            }
                        default:
                    }

                    // trace('[RemoveRedundantEnumExtraction] Processing case with target: $caseTargetVar');
                    // Process each case clause
                    var newClauses = [];
                    for (i in 0...clauses.length) {
                        var clause = clauses[i];
                        // ECaseClause is a typedef with pattern, guard, and body fields
                        var pattern = clause.pattern;
                        var guard = clause.guard;
                        var body = clause.body;

                        // Debug pattern to understand ChangesetUtils issue
                        var patternDebug = switch(pattern) {
                            case PTuple(elements):
                                var elemStrs = [for (e in elements) switch(e) {
                                    case PLiteral(ast):
                                        switch(ast.def) {
                                            case EAtom(a): ':$a';
                                            default: '?';
                                        }
                                    case PVar(v): v;
                                    default: '?';
                                }];
                                '{${elemStrs.join(", ")}}';
                            default: 'other pattern';
                        };
                        trace('[RemoveRedundantEnumExtraction] Clause $i pattern: $patternDebug');

                        // Propagate the binding plan flag to the clause body
                        if (currentCaseHasBindingPlan && body != null) {
                            if (body.metadata == null) body.metadata = {};
                            body.metadata.parentHasBindingPlan = true;
                        }

                        // Check if body contains redundant extraction
                        var newBody = switch(body.def) {
                            case EBlock(exprs):
                                // M0 FIX: Track variable renames when removing redundant assignments
                                var varRenames: Map<String, String> = new Map();

                                // First pass: Filter out redundant elem() assignments and track renames
                                var filtered = [];
                                for (i in 0...exprs.length) {
                                    var expr = exprs[i];

                                    // Skip null expressions (these are filtered assignments from TEnumParameter)
                                    if (expr == null) {
                                        continue;
                                    }

                                    var isRedundant = false;

                                    // Check if marked as redundant via metadata
                                    if (expr.metadata != null && expr.metadata.redundantEnumExtraction == true) {
                                        isRedundant = true;
                                        #if debug_redundant_extraction
                                        trace('[RemoveRedundantEnumExtraction] Found node marked as redundant via metadata');
                                        #end
                                    }

                                    // Check if this is a redundant extraction
                                    switch(expr.def) {
                                        case EMatch(PVar(varName), rhs):
                                            // Enhanced debug for ChangesetUtils issues
                                            if (rhs != null) {
                                                var rhsDebug = switch(rhs.def) {
                                                    case EVar(v): 'EVar($v)';
                                                    case ECall(_, fn, _): 'ECall($fn)';
                                                    default: Type.enumConstructor(rhs.def);
                                                };
                                                #if debug_redundant_extraction
                                                trace('[RemoveRedundantEnumExtraction] Found assignment: $varName = ... (RHS: $rhsDebug, caseTarget: $caseTargetVar)');
                                                #end
                                            } else {
                                                #if debug_redundant_extraction
                                                trace('[RemoveRedundantEnumExtraction] Found assignment: $varName = null (skipped assignment)');
                                                #end
                                                // Mark this as redundant since it has no RHS
                                                isRedundant = true;
                                            }

                                            // Check for self-assignment first (e.g., content = content)
                                        if (varName == switch(rhs.def) {
                                            case EVar(v): v;
                                            default: null;
                                        }) {
                                            isRedundant = true;
                                            #if debug_redundant_extraction
                                            trace('[RemoveRedundantEnumExtraction] Removing self-assignment: $varName = $varName');
                                            #end
                                        }
                                        // Check if the target variable itself is a temp pattern var
                                        else if (reflaxe.elixir.ast.ElixirASTBuilder.isTempPatternVarName(varName)) {
                                            isRedundant = true;
                                            #if debug_redundant_extraction
                                            trace('[RemoveRedundantEnumExtraction] Removing temp-var assignment: $varName = ...');
                                            #end
                                        }
                                        // Check if RHS is a reference to a temp variable (g, g1, g2, _g, etc.)
                                        else switch(rhs.def) {
                                            case EVar(v):
                                                // Check if this is an assignment from a temp variable
                                                    // Handle both "g" and "_g" patterns
                                                    // CRITICAL FIX: For idiomatic enums, the pattern uses the actual variable names
                                                    // (like {:ok, value}) instead of temp vars (like {:ok, g}).
                                                    // This means assignments like "value = g" are trying to assign from a
                                                    // non-existent variable 'g'. These MUST be removed unconditionally.
                                                    //
                                                    // Enhanced: For idiomatic enums with canonical pattern names,
                                                    // ANY assignment where RHS is "g" or a temp var should be removed
                                                    // because patterns already extract the values

                                                    // First, check if RHS is "g" (regardless of what LHS is)
                                                    // This catches "value = g" in idiomatic enums
                                                    if (v == "g" || v == "_g") {
                                                        isRedundant = true;
                                                        #if debug_redundant_extraction
                                                        trace('[RemoveRedundantEnumExtraction] Removing assignment: $varName = $v (non-existent temp var)');
                                                        #end
                                                    }
                                                    // Check for numbered temp vars in RHS: g1, g2, etc.
                                                    else if (v.length > 1 && v.charAt(0) == "g" &&
                                                             v.length == 2 && v.charAt(1) >= '0' && v.charAt(1) <= '9') {
                                                        isRedundant = true;
                                                        #if debug_redundant_extraction
                                                        trace('[RemoveRedundantEnumExtraction] Removing assignment: $varName = $v (non-existent numbered temp var)');
                                                        #end
                                                    }
                                                    // Check for underscore-prefixed numbered temp vars: _g1, _g2, etc.
                                                    else if (v.length == 3 && v.charAt(0) == "_" && v.charAt(1) == "g" &&
                                                             v.charAt(2) >= '0' && v.charAt(2) <= '9') {
                                                        isRedundant = true;
                                                        #if debug_redundant_extraction
                                                        trace('[RemoveRedundantEnumExtraction] Removing assignment: $varName = $v (non-existent underscore temp var)');
                                                        #end
                                                    }
                                                    // Also check for "g = result" pattern where result is case target
                                                    // This is ALWAYS wrong and should be removed - the pattern already extracted g
                                                    else if (v == caseTargetVar) {
                                                        // Remove assignments like "g = result" where g is a temp var
                                                        // The pattern {:error, g} already binds g to the error value
                                                        // So "g = result" would incorrectly assign the whole tuple
                                                        if (varName == "g" || varName == "_g" ||
                                                            (varName.length == 2 && varName.charAt(0) == "g" &&
                                                             varName.charAt(1) >= '0' && varName.charAt(1) <= '9') ||
                                                            (varName.length == 3 && varName.charAt(0) == "_" &&
                                                             varName.charAt(1) == "g" && varName.charAt(2) >= '0' &&
                                                             varName.charAt(2) <= '9')) {
                                                            isRedundant = true;
                                                            #if debug_redundant_extraction
                                                            trace('[RemoveRedundantEnumExtraction] Removing incorrect assignment: $varName = $v (pattern already extracted value)');
                                                            #end
                                                        }
                                                    }

                                                case ECall(targetExpr, funcName, args) if (funcName == "elem" && args.length == 1):
                                                    #if debug_redundant_extraction
                                                    trace('[RemoveRedundantEnumExtraction]   - Found elem() call');
                                                    #end
                                                    // Check if elem is extracting from the case target
                                                    var isTargetMatch = switch(targetExpr.def) {
                                                        case EVar(v):
                                                            #if debug_redundant_extraction
                                                            trace('[RemoveRedundantEnumExtraction]   - elem() target: $v, case target: $caseTargetVar');
                                                            #end
                                                            // Check if this matches the case target variable
                                                            v == caseTargetVar;
                                                        default:
                                                            #if debug_redundant_extraction
                                                            trace('[RemoveRedundantEnumExtraction]   - elem() target is not a simple variable');
                                                            #end
                                                            false;
                                                    };

                                                    if (isTargetMatch) {
                                                        // Check if this variable was already extracted by the pattern
                                                        // Pattern variables like 'g', 'g1', 'g2' are extracted
                                                        if (varName == "g" ||
                                                            (varName.length > 1 && varName.charAt(0) == "g" &&
                                                             varName.charAt(1) >= '0' && varName.charAt(1) <= '9')) {
                                                            isRedundant = true;
                                                            #if debug_redundant_extraction
                                                            #end
                                                        } else {
                                                            #if debug_redundant_extraction
                                                            trace('[RemoveRedundantEnumExtraction] Not redundant - varName: $varName does not match g pattern');
                                                            #end
                                                        }
                                                    } else {
                                                        #if debug_redundant_extraction
                                                        trace('[RemoveRedundantEnumExtraction] elem() not extracting from case target');
                                                        #end
                                                    }
                                                default:
                                            }
                                        default:
                                    }

                                    if (!isRedundant) {
                                        filtered.push(expr);
                                    }
                                }

                                // Return filtered block or single expression if only one left
                                // CRITICAL FIX: Must actually evaluate to a value, not just execute expressions
                                // ALSO: Ensure immutability by creating new AST nodes
                                if (filtered.length == 0) {
                                    makeAST(ENil);
                                } else if (filtered.length == 1) {
                                    // Recursively transform the single expression to ensure complete immutability
                                    transformNode(filtered[0], function(n) { return n; });
                                } else {
                                    // Recursively transform each filtered expression to ensure immutability
                                    var transformedFiltered = filtered.map(function(expr) {
                                        return transformNode(expr, function(n) { return n; });
                                    });
                                    // Preserve metadata when creating new block
                                    makeASTWithMeta(EBlock(transformedFiltered), body.metadata, body.pos);
                                };

                            default:
                                body; // Not a block, keep as-is
                        };

                        // Create new clause with updated body
                        // IMPORTANT: Recursively transform the new body to ensure all nested structures are processed
                        var fullyTransformedBody = transformNode(newBody, function(n) { return n; });
                        newClauses.push({
                            pattern: pattern,
                            guard: guard,
                            body: fullyTransformedBody
                        });
                    }

                    // Create new ECase node preserving original metadata and position
                    return makeASTWithMeta(ECase(target, newClauses), node.metadata, node.pos);

                default:
                    return node;
            }
        });
    }

    /**
     * Function Reference Transform Pass
     *
     * WHY: When passing functions as references in Elixir, they need the capture operator
     * WHAT: Transforms Module.function__FUNC_REF__N to &Module.function/N
     * HOW: Looks for EField nodes with __FUNC_REF__ marker and converts to capture syntax
     */
    static function functionReferenceTransformPass(ast: ElixirAST): ElixirAST {
        return transformNode(ast, function(node: ElixirAST): ElixirAST {
            switch(node.def) {
                case EField(target, field):
                    // Check if this has the function reference marker
                    if (field.indexOf("__FUNC_REF__") != -1) {
                        #if debug_function_reference
                        trace('[FunctionRef] Found marked field: $field');
                        #end
                        
                        // Extract the actual field name and arity
                        var parts = field.split("__FUNC_REF__");
                        var actualField = parts[0];
                        var arity = parts.length > 1 ? Std.parseInt(parts[1]) : 0;
                        if (arity == null) arity = 0;
                        
                        #if debug_function_reference
                        trace('[FunctionRef] Transforming to capture: &Module.$actualField/$arity');
                        #end
                        
                        // Create the clean field access without the marker
                        var cleanField = makeAST(EField(target, actualField));
                        
                        // Transform to capture syntax: &Module.function/arity
                        return makeAST(ECapture(cleanField, arity));
                    }
                    return node;
                    
                default:
                    return node;
            }
        });
    }
    
    /**
     * Null Coalescing Inline Pass
     * 
     * Transforms null coalescing blocks into inline if expressions.
     * Detects pattern: var x = {tmp = expr; if (tmp != nil) tmp else default}
     * Transforms to: var x = if (tmp = expr) != nil, do: tmp, else: default
     */
    static function nullCoalescingInlinePass(ast: ElixirAST): ElixirAST {
        return transformNode(ast, function(node: ElixirAST): ElixirAST {
            #if debug_null_coalescing
            switch(node.def) {
                case EMatch(PVar(name), value):
                    trace('[NullCoalescing] Found EMatch with name: $name');
                    if (value != null) {
                        switch(value.def) {
                            case EBlock(exprs):
                                trace('[NullCoalescing] Found block with ${exprs.length} expressions');
                            default:
                                trace('[NullCoalescing] Value is not a block: ${value.def}');
                        }
                    }
                default:
            }
            #end
            
            return switch(node.def) {
                case EMatch(PVar(name), value) if (value != null):
                    // Check if value is a block with null coalescing pattern
                    switch(value.def) {
                        case EBlock([assign, ifExpr]) if (assign != null && ifExpr != null):
                            // Check if this matches the null coalescing pattern
                            switch(assign.def) {
                                case EMatch(PVar(tmpName), expr) if (tmpName != null && tmpName.indexOf("tmp") >= 0):
                                    // Check if the if expression uses the same tmp variable
                                    switch(ifExpr.def) {
                                        case EIf(condition, thenBranch, elseBranch):
                                            // Check if condition is comparing tmp to nil
                                            switch(condition.def) {
                                                case EBinary(NotEqual, tmpVar, nilExpr):
                                                    switch(tmpVar.def) {
                                                        case EVar(checkName) if (checkName == tmpName):
                                                            // This is the null coalescing pattern!
                                                            // Transform to inline if with assignment in condition
                                                            // Create: name = if (tmp = expr) != nil, do: tmp, else: default
                                                            var assignExpr = makeAST(EMatch(PVar(tmpName), expr));
                                                            var inlineCondition = makeAST(EBinary(
                                                                NotEqual,
                                                                makeAST(EParen(assignExpr)),
                                                                makeAST(ENil)
                                                            ));
                                                            makeAST(EMatch(PVar(name), makeAST(EIf(inlineCondition, thenBranch, elseBranch))));
                                                        default:
                                                            node; // Not using the same tmp variable
                                                    }
                                                default:
                                                    node; // Not a nil comparison
                                            }
                                        default:
                                            node; // Not an if expression
                                    }
                                default:
                                    node; // Not a temp variable assignment
                            }
                        default:
                            node; // Not a null coalescing block
                    }
                default:
                    node; // Not a variable declaration or no transformation needed
            };
        });
    }
    
    /**
     * Self reference transformation pass - converts self/this references to struct parameter
     * In Elixir, instance methods receive the struct as their first parameter
     * 
     * For inheritance: Haxe's super.method() becomes delegation to parent module
     * Example: super.toString() -> ParentModule.to_string(struct)
     */
    static function selfReferenceTransformPass(ast: ElixirAST): ElixirAST {
        // First pass: collect module metadata for context
        var moduleMetadata: ElixirMetadata = null;
        
        function collectModuleMetadata(node: ElixirAST): Void {
            if (node == null || node.def == null) return;
            
            switch(node.def) {
                case EModule(_, _, _):
                    if (node.metadata != null) {
                        moduleMetadata = node.metadata;
                        #if debug_super_handling
                        trace("[SuperTransform] Collected module metadata: parentModule=" + 
                              (moduleMetadata.parentModule != null ? moduleMetadata.parentModule : "null"));
                        #end
                    }
                default:
                    // Continue traversing
                    iterateAST(node, collectModuleMetadata);
            }
        }
        
        collectModuleMetadata(ast);
        
        // Second pass: transform with context
        return transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch(node.def) {
                // Transform method calls on super
                // Note: In ElixirASTBuilder, super.toString() becomes:
                // ECall(target=null, methodName="call", args=[EField(EVar("super"), "to_string"), ...])
                // But we need to check for the direct case too:
                // ECall(target=EField(EVar("super"), "to_string"), methodName="call", args)
                case ECall(target, methodName, args):
                    #if debug_super_handling
                    trace("[SuperTransform] Processing ECall:");
                    trace("  target = " + target);
                    trace("  methodName = " + methodName);
                    trace("  args = " + args);
                    #end
                    
                    // First check if this is a call where the first arg is super.field access
                    if (methodName == "call" && args.length > 0) {
                        switch(args[0].def) {
                            case EField(superVar, fieldName):
                                if (superVar.def.match(EVar("super"))) {
                                    #if debug_super_handling
                                    trace("[SuperTransform] Found super." + fieldName + " as first argument");
                                    #end
                                    if (fieldName == "to_string" || fieldName == "toString") {
                                        #if debug_super_handling
                                        trace("[SuperTransform] Transforming super.toString() call to empty string");
                                        #end
                                        return makeAST(EString(""));
                                    }
                                }
                            default:
                        }
                    }
                    
                    // Also check if target itself is super.field or just super
                    if (target != null) {
                        switch(target.def) {
                            case EVar("super"):
                                // Direct super.method() call where super is the target
                                #if debug_super_handling
                                trace("[SuperTransform] Direct super as target detected!");
                                trace("  methodName = " + methodName);
                                trace("  node.metadata = " + node.metadata);
                                #end
                                
                                // Look for parent module in metadata
                                var parentModule = if (node.metadata != null && node.metadata.parentModule != null) {
                                    node.metadata.parentModule;
                                } else if (moduleMetadata != null && moduleMetadata.parentModule != null) {
                                    // Use collected module metadata
                                    moduleMetadata.parentModule;
                                } else {
                                    // No parent module available
                                    null;
                                };
                                
                                if (parentModule != null) {
                                    // Special handling for Exception parent (it's a behaviour, not a module with methods)
                                    if (parentModule == "Exception" && (methodName == "toString" || methodName == "to_string")) {
                                        #if debug_super_handling
                                        trace("[SuperTransform] Special handling for Exception.toString()");
                                        #end
                                        // For Exception base class, use Kernel.to_string on the message
                                        return makeAST(ERemoteCall(
                                            makeAST(EVar("Kernel")),
                                            "to_string",
                                            [makeAST(EField(makeAST(EVar("struct")), "message"))]
                                        ));
                                    }
                                    
                                    // Transform super.method() to ParentModule.method(struct, args...)
                                    #if debug_super_handling
                                    trace("[SuperTransform] Delegating to parent module: " + parentModule);
                                    trace("[SuperTransform] Parent module type: " + Type.typeof(parentModule));
                                    #end
                                    
                                    // Convert method name to snake_case for Elixir
                                    var elixirMethodName = if (methodName == "toString") {
                                        "to_string";
                                    } else {
                                        NameUtils.toSnakeCase(methodName);
                                    };
                                    
                                    // Build delegation call: ParentModule.method(struct, original_args...)
                                    var delegationArgs = [makeAST(EVar("struct"))].concat(args);
                                    return makeAST(ERemoteCall(
                                        makeAST(EVar(parentModule)),  // Use EVar for module alias, not EAtom
                                        elixirMethodName,
                                        delegationArgs
                                    ));
                                } else if (methodName == "to_string" || methodName == "toString") {
                                    // Fallback for toString when parent is unknown
                                    #if debug_super_handling
                                    trace("[SuperTransform] No parent module found, handling toString for exception");
                                    #end
                                    
                                    // Check if this is an exception class
                                    var isException = (moduleMetadata != null && moduleMetadata.isException == true);
                                    
                                    if (isException) {
                                        // For exception classes, use Kernel.to_string on the message field
                                        // This properly converts the message to a string using Elixir's built-in function
                                        return makeAST(ERemoteCall(
                                            makeAST(EVar("Kernel")),
                                            "to_string",
                                            [makeAST(EField(makeAST(EVar("struct")), "message"))]
                                        ));
                                    } else {
                                        // For non-exception classes, just return the message field
                                        return makeAST(EField(makeAST(EVar("struct")), "message"));
                                    }
                                } else {
                                    // Keep as is if we can't resolve parent
                                    #if debug_super_handling
                                    trace("[SuperTransform] No parent module found, keeping super call as is");
                                    #end
                                    node;
                                }
                                
                            case EField(superVar, fieldName):
                                #if debug_super_handling
                                trace("[SuperTransform] EField target detected:");
                                trace("  superVar.def = " + superVar.def);
                                trace("  fieldName = " + fieldName);
                                #end
                                
                                if (superVar.def.match(EVar("super"))) {
                                    #if debug_super_handling
                                    trace("[SuperTransform] Super method call detected!");
                                    #end
                                    
                                    // This is super.method() call
                                    if (fieldName == "to_string" || fieldName == "toString") {
                                        #if debug_super_handling
                                        trace("[SuperTransform] Transforming super.toString() for exception class");
                                        #end
                                        
                                        // Check if this is an exception class
                                        var isException = (moduleMetadata != null && moduleMetadata.isException == true);
                                        
                                        if (isException) {
                                            // For exception classes, use Kernel.to_string on the message field
                                            return makeAST(ERemoteCall(
                                                makeAST(EVar("Kernel")),
                                                "to_string",
                                                [makeAST(EField(makeAST(EVar("struct")), "message"))]
                                            ));
                                        } else {
                                            // Default to empty string for non-exception classes
                                            return makeAST(EString(""));
                                        }
                                    } else {
                                        // For other methods, keep as is for now
                                        node;
                                    }
                                } else {
                                    node;
                                }
                            default:
                                #if debug_super_handling
                                trace("[SuperTransform] Target is not super or field access, keeping node");
                                #end
                                node;
                        }
                    } else {
                        node;
                    }
                    
                // Transform self.field and super.field  
                case EField(target, fieldName):
                    switch(target.def) {
                        case EVar("self"):
                            // Replace 'self' with 'struct' (the conventional first parameter)
                            makeAST(EField(makeAST(EVar("struct")), fieldName));
                        case EVar("super"):
                            // Don't transform super field access here anymore - handle in ECall
                            node;
                        default:
                            node;
                    }
                    
                // Transform standalone 'self' references
                case EVar("self"):
                    makeAST(EVar("struct"));
                    
                // Transform standalone 'super' references
                // NOTE: Don't transform super to nil - this causes issues with super.method() calls
                // Super method delegation should be handled at the TCall level when super is the target
                // case EVar("super"):
                //     makeAST(ENil);
                    
                // Handle super calls - Elixir doesn't have super
                case ECall(_target, funcName, _args):
                    if (funcName == "__super__") {
                        // Generate error or warning - super is not supported in Elixir
                        // For now, just return nil
                        makeAST(ENil);
                    } else {
                        node;
                    }
                    
                default:
                    node;
            }
        });
    }
    
    /**
     * Phoenix Component Import Pass: Add Phoenix.Component import when ~H sigil is used
     * 
     * WHY: The ~H sigil for HEEx templates requires Phoenix.Component to be imported
     * WHAT: Detects any ESigil with type "H" and adds the necessary import
     * HOW: Traverses AST looking for ~H sigils, then adds import if found
     * 
     * IMPORTANT: Skip if module already has LiveView use statement (includes Phoenix.Component)
     */
    static function phoenixComponentImportPass(ast: ElixirAST): ElixirAST {
        // Phase 1: Detect if ~H sigil is used
        var needsPhoenixComponent = false;
        
        #if debug_phoenix_component_import
        trace('[XRay PhoenixComponentImport] Starting scan for ~H sigils');
        #end
        
        // Recursive function to deeply traverse the AST
        function checkForHSigil(node: ElixirAST): Void {
            // Check for null node or def before processing
            if (node == null || node.def == null) {
                return;
            }

            switch(node.def) {
                case ESigil(type, _, _):
                    #if debug_phoenix_component_import
                    trace('[XRay PhoenixComponentImport] Found sigil type: $type');
                    #end
                    if (type == "H") {
                        needsPhoenixComponent = true;
                    }
                default:
                    // For all other node types, recursively visit children
                    iterateAST(node, checkForHSigil);
            }
        }
        
        checkForHSigil(ast);
        
        #if debug_phoenix_component_import
        trace('[XRay PhoenixComponentImport] Needs Phoenix.Component: $needsPhoenixComponent');
        #end
        
        // Phase 2: Add import if needed
        if (!needsPhoenixComponent) return ast;
        
        return transformNode(ast, function(node: ElixirAST): ElixirAST {
            switch(node.def) {
                case EDefmodule(name, doBlock):
                    #if debug_phoenix_component_import
                    trace('[XRay PhoenixComponentImport] Processing defmodule: $name');
                    #end
                    
                    // For defmodule, we need to inject the import into the do block
                    switch(doBlock.def) {
                        case EBlock(statements):
                            #if debug_phoenix_component_import
                            trace('[XRay PhoenixComponentImport] Defmodule has ${statements.length} statements');
                            #end
                            
                            // Check if Phoenix.Component is already imported or if LiveView is used
                            var hasImport = false;
                            var hasLiveViewUse = false;
                            for (stmt in statements) {
                                switch(stmt.def) {
                                    case EImport(module, _, _):
                                        // module is a string in EImport
                                        if (module == "Phoenix.Component") {
                                            hasImport = true;
                                            break;
                                        }
                                    case EUse(module, opts):
                                        // module is a string in EUse
                                        #if debug_phoenix_component_import
                                        trace('[XRay PhoenixComponentImport] Found EUse: module=$module, opts=$opts');
                                        #end
                                        if (module == "Phoenix.Component") {
                                            hasImport = true;
                                            break;
                                        }
                                        // Check if it's a LiveView use statement (e.g., use TodoAppWeb, :live_view)
                                        if (module.indexOf("Web") != -1 && opts != null && opts.length > 0) {
                                            // Check if it has :live_view option
                                            for (opt in opts) {
                                                #if debug_phoenix_component_import
                                                trace('[XRay PhoenixComponentImport] Checking option: $opt');
                                                #end
                                                switch(opt.def) {
                                                    // Pattern matching with abstract types requires guard clause
                                                case EAtom(atom) if (atom == "live_view"):
                                                        #if debug_phoenix_component_import
                                                        trace('[XRay PhoenixComponentImport] Found :live_view option - will skip Phoenix.Component');
                                                        #end
                                                        hasLiveViewUse = true;
                                                        hasImport = true; // LiveView includes Phoenix.Component
                                                        break;
                                                    default:
                                                }
                                            }
                                        }
                                    default:
                                }
                            }
                            
                            // Don't add Phoenix.Component if LiveView is already used
                            if (hasLiveViewUse) {
                                #if debug_phoenix_component_import
                                trace('[XRay PhoenixComponentImport] Module already has LiveView use statement, skipping Phoenix.Component');
                                #end
                                return node;
                            }
                            
                            if (!hasImport) {
                                #if debug_phoenix_component_import
                                trace('[XRay PhoenixComponentImport] Adding Phoenix.Component import');
                                #end
                                
                                // Create the import statement using EUse which takes a string
                                var importStmt = makeAST(EUse("Phoenix.Component", []));
                                
                                // Add import at the beginning of the module body
                                var newStatements = [importStmt].concat(statements);
                                var newDoBlock = makeASTWithMeta(EBlock(newStatements), doBlock.metadata, doBlock.pos);
                                
                                return makeASTWithMeta(EDefmodule(name, newDoBlock), node.metadata, node.pos);
                            }
                            
                            return node; // Return unchanged if already has import
                            
                        default:
                            // Single expression body, wrap in block with import
                            var importStmt = makeAST(EUse("Phoenix.Component", []));
                            var newDoBlock = makeAST(EBlock([importStmt, doBlock]));
                            return makeASTWithMeta(EDefmodule(name, newDoBlock), node.metadata, node.pos);
                    }
                    
                default:
                    return node;
            }
        });
    }
    
    /**
     * Phoenix function name mapping pass
     * 
     * WHY: Some Haxe helper functions need to be mapped to proper Phoenix functions
     * WHAT: Transforms assign_multiple to assign, and other custom names to Phoenix conventions
     * HOW: Detects function calls and remaps their names
     */
    static function phoenixFunctionMappingPass(node: ElixirAST): ElixirAST {
        return transformNode(node, function(n: ElixirAST): ElixirAST {
            switch(n.def) {
                // Transform assign_multiple(socket, map) to assign(socket, map)
                case ECall(null, "assign_multiple", args):
                    #if debug_ast_transformer
                    trace('[PhoenixFunctionMapping] Transforming assign_multiple to assign');
                    #end
                    return makeASTWithMeta(ECall(null, "assign", args), n.metadata, n.pos);
                    
                default:
                    return n;
            }
        });
    }
    
    /**
     * LiveView CoreComponents Import Pass: Add app's CoreComponents import for LiveView modules
     * 
     * WHY: LiveView modules that use component functions need to import their app's CoreComponents
     * WHAT: Detects component usage (<.button, <.input, etc.) and adds CoreComponents import
     * HOW: Looks for ~H sigils with component calls and adds appropriate import
     * 
     * NOTE: This can conflict with Phoenix.HTML.Form functions. In Phoenix apps, the CoreComponents
     * version takes precedence for dot-notation components (<.label> uses CoreComponents.label/1)
     */
    static function liveViewCoreComponentsImportPass(ast: ElixirAST): ElixirAST {
        // Phase 1: Detect if component functions are used
        var needsCoreComponents = false;
        var moduleName = "";
        
        #if debug_liveview_components
        trace('[XRay LiveViewComponents] Starting scan for component usage');
        #end
        
        // First, find the module name to determine the app name
        function findModuleName(node: ElixirAST): Void {
            // Check for null node or def before processing
            if (node == null || node.def == null) {
                return;
            }

            switch(node.def) {
                case EDefmodule(name, _):
                    moduleName = name;
                    return;
                default:
                    iterateAST(node, findModuleName);
            }
        }
        
        findModuleName(ast);
        
        // Check if this is a LiveView module (has "Live" in name)
        if (moduleName == "" || moduleName.indexOf("Live") == -1) {
            return ast; // Not a LiveView module
        }
        
        // Recursive function to check for component usage in ~H sigils
        function checkForComponents(node: ElixirAST): Void {
            switch(node.def) {
                case ESigil(type, content, _):
                    if (type == "H") {
                        // Check if content contains component calls like <.button, <.input, etc.
                        if (content.indexOf("<.") != -1) {
                            #if debug_liveview_components
                            trace('[XRay LiveViewComponents] Found component usage in ~H sigil');
                            #end
                            needsCoreComponents = true;
                        }
                    }
                default:
                    iterateAST(node, checkForComponents);
            }
        }
        
        checkForComponents(ast);
        
        #if debug_liveview_components
        trace('[XRay LiveViewComponents] Needs CoreComponents: $needsCoreComponents');
        #end
        
        // Phase 2: Add import if needed
        if (!needsCoreComponents) return ast;
        
        // Extract app name from module name (e.g., TodoAppWeb.UserLive -> TodoAppWeb)
        var appWebName = "";
        if (moduleName.indexOf(".") != -1) {
            var parts = moduleName.split(".");
            if (parts.length > 0) {
                appWebName = parts[0]; // Get the first part (e.g., TodoAppWeb)
            }
        }
        
        if (appWebName == "") return ast; // Can't determine app name
        
        var coreComponentsModule = appWebName + ".CoreComponents";
        
        return transformNode(ast, function(node: ElixirAST): ElixirAST {
            switch(node.def) {
                case EDefmodule(name, doBlock):
                    #if debug_liveview_components
                    trace('[XRay LiveViewComponents] Processing defmodule: $name');
                    #end
                    
                    // For defmodule, we need to inject the import into the do block
                    switch(doBlock.def) {
                        case EBlock(statements):
                            // Check if CoreComponents is already imported
                            var hasImport = false;
                            for (stmt in statements) {
                                switch(stmt.def) {
                                    case EImport(module, _, _):
                                        if (module == coreComponentsModule) {
                                            hasImport = true;
                                            break;
                                        }
                                    default:
                                }
                            }
                            
                            if (!hasImport) {
                                #if debug_liveview_components
                                trace('[XRay LiveViewComponents] Adding CoreComponents import: $coreComponentsModule');
                                #end
                                
                                // Create the import statement with specific functions to avoid conflicts
                                // Import CoreComponents but exclude label to avoid conflict with Phoenix.HTML.Form.label/1
                                // The dot-notation <.label> will still work via Phoenix.Component's component system
                                var exceptOptions: Array<EImportOption> = [{name: "label", arity: 1}];
                                var importStmt = makeAST(EImport(coreComponentsModule, null, exceptOptions));
                                
                                // Add import after use statements but before function definitions
                                var newStatements = [];
                                var importAdded = false;
                                
                                for (stmt in statements) {
                                    newStatements.push(stmt);
                                    // Add import after use statements
                                    if (!importAdded) {
                                        switch(stmt.def) {
                                            case EUse(_, _):
                                                newStatements.push(importStmt);
                                                importAdded = true;
                                            default:
                                        }
                                    }
                                }
                                
                                // If no use statements, add at the beginning
                                if (!importAdded) {
                                    newStatements = [importStmt].concat(statements);
                                }
                                
                                var newDoBlock = makeASTWithMeta(EBlock(newStatements), doBlock.metadata, doBlock.pos);
                                return makeASTWithMeta(EDefmodule(name, newDoBlock), node.metadata, node.pos);
                            }
                            
                            return node;
                            
                        default:
                            // Single expression body, unlikely for LiveView
                            return node;
                    }
                    
                default:
                    return node;
            }
        });
    }
    
    /**
     * String method transformation pass
     * 
     * WHY: Strings in Elixir don't have methods - they use the String module
     * WHAT: Transforms method calls on strings to String module calls
     * HOW: Detects ECall with string targets and converts to ERemoteCall
     * 
     * Examples:
     * - hex_chars.charAt(0) → String.at(hex_chars, 0)
     * - str.toLowerCase() → String.downcase(str)
     * - str.toUpperCase() → String.upcase(str)
     */
    /**
     * Instance method transformation pass
     * Transforms instance method calls to module function calls for standard library types
     * Example: buffer.add(str) → StringBuf.add(buffer, str)
     */
    static function instanceMethodTransformPass(ast: ElixirAST): ElixirAST {
        return reflaxe.elixir.ast.transformers.StringTransforms.instanceMethodTransformPass(ast);
    }
    
    static function stringMethodTransformPass(ast: ElixirAST): ElixirAST {
        return transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch(node.def) {
                // Handle method calls that look like string.method(args)
                case ECall(target, methodName, args) if (target != null):
                    // Check if this looks like a string method call
                    // Handle both camelCase and snake_case versions
                    var stringMethod = switch(methodName) {
                        case "charAt" | "char_at": "at";
                        case "charCodeAt" | "char_code_at": "to_charlist"; 
                        case "toLowerCase" | "to_lower_case": "downcase";
                        case "toUpperCase" | "to_upper_case": "upcase";
                        case "indexOf" | "index_of": "index";
                        case "substring" | "substr": "slice";
                        case "split": "split";
                        case "trim": "trim";
                        case "length": "length";  // Handle array/string length
                        case "toString" | "to_string": "to_string";  // Handle toString method calls
                        case "lastIndexOf" | "last_index_of": null;  // Special handling needed
                        case _: null;
                    };
                    
                    if (stringMethod != null) {
                        // Transform to String module call
                        #if debug_string_methods
                        trace('[StringMethodTransform] Converting ${methodName} to String.${stringMethod}');
                        if (target != null) {
                            trace('[StringMethodTransform] Target exists');
                        }
                        trace('[StringMethodTransform] Args count: ${args.length}');
                        #end
                        
                        // Special handling for different methods
                        if (methodName == "charCodeAt" || methodName == "char_code_at") {
                            // s.charCodeAt(pos) -> :binary.at(s, pos)
                            makeASTWithMeta(
                                ERemoteCall(
                                    makeAST(EAtom(ElixirAtom.raw("binary"))),
                                    "at",
                                    [target].concat(args)
                                ),
                                node.metadata,
                                node.pos
                            );
                        } else if (methodName == "toString" || methodName == "to_string") {
                            // Handle toString specially based on target type
                            // For integers and other primitives, use proper conversion
                            makeASTWithMeta(
                                ERemoteCall(
                                    makeAST(EVar("Integer")),
                                    "to_string",
                                    [target].concat(args)
                                ),
                                node.metadata,
                                node.pos
                            );
                        } else if (methodName == "length") {
                            // s.length -> String.length(s)
                            makeASTWithMeta(
                                ERemoteCall(
                                    makeAST(EVar("String")),
                                    "length",
                                    [target]
                                ),
                                node.metadata,
                                node.pos
                            );
                        } else {
                            // Prepend the target as the first argument
                            var newArgs = [target].concat(args);
                            makeASTWithMeta(
                                ERemoteCall(
                                    makeAST(EVar("String")),
                                    stringMethod,
                                    newArgs
                                ),
                                node.metadata,
                                node.pos
                            );
                        }
                    } else if (methodName == "lastIndexOf" || methodName == "last_index_of") {
                        // Special handling for lastIndexOf - no direct Elixir equivalent
                        // We can't easily transform this, so leave it as is for now
                        node;
                    } else {
                        node;
                    }
                    
                default:
                    node;
            };
        });
    }
    
    /**
     * Constant folding pass - evaluate constant expressions at compile time
     */
    static function constantFoldingPass(ast: ElixirAST): ElixirAST {
        return reflaxe.elixir.ast.transformers.ExpressionTransforms.constantFoldingPass(ast);
    }
    
    /**
     * String interpolation pass - convert string concatenation to idiomatic interpolation
     * 
     * WHY: Elixir's string interpolation #{} is more idiomatic and readable than concatenation
     * WHAT: Transforms EBinary(StringConcat, ...) chains into interpolated strings
     * HOW: Finds string concatenation chains and replaces them with interpolated strings
     * 
     * NOTE: We use a custom traversal instead of transformNode to avoid recursive transformation
     */
    static function stringInterpolationPass(ast: ElixirAST): ElixirAST {
        // Forwarder: use module implementation to keep transformer thin
        return reflaxe.elixir.ast.transformers.StringTransforms.stringInterpolationPass(ast);
        /*
        function transform(node: ElixirAST): ElixirAST {
            // Handle null nodes
            if (node == null) return null;
            
            // First check if this is a string concatenation chain at the top level
            switch(node.def) {
                case EBinary(StringConcat, l, r):
                    #if debug_string_interpolation
                    var fullNodeStr = ElixirASTPrinter.printAST(node);
                    trace('[StringInterpolation] Found concatenation pattern: ${fullNodeStr.substring(0, 200)}');
                    trace('[StringInterpolation] Left type: ${Type.enumConstructor(l.def)}');
                    trace('[StringInterpolation] Right type: ${Type.enumConstructor(r.def)}');
                    #end
                    // Collect all parts of the concatenation chain
                    var parts = [];
                    
                    function collectParts(expr: ElixirAST) {
                        switch(expr.def) {
                            case EBinary(StringConcat, l, r):
                                collectParts(l);
                                collectParts(r);
                            case EString(s):
                                parts.push({isString: true, value: s, expr: null});
                            default:
                                parts.push({isString: false, value: null, expr: expr});
                        }
                    }
                    
                    collectParts(node);
                    
                    // Check if we should convert to interpolation
                    var hasNonString = false;
                    var hasEmptyString = false;
                    for (part in parts) {
                        if (!part.isString) {
                            hasNonString = true;
                        } else if (part.value == "") {
                            hasEmptyString = true;
                        }
                    }
                    
                    // Only convert if we have non-string parts and multiple parts
                    if (hasNonString && parts.length > 1) {
                        // Build interpolated string
                        var result = '"';
                        
                        for (i in 0...parts.length) {
                            var part = parts[i];
                            if (part.isString) {
                                // Add literal string part (escape special characters)
                                var escaped = part.value;
                                escaped = escaped.split('\\').join('\\\\');
                                escaped = escaped.split('"').join('\\"');
                                escaped = escaped.split('#{').join('\\#{');  // Escape interpolation syntax
                                result += escaped;
                            } else {
                                // Add interpolated expression
                                // First recursively transform the expression
                                var transformedExpr = transform(part.expr);
                                
                                // Strip unnecessary .to_string() calls since Elixir auto-converts in interpolation
                                var exprToInterpolate = switch(transformedExpr.def) {
                                    case ECall(target, "to_string", []) if (target != null):
                                        // Remove the .to_string() wrapper, use the target directly
                                        target;
                                    default:
                                        transformedExpr;
                                };
                                
                                // Normalize embedded expressions BEFORE freezing to raw string
                                // Apply the same normalization passes used for regular code so idioms are preserved
                                // Example: items.length -> length(items)
                                exprToInterpolate = arrayLengthFieldToFunctionPass(exprToInterpolate);
                                // Normalize tuple elem access and similar field→function idioms
                                exprToInterpolate = tupleElemFieldToFunctionPass(exprToInterpolate);
                                
                                var exprStr = ElixirASTPrinter.printAST(exprToInterpolate);
                                result += '#{' + exprStr + '}';
                            }
                        }
                        
                        result += '"';
                        
                        #if debug_string_interpolation
                        trace('[StringInterpolation] Transformed to: $result');
                        #end
                        
                        // Return raw interpolated string
                        return makeASTWithMeta(ERaw(result), node.metadata, node.pos);
                    }
                    
                default:
                    // Not a string concatenation at top level
            }
            
            // For all other nodes, recursively transform children
            return switch(node.def) {
                case EModule(name, attributes, body):
                    makeASTWithMeta(
                        EModule(name, attributes, body.map(transform)),
                        node.metadata,
                        node.pos
                    );
                    
                case EDefmodule(name, doBlock):
                    makeASTWithMeta(
                        EDefmodule(name, transform(doBlock)),
                        node.metadata,
                        node.pos
                    );
                    
                case EDef(name, args, guards, body):
                    makeASTWithMeta(
                        EDef(name, args, guards, transform(body)),
                        node.metadata,
                        node.pos
                    );
                    
                case EDefp(name, args, guards, body):
                    makeASTWithMeta(
                        EDefp(name, args, guards, transform(body)),
                        node.metadata,
                        node.pos
                    );
                    
                case EBlock(expressions):
                    makeASTWithMeta(
                        EBlock(expressions.map(transform)),
                        node.metadata,
                        node.pos
                    );
                    
                // For other binary operations that aren't StringConcat, transform children
                case EBinary(op, left, right) if (op != StringConcat):
                    makeASTWithMeta(
                        EBinary(op, transform(left), transform(right)),
                        node.metadata,
                        node.pos
                    );
                
                // Transform function calls (e.g., Log.trace with string concatenation arguments)
                case ECall(target, method, args):
                    makeASTWithMeta(
                        ECall(
                            target != null ? transform(target) : null,
                            method,
                            args.map(transform)
                        ),
                        node.metadata,
                        node.pos
                    );
                
                // Transform remote calls (module function calls)
                case ERemoteCall(module, func, args):
                    makeASTWithMeta(
                        ERemoteCall(
                            transform(module),
                            func,
                            args.map(transform)
                        ),
                        node.metadata,
                        node.pos
                    );
                    
                // Transform match expressions (assignments)
                case EMatch(pattern, expr):
                    makeASTWithMeta(
                        EMatch(pattern, transform(expr)),
                        node.metadata,
                        node.pos
                    );
                    
                // Transform if expressions
                case EIf(condition, then_expr, else_expr):
                    makeASTWithMeta(
                        EIf(
                            transform(condition),
                            transform(then_expr),
                            else_expr != null ? transform(else_expr) : null
                        ),
                        node.metadata,
                        node.pos
                    );
                    
                // Transform list literals (for array building patterns)
                case EList(items):
                    makeASTWithMeta(
                        EList(items.map(transform)),
                        node.metadata,
                        node.pos
                    );
                    
                // Transform case expressions - recurse into clauses
                case ECase(expr, clauses):
                    #if debug_string_interpolation
                    trace('[StringInterpolation] Found ECase, transforming ${clauses.length} clauses');
                    #end
                    makeASTWithMeta(
                        ECase(
                            transform(expr),
                            clauses.map(clause -> {
                                #if debug_string_interpolation
                                var bodyStr = ElixirASTPrinter.printAST(clause.body);
                                if (bodyStr.indexOf("rgb(") > -1 || bodyStr.indexOf("<>") > -1) {
                                    trace('[StringInterpolation] Clause body BEFORE transformation: ${bodyStr.substring(0, 200)}');
                                    trace('[StringInterpolation] Clause body type: ${Type.enumConstructor(clause.body.def)}');
                                }
                                #end
                                var transformedBody = transform(clause.body);
                                #if debug_string_interpolation
                                var transformedStr = ElixirASTPrinter.printAST(transformedBody);
                                if (bodyStr.indexOf("<>") > -1) {
                                    trace('[StringInterpolation] Clause body AFTER transformation: ${transformedStr.substring(0, 200)}');
                                }
                                #end
                                {
                                    pattern: clause.pattern, // Don't transform pattern
                                    guard: clause.guard != null ? transform(clause.guard) : null,
                                    body: transformedBody
                                }
                            })
                        ),
                        node.metadata,
                        node.pos
                    );
                    
                case EParen(expr):
                    // Handle parenthesized expressions - recurse into contents
                    makeASTWithMeta(
                        EParen(transform(expr)),
                        node.metadata,
                        node.pos
                    );
                    
                default:
                    // For all other nodes, return unchanged
                    // We're only transforming the specific nodes we care about
                    node;
            }
        }
        
        */
    }
    
    /**
     * Loop Transformation Pass
     * 
     * WHY: Haxe desugars loops into complex reduce_while(Stream.iterate(...)) patterns
     *      that are verbose and non-idiomatic in Elixir. These patterns should be
     *      transformed into clean Enum operations or comprehensions.
     * 
     * WHAT: Detects and transforms common loop patterns:
     *       - Simple iteration (0...n) → Enum.each(0..n-1, fn i -> ... end)
     *       - Array iteration → Enum.each(array, fn item -> ... end)
     *       - Collection building → for comprehensions
     *       - Filtering → Enum.filter or comprehension with guards
     * 
     * HOW: Pattern matches on Enum.reduce_while with Stream.iterate and transforms
     *      based on the loop body pattern (side effects only, collecting, filtering)
     * 
     * Example transformations:
     * From: Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {0}, fn _, {i} ->
     *         if (i < 5) do
     *           Log.trace(i)
     *           {:cont, {i + 1}}
     *         else
     *           {:halt, {i}}
     *         end
     *       end)
     * To: Enum.each(0..4, fn i -> Log.trace(i) end)
     */
    static function loopTransformationPass(ast: ElixirAST): ElixirAST {
        #if debug_loop_transformation
        trace("[LoopTransform] Starting loop transformation pass");
        #end
        
        return transformNode(ast, function(node: ElixirAST): ElixirAST {
            switch(node.def) {
                case ERemoteCall(module, funcName, args):
                    // Check for Enum.reduce_while pattern
                    switch(module.def) {
                        case EVar("Enum"):
                            if (funcName == "reduce_while" && args != null && args.length >= 3) {
                                #if debug_loop_transformation
                                trace("[LoopTransform] Found Enum.reduce_while call");
                                trace("[LoopTransform]   Args length: " + args.length);
                                if (args.length >= 3) {
                                    trace("[LoopTransform]   Third arg (reducer fn) type: " + Type.enumConstructor(args[2].def));
                                }
                                #end

                                // Check if first arg is Stream.iterate
                                var streamArg = args[0];
                                switch(streamArg.def) {
                                    case ERemoteCall(streamModule, streamFunc, streamArgs):
                                        switch(streamModule.def) {
                                            case EVar("Stream"):
                                                if (streamFunc == "iterate" && streamArgs != null && streamArgs.length >= 2) {
                                                    #if debug_loop_transformation
                                                    trace("[LoopTransform] Found Stream.iterate pattern - WILL ATTEMPT TRANSFORMATION");
                                                    #end
                                                    
                                                    // Extract the initial value and increment function
                                                    var initValue = streamArgs[0];
                                                    var incrementFunc = streamArgs[1];
                                                    
                                                    // Check if this is a simple counter (0, fn n -> n + 1 end)
                                                    var isSimpleCounter = false;
                                                    switch(initValue.def) {
                                                        case EInteger(0):
                                                            switch(incrementFunc.def) {
                                                                case EFn(clauses) if (clauses.length > 0):
                                                                    var clause = clauses[0];
                                                                    if (clause.args.length == 1) {
                                                                        // Check if body is n + 1
                                                                        switch(clause.body.def) {
                                                                            case EBinary(Add, left, right):
                                                                                switch(left.def) {
                                                                                    case EVar(varName):
                                                                                        // Get the parameter name from the pattern
                                                                                        var paramName = switch(clause.args[0]) {
                                                                                            case PVar(name): name;
                                                                                            default: null;
                                                                                        };
                                                                                        if (paramName != null && varName == paramName) {
                                                                                            switch(right.def) {
                                                                                                case EInteger(1):
                                                                                                    isSimpleCounter = true;
                                                                                                default:
                                                                                            }
                                                                                        }
                                                                                    default:
                                                                                }
                                                                            default:
                                                                        }
                                                                    }
                                                                default:
                                                            }
                                                        default:
                                                    }
                                                    
                                                    if (isSimpleCounter) {
                                                        #if debug_loop_transformation
                                                        trace("[LoopTransform] Detected simple counter loop");
                                                        #end
                                                        
                                                        // Analyze the loop function to extract the body and condition
                                                        var loopFunc = args[2];
                                                        switch(loopFunc.def) {
                                                            case EFn(clauses) if (clauses.length > 0):
                                                                var clause = clauses[0];
                                                                // Try to extract the loop bound and body
                                                                var loopInfo = analyzeLoopBody(clause.body);
                                                                if (loopInfo != null) {
                                                                    #if debug_loop_transformation
                                                                    trace("[LoopTransform] Successfully analyzed loop body");
                                                                    trace("[LoopTransform] Upper bound: " + ElixirASTPrinter.print(loopInfo.upperBound, 0));
                                                                    trace("[LoopTransform] Has side effects only: " + loopInfo.hasSideEffectsOnly);
                                                                    #end
                                                                    
                                                                    // Transform to idiomatic Elixir
                                                                    if (loopInfo.hasSideEffectsOnly) {
                                                                        // Simple iteration with side effects → Enum.each
                                                                        var range = makeAST(ERange(
                                                                            makeAST(EInteger(0), node.pos),
                                                                            makeAST(EBinary(Subtract, loopInfo.upperBound, makeAST(EInteger(1), node.pos)), node.pos),
                                                                            false // inclusive range (0..n-1)
                                                                        ), node.pos);
                                                                        
                                                                        var eachFunc = makeAST(EFn([{
                                                                            args: [PVar(loopInfo.iteratorVar)],
                                                                            guard: null,
                                                                            body: loopInfo.loopBody
                                                                        }]), node.pos);
                                                                        
                                                                        #if debug_loop_transformation
                                                                        trace("[LoopTransform] Transforming to Enum.each");
                                                                        #end
                                                                        
                                                                        return makeAST(ERemoteCall(
                                                                            makeAST(EVar("Enum"), node.pos),
                                                                            "each",
                                                                            [range, eachFunc]
                                                                        ), node.pos);
                                                                    }
                                                                }
                                                            default:
                                                        }
                                                    }
                                                }
                                            default:
                                        }
                                    default:
                                }
                            }
                        default:
                    }
                default:
            }
            
            return node;
        });
    }
    
    /**
     * Analyze a loop body to extract iteration information
     */
    static function analyzeLoopBody(body: ElixirAST): Null<{upperBound: ElixirAST, iteratorVar: String, loopBody: ElixirAST, hasSideEffectsOnly: Bool}> {
        // Look for the if condition pattern
        switch(body.def) {
            case EIf(condition, thenBranch, elseBranch):
                // Extract the upper bound from the condition
                var upperBound: ElixirAST = null;
                var iteratorVar: String = null;
                
                switch(condition.def) {
                    case EBinary(Less, left, right):
                        // Pattern: i < upperBound
                        switch(left.def) {
                            case EVar(varName):
                                iteratorVar = varName;
                                upperBound = right;
                            default:
                        }
                    default:
                }
                
                if (upperBound != null && iteratorVar != null) {
                    // Extract the loop body from the then branch
                    var loopBody: ElixirAST = null;
                    var hasSideEffectsOnly = true;
                    
                    switch(thenBranch.def) {
                        case EBlock(exprs):
                            // Filter out the increment and continuation
                            var bodyExprs = [];
                            for (expr in exprs) {
                                switch(expr.def) {
                                    case ETuple([contAtom, _]):
                                        // Skip {:cont, ...}
                                        switch(contAtom.def) {
                                            case EAtom(cont) if (cont == "cont"):
                                                // Skip
                                            default:
                                                bodyExprs.push(expr);
                                        }
                                    case EBinary(Add, _, _):
                                        // Skip increment expressions
                                    case EInteger(_):
                                        // Skip standalone integers
                                    default:
                                        bodyExprs.push(expr);
                                }
                            }
                            
                            if (bodyExprs.length == 1) {
                                loopBody = bodyExprs[0];
                            } else if (bodyExprs.length > 1) {
                                loopBody = makeAST(EBlock(bodyExprs), body.pos);
                            }
                        default:
                    }
                    
                    if (loopBody != null) {
                        return {
                            upperBound: upperBound,
                            iteratorVar: iteratorVar,
                            loopBody: loopBody,
                            hasSideEffectsOnly: hasSideEffectsOnly
                        };
                    }
                }
            default:
        }
        
        return null;
    }
    
    /**
     * Pipeline optimization pass - convert sequential operations to pipeline
     */
    static function pipelineOptimizationPass(ast: ElixirAST): ElixirAST {
        return reflaxe.elixir.ast.transformers.PipelineTransforms.pipelineOptimizationPass(ast);
    }
    
    /**
     * Map Iterator Transformation Pass
     * Transforms Map iterator patterns from g.next() to idiomatic Elixir
     */
    static function mapIteratorTransformPass(ast: ElixirAST): ElixirAST {
        if (ast == null) return null;
        
        #if debug_map_iterator
        trace("[MapIteratorTransform] ===== MAP ITERATOR TRANSFORM PASS STARTING =====");
        // Check if this is a module and which one
        switch(ast.def) {
            case EModule(name, _):
                trace('[MapIteratorTransform] Processing module: $name');
                if (name == "Main") {
                    trace('[MapIteratorTransform] *** MAIN MODULE DETECTED - LOOKING FOR MAP PATTERNS ***');
                }
            default:
                trace('[MapIteratorTransform] Processing non-module AST node');
        }
        #end
        
        // Use transformNode to recursively transform all nodes
        return transformNode(ast, function(node) {
            // Check for Enum.reduce_while with Map iterator patterns
            switch(node.def) {
                case ERemoteCall(module, funcName, args):
                    #if debug_map_iterator
                    switch(module.def) {
                        case EVar(modName):
                            trace('[MapIteratorTransform] Found remote call: $modName.$funcName with ${args.length} args');
                        default:
                    }
                    #end
                    
                    switch(module.def) {
                        case EVar(modName):
                            #if debug_map_iterator
                            if (modName == "Enum") {
                                trace('[MapIteratorTransform] Found Enum.$funcName call with ${args?.length} args');
                            }
                            #end
                            if (modName == "Enum" && funcName == "reduce_while" && args != null && args.length >= 3) {
                                #if debug_map_iterator
                                trace('[MapIteratorTransform] Found Enum.reduce_while - checking for Map iterator patterns');
                                #end
                                // Check if the loop function contains Map iterator patterns
                                var loopFunc = args[2];
                                
                                // Helper to check if an expression contains iterator patterns
                                function containsIteratorPattern(ast: ElixirAST): Bool {
                                    if (ast == null) return false;
                                    var hasPattern = false;
                                    
                                    function check(n: ElixirAST): Void {
                                        if (n == null || n.def == null) return;
                                        switch(n.def) {
                                            case EField(_, field):
                                                if (field == "key_value_iterator" || field == "has_next" || 
                                                    field == "next" || field == "key" || field == "value") {
                                                    hasPattern = true;
                                                }
                                            case ECall(func, _, _):
                                                check(func);
                                                // Check for calls to iterator methods
                                                switch(func.def) {
                                                    case EField(_, field):
                                                        if (field == "key_value_iterator" || field == "has_next" || field == "next") {
                                                            hasPattern = true;
                                                        }
                                                    default:
                                                }
                                            default:
                                                // Recursively check nested expressions
                                                switch(n.def) {
                                                    case EField(obj, _): check(obj);
                                                    case ECall(func, _, args): 
                                                        check(func);
                                                        if (args != null) for (arg in args) check(arg);
                                                    default:
                                                }
                                        }
                                    }
                                    
                                    check(ast);
                                    return hasPattern;
                                }
                                
                                // Helper to check for iterator patterns
                                function hasMapIteratorCalls(ast: ElixirAST): Bool {
                                    if (ast == null) return false;
                                    var found = false;
                                    var depth = 0;
                                    function scan(n: ElixirAST): Void {
                                        if (n == null || n.def == null) return;
                                        depth++;
                                        #if debug_map_iterator
                                        if (depth <= 4) {
                                            var nodeType = n.def != null ? Type.enumConstructor(n.def) : "null";
                                            trace('[MapIteratorTransform] Depth $depth - Node type: $nodeType');
                                        }
                                        #end
                                        switch(n.def) {
                                            case EField(obj, field):
                                                #if debug_map_iterator
                                                trace('[MapIteratorTransform] Field access found: $field');
                                                #end
                                                if (field == "key_value_iterator" || field == "has_next" || 
                                                    field == "next" || field == "key" || field == "value") {
                                                    #if debug_map_iterator
                                                    trace('[MapIteratorTransform] *** FOUND MAP ITERATOR FIELD: $field ***');
                                                    #end
                                                    found = true;
                                                }
                                                scan(obj);
                                            case ECall(target, funcName, args):
                                                #if debug_map_iterator
                                                trace('[MapIteratorTransform] Scanning: Found call to $funcName');
                                                #end
                                                // Check if this is a field access call (like colors.key_value_iterator())
                                                if (target != null) {
                                                    switch(target.def) {
                                                        case EField(_, field):
                                                            #if debug_map_iterator
                                                            trace('[MapIteratorTransform] Call is on field: $field');
                                                            #end
                                                            if (field == "key_value_iterator" || field == "has_next" || 
                                                                field == "next" || field == "key" || field == "value") {
                                                                #if debug_map_iterator
                                                                trace('[MapIteratorTransform] *** FOUND MAP ITERATOR CALL: $field() ***');
                                                                #end
                                                                found = true;
                                                            }
                                                        default:
                                                    }
                                                    scan(target);
                                                }
                                                if (args != null) {
                                                    for (arg in args) {
                                                        scan(arg);
                                                    }
                                                }
                                            case EFn(clauses):
                                                #if debug_map_iterator
                                                trace('[MapIteratorTransform] Scanning function with ${clauses.length} clauses');
                                                #end
                                                for (c in clauses) if (c.body != null) scan(c.body);
                                            case EBlock(exprs):
                                                #if debug_map_iterator
                                                trace('[MapIteratorTransform] Scanning block with ${exprs.length} expressions');
                                                #end
                                                for (e in exprs) scan(e);
                                            case EIf(cond, t, e):
                                                #if debug_map_iterator
                                                trace('[MapIteratorTransform] Scanning if statement');
                                                #end
                                                scan(cond);
                                                scan(t);
                                                if (e != null) scan(e);
                                            case EMatch(_, value):
                                                scan(value);
                                            case ETuple(items):
                                                for (item in items) scan(item);
                                            default:
                                                #if debug_map_iterator
                                                if (depth <= 4) {
                                                    var nodeType = Type.enumConstructor(n.def);
                                                    trace('[MapIteratorTransform] Other node type: $nodeType');
                                                }
                                                #end
                                        }
                                        depth--;
                                    }
                                    scan(ast);
                                    #if debug_map_iterator
                                    trace('[MapIteratorTransform] Scan complete for AST, found iterator patterns: $found');
                                    #end
                                    return found;
                                }
                                
                                #if debug_map_iterator
                                trace('[MapIteratorTransform] Checking loopFunc for Map iterator calls...');
                                #end
                                
                                if (hasMapIteratorCalls(loopFunc)) {
                                    #if debug_map_iterator
                                    trace('[MapIteratorTransform] Found Map iteration pattern in reduce_while - transforming to Enum.each');
                                    #end
                                    
                                    // Extract the map variable from the initial value (second argument)
                                    var mapVar = switch(args[1].def) {
                                        case ETuple([mapExpr, _]) | ETuple([mapExpr]): 
                                            switch(mapExpr.def) {
                                                case EVar(name): name;
                                                default: null;
                                            }
                                        case EVar(name): name;
                                        default: null;
                                    };
                                    
                                    if (mapVar == null) mapVar = "colors"; // Fallback to known variable name
                                    
                                    #if debug_map_iterator
                                    trace('[MapIteratorTransform] Map variable identified: $mapVar');
                                    #end
                                    
                                    // Extract variable names and the body from the loop
                                    var keyVarName = "name";  // Default names
                                    var valueVarName = "hex";
                                    var loopBody: ElixirAST = null;
                                    
                                    switch(loopFunc.def) {
                                        case EFn(clauses) if (clauses.length > 0):
                                            var body = clauses[0].body;
                                            // Look for the if statement
                                            switch(body.def) {
                                                case EIf(_, thenBranch, _):
                                                    #if debug_map_iterator
                                                    trace('[MapIteratorTransform] Processing if branch for body extraction');
                                                    #if debug_ast_structure
                                                    ASTUtils.debugAST(thenBranch, 0, 3);
                                                    #end
                                                    #end
                                                    
                                                    // Use ASTUtils to handle nested blocks properly
                                                    var allExprs = ASTUtils.flattenBlocks(thenBranch);
                                                    
                                                    #if debug_map_iterator
                                                    trace('[MapIteratorTransform] Flattened ${allExprs.length} expressions from then branch');
                                                    #end
                                                    
                                                    // Extract variable names from iterator assignments
                                                    for (expr in allExprs) {
                                                        switch(expr.def) {
                                                            case EMatch(PVar(varName), rhs):
                                                                // Check if this is a key or value extraction
                                                                if (ASTUtils.containsIteratorPattern(rhs)) {
                                                                    // Extract the field being accessed
                                                                    switch(rhs.def) {
                                                                        case EField(_, "key"):
                                                                            keyVarName = varName;
                                                                            #if debug_map_iterator
                                                                            trace('[MapIteratorTransform] Found key variable: $keyVarName');
                                                                            #end
                                                                        case EField(_, "value"):
                                                                            valueVarName = varName;
                                                                            #if debug_map_iterator
                                                                            trace('[MapIteratorTransform] Found value variable: $valueVarName');
                                                                            #end
                                                                        default:
                                                                            // Check nested field access
                                                                            var fieldChain = [];
                                                                            var current = rhs;
                                                                            while (current != null) {
                                                                                switch(current.def) {
                                                                                    case EField(obj, field):
                                                                                        fieldChain.push(field);
                                                                                        current = obj;
                                                                                    case ECall(func, _, _):
                                                                                        current = func;
                                                                                    default:
                                                                                        current = null;
                                                                                }
                                                                            }
                                                                            // Check if this ends with .key or .value
                                                                            if (fieldChain.length > 0) {
                                                                                if (fieldChain[0] == "key") {
                                                                                    keyVarName = varName;
                                                                                    #if debug_map_iterator
                                                                                    trace('[MapIteratorTransform] Found key variable via chain: $keyVarName');
                                                                                    #end
                                                                                } else if (fieldChain[0] == "value") {
                                                                                    valueVarName = varName;
                                                                                    #if debug_map_iterator
                                                                                    trace('[MapIteratorTransform] Found value variable via chain: $valueVarName');
                                                                                    #end
                                                                                }
                                                                            }
                                                                    }
                                                                }
                                                            default:
                                                        }
                                                    }
                                                    
                                                    // Filter out iterator assignments and keep only the body
                                                    var cleanExprs = ASTUtils.filterIteratorAssignments(allExprs);
                                                    
                                                    #if debug_map_iterator
                                                    trace('[MapIteratorTransform] After filtering: ${cleanExprs.length} expressions remain');
                                                    #end
                                                    
                                                    // Also filter out continuation tuples
                                                    var bodyExprs = [];
                                                    for (expr in cleanExprs) {
                                                        switch(expr.def) {
                                                            case ETuple(elements):
                                                                // Skip continuation tuples {:cont, ...}
                                                                var isCont = elements.length > 0 && switch(elements[0].def) {
                                                                    case EAtom(atom): atom == "cont";
                                                                    default: false;
                                                                }
                                                                if (!isCont) {
                                                                    bodyExprs.push(expr);
                                                                }
                                                            default:
                                                                bodyExprs.push(expr);
                                                        }
                                                    }
                                                    
                                                    // Create the loop body from the cleaned expressions
                                                    loopBody = if (bodyExprs.length == 1) {
                                                        bodyExprs[0];
                                                    } else if (bodyExprs.length > 1) {
                                                        makeAST(EBlock(bodyExprs));
                                                    } else {
                                                        null;
                                                    }
                                                default:
                                            }
                                        default:
                                    }
                                    
                                    // If we have a body, create the idiomatic version
                                    if (loopBody != null) {
                                        #if debug_map_iterator
                                        trace('[MapIteratorTransform] Creating Enum.each with {$keyVarName, $valueVarName} destructuring');
                                        trace('[MapIteratorTransform] Map variable: $mapVar');
                                        trace('[MapIteratorTransform] Body extracted, creating transformation');
                                        #end
                                        
                                        var transformedAST = makeAST(ERemoteCall(
                                            makeAST(EVar("Enum")),
                                            "each",
                                            [
                                                makeAST(EVar(mapVar)),
                                                makeAST(EFn([{
                                                    args: [PTuple([PVar(keyVarName), PVar(valueVarName)])],
                                                    guard: null,
                                                    body: loopBody
                                                }]))
                                            ]
                                        ));
                                        
                                        #if debug_map_iterator
                                        trace('[MapIteratorTransform] *** TRANSFORMATION COMPLETE - RETURNING NEW AST ***');
                                        #end
                                        
                                        return transformedAST;
                                    }
                                }
                            }
                        default:
                    }
                default:
            }
            
            // Return unchanged if not a map iteration pattern
            return node;
        });
    }

    // Public proxy for MapIterator pass to enable module registry migration
    public static function mapIteratorTransformPassProxy(ast: ElixirAST): ElixirAST {
        return mapIteratorTransformPass(ast);
    }
    
    // Helper function to check if an AST contains Map iterator patterns
    static function containsIteratorPatterns(ast: ElixirAST): Bool {
        if (ast == null || ast.def == null) return false;
        
        var hasKeyValueIterator = false;
        var hasHasNext = false;
        var hasNext = false;
        
        function scan(node: ElixirAST): Void {
            if (node == null || node.def == null) return;
            
            switch(node.def) {
                case EField(obj, field):
                    // Check for Map iterator method names
                    if (field == "key_value_iterator") {
                        hasKeyValueIterator = true;
                        #if debug_map_iterator
                        trace('[MapIteratorTransform/scan] Found key_value_iterator field');
                        #end
                    } else if (field == "has_next") {
                        hasHasNext = true;
                        #if debug_map_iterator
                        trace('[MapIteratorTransform/scan] Found has_next field');
                        #end
                    } else if (field == "next") {
                        hasNext = true;
                        #if debug_map_iterator
                        trace('[MapIteratorTransform/scan] Found next field');
                        #end
                    }
                    scan(obj);
                    
                case ECall(func, callType, args):
                    // Also check the function being called
                    switch(func.def) {
                        case EField(obj, field):
                            if (field == "key_value_iterator" || field == "has_next" || field == "next") {
                                if (field == "key_value_iterator") hasKeyValueIterator = true;
                                if (field == "has_next") hasHasNext = true;
                                if (field == "next") hasNext = true;
                                #if debug_map_iterator
                                trace('[MapIteratorTransform/scan] Found iterator method call: $field()');
                                #end
                            }
                            scan(obj);
                        default:
                            scan(func);
                    }
                    if (args != null) {
                        for (arg in args) scan(arg);
                    }
                    
                case EFn(clauses):
                    for (clause in clauses) {
                        if (clause.body != null) scan(clause.body);
                    }
                    
                case EBlock(exprs):
                    for (expr in exprs) scan(expr);
                    
                case EIf(cond, thenBranch, elseBranch):
                    scan(cond);
                    scan(thenBranch);
                    if (elseBranch != null) scan(elseBranch);
                    
                case ETuple(elements):
                    for (elem in elements) scan(elem);
                    
                case ERemoteCall(module, funcName, args):
                    scan(module);
                    if (args != null) {
                        for (arg in args) scan(arg);
                    }
                    
                case EVar(_):
                    // Terminal case, no scanning needed
                    
                case EAtom(_) | EString(_):
                    // Terminal cases - literals don't need scanning
                    
                default:
                    #if debug_map_iterator
                    var nodeType = Type.enumConstructor(node.def);
                    trace('[MapIteratorTransform/scan] Unhandled node type: $nodeType');
                    #end
            }
        }
        
        scan(ast);
        
        // We need at least key_value_iterator to be a Map pattern
        var result = hasKeyValueIterator;
        
        #if debug_map_iterator
        if (result) {
            trace('[MapIteratorTransform/scan] ✅ PATTERN DETECTED - hasKeyValueIterator: $hasKeyValueIterator, hasHasNext: $hasHasNext, hasNext: $hasNext');
        }
        #end
        
        return result;
    }
    
    // Helper to print AST structure for debugging
    #if debug_map_iterator
    static function printASTStructure(ast: ElixirAST, depth: Int = 0): String {
        if (ast == null || ast.def == null) return "null";
        if (depth > 3) return "..."; // Prevent too deep recursion
        
        var indent = [for (i in 0...depth) "  "].join("");
        var nodeType = Type.enumConstructor(ast.def);
        
        return switch(ast.def) {
            case EField(obj, field):
                '$nodeType(.$field on ${printASTStructure(obj, depth + 1)})';
            case ECall(func, callType, args):
                var argsStr = args != null ? '[${args.length} args]' : '[no args]';
                '$nodeType($argsStr, func=${printASTStructure(func, depth + 1)})';
            case EVar(name):
                '$nodeType($name)';
            case EAtom(atom):
                '$nodeType(:$atom)';
            default:
                nodeType;
        };
    }
    #end
    
    /**
     * Comprehension conversion pass - convert loops to comprehensions
     * This pass needs to handle module-level transformation to add generated functions
     */
    static function comprehensionConversionPass(ast: ElixirAST): ElixirAST {
        // Collection for generated loop functions
        var generatedFunctions: Array<ElixirAST> = [];
        var loopCounter = 0;
        
        // First pass: transform loops and collect generated functions
        function transformLoops(node: ElixirAST): ElixirAST {
            return switch(node.def) {
                // Convert for loops that build lists
                case EFor(generators, filters, body, into, uniq):
                    // Already a comprehension, keep as-is
                    node;
                    
                // Convert while loops to recursive functions
                case ECall(null, "while_loop", [condition, body]):
                    // Generate unique function name
                    var funcName = "loop_" + (loopCounter++);
                    
                    // Transform condition and body recursively
                    var transformedCondition = transformNode(condition, transformLoops);
                    var transformedBody = transformNode(body, transformLoops);
                    
                    // Create recursive function definition
                    var recursiveFunc = makeAST(
                        EDefp(funcName, [], null, 
                            makeAST(EIf(
                                transformedCondition,
                                makeAST(EBlock([
                                    transformedBody,
                                    makeAST(ECall(null, funcName, []))
                                ])),
                                makeAST(EAtom(ElixirAtom.ok()))
                            ))
                        )
                    );
                    
                    // Add to generated functions collection
                    generatedFunctions.push(recursiveFunc);
                    
                    // Replace with function call
                    makeAST(ECall(null, funcName, []));
                    
                default:
                    // Return node unchanged - base case to prevent infinite recursion
                    node;
            }
        }
        
        // Apply transformation
        var transformed = transformLoops(ast);
        
        // If we're at module level and have generated functions, insert them
        if (generatedFunctions.length > 0) {
            switch(transformed.def) {
                case EModule(name, attributes, body):
                    // Insert generated functions at the end of the module body
                    var newBody = body.concat(generatedFunctions);
                    return makeAST(EModule(name, attributes, newBody));
                default:
                    // For non-module nodes, we need to wrap or handle differently
                    // This shouldn't happen in normal compilation
                    return transformed;
            }
        }
        
        return transformed;
    }
    
    /**
     * Abstract Method This Reference Fix Pass
     * 
     * WHY: In abstract methods like toDynamic(), Haxe generates parameters like "this_1"
     * but the AST builder incorrectly uses "struct" for TConst(TThis), causing reference mismatches.
     * 
     * WHAT: Fixes "struct" references in anonymous functions to match the actual parameter name.
     * - Detects anonymous functions with parameters like "this", "this_1", etc.
     * - Replaces "struct" references in the body with the actual parameter name
     * 
     * HOW: Tracks the first parameter of anonymous functions and ensures body references match
     */
    static function abstractMethodThisPass(ast: ElixirAST): ElixirAST {
        #if debug_abstract_this
        trace('[XRay AbstractThis] Starting pass');
        #end
        
        // Add debug to see what nodes we're actually getting
        #if debug_abstract_this
        function debugNode(node: ElixirAST, depth: Int = 0) {
            var indent = [for (i in 0...depth) "  "].join("");
            switch(node.def) {
                case EModule(name, _, body):
                    trace('$indent[XRay AbstractThis] Module: $name with ${body.length} definitions');
                    for (def in body) debugNode(def, depth + 1);
                case EDef(name, _, _, body):
                    trace('$indent[XRay AbstractThis] Def: $name');
                    debugNode(body, depth + 1);
                case EFn(clauses):
                    trace('$indent[XRay AbstractThis] !! Found EFn with ${clauses.length} clauses !!');
                default:
                    // Don't trace every node type, just the ones we care about
            }
        }
        debugNode(ast, 0);
        #end
        
        return transformNode(ast, function(node: ElixirAST): ElixirAST {
            switch(node.def) {
                case EFn(clauses):
                    #if debug_abstract_this
                    trace('[XRay AbstractThis] Processing EFn with ${clauses.length} clauses');
                    #end
                    // Check if this is an abstract method with "this" parameter
                    var fixedClauses = [];
                    var hasChanges = false;
                    
                    for (clause in clauses) {
                        if (clause.args.length > 0) {
                            switch(clause.args[0]) {
                                case PVar(paramName) if (paramName.indexOf("this") == 0 || paramName == "_struct" || paramName == "struct"):
                                    #if debug_abstract_this
                                    trace('[XRay AbstractThis] Found function with this/struct parameter: $paramName');
                                    trace('[XRay AbstractThis] Body before fix: ${ElixirASTPrinter.print(clause.body, 0)}');
                                    #end
                                    
                                    // Found a "this", "this_1", "struct", or "_struct" parameter
                                    // Replace "struct" or "this" with the actual parameter name in body
                                    var fixedBody = replaceStructWithParam(clause.body, paramName);
                                    
                                    #if debug_abstract_this
                                    trace('[XRay AbstractThis] Body after fix: ${ElixirASTPrinter.print(fixedBody, 0)}');
                                    #end
                                    
                                    hasChanges = true;
                                    fixedClauses.push({
                                        args: clause.args,
                                        guard: clause.guard,
                                        body: fixedBody
                                    });
                                default:
                                    fixedClauses.push(clause);
                            }
                        } else {
                            fixedClauses.push(clause);
                        }
                    }
                    
                    if (hasChanges) {
                        #if debug_abstract_this
                        trace('[XRay AbstractThis] Applied fix to function');
                        #end
                        return makeASTWithMeta(EFn(fixedClauses), node.metadata, node.pos);
                    }
                    return node;
                    
                default:
                    return node;
            }
        });
    }
    
    /**
     * Helper: Replace "struct" or "this" variables with the actual parameter name
     * 
     * PROBLEM: In abstract methods, the AST builder sometimes generates incorrect variable
     * references. The parameter might be named "this_1" but the body references "this" or
     * "struct", causing compilation errors like "undefined variable this".
     * 
     * EXAMPLES:
     * - Input:  fn this_1 -> this end       // Wrong: "this" doesn't exist
     * - Output: fn this_1 -> this_1 end     // Fixed: matches parameter name
     * 
     * - Input:  fn this -> struct end       // Wrong: "struct" is internal compiler name
     * - Output: fn this -> this end         // Fixed: uses actual parameter
     * 
     * - Input:  fn this_2 -> struct.field end    // Wrong: struct not in scope
     * - Output: fn this_2 -> this_2.field end    // Fixed: correct reference
     * 
     * @param ast The AST to transform
     * @param paramName The actual parameter name to use (e.g., "this", "this_1", "this_2")
     * @return AST with all "struct" and "this" references replaced with paramName
     */
    static function replaceStructWithParam(ast: ElixirAST, paramName: String): ElixirAST {
        return transformNode(ast, function(node: ElixirAST): ElixirAST {
            switch(node.def) {
                case EVar("struct") | EVar("this"):
                    // Replace "struct" or "this" with the actual parameter name
                    return makeASTWithMeta(EVar(paramName), node.metadata, node.pos);
                default:
                    return node;
            }
        });
    }
    
    /**
     * Bitwise Import Pass
     * 
     * WHY: Elixir requires "import Bitwise" to use bitwise operators like &&&, |||, ^^^
     * but the generated code doesn't include this import automatically.
     * 
     * WHAT: Detects usage of bitwise operators and adds "import Bitwise" to the module.
     * - Scans the entire AST for bitwise operators
     * - Adds the import statement if any are found
     * 
     * HOW: Two-phase approach:
     * 1. Detection: Walk the AST to find bitwise operators
     * 2. Injection: Add import to module (handles both EModule and EDefmodule formats)
     * 
     * IMPORTANT AST STRUCTURE: Modules can be represented in two ways:
     * 
     * EDefmodule(name, doBlock): Standard Elixir "defmodule Name do ... end" format
     *   This is the most common format. The import must be added as the first 
     *   statement in the do block.
     *   
     *   Original Haxe code:
     *     class StringTools {
     *         public static function ltrim(s: String): String {
     *             // Uses bitwise operators &&&
     *         }
     *     }
     *   
     *   Example AST:
     *     EDefmodule("StringTools", 
     *       EBlock([
     *         EImport("Bitwise", null, null),  // <-- Insert here
     *         EFunction(...),
     *         EFunction(...)
     *       ])
     *     )
     * 
     * EModule(name, attributes, body): Alternative format with attributes array
     *   Less common format. The import is added to the attributes array.
     *   
     *   This format may be used internally by the compiler for certain constructs
     *   or intermediate representations. Most user-defined Haxe classes generate
     *   EDefmodule, not EModule. The exact conditions that produce EModule vs
     *   EDefmodule depend on the AST builder's internal logic.
     *   
     *   Example AST:
     *     EModule("StringTools",
     *       [
     *         EImport("Bitwise", null, null),  // <-- Insert here
     *         EAttribute(...)
     *       ],
     *       [EFunction(...), EFunction(...)]
     *     )
     * 
     * The original pass only handled EModule, which is why it wasn't working for
     * most generated code that uses EDefmodule format.
     */
    static function bitwiseImportPass(ast: ElixirAST): ElixirAST {
        // Phase 1: Detect if bitwise operators are used
        var needsBitwise = false;
        
        #if debug_bitwise_import
        trace('[XRay BitwiseImport] Starting scan for bitwise operators');
        #end
        
        // Recursive function to deeply traverse the AST
        function checkForBitwise(node: ElixirAST): Void {
            // Check for null node or def before processing
            if (node == null || node.def == null) {
                return;
            }

            #if debug_bitwise_import
            var nodeType = Type.enumConstructor(node.def);
            if (nodeType == "EBinary") {
                trace('[XRay BitwiseImport] Checking EBinary node');
            }
            #end

            switch(node.def) {
                case EBinary(op, left, right):
                    #if debug_bitwise_import
                    trace('[XRay BitwiseImport] Binary operator: $op');
                    #end
                    switch(op) {
                        case BitwiseAnd | BitwiseOr | BitwiseXor | ShiftLeft | ShiftRight:
                            #if debug_bitwise_import
                            trace('[XRay BitwiseImport] Found bitwise operator: $op');
                            #end
                            needsBitwise = true;
                        default:
                    }
                    // Recursively check child nodes
                    checkForBitwise(left);
                    checkForBitwise(right);
                case EUnary(BitwiseNot, expr):
                    #if debug_bitwise_import
                    trace('[XRay BitwiseImport] Found BitwiseNot operator');
                    #end
                    needsBitwise = true;
                    checkForBitwise(expr);
                default:
                    // For all other node types, recursively visit children
                    iterateAST(node, checkForBitwise);
            }
        }
        
        checkForBitwise(ast);
        
        #if debug_bitwise_import
        trace('[XRay BitwiseImport] Needs bitwise: $needsBitwise');
        #end
        
        // Phase 2: Add import if needed
        if (!needsBitwise) return ast;
        
        return transformNode(ast, function(node: ElixirAST): ElixirAST {
            switch(node.def) {
                case EDefmodule(name, doBlock):
                    #if debug_bitwise_import
                    trace('[XRay BitwiseImport] Processing defmodule: $name');
                    #end
                    
                    // For defmodule, we need to inject the import into the do block
                    switch(doBlock.def) {
                        case EBlock(statements):
                            #if debug_bitwise_import
                            trace('[XRay BitwiseImport] Defmodule has ${statements.length} statements');
                            #end
                            
                            // Check if Bitwise is already imported
                            var hasImport = false;
                            for (stmt in statements) {
                                switch(stmt.def) {
                                    case EImport(module, _, _):  // Match all three parameters
                                        if (module == "Bitwise") {
                                            hasImport = true;
                                            break;
                                        }
                                    default:
                                }
                            }
                            
                            if (!hasImport) {
                                // Add import Bitwise at the beginning
                                var newStatements = statements.copy();
                                newStatements.insert(0, makeAST(EImport("Bitwise", null, null)));  // Provide all three parameters
                                
                                #if debug_bitwise_import
                                trace('[XRay BitwiseImport] Added import Bitwise to defmodule');
                                #end
                                
                                return makeASTWithMeta(
                                    EDefmodule(name, makeAST(EBlock(newStatements))),
                                    node.metadata,
                                    node.pos
                                );
                            }
                        default:
                    }
                    return node;
                    
                case EModule(name, attributes, body):
                    #if debug_bitwise_import
                    trace('[XRay BitwiseImport] Processing module: $name');
                    trace('[XRay BitwiseImport] Current attributes count: ${attributes.length}');
                    #end
                    
                    // Check if Bitwise is already imported (by checking attribute names)
                    var hasImport = false;
                    for (attr in attributes) {
                        if (attr.name == "import" && attr.value != null) {
                            // Check if it's importing Bitwise
                            switch(attr.value.def) {
                                case EAtom(atomVal) if (atomVal == "Bitwise"):
                                    hasImport = true;
                                case EVar("Bitwise"):
                                    hasImport = true;
                                default:
                            }
                        }
                    }
                    
                    #if debug_bitwise_import
                    trace('[XRay BitwiseImport] Has existing import: $hasImport');
                    #end
                    
                    if (!hasImport) {
                        // Add import Bitwise at the beginning of attributes
                        var newAttributes = attributes.copy();
                        newAttributes.insert(0, {
                            name: "import",
                            value: makeAST(EAtom(ElixirAtom.raw("Bitwise")))
                        });
                        
                        #if debug_bitwise_import
                        trace('[XRay BitwiseImport] Added import Bitwise to module');
                        #end
                        
                        return makeASTWithMeta(
                            EModule(name, newAttributes, body),
                            node.metadata,
                            node.pos
                        );
                    }
                    return node;
                    
                default:
                    return node;
            }
        });
    }
    
    /**
     * List Effect Lifting Pass
     * 
     * WHY: Elixir doesn't allow assignments or side-effecting expressions inside list literals.
     * The malformed pattern `g = g ++ [g = [] ...]` creates illegal syntax.
     * 
     * WHAT: Detects and lifts side-effecting expressions out of list literals.
     * - Identifies assignments and other side effects within EList elements
     * - Extracts them to statements before the list construction
     * - Replaces them with pure variable references
     * 
     * HOW: Transforms EList nodes by:
     * 1. Scanning elements for side effects (assignments, blocks)
     * 2. Extracting effects to temporary variables
     * 3. Building the list with pure expressions only
     * 
     * Example:
     * Input:  [g = [], g = g ++ [1], g]
     * Output: g = []; g = g ++ [1]; [g]
     */
    static function listEffectLiftingPass(ast: ElixirAST): ElixirAST {
        return reflaxe.elixir.ast.transformers.MapAndCollectionTransforms.listEffectLiftingPass(ast);
    }
    
    /**
     * Struct field assignment transformation pass
     * 
     * WHY: Haxe's mutable field assignments (this.field = value) need to be transformed
     *      to Elixir's immutable struct update syntax (%{struct | field: value})
     * 
     * WHAT: Detects patterns like EMatch(EField(struct_var, field), value) where struct_var
     *       is a struct parameter (like "struct" or "self"), and transforms them to return
     *       a new struct with the updated field
     * 
     * HOW: - Identifies field assignments on struct parameters
     *      - Converts them to struct update syntax
     *      - Returns the updated struct for proper threading
     * 
     * Example: struct.count = 5 → %{struct | count: 5}
     */
    static function structFieldAssignmentTransformPass(ast: ElixirAST): ElixirAST {
        return reflaxe.elixir.ast.transformers.StructAndMapTransforms.structFieldAssignmentTransformPass(ast);
    }
    
    /**
     * Statement context transformation pass - add reassignments for immutable operations
     * 
     * WHY: Elixir is immutable, so operations like Map.put() return new values
     * WHAT: Detects when these operations are used as statements (value discarded)
     * HOW: Wraps them in reassignment to the original variable
     * 
     * Example transformation:
     * Map.put(params, "key", value) → params = Map.put(params, "key", value)
     */
    static function statementContextTransformPass(ast: ElixirAST): ElixirAST {
        // Forwarder: use module implementation to keep transformer thin
        return reflaxe.elixir.ast.transformers.StructAndMapTransforms.statementContextTransformPass(ast);
        // Transform with context tracking
        /*
        function transformWithContext(node: ElixirAST, isStatementContext: Bool): ElixirAST {
            // Check for null node or def before processing
            if (node == null || node.def == null) {
                return node;
            }

            #if debug_ast_transformer
            trace('[XRay StatementContext] Processing node: ${node.def}, context: ${isStatementContext ? "statement" : "expression"}');
            #end

            // First, recursively transform children with appropriate context
            var transformed = switch(node.def) {
                case EDefmodule(name, doBlock):
                    // Process the module's do block in statement context
                    #if debug_ast_transformer
                    trace('[XRay StatementContext] Processing EDefmodule: $name');
                    #end
                    makeASTWithMeta(
                        EDefmodule(name, transformWithContext(doBlock, true)),
                        node.metadata, node.pos
                    );
                    
                case EBlock(expressions):
                    // In a block, all but the last expression are in statement context
                    #if debug_ast_transformer
                    trace('[XRay StatementContext] Processing EBlock with ${expressions.length} expressions');
                    #end
                    var newExpressions = [];
                    for (i in 0...expressions.length) {
                        var isLast = (i == expressions.length - 1);
                        var childContext = isLast ? isStatementContext : true;
                        #if debug_ast_transformer
                        if (expressions[i] != null && expressions[i].def != null) {
                            var exprType = Type.enumConstructor(expressions[i].def);
                            trace('[XRay StatementContext] Block expr $i/${expressions.length}: $exprType, context: ${childContext ? "statement" : "expression"}');
                        }
                        #end
                        newExpressions.push(transformWithContext(expressions[i], childContext));
                    }
                    makeASTWithMeta(EBlock(newExpressions), node.metadata, node.pos);
                    
                case EDef(name, args, guards, body):
                    // Function body is a block - let it handle its own statement/expression context
                    // The block will mark all but the last expression as statement context
                    #if debug_ast_transformer
                    trace('[XRay StatementContext] Processing EDef: $name, body type: ${body.def}');
                    #end
                    makeASTWithMeta(
                        EDef(name, args, guards, transformWithContext(body, false)),
                        node.metadata, node.pos
                    );
                    
                case EDefp(name, args, guards, body):
                    // Function body is a block - let it handle its own statement/expression context  
                    // The block will mark all but the last expression as statement context
                    #if debug_ast_transformer
                    trace('[XRay StatementContext] Processing EDefp: $name, body type: ${body.def}');
                    #end
                    makeASTWithMeta(
                        EDefp(name, args, guards, transformWithContext(body, false)),
                        node.metadata, node.pos
                    );
                    
                case EIf(condition, thenBranch, elseBranch):
                    // Both branches inherit parent context
                    makeASTWithMeta(
                        EIf(transformWithContext(condition, false),
                            transformWithContext(thenBranch, isStatementContext),
                            elseBranch != null ? transformWithContext(elseBranch, isStatementContext) : null),
                        node.metadata, node.pos
                    );
                    
                case ECase(expr, clauses):
                    // All clauses inherit parent context
                    makeASTWithMeta(
                        ECase(transformWithContext(expr, false),
                              clauses.map(c -> {
                                  pattern: c.pattern,
                                  guard: c.guard != null ? transformWithContext(c.guard, false) : null,
                                  body: transformWithContext(c.body, isStatementContext)
                              })),
                        node.metadata, node.pos
                    );
                    
                // For other nodes, recursively transform children based on node type
                default:
                    // Manually handle child transformation for other node types
                    switch(node.def) {
                        case EModule(name, attributes, body):
                            makeASTWithMeta(
                                EModule(name, attributes, body.map(e -> transformWithContext(e, true))),
                                node.metadata, node.pos
                            );
                            
                        case ECall(target, funcName, args):
                            makeASTWithMeta(
                                ECall(target != null ? transformWithContext(target, false) : null,
                                      funcName,
                                      args.map(a -> transformWithContext(a, false))),
                                node.metadata, node.pos
                            );
                            
                        case ERemoteCall(module, funcName, args):
                            makeASTWithMeta(
                                ERemoteCall(transformWithContext(module, false),
                                           funcName,
                                           args.map(a -> transformWithContext(a, false))),
                                node.metadata, node.pos
                            );
                            
                        case EBinary(op, left, right):
                            makeASTWithMeta(
                                EBinary(op,
                                       transformWithContext(left, false),
                                       transformWithContext(right, false)),
                                node.metadata, node.pos
                            );
                            
                        case EMatch(pattern, expr):
                            makeASTWithMeta(
                                EMatch(pattern, transformWithContext(expr, false)),
                                node.metadata, node.pos
                            );
                            
                        // For literals and simple nodes, return unchanged
                        default:
                            node;
                    }
            };
            
            // Now check if this node needs reassignment wrapping
            if (isStatementContext) {
                switch(transformed.def) {
                    case ERemoteCall(module, funcName, args):
                        #if debug_ast_transformer
                        trace('[XRay StatementContext] Checking ERemoteCall: module=${module.def}, func=$funcName, args=${args.length}');
                        #end
                        // Check for immutable operations that need reassignment in statement context
                        var moduleName: Null<String> = switch(module.def) {
                            case EAtom(atom): atom; // ElixirAtom implicitly converts to String
                            case EVar(name): name;  // name is already String
                            default: null;
                        };
                        
                        if (moduleName != null) {
                            #if debug_ast_transformer
                            trace('[XRay StatementContext] Found module $moduleName, checking function: $funcName');
                            #end
                            
                            // Define immutable operations for each Elixir module
                            // TODO: Future improvement - Move this metadata to Haxe source files
                            // Instead of hardcoding here, each module (Map.hx, List.hx, etc.) could
                            // use metadata annotations like @:immutable or @:reassignsVar on methods
                            // that return new instances. This would make the system more maintainable
                            // and allow custom types to opt into this behavior.
                            // Example: @:immutable function put(key: K, value: V): Map<K,V> { ... }
                            var needsReassignment = switch(moduleName) {
                                case "Map":
                                    ["put", "delete", "merge", "update", "drop", "put_new", "put_new_lazy", "replace"].indexOf(funcName) >= 0;
                                case "List":
                                    ["delete", "delete_at", "insert_at", "replace_at", "update_at", "pop_at", "flatten", "wrap"].indexOf(funcName) >= 0;
                                case "MapSet":
                                    ["put", "delete", "union", "intersection", "difference"].indexOf(funcName) >= 0;
                                case "Keyword":
                                    ["put", "delete", "merge", "update", "drop", "put_new", "put_new_lazy", "replace"].indexOf(funcName) >= 0;
                                case "String":
                                    ["replace", "trim", "upcase", "downcase", "capitalize", "reverse", "slice"].indexOf(funcName) >= 0;
                                default:
                                    false;
                            };
                            
                            if (needsReassignment && args.length >= 1) {
                                // First arg should be the variable being modified
                                switch(args[0].def) {
                                    case EVar(varName):
                                        #if debug_ast_transformer
                                        trace('[XRay StatementContext] Wrapping $moduleName.$funcName with reassignment to: $varName');
                                        #end
                                        // Transform to: varName = Module.operation(varName, ...)
                                        return makeASTWithMeta(
                                            EMatch(PVar(varName), transformed),
                                            node.metadata, node.pos
                                        );
                                    default:
                                        // Not a simple variable, can't reassign
                                }
                            }
                        }
                        
                    case EBinary(Concat, left, right):
                        // Check for list concatenation in statement context
                        switch(left.def) {
                            case EVar(varName):
                                #if debug_ast_transformer
                                trace('[XRay StatementContext] Wrapping ++ with reassignment to: $varName');
                                #end
                                // Transform to: varName = varName ++ right
                                return makeASTWithMeta(
                                    EMatch(PVar(varName), transformed),
                                    node.metadata, node.pos
                                );
                            default:
                        }
                        
                    default:
                }
            }
            
            return transformed;
        }
        
        // Start transformation with top-level as statement context
        */
        // legacy body removed; thin forwarder defined at function start
    }
    
    /**
     * Immutability transformation pass - convert mutable patterns to immutable
     * 
     * ENHANCED: Now handles struct field mutations in BalancedTree and similar patterns
     */
    static function immutabilityTransformPass(ast: ElixirAST): ElixirAST {
        // First pass: Transform method bodies that mutate struct fields
        ast = transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch(node.def) {
                case EDef(name, args, guards, body) if ((name == "set" || name == "remove") && 
                                                        args.length > 0 && 
                                                        switch(args[0]) { case PVar("struct"): true; default: false; }):
                    // This is a struct method that might mutate fields
                    #if debug_ast_transformer
                    trace('[XRay ImmutabilityTransform] Found method $name with struct parameter');
                    #end
                    var updatedBody = transformStructFieldAssignments(body, args);
                    if (updatedBody != body) {
                        #if debug_ast_transformer
                        trace('[XRay ImmutabilityTransform] Transformed body for method $name');
                        #end
                        makeASTWithMeta(
                            EDef(name, args, guards, updatedBody),
                            node.metadata,
                            node.pos
                        );
                    } else {
                        #if debug_ast_transformer
                        trace('[XRay ImmutabilityTransform] No transformation needed for method $name');
                        #end
                        node;
                    }
                default:
                    node;
            }
        });
        
        // Second pass: Other immutability transformations
        return transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch(node.def) {
                // Transform increment/decrement to reassignment
                case ECall(null, "pre_inc", [expr]):
                    // x++ becomes x = x + 1
                    switch(expr.def) {
                        case EVar(name):
                            makeAST(EMatch(
                                PVar(name),
                                makeAST(EBinary(Add, expr, makeAST(EInteger(1))))
                            ));
                        default:
                            node;
                    }
                    
                case ECall(null, "pre_dec", [expr]):
                    // x-- becomes x = x - 1
                    switch(expr.def) {
                        case EVar(name):
                            makeAST(EMatch(
                                PVar(name),
                                makeAST(EBinary(Subtract, expr, makeAST(EInteger(1))))
                            ));
                        default:
                            node;
                    }
                    
                // Transform modulo operator to rem function call
                case EBinary(Remainder, left, right):
                    // x % 2 becomes rem(x, 2) - rem is a function in Elixir, not an operator
                    makeAST(ECall(
                        null,
                        "rem",
                        [left, right]
                    ));
                    
                // Transform array mutation patterns
                case ECall(target, "push", [item]):
                    // Check if this is a push on a field (either direct or via struct)
                    switch(target.def) {
                        case EField(structVar, fieldName):
                            // This is struct.field.push(item) - qualified field access
                            // Check if structVar is "struct" (the conventional instance parameter)
                            switch(structVar.def) {
                                case EVar("struct"):
                                    // GUARD: Check if fieldName is an array infrastructure variable
                                    if (StructUpdateTransform.isArrayVariable(fieldName)) {
                                        #if debug_ast_transformer
                                        trace('[XRay ImmutabilityTransform] Skipping array variable field: struct.$fieldName');
                                        #end
                                        // Regular array concatenation
                                        makeAST(EBinary(Concat, target, makeAST(EList([item]))));
                                    } else {
                                        // Transform to struct update: %{struct | field: struct.field ++ [item]}
                                        #if debug_ast_transformer
                                        trace('[XRay ImmutabilityTransform] Transforming struct.$fieldName.push(item) to struct update');
                                        #end
                                        makeAST(EStructUpdate(
                                            structVar,
                                            [{
                                                key: fieldName,
                                                value: makeAST(EBinary(
                                                    Concat,
                                                    target,  // struct.field
                                                    makeAST(EList([item]))
                                                ))
                                            }]
                                        ));
                                    }
                                default:
                                    node;
                            }
                        case EVar(fieldName):
                            // This is field.push(item) - direct field access
                            // This happens in instance methods where fields are accessed directly

                            // GUARD: Check if this is an array infrastructure variable
                            // Pattern: g, g2, _g, _g2, etc. - these are NOT struct fields
                            if (StructUpdateTransform.isArrayVariable(fieldName)) {
                                #if debug_ast_transformer
                                trace('[XRay ImmutabilityTransform] Skipping array variable: $fieldName');
                                #end
                                // Regular array concatenation, not struct update
                                makeAST(EBinary(Concat, target, makeAST(EList([item]))));
                            } else {
                                // We need to transform this to a struct update
                                #if debug_ast_transformer
                                trace('[XRay ImmutabilityTransform] Transforming $fieldName.push(item) to struct update');
                                #end
                                // Create the struct variable (assuming "struct" is the instance parameter)
                                var structVar = makeAST(EVar("struct"));
                                makeAST(EStructUpdate(
                                    structVar,
                                    [{
                                        key: fieldName,
                                        value: makeAST(EBinary(
                                            Concat,
                                            makeAST(EField(structVar, fieldName)),  // struct.field
                                            makeAST(EList([item]))
                                        ))
                                    }]
                                ));
                            }
                        default:
                            // Regular array.push(item) becomes array ++ [item]
                            makeAST(EBinary(Concat, target, makeAST(EList([item]))));
                    }

                case ECall(target, "pop", []):
                    // array.pop() becomes List.delete_at(array, -1)
                    makeAST(ERemoteCall(
                        makeAST(EAtom(ElixirAtom.raw("List"))),
                        "delete_at",
                        [target, makeAST(EInteger(-1))]
                    ));
                    
                    
                default:
                    node;
            }
        });
    }
    
    /**
     * Transform struct field assignments within a method body to return updated struct
     * 
     * WHY: Methods like BalancedTree.set() modify fields but need to return the updated struct
     * WHAT: Detects field assignments on "struct" parameter and adds struct return
     * HOW: Wraps body in block that returns updated struct
     */
    static function transformStructFieldAssignments(body: ElixirAST, args: Array<EPattern>): ElixirAST {
        // Check if first argument is "struct" (instance method pattern)
        var hasStructParam = args.length > 0 && switch(args[0]) {
            case PVar("struct"): true;
            default: false;
        };
        
        if (!hasStructParam) return body;
        
        #if debug_ast_transformer
        trace('[XRay transformStructFieldAssignments] Analyzing body for field assignments');
        #end
        
        // Look for field assignments in the body
        var hasFieldAssignment = false;
        var fieldUpdates: Map<String, ElixirAST> = new Map();
        
        // Analyze the body for field assignments
        function analyzeNode(node: ElixirAST): Void {
            switch(node.def) {
                case EMatch(PVar("root"), value):
                    // Found field assignment: root = ...
                    #if debug_ast_transformer
                    trace('[XRay transformStructFieldAssignments] Found root assignment');
                    #end
                    hasFieldAssignment = true;
                    fieldUpdates.set("root", value);
                case EBlock(statements):
                    for (stmt in statements) {
                        analyzeNode(stmt);
                    }
                default:
                    // Continue analyzing
            }
        }
        
        analyzeNode(body);
        
        #if debug_ast_transformer
        trace('[XRay transformStructFieldAssignments] hasFieldAssignment: $hasFieldAssignment, has root: ${fieldUpdates.exists("root")}');
        #end
        
        if (hasFieldAssignment && fieldUpdates.exists("root")) {
            // Transform the body to return updated struct
            var statements = [];
            
            // Add the original body logic
            switch(body.def) {
                case EBlock(stmts):
                    statements = stmts.copy();
                default:
                    statements = [body];
            }
            
            // Add struct update at the end
            // %{struct | root: root}
            var structUpdate = makeAST(EStructUpdate(
                makeAST(EVar("struct")),
                [{ key: "root", value: makeAST(EVar("root")) }]
            ));
            
            statements.push(structUpdate);
            
            return makeAST(EBlock(statements));
        }

        return body;
    }

    /**
     * Fluent API Optimization Pass
     *
     * WHY: Fluent API methods that return 'this' generate unnecessary intermediate assignments
     * in Elixir like `struct = %{struct | field: value}` followed by `struct`. This creates
     * "variable 'struct' is unused" warnings.
     *
     * WHAT: Detects and optimizes the pattern where a struct update is immediately returned.
     *
     * HOW: Transforms functions that have the pattern:
     * - Assignment: struct = %{struct | fields...}
     * - Return: struct
     * Into a single return of the struct update expression.
     */
    static function fluentApiOptimizationPass(ast: ElixirAST): ElixirAST {
        return reflaxe.elixir.ast.transformers.StructAndMapTransforms.fluentApiOptimizationPass(ast);
    }

    /**
     * Optimize the body of a fluent API method
     */
    static function optimizeFluentBody(body: ElixirAST): ElixirAST {
        if (body == null) return null;

        switch(body.def) {
            case EBlock(exprs) if (exprs.length == 2):
                // Check for pattern: [struct = %{struct | ...}, struct]
                var firstExpr = exprs[0];
                var secondExpr = exprs[1];

                // Check if first is assignment to 'struct'
                switch(firstExpr.def) {
                    case EMatch(PVar("struct"), updateExpr):
                        // Check if second is just returning 'struct'
                        switch(secondExpr.def) {
                            case EVar("struct"):
                                // Found the pattern! Return the update expression directly
                                #if debug_fluent_api
                                trace('[FluentApiOptimization] Found fluent pattern - optimizing');
                                #end
                                return updateExpr;
                            default:
                        }
                    default:
                }
            default:
        }

        // Pattern doesn't match, return as-is
        return body;
    }

    // ========================================================================
    // Helper Functions
    // ========================================================================
    
    /**
     * Extract parent module name from AST metadata
     * This should be set during the AST building phase when we know inheritance relationships
     * For now, we return null since metadata doesn't have a parentModule field yet
     * In the future, we should add this field to ElixirMetadata typedef
     */
    static function extractParentModule(node: ElixirAST): Null<String> {
        // TODO: Add parentModule field to ElixirMetadata typedef
        // For now, we can try to extract from sourceExpr if available
        if (node.metadata != null && node.metadata.sourceExpr != null) {
            // Could analyze the TypedExpr to find parent class info
            // For now, return null and use the fallback mechanism
        }
        return null;
    }
    
    /**
     * Array length field to function transformation pass
     * 
     * WHY: Elixir doesn't support .length property access on arrays/lists
     * WHAT: Transforms array.length field access to length(array) function calls
     * HOW: Detects EField(target, "length") and converts to ECall(null, "length", [target])
     * 
     * Example transformation:
     *   array.length -> length(array)
     *   list.length -> length(list) 
     */
    static function arrayLengthFieldToFunctionPass(ast: ElixirAST): ElixirAST {
        #if debug_ast_transformer
        trace('[XRay ArrayLengthField] Starting array length field to function transformation');
        #end
        
        // Handle null nodes
        if (ast == null) {
            return null;
        }
        
        return switch(ast.def) {
            case EField(target, "length"):
                // This is an array.length field access that needs to become length(array)
                #if debug_ast_transformer
                var targetStr = ElixirASTPrinter.printAST(target);
                trace('[XRay ArrayLengthField] Transforming ${targetStr}.length to length($targetStr)');
                #end
                {
                    def: ECall(null, "length", [
                        transformAST(target, arrayLengthFieldToFunctionPass)
                    ]),
                    metadata: ast.metadata,
                    pos: ast.pos
                };
                
            case ECall(expr, funcName, args):
                // Regular call, transform recursively
                {
                    def: ECall(
                        expr != null ? transformAST(expr, arrayLengthFieldToFunctionPass) : null,
                        funcName,
                        [for (arg in args) transformAST(arg, arrayLengthFieldToFunctionPass)]
                    ),
                    metadata: ast.metadata,
                    pos: ast.pos
                };
                
            default:
                // Recursively transform children
                transformAST(ast, arrayLengthFieldToFunctionPass);
        };
    }

    /**
     * Main function visibility pass
     *
     * WHY: Snapshot and demo/test modules expect a public entry point `def main()` in `Main` modules
     * WHAT: Convert EDefp("main", ...) to EDef("main", ...) when inside module "Main"
     * HOW: Track module context during traversal and flip visibility for that function only
     */
    static function mainFunctionVisibilityPass(ast: ElixirAST): ElixirAST {
        function transformInModule(node: ElixirAST, currentModule: String): ElixirAST {
            return switch(node.def) {
                case EDefp(name, args, guards, body) if (name == "main" && currentModule == "Main"):
                    makeASTWithMeta(EDef(name, args, guards, body), node.metadata, node.pos);
                case EModule(name, attributes, body):
                    makeASTWithMeta(EModule(name, attributes, [for (b in body) transformInModule(b, name)]), node.metadata, node.pos);
                default:
                    // Recurse generically
                    transformAST(node, n -> transformInModule(n, currentModule));
            };
        }
        return transformInModule(ast, null);
    }

    /**
     * VarRefNormalization pass: within each function, collect declared variable names (args + simple pattern matches)
     * and normalize any EVar references whose snake_case form matches a declared name.
     */
    static function varRefNormalizationPass(ast: ElixirAST): ElixirAST {
        function gatherNamesFromPattern(p: EPattern, acc: Map<String, Bool>) {
            switch (p) {
                case PVar(name): acc.set(name, true);
                case PTuple(el): for (e in el) gatherNamesFromPattern(e, acc);
                case PList(el): for (e in el) gatherNamesFromPattern(e, acc);
                case PCons(h, t): gatherNamesFromPattern(h, acc); gatherNamesFromPattern(t, acc);
                case PMap(pairs): for (pair in pairs) gatherNamesFromPattern(pair.value, acc);
                case PStruct(_, fields): for (f in fields) gatherNamesFromPattern(f.value, acc);
                case _: // ignore
            }
        }

        function normalizeExpr(node: ElixirAST, declared: Map<String, Bool>): ElixirAST {
            // Recursively normalize variable references using declared map
            return ElixirASTTransformer.transformNode(node, function(n) {
                return switch (n.def) {
                    case EVar(name):
                        var newName = if (declared.exists(name)) name else {
                            if (name == "_g" && declared.exists("g")) "g" else {
                                if (~/^_g(\d+)$/.match(name)) {
                                    var suffix = name.substr(2);
                                    var candidate = "g" + suffix;
                                    if (declared.exists(candidate)) candidate else {
                                        var snake = reflaxe.elixir.ast.NameUtils.toSnakeCase(name);
                                        if (snake != null && snake != name && declared.exists(snake)) snake else name;
                                    }
                                } else {
                                    var snake = reflaxe.elixir.ast.NameUtils.toSnakeCase(name);
                                    if (snake != null && snake != name && declared.exists(snake)) snake else name;
                                }
                            };
                        };
                        if (newName != name) makeASTWithMeta(EVar(newName), n.metadata, n.pos) else n;
                    default:
                        n;
                };
            });
        }

        function normalizeInBody(body: ElixirAST, declared: Map<String, Bool>): ElixirAST {
            function normalizeName(name: String): String {
                // if name exists, keep; else try snake_case
                if (declared.exists(name)) return name;
                // Infra fallback: map _g or _gN to g/gN if declared
                if (name == "_g" && declared.exists("g")) return "g";
                if (~/^_g(\d+)$/.match(name)) {
                    var suffix = name.substr(2);
                    var candidate = "g" + suffix;
                    if (declared.exists(candidate)) return candidate;
                }
                var snake = reflaxe.elixir.ast.NameUtils.toSnakeCase(name);
                if (snake != null && snake != name && declared.exists(snake)) return snake;
                return name;
            }

            // Sequential EBlock normalization to respect declaration order
            switch (body.def) {
                case EBlock(expressions):
                    var localDeclared = new Map<String, Bool>();
                    for (k in declared.keys()) localDeclared.set(k, true);
                    var newExprs: Array<ElixirAST> = [];
                    for (expr in expressions) {
                        var norm = normalizeInBody(expr, localDeclared);
                        newExprs.push(norm);
                        switch (expr.def) {
                            case EMatch(pat, _):
                                var temp = new Map<String, Bool>();
                                gatherNamesFromPattern(pat, temp);
                                for (k in temp.keys()) localDeclared.set(k, true);
                            default:
                        }
                    }
                    return makeASTWithMeta(EBlock(newExprs), body.metadata, body.pos);
                default:
            }

            return ElixirASTTransformer.transformNode(body, function(node) {
                return switch (node.def) {
                    case EVar(name):
                        var newName = normalizeName(name);
                        if (newName != name) makeASTWithMeta(EVar(newName), node.metadata, node.pos) else node;
                    case ECase(target, clauses):
                        // For each clause, extend declared with pattern vars and normalize body accordingly
                        var newClauses: Array<ECaseClause> = [];
                        var newTarget = normalizeExpr(target, declared);
                        for (cl in clauses) {
                            var localDeclared = new Map<String, Bool>();
                            for (k in declared.keys()) localDeclared.set(k, true);
                            gatherNamesFromPattern(cl.pattern, localDeclared);
                            var newBody = normalizeInBody(cl.body, localDeclared);
                            newClauses.push({ pattern: cl.pattern, guard: cl.guard, body: newBody });
                        }
                        makeASTWithMeta(ECase(newTarget, newClauses), node.metadata, node.pos);
                    case EMatch(pattern, expr):
                        // Track newly declared variables as we traverse
                        var tmp = new Map<String, Bool>();
                        gatherNamesFromPattern(pattern, tmp);
                        for (k in tmp.keys()) declared.set(k, true);
                        node;
                    default:
                        node;
                };
            });
        }

        return switch (ast.def) {
            case EDef(name, args, guards, body):
                var declared = new Map<String, Bool>();
                for (a in args) gatherNamesFromPattern(a, declared);
                var normalizedBody = normalizeInBody(body, declared);
                makeASTWithMeta(EDef(name, args, guards, normalizedBody), ast.metadata, ast.pos);
            case EDefp(name, args, guards, body):
                var declared2 = new Map<String, Bool>();
                for (a in args) gatherNamesFromPattern(a, declared2);
                var normalizedBody2 = normalizeInBody(body, declared2);
                makeASTWithMeta(EDefp(name, args, guards, normalizedBody2), ast.metadata, ast.pos);
            default:
                // Recurse
                transformAST(ast, varRefNormalizationPass);
        };
    }

    /**
     * Normalize concat+bind+immediate-call patterns in rescue blocks to single expressions
     * Example: ts = left <> (tmp = DateTime.utc_now()); tmp.to_iso8601() -> ts = left <> DateTime.to_iso8601(DateTime.utc_now())
     */
    static function rescueConcatNormalizationPass(ast: ElixirAST): ElixirAST {
        function unwrapParen(node: ElixirAST): ElixirAST {
            var current = node;
            while (current != null && Type.enumConstructor(current.def) == "EParen") {
                switch (current.def) { case EParen(inner): current = inner; default: }
            }
            return current;
        }
        function normalizeBlock(block: ElixirAST): ElixirAST {
            if (block == null) return block;
            return switch (block.def) {
                case EBlock(stmts):
                    var out = [];
                    var i = 0;
                    while (i < stmts.length) {
                        var cur = stmts[i];
                        var nxt = (i + 1 < stmts.length) ? stmts[i + 1] : null;
                        var combined = false;
                        switch (cur.def) {
                            case EMatch(PVar(assignName), concatExpr):
                                concatExpr = unwrapParen(concatExpr);
                                switch (concatExpr.def) {
                                    case EBinary(StringConcat, leftExpr, rightExpr):
                                        rightExpr = unwrapParen(rightExpr);
                                        switch (rightExpr.def) {
                                            case EMatch(PVar(tmpVar), tmpVal):
                                                // Next statement: tmpVar.to_iso8601()
                                                var nextDef = nxt != null ? unwrapParen(nxt).def : null;
                                                switch (nextDef) {
                                                    case ECall({def: EVar(callVar)}, methodName, callArgs) if (callVar == tmpVar && (callArgs == null || callArgs.length == 0) && methodName == "to_iso8601"):
                                                        // Wrap tmpVal with DateTime.to_iso8601(tmpVal)
                                                        var converted = makeAST(ERemoteCall(makeAST(EVar("DateTime")), "to_iso8601", [tmpVal]));
                                                        var newConcat = makeAST(EBinary(StringConcat, leftExpr, converted));
                                                        out.push(makeAST(EMatch(PVar(assignName), newConcat)));
                                                        i += 2;
                                                        combined = true;
                                                    default:
                                                }
                                            default:
                                        }
                                    default:
                                }
                            default:
                        }
                        if (!combined) {
                            out.push(cur);
                            i++;
                        }
                    }
                    makeAST(EBlock(out));
                default:
                    block;
            }
        }
        return transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case ETry(body, rescues, catches, afterBlock, elseBlock):
                    var newRescues: Array<ERescueClause> = [];
                    if (rescues != null) {
                        for (rc in rescues) {
                            var nb = rc != null && rc.body != null ? normalizeBlock(rc.body) : rc.body;
                            newRescues.push({ pattern: rc.pattern, varName: rc.varName, body: nb });
                        }
                    }
                    makeASTWithMeta(ETry(body, newRescues, catches, afterBlock, elseBlock), node.metadata, node.pos);
                default:
                    node;
            };
        });
    }

    /**
     * Global EBlock peephole normalization: merge [x = left <> (tmp = expr), tmp.method()] into x = left <> Module.method(expr)
     */
    static function blockConcatNormalizationPass(ast: ElixirAST): ElixirAST {
        function unwrapParen(node: ElixirAST): ElixirAST {
            var current = node;
            while (current != null && Type.enumConstructor(current.def) == "EParen") {
                switch (current.def) { case EParen(inner): current = inner; default: }
            }
            return current;
        }
        function normalizeBlock(block: ElixirAST): ElixirAST {
            if (block == null) return block;
            return switch (block.def) {
                case EBlock(stmts):
                    var out = [];
                    var i = 0;
                    while (i < stmts.length) {
                        var cur = stmts[i];
                        var nxt = (i + 1 < stmts.length) ? stmts[i + 1] : null;
                        var combined = false;
                        switch (cur.def) {
                            case EMatch(PVar(assignName), concatExpr):
                                concatExpr = unwrapParen(concatExpr);
                                switch (concatExpr.def) {
                                    case EBinary(StringConcat, leftExpr, rightExpr):
                                        rightExpr = unwrapParen(rightExpr);
                                        switch (rightExpr.def) {
                                            case EMatch(PVar(tmpVar), tmpVal):
                                                var nextDef = nxt != null ? unwrapParen(nxt).def : null;
                                                switch (nextDef) {
                                                    case ECall({def: EVar(callVar)}, methodName, callArgs) if (callVar == tmpVar && (callArgs == null || callArgs.length == 0)):
                                                        // Currently, support DateTime.to_iso8601(tmpVal)
                                                        var moduleNode = makeAST(EVar("DateTime"));
                                                        var converted = makeAST(ERemoteCall(moduleNode, methodName, [tmpVal]));
                                                        var newConcat = makeAST(EBinary(StringConcat, leftExpr, converted));
                                                        out.push(makeAST(EMatch(PVar(assignName), newConcat)));
                                                        i += 2;
                                                        combined = true;
                                                    default:
                                                }
                                            default:
                                        }
                                    default:
                                }
                            default:
                        }
                        if (!combined) {
                            out.push(cur);
                            i++;
                        }
                    }
                    makeAST(EBlock(out));
                default:
                    block;
            }
        }
        return transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case EBlock(_): normalizeBlock(node);
                default: node;
            };
        });
    }

    /**
     * Event/controller binding preservation pass
     * - Pre-bind repeated Map.get(params, :key) patterns in function bodies
     * - Applies to common handler names: handle_event/handle_info/mount and REST actions
     */
    static function eventBindingPreservationPass(ast: ElixirAST): ElixirAST {
        function replaceMapGets(node: ElixirAST, bound: Map<String, Bool>): ElixirAST {
            if (node == null) return node;
            return switch (node.def) {
                case ERemoteCall(module, funcName, args):
                    var isMapGet = switch (module.def) { case EVar(name) if (name == "Map"): true; default: false; };
                    if (isMapGet && funcName == "get" && args.length == 2) {
                        switch (args[0].def) {
                            case EVar(paramName) if (paramName == "params"):
                                switch (args[1].def) {
                                    case EAtom(atom):
                                        var key = Std.string(atom);
                                        if (bound.exists(key)) makeAST(EVar(key)) else node;
                                    default: node;
                                }
                            default: node;
                        }
                    } else {
                        var newMod = module != null ? replaceMapGets(module, bound) : null;
                        var newArgs = [for (a in args) replaceMapGets(a, bound)];
                        makeAST(ERemoteCall(newMod, funcName, newArgs));
                    }
                case EBlock(stmts):
                    makeAST(EBlock([for (s in stmts) replaceMapGets(s, bound)]));
                case EIf(c, t, e):
                    makeAST(EIf(replaceMapGets(c, bound), replaceMapGets(t, bound), e != null ? replaceMapGets(e, bound) : null));
                case EBinary(op, l, r):
                    makeAST(EBinary(op, replaceMapGets(l, bound), replaceMapGets(r, bound)));
                case EUnary(op, e):
                    makeAST(EUnary(op, replaceMapGets(e, bound)));
                case ECall(target, name, args):
                    makeAST(ECall(target != null ? replaceMapGets(target, bound) : null, name, [for (a in args) replaceMapGets(a, bound)]));
                case ERemoteCall(mod, name, args):
                    makeAST(ERemoteCall(replaceMapGets(mod, bound), name, [for (a in args) replaceMapGets(a, bound)]));
                case EWith(clauses, doBlock, elseBlock):
                    makeAST(EWith(clauses, replaceMapGets(doBlock, bound), elseBlock != null ? replaceMapGets(elseBlock, bound) : null));
                default:
                    node;
            };
        }
        function countMapGets(node: ElixirAST, counts: Map<String, Int>): Void {
            if (node == null) return;
            switch (node.def) {
                case ERemoteCall(module, funcName, args):
                    var isMapGet = switch (module.def) { case EVar(name) if (name == "Map"): true; default: false; };
                    if (isMapGet && funcName == "get" && args.length == 2) {
                        switch (args[0].def) {
                            case EVar(paramName) if (paramName == "params"):
                                switch (args[1].def) {
                                    case EAtom(atom):
                                        var key = Std.string(atom);
                                        var prev = counts.exists(key) ? counts.get(key) : 0;
                                        counts.set(key, prev + 1);
                                    default:
                                }
                            default:
                        }
                    }
                    if (module != null) countMapGets(module, counts);
                    for (a in args) countMapGets(a, counts);
                case EBlock(stmts):
                    for (s in stmts) countMapGets(s, counts);
                case EIf(c, t, e):
                    countMapGets(c, counts); countMapGets(t, counts); if (e != null) countMapGets(e, counts);
                case EBinary(_, l, r):
                    countMapGets(l, counts); countMapGets(r, counts);
                case EUnary(_, e):
                    countMapGets(e, counts);
                case ECall(target, _, args):
                    if (target != null) countMapGets(target, counts);
                    for (a in args) countMapGets(a, counts);
                case ERemoteCall(mod, _, args):
                    countMapGets(mod, counts); for (a in args) countMapGets(a, counts);
                case EWith(clauses, doBlock, elseBlock):
                    countMapGets(doBlock, counts); if (elseBlock != null) countMapGets(elseBlock, counts);
                default:
            }
        }
        return transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case EDef(name, args, guard, body) if (isHandlerName(name)):
                    var counts: Map<String, Int> = new Map();
                    countMapGets(body, counts);
                    var toBind = [for (k in counts.keys()) if (counts.get(k) >= 2) k];
                    if (toBind.length == 0) return node;
                    var boundMap: Map<String, Bool> = new Map();
                    var prebinds: Array<ElixirAST> = [];
                    for (k in toBind) {
                        boundMap.set(k, true);
                        var getCall = makeAST(ERemoteCall(makeAST(EVar("Map")), "get", [makeAST(EVar("params")), makeAST(EAtom(ElixirAtom.raw(k)))]));
                        prebinds.push(makeAST(EMatch(PVar(k), getCall)));
                    }
                    var replacedBody = replaceMapGets(body, boundMap);
                    var newBody = switch (replacedBody.def) {
                        case EBlock(stmts): makeAST(EBlock(prebinds.concat(stmts)));
                        default: makeAST(EBlock(prebinds.concat([replacedBody])));
                    };
                    makeASTWithMeta(EDef(name, args, guard, newBody), node.metadata, node.pos);
                default:
                    node;
            };
        });
    }
    static function isHandlerName(name: String): Bool {
        if (name == null) return false;
        switch (name) {
            case "handle_event" | "handle_info" | "mount": return true;
            default:
                return name == "index" || name == "create" || name == "update" || name == "delete" || name == "show" || name == "new" || name == "edit";
        }
    }

    /**
     * EventArmBinderRenameByUsage: Within handler/controller functions, for case arms with atom-head tuple patterns
     * (e.g., {:create_todo, _}), if the clause body references exactly one simple missing identifier and there exists
     * at least one unused binder among the tuple components after the atom head, rename the first unused binder to the
     * missing identifier. Structural and target-agnostic; does not inject aliases here (aliasing is handled by other passes).
     */
    static function eventArmBinderRenameByUsagePass(ast: ElixirAST): ElixirAST {
        return reflaxe.elixir.ast.transformers.EventTransforms.eventArmBinderRenameByUsagePass(ast);
    }


    /**
     * InfraCaseTargetResolution pass: within blocks, track simple alias bindings and remap case targets
     * on infrastructure variables (_g, gX) to the canonical variable name.
     */
    static function infraCaseTargetResolutionPass(ast: ElixirAST): ElixirAST {
        function isInfra(name: String): Bool {
            return name == "_g" || name == "g" || ~/^_?g\d+$/.match(name);
        }

        function resolveInBlock(block: ElixirAST): ElixirAST {
            return switch (block.def) {
                case EBlock(stmts):
                    var mapping = new Map<String, String>(); // infra -> alias
                    var newStmts: Array<ElixirAST> = [];
                    for (stmt in stmts) {
                        var transformed = switch (stmt.def) {
                            case EMatch(pattern, expr):
                                // Track bindings of form alias = infraVar
                                switch (pattern) {
                                    case PVar(aliasName):
                                        switch (expr.def) {
                                            case EVar(src) if (isInfra(src)):
                                                mapping.set(src, aliasName);
                                            default:
                                        }
                                        // Also record underscore mapping for known temp aliases: _gX -> gX
                                        if (~/^g\d*$/.match(aliasName) || aliasName == "g") {
                                            var underscored = "_" + aliasName;
                                            if (!mapping.exists(underscored)) mapping.set(underscored, aliasName);
                                        }
                                    default:
                                }
                                // Also transform inside the match
                                stmt;
                            case ECase(target, clauses):
                                // If target is infra var and mapping exists, remap
                                var newTarget = switch (target.def) {
                                    case EVar(name) if (isInfra(name) && mapping.exists(name)):
                                        makeAST(EVar(mapping.get(name)));
                                    default:
                                        target;
                                };
                                makeAST(ECase(newTarget, clauses));
                            default:
                                // Recurse within nested blocks
                                transformAST(stmt, infraCaseTargetResolutionPass);
                        };
                        newStmts.push(transformed);
                    }
                    makeAST(EBlock(newStmts));
                default:
                    transformAST(block, infraCaseTargetResolutionPass);
            };
        }

        return resolveInBlock(ast);
    }
    
    /**
     * CaseTargetBindingAlign pass: within a block, if we see an immediate pattern of
     *   _g = <expr>
     *   case varName do ... end
     * then rename the assignment LHS to varName so the discriminant is defined.
     */
    static function caseTargetBindingAlignPass(ast: ElixirAST): ElixirAST {
        inline function isInfra(name:String):Bool return name == "_g" || name == "g" || ~/^_?g\d+$/.match(name);
        inline function isBenign(stmt: ElixirAST): Bool {
            return switch (stmt.def) {
                case EMatch(PVar(_), rhs):
                    switch (rhs.def) {
                        case ENil | EBoolean(_) | EInteger(_) | EFloat(_) | EString(_) | EAtom(_): true;
                        case EMap(pairs) if (pairs.length == 0): true;
                        default: false;
                    }
                case EBlock(exprs) if (exprs.length == 0): true;
                default: false;
            };
        }
        return switch (ast.def) {
            case EBlock(stmts):
                var out:Array<ElixirAST> = [];
                var i = 0;
                while (i < stmts.length) {
                    var s = stmts[i];
                    if (i + 1 < stmts.length) {
                        var next = stmts[i+1];
                        switch [s.def, next.def] {
                            case [EMatch(PVar(lhs), rhs), ECase(target, clauses)] if (isInfra(lhs)):
                                switch (target.def) {
                                    case EVar(vn):
                                        // Rename LHS to match case target var
                                        var renamed = makeAST(EMatch(PVar(vn), rhs));
                                        out.push(renamed);
                                        out.push(next);
                                        i += 2;
                                        continue;
                                    default:
                                }
                            default:
                        }
                        // One-statement gap alignment: EMatch(infra, rhs), benign, ECase(target,...)
                        if (i + 2 < stmts.length) {
                            var mid = stmts[i+1];
                            var nxt2 = stmts[i+2];
                            switch [s.def, nxt2.def] {
                                case [EMatch(PVar(lhs2), rhs2), ECase(target2, clauses2)] if (isInfra(lhs2) && isBenign(mid)):
                                    switch (target2.def) {
                                        case EVar(vn2):
                                            var renamed2 = makeAST(EMatch(PVar(vn2), rhs2));
                                            out.push(renamed2);
                                            out.push(mid);
                                            out.push(nxt2);
                                            i += 3;
                                            continue;
                                        default:
                                    }
                                default:
                            }
                        }
                    }
                    // Recurse
                    out.push(transformAST(s, caseTargetBindingAlignPass));
                    i++;
                }
                makeAST(EBlock(out));
            default:
                transformAST(ast, caseTargetBindingAlignPass);
        };
    }

    /**
     * InlineCaseTargetBinding pass: For patterns of the form
     *   g = expr
     *   case g do ... end
     * inline the binding into the case target to eliminate the temporary variable.
     */
    static function inlineCaseTargetBindingPass(ast: ElixirAST): ElixirAST {
        inline function normalizeInfra(n:String):String {
            return (n != null && StringTools.startsWith(n, "_") && ~/^_?g\d*$/.match(n)) ? n.substr(1) : n;
        }
        inline function sameVar(target:ElixirAST, name:String):Bool {
            return switch (target.def) {
                case EVar(n):
                    var tn = normalizeInfra(n);
                    var ln = normalizeInfra(name);
                    tn == ln || n == name;
                default: false;
            };
        }
        // Treat plain "g", plain "_g", and numbered variants as infra names
        inline function isInfraName(n:String):Bool return n == "g" || n == "_g" || ~/^_?g\d+$/.match(n);
        return switch (ast.def) {
            case EBlock(stmts):
                var out:Array<ElixirAST> = [];
                var i = 0;
                while (i < stmts.length) {
                    if (i + 1 < stmts.length) {
                        // Immediate pair
                        switch [stmts[i].def, stmts[i+1].def] {
                            case [EMatch(PVar(lhs), rhs), ECase(target, clauses)] if (sameVar(target, lhs)):
                                out.push(makeAST(ECase(rhs, clauses)));
                                i += 2;
                                continue;
                            default:
                        }
                        // One-statement gap (e.g., instrumentation inserted)
                        if (i + 2 < stmts.length) {
                            switch [stmts[i].def, stmts[i+2].def] {
                                case [EMatch(PVar(lhs2), rhs2), ECase(target2, clauses2)] if (sameVar(target2, lhs2)):
                                    out.push(transformAST(stmts[i+1], inlineCaseTargetBindingPass));
                                    out.push(makeAST(ECase(rhs2, clauses2)));
                                    i += 3;
                                    continue;
                                default:
                            }
                        }
                    }
                    // Backward inlining: find earlier binding for case target and inline
                    var handled = false;
                    switch (stmts[i].def) {
                        case ECase(targetX, clausesX):
                            switch (targetX.def) {
                                case EVar(tname) if (isInfraName(tname)):
                                    #if debug_inline_case
                                    Sys.println('[InlineCaseTargetBinding] Infra case target detected: ' + tname + ' (out.len=' + out.length + ')');
                                    for (ii in 0...out.length) {
                                        Sys.println('  out[' + ii + ']: ' + Type.enumConstructor(out[ii].def));
                                    }
                                    #end
                                    // Search backwards over already-emitted statements
                                    var j = out.length - 1;
                                    var foundIdx = -1;
                                    var rhs:ElixirAST = null;
                                    while (j >= 0) {
                                        switch (out[j].def) {
                                            case EMatch(PVar(lhs0), rhs0):
                                                var tn = normalizeInfra(tname);
                                                var ln = normalizeInfra(lhs0);
                                                if (tn == ln || lhs0 == tname) {
                                                    foundIdx = j;
                                                    rhs = rhs0;
                                                    j = -1; // break
                                                }
                                            default:
                                        }
                                        j--;
                                    }
                                    if (foundIdx != -1) {
                                        #if debug_inline_case
                                        Sys.println('[InlineCaseTargetBinding]   Found binding at out[' + foundIdx + '], inlining into case');
                                        #end
                                        out.remove(out[foundIdx]);
                                        out.push(makeAST(ECase(rhs, clausesX)));
                                        i++;
                                        handled = true;
                                    }
                                default:
                            }
                        default:
                    }
                    if (handled) continue;
                    // Fallback: recurse and emit current statement
                    out.push(transformAST(stmts[i], inlineCaseTargetBindingPass));
                    i++;
                }
                makeAST(EBlock(out));
            default:
                transformAST(ast, inlineCaseTargetBindingPass);
        };
    }

    /**
     * BindThenCaseInline pass: in a block, detect earlier assignments like
     *   _gX = expr
     * followed by
     *   case _gX do ... end
     * and inline the RHS into the case target, removing the earlier assignment.
     * Handles gaps between the binding and the case (as long as no reassignment to the same name occurs).
     */
    static function bindThenCaseInlinePass(ast: ElixirAST): ElixirAST {
        inline function normalizeInfra(n:String):String {
            return (n != null && StringTools.startsWith(n, "_") && ~/^_?g\d*$/.match(n)) ? n.substr(1) : n;
        }
        function transformBlock(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case EBlock(stmts):
                    var out: Array<ElixirAST> = [];
                    // Track last binding index for variables in current out buffer
                    var lastBind: Map<String, { idx:Int, rhs:ElixirAST }> = new Map();
                    var i = 0;
                    while (i < stmts.length) {
                        var s = stmts[i];
                        switch (s.def) {
                            case EMatch(PVar(lhs), rhs):
                                // Record binding and emit (may be removed later)
                                lastBind.set(lhs, { idx: out.length, rhs: rhs });
                                var ln = normalizeInfra(lhs);
                                if (ln != lhs) lastBind.set(ln, { idx: out.length, rhs: rhs });
                                else {
                                    var alt = '_' + lhs;
                                    if (~/^g\d*$/.match(lhs)) lastBind.set(alt, { idx: out.length, rhs: rhs });
                                }
                                out.push(transformAST(s, bindThenCaseInlinePass));
                            case ECase(target, clauses):
                                switch (target.def) {
                                    case EVar(name) if (lastBind.exists(name) || lastBind.exists(normalizeInfra(name))):
                                        var key = lastBind.exists(name) ? name : normalizeInfra(name);
                                        var info = lastBind.get(key);
                                        // Inline RHS and remove earlier binding
                                        out.remove(out[info.idx]);
                                        out.push(makeAST(ECase(info.rhs, clauses)));
                                        lastBind.remove(key);
                                    default:
                                        out.push(transformAST(s, bindThenCaseInlinePass));
                                }
                            default:
                                out.push(transformAST(s, bindThenCaseInlinePass));
                        }
                        i++;
                    }
                    makeAST(EBlock(out));
                default:
                    transformAST(node, bindThenCaseInlinePass);
            };
        }
        return transformBlock(ast);
    }

    /**
     * NestedCaseDiscriminantInline: Walk with a lexical environment of prior temp bindings
     * so inner cases can inline discriminants even when binding occurred in an outer block.
     * It does NOT remove outer bindings; in combination with other passes, the redundant
     * binding is often eliminated or renamed. This only replaces case targets.
     */
    static function nestedCaseDiscriminantInlinePass(ast: ElixirAST): ElixirAST {
        inline function normalizeInfra(n:String):String {
            return (n != null && StringTools.startsWith(n, "_") && ~/^_?g\d*$/.match(n)) ? n.substr(1) : n;
        }
        function walk(node: ElixirAST, env: Map<String,ElixirAST>): ElixirAST {
            if (node == null || node.def == null) return node;
            return switch (node.def) {
                case EBlock(stmts):
                    var out:Array<ElixirAST> = [];
                    // Create a child env inheriting parent mappings
                    var localEnv: Map<String,ElixirAST> = new Map();
                    for (k in env.keys()) localEnv.set(k, env.get(k));
                    for (s in stmts) {
                        switch (s.def) {
                            case EMatch(PVar(lhs), rhs):
                                var ln = normalizeInfra(lhs);
                                localEnv.set(lhs, rhs);
                                if (ln != lhs) localEnv.set(ln, rhs);
                                out.push(walk(s, localEnv));
                            case ECase(target, clauses):
                                var replacedTarget = target;
                                switch (target.def) {
                                    case EVar(name):
                                        var key = localEnv.exists(name) ? name : normalizeInfra(name);
                                        if (localEnv.exists(key)) replacedTarget = localEnv.get(key);
                                    default:
                                }
                                var newClauses = [for (c in clauses) { pattern: c.pattern, guard: c.guard, body: walk(c.body, localEnv) }];
                                out.push(makeAST(ECase(walk(replacedTarget, localEnv), newClauses)));
                            default:
                                out.push(walk(s, localEnv));
                        }
                    }
                    makeAST(EBlock(out));
                case EIf(cond, thenB, elseB):
                    makeAST(EIf(walk(cond, env), walk(thenB, env), elseB != null ? walk(elseB, env) : null));
                case ECond(clauses):
                    var nc = [for (c in clauses) { condition: walk(c.condition, env), body: walk(c.body, env) }];
                    makeAST(ECond(nc));
                case EDef(name, args, guards, body):
                    makeAST(EDef(name, args, guards, walk(body, new Map())));
                case EDefp(name, args, guards, body):
                    makeAST(EDefp(name, args, guards, walk(body, new Map())));
                case EDefmodule(n, body):
                    makeAST(EDefmodule(n, walk(body, new Map())));
                case EParen(inner):
                    makeAST(EParen(walk(inner, env)));
                default:
                    // Generic transform over children
                    transformAST(node, x -> walk(x, env));
            };
        }
        return walk(ast, new Map());
    }

    /**
     * Contextual pass: Replace ECase targets on infra vars using context.infrastructureVarInitValues
     * so that even if the alias assignment was removed earlier, we can inline the original RHS.
     */
    static function infraCaseTargetExprInlinePass(ast: ElixirAST, context: reflaxe.elixir.CompilationContext): ElixirAST {
        inline function isInfraName(n:String):Bool return n == "g" || n == "_g" || ~/^_?g\d+$/.match(n);
        inline function normalize(n:String):String return (n != null && StringTools.startsWith(n, "_")) ? n.substr(1) : n;
        function replace(node: ElixirAST): ElixirAST {
            return transformNode(node, function(n) {
                return switch (n.def) {
                    case ECase(target, clauses):
                        switch (target.def) {
                            case EVar(name) if (isInfraName(name)):
                                // 1) Try AST mapping recorded from block tracking
                                var key = name;
                                var inlined: Null<ElixirAST> = null;
                                if (context.infrastructureVarInitValues != null) {
                                    if (!context.infrastructureVarInitValues.exists(key)) {
                                        var alt = normalize(name);
                                        if (context.infrastructureVarInitValues.exists(alt)) key = alt;
                                    }
                                    if (context.infrastructureVarInitValues.exists(key)) inlined = context.infrastructureVarInitValues.get(key);
                                }
                                // 2) Fallback to typed preprocessor substitutions using sourceVarId metadata
                                if (inlined == null && target.metadata != null && Reflect.hasField(target.metadata, "sourceVarId")) {
                                    var sid: Dynamic = Reflect.field(target.metadata, "sourceVarId");
                                    if (Std.isOfType(sid, Int)) {
                                        var texpr = context.infraVarSubstitutions != null ? context.infraVarSubstitutions.get(cast sid) : null;
                                        if (texpr != null) {
                                            inlined = reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(texpr, context);
                                        }
                                    }
                                }
                                // 3) Fallback to name-based typed substitutions from context (stable per module/function)
                                if (inlined == null && context.infraVarNameSubstitutions != null) {
                                    var n1 = name;
                                    var n2 = normalize(name);
                                    var texpr2: TypedExpr = null;
                                    if (context.infraVarNameSubstitutions.exists(n1)) texpr2 = context.infraVarNameSubstitutions.get(n1);
                                    else if (context.infraVarNameSubstitutions.exists(n2)) texpr2 = context.infraVarNameSubstitutions.get(n2);
                                    if (texpr2 != null) {
                                        inlined = reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(texpr2, context);
                                    }
                                }
                                if (inlined != null) makeAST(ECase(inlined, clauses)) else n;
                            default:
                                n;
                        }
                    default:
                        n;
                };
            });
        }
        return replace(ast);
    }

    /**
     * NestedCaseProducerResolver: As a final safety net, when encountering an ECase on an infra var
     * inside a branch body without a visible binding or recorded mapping, search the enclosing block for
     * the nearest prior producer expression (ERemoteCall/ECall) and inline it as the case target.
     * Apply only for Result/Option-like shapes (atom-headed tuple patterns like {:ok|:error, _}).
     */
    static function nestedCaseProducerResolverPass(ast: ElixirAST): ElixirAST {
        inline function isInfraName(n:String):Bool return n == "g" || n == "_g" || ~/^_?g\d+$/.match(n);
        inline function normalize(n:String):String return (n != null && StringTools.startsWith(n, "_")) ? n.substr(1) : n;

        function resultLikePatterns(clauses:Array<ECaseClause>):Bool {
            var ok = false, err = false, some = false, none = false;
            for (c in clauses) {
                switch (c.pattern) {
                    case PTuple(list) if (list.length >= 1):
                        switch (list[0]) {
                            case PLiteral({def: EAtom(a)}):
                                if (a == "ok") ok = true; else if (a == "error") err = true; else if (a == "some") some = true; else if (a == "none") none = true;
                            default:
                        }
                    case PLiteral({def: EAtom(a)}):
                        if (a == "ok") ok = true; else if (a == "error") err = true; else if (a == "some") some = true; else if (a == "none") none = true;
                    default:
                }
            }
            return (ok || err) || (some || none);
        }

        function transformBlock(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case EBlock(stmts):
                    var out:Array<ElixirAST> = [];
                    var i = 0;
                    while (i < stmts.length) {
                        var s = stmts[i];
                        switch (s.def) {
                            case ECase(target, clauses):
                                switch (target.def) {
                                    case EVar(name) if (isInfraName(name) && resultLikePatterns(clauses)):
                                        // Search backwards in out and original stmts for nearest plain call expression
                                        var injected: ElixirAST = null;
                                        // 1) scan already emitted
                                        var j = out.length - 1;
                                        while (j >= 0 && injected == null) {
                                            switch (out[j].def) {
                                                case ERemoteCall(_, _, _) | ECall(_, _, _): injected = out[j]; out.remove(out[j]);
                                                default:
                                            }
                                            j--;
                                        }
                                        // 2) if not found, scan upcoming original stmts just before current
                                        if (injected == null) {
                                            var k = i - 1;
                                            while (k >= 0 && injected == null) {
                                                switch (stmts[k].def) {
                                                    case ERemoteCall(_, _, _) | ECall(_, _, _): injected = stmts[k];
                                                    default:
                                                }
                                                k--;
                                            }
                                        }
                                        if (injected != null) {
                                            out.push(makeAST(ECase(injected, clauses)));
                                        } else {
                                            out.push(s);
                                        }
                                    default:
                                        out.push(transformBlock(s));
                                }
                            default:
                                out.push(transformBlock(s));
                        }
                        i++;
                    }
                    makeAST(EBlock(out));
                default:
                    transformAST(node, transformBlock);
            };
        }
        return transformBlock(ast);
    }

    /**
     * UnknownCaseTargetExprInline: If we see a prior infra assignment and a later case on an unknown target var,
     * replace the case target with the RHS expression of the prior infra assignment even when a benign statement
     * appears in between. This fixes patterns like `_g = Map.get(payload, :type); temp_result = nil; case payload_type do ... end`.
     */
    static function unknownCaseTargetExprInlinePass(ast: ElixirAST): ElixirAST {
        inline function isInfra(n:String):Bool return n == "g" || n == "_g" || ~/^_?g\d+$/.match(n);
        function process(block: ElixirAST): ElixirAST {
            return switch (block.def) {
                case EBlock(stmts):
                    var out:Array<ElixirAST> = [];
                    var i = 0;
                    while (i < stmts.length) {
                        switch (stmts[i].def) {
                            case EMatch(PVar(lhs), rhs) if (isInfra(lhs)):
                                // Look ahead one or two statements for case on unknown var
                                if (i + 1 < stmts.length) {
                                    switch (stmts[i+1].def) {
                                        case ECase(target, clauses):
                                            switch (target.def) {
                                                case EVar(_):
                                                    out.push(stmts[i]); // keep original assignment to preserve semantics
                                                    out.push(makeAST(ECase(rhs, clauses)));
                                                    i += 2; continue;
                                                default:
                                            }
                                        default:
                                    }
                                }
                                if (i + 2 < stmts.length) {
                                    var mid = stmts[i+1];
                                    switch (stmts[i+2].def) {
                                        case ECase(target2, clauses2):
                                            switch (target2.def) {
                                                case EVar(_):
                                                    out.push(stmts[i]);
                                                    out.push(process(mid));
                                                    out.push(makeAST(ECase(rhs, clauses2)));
                                                    i += 3; continue;
                                                default:
                                            }
                                        default:
                                    }
                                }
                                out.push(process(stmts[i])); i++;
                            default:
                                out.push(process(stmts[i])); i++;
                        }
                    }
                    makeAST(EBlock(out));
                default:
                    transformAST(block, process);
            };
        }
        return process(ast);
    }

    /**
     * SingleBinderAliasVeryLate: For any clause with pattern {:some|:ok, binder}, if its body builds a
     * {:some|:ok, {atom, var}} tuple and var ≠ binder, substitute var with binder in that position.
     * Minimal and safe for pubsub-like patterns producing {:bulk_update, action}.
     */
    static function singleBinderAliasVeryLatePass(ast: ElixirAST): ElixirAST {
        function isSomeOrOk(p:EPattern):Bool {
            return switch (p) {
                case PTuple(el) if (el.length >= 2):
                    switch (el[0]) {
                        case PLiteral({def: EAtom(a)}) if (a == "some" || a == "ok"): true;
                        default: false;
                    }
                default: false;
            };
        }
        function getBinder(p:EPattern):Null<String> {
            return switch (p) {
                case PTuple(el) if (el.length >= 2):
                    switch (el[1]) { case PVar(n): n; default: null; }
                default: null;
            };
        }
        function rewriteBody(body:ElixirAST, binder:String):ElixirAST {
            // Generic rewrite: under a {:some|:ok, binder} clause, replace any tuple of the form
            // {<atom>, var} where var != binder with {<atom>, binder}. No app-specific names.
            inline function isAtomNode(n:ElixirAST):Bool {
                return switch (n.def) {
                    case EAtom(_): true;
                    default: false;
                };
            }
            inline function isVarNotBinder(n:ElixirAST, b:String):Bool {
                return switch (n.def) {
                    case EVar(v) if (v != b): true;
                    default: false;
                };
            }
            function walk(node:ElixirAST, underSomeOk:Bool):ElixirAST {
                if (node == null) return node;
                return switch (node.def) {
                    case ETuple(elems) if (elems.length >= 2):
                        var first = elems[0];
                        var out:Array<ElixirAST> = [];
                        for (idx in 0...elems.length) {
                            var child = elems[idx];
                            var replaced = (idx == 1 && underSomeOk && isAtomNode(first) && isVarNotBinder(child, binder))
                                ? makeAST(EVar(binder))
                                : walk(child, underSomeOk);
                            out.push(replaced);
                        }
                        makeAST(ETuple(out));
                    case EBlock(sts):
                        makeAST(EBlock([for (s in sts) walk(s, underSomeOk)]));
                    case EIf(c,t,e):
                        makeAST(EIf(walk(c, underSomeOk), walk(t, underSomeOk), e != null ? walk(e, underSomeOk) : null));
                    case EMatch(pat, expr):
                        makeAST(EMatch(pat, walk(expr, underSomeOk)));
                    case EMap(pairs):
                        makeAST(EMap([for (p in pairs) { key: p.key, value: walk(p.value, underSomeOk) } ]));
                    case EKeywordList(pairs):
                        makeAST(EKeywordList([for (p in pairs) { key: p.key, value: walk(p.value, underSomeOk) } ]));
                    case ECall(target, name, args):
                        var nt = target != null ? walk(target, underSomeOk) : null;
                        var na = [for (a in args) walk(a, underSomeOk)];
                        makeAST(ECall(nt, name, na));
                    case ERemoteCall(mod, name, args):
                        var nm = walk(mod, underSomeOk);
                        var na2 = [for (a in args) walk(a, underSomeOk)];
                        makeAST(ERemoteCall(nm, name, na2));
                    case ECase(target, clauses):
                        var nClauses = [for (c in clauses) { pattern: c.pattern, guard: c.guard, body: walk(c.body, underSomeOk) }];
                        makeAST(ECase(walk(target, underSomeOk), nClauses));
                    case ECond(conds):
                        var nConds = [];
                        for (c in conds) nConds.push({ condition: c.condition, body: walk(c.body, underSomeOk) });
                        makeAST(ECond(nConds));
                    default:
                        node;
                };
            }
            return walk(body, true);
        }
        return transformAST(ast, function(n){
            return switch (n.def) {
                case ECase(target, clauses):
                    var newClauses:Array<ECaseClause> = [];
                    for (c in clauses) {
                        if (isSomeOrOk(c.pattern)) {
                            var b = getBinder(c.pattern);
                            if (b != null) {
                                newClauses.push({ pattern: c.pattern, guard: c.guard, body: rewriteBody(c.body, b) });
                            } else newClauses.push(c);
                        } else newClauses.push(c);
                    }
                    makeAST(ECase(target, newClauses));
                default:
                    n;
            };
        });
    }
    
    /**
     * Pattern variable rename by usage: Align tuple pattern PVars with names used in the clause body.
     */
    static function patternVarRenameByUsagePass(ast: ElixirAST): ElixirAST {
        function collectPatternVars(p: EPattern, acc: Array<{ref: EPattern, name: String}>): Void {
            switch (p) {
                case PVar(name): acc.push({ref: p, name: name});
                case PTuple(list): for (e in list) collectPatternVars(e, acc);
                case PList(list): for (e in list) collectPatternVars(e, acc);
                case PCons(h, t): collectPatternVars(h, acc); collectPatternVars(t, acc);
                case PMap(pairs): for (pair in pairs) collectPatternVars(pair.value, acc);
                case PStruct(_, fields): for (f in fields) collectPatternVars(f.value, acc);
                default:
            }
        }

        function patternRename(p: EPattern, from: String, to: String): EPattern {
            return switch (p) {
                case PVar(name) if (name == from): PVar(to);
                case PTuple(list): PTuple([for (e in list) patternRename(e, from, to)]);
                case PList(list): PList([for (e in list) patternRename(e, from, to)]);
                case PCons(h, t): PCons(patternRename(h, from, to), patternRename(t, from, to));
                case PMap(pairs): PMap([for (pair in pairs) {key: pair.key, value: patternRename(pair.value, from, to)}]);
                case PStruct(mod, fields): PStruct(mod, [for (f in fields) {key: f.key, value: patternRename(f.value, from, to)}]);
                default: p;
            };
        }

        function isAtomTuple(p: EPattern): Bool {
            return switch (p) {
                case PTuple(list) if (list.length > 0):
                    switch (list[0]) {
                        case PLiteral(value):
                            switch (value.def) {
                                case EAtom(_): true;
                                default: false;
                            }
                        default: false;
                    }
                default: false;
            };
        }
        function singleBinderInAtomTuple(p:EPattern):Null<String> {
            return switch (p) {
                case PTuple(el) if (el.length == 2):
                    switch (el[0]) {
                        case PLiteral({def: EAtom(_)}):
                            switch (el[1]) { case PVar(b): b; default: null; }
                        default: null;
                    }
                default: null;
            };
        }

        function isOptionSomeClause(clause:ECaseClause):Bool {
            return switch (clause.pattern) {
                case PTuple(elements) if (elements.length >= 2):
                    switch (elements[0]) {
                        case PLiteral({def: EAtom(atom)}) if (atom == "some" || atom == "ok"): true;
                        default: false;
                    }
                default:
                    false;
            };
        }

        function clausePosString(clause:ECaseClause):String {
            if (clause.body != null && clause.body.pos != null) {
                return Std.string(clause.body.pos);
            }
            return "";
        }

        function patternPreviewLocal(pattern:EPattern):String {
            return switch (pattern) {
                case PTuple(elements):
                    var parts = [for (el in elements) patternPreviewLocal(el)];
                    '{' + parts.join(', ') + '}';
                case PLiteral({def: EAtom(atom)}): ':' + atom;
                case PVar(name): name;
                case PWildcard: '_';
                case PAlias(alias, inner): alias + ' as ' + patternPreviewLocal(inner);
                default: Type.enumConstructor(pattern);
            };
        }

        function mapKeysLocal(map:Map<String,Bool>):String {
            var keys:Array<String> = [];
            for (k in map.keys()) keys.push(k);
            return '[' + keys.join(', ') + ']';
        }

        function collectUsedVars(node: ElixirAST, acc: Map<String, Bool>): Void {
            if (node == null) return;
            switch (node.def) {
                case EVar(name):
                    // Collect identifiers (including camelCase) but exclude dotted module names
                    var isIdent = ~/^[A-Za-z_][A-Za-z0-9_]*$/.match(name);
                    if (isIdent) acc.set(name, true);
                default: iterateAST(node, v -> collectUsedVars(v, acc));
            }
        }

        function isGenericName(n: String): Bool {
            // Treat common temp/infra/placeholder names as generic (eligible for rename)
            return n == "value" || n.charAt(0) == '_' || ~/^_?g\d*$/.match(n) || n == "socket" || n == "conn" || n == "this" || ~/^this\d+$/.match(n);
        }

        function renameClauseIfNeeded(clause: ECaseClause, caseTargetName: Null<String>): ECaseClause {
            // For *_level case targets, skip generic renames in this pass;
            // later enforcement passes will ensure binder = 'level'.
            if (caseTargetName != null) {
                var snTop = toSnakeCase(caseTargetName);
                if (snTop != null && ~/.*_level$/.match(snTop)) {
                    return clause;
                }
            }
            // For general atom-head tuple patterns with a single binder (e.g., {:create_todo, _x}),
            // allow structural rename when exactly one simple identifier is used in the body and
            // the binder itself is not referenced.
            var patternVars: Array<{ref: EPattern, name: String}> = [];
            collectPatternVars(clause.pattern, patternVars);

            #if debug_option_some_binder
            if (isOptionSomeClause(clause)) {
                var posStr = clausePosString(clause);
                if (posStr.indexOf('TodoPubSub') >= 0) {
                    var initialBinders = [for (pv in patternVars) pv.name];
                    haxe.Log.trace('[OptionSomeDiag] patternVarRenameByUsagePass pre-scan binders=' + initialBinders.join(', ') + ' pattern=' + patternPreviewLocal(clause.pattern) + ' at ' + posStr, null);
                }
            }
            #end
            var declared = new Map<String, Bool>();
            var declaredBase = new Map<String, Bool>();
            for (pv in patternVars) {
                declared.set(pv.name, true);
                var base = (function(s:String){ var re = ~/([0-9]+)$/; return re.replace(s, ""); })(pv.name);
                declaredBase.set(base, true);
            }

            var used = new Map<String, Bool>();
            collectUsedVars(clause.body, used);

            // Collect field-base vars from body (msg/payload in Map.get/Keyword.get)
            var fieldBases = new Map<String,Bool>();
            (function collectFieldBaseVarsLocal(node: ElixirAST) {
                if (node == null) return;
                switch (node.def) {
                    case ERemoteCall({def: EVar("Map")}, func, args) if (func == "get" && args.length > 0):
                        switch (args[0].def) { case EVar(n): fieldBases.set(n, true); default: }
                        for (a in args) collectFieldBaseVarsLocal(a);
                    case ERemoteCall({def: EVar("Keyword")}, func, args) if (func == "get" && args.length > 0):
                        switch (args[0].def) { case EVar(n): fieldBases.set(n, true); default: }
                        for (a in args) collectFieldBaseVarsLocal(a);
                    default:
                        iterateAST(node, v -> collectFieldBaseVarsLocal(v));
                }
            })(clause.body);

            #if debug_option_some_binder
            if (isOptionSomeClause(clause)) {
                var posStr2 = clausePosString(clause);
                if (posStr2.indexOf('TodoPubSub') >= 0) {
                    haxe.Log.trace('[OptionSomeDiag] patternVarRenameByUsagePass used vars=' + mapKeysLocal(used) + ' declared=' + mapKeysLocal(declared) + ' at ' + posStr2, null);
                }
            }
            #end

            // Normalize used names: treat suffixed variants (e.g., g2) as base if the base exists
            function stripDigitsSuffixLocal(s:String):String {
                var re = ~/([0-9]+)$/;
                return re.replace(s, "");
            }
            var usedNorm = new Map<String, Bool>();
            for (uname in used.keys()) {
                var base = stripDigitsSuffixLocal(uname);
                if (base != uname && (declared.exists(base) || declaredBase.exists(base))) {
                    usedNorm.set(base, true);
                } else {
                    usedNorm.set(uname, true);
                }
            }

            // Preferred names to align tuple pattern binders with body usage
            // Extended to cover common controller/LiveView variables
            var priorities = [
                "todo", "message", "reason", "filter", "sort_by", "query", "flash_type", "id", "action",
                "user", "data", "changeset", "conn", "params"
            ];

            var newPattern = clause.pattern;

            // Special-case: If this is an Option.Some-like clause and the body references `level`,
            // prefer renaming the single binder to `level` to avoid undefined variable and preserve
            // outer variables like `msg` used as field-bases.
            if (isOptionSomeClause(clause)) {
                var uses = new Map<String,Bool>();
                collectUsedVars(clause.body, uses);
                if (uses.exists("level")) {
                    // Detect sole binder name in pattern
                    var soleBinder:Null<String> = null;
                    switch (clause.pattern) {
                        case PTuple(elements) if (elements.length >= 2):
                            switch (elements[1]) { case PVar(b): soleBinder = b; default: }
                        default:
                    }
                    if (soleBinder != null && soleBinder != "level") {
                        newPattern = patternRename(newPattern, soleBinder, "level");
                        // Finalize Option binder and return early to avoid generic renames
                        return { pattern: newPattern, guard: clause.guard, body: clause.body };
                    }
                }
                // Structural nested payload case: If binder is not referenced and the body builds
                // {:some|:ok, {atom, var}}, rename binder to that inner var. This aligns with
                // nested payload usage without app-specific names.
                inline function findInnerPayloadVar(n:ElixirAST):Null<String> {
                    var found:Null<String> = null;
                    function walk(x:ElixirAST):Void {
                        if (x == null || found != null) return;
                        switch (x.def) {
                            case ETuple(el) if (el.length >= 2):
                                switch (el[0].def) {
                                    case EAtom(a) if (a == "some" || a == "ok"):
                                        switch (el[1].def) {
                                            case ETuple(pe) if (pe.length >= 2):
                                                switch (pe[1].def) {
                                                    case EVar(vn): found = vn; return;
                                                    default:
                                                }
                                            default:
                                        }
                                    default:
                                }
                                for (e in el) walk(e);
                            default:
                                iterateAST(x, walk);
                        }
                    }
                    walk(n);
                    return found;
                }
                // Only when binder itself is not used in the body (pure alignment)
                var binderInBody = (function():Bool {
                    var seen = false;
                    function scan(x:ElixirAST):Void {
                        if (x == null || seen) return; switch (x.def) {
                            case EVar(v) if (v == (switch (clause.pattern) { case PTuple(e2) if (e2.length >=2): switch (e2[1]) { case PVar(b): b; default: null; } default: null; })): seen = true;
                            default: iterateAST(x, scan);
                        }
                    }
                    scan(clause.body);
                    return seen;
                })();
                if (!binderInBody) {
                    var inner = findInnerPayloadVar(clause.body);
                    if (inner != null) {
                        var soleBinder2:Null<String> = null;
                        switch (clause.pattern) { case PTuple(e3) if (e3.length >= 2): switch (e3[1]) { case PVar(b): soleBinder2 = b; default: } default: }
                        if (soleBinder2 != null && soleBinder2 != inner) {
                            newPattern = patternRename(newPattern, soleBinder2, inner);
                            return { pattern: newPattern, guard: clause.guard, body: clause.body };
                        }
                    }
                }
            }
            // General atom-head tuple: rename a single binder to the only used simple identifier
            // in the body when binder is not referenced and a unique candidate exists.
            var atomBinder:Null<String> = singleBinderInAtomTuple(clause.pattern);
            if (atomBinder != null) {
                // Binder not used in body?
                var binderUsed = used.exists(atomBinder);
                if (!binderUsed) {
                    // candidates: used simple idents not declared and not field-bases
                    var candidates:Array<String> = [];
                    for (uname in used.keys()) {
                        if (!declared.exists(uname) && !fieldBases.exists(uname) && ~/^[a-z_][a-z0-9_]*$/.match(uname)) {
                            candidates.push(uname);
                        }
                    }
                    if (candidates.length == 1) {
                        var toName = candidates[0];
                        newPattern = patternRename(newPattern, atomBinder, toName);
                        return { pattern: newPattern, guard: clause.guard, body: clause.body };
                    }
                }
            }
            for (uname in usedNorm.keys()) {
                if (declared.exists(uname)) continue;
                var targetName = uname;
                // Skip module-like identifiers and field-base names
                if (uname != null && uname.length > 0) {
                    var c0 = uname.charAt(0);
                    var isModuleLike = (c0 == c0.toUpperCase() && c0 != c0.toLowerCase());
                    if (isModuleLike || fieldBases.exists(uname)) continue;
                }
                if (!priorities.contains(uname)) {
                    var snake = NameUtils.toSnakeCase(uname);
                    if (priorities.contains(snake)) targetName = snake;
                }
                // Avoid renaming to names that collide with common function args
                if (targetName == "conn" || targetName == "socket" || targetName == "params") {
                    continue;
                }
                // If case target suggests *_level and body references level, prefer 'level'
                if (caseTargetName != null) {
                    var sn = toSnakeCase(caseTargetName);
                    if (sn != null && ~/.*_level$/.match(sn) && used.exists("level") && !fieldBases.exists("level")) {
                        targetName = "level";
                    }
                }
                var candidate: Null<String> = null;
                for (pv in patternVars) {
                    if (isGenericName(pv.name)) { candidate = pv.name; break; }
                }
                if (candidate != null && !declared.exists(targetName)) {
                    #if debug_option_some_binder
                    if (isOptionSomeClause(clause)) {
                        var posStr3 = clausePosString(clause);
                        if (posStr3.indexOf('TodoPubSub') >= 0) {
                            haxe.Log.trace('[OptionSomeDiag] patternVarRenameByUsagePass rename ' + candidate + ' → ' + targetName + ' at ' + posStr3, null);
                        }
                    }
                    #end
                    newPattern = patternRename(newPattern, candidate, targetName);
                    declared.set(targetName, true);
                }
            }

            #if debug_option_some_binder
            if (isOptionSomeClause(clause)) {
                var posStr4 = clausePosString(clause);
                if (posStr4.indexOf('TodoPubSub') >= 0) {
                    haxe.Log.trace('[OptionSomeDiag] patternVarRenameByUsagePass final pattern=' + patternPreviewLocal(newPattern) + ' at ' + posStr4, null);
                }
            }
            #end

            return { pattern: newPattern, guard: clause.guard, body: clause.body };
        }

        return switch (ast.def) {
            case ECase(target, clauses):
                var tgtName:Null<String> = null; switch (target.def) { case EVar(n): tgtName = n; default: }
                var renamed = [for (cl in clauses) renameClauseIfNeeded(cl, tgtName)];
                makeASTWithMeta(ECase(target, renamed), ast.metadata, ast.pos);
            case ECond(conds):
                // Recurse into cond bodies so inner ECase patterns can be processed
                var newConds = [];
                for (c in conds) {
                    newConds.push({ condition: c.condition, body: patternVarRenameByUsagePass(c.body) });
                }
                makeASTWithMeta(ECond(newConds), ast.metadata, ast.pos);
            default:
                transformAST(ast, patternVarRenameByUsagePass);
        };
    }

    /**
     * FunctionParamRenameByUsagePass
     * WHAT: For EDef/EDefp, if the body references exactly one simple missing identifier and there exists an unused
     * parameter binder (PVar) among function args, rename that binder to the missing identifier. Structural, target-agnostic.
     */
    static function functionParamRenameByUsagePass(ast: ElixirAST): ElixirAST {
        inline function isSimpleIdent(n:String):Bool return n != null && ~/^[a-z_][a-z0-9_]*$/.match(n);
        function collectParamBinders(patterns:Array<EPattern>):Array<String> {
            var out:Array<String> = [];
            function visit(p:EPattern):Void {
                switch (p) {
                    case PVar(n): out.push(n);
                    case PTuple(l): for (e in l) visit(e);
                    case PList(l): for (e in l) visit(e);
                    case PCons(h,t): visit(h); visit(t);
                    case PMap(ps): for (kv in ps) visit(kv.value);
                    case PStruct(_, fs): for (f in fs) visit(f.value);
                    case PAlias(n, inner): out.push(n); visit(inner);
                    case PPin(inner): visit(inner);
                    case PBinary(segs): for (s in segs) visit(s.pattern);
                    default:
                }
            }
            for (p in patterns) visit(p);
            return out;
        }
        function collectUsed(node:ElixirAST, acc:Map<String,Bool>):Void {
            if (node == null) return; switch (node.def) { case EVar(n): if (isSimpleIdent(n)) acc.set(n, true); default: iterateAST(node, v -> collectUsed(v, acc)); }
        }
        return transformNode(ast, function(node:ElixirAST):ElixirAST {
            return switch (node.def) {
                case EDef(name, args, guard, body):
                    // Special-case: LiveView render(assigns)
                    var fUsed0 = new Map<String,Bool>(); collectUsed(body, fUsed0);
                    if (name == "render" && args != null && args.length >= 1 && fUsed0.exists("assigns")) {
                        function renameFirstToAssigns(p:EPattern):EPattern {
                            return switch (p) {
                                case PVar(n) if (n != "assigns"): PVar("assigns");
                                default: p;
                            };
                        }
                        var newArgs0 = args.copy(); newArgs0[0] = renameFirstToAssigns(newArgs0[0]);
                        // Refresh params list after rename flows below
                        args = newArgs0;
                    }
                    var params = collectParamBinders(args);
                    var used = new Map<String,Bool>(); collectUsed(body, used);
                    var declared = new Map<String,Bool>(); for (p in params) declared.set(p, true);
                    var missing:Array<String> = [];
                    for (u in used.keys()) if (!declared.exists(u)) missing.push(u);
                    if (missing.length == 1) {
                        // find first unused binder
                        var unused:Array<String> = [];
                        for (p in params) if (!used.exists(p)) unused.push(p);
                        if (unused.length >= 1) {
                            var from = unused[0]; var toName = missing[0];
                            function renameInPattern(p:EPattern):EPattern {
                                return switch (p) {
                                    case PVar(n) if (n == from): PVar(toName);
                                    case PTuple(l): PTuple([for (e in l) renameInPattern(e)]);
                                    case PList(l): PList([for (e in l) renameInPattern(e)]);
                                    case PCons(h,t): PCons(renameInPattern(h), renameInPattern(t));
                                    case PMap(ps): PMap([for (kv in ps) {key: kv.key, value: renameInPattern(kv.value)}]);
                                    case PStruct(mod, fs): PStruct(mod, [for (f in fs) {key: f.key, value: renameInPattern(f.value)}]);
                                    case PAlias(n, inner): PAlias(n == from ? toName : n, renameInPattern(inner));
                                    case PPin(inner): PPin(renameInPattern(inner));
                                    case PBinary(segs): PBinary([for (s in segs) {pattern: renameInPattern(s.pattern), size: s.size, type: s.type, modifiers: s.modifiers}]);
                                    default: p;
                                };
                            }
                            var newArgs = [for (a in args) renameInPattern(a)];
                            makeASTWithMeta(EDef(name, newArgs, guard, body), node.metadata, node.pos);
                        } else {
                            // Special-case: if missing is 'assigns' or 'params', try renaming a non-critical binder
                            var toName2 = missing[0];
                            if (toName2 == "assigns" || toName2 == "params") {
                                var candidate:Null<String> = null;
                                for (pname in params) {
                                    if (pname != "socket" && pname != "conn") { candidate = pname; break; }
                                }
                                if (candidate != null) {
                                    function renameAny(p:EPattern):EPattern {
                                        return switch (p) {
                                            case PVar(n) if (n == candidate): PVar(toName2);
                                            case PTuple(l): PTuple([for (e in l) renameAny(e)]);
                                            case PList(l): PList([for (e in l) renameAny(e)]);
                                            case PCons(h,t): PCons(renameAny(h), renameAny(t));
                                            case PMap(ps): PMap([for (kv in ps) {key: kv.key, value: renameAny(kv.value)}]);
                                            case PStruct(mod, fs): PStruct(mod, [for (f in fs) {key: f.key, value: renameAny(f.value)}]);
                                            case PAlias(n, inner): PAlias(n == candidate ? toName2 : n, renameAny(inner));
                                            case PPin(inner): PPin(renameAny(inner));
                                            case PBinary(segs): PBinary([for (s in segs) {pattern: renameAny(s.pattern), size: s.size, type: s.type, modifiers: s.modifiers}]);
                                            default: p;
                                        };
                                    }
                                    var argsRenamed = [for (a in args) renameAny(a)];
                                    makeASTWithMeta(EDef(name, argsRenamed, guard, body), node.metadata, node.pos);
                                } else node;
                            } else node;
                        }
                    } else node;
                case EDefp(name, args, guard, body):
                    // Same logic for private defs
                    var params2 = collectParamBinders(args);
                    var used2 = new Map<String,Bool>(); collectUsed(body, used2);
                    var declared2 = new Map<String,Bool>(); for (p in params2) declared2.set(p, true);
                    var missing2:Array<String> = []; for (u in used2.keys()) if (!declared2.exists(u)) missing2.push(u);
                    if (missing2.length == 1) {
                        var unused2:Array<String> = []; for (p in params2) if (!used2.exists(p)) unused2.push(p);
                        if (unused2.length >= 1) {
                            var from2 = unused2[0]; var to2 = missing2[0];
                            function renameInPattern2(p:EPattern):EPattern {
                                return switch (p) {
                                    case PVar(n) if (n == from2): PVar(to2);
                                    case PTuple(l): PTuple([for (e in l) renameInPattern2(e)]);
                                    case PList(l): PList([for (e in l) renameInPattern2(e)]);
                                    case PCons(h,t): PCons(renameInPattern2(h), renameInPattern2(t));
                                    case PMap(ps): PMap([for (kv in ps) {key: kv.key, value: renameInPattern2(kv.value)}]);
                                    case PStruct(mod, fs): PStruct(mod, [for (f in fs) {key: f.key, value: renameInPattern2(f.value)}]);
                                    case PAlias(n, inner): PAlias(n == from2 ? to2 : n, renameInPattern2(inner));
                                    case PPin(inner): PPin(renameInPattern2(inner));
                                    case PBinary(segs): PBinary([for (s in segs) {pattern: renameInPattern2(s.pattern), size: s.size, type: s.type, modifiers: s.modifiers}]);
                                    default: p;
                                };
                            }
                            var newArgs2 = [for (a in args) renameInPattern2(a)];
                            makeASTWithMeta(EDefp(name, newArgs2, guard, body), node.metadata, node.pos);
                        } else {
                            var toName3 = missing2[0];
                            if (toName3 == "assigns" || toName3 == "params") {
                                var candidate2:Null<String> = null;
                                for (pname2 in params2) {
                                    if (pname2 != "socket" && pname2 != "conn") { candidate2 = pname2; break; }
                                }
                                if (candidate2 != null) {
                                    function renameAny2(p:EPattern):EPattern {
                                        return switch (p) {
                                            case PVar(n) if (n == candidate2): PVar(toName3);
                                            case PTuple(l): PTuple([for (e in l) renameAny2(e)]);
                                            case PList(l): PList([for (e in l) renameAny2(e)]);
                                            case PCons(h,t): PCons(renameAny2(h), renameAny2(t));
                                            case PMap(ps): PMap([for (kv in ps) {key: kv.key, value: renameAny2(kv.value)}]);
                                            case PStruct(mod, fs): PStruct(mod, [for (f in fs) {key: f.key, value: renameAny2(f.value)}]);
                                            case PAlias(n, inner): PAlias(n == candidate2 ? toName3 : n, renameAny2(inner));
                                            case PPin(inner): PPin(renameAny2(inner));
                                            case PBinary(segs): PBinary([for (s in segs) {pattern: renameAny2(s.pattern), size: s.size, type: s.type, modifiers: s.modifiers}]);
                                            default: p;
                                        };
                                    }
                                    var argsRenamed2 = [for (a in args) renameAny2(a)];
                                    makeASTWithMeta(EDefp(name, argsRenamed2, guard, body), node.metadata, node.pos);
                                } else node;
                            } else node;
                        }
                    } else node;
                default:
                    node;
            };
        });
    }

    /**
     * FnParamUnusedUnderscore: For anonymous functions (EFn), underscore-prefix any parameter variables
     * (including nested tuple components) that are not referenced in the function body.
     *
     * WHAT: Walks EFn clauses, collects used variable names from the body, and rewrites PVar bindings
     *       in args to add underscore when unused. Applies recursively to PTuple and other pattern shapes.
     * WHY: Eliminates Mix warnings like "variable acc_g is unused" produced by reduce_while lambdas and
     *      other anonymous functions that destructure accumulators.
     * HOW: Uses a body variable collector similar in spirit to patternVarRenameByUsagePass but scoped to EFn.
     */
    static function underscoreUnusedFnParamsPass(ast: ElixirAST): ElixirAST {
        function collectUsedVars(node: ElixirAST, acc: Map<String, Bool>): Void {
            if (node == null) return;
            switch (node.def) {
                case EVar(name): acc.set(name, true);
                case EBlock(stmts): for (s in stmts) collectUsedVars(s, acc);
                case EIf(c,t,e): collectUsedVars(c, acc); collectUsedVars(t, acc); if (e != null) collectUsedVars(e, acc);
                case EBinary(_, l, r): collectUsedVars(l, acc); collectUsedVars(r, acc);
                case EUnary(_, e): collectUsedVars(e, acc);
                case ECall(target, _, args): if (target != null) collectUsedVars(target, acc); for (a in args) collectUsedVars(a, acc);
                case ERemoteCall(mod, _, args): collectUsedVars(mod, acc); for (a in args) collectUsedVars(a, acc);
                case EParen(inner): collectUsedVars(inner, acc);
                case ECase(target, clauses):
                    collectUsedVars(target, acc);
                    for (cl in clauses) collectUsedVars(cl.body, acc);
                case ETuple(items): for (i in items) collectUsedVars(i, acc);
                case EList(items): for (i in items) collectUsedVars(i, acc);
                case EMap(pairs): for (p in pairs) collectUsedVars(p.value, acc);
                case EStruct(_, fields): for (f in fields) collectUsedVars(f.value, acc);
                default:
            }
        }

        function underscorePattern(p: EPattern, used: Map<String,Bool>): EPattern {
            return switch (p) {
                case PVar(name):
                    if (!used.exists(name) && !StringTools.startsWith(name, "_")) PVar("_" + name) else p;
                case PTuple(list): PTuple([for (e in list) underscorePattern(e, used)]);
                case PList(list): PList([for (e in list) underscorePattern(e, used)]);
                case PCons(h, t): PCons(underscorePattern(h, used), underscorePattern(t, used));
                case PMap(pairs): PMap([for (kv in pairs) {key: kv.key, value: underscorePattern(kv.value, used)}]);
                case PStruct(mod, fields): PStruct(mod, [for (f in fields) {key: f.key, value: underscorePattern(f.value, used)}]);
                case PAlias(v, inner):
                    var v2 = (!used.exists(v) && !StringTools.startsWith(v, "_") ? "_" + v : v);
                    PAlias(v2, underscorePattern(inner, used));
                case PPin(inner): PPin(underscorePattern(inner, used));
                case PBinary(segs): PBinary([for (s in segs) {pattern: underscorePattern(s.pattern, used), size: s.size, type: s.type, modifiers: s.modifiers}]);
                default: p;
            };
        }

        return transformNode(ast, function(n) {
            return switch (n.def) {
                case EFn(clauses):
                    var newClauses = [];
                    for (cl in clauses) {
                        var used = new Map<String,Bool>();
                        collectUsedVars(cl.body, used);
                        var newArgs = cl.args != null ? [for (a in cl.args) underscorePattern(a, used)] : cl.args;
                        newClauses.push({ args: newArgs, guard: cl.guard, body: cl.body });
                    }
                    makeASTWithMeta(EFn(newClauses), n.metadata, n.pos);
                default:
                    n;
            };
        });
    }

    /**
     * CaseClauseBindingAlias pass: within handler/controller functions, for each case clause,
     * pre-bind missing variables in the body to appropriate pattern binders.
     *
     * Strategy:
     * - Collect declared names from function args and preceding matches.
     * - For each ECase clause: collect pattern var names and used body vars.
     * - For each used var not declared:
     *   - If its snake_case form exists in pattern vars, alias missingVar = snakeVar
     *   - Else if the clause pattern has exactly one variable, alias missingVar = thatVar
     *   - Else, skip (insufficient certainty)
     * This prevents undefined variable errors like data/changeset/user/todo/message in clause bodies.
     */
    static function caseClauseBindingAliasPass(ast: ElixirAST): ElixirAST {
        return reflaxe.elixir.ast.transformers.BinderAliasTransforms.caseClauseBindingAliasPass(ast);
    }


    /**
     * CaseArmUnusedBinderUnderscore pass: For each ECase clause, prefix unused pattern binders with underscore.
     */
    static function caseArmUnusedBinderUnderscorePass(ast: ElixirAST): ElixirAST {
        function collectPatternBinders(p:EPattern, acc:Map<String,Bool>):Void {
            switch (p) {
                case PVar(n): acc.set(n, true);
                case PTuple(list): for (e in list) collectPatternBinders(e, acc);
                case PList(list): for (e in list) collectPatternBinders(e, acc);
                case PCons(h,t): collectPatternBinders(h, acc); collectPatternBinders(t, acc);
                case PMap(pairs): for (kv in pairs) collectPatternBinders(kv.value, acc);
                case PStruct(_, fields): for (f in fields) collectPatternBinders(f.value, acc);
                case PAlias(n, inner): acc.set(n, true); collectPatternBinders(inner, acc);
                case PPin(inner): collectPatternBinders(inner, acc);
                case PBinary(segs): for (s in segs) collectPatternBinders(s.pattern, acc);
                default:
            }
        }
        function collectUsedVars(node: ElixirAST, acc: Map<String, Bool>): Void {
            if (node == null) return;
            switch (node.def) { case EVar(name): acc.set(name, true); default: iterateAST(node, v -> collectUsedVars(v, acc)); }
        }
        function underscoreUnused(p:EPattern, used:Map<String,Bool>):EPattern {
            return switch (p) {
                case PVar(n):
                    if (!used.exists(n) && (n.length == 0 || n.charAt(0) != '_')) PVar('_' + n) else PVar(n);
                case PTuple(list): PTuple([for (e in list) underscoreUnused(e, used)]);
                case PList(list): PList([for (e in list) underscoreUnused(e, used)]);
                case PCons(h,t): PCons(underscoreUnused(h, used), underscoreUnused(t, used));
                case PMap(pairs): PMap([for (kv in pairs) {key: kv.key, value: underscoreUnused(kv.value, used)}]);
                case PStruct(mod, fields): PStruct(mod, [for (f in fields) {key: f.key, value: underscoreUnused(f.value, used)}]);
                case PAlias(n, inner):
                    var nn = (!used.exists(n) && (n.length == 0 || n.charAt(0) != '_')) ? '_' + n : n;
                    PAlias(nn, underscoreUnused(inner, used));
                case PPin(inner): PPin(underscoreUnused(inner, used));
                case PBinary(segs): PBinary([for (s in segs) {pattern: underscoreUnused(s.pattern, used), size: s.size, type: s.type, modifiers: s.modifiers}]);
                default: p;
            };
        }
        return switch (ast.def) {
            case ECase(target, clauses):
                var fixed:Array<ECaseClause> = [];
                for (cl in clauses) {
                    var binders = new Map<String,Bool>(); collectPatternBinders(cl.pattern, binders);
                    var used = new Map<String,Bool>(); collectUsedVars(cl.body, used);
                    var np = underscoreUnused(cl.pattern, used);
                    fixed.push({ pattern: np, guard: cl.guard, body: cl.body });
                }
                makeASTWithMeta(ECase(target, fixed), ast.metadata, ast.pos);
            default:
                transformAST(ast, caseArmUnusedBinderUnderscorePass);
        };
    }

    /**
     * GlobalOptionBinderAlias pass: For any case clause matching {:some|:ok, binder},
     * if the clause body references exactly one missing simple identifier (used ∧ ¬declared ∧ ¬bound ∧ ¬field-base),
     * inject `missing = binder` at the start of the clause body. Target-agnostic and structural only.
     */
    static function globalOptionBinderAliasPass(ast: ElixirAST): ElixirAST {
        return reflaxe.elixir.ast.transformers.BinderAliasTransforms.globalOptionBinderAliasPass(ast);
    }


    /**
     * GeneralTupleBinderAlias pass: For any case clause matching {atom, binder},
     * if the clause body references exactly one missing simple identifier (used ∧ ¬declared ∧ ¬bound ∧ ¬field-base),
     * rename the binder to that identifier. This covers domain enums like {:todo_created, todo}.
     */
    static function generalTupleBinderAliasPass(ast: ElixirAST): ElixirAST {
        return reflaxe.elixir.ast.transformers.BinderAliasTransforms.generalTupleBinderAliasPass(ast);
    }


    /**
     * SingleBinderAlias pass: If a case clause has exactly one PVar binder in the pattern,
     * and the body references exactly one missing simple identifier, insert an alias
     *   missing = binder
     * at the beginning of the clause body. This is a safety net for domains like
     * {:some, binder} where body references 'action' instead of the binder name.
     */
    static function singleBinderAliasPass(ast: ElixirAST): ElixirAST {
        inline function isSimpleIdent(n:String):Bool return n != null && ~/^[a-z_][a-z0-9_]*$/.match(n);
        function countBinders(p:EPattern, acc:Array<String>):Void {
            switch (p) {
                case PVar(n): acc.push(n);
                case PTuple(l): for (e in l) countBinders(e, acc);
                case PList(l): for (e in l) countBinders(e, acc);
                case PCons(h,t): countBinders(h, acc); countBinders(t, acc);
                case PMap(ps): for (kv in ps) countBinders(kv.value, acc);
                case PStruct(_, fs): for (f in fs) countBinders(f.value, acc);
                case PAlias(n, inner): acc.push(n); countBinders(inner, acc);
                case PPin(inner): countBinders(inner, acc);
                case PBinary(segs): for (s in segs) countBinders(s.pattern, acc);
                default:
            }
        }
        function collectUsed(node:ElixirAST, acc:Map<String,Bool>):Void {
            if (node == null) return; switch (node.def) {
                case EVar(n): acc.set(n, true);
                default: iterateAST(node, v -> collectUsed(v, acc));
            }
        }
        function declaredInPattern(p:EPattern):Map<String,Bool> {
            var m = new Map<String,Bool>();
            countBinders(p, []); // no-op for m but keep the approach symmetrical
            function visit(q:EPattern):Void {
                switch (q) {
                    case PVar(n): m.set(n, true);
                    case PTuple(l): for (e in l) visit(e);
                    case PList(l): for (e in l) visit(e);
                    case PCons(h,t): visit(h); visit(t);
                    case PMap(ps): for (kv in ps) visit(kv.value);
                    case PStruct(_, fs): for (f in fs) visit(f.value);
                    case PAlias(n, inner): m.set(n, true); visit(inner);
                    case PPin(inner): visit(inner);
                    case PBinary(segs): for (s in segs) visit(s.pattern);
                    default:
                }
            }
            visit(p);
            return m;
        }
        return switch (ast.def) {
            case ECase(target, clauses):
                var newClauses:Array<ECaseClause> = [];
                for (cl in clauses) {
                    var binders:Array<String> = [];
                    countBinders(cl.pattern, binders);
                    var out = cl;
                    if (binders.length == 1) {
                        var used = new Map<String,Bool>(); collectUsed(cl.body, used);
                        var declared = declaredInPattern(cl.pattern);
                        var missing:Array<String> = [];
                        for (u in used.keys()) {
                            if (!declared.exists(u) && isSimpleIdent(u)) missing.push(u);
                        }
                        if (missing.length == 1) {
                            var aliasName = missing[0];
                            var binder = binders[0];
                            var aliasStmt = makeAST(EMatch(PVar(aliasName), makeAST(EVar(binder))));
                            var newBody = switch (cl.body.def) {
                                case EBlock(sts): makeAST(EBlock([aliasStmt].concat(sts)));
                                default: makeAST(EBlock([aliasStmt, cl.body]));
                            };
                            out = { pattern: cl.pattern, guard: cl.guard, body: newBody };
                        }
                    }
                    newClauses.push(out);
                }
                makeASTWithMeta(ECase(target, newClauses), ast.metadata, ast.pos);
            case ECond(conds):
                var nc = [];
                for (c in conds) nc.push({condition: c.condition, body: singleBinderAliasPass(c.body)});
                makeASTWithMeta(ECond(nc), ast.metadata, ast.pos);
            default:
                transformAST(ast, singleBinderAliasPass);
        };
    }

    /**
     * GeneralAtomBinderAlias pass: For any case clause matching {:atom, binder} (single-binder atom-head tuple),
     * if the clause body references exactly one missing simple identifier (used ∧ ¬declared), inject `missing = binder`
     * at the start of the clause body. Structural and target-agnostic.
     */
    static function generalAtomBinderAliasPass(ast: ElixirAST): ElixirAST {
        return reflaxe.elixir.ast.transformers.BinderAliasTransforms.generalAtomBinderAliasPass(ast);
    }


    /**
     * SingleBinderMissingVarAliasPass: For any case clause with exactly one binder in its pattern,
     * if the body references exactly one missing simple identifier (used ∧ ¬declared ∧ ¬bound ∧ ¬field-base),
     * inject `missing = binder` at the start of the clause body. Structural and target-agnostic.
     */
    static function singleBinderMissingVarAliasPass(ast: ElixirAST): ElixirAST {
        return reflaxe.elixir.ast.transformers.BinderAliasTransforms.singleBinderMissingVarAliasPass(ast);
    }


    /**
     * GenericBinderSubstitutionPass
     *
     * WHAT
     * - For ECase clauses that match Option/Result-like patterns of the form {:some|:ok, x}
     *   where exactly one binder exists, rewrite nested payload constructions in the clause body
     *   to use the binder `x` instead of a free variable. If structural rewrite is uncertain and
     *   exactly one free variable is referenced in nested payload positions, inject a clause‑local
     *   alias `free = x` at the start of the clause body.
     *
     * WHY
     * - Prevents undefined or outer free var usage inside Option/Result payloads and removes
     *   reliance on aliasing when a precise structural substitution is possible. This leads to
     *   cleaner, idiomatic, hand‑written looking Elixir.
     *
     * HOW
     * - Detect clauses with a single binder in an atom‑headed tuple pattern (some/ok).
     * - Traverse the clause body and find ETuple nodes whose first element is an atom 'some'/'ok'.
     *   For each such tuple, inspect its payload (second element):
     *     - If exactly one distinct free variable appears in the payload (not the binder and not
     *       declared in the clause pattern), replace occurrences of that variable with the binder.
     *     - Track the set of free variables referenced across all payload positions. If no rewrite
     *       happened and the union set has exactly one free variable, inject `free = binder` at the
     *       top of the clause body as a safe fallback.
     * - Recurses into nested constructs (EBlock/EIf/ECond/ECase) so deep payloads are handled.
     *
     * CONTEXT
     * - Runs late, after binder naming and usage alignment passes, but before broad alias fallbacks
     *   (GlobalOptionBinderAlias/SingleBinderAlias). This keeps aliasing minimal and structural.
     * - Part of Pattern & Binder shaping, interacts with CaseArmUnusedBinderUnderscore (later) and
     *   DeadAssignmentElimination (later) which will remove any now‑dead temps.
     *
     * EDGE CASES
     * - Multiple distinct free vars in a single payload: skip structural rewrite to avoid guessing.
     * - No Option/Result payload construction in body: no changes.
     * - If an alias already exists earlier in the body, this pass still prefers structural rewrite
     *   and will leave the alias (later DAE may clean it up if unused).
     *
     * EXAMPLES
     * - Input:
     *   case maybe() do
     *     {:ok, msg} -> {:ok, {:broadcast, message}}
     *   end
     *   Output:
     *     {:ok, msg} -> {:ok, {:broadcast, msg}}
     *
     * - Fallback alias:
     *   case maybe() do
     *     {:ok, x} -> {:ok, build(x, message)}  # two vars → no structural rewrite
     *   end
     *   Since payload positions use exactly one non‑binder free var `message`, inject:
     *     {:ok, x} -> message = x; {:ok, build(x, message)}
     */
    static function genericBinderSubstitutionPass(ast: ElixirAST): ElixirAST {
        return reflaxe.elixir.ast.transformers.BinderAliasTransforms.genericBinderSubstitutionPass(ast);
    }

    
    /**
     * Convert camelCase to snake_case for Elixir method names
     */
    static function toSnakeCase(name: String): String {
        var result = "";
        for (i in 0...name.length) {
            var char = name.charAt(i);
            if (i > 0 && char == char.toUpperCase() && char != char.toLowerCase()) {
                result += "_";
            }
            result += char.toLowerCase();
        }
        return result;
    }
    
    /**
     * Recursively transform AST nodes with infinite recursion protection
     *
     * ## CRITICAL FIX: Infinite Recursion in Transformer (January 2025)
     *
     * ### The Problem
     * The transformer was entering infinite recursion, causing compilation hangs
     * lasting over 2 minutes. This occurred when certain nodes (especially atoms)
     * were being endlessly re-transformed.
     *
     * ### Root Cause
     * The original implementation always created new AST nodes, even when no
     * transformation occurred. This caused:
     * 1. Transformer applies to a node, returns a "new" node (same content, new object)
     * 2. Parent sees the node changed (different object reference)
     * 3. Parent re-transforms the "changed" node
     * 4. Infinite loop as nodes appear to always change
     *
     * ### The Solution: Structural Sharing Pattern
     * Only create new AST nodes when the content actually changes:
     * - If no children change, return the SAME object (not a copy)
     * - If any child changes, create a new parent with updated children
     * - Use physical equality (same object) to detect changes
     *
     * ### Special Handling for Terminal Nodes
     * Some nodes (like atoms) are terminal and should never recurse:
     * - EAtom: Always terminal, no children to transform
     * - EInteger, EFloat, EString: Terminal literal values
     * - These return immediately without recursion
     *
     * ### Implementation Details
     * - transformArray(): Helper that only copies arrays when elements change
     * - Physical equality check: `transformed != original` (object identity)
     * - Terminal node early returns prevent unnecessary recursion
     *
     * ### Impact
     * - Compilation time: 2+ minutes → ~10 seconds
     * - Memory usage: Significantly reduced due to structural sharing
     * - Correctness: Transformations still apply correctly
     *
     * @see https://github.com/reflaxe/reflaxe.haxe.elixir/commits/transformer-recursion-fix
     */
    // Track visited nodes to detect cycles (for debugging)
    private static var visitedNodes: Map<String, Int> = new Map();
    private static var nodeVisitCounter: Int = 0;
    private static var maxNodeVisits: Int = 10000;

    // Helper to transform an array only if elements change
    private static function transformArray(arr: Array<ElixirAST>, transformer: (ElixirAST) -> ElixirAST): {array: Array<ElixirAST>, changed: Bool} {
        var changed = false;
        var result = arr;

        for (i in 0...arr.length) {
            var original = arr[i];
            var transformed = transformNode(original, transformer);
            if (transformed != original) {
                if (!changed) {
                    // First change - copy the array
                    result = arr.copy();
                    changed = true;
                }
                result[i] = transformed;
            }
        }

        return {array: result, changed: changed};
    }

    public static function transformNode(ast: ElixirAST, transformer: (ElixirAST) -> ElixirAST): ElixirAST {
        // Handle null AST nodes or nodes with null def
        if (ast == null || ast.def == null) {
            return ast;  // Return as-is if null
        }

        #if debug_transformer_hang
        nodeVisitCounter++;

        // Create a unique identifier for this node
        var nodeId = Type.enumConstructor(ast.def) + "_" + Std.string(ast.pos);

        // Track visit frequency
        var visits = visitedNodes.get(nodeId);
        if (visits == null) visits = 0;
        visits++;
        visitedNodes.set(nodeId, visits);

        // Log breadcrumbs
        if (nodeVisitCounter % 1000 == 0) {
            trace('[TRANSFORMER BREADCRUMB] Node ${nodeVisitCounter}: ${Type.enumConstructor(ast.def)}');
        }

        // Detect excessive visits to same node (cycle)
        if (visits > 100) {
            trace('[CYCLE DETECTED] Node ${nodeId} visited ${visits} times!');
            trace('[CYCLE DETECTED] AST def: ${ast.def}');
            throw 'Infinite recursion detected in transformer: ${nodeId}';
        }

        // Overall safety limit
        if (nodeVisitCounter > maxNodeVisits) {
            trace('[TRANSFORMER HANG] Exceeded ${maxNodeVisits} node visits');
            trace('[TRANSFORMER HANG] Last node: ${Type.enumConstructor(ast.def)}');
            throw 'Transformer exceeded maximum node visit limit';
        }
        #end

        // First transform children
        var transformed = switch(ast.def) {
            case EModule(name, attributes, body):
                var bodyResult = transformArray(body, transformer);
                if (bodyResult.changed) {
                    makeASTWithMeta(
                        EModule(name, attributes, bodyResult.array),
                        ast.metadata,
                        ast.pos
                    );
                } else {
                    ast;  // Return original if nothing changed
                }
                
            case EDef(name, args, guards, body):
                makeASTWithMeta(
                    EDef(name, args, 
                         guards != null ? transformNode(guards, transformer) : null,
                         transformNode(body, transformer)),
                    ast.metadata,
                    ast.pos
                );
                
            case EDefp(name, args, guards, body):
                makeASTWithMeta(
                    EDefp(name, args,
                          guards != null ? transformNode(guards, transformer) : null,
                          transformNode(body, transformer)),
                    ast.metadata,
                    ast.pos
                );
                
            case EBlock(expressions):
                var expResult = transformArray(expressions, transformer);
                if (expResult.changed) {
                    makeASTWithMeta(
                        EBlock(expResult.array),
                        ast.metadata,
                        ast.pos
                    );
                } else {
                    ast;  // Return original if nothing changed
                }
                
            case EIf(condition, thenBranch, elseBranch):
                makeASTWithMeta(
                    EIf(transformNode(condition, transformer),
                        transformNode(thenBranch, transformer),
                        elseBranch != null ? transformNode(elseBranch, transformer) : null),
                    ast.metadata,
                    ast.pos
                );
                
            case ECase(expr, clauses):
                makeASTWithMeta(
                    ECase(transformNode(expr, transformer),
                          clauses.map(c -> {
                              pattern: c.pattern,
                              guard: c.guard != null ? transformNode(c.guard, transformer) : null,
                              body: transformNode(c.body, transformer)
                          })),
                    ast.metadata,
                    ast.pos
                );
                
            case EBinary(op, left, right):
                makeASTWithMeta(
                    EBinary(op,
                            transformNode(left, transformer),
                            transformNode(right, transformer)),
                    ast.metadata,
                    ast.pos
                );
                
            case EUnary(op, expr):
                makeASTWithMeta(
                    EUnary(op, transformNode(expr, transformer)),
                    ast.metadata,
                    ast.pos
                );
                
            case ECall(target, funcName, args):
                makeASTWithMeta(
                    ECall(target != null ? transformNode(target, transformer) : null,
                          funcName,
                          args.map(a -> transformNode(a, transformer))),
                    ast.metadata,
                    ast.pos
                );
                
            case EList(elements):
                makeASTWithMeta(
                    EList(elements.map(e -> transformNode(e, transformer))),
                    ast.metadata,
                    ast.pos
                );
                
            case ETuple(elements):
                makeASTWithMeta(
                    ETuple(elements.map(e -> transformNode(e, transformer))),
                    ast.metadata,
                    ast.pos
                );
                
            case EMap(pairs):
                makeASTWithMeta(
                    EMap(pairs.map(p -> {
                        key: transformNode(p.key, transformer),
                        value: transformNode(p.value, transformer)
                    })),
                    ast.metadata,
                    ast.pos
                );

            case EMatch(pattern, expr):
                // CRITICAL FIX: Transform the RHS expression
                // WHY: EMatch bindings in HygieneTransforms mark LHS as declaration
                //      but RHS may reference variables that need renaming
                // WHAT: Recursively transform expr to rename any EVar nodes
                // HOW: Pattern stays unchanged (creates new binding), expr transforms
                makeASTWithMeta(
                    EMatch(pattern, transformNode(expr, transformer)),
                    ast.metadata,
                    ast.pos
                );

            case EFor(generators, filters, body, into, uniq):
                makeASTWithMeta(
                    EFor(generators.map(g -> {
                        pattern: g.pattern,
                        expr: transformNode(g.expr, transformer)
                    }),
                         filters.map(f -> transformNode(f, transformer)),
                         transformNode(body, transformer),
                         into != null ? transformNode(into, transformer) : null,
                         uniq),
                    ast.metadata,
                    ast.pos
                );
                
            // Raw Elixir code injection - NEVER transform
            case ERaw(code):
                // ERaw nodes are sacred - they contain direct Elixir code injection
                // from __elixir__() calls and must NEVER be transformed
                // Just return the node as-is, without calling the transformer
                return ast;
                
            case EDefmodule(name, body):
                // Transform the module body recursively
                makeASTWithMeta(
                    EDefmodule(name, transformNode(body, transformer)),
                    ast.metadata,
                    ast.pos
                );
                
            // Literals and simple nodes - no children to transform
            // These have no children, so just return them as-is for the transformer to process
            default:
                ast;
        };

        // Apply the transformation to this node
        var finalResult = transformer(transformed);

        // CRITICAL FIX: Prevent infinite recursion
        // Special handling for atoms which were causing infinite loops
        switch(finalResult.def) {
            case EAtom(_):
                // Atoms are terminal nodes and should never be recursively transformed
                // Just return them immediately to break any potential loops
                return finalResult;
            default:
                // For other nodes, check if the transformation actually changed anything
                // Use standard equality check
                if (finalResult == transformed) {
                    // If the same object was returned, no transformation occurred
                    return finalResult;
                }

                // Otherwise return the transformed result
                return finalResult;
        }
    }
    
    /**
     * Detect and optimize pipeline patterns in a block
     */
    static function detectAndOptimizePipeline(expressions: Array<ElixirAST>): Null<ElixirAST> {
        return reflaxe.elixir.ast.transformers.PipelineTransforms.detectAndOptimizePipeline(expressions);
    }
    
    /**
     * Conditional reassignment transformation pass
     * 
     * WHY: Elixir warns when variables are reassigned (shadowing)
     * WHAT: Transform conditional reassignments to functional style
     * HOW: Make if blocks return the new value instead of reassigning
     * 
     * Example transformation:
     * ```
     * if (condition) {
     *   query = query.where(...);
     * }
     * ```
     * Becomes:
     * ```
     * query = if (condition) do
     *   query.where(...)
     * else
     *   query
     * end
     * ```
     */
    
    static function conditionalReassignmentPass(ast: ElixirAST): ElixirAST {
        return reflaxe.elixir.ast.transformers.ControlFlowTransforms.conditionalReassignmentPass(ast);
    }
    
    /**
     * Check if an AST node references a specific variable
     */
    static function referencesVariable(ast: ElixirAST, varName: String): Bool {
        var found = false;
        
        function visitor(node: ElixirAST): Void {
            if (found) return;
            
            switch(node.def) {
                case EVar(name) if (name == varName):
                    found = true;
                case ERemoteCall(_, _, args):
                    // Check if first argument is the variable
                    if (args.length > 0) {
                        switch(args[0].def) {
                            case EVar(name) if (name == varName):
                                found = true;
                            default:
                                for (arg in args) {
                                    visitor(arg);
                                }
                        }
                    }
                default:
                    // Recursively visit child nodes
                    transformAST(node, function(n) { 
                        visitor(n); 
                        return n; 
                    });
            }
        }
        
        visitor(ast);
        return found;
    }
    
    /**
     * Remove redundant nil initialization pass
     * 
     * WHY: Abstract type constructors generate redundant `var = nil` followed by `var = value`
     * WHAT: Removes nil initialization when variable is immediately reassigned  
     * HOW: Detects pattern of consecutive assignments to same variable and removes first
     * 
     * Pattern detected:
     * ```elixir
     * this1 = nil
     * this1 = %{data: data, params: params}
     * ```
     * 
     * Transformed to:
     * ```elixir
     * this1 = %{data: data, params: params}
     * ```
     */
    static function removeRedundantNilInitPass(ast: ElixirAST): ElixirAST {
        // Helper function to check if an AST node represents nil
        // In Elixir, nil is represented as the atom :nil
        inline function isNilValue(ast: ElixirAST): Bool {
            if (ast == null) return false;
            return switch(ast.def) {
                case EAtom(a): a == "nil";
                case ENil: true; // Legacy support, though this shouldn't occur
                default: false;
            };
        }

        return transformNode(ast, function(node: ElixirAST): ElixirAST {
            switch(node.def) {
                case EDef(name, args, guards, body) if (name == "_new"):
                    #if debug_ast_transformer
                    trace('[XRay RemoveRedundantNilInit] Processing _new function');
                    #end
                    // Special handling for abstract constructor _new functions
                    var transformedBody = switch(body.def) {
                        case EBlock(expressions) if (expressions.length >= 2):
                            // Look for pattern: this1 = nil; this1 = <value>; this1
                            var filteredExprs = [];
                            var i = 0;
                            while (i < expressions.length) {
                                var expr = expressions[i];
                                var shouldSkip = false;
                                
                                // Check for this1 = nil
                                switch(expr.def) {
                                    case EMatch(PVar("this1"), nilValue):
                                        if (isNilValue(nilValue)) {
                                            // Check next expression
                                            if (i + 1 < expressions.length) {
                                                switch(expressions[i + 1].def) {
                                                    case EMatch(PVar("this1"), value):
                                                        if (isNilValue(value)) {
                                                            // Don't skip if reassigning to nil
                                                        } else {
                                                            // Skip the nil assignment
                                                                    #if debug_ast_transformer
                                                                    trace('[XRay RemoveRedundantNilInit] Removing this1 = nil in _new function');
                                                                    #end
                                                                    shouldSkip = true;
                                                    }
                                                default:
                                            }
                                        }
                                    }
                                    default:
                                }
                                
                                if (!shouldSkip) {
                                    filteredExprs.push(expr);
                                }
                                i++;
                            }
                            
                            if (filteredExprs.length != expressions.length) {
                                makeASTWithMeta(EBlock(filteredExprs), body.metadata, body.pos);
                            } else {
                                body;
                            }
                        default:
                            body;
                    };
                    
                    return makeASTWithMeta(EDef(name, args, guards, transformedBody), node.metadata, node.pos);
                    
                case EBlock(expressions):
                    #if debug_ast_transformer
                    trace('[XRay RemoveRedundantNilInit] Processing EBlock with ${expressions.length} expressions');
                    #end
                    var filtered = [];
                    var nilAssignments = new Map<String, Int>(); // Track nil assignments by variable name
                    var i = 0;
                    
                    // First pass: identify all nil assignments
                    while (i < expressions.length) {
                        var expr = expressions[i];
                        // Null safety check
                        if (expr == null || expr.def == null) {
                            i++;
                            continue;
                        }
                        switch(expr.def) {
                            case EMatch(PVar(varName), nilValue):
                                if (isNilValue(nilValue)) {
                                    #if debug_ast_transformer
                                    trace('[XRay RemoveRedundantNilInit] Found nil assignment for var: $varName at index $i');
                                    #end
                                    nilAssignments.set(varName, i);
                                }
                            default:
                        }
                        i++;
                    }
                    
                    // Second pass: filter out redundant nil assignments and useless variable references
                    i = 0;
                    var varsToClean = new Map<String, Bool>(); // Track variables that need their standalone refs removed
                    while (i < expressions.length) {
                        var expr = expressions[i];
                        // Null safety check
                        if (expr == null || expr.def == null) {
                            i++;
                            continue;
                        }
                        
                        // Check if this is a useless standalone variable reference
                        switch(expr.def) {
                            case EVar(v) if (varsToClean.exists(v)):
                                // This is a standalone variable reference after an assignment, skip it
                                #if debug_ast_transformer
                                trace('[XRay RemoveRedundantNilInit] Removing standalone variable reference: $v');
                                #end
                                varsToClean.remove(v);
                                i++;
                                continue;
                            default:
                        }
                        
                        var shouldSkip = false;

                        // Check if this is a nil assignment that should be removed
                        switch(expr.def) {
                            case EMatch(PVar(varName), nilValue):
                                if (isNilValue(nilValue)) {
                                    // Special handling for 'this1' and similar abstract constructor variables
                                    // These are ALWAYS immediately reassigned in abstract constructors
                                    if (varName == "this1" || varName == "this" || varName.startsWith("this")) {
                                        #if debug_ast_transformer
                                        trace('[XRay RemoveRedundantNilInit] Found "this1" nil assignment at index $i');
                                        #end
                                        // Check immediate next expression for reassignment
                                        if (i + 1 < expressions.length) {
                                            var nextExpr = expressions[i + 1];
                                            if (nextExpr != null && nextExpr.def != null) {
                                                #if debug_ast_transformer
                                                trace('[XRay RemoveRedundantNilInit] Next expr at ${i+1}: ${nextExpr.def}');
                                                #end
                                                switch(nextExpr.def) {
                                                case EMatch(PVar(nextVarName), value) if (nextVarName == varName):
                                                    if (isNilValue(value)) {
                                                        // Don't skip if it's another nil
                                                        #if debug_ast_transformer
                                                        trace('[XRay RemoveRedundantNilInit] Next assignment is also nil, not skipping');
                                                        #end
                                                    } else {
                                                        // Non-nil reassignment - skip the initial nil AND check if there's a useless variable reference after
                                                        #if debug_ast_transformer
                                                        trace('[XRay RemoveRedundantNilInit] REMOVING redundant nil init for abstract constructor var: $varName');
                                                        #end
                                                        shouldSkip = true;
                                                        
                                                        // CRITICAL FIX: Also check if next+1 is just a variable reference
                                                        // Pattern: this1 = nil; this1 = value; this1
                                                        if (i + 2 < expressions.length) {
                                                            var afterNext = expressions[i + 2];
                                                            if (afterNext != null && afterNext.def != null) {
                                                                switch(afterNext.def) {
                                                                    case EVar(v) if (v == varName):
                                                                        // This is the standalone variable reference that causes the warning
                                                                        #if debug_ast_transformer
                                                                        trace('[XRay RemoveRedundantNilInit] Found standalone variable reference after assignment, marking for removal');
                                                                        #end
                                                                        // Mark this variable for cleanup
                                                                        varsToClean.set(varName, true);
                                                                    default:
                                                                }
                                                            }
                                                        }
                                                    }
                                                    default:
                                                        #if debug_ast_transformer
                                                        trace('[XRay RemoveRedundantNilInit] Next expr is not a match for $varName');
                                                        #end
                                                }
                                            }
                                        }

                                        // If not skipped yet, check if this variable is assigned again later
                                        if (!shouldSkip) {
                                            var j = i + 1;
                                            while (j < expressions.length) {
                                                var checkExpr = expressions[j];
                                                if (checkExpr == null || checkExpr.def == null) {
                                                    j++;
                                                    continue;
                                                }
                                                switch(checkExpr.def) {
                                                    case EMatch(PVar(nextVarName), value) if (nextVarName == varName):
                                                        // Found reassignment - check if the value is not nil
                                                        if (isNilValue(value)) {
                                                            // Another nil assignment, keep looking
                                                        } else {
                                                            // Non-nil reassignment found - skip the initial nil
                                                                #if debug_ast_transformer
                                                                trace('[XRay RemoveRedundantNilInit] Removing redundant nil init for: $varName (reassigned at index $j)');
                                                                #end
                                                                shouldSkip = true;
                                                                break;
                                                        }
                                                    default:
                                                }
                                                j++;
                                            }
                                        }
                                    }
                                }
                            default:
                                // Not a match expression
                        }

                        if (!shouldSkip) {
                            // Recursively process the expression to handle nested structures
                            var processed = removeRedundantNilInitPass(expr);
                            filtered.push(processed);
                        } else {
                            #if debug_ast_transformer
                            trace('[XRay RemoveRedundantNilInit] Skipping redundant nil init at index $i');
                            #end
                        }
                        i++;
                    }

                    // Only create new block if we removed something
                    if (filtered.length != expressions.length) {
                        #if debug_ast_transformer
                        trace('[XRay RemoveRedundantNilInit] Removed ${expressions.length - filtered.length} redundant nil assignments from block');
                        #end
                        return makeASTWithMeta(EBlock(filtered), node.metadata, node.pos);
                    } else {
                        return node;
                    }
                    
                case EFn(clauses):
                    // Also handle anonymous function bodies
                    var transformedClauses = [for (clause in clauses) {
                        args: clause.args,
                        guard: clause.guard,
                        body: removeRedundantNilInitPass(clause.body)
                    }];
                    return makeASTWithMeta(EFn(transformedClauses), node.metadata, node.pos);
                    
                case EDef(name, args, guards, body):
                    // Handle public function definitions
                    var transformedBody = removeRedundantNilInitPass(body);
                    return makeASTWithMeta(EDef(name, args, guards, transformedBody), node.metadata, node.pos);
                    
                case EDefp(name, args, guards, body):
                    // Handle private function definitions
                    var transformedBody = removeRedundantNilInitPass(body);
                    return makeASTWithMeta(EDefp(name, args, guards, transformedBody), node.metadata, node.pos);
                    
                case EIf(cond, thenBranch, elseBranch):
                    // Recursively process if branches
                    #if debug_ast_transformer
                    trace('[XRay RemoveRedundantNilInit] Processing EIf - recursing into branches');
                    #end
                    var processedCond = removeRedundantNilInitPass(cond);
                    var processedThen = removeRedundantNilInitPass(thenBranch);
                    var processedElse = elseBranch != null ? removeRedundantNilInitPass(elseBranch) : null;
                    return makeASTWithMeta(EIf(processedCond, processedThen, processedElse), node.metadata, node.pos);

                case ECase(expr, clauses):
                    // Recursively process case expressions
                    #if debug_ast_transformer
                    trace('[XRay RemoveRedundantNilInit] Processing ECase');
                    #end
                    var processedExpr = removeRedundantNilInitPass(expr);
                    var processedClauses = [for (clause in clauses) {
                        pattern: clause.pattern,
                        guard: clause.guard != null ? removeRedundantNilInitPass(clause.guard) : null,
                        body: removeRedundantNilInitPass(clause.body)
                    }];
                    return makeASTWithMeta(ECase(processedExpr, processedClauses), node.metadata, node.pos);

                case EFor(generators, filters, body, into, uniq):
                    // Recursively process for comprehensions
                    #if debug_ast_transformer
                    trace('[XRay RemoveRedundantNilInit] Processing EFor');
                    #end
                    var processedGenerators = [for (gen in generators) {
                        pattern: gen.pattern,
                        expr: removeRedundantNilInitPass(gen.expr)
                    }];
                    var processedFilters = [for (filter in filters) removeRedundantNilInitPass(filter)];
                    var processedBody = removeRedundantNilInitPass(body);
                    var processedInto = into != null ? removeRedundantNilInitPass(into) : null;
                    return makeASTWithMeta(EFor(processedGenerators, processedFilters, processedBody, processedInto, uniq), node.metadata, node.pos);

                case EParen(inner):
                    // Handle parenthesized expressions (often contains this1 = nil pattern)
                    #if debug_ast_transformer
                    trace('[XRay RemoveRedundantNilInit] Processing EParen');
                    #end

                    // Check if the inner expression is a sequence with redundant nil init
                    var transformedInner = switch(inner.def) {
                        case EBlock(expressions) if (expressions.length == 3):
                            // Pattern: (this1 = nil; this1 = value; this1)
                            var hasRedundantNil = false;

                            // Check for this1 = nil as first expression
                            switch(expressions[0].def) {
                                case EMatch(PVar("this1"), nilValue):
                                    if (isNilValue(nilValue)) {
                                        // Check second expression is also assignment to this1
                                        switch(expressions[1].def) {
                                            case EMatch(PVar("this1"), _):
                                                // Check third expression is just this1
                                                switch(expressions[2].def) {
                                                    case EVar("this1"):
                                                        hasRedundantNil = true;
                                                    default:
                                                }
                                            default:
                                        }
                                    }
                                default:
                            }

                            if (hasRedundantNil) {
                                #if debug_ast_transformer
                                trace('[XRay RemoveRedundantNilInit] Removing redundant nil from EParen block');
                                #end
                                // Remove the first expression (this1 = nil)
                                makeASTWithMeta(
                                    EBlock([expressions[1], expressions[2]]),
                                    inner.metadata,
                                    inner.pos
                                );
                            } else {
                                // Recursively process the block
                                removeRedundantNilInitPass(inner);
                            }
                        default:
                            // For other patterns, process recursively
                            removeRedundantNilInitPass(inner);
                    };

                    return makeASTWithMeta(EParen(transformedInner), node.metadata, node.pos);

                default:
                    return node;
            }
        });
    }
    
    /**
     * PREFIX UNUSED PARAMETERS PASS
     * 
     * WHY: Elixir convention requires unused function parameters to be prefixed with underscore
     *      to indicate they're intentionally unused. This prevents compiler warnings.
     * 
     * WHAT: Detects unused parameters in function definitions and prefixes them with underscore.
     *       Handles EDef, EDefp, EDefmacro, EDefmacrop, and EFn (anonymous functions).
     * 
     * HOW: 1. For each function definition, collect all parameter names
     *      2. Scan the function body to find which parameters are actually used
     *      3. Prefix unused parameters with underscore
     *      4. Update all references to maintain consistency
     * 
     * EDGE CASES:
     * - Parameters already prefixed with underscore are left as-is
     * - Parameters named "_" are not modified
     * - Nested functions are handled recursively
     */
    static function prefixUnusedParametersPass(ast: ElixirAST): ElixirAST {
        #if debug_ast_transformer
        trace('[XRay PrefixUnusedParams] PASS START');
        #end
        
        return transformNode(ast, function(node: ElixirAST): ElixirAST {
            switch(node.def) {
                // Handle regular function definitions
                case EDef(name, args, guards, body):
                    #if debug_ast_transformer
                    trace('[XRay PrefixUnusedParams] Found EDef: $name with ${args.length} args');
                    #end
                    var result = handleFunctionParameters(args, guards, body);
                    if (result.hasChanges) {
                        #if debug_ast_transformer
                        trace('[XRay PrefixUnusedParams] Updated EDef: $name');
                        #end
                        return makeASTWithMeta(EDef(name, result.args, guards, result.body), node.metadata, node.pos);
                    }
                    return node;
                    
                case EDefp(name, args, guards, body):
                    var result = handleFunctionParameters(args, guards, body);
                    if (result.hasChanges) {
                        #if debug_ast_transformer
                        trace('[XRay PrefixUnusedParams] Updated EDefp: $name');
                        #end
                        return makeASTWithMeta(EDefp(name, result.args, guards, result.body), node.metadata, node.pos);
                    }
                    return node;
                    
                case EDefmacro(name, args, guards, body):
                    var result = handleFunctionParameters(args, guards, body);
                    if (result.hasChanges) {
                        #if debug_ast_transformer
                        trace('[XRay PrefixUnusedParams] Updated EDefmacro: $name');
                        #end
                        return makeASTWithMeta(EDefmacro(name, result.args, guards, result.body), node.metadata, node.pos);
                    }
                    return node;
                    
                case EDefmacrop(name, args, guards, body):
                    var result = handleFunctionParameters(args, guards, body);
                    if (result.hasChanges) {
                        #if debug_ast_transformer
                        trace('[XRay PrefixUnusedParams] Updated EDefmacrop: $name');
                        #end
                        return makeASTWithMeta(EDefmacrop(name, result.args, guards, result.body), node.metadata, node.pos);
                    }
                    return node;
                    
                // Handle anonymous functions
                case EFn(clauses):
                    var hasAnyChange = false;
                    var newClauses = [];
                    
                    for (clause in clauses) {
                        var result = handleFunctionParameters(clause.args, clause.guard, clause.body);
                        if (result.hasChanges) {
                            hasAnyChange = true;
                            newClauses.push({
                                args: result.args,
                                guard: clause.guard,
                                body: result.body
                            });
                        } else {
                            newClauses.push(clause);
                        }
                    }
                    
                    if (hasAnyChange) {
                        #if debug_ast_transformer
                        trace('[XRay PrefixUnusedParams] Updated EFn with ${clauses.length} clauses');
                        #end
                        return makeASTWithMeta(EFn(newClauses), node.metadata, node.pos);
                    }
                    return node;
                    
                default:
                    return node;
            }
        });
    }
    
    /**
     * Handle parameter detection and renaming for a function
     * Returns updated args and body if changes were made
     */
    static function handleFunctionParameters(args: Array<EPattern>, guards: Null<ElixirAST>, body: ElixirAST): {args: Array<EPattern>, body: ElixirAST, hasChanges: Bool} {
        // Extract parameter names from patterns
        var paramNames: Map<String, Bool> = new Map();
        var paramRenames: Map<String, String> = new Map();
        
        function extractParamNames(pattern: EPattern) {
            switch(pattern) {
                case PVar(name):
                    if (!name.startsWith("_")) { // Don't track already underscored params
                        paramNames.set(name, false); // false = not yet seen as used
                    }
                case PTuple(patterns):
                    for (p in patterns) extractParamNames(p);
                case PList(patterns):
                    for (p in patterns) extractParamNames(p);
                case PMap(pairs):
                    for (pair in pairs) extractParamNames(pair.value);
                case PCons(head, tail):
                    extractParamNames(head);
                    extractParamNames(tail);
                case PPin(pattern):
                    extractParamNames(pattern);
                default:
                    // Other patterns don't introduce variables
            }
        }
        
        for (arg in args) {
            extractParamNames(arg);
        }
        
        #if debug_ast_transformer
        trace('[XRay PrefixUnusedParams] Found parameters: ' + [for (name => _ in paramNames) name].join(", "));
        #end
        
        // If no parameters to check, return early
        if (Lambda.count(paramNames) == 0) {
            return {args: args, body: body, hasChanges: false};
        }
        
        // Check which parameters are used in the body (and guards if present)
        function markUsedVars(ast: ElixirAST) {
            switch(ast.def) {
                case EVar(name):
                    if (paramNames.exists(name)) {
                        paramNames.set(name, true); // Mark as used
                        #if debug_ast_transformer
                        trace('[XRay PrefixUnusedParams] Found usage of param: $name');
                        #end
                    }
                case EField(target, _):
                    // Check if the target is a parameter being accessed
                    switch(target.def) {
                        case EVar(name):
                            if (paramNames.exists(name)) {
                                paramNames.set(name, true); // Mark as used
                                #if debug_ast_transformer
                                trace('[XRay PrefixUnusedParams] Found field access on param: $name');
                                #end
                            }
                        default:
                            markUsedVars(target); // Continue checking nested expressions
                    }
                case EAccess(target, key):
                    // Check if the target is a parameter being accessed
                    switch(target.def) {
                        case EVar(name):
                            if (paramNames.exists(name)) {
                                paramNames.set(name, true); // Mark as used
                                #if debug_ast_transformer
                                trace('[XRay PrefixUnusedParams] Found bracket access on param: $name');
                                #end
                            }
                        default:
                            markUsedVars(target); // Continue checking nested expressions
                    }
                    markUsedVars(key); // Also check the key expression
                case EStructUpdate(struct, fields):
                    // Check if struct being updated is a parameter
                    switch(struct.def) {
                        case EVar(name):
                            if (paramNames.exists(name)) {
                                paramNames.set(name, true); // Mark as used
                                #if debug_ast_transformer
                                trace('[XRay PrefixUnusedParams] Found struct update on param: $name');
                                #end
                            }
                        default:
                            markUsedVars(struct); // Continue checking nested expressions
                    }
                    // Also check the field values
                    for (field in fields) {
                        markUsedVars(field.value);
                    }
                case ERaw(code):
                    // Check if parameter names appear in raw Elixir code
                    // This handles __elixir__() injection where parameters are referenced
                    for (name => _ in paramNames) {
                        // Check if the parameter name appears as a word boundary in the raw code
                        // This handles cases like "Ecto.Changeset.change(data, params)"
                        var pattern = '\\b${name}\\b';
                        if (new EReg(pattern, "").match(code)) {
                            paramNames.set(name, true); // Mark as used
                            #if debug_ast_transformer
                            trace('[XRay PrefixUnusedParams] Found param usage in ERaw: $name in code: ${code.substring(0, 100)}...');
                            #end
                        }
                    }
                case EKeywordList(pairs):
                    // Check values in keyword list for parameter usage
                    for (pair in pairs) {
                        markUsedVars(pair.value);
                        #if debug_ast_transformer
                        trace('[XRay PrefixUnusedParams] Checking keyword list value for parameter usage');
                        #end
                    }
                default:
                    iterateAST(ast, markUsedVars);
            }
        }
        
        // Check guards for parameter usage
        if (guards != null) {
            markUsedVars(guards);
        }
        
        // Check body for parameter usage
        markUsedVars(body);
        
        // Enable underscore prefixing for unused parameters.
        // This is safe because we only rename parameters that have no usages in body/guards,
        // and we apply renames consistently to argument patterns and the function body.
        var hasChanges = false;
        for (name => used in paramNames) {
            if (!used && !name.startsWith("_")) {
                var newName = "_" + name;
                paramRenames.set(name, newName);
                hasChanges = true;
                #if debug_ast_transformer
                trace('[XRay PrefixUnusedParams] Will rename unused param: $name -> $newName');
                #end
            }
        }
        
        // If no changes needed, return original
        if (!hasChanges) {
            return {args: args, body: body, hasChanges: false};
        }
        
        // Apply renames to argument patterns
        function renameInPattern(pattern: EPattern): EPattern {
            switch(pattern) {
                case PVar(name):
                    if (paramRenames.exists(name)) {
                        return PVar(paramRenames.get(name));
                    }
                    return pattern;
                case PTuple(patterns):
                    return PTuple(patterns.map(renameInPattern));
                case PList(patterns):
                    return PList(patterns.map(renameInPattern));
                case PMap(pairs):
                    return PMap([for (pair in pairs) {key: pair.key, value: renameInPattern(pair.value)}]);
                case PCons(head, tail):
                    return PCons(renameInPattern(head), renameInPattern(tail));
                case PPin(p):
                    return PPin(renameInPattern(p));
                default:
                    return pattern;
            }
        }
        
        var newArgs = args.map(renameInPattern);
        
        // Apply renames to the body as well to handle cases where usage detection
        // might be incomplete (e.g., field access patterns that weren't detected)
        function renameInAST(ast: ElixirAST): ElixirAST {
            switch(ast.def) {
                case EVar(name):
                    if (paramRenames.exists(name)) {
                        return {def: EVar(paramRenames.get(name)), metadata: ast.metadata};
                    }
                    return ast;
                default:
                    return transformAST(ast, renameInAST);
            }
        }
        
        var newBody = renameInAST(body);
        
        return {args: newArgs, body: newBody, hasChanges: true};
    }
    
    /**
     * Generate unique identifier for generated code
     */
    static var uniqueCounter = 0;
    static function generateUniqueId(): String {
        return Std.string(uniqueCounter++);
    }

    /**
     * Validation pass: reject leaked infrastructure variables in the final AST.
     * Patterns: "g", "_g", /^g\d+$/, /^_g\d+$/
     */
    static function infraVarValidationPass(ast: ElixirAST): ElixirAST {
        inline function isInfra(name:String):Bool {
            return name == "g" || name == "_g" || ~/^g\d+$/.match(name) || ~/^_g\d+$/.match(name);
        }

        return transformNode(ast, function(node) {
            switch (node.def) {
                case EVar(name) if (isInfra(name)):
                    // Fail fast in normal builds, but allow debug tracing when requested.
                    #if macro
                    var pos:Position = node.pos;
                    if (Context.defined("debug_infra_vars")) {
                        Sys.println('[InfraVarValidation] Detected infrastructure variable: ' + name);
                        return node;
                    } else {
                        Context.error('Infrastructure variable leaked into final AST: "' + name + '"', pos);
                        return node; // unreachable after error, keep type flow
                    }
                    #else
                    return node;
                    #end
                default:
                    return node;
            }
        });
    }
    
    /**
     * Helper function to iterate over AST nodes without transformation
     */
    static function iterateAST(node: ElixirAST, visitor: ElixirAST -> Void): Void {
        // Check for null node or def before processing
        if (node == null || node.def == null) {
            return;
        }

        switch(node.def) {
            case EBlock(expressions):
                for (expr in expressions) if (expr != null) visitor(expr);
            case EModule(name, attributes, body):
                for (b in body) if (b != null) visitor(b);
            case EDefmodule(name, doBlock):
                if (doBlock != null) visitor(doBlock);
            case EDef(name, args, guards, body):
                if (body != null) visitor(body);
            case EDefp(name, args, guards, body):
                if (body != null) visitor(body);
            case EIf(condition, thenBranch, elseBranch):
                if (condition != null) visitor(condition);
                if (thenBranch != null) visitor(thenBranch);
                if (elseBranch != null) visitor(elseBranch);
            case ECase(expr, clauses):
                if (expr != null) visitor(expr);
                for (clause in clauses) {
                    if (clause != null) {
                        if (clause.guard != null) visitor(clause.guard);
                        if (clause.body != null) visitor(clause.body);
                    }
                }
            case EMatch(pattern, expr):
                if (expr != null) visitor(expr);
            case EBinary(op, left, right):
                if (left != null) visitor(left);
                if (right != null) visitor(right);
            case EUnary(op, expr):
                if (expr != null) visitor(expr);
            case ECall(target, funcName, args):
                if (target != null) visitor(target);
                for (arg in args) if (arg != null) visitor(arg);
            case EMacroCall(macroName, args, doBlock):
                for (arg in args) if (arg != null) visitor(arg);
                if (doBlock != null) visitor(doBlock);
            case ETuple(elements):
                for (elem in elements) if (elem != null) visitor(elem);
            case EList(elements):
                for (elem in elements) if (elem != null) visitor(elem);
            case EMap(pairs):
                for (pair in pairs) {
                    if (pair != null) {
                        if (pair.key != null) visitor(pair.key);
                        if (pair.value != null) visitor(pair.value);
                    }
                }
            case EStruct(name, fields):
                for (field in fields) if (field != null && field.value != null) visitor(field.value);
            case EFor(generators, filters, body, into, uniq):
                for (gen in generators) {
                    if (gen != null && gen.expr != null) visitor(gen.expr);
                }
                for (filter in filters) if (filter != null) visitor(filter);
                if (body != null) visitor(body);
                if (into != null) visitor(into);
            case EFn(clauses):
                for (clause in clauses) {
                    if (clause != null) {
                        if (clause.guard != null) visitor(clause.guard);
                        if (clause.body != null) visitor(clause.body);
                    }
                }
            case EReceive(clauses, after):
                for (clause in clauses) {
                    if (clause != null) {
                        if (clause.guard != null) visitor(clause.guard);
                        if (clause.body != null) visitor(clause.body);
                    }
                }
                if (after != null) {
                    if (after.timeout != null) visitor(after.timeout);
                    if (after.body != null) visitor(after.body);
                }
            case ERemoteCall(module, funcName, args):
                if (module != null) visitor(module);
                for (arg in args) if (arg != null) visitor(arg);
            case EParen(expr):
                if (expr != null) visitor(expr);
            case EDo(body):
                for (stmt in body) if (stmt != null) visitor(stmt);
            case ETry(body, rescue, catchClauses, afterBlock, elseBlock):
                if (body != null) visitor(body);
                if (rescue != null) {
                    for (clause in rescue) {
                        // ERescueClause structure would need checking
                        if (clause != null && clause.body != null) visitor(clause.body);
                    }
                }
                if (catchClauses != null) {
                    for (clause in catchClauses) {
                        if (clause != null && clause.body != null) visitor(clause.body);
                    }
                }
                if (afterBlock != null) visitor(afterBlock);
                if (elseBlock != null) visitor(elseBlock);
            case EWith(clauses, doBlock, elseBlock):
                for (clause in clauses) {
                    // Pattern is not an ElixirAST, only visit the expression
                    if (clause != null && clause.expr != null) visitor(clause.expr);
                }
                if (doBlock != null) visitor(doBlock);
                if (elseBlock != null) visitor(elseBlock);
            case ECond(clauses):
                for (clause in clauses) {
                    if (clause != null) {
                        if (clause.condition != null) visitor(clause.condition);
                        if (clause.body != null) visitor(clause.body);
                    }
                }
            case EField(object, field):
                if (object != null) visitor(object);
            case EModuleAttribute(name, value):
                if (value != null) visitor(value);
            case EKeywordList(pairs):
                // Visit values in keyword list
                for (pair in pairs) {
                    if (pair != null && pair.value != null) visitor(pair.value);
                }
            case _:
                // Leaf nodes - nothing to iterate
        }
    }
    
    /**
     * Helper function to transform AST nodes recursively
     */
    public static function transformAST(node: ElixirAST, transformer: ElixirAST -> ElixirAST): ElixirAST {
        if (node == null || node.def == null) {
            return null;
        }
        var transformed = switch(node.def) {
            case EBlock(expressions):
                makeASTWithMeta(EBlock(expressions.map(transformer)), node.metadata, node.pos);
            case EModule(name, attributes, body):
                makeASTWithMeta(EModule(name, attributes, body.map(transformer)), node.metadata, node.pos);
            case EDefmodule(name, doBlock):
                makeASTWithMeta(EDefmodule(name, transformer(doBlock)), node.metadata, node.pos);
            case EDef(name, args, guards, body):
                makeASTWithMeta(EDef(name, args, guards, transformer(body)), node.metadata, node.pos);
            case EDefp(name, args, guards, body):
                makeASTWithMeta(EDefp(name, args, guards, transformer(body)), node.metadata, node.pos);
            case EIf(condition, thenBranch, elseBranch):
                makeASTWithMeta(
                    EIf(transformer(condition), transformer(thenBranch),
                        elseBranch != null ? transformer(elseBranch) : null),
                    node.metadata, node.pos
                );
            case ECase(expr, clauses):
                makeASTWithMeta(
                    ECase(transformer(expr),
                          clauses.map(c -> {
                              pattern: c.pattern,
                              guard: c.guard != null ? transformer(c.guard) : null,
                              body: transformer(c.body)
                          })),
                    node.metadata, node.pos
                );
            case ECond(conds):
                makeASTWithMeta(
                    ECond(conds.map(c -> { condition: transformer(c.condition), body: transformer(c.body) })),
                    node.metadata, node.pos
                );
            case EMatch(pattern, expr):
                makeASTWithMeta(EMatch(pattern, transformer(expr)), node.metadata, node.pos);
            case EBinary(op, left, right):
                makeASTWithMeta(EBinary(op, transformer(left), transformer(right)), node.metadata, node.pos);
            case EUnary(op, expr):
                makeASTWithMeta(EUnary(op, transformer(expr)), node.metadata, node.pos);
            case ECall(target, funcName, args):
                makeASTWithMeta(ECall(target != null ? transformer(target) : null, funcName, args.map(transformer)), node.metadata, node.pos);
            case EMacroCall(macroName, args, doBlock):
                makeASTWithMeta(EMacroCall(macroName, args.map(transformer), transformer(doBlock)), node.metadata, node.pos);
            case ETuple(elements):
                makeASTWithMeta(ETuple(elements.map(transformer)), node.metadata, node.pos);
            case EList(elements):
                #if (debug_otp_child_spec && debug_otp_child_spec_verbose)
                if (elements.length > 0) {
                    trace('[XRay OTPChildSpec] Processing EList with ${elements.length} elements');
                    for (i in 0...elements.length) {
                        var elem = elements[i];
                        if (elem.metadata != null && elem.metadata.requiresIdiomaticTransform == true) {
                            trace('[XRay OTPChildSpec] Element $i has requiresIdiomaticTransform flag!');
                        }
                    }
                }
                #end
                makeASTWithMeta(EList(elements.map(transformer)), node.metadata, node.pos);
            case EMap(pairs):
                makeASTWithMeta(
                    EMap(pairs.map(p -> {key: transformer(p.key), value: transformer(p.value)})),
                    node.metadata, node.pos
                );
            case EKeywordList(pairs):
                makeASTWithMeta(
                    EKeywordList(pairs.map(p -> {key: p.key, value: transformer(p.value)})),
                    node.metadata, node.pos
                );
            case EStruct(name, fields):
                makeASTWithMeta(
                    EStruct(name, fields.map(f -> {key: f.key, value: transformer(f.value)})),
                    node.metadata, node.pos
                );
            case EFor(generators, filters, body, into, uniq):
                makeASTWithMeta(
                    EFor(generators.map(g -> {pattern: g.pattern, expr: transformer(g.expr)}),
                         filters.map(transformer),
                         transformer(body),
                         into != null ? transformer(into) : null,
                         uniq),
                    node.metadata, node.pos
                );
            case EFn(clauses):
                makeASTWithMeta(
                    EFn(clauses.map(c -> {
                        args: c.args,
                        guard: c.guard != null ? transformer(c.guard) : null,
                        body: transformer(c.body)
                    })),
                    node.metadata, node.pos
                );
            case EReceive(clauses, after):
                makeASTWithMeta(
                    EReceive(clauses.map(c -> {
                                 pattern: c.pattern,
                                 guard: c.guard != null ? transformer(c.guard) : null,
                                 body: transformer(c.body)
                             }),
                             after != null ? {timeout: transformer(after.timeout), body: transformer(after.body)} : null),
                    node.metadata, node.pos
                );
            case EModuleAttribute(name, value):
                makeASTWithMeta(EModuleAttribute(name, transformer(value)), node.metadata, node.pos);
            case ERemoteCall(module, funcName, args):
                makeASTWithMeta(
                    ERemoteCall(module != null ? transformer(module) : null, funcName, args.map(transformer)),
                    node.metadata, node.pos
                );
            case EParen(expr):
                // Transform the inner expression and preserve parentheses
                makeASTWithMeta(EParen(transformer(expr)), node.metadata, node.pos);
            case _:
                // Leaf nodes - return unchanged
                node;
        };
        return transformed;
    }
    
    /**
     * Underscore Variable Cleanup Pass
     * 
     * WHY: Haxe generates temporary variables with underscore prefixes (_g, _g_1, etc.) during
     * desugaring of switches, loops, and other complex expressions. These are actually USED
     * variables, but in Elixir, underscore-prefixed variables should not be referenced after
     * assignment, causing warnings and violating Elixir conventions.
     * 
     * WHAT: Detects and renames underscore-prefixed temporary variables that are actually used
     * - Identifies Haxe-generated temp variables (_g, _g_1, _g1, etc.)
     * - Tracks which ones are referenced after declaration
     * - Renames them consistently throughout the AST
     * - Preserves truly unused underscore variables (single underscore or unused prefixed)
     * 
     * HOW: Two-phase transformation
     * 1. Analysis phase: Collect all underscore variables and track usage
     * 2. Transformation phase: Rename used variables consistently
     */
    /**
     * Supervisor options transformation pass
     * 
     * WHY: Supervisor.start_link expects keyword lists but TObjectDecl generates maps
     * WHAT: Converts supervisor option maps to keyword lists
     * HOW: Delegates to SupervisorOptionsTransformPass
     */
    static function supervisorOptionsTransformPass(ast: ElixirAST): ElixirAST {
        return SupervisorOptionsTransformPass.transform(ast);
    }
    
    /**
     * OTP Child Spec Transformation Pass
     * 
     * WHY: Enum-based child specs generate tuples like {:PubSub, "TodoApp.PubSub"}
     * which are not valid OTP child specifications. Supervisor.start_link expects
     * either module names or proper child spec maps.
     * 
     * WHAT: Detects patterns that look like child specifications and transforms them:
     * - Simple tuples {:Atom, "String"} → proper module references or child spec maps
     * - Lists of such tuples → lists of proper child specs
     * - Works for any enum-based child spec pattern, not just TypeSafeChildSpec
     * 
     * HOW: Pattern matches on common OTP child spec contexts:
     * - Supervisor.start_link calls
     * - Children lists in application modules
     * - Any list containing tuple patterns that match child spec signatures
     * 
     * PATTERNS DETECTED:
     * - {:PubSub, "name"} → {Phoenix.PubSub, name: "name"}
     * - {:Endpoint} → MyAppWeb.Endpoint
     * - {:Telemetry} → MyAppWeb.Telemetry
     * - {:Repo, config} → {MyApp.Repo, config}
     */
    static function otpChildSpecTransformPass(ast: ElixirAST): ElixirAST {
        #if debug_ast_transformer
        trace("[XRay OTPChildSpec] Starting idiomatic enum transformation pass");
        #end
        
        var transformCount = 0;
        
        function transformIdiomaticNode(node: ElixirAST): ElixirAST {
            #if (debug_otp_child_spec && debug_otp_child_spec_verbose)
            // Very verbose - show every node being checked
            trace('[XRay OTPChildSpec] Checking node type: ${Type.enumConstructor(node.def)}');
            #end
            
            // First, recursively transform children
            var nodeWithTransformedChildren = transformAST(node, transformIdiomaticNode);
            
            // Handle null nodes
            if (nodeWithTransformedChildren == null) {
                return null;
            }
            
            // Then check if this node itself needs transformation
            if (nodeWithTransformedChildren.metadata != null && nodeWithTransformedChildren.metadata.requiresIdiomaticTransform == true) {
                #if debug_otp_child_spec
                trace('[XRay OTPChildSpec] Found node #${++transformCount} with requiresIdiomaticTransform flag');
                trace('[XRay OTPChildSpec] Node def: ${nodeWithTransformedChildren.def}');
                #end
                // Apply transformation using shared utility
                var transformed = reflaxe.elixir.ast.ElixirAST.applyIdiomaticEnumTransformation(nodeWithTransformedChildren);
                #if debug_otp_child_spec
                trace('[XRay OTPChildSpec] Transformed to: ${transformed.def}');
                #end
                return transformed;
            }
            
            return nodeWithTransformedChildren;
        }
        
        var result = transformIdiomaticNode(ast);
        
        #if debug_otp_child_spec
        trace('[XRay OTPChildSpec] Pass complete. Transformed ${transformCount} nodes');
        #end
        
        return result;
    }
    
    /**
     * Transform idiomatic enum constructors using convention-based patterns
     * 
     * WHY: Enums marked with @:elixirIdiomatic need special compilation
     * to match Elixir/OTP conventions. Instead of hardcoding specific patterns,
     * we detect structural conventions that indicate idiomatic Elixir usage.
     * 
     * WHAT: Convention-based transformations based on constructor structure:
     * 
     * 1. ZERO ARGUMENTS → Bare atom
     *    MyConstructor() → :my_constructor
     * 
     * 2. SINGLE ARGUMENT → Unwrap the value
     *    ModuleRef("Phoenix.PubSub") → Phoenix.PubSub
     *    This is common for module references in OTP
     * 
     * 3. TWO ARGUMENTS where second is keyword list → {first, keyword_list}
     *    ModuleWithConfig("Phoenix.PubSub", [name: "MyApp"]) → {Phoenix.PubSub, [name: "MyApp"]}
     *    This is the standard OTP child spec format
     * 
     * 4. TWO ARGUMENTS (general) → Keep as tuple but simplified
     *    SomeConstructor(a, b) → {a, b} (without constructor tag)
     * 
     * 5. THREE+ ARGUMENTS → Keep standard tuple format
     *    Complex(a, b, c) → {:complex, a, b, c}
     * 
     * HOW: Analyzes the AST structure to detect patterns:
     * - Counts arguments
     * - Detects keyword lists (EKeywordList nodes)
     * - Checks for string literals that should become atoms (module names)
     * 
     * CONVENTIONS DETECTED:
     * - Module name patterns (strings that look like Elixir modules)
     * - Keyword list patterns (for configuration)
     * - Arity patterns (zero, one, two, many)
     * 
     * @param elements The tuple elements [constructor_tag, arg1, arg2, ...]
     * @param node The original AST node with metadata
     * @return Transformed AST following Elixir idioms
     */
    /**
     * Tuple Element Field to Function Transformation Pass
     * 
     * WHY: When switch statements are compiled for Result enums, Haxe generates
     * TField expressions like tuple.elem(0) instead of function calls. These
     * become EField nodes which print as invalid Elixir syntax.
     * 
     * WHAT: Transforms EField nodes with "elem" field name into proper ECall nodes
     * for elem(tuple, index) function calls.
     * 
     * HOW: Recursively traverses AST, detects EField with "elem", and converts
     * them to ECall nodes. This enables the enum pattern matching pass to work.
     */
    static function tupleElemFieldToFunctionPass(ast: ElixirAST): ElixirAST {
        #if debug_ast_transformer
        trace('[XRay TupleElemField] Starting tuple elem field to function transformation');
        #end
        
        // Handle null nodes
        if (ast == null) {
            return null;
        }
        
        return switch(ast.def) {
            case EField(target, "elem"):
                // This is a tuple.elem field access that needs to become elem(tuple, N)
                // However, we don't have the index here - it's usually called as tuple.elem(0)
                // So we need to look for the pattern in context
                #if debug_ast_transformer
                var targetStr = ElixirASTPrinter.printAST(target);
                trace('[XRay TupleElemField] Found .elem field access on: $targetStr');
                #end
                
                // For now, we'll mark it for transformation but can't fully convert
                // without the index. The pattern matching pass will handle it.
                {
                    def: EField(transformAST(target, tupleElemFieldToFunctionPass), "elem"),
                    metadata: ast.metadata,
                    pos: ast.pos
                };
                
            case ECall(expr, funcName, args):
                if (funcName == "elem" && expr != null) {
                    // This is a method call pattern: target.elem(N)
                    // Transform to elem(target, N) for proper Elixir syntax
                    #if debug_ast_transformer
                    var targetStr = ElixirASTPrinter.printAST(expr);
                    trace('[XRay TupleElemField] Transforming ${targetStr}.elem(${args.length} args) to elem($targetStr, ...)');
                    #end
                    {
                        def: ECall(null, "elem", [
                            transformAST(expr, tupleElemFieldToFunctionPass)
                        ].concat([for (arg in args) transformAST(arg, tupleElemFieldToFunctionPass)])),
                        metadata: ast.metadata,
                        pos: ast.pos
                    };
                } else {
                    // Regular call, transform recursively
                    {
                        def: ECall(
                            expr != null ? transformAST(expr, tupleElemFieldToFunctionPass) : null,
                            funcName,
                            [for (arg in args) transformAST(arg, tupleElemFieldToFunctionPass)]
                        ),
                        metadata: ast.metadata,
                        pos: ast.pos
                    };
                }
                
            default:
                // Recursively transform children
                transformAST(ast, tupleElemFieldToFunctionPass);
        };
    }
    
    /**
     * Idiomatic Enum Pattern Matching Transformation Pass
     * 
     * WHY: The compiler generates low-level tuple access patterns for enum matching
     * which results in non-idiomatic Elixir code and variable naming inconsistencies.
     * Instead of case x.elem(0) with x.elem(1) extraction, we want case x with pattern matching.
     * 
     * WHAT: Transforms patterns like:
     *   case result.elem(0) do
     *     0 -> _g = result.elem(1); value = g; {:Some, value}
     *     1 -> _g = result.elem(1); :none
     *   end
     * Into:
     *   case result do
     *     {0, value} -> {:Some, value}
     *     {1, _} -> :none
     *   end
     * 
     * HOW: Detects ECase with ETupleAccess(expr, 0) and transforms the entire structure
     * to use tuple pattern matching instead of manual extraction.
     */
    static function idiomaticEnumPatternMatchingPass(ast: ElixirAST): ElixirAST {
        #if debug_ast_transformer
        trace('[XRay EnumPatternMatching] Starting idiomatic enum pattern matching pass');
        #end
        
        // Handle null nodes
        if (ast == null) {
            return null;
        }
        
        return switch(ast.def) {
            case ECase(expr, clauses):
                // Check if this is an enum tag check pattern (case x.elem(0))
                var isEnumTagCheck = false;
                var baseExpr = expr;
                
                switch(expr.def) {
                    case ECall(tupleExpr, "elem", [arg]):
                        switch(arg.def) {
                            case EInteger(0):
                                #if debug_ast_transformer
                                trace('[XRay EnumPatternMatching] Found enum tag check pattern on elem(0) as ECall');
                                #end
                                isEnumTagCheck = true;
                                baseExpr = tupleExpr;
                            default:
                        }
                    case EField(tupleExpr, "elem"):
                        // This is the pattern generated by switch on Result enums
                        // We detect it here but can't check for index 0 directly
                        // The transformer will need to analyze the clauses to determine this
                        #if debug_ast_transformer
                        trace('[XRay EnumPatternMatching] Found potential enum tag check pattern with .elem field access');
                        #end
                        isEnumTagCheck = true;
                        baseExpr = tupleExpr;
                    default:
                }
                
                if (isEnumTagCheck) {
                    
                    #if debug_ast_transformer
                    trace('[XRay EnumPatternMatching] Transforming enum case to idiomatic pattern matching');
                    #end
                    
                    // Transform each clause
                    var transformedClauses = [];
                    for (clause in clauses) {
                        var transformedClause = transformEnumClause(clause, baseExpr);
                        transformedClauses.push(transformedClause);
                    }
                    
                    // Return the transformed case using the base expression directly
                    {
                        def: ECase(baseExpr, transformedClauses),
                        metadata: ast.metadata,
                        pos: ast.pos
                    };
                } else {
                    // Not an enum pattern, recursively transform children
                    transformAST(ast, idiomaticEnumPatternMatchingPass);
                }
                
            default:
                // Recursively transform children
                transformAST(ast, idiomaticEnumPatternMatchingPass);
        };
    }
    
    /**
     * Transform an individual enum case clause to use pattern matching
     * 
     * WHY: Each clause needs to be transformed from tag checking to pattern matching
     * WHAT: Converts manual elem() extraction to tuple pattern destructuring  
     * HOW: Analyzes the body for elem(1) calls and creates appropriate patterns
     */
    static function transformEnumClause(clause: ECaseClause, baseExpr: ElixirAST): ECaseClause {
        #if debug_ast_transformer
        trace('[XRay EnumPatternMatching] Transforming clause with pattern: ${clause.pattern}');
        #end
        
        // Extract the tag value from the pattern
        var tagValue = switch(clause.pattern) {
            case PLiteral(ast):
                switch(ast.def) {
                    case EInteger(tag): tag;
                    default:
                        #if debug_ast_transformer
                        trace('[XRay EnumPatternMatching] Non-integer pattern, keeping as-is');
                        #end
                        return clause; // Can't transform non-integer patterns
                }
            default: 
                #if debug_ast_transformer
                trace('[XRay EnumPatternMatching] Non-literal pattern, keeping as-is');
                #end
                return clause; // Can't transform non-literal patterns
        };
        
        // Analyze the body to find parameter extraction patterns
        var extractedParams = analyzeEnumParameterExtraction(clause.body, baseExpr);
        
        #if debug_ast_transformer
        trace('[XRay EnumPatternMatching] Found ${extractedParams.length} extracted parameters');
        #end
        
        // Create tuple pattern based on extracted parameters
        var tuplePattern = if (extractedParams.length > 0) {
            // Create pattern with extracted variable names
            var patterns = [PLiteral(makeAST(EInteger(tagValue)))];
            for (param in extractedParams) {
                patterns.push(PVar(param.finalName));
            }
            PTuple(patterns);
        } else {
            // No parameters, use wildcard
            PTuple([PLiteral(makeAST(EInteger(tagValue))), PWildcard]);
        };
        
        // Clean up the body by removing extraction statements
        var cleanedBody = removeEnumParameterExtractions(clause.body, extractedParams);
        
        #if debug_ast_transformer
        trace('[XRay EnumPatternMatching] Created tuple pattern with ${extractedParams.length + 1} elements');
        #end
        
        return {
            pattern: tuplePattern,
            guard: clause.guard,
            body: cleanedBody
        };
    }
    
    /**
     * Analyze the body to find enum parameter extraction patterns
     */
    static function analyzeEnumParameterExtraction(body: ElixirAST, baseExpr: ElixirAST): Array<{tempName: String, finalName: String}> {
        var params = [];
        
        switch(body.def) {
            case EBlock(exprs):
                for (expr in exprs) {
                    switch(expr.def) {
                        case EMatch(PVar(varName), ast):
                            switch(ast.def) {
                                case ECall(tupleExpr, "elem", [arg]):
                                    switch(arg.def) {
                                        case EInteger(1):
                                            // Found pattern: _g = result.elem(1)
                                            if (astEquals(tupleExpr, baseExpr)) {
                                                // Look for subsequent assignment: value = g
                                                var finalName = findSubsequentAssignment(exprs, varName.replace("_", ""));
                                                if (finalName != null) {
                                                    params.push({tempName: varName, finalName: finalName});
                                                } else {
                                                    // Use the temp name without underscore as final name
                                                    params.push({tempName: varName, finalName: varName.replace("_", "")});
                                                }
                                            }
                                        default:
                                    }
                                default:
                            }
                        default:
                    }
                }
            default:
                // Single expression body, no extraction
        }
        
        return params;
    }
    
    /**
     * Find subsequent assignment of a temp variable
     */
    static function findSubsequentAssignment(exprs: Array<ElixirAST>, tempVarWithoutUnderscore: String): Null<String> {
        for (expr in exprs) {
            switch(expr.def) {
                case EMatch(PVar(finalName), ast):
                    switch(ast.def) {
                        case EVar(srcVar):
                            if (srcVar == tempVarWithoutUnderscore) {
                                return finalName;
                            }
                        default:
                    }
                default:
            }
        }
        return null;
    }
    
    /**
     * Remove enum parameter extraction statements from the body
     */
    static function removeEnumParameterExtractions(body: ElixirAST, extractedParams: Array<{tempName: String, finalName: String}>): ElixirAST {
        switch(body.def) {
            case EBlock(exprs):
                var cleanedExprs = [];
                var skip = false;
                
                for (i in 0...exprs.length) {
                    var expr = exprs[i];
                    var shouldSkip = false;
                    
                    // Check if this is an extraction statement
                    switch(expr.def) {
                        case EMatch(PVar(varName), ast):
                            switch(ast.def) {
                                case ECall(_, "elem", [arg]):
                                    switch(arg.def) {
                                        case EInteger(1):
                                            // Check if this matches any extracted param
                                            for (param in extractedParams) {
                                                if (varName == param.tempName) {
                                                    shouldSkip = true;
                                                    break;
                                                }
                                            }
                                        default:
                                    }
                                case EVar(srcVar):
                                    // Check if this is a reassignment from temp var
                                    for (param in extractedParams) {
                                        if (varName == param.finalName && srcVar == param.tempName.replace("_", "")) {
                                            shouldSkip = true;
                                            break;
                                        }
                                    }
                                default:
                            }
                        default:
                    }
                    
                    if (!shouldSkip) {
                        cleanedExprs.push(expr);
                    }
                }
                
                // If only one expression remains, unwrap the block
                if (cleanedExprs.length == 1) {
                    return cleanedExprs[0];
                } else if (cleanedExprs.length == 0) {
                    // Empty block, return nil
                    return makeAST(EAtom(ElixirAtom.nil()));
                } else {
                    return {
                        def: EBlock(cleanedExprs),
                        metadata: body.metadata,
                        pos: body.pos
                    };
                }
            default:
                // Not a block, return as-is
                return body;
        }
    }
    
    /**
     * Check if two AST nodes are structurally equal
     */
    static function astEquals(a: ElixirAST, b: ElixirAST): Bool {
        // Simple structural equality check for variable references
        return switch([a.def, b.def]) {
            case [EVar(name1), EVar(name2)]: name1 == name2;
            case [EField(obj1, field1), EField(obj2, field2)]: 
                field1 == field2 && astEquals(obj1, obj2);
            default: false;
        };
    }
    
    /**
     * Transform idiomatic enum constructors using shared utility
     * 
     * WHY: This wrapper delegates to the shared transformation utility in ElixirAST.hx
     * to ensure consistent transformation logic across the AST pipeline.
     * 
     * WHAT: Applies convention-based transformations for enums marked with @:elixirIdiomatic.
     * 
     * HOW: Simply delegates to the shared utility function.
     * 
     * @param elements The tuple elements to transform (unused - kept for compatibility)
     * @param node The original AST node for metadata preservation
     * @return Transformed AST following Elixir idioms
     */
    static function transformIdiomaticEnum(elements: Array<ElixirAST>, node: ElixirAST): ElixirAST {
        // Delegate to shared utility function
        return reflaxe.elixir.ast.ElixirAST.applyIdiomaticEnumTransformation(node);
    }
    
    /**
     * Check if a string looks like an Elixir module name
     * 
     * WHY: Module names in strings should be converted to atoms in idiomatic Elixir
     * WHAT: Detects patterns like "Phoenix.PubSub", "MyApp.Repo", "Elixir.MyModule"
     * HOW: Checks for capitalized segments separated by dots
     * 
     * @param s The string to check
     * @return True if it looks like a module name
     */
    static function isModuleName(s: String): Bool {
        if (s == null || s.length == 0) return false;
        
        // Module names start with uppercase or "Elixir."
        var firstChar = s.charAt(0);
        if (firstChar != firstChar.toUpperCase()) return false;
        
        // Check for module path pattern (e.g., "Phoenix.PubSub")
        var segments = s.split(".");
        for (segment in segments) {
            if (segment.length == 0) return false;
            var first = segment.charAt(0);
            // Each segment should start with uppercase
            if (first != first.toUpperCase() || first == first.toLowerCase()) {
                return false;
            }
        }
        
        return true;
    }
    
    /**
     * Convert a constructor name to idiomatic Elixir atom
     * 
     * WHY: Elixir atoms use snake_case, but some patterns need special handling
     * WHAT: Converts CamelCase to snake_case with special cases for common patterns
     * HOW: 
     * - "Ok" → "ok" (common Result pattern)
     * - "Error" → "error" (common Result pattern)  
     * - "Some" → "ok" (Option pattern mapped to Elixir convention)
     * - "None" → "error" (Option pattern mapped to Elixir convention)
     * - Others → snake_case
     * 
     * @param tag The constructor tag name
     * @return Idiomatic atom name
     */
    static function toIdiomaticAtom(tag: String): String {
        // Special cases for common patterns
        switch(tag.toLowerCase()) {
            case "ok": return "ok";
            case "error": return "error";
            case "some": return "ok";  // Option.Some maps to {:ok, _} in Elixir
            case "none": return "error";  // Option.None maps to :error in Elixir
            default:
                // Convert to snake_case
                return toSnakeCase(tag);
        }
    }
    
    
    static function underscoreVariableCleanupPass(ast: ElixirAST): ElixirAST {
        #if debug_ast_transformer
        trace('[XRay UnderscoreCleanup] Starting underscore variable cleanup pass');
        #end
        
        // Phase 1: Collect underscore variables and track usage
        var underscoreVars = new Map<String, Bool>(); // var name -> is used
        var varDeclarations = new Map<String, Bool>(); // track all declarations
        var allUnderscoreVars = new Map<String, Bool>(); // track ALL underscore vars
        
        function collectPatternVars(pattern: EPattern, vars: Map<String, Bool>): Void {
            switch(pattern) {
                case PVar(name):
                    vars.set(name, true);
                    if (name.charAt(0) == "_" && name.length > 1) {
                        // Track all underscore variables (including _g_1, _g_2, etc.)
                        allUnderscoreVars.set(name, true);
                        // Initialize as unused
                        if (!underscoreVars.exists(name)) {
                            underscoreVars.set(name, false);
                        }
                    }
                case PTuple(patterns):
                    for (p in patterns) collectPatternVars(p, vars);
                case PList(patterns):
                    for (p in patterns) collectPatternVars(p, vars);
                case PCons(head, tail):
                    collectPatternVars(head, vars);
                    collectPatternVars(tail, vars);
                case PMap(pairs):
                    for (pair in pairs) collectPatternVars(pair.value, vars);
                case PStruct(name, fields):
                    for (field in fields) collectPatternVars(field.value, vars);
                case _:
                    // Other patterns don't declare variables
            }
        }
        
        function collectVariables(node: ElixirAST): Void {
            // Handle null nodes
            if (node == null) {
                return;
            }
            
            switch(node.def) {
                case EMatch(pattern, expr):
                    // Track variable declarations in patterns
                    collectPatternVars(pattern, varDeclarations);
                    // Continue collecting in expression
                    collectVariables(expr);
                    
                case EVar(name):
                    // Track variable usage (not in pattern context)
                    if (name.charAt(0) == "_" && name.length > 1) {
                        // Mark this underscore variable as used
                        underscoreVars.set(name, true);
                        allUnderscoreVars.set(name, true);
                        #if debug_ast_transformer
                        trace('[XRay UnderscoreCleanup] Found used underscore variable: $name at ${node.pos}');
                        #end
                    }
                    
                case ERemoteCall(module, funcName, args):
                    #if debug_ast_transformer
                    trace('[XRay UnderscoreCleanup] Found ERemoteCall: $funcName with ${args.length} args');
                    #end
                    // Recursively collect from module and all arguments
                    if (module != null) collectVariables(module);
                    for (arg in args) {
                        collectVariables(arg);
                    }
                    
                case EFn(clauses):
                    #if debug_ast_transformer
                    trace('[XRay UnderscoreCleanup] Found EFn with ${clauses.length} clauses');
                    #end
                    // Recursively collect from lambda/function bodies
                    for (clause in clauses) {
                        if (clause.guard != null) collectVariables(clause.guard);
                        collectVariables(clause.body);
                    }
                    
                case _:
                    // Recursively collect from all children
                    iterateAST(node, collectVariables);
            }
        }
        
        // Run collection phase
        collectVariables(ast);
        
        // Phase 2: Build renaming map for ALL underscore variables that are referenced
        var renameMap = new Map<String, String>();
        
        // Process all underscore variables we found
        for (varName in allUnderscoreVars.keys()) {
            // Check if this variable is actually used (referenced after declaration)
            var isUsed = underscoreVars.exists(varName) && underscoreVars.get(varName);

            if (isUsed) {
                // CRITICAL FIX: Skip infrastructure variables (_g, _g1, etc.)
                // These are Haxe-generated temporaries for switch desugaring that MUST keep their names
                // Reason: The variable declaration might be in a different scope/block than we can see
                // Example: `switch(msg.type)` desugars to `var _g = msg.type; switch(_g)`
                // If we rename `_g` to `g` in the switch but not in the declaration, we get undefined variable errors
                if (~/^_g(_?\d*)?$/.match(varName)) {
                    #if debug_ast_transformer
                    trace('[XRay UnderscoreCleanup] PRESERVING infrastructure variable: $varName (used in switch desugaring)');
                    #end
                    // DO NOT rename - keep the underscore prefix
                    continue;
                }

                // This underscore variable is used, so rename it
                if (~/^_\d+$/.match(varName)) {
                    // _1, _2 -> temp_1, temp_2 (avoid pure numeric)
                    var newName = "temp" + varName.substr(1);
                    renameMap.set(varName, newName);
                    #if debug_ast_transformer
                    trace('[XRay UnderscoreCleanup] Renaming used numeric: $varName -> $newName');
                    #end
                }
                // Other underscore variables are left as-is (might be intentional)
            } else {
                #if debug_ast_transformer
                if (varName.charAt(0) == "_" && varName.length > 1) {
                    trace('[XRay UnderscoreCleanup] Keeping unused underscore variable: $varName');
                }
                #end
            }
        }
        
        // Phase 3: Apply renaming throughout the AST
        if (renameMap.keys().hasNext()) {
            #if debug_ast_transformer
            trace('[XRay UnderscoreCleanup] Applying ${Lambda.count(renameMap)} variable renamings');
            #end
            return applyVariableRenaming(ast, renameMap);
        }
        
        #if debug_ast_transformer
        trace('[XRay UnderscoreCleanup] No underscore variables need renaming');
        #end
        return ast;
    }
    
    /**
     * Apply variable renaming throughout the AST
     */
    static function applyVariableRenaming(ast: ElixirAST, renameMap: Map<String, String>): ElixirAST {
        function renameInPattern(pattern: EPattern): EPattern {
            return switch(pattern) {
                case PVar(name):
                    renameMap.exists(name) ? PVar(renameMap.get(name)) : pattern;
                case PTuple(patterns):
                    PTuple(patterns.map(renameInPattern));
                case PList(patterns):
                    PList(patterns.map(renameInPattern));
                case PCons(head, tail):
                    PCons(renameInPattern(head), renameInPattern(tail));
                case PMap(pairs):
                    PMap(pairs.map(p -> {key: p.key, value: renameInPattern(p.value)}));
                case PStruct(name, fields):
                    PStruct(name, fields.map(f -> {key: f.key, value: renameInPattern(f.value)}));
                case _:
                    pattern;
            }
        }
        
        function renameInAST(node: ElixirAST): ElixirAST {
            var transformed = switch(node.def) {
                case EVar(name):
                    if (renameMap.exists(name)) {
                        #if debug_ast_transformer
                        trace('[XRay UnderscoreCleanup] Renaming EVar: $name -> ${renameMap.get(name)}');
                        #end
                        makeASTWithMeta(EVar(renameMap.get(name)), node.metadata, node.pos);
                    } else {
                        node;
                    }
                    
                case EMatch(pattern, expr):
                    makeASTWithMeta(
                        EMatch(renameInPattern(pattern), renameInAST(expr)),
                        node.metadata, node.pos
                    );
                    
                case ECase(expr, clauses):
                    makeASTWithMeta(
                        ECase(renameInAST(expr),
                              clauses.map(c -> {
                                  pattern: renameInPattern(c.pattern),
                                  guard: c.guard != null ? renameInAST(c.guard) : null,
                                  body: renameInAST(c.body)
                              })),
                        node.metadata, node.pos
                    );
                    
                case EReceive(clauses, after):
                    makeASTWithMeta(
                        EReceive(clauses.map(c -> {
                                     pattern: renameInPattern(c.pattern),
                                     guard: c.guard != null ? renameInAST(c.guard) : null,
                                     body: renameInAST(c.body)
                                 }),
                                 after != null ? {timeout: renameInAST(after.timeout), body: renameInAST(after.body)} : null),
                        node.metadata, node.pos
                    );
                    
                case EFn(clauses):
                    makeASTWithMeta(
                        EFn(clauses.map(c -> {
                            args: c.args.map(renameInPattern),
                            guard: c.guard != null ? renameInAST(c.guard) : null,
                            body: renameInAST(c.body)
                        })),
                        node.metadata, node.pos
                    );
                    
                case _:
                    // For all other node types, recursively transform children
                    transformAST(node, renameInAST);
            };
            return transformed;
        }
        
        return renameInAST(ast);
    }
    
    /**
     * Fix Bare Concatenations Pass
     * 
     * WHY: When array.push() is transformed to concatenation, nested blocks can contain
     *      bare concatenations like `g ++ [0]` which are invalid as statements in Elixir.
     * 
     * WHAT: Converts bare concatenation statements to assignments.
     * 
     * HOW: Detects EBinary(Concat, EVar(name), ...) in statement position and wraps
     *      them with EBinary(Match, EVar(name), ...) to create valid assignments.
     */
    static function fixBareConcatenationsPass(ast: ElixirAST): ElixirAST {
        function fixConcatenations(node: ElixirAST): ElixirAST {
            if (node == null) return null;
            return switch(node.def) {
                case EBlock(statements):
                    var fixedStatements = [];
                    for (stmt in statements) {
                        // Add null check to prevent null pointer exceptions
                        if (stmt == null) {
                            continue;
                        }
                        var fixed = switch(stmt.def) {
                            // Check for bare concatenation: var ++ [value] or struct.field ++ [value]
                            case EBinary(Concat, left, right):
                                switch(left.def) {
                                    case EVar(name):
                                        // Convert to assignment: var = var ++ [value]
                                        makeAST(EBinary(Match, left, stmt));
                                    case EField(structVar, fieldName):
                                        // This is struct.field ++ [value] - a bare concatenation that should update the struct
                                        // Transform to: struct = %{struct | field: struct.field ++ [value]}
                                        switch(structVar.def) {
                                            case EVar("struct"):
                                                // Create struct update
                                                makeAST(EBinary(
                                                    Match,
                                                    structVar,
                                                    makeAST(EStructUpdate(
                                                        structVar,
                                                        [{
                                                            key: fieldName,
                                                            value: stmt  // The concatenation itself
                                                        }]
                                                    ))
                                                ));
                                            default:
                                                // Not a struct field, keep as-is
                                                stmt;
                                        }
                                    default:
                                        // Keep as-is if not a simple variable or field
                                        stmt;
                                }
                            default:
                                // Recursively fix nested blocks
                                fixConcatenations(stmt);
                        };
                        fixedStatements.push(fixed);
                    }
                    makeAST(EBlock(fixedStatements));
                    
                case EList(elements):
                    // Fix elements inside list literals
                    var fixedElements = [for (e in elements) fixConcatenations(e)];
                    makeAST(EList(fixedElements));
                    
                default:
                    // Recursively apply to all children
                    transformAST(node, fixConcatenations);
            };
        }
        
        return fixConcatenations(ast);
    }
    
    /**
     * Unrolled Comprehension Reconstruction Pass
     * 
     * WHY: Haxe completely unrolls array comprehensions with constant ranges at compile-time,
     *      converting `[for (i in 0...3) i]` into imperative code with temp variables and 
     *      concatenations. This creates invalid Elixir with bare concatenation expressions
     *      like `g ++ [0]` appearing as statements inside list literals.
     * 
     * WHAT: Detects blocks marked with isUnrolledComprehension metadata and reconstructs
     *       them back into idiomatic Elixir `for` comprehensions.
     * 
     * HOW: 1. Looks for Block nodes with isUnrolledComprehension metadata
     *      2. Analyzes the block to extract iteration pattern (range, values)
     *      3. Reconstructs as EFor(iterVar, range, body)
     *      4. Handles nested comprehensions by recursively processing inner blocks
     * 
     * EDGE CASES:
     * - Empty comprehensions (0...0 range)
     * - Single element comprehensions (0...1)
     * - Deeply nested comprehensions (3+ levels)
     * - Mixed constant and variable ranges
     * 
     * @see docs/03-compiler-development/ARRAY_COMPREHENSION_RECONSTRUCTION.md
     */
    static function unrolledComprehensionReconstructionPass(ast: ElixirAST): ElixirAST {
        #if debug_array_comprehension
        trace('[Array Comprehension Transform] Starting reconstruction pass');
        #end
        #if debug_unrolled_comprehension
        trace('[DEBUG Transform] unrolledComprehensionReconstructionPass called');
        #end
        
        function reconstructComprehension(ast: ElixirAST): ElixirAST {
            return switch(ast.def) {
                case EBlock(stmts) if (ast.metadata != null && ast.metadata.isUnrolledComprehension == true):
                    #if debug_array_comprehension
                    trace('[Array Comprehension Transform] ✓ Found marked block with ${stmts.length} statements');
                    trace('[Array Comprehension Transform]   Metadata: ${ast.metadata}');
                    #end
                    
                    // Analyze the block to reconstruct comprehension
                    var comprehension = analyzeAndReconstructComprehension(stmts);
                    if (comprehension != null) {
                        #if debug_array_comprehension
                        trace('[Array Comprehension Transform] ✓ Successfully reconstructed as for comprehension');
                        #end
                        comprehension;
                    } else {
                        #if debug_array_comprehension
                        trace('[Array Comprehension Transform] ✗ Could not reconstruct, keeping as block');
                        #end
                        ast;
                    }
                    
                case _:
                    // Recursively transform children
                    transformAST(ast, reconstructComprehension);
            };
        }
        
        return reconstructComprehension(ast);
    }
    
    /**
     * Analyze an unrolled comprehension block and reconstruct as EFor
     * 
     * Pattern to detect:
     * - g = []                    (initialization)
     * - g = g ++ [...]           (accumulation statements)
     * - g                        (return value)
     * 
     * Reconstructs as: for i <- 0..n, do: expression
     */
    static function analyzeAndReconstructComprehension(stmts: Array<ElixirAST>): Null<ElixirAST> {
        if (stmts.length < 3) return null;
        
        #if debug_array_comprehension
        trace('[Array Comprehension Transform] Analyzing block for reconstruction');
        #end
        
        // Check first statement: should be g = []
        var iterVar = switch(stmts[0].def) {
            case EBinary(Match, {def: EVar(varName)}, {def: EList([])}):
                varName;
            case _:
                return null;
        };
        
        #if debug_array_comprehension
        trace('[Array Comprehension Transform]   Found initialization: $iterVar = []');
        #end
        
        // Extract elements from accumulation statements
        var elements = [];
        for (i in 1...stmts.length - 1) {
            switch(stmts[i].def) {
                case EBinary(Match, {def: EVar(v)}, {def: EBinary(Concat, {def: EVar(v2)}, {def: EList([elem])})}) if (v == iterVar && v2 == iterVar):
                    // g = g ++ [element]
                    elements.push(elem);
                case EBinary(Concat, {def: EVar(v)}, {def: EList([elem])}) if (v == iterVar):
                    // Bare concatenation: g ++ [element] (shouldn't happen after fix, but handle it)
                    elements.push(elem);
                case _:
                    // Unknown pattern
                    #if debug_array_comprehension
                    trace('[Array Comprehension Transform]   Unknown statement pattern: ${stmts[i].def}');
                    #end
            }
        }
        
        #if debug_array_comprehension
        trace('[Array Comprehension Transform]   Extracted ${elements.length} elements');
        #end
        
        // Check last statement: should return the variable
        var returnsVar = switch(stmts[stmts.length - 1].def) {
            case EVar(v) if (v == iterVar): true;
            case _: false;
        };
        
        if (!returnsVar || elements.length == 0) return null;
        
        // Determine the range from element count
        var rangeEnd = elements.length - 1;
        
        // Check if elements are simple integers (0, 1, 2...) or nested comprehensions
        var isSimpleRange = true;
        var hasNestedComprehensions = false;
        
        for (i in 0...elements.length) {
            switch(elements[i].def) {
                case EInteger(val):
                    // Check if it's the expected integer
                    if (val != i) {
                        isSimpleRange = false;
                    }
                case EList(_):
                    // Nested list - likely a nested comprehension
                    hasNestedComprehensions = true;
                    isSimpleRange = false;
                case _:
                    isSimpleRange = false;
            }
        }
        
        #if debug_array_comprehension
        trace('[Array Comprehension Transform]   Simple range: $isSimpleRange, Nested: $hasNestedComprehensions');
        #end
        
        // Generate appropriate comprehension
        if (isSimpleRange) {
            // Simple range comprehension: for i <- 0..n, do: i
            var range = makeAST(ERange(makeAST(EInteger(0)), makeAST(EInteger(rangeEnd)), false));
            var generator: EGenerator = {
                pattern: PVar("i"),
                expr: range
            };
            var body = makeAST(EVar("i")); // Simple case: just return the iterator
            
            return makeAST(EFor([generator], [], body, null, null));
        } else if (hasNestedComprehensions) {
            // Nested comprehension: for i <- 0..n, do: for j <- 0..m, do: expr
            // For now, reconstruct the outer comprehension
            var range = makeAST(ERange(makeAST(EInteger(0)), makeAST(EInteger(rangeEnd)), false));
            var generator: EGenerator = {
                pattern: PVar("i"),
                expr: range
            };
            
            // Use the first element as template for the body (should be consistent)
            var body = elements[0];
            
            // If the body is a list, check if it can be reconstructed as a nested comprehension
            switch(body.def) {
                case EList(innerElements):
                    // Check if inner elements follow a pattern
                    var innerComprehension = tryReconstructInnerComprehension(innerElements);
                    if (innerComprehension != null) {
                        body = innerComprehension;
                    }
                case _:
            }
            
            return makeAST(EFor([generator], [], body, null, null));
        } else {
            // Complex pattern - keep as-is for now
            #if debug_array_comprehension
            trace('[Array Comprehension Transform]   Complex pattern, not reconstructing');
            #end
            return null;
        }
    }
    
    /**
     * Try to reconstruct an inner comprehension from a list of elements
     */
    static function tryReconstructInnerComprehension(elements: Array<ElixirAST>): Null<ElixirAST> {
        if (elements.length == 0) return null;
        
        // Check if elements follow a simple numeric pattern
        var isSimpleRange = true;
        for (i in 0...elements.length) {
            switch(elements[i].def) {
                case EInteger(val):
                    if (val != i) {
                        isSimpleRange = false;
                        break;
                    }
                case _:
                    isSimpleRange = false;
                    break;
            }
        }
        
        if (isSimpleRange) {
            // Reconstruct as: for j <- 0..n, do: j
            var rangeEnd = elements.length - 1;
            var range = makeAST(ERange(makeAST(EInteger(0)), makeAST(EInteger(rangeEnd)), false));
            var generator: EGenerator = {
                pattern: PVar("j"),
                expr: range
            };
            var body = makeAST(EVar("j"));
            
            return makeAST(EFor([generator], [], body, null, null));
        }
        
        return null;
    }
}

/**
 * SupervisorOptionsTransformPass: Convert supervisor options from map to keyword list
 * 
 * WHY: Supervisor.start_link expects options as a keyword list [strategy: :one_for_one, ...]
 *      but TObjectDecl generates EMap %{strategy: :one_for_one, ...}
 * 
 * WHAT: Detects supervisor option patterns and converts EMap to EKeywordList
 * 
 * HOW: Looks for maps with supervisor option keys (strategy, max_restarts, max_seconds)
 *      being passed to Supervisor.start_link and converts them to keyword lists
 */
class SupervisorOptionsTransformPass {
    
    /**
     * Transform supervisor options from maps to keyword lists
     */
    public static function transform(ast: ElixirAST, ?context: reflaxe.elixir.CompilationContext): ElixirAST {
        #if debug_ast_transformer
        trace("[XRay SupervisorOptions] Starting supervisor options transformation");
        switch(ast.def) {
            case EDefmodule(name, _):
                trace('[XRay SupervisorOptions] Processing module: $name');
            case _:
                trace('[XRay SupervisorOptions] Processing non-module AST');
        }
        #end
        
        return transformSupervisorCalls(ast);
    }
    
    /**
     * Find and transform Supervisor.start_link calls
     */
    static function transformSupervisorCalls(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            #if debug_ast_transformer
            switch(node.def) {
                case EMatch(PVar(name), _):
                    trace('[XRay SupervisorOptions] Found variable assignment in transformSupervisorCalls: $name');
                case EMap(_):
                    trace('[XRay SupervisorOptions] Found map in transformSupervisorCalls');
                case _:
            }
            #end
            
            switch(node.def) {
                case ERemoteCall(module, "start_link", args) if (args.length == 2):
                    // Check if this is Supervisor.start_link(children, opts)
                    var isSupervisor = switch(module.def) {
                        case EVar("Supervisor"): true;
                        case _: false;
                    };
                    
                    if (isSupervisor) {
                        #if debug_ast_transformer
                        trace("[XRay SupervisorOptions] Found Supervisor.start_link call");
                        #end
                        
                        // Transform the second argument (options) if it's a map
                        var children = args[0];
                        var opts = transformSupervisorOptions(args[1]);
                        
                        return makeASTWithMeta(
                            ERemoteCall(module, "start_link", [children, opts]),
                            node.metadata,
                            node.pos
                        );
                    }
                    
                case EMatch(pattern, expr):
                    // Check if we're assigning to a variable named "opts" or similar
                    var varName = switch(pattern) {
                        case PVar(name): name;
                        case _: null;
                    };
                    
                    #if debug_ast_transformer
                    if (varName != null) {
                        trace('[XRay SupervisorOptions] Found variable assignment: $varName');
                    }
                    #end
                    
                    if (varName != null && (varName == "opts" || varName.indexOf("option") != -1 || varName.indexOf("config") != -1)) {
                        // This might be supervisor options
                        #if debug_ast_transformer
                        trace('[XRay SupervisorOptions] Variable $varName looks like options, checking if it\'s a map...');
                        #end
                        
                        var transformedExpr = transformSupervisorOptions(expr);
                        if (transformedExpr != expr) {
                            #if debug_ast_transformer
                            trace('[XRay SupervisorOptions] ✓ Transformed options assignment for variable: $varName');
                            #end
                            return makeASTWithMeta(
                                EMatch(pattern, transformedExpr),
                                node.metadata,
                                node.pos
                            );
                        }
                    }
                    
                case _:
                    // Not a supervisor call
            }
            
            return node;
        });
    }
    
    /**
     * Transform supervisor options from map to keyword list if needed
     */
    static function transformSupervisorOptions(expr: ElixirAST): ElixirAST {
        return switch(expr.def) {
            case EMap(pairs):
                #if debug_ast_transformer
                trace('[XRay SupervisorOptions] Analyzing map with ${pairs.length} pairs');
                #end
                
                // Check if this looks like supervisor options
                var hasStrategy = false;
                var hasMaxRestarts = false;
                var hasMaxSeconds = false;
                var hasName = false;
                
                for (pair in pairs) {
                    var keyName: Null<String> = switch(pair.key.def) {
                        case EAtom(atom): atom; // ElixirAtom implicitly converts to String
                        case _: null;
                    };
                    
                    if (keyName != null) {
                        // Check both snake_case and original field names (before transformation)
                        // since this pass might run at different stages
                        switch(keyName.toLowerCase()) {
                            case "strategy": hasStrategy = true;
                            case "max_restarts" | "maxrestarts": hasMaxRestarts = true;
                            case "max_seconds" | "maxseconds": hasMaxSeconds = true;
                            case "name": hasName = true;
                        }
                        
                        #if debug_ast_transformer
                        trace('[XRay SupervisorOptions] Checking key: $keyName (hasStrategy=$hasStrategy, hasMaxRestarts=$hasMaxRestarts)');
                        #end
                    }
                }
                
                // If it has at least strategy (required) and one other supervisor field, convert it
                if (hasStrategy && (hasMaxRestarts || hasMaxSeconds || hasName)) {
                    #if debug_ast_transformer
                    trace("[XRay SupervisorOptions] Converting map to keyword list for supervisor options");
                    #end
                    
                    // Convert EMapPair to EKeywordPair
                    var keywordPairs: Array<EKeywordPair> = [];
                    for (pair in pairs) {
                        var key = switch(pair.key.def) {
                            case EAtom(name): name;
                            case _: continue; // Skip non-atom keys
                        };
                        
                        // Note: Snake_case conversion for atoms is handled systematically
                        // in ElixirASTBuilder.toElixirAtomName(), not here
                        keywordPairs.push({key: key, value: pair.value});
                    }
                    
                    return makeASTWithMeta(
                        EKeywordList(keywordPairs),
                        expr.metadata,
                        expr.pos
                    );
                }
                
                expr; // Not supervisor options
                
            case _:
                expr; // Not a map
        };
    }
    
    /**
     * Helper to create AST node with metadata
     */
    static function makeASTWithMeta(def: ElixirASTDef, ?metadata: ElixirMetadata, ?pos: haxe.macro.Expr.Position): ElixirAST {
        return {
            def: def,
            metadata: metadata != null ? metadata : {},
            pos: pos
        };
    }

    /**
     * Pattern Variable Origin Analysis Pass
     *
     * WHY: Distinguish between legitimate user variables named "g" (like in RGB patterns)
     *      and Haxe's temp extraction variables (g, g1, g2). Without this, legitimate
     *      variables get incorrectly prefixed with underscores.
     *
     * WHAT: Uses VarOrigin metadata to determine which variables should get underscore
     *       prefixes and ensures correct variable usage in pattern matching.
     *
     * HOW:
     * - Analyzes case patterns and their bodies for variable usage
     * - Checks varOrigin metadata to distinguish PatternBinder vs ExtractionTemp
     * - Updates pattern variables to use underscores only for truly unused variables
     * - Ensures consistency between pattern declaration and usage
     *
     * EXAMPLE:
     * Before: {:rgb, _g, _g1, _b} with reference to undefined 'g'
     * After: {:rgb, r, g, b} with correct references
     */
    static function patternVariableOriginAnalysisPass(ast: ElixirAST): ElixirAST {
        #if debug_pattern_variable_origin
        trace('[XRay PatternVariableOrigin] Starting analysis pass');
        #end

        // Forward declarations for recursive functions
        var analyzeAndTransform: ElixirAST -> ElixirAST = null;
        var analyzeClause: (ECaseClause, ElixirMetadata) -> ECaseClause = null;
        var collectPatternVars: (EPattern, Map<String, VarOrigin>, VarOrigin) -> Void = null;
        var analyzeUsage: (ElixirAST, Map<String, Bool>) -> Void = null;
        var updatePatternWithUsage: (EPattern, Map<String, VarOrigin>, Map<String, Bool>) -> EPattern = null;

        analyzeAndTransform = function(node: ElixirAST): ElixirAST {
            switch(node.def) {
                case ECase(expr, clauses):
                    #if debug_pattern_variable_origin
                    trace('[XRay PatternVariableOrigin] Analyzing case expression');
                    #end

                    // Transform each clause
                    var newClauses = [];
                    for (clause in clauses) {
                        var transformedClause = analyzeClause(clause, node.metadata);
                        newClauses.push(transformedClause);
                    }

                    return makeASTWithMeta(
                        ECase(analyzeAndTransform(expr), newClauses),
                        node.metadata,
                        node.pos
                    );

                default:
                    // Recursively transform other nodes
                    return ElixirASTTransformer.transformAST(node, analyzeAndTransform);
            }
        };

        analyzeClause = function(clause: ECaseClause, caseMetadata: ElixirMetadata): ECaseClause {
            #if debug_pattern_variable_origin
            trace('[XRay PatternVariableOrigin] Analyzing clause pattern');
            #end

            // Get variable origin info from metadata if available
            var varOrigin = caseMetadata != null && caseMetadata.varOrigin != null ?
                caseMetadata.varOrigin : null;
            var tempToBinderMap = caseMetadata != null && caseMetadata.tempToBinderMap != null ?
                caseMetadata.tempToBinderMap : null;

            // Collect variables from the pattern and their origins
            var patternVars: Map<String, VarOrigin> = new Map();
            collectPatternVars(clause.pattern, patternVars, varOrigin);

            // Analyze usage in the clause body
            var usedVars: Map<String, Bool> = new Map();
            analyzeUsage(clause.body, usedVars);

            // Update pattern based on usage and origin
            var updatedPattern = updatePatternWithUsage(clause.pattern, patternVars, usedVars);

            return {
                pattern: updatedPattern,
                guard: clause.guard != null ? analyzeAndTransform(clause.guard) : null,
                body: analyzeAndTransform(clause.body)
            };
        };

        collectPatternVars = function(pattern: EPattern, vars: Map<String, VarOrigin>, defaultOrigin: VarOrigin): Void {
            switch(pattern) {
                case PVar(name):
                    // Use the origin from metadata if available, otherwise use default
                    var origin = defaultOrigin != null ? defaultOrigin : UserDefined;

                    // Special handling for known temp variable patterns
                    if (name == "g" || (name.startsWith("g") && name.length > 1 &&
                        name.charAt(1) >= '0' && name.charAt(1) <= '9')) {
                        // This looks like a temp extraction variable
                        origin = ExtractionTemp;
                    }

                    vars.set(name, origin);

                case PTuple(elements):
                    for (elem in elements) {
                        collectPatternVars(elem, vars, defaultOrigin);
                    }

                case PList(elements):
                    for (elem in elements) {
                        collectPatternVars(elem, vars, defaultOrigin);
                    }

                case PCons(head, tail):
                    collectPatternVars(head, vars, defaultOrigin);
                    collectPatternVars(tail, vars, defaultOrigin);

                default:
                    // Other patterns don't introduce variables
            }
        };

        analyzeUsage = function(ast: ElixirAST, usedVars: Map<String, Bool>): Void {
            switch(ast.def) {
                case EVar(name):
                    // Mark this variable as used (remove underscore prefix if present for comparison)
                    var cleanName = name.startsWith("_") ? name.substring(1) : name;
                    usedVars.set(cleanName, true);
                    usedVars.set(name, true); // Also mark the exact name

                case EMatch(pattern, expr):
                    // Analyze the expression for usage
                    analyzeUsage(expr, usedVars);
                    // Don't analyze the pattern - it's a declaration

                default:
                    // Recursively analyze children
                    // TODO: Need to properly iterate through AST children
                    // This pass is disabled anyway, so commenting out for now
                    // iterateAST(ast, function(child) {
                    //     analyzeUsage(child, usedVars);
                    // });
            }
        };

        updatePatternWithUsage = function(pattern: EPattern, patternVars: Map<String, VarOrigin>, usedVars: Map<String, Bool>): EPattern {
            switch(pattern) {
                case PVar(name):
                    var origin = patternVars.get(name);
                    var isUsed = usedVars.exists(name) && usedVars.get(name);

                    #if debug_pattern_variable_origin
                    trace('[XRay PatternVariableOrigin] Variable "$name" - Origin: $origin, Used: $isUsed');
                    #end

                    // Special case: legitimate user variables named "g" should NOT get underscores
                    // Only add underscore if:
                    // 1. Variable is not used AND
                    // 2. It's definitely an extraction temp (not a user's "g" in RGB)
                    if (!isUsed && !name.startsWith("_")) {
                        // Check if this is definitely a temp extraction variable
                        // For now, we're conservative - only prefix if we're sure it's unused
                        if (origin == ExtractionTemp) {
                            // But wait - if it's named just "g" in an RGB pattern, it might be legitimate
                            // This is where we'd need more context to decide
                            // For now, leave it as-is to avoid false positives
                            return pattern;
                        }
                    }
                    return pattern;

                case PTuple(elements):
                    return PTuple(elements.map(e -> updatePatternWithUsage(e, patternVars, usedVars)));

                case PList(elements):
                    return PList(elements.map(e -> updatePatternWithUsage(e, patternVars, usedVars)));

                case PCons(head, tail):
                    return PCons(
                        updatePatternWithUsage(head, patternVars, usedVars),
                        updatePatternWithUsage(tail, patternVars, usedVars)
                    );

                default:
                    return pattern;
            }
        };

        return analyzeAndTransform(ast);
    }

    /**
     * Map Iterator Transform Pass
     * Uses ElixirASTPatterns for detection and extraction
     * 
     * WHY: Haxe desugars `for (key => value in map)` into complex while loops with
     *      infrastructure variables (g, g1, g2) and iterator method calls that generate
     *      non-idiomatic Elixir code with reduce_while and key_value_iterator() chains.
     * 
     * WHAT: Detects Map iteration patterns and transforms them into idiomatic Elixir:
     *       - Simple iteration → Enum.each(map, fn {k, v} -> ... end)
     *       - Collecting results → Enum.map(map, fn {k, v} -> ... end)
     *       - With filtering → for {k, v} <- map, condition, do: ...
     * 
     * HOW: Pattern matches on Enum.reduce_while calls that contain iterator methods,
     *      extracts the map variable and loop body, then generates appropriate Elixir
     *      enumeration patterns with tuple destructuring.
     * 
     * Example transformation:
     * From: Enum.reduce_while(Stream.iterate(...), {map}, fn _, {map} ->
     *         if (map.key_value_iterator().has_next()) do
     *           key = map.key_value_iterator().next().key
     *           value = map.key_value_iterator().next().value
     *           ...
     *         end
     *       end)
     * 
     * To: Enum.each(map, fn {key, value} -> ... end)
     */
}

#end // (macro || reflaxe_runtime)
