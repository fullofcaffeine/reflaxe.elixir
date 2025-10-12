package reflaxe.elixir.ast;

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
            } else {
                #if debug_contextual_passes
                trace('[XRay Contextual Pass] Using stateless variant for: ${passConfig.name}');
                trace('[XRay Contextual Pass] Contextual variant available: ${passConfig.contextualPass != null}');
                trace('[XRay Contextual Pass] Context provided: ${context != null}');
                #end

                result = passConfig.pass(result);
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

        // Inject `require Ecto.Query` in modules that call Ecto.Query macros (from/where/order_by/preload)
        passes.push({
            name: "EctoQueryRequireInjection",
            description: "Add `require Ecto.Query` to modules that use Ecto.Query macros",
            enabled: true,
            pass: ectoQueryRequirePass
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
        
        // Constant folding pass
        // String interpolation transformation (should run before constant folding)
        passes.push({
            name: "StringInterpolation",
            description: "Convert string concatenation to idiomatic string interpolation",
            enabled: true,
            pass: stringInterpolationPass
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
        /*
        passes.push({
            name: "StringMethodTransform",
            description: "Convert string method calls to String module calls",
            enabled: true,
            pass: stringMethodTransformPass
        });
        */
        
        // Pipeline optimization pass
        #if !disable_pipeline_optimization
        passes.push({
            name: "PipelineOptimization",
            description: "Convert sequential operations to pipeline",
            enabled: true,
            pass: pipelineOptimizationPass
        });
        #end
        
        // Instance method transformation pass for standard library types
        passes.push({
            name: "InstanceMethodTransform",
            description: "Transform instance.method() to Module.function(instance) for stdlib types",
            enabled: true,
            pass: instanceMethodTransformPass
        });

        // Normalize zero-arity Module.new() to struct literals (context-aware app prefix)
        passes.push({
            name: "ModuleNewToStructLiteral",
            description: "Rewrite Module.new() → %<App>.Module{} using module context to derive <App>",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.ModuleNewToStructLiteral.moduleNewToStructLiteralPass
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
            pass: comprehensionConversionPass
        });
        #end
        
        // Unrolled comprehension optimization pass (MUST run before effect lifting)
        // TODO: Fix implementation - functions need to be moved before this reference
        /*
        passes.push({
            name: "UnrolledComprehensionOptimization",
            description: "Optimize unrolled array comprehensions with bare concatenations",
            enabled: true,
            pass: unrolledComprehensionOptimizationPass
        });
        */
        
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
            pass: statementContextTransformPass
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
            pass: structFieldAssignmentTransformPass
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
            pass: fluentApiOptimizationPass
        });

        // Array length field to function transformation (must run early to fix field access)
        passes.push({
            name: "ArrayLengthFieldToFunction",
            description: "Transform array.length field access to length(array) function calls",
            enabled: true,
            pass: arrayLengthFieldToFunctionPass
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
            pass: tupleElemFieldToFunctionPass
        });
        
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
                return transformNode(ast, function(n: ElixirAST): ElixirAST {
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
            pass: underscoreVariableCleanupPass
        });
        #end
        
        // Abstract method this reference fix (should run after underscore cleanup)
        passes.push({
            name: "AbstractMethodThis",
            description: "Fix 'this' references in abstract methods",
            enabled: true,
            pass: abstractMethodThisPass
        });
        
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

        // Final safeguard: rewrite any remaining free assign(socket, map) to Component.assign(socket, map)
        passes.push({
            name: "FinalAssignRewrite",
            description: "Rewrite remaining assign/2 calls to Component.assign/2",
            enabled: true,
            pass: function(ast: ElixirAST): ElixirAST {
                return transformNode(ast, function(n: ElixirAST): ElixirAST {
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
                return transformNode(ast, function(n: ElixirAST): ElixirAST {
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
        // Safety net: qualify bare SafePubSub to Phoenix.SafePubSub
        passes.push({
            name: "SafePubSubAliasFix",
            description: "Fix bare SafePubSub references to Phoenix.SafePubSub",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.SafePubSubAliasFixTransforms.fixPass
        });
        // Fix Telemetry.start_link children var name mismatch
        passes.push({
            name: "TelemetryChildrenArgFix",
            description: "Use _children in Supervisor.start_link when assignment was underscored",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.TelemetryChildrenArgFixTransforms.fixPass
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

        // Absolute last: ensure declarations and references agree after all prior rewrites
        passes.push({
            name: "RefDeclAlignment(Final)",
            description: "Absolute final alignment of local names to canonical spelling",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.RefDeclAlignmentTransforms.alignLocalsPass
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

        // Final safety: rename references name -> _name when only underscored binder exists
        passes.push({
            name: "LocalUnderscoreReferenceFallback(Final)",
            description: "Fallback renaming of EVar(name) -> EVar(_name) when only _name declared (final)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.LocalUnderscoreReferenceFallbackTransforms.fallbackUnderscoreReferenceFixPass
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
        passes.push({
            name: "ModuleNewToStructLiteral",
            description: "Rewrite Module.new() to %Module{}",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.BinderTransforms.moduleNewToStructLiteralPass
        });

        // Inline ~H content by replacing Phoenix.HTML.raw(content) with the actual string literal
        // assigned to `content` earlier in render(assigns), removing the intermediate var.
        passes.push({
            name: "HeexContentInline",
            description: "Inline ~H content to avoid accessing local variables inside templates",
            enabled: true,
            pass: heexContentInlinePass
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
            pass: numericNoOpCleanupPass
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
        passes.push({
            name: "MapConcatEachToMapAssign",
            description: "Rewrite temp=[], Enum.each(... temp=Enum.concat(temp,[expr]) ...) → temp = Enum.map(list, fn -> expr) end",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.MapAndCollectionTransforms.mapConcatEachToMapAssignPass
        });
        passes.push({
            name: "FindRewrite",
            description: "Rewrite Enum.each scans ending with nil into Enum.find(list, &pred/1)",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.MapAndCollectionTransforms.findRewritePass
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
        passes.push({
            name: "EFnNumericSentinelCleanup(Final)",
            description: "Drop EInteger(0|1) and EFloat(0.0) statements in EFn bodies",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EFnNumericSentinelCleanupTransforms.cleanupPass
        });
        passes.push({
            name: "EFnLocalAssignDiscard(Final)",
            description: "Replace unused local rebinds in EFn bodies with wildcard assignment",
            enabled: true,
            pass: reflaxe.elixir.ast.transformers.EFnLocalAssignDiscardTransforms.discardPass
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
        //     pass: null // patternVariableOriginAnalysisPass
        // });

        // Safety net: ensure `require Ecto.Query` after all late passes
        passes.push({
            name: "EctoQueryRequireInjection(Final)",
            description: "Final sweep to inject `require Ecto.Query` in modules using Ecto.Query macros",
            enabled: true,
            pass: ectoQueryRequirePass
        });

        // Return only enabled passes
        return passes.filter(p -> p.enabled);
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
                    // Handle synthetic super calls marker, if any
                    if (methodName == "__super__") {
                        return makeAST(ENil);
                    }
                    
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
                    
                // fallthrough
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
     * Ecto Query Require Pass
     *
     * WHAT
     * - Scans modules for calls to Ecto.Query.* (macros like from/where/order_by/preload)
     * - Injects `require Ecto.Query` at module top if missing
     *
     * WHY
     * - In Elixir, macros must be required in the caller module
     * - Our builder emits ERemoteCall(EVar("Ecto.Query"), ...), which needs `require Ecto.Query`
     *
     * HOW
     * - Traverse defmodule body; if any ERemoteCall with module EVar("Ecto.Query") found, set needsRequire
     * - Check existing statements for Kernel.require("Ecto.Query"); if missing, prepend it
     */
    static function ectoQueryRequirePass(node: ElixirAST): ElixirAST {
        // Support both EDefmodule (do/end body) and EModule (attribute + body array) shapes
        function scanForEctoCalls(x: ElixirAST, found: {needs:Bool, has:Bool}): Void {
            if (x == null || x.def == null) return;
            switch (x.def) {
                case ERemoteCall(mod, func, args):
                    switch (mod.def) {
                        case EVar(m) if (m == "Kernel" && func == "require" && args != null && args.length == 1):
                            switch (args[0].def) { case EVar(v) if (v == "Ecto.Query"): found.has = true; default: }
                        case EVar(m) if (m == "Ecto.Query"): found.needs = true;
                        default:
                    }
                    if (args != null) for (a in args) scanForEctoCalls(a, found);
                case ECall(target, _, args):
                    if (target != null) scanForEctoCalls(target, found);
                    if (args != null) for (a in args) scanForEctoCalls(a, found);
                case EBlock(es): for (e in es) scanForEctoCalls(e, found);
                case EIf(c,t,e): scanForEctoCalls(c, found); scanForEctoCalls(t, found); if (e != null) scanForEctoCalls(e, found);
                case ECase(e, cs): scanForEctoCalls(e, found); for (c in cs) { if (c.guard != null) scanForEctoCalls(c.guard, found); scanForEctoCalls(c.body, found); }
                case EBinary(_, l, r): scanForEctoCalls(l, found); scanForEctoCalls(r, found);
                case EFn(cs): for (cl in cs) scanForEctoCalls(cl.body, found);
                case EDef(_, _, _, body): scanForEctoCalls(body, found);
                case EDefp(_, _, _, body): scanForEctoCalls(body, found);
                default:
            }
        }
        
        return transformNode(node, function(n: ElixirAST): ElixirAST {
            switch (n.def) {
                case EDefmodule(name, doBlock):
                    switch (doBlock.def) {
                        case EBlock(statements):
                            var found = {needs:false, has:false};
                            for (s in statements) scanForEctoCalls(s, found);
                            if (found.needs && !found.has) {
                                var requireStmt = makeAST(ERequire("Ecto.Query", null));
                                var newStatements = [requireStmt].concat(statements);
                                var newDo = makeASTWithMeta(EBlock(newStatements), doBlock.metadata, doBlock.pos);
                                return makeASTWithMeta(EDefmodule(name, newDo), n.metadata, n.pos);
                            }
                            return n;
                        default:
                            return n;
                    }
                case EModule(name, attrs, body):
                    var found2 = {needs:false, has:false};
                    for (b in body) scanForEctoCalls(b, found2);
                    if (found2.needs && !found2.has) {
                        var requireStmt2 = makeAST(ERequire("Ecto.Query", null));
                        var newBody = [requireStmt2].concat(body);
                        return makeASTWithMeta(EModule(name, attrs, newBody), n.metadata, n.pos);
                    }
                    return n;
                default:
                    return n;
            }
        });
    }

    /**
     * HeexContentInlinePass
     *
     * WHAT
     * - Replaces ~H"""<%= Phoenix.HTML.raw(content) %>""" in render(assigns) with ~H"""<html...>"""
     *   when `content` was assigned from a string literal earlier in the function.
     * - Removes the `content = "..."` intermediate assignment.
     *
     * WHY
     * - LiveView warns when templates access local variables; templates should use assigns
     *   or be self-contained. Inlining avoids variable access and keeps idiomatic ~H usage.
     *
     * HOW
     * - For EDef("render", [assigns], _, EBlock(stmts)) find:
     *   a) EMatch(PVar("content"), EString(html))
     *   b) ESigil("H", s) where s contains "Phoenix.HTML.raw(content)"
     *   Replace (b) with ESigil("H", html) and drop (a).
     */
    static function heexContentInlinePass(ast: ElixirAST): ElixirAST {
        return transformNode(ast, function(node: ElixirAST): ElixirAST {
            switch (node.def) {
                case EDef(name, args, guards, body) if (name == "render"):
                    // Only handle block bodies
                    switch (body.def) {
                        case EBlock(stmts):
                            var contentHtml: Null<String> = null;
                            var contentAssignIdx: Int = -1;
                            // Find content = "..." (allow optional parentheses)
                            for (i in 0...stmts.length) {
                                switch (stmts[i].def) {
                                    case EMatch(PVar(varName), rhs) if (varName == "content"):
                                        switch (rhs.def) {
                                            case EString(s): contentHtml = s;
                                            case EParen(inner):
                                                switch (inner.def) {
                                                    case EString(s2): contentHtml = s2;
                                                    default:
                                                }
                                            default:
                                        }
                                        contentAssignIdx = i;
                                        break;
                                    default:
                                }
                            }
                            if (contentHtml == null) return node;
                            // Find ~H that references Phoenix.HTML.raw(content) (allow EParen wrapping)
                            var sigilIdx: Int = -1;
                            for (i in 0...stmts.length) {
                                switch (stmts[i].def) {
                                    case ESigil(type, content, modifiers) if (type == "H" && content.indexOf("Phoenix.HTML.raw(content)") != -1):
                                        sigilIdx = i;
                                        break;
                                    case EParen(inner):
                                        switch (inner.def) {
                                            case ESigil(type2, content2, modifiers2) if (type2 == "H" && content2.indexOf("Phoenix.HTML.raw(content)") != -1):
                                                sigilIdx = i;
                                                break;
                                            default:
                                        }
                                    default:
                                }
                            }
                            if (sigilIdx == -1) return node;
                            // Build new statements: replace sigil with literal html, drop the assignment
                            var newStmts = [];
                            for (i in 0...stmts.length) {
                                if (i == contentAssignIdx) continue; // drop assignment
                                if (i == sigilIdx) {
                                    // Preserve parentheses if original was parenthesized
                                    switch (stmts[i].def) {
                                        case EParen(_):
                                            newStmts.push(makeASTWithMeta(EParen(makeAST(ESigil("H", contentHtml, ""))), stmts[i].metadata, stmts[i].pos));
                                        default:
                                            newStmts.push(makeASTWithMeta(ESigil("H", contentHtml, ""), stmts[i].metadata, stmts[i].pos));
                                    }
                                } else {
                                    newStmts.push(stmts[i]);
                                }
                            }
                            return makeASTWithMeta(EDef(name, args, guards, makeAST(EBlock(newStmts))), node.metadata, node.pos);
                        default:
                            return node;
                    }
                default:
                    return node;
            }
        });
    }

    /**
     * NumericNoOpCleanupPass
     *
     * WHAT
     * - Removes EBinary operations with numeric literals when used as statements.
     * - Converts bare increments like `if cond, do: count + 1` into `if cond, do: count = count + 1`.
     *
     * WHY
     * - Avoids Elixir warnings and preserves intended increment semantics when missed by earlier passes.
     */
    static function numericNoOpCleanupPass(ast: ElixirAST): ElixirAST {
        function isNumericLiteral(n: ElixirAST): Bool {
            return switch (n.def) {
                case EInteger(_) | EFloat(_): true;
                default: false;
            }
        }
        function rewriteIfIncrements(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EBinary(Add, {def: EInteger(a)}, {def: EInteger(b)}):
                    // Fold constant addition to a single literal (eliminates operator warning)
                    makeAST(EInteger(a + b));
                case EIf(cond, thenB, elseB):
                    var newThen = switch (thenB.def) {
                        case EBinary(Add, {def: EVar(v)}, rhs):
                            makeAST(EMatch(PVar(v), makeAST(EBinary(Add, makeAST(EVar(v)), rewriteIfIncrements(rhs)))));
                        case EBinary(Add, l, r) if (isNumericLiteral(l) && isNumericLiteral(r)):
                            makeAST(ENil);
                        default:
                            rewriteIfIncrements(thenB);
                    };
                    var newElse = if (elseB != null) switch (elseB.def) {
                        case EBinary(Add, {def: EVar(v2)}, rhs2):
                            makeAST(EMatch(PVar(v2), makeAST(EBinary(Add, makeAST(EVar(v2)), rewriteIfIncrements(rhs2)))));
                        case EBinary(Add, l2, r2) if (isNumericLiteral(l2) && isNumericLiteral(r2)):
                            makeAST(ENil);
                        default:
                            rewriteIfIncrements(elseB);
                    } else null;
                    makeASTWithMeta(EIf(rewriteIfIncrements(cond), newThen, newElse), n.metadata, n.pos);
                case EBlock(stmts):
                    var out: Array<ElixirAST> = [];
                    for (s in stmts) {
                        // Drop standalone numeric operations like 0 + 1
                        var drop = switch (s.def) {
                            case EBinary(_, l, r) if (isNumericLiteral(l) && isNumericLiteral(r)): true;
                            case EInteger(_): true; // Drop bare integer literal statements
                            default: false;
                        };
                        if (!drop) out.push(rewriteIfIncrements(s));
                    }
                    makeASTWithMeta(EBlock(out), n.metadata, n.pos);
                default:
                    n;
            }
        }
        return rewriteIfIncrements(ast);
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
        return transformNode(ast, function(node: ElixirAST): ElixirAST {
            #if debug_instance_methods
            switch(node.def) {
                case ECall(target, methodName, args):
                    trace('[InstanceMethodTransform] DEBUG - ECall detected:');
                    trace('  methodName: ${methodName}');
                    if (target != null) {
                        trace('  target.def: ${target.def}');
                    }
                    trace('  args.length: ${args.length}');
                default:
            }
            #end
            
            return switch(node.def) {
                // Handle instance method calls like instance.method(args)
                case ECall({def: EField(target, field), metadata: fieldMeta, pos: fieldPos}, methodName, args):
                    // This handles chained field access: struct.buffer.add()
                    // The field access (struct.buffer) becomes the target
                    // Transform to: StringBuf.add(struct.buffer, args)
                    
                    // Detect StringBuf methods
                    if (methodName == "add" || methodName == "toString" || methodName == "to_string") {
                        #if debug_instance_methods
                        trace('[InstanceMethodTransform] Detected potential StringBuf method: ${methodName}');
                        #end
                        
                        // For now, assume it's a StringBuf if it has these methods
                        // A more sophisticated approach would track types through metadata
                        var moduleName = switch(methodName) {
                            case "add": "StringBuf";
                            case "toString" | "to_string": "StringBuf";
                            default: null;
                        };
                        
                        if (moduleName != null) {
                            // Transform instance.method(args) to Module.method(instance, args)
                            var moduleRef = makeAST(EVar(moduleName));
                            var targetField = makeASTWithMeta(EField(target, field), fieldMeta, fieldPos);
                            var newArgs = [targetField].concat(args);
                            var functionName = switch(methodName) {
                                case "toString" | "to_string": "to_string";
                                default: methodName;
                            };
                            
                            return makeASTWithMeta(
                                ERemoteCall(moduleRef, functionName, newArgs),
                                node.metadata,
                                node.pos
                            );
                        }
                    }
                    
                    // Check for other known instance types
                    // Could extend this to Map, List, etc.
                    node;
                    
                case ECall(target, methodName, args) if (target != null):
                    // Handle direct method calls (without field access chain)
                    // Check if this is a method that should be transformed
                    switch(target.def) {
                        case EVar(varName):
                            // Direct variable method call: buffer.add() or struct.write_value()
                            if (methodName == "add" || methodName == "toString" || methodName == "to_string") {
                                #if debug_instance_methods
                                trace('[InstanceMethodTransform] Direct method call on var: ${varName}.${methodName}');
                                #end
                                
                                // Transform to module function call
                                var moduleName = "StringBuf"; // Assume StringBuf for these methods
                                var moduleRef = makeAST(EVar(moduleName));
                                var functionName = switch(methodName) {
                                    case "toString" | "to_string": "to_string";
                                    default: methodName;
                                };
                                
                                return makeASTWithMeta(
                                    ERemoteCall(moduleRef, functionName, [target].concat(args)),
                                    node.metadata,
                                    node.pos
                                );
                            } else if (methodName == "write_value" || methodName == "writeValue") {
                                #if debug_instance_methods
                                trace('[InstanceMethodTransform] Struct method call on var: ${varName}.${methodName}');
                                #end
                                
                                // Transform struct.write_value(args) to write_value(struct, args)  
                                var functionName = switch(methodName) {
                                    case "writeValue": "write_value";
                                    default: methodName;
                                };
                                
                                // Transform to local function call with struct as first argument
                                return makeASTWithMeta(
                                    ECall(null, functionName, [target].concat(args)),
                                    node.metadata,
                                    node.pos
                                );
                            }
                        case EField(obj, field):
                            // Method call on field access: struct.write_value()
                            // These should become local function calls: write_value(struct, ...)
                            if (methodName == "write_value" || methodName == "writeValue") {
                                #if debug_instance_methods
                                trace('[InstanceMethodTransform] Struct method call: ${field}.${methodName}');
                                #end
                                
                                // Transform struct.method(args) to method(struct, args)
                                var functionName = switch(methodName) {
                                    case "writeValue": "write_value";
                                    default: methodName;
                                };
                                
                                // Create the target (struct.field)
                                var targetExpr = makeAST(EField(obj, field));
                                
                                // Transform to local function call with struct as first argument
                                return makeASTWithMeta(
                                    ECall(null, functionName, [targetExpr].concat(args)),
                                    node.metadata,
                                    node.pos
                                );
                            }
                        default:
                    }
                    node;
                    
                default:
                    node;
            };
        });
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
        return transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch(node.def) {
                // Fold binary operations on constants
                case EBinary(op, left, right):
                    switch([left.def, right.def]) {
                        case [EInteger(l), EInteger(r)]:
                            var result = switch(op) {
                                case Add: l + r;
                                case Subtract: l - r;
                                case Multiply: l * r;
                                case Divide: Math.floor(l / r);
                                case Remainder: l % r;
                                case Less: l < r ? 1 : 0;
                                case Greater: l > r ? 1 : 0;
                                case LessEqual: l <= r ? 1 : 0;
                                case GreaterEqual: l >= r ? 1 : 0;
                                case Equal: l == r ? 1 : 0;
                                case NotEqual: l != r ? 1 : 0;
                                default: null;
                            };
                            
                            if (result != null) {
                                // For boolean results, convert to EBoolean
                                if (op == Less || op == Greater || op == LessEqual || 
                                    op == GreaterEqual || op == Equal || op == NotEqual) {
                                    makeASTWithMeta(EBoolean(result == 1), node.metadata, node.pos);
                                } else {
                                    makeASTWithMeta(EInteger(result), node.metadata, node.pos);
                                }
                            } else {
                                node; // Can't fold, return unchanged
                            }
                            
                        case [EString(l), EString(r)] if (op == StringConcat):
                            makeASTWithMeta(EString(l + r), node.metadata, node.pos);
                            
                        case [EList(l), EList(r)] if (op == Concat):
                            makeASTWithMeta(EList(l.concat(r)), node.metadata, node.pos);
                            
                        default:
                            node; // Not constant, return unchanged
                    }
                    
                // Fold unary operations on constants
                case EUnary(op, expr):
                    switch(expr.def) {
                        case EInteger(i) if (op == Negate):
                            makeASTWithMeta(EInteger(-i), node.metadata, node.pos);
                        case EBoolean(b) if (op == Not):
                            makeASTWithMeta(EBoolean(!b), node.metadata, node.pos);
                        default:
                            node;
                    }
                    
                default:
                    node; // Not a foldable expression
            }
        });
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
        
        return transform(ast);
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
        return transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch(node.def) {
                case EBlock(expressions):
                    // Look for pipeline patterns in blocks
                    var optimized = detectAndOptimizePipeline(expressions);
                    if (optimized != null) {
                        optimized;
                    } else {
                        node;
                    }
                    
                default:
                    node;
            }
        });
    }
    
    /**
     * Map Iterator Transformation Pass (forwarder)
     * Thin forwarder to MapAndCollectionTransforms.mapIteratorTransformPass
     */
    static function mapIteratorTransformPass(ast: ElixirAST): ElixirAST {
        return reflaxe.elixir.ast.transformers.MapAndCollectionTransforms.mapIteratorTransformPass(ast);
    }
    
    // Helper function to check if an AST contains Map iterator patterns
    // (legacy helper functions removed; implemented in MapAndCollectionTransforms)
    
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
        #if debug_effect_lifting
        trace('[XRay ListEffectLifting] Starting pass');
        #end
        
        return transformNode(ast, function(node: ElixirAST): ElixirAST {
            switch(node.def) {
                case EList(elements):
                    #if debug_effect_lifting
                    trace('[XRay ListEffectLifting] Processing list with ${elements.length} elements');
                    #end
                    
                    // Check if any element has side effects
                    var hasEffects = false;
                    var liftedStatements: Array<ElixirAST> = [];
                    var pureElements: Array<ElixirAST> = [];
                    
                    for (i in 0...elements.length) {
                        var elem = elements[i];
                        #if debug_effect_lifting
                        trace('[XRay ListEffectLifting] Checking element $i: ${ElixirASTPrinter.print(elem, 0).substring(0, 50)}');
                        #end
                        
                        switch(elem.def) {
                            case EMatch(left, right):
                                // Assignment inside list - needs lifting
                                #if debug_effect_lifting
                                trace('[XRay ListEffectLifting] Found assignment in element $i');
                                #end
                                hasEffects = true;
                                liftedStatements.push(elem);
                                // Replace with just the variable reference
                                switch(left) {
                                    case PVar(name):
                                        pureElements.push(makeAST(EVar(name)));
                                    default:
                                        // For other patterns, convert to a simple variable
                                        pureElements.push(makeAST(EVar("_lifted_var")));
                                }
                                
                            case EBlock(exprs) if (exprs.length > 0):
                                // Block inside list - extract statements, keep last expression
                                #if debug_effect_lifting
                                trace('[XRay ListEffectLifting] Found block in element $i with ${exprs.length} expressions');
                                #end
                                hasEffects = true;
                                for (j in 0...exprs.length - 1) {
                                    liftedStatements.push(exprs[j]);
                                }
                                pureElements.push(exprs[exprs.length - 1]);
                                
                            case EBinary(Concat, left, right):
                                // Check if this is a nested problematic pattern
                                switch(right.def) {
                                    case EList(innerElements) if (innerElements.length > 0):
                                        // Check if inner list has assignments
                                        var innerHasEffects = false;
                                        for (innerElem in innerElements) {
                                            switch(innerElem.def) {
                                                case EMatch(_, _) | EBlock(_):
                                                    innerHasEffects = true;
                                                    break;
                                                default:
                                            }
                                        }
                                        if (innerHasEffects) {
                                            #if debug_effect_lifting
                                            trace('[XRay ListEffectLifting] Found nested list with effects');
                                            #end
                                            // Process the inner list recursively
                                            var processedInner = listEffectLiftingPass(makeAST(right.def));
                                            switch(processedInner.def) {
                                                case EBlock(stmts) if (stmts.length > 0):
                                                    hasEffects = true;
                                                    // Add all but last statement to lifted
                                                    for (k in 0...stmts.length - 1) {
                                                        liftedStatements.push(stmts[k]);
                                                    }
                                                    // Keep the concatenation with cleaned list
                                                    pureElements.push(makeAST(EBinary(Concat, left, stmts[stmts.length - 1])));
                                                default:
                                                    pureElements.push(elem);
                                            }
                                        } else {
                                            pureElements.push(elem);
                                        }
                                    default:
                                        pureElements.push(elem);
                                }
                                
                            default:
                                // Pure expression, keep as-is
                                pureElements.push(elem);
                        }
                    }
                    
                    if (hasEffects) {
                        #if debug_effect_lifting
                        trace('[XRay ListEffectLifting] Lifting ${liftedStatements.length} statements');
                        #end
                        
                        // Return a block with lifted statements followed by pure list
                        var allStatements = liftedStatements.copy();
                        allStatements.push(makeAST(EList(pureElements)));
                        return makeAST(EBlock(allStatements));
                    }
                    
                    return node;
                    
                default:
                    return node;
            }
        });
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
        // Need to track the original struct variable for field assignments
        var structVarTracking: Map<String, String> = new Map();
        
        return transformNode(ast, function(node: ElixirAST): ElixirAST {
            switch(node.def) {
                case EBlock(expressions):
                    // Process block expressions looking for field assignment patterns
                    var transformed = [];
                    var i = 0;
                    
                    while (i < expressions.length) {
                        var expr = expressions[i];
                        
                        // Look for pattern: spec = worker(...) followed by fieldName = value
                        switch(expr.def) {
                            case EMatch(PVar(varName), rhs):
                                // Track struct variable assignments from known constructors
                                switch(rhs.def) {
                                    case ECall(_, funcName, _) if (funcName == "worker" || funcName == "supervisor" || funcName == "temp_worker"):
                                        structVarTracking.set(varName, varName);
                                    case ERemoteCall(_, funcName, _) if (funcName == "worker" || funcName == "supervisor" || funcName == "temp_worker"):
                                        structVarTracking.set(varName, varName);
                                    default:
                                }
                                
                                // Check if this is a field assignment pattern
                                // Look ahead for the next expression to see if it's a field assignment
                                if (i + 1 < expressions.length) {
                                    var nextExpr = expressions[i + 1];
                                    switch(nextExpr.def) {
                                        case EMatch(PVar(fieldName), fieldValue):
                                            // Check if previous expression was a struct assignment we're tracking
                                            // and the field name matches common struct field patterns
                                            if (structVarTracking.exists(varName) && 
                                                (fieldName == "restart" || fieldName == "shutdown" || fieldName == "type" || 
                                                 fieldName == "strategy" || fieldName == "max_restarts" || fieldName == "max_seconds")) {
                                                // This looks like a struct field assignment pattern
                                                // Transform: fieldName = value → spec = Map.put(spec, :fieldName, value)
                                                #if debug_ast_transformer
                                                trace('[XRay StructFieldAssignment] Found field assignment pattern: $fieldName = ...');
                                                trace('[XRay StructFieldAssignment] Transforming to Map.put($varName, :$fieldName, ...)');
                                                #end
                                                
                                                // Add the original struct assignment
                                                transformed.push(expr);
                                                
                                                // Transform the field assignment to Map.put
                                                var mapPut = makeAST(EMatch(
                                                    PVar(varName),
                                                    makeAST(ERemoteCall(
                                                        makeAST(EVar("Map")),
                                                        "put",
                                                        [
                                                            makeAST(EVar(varName)),
                                                            makeAST(EAtom(fieldName)),
                                                            fieldValue
                                                        ]
                                                    ))
                                                ));
                                                transformed.push(mapPut);
                                                
                                                // Skip the original field assignment
                                                i += 2;
                                                continue;
                                            }
                                        default:
                                    }
                                }
                                
                                // Not a field assignment pattern, keep as-is
                                transformed.push(expr);
                            default:
                                transformed.push(expr);
                        }
                        i++;
                    }
                    
                    // Return transformed block if we made changes
                    if (transformed.length > 0) {
                        return makeASTWithMeta(EBlock(transformed), node.metadata, node.pos);
                    }
                    return node;
                    
                default:
                    // Not a block, continue traversal
                    return node;
            }
        });
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
        // Transform with context tracking
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
        return transformWithContext(ast, true);
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
        #if debug_fluent_api
        trace("[FluentApiOptimization] Starting optimization pass");
        #end

        return transformNode(ast, function(node) {
            switch(node.def) {
                case EDef(name, args, guards, body):
                    var optimizedBody = optimizeFluentBody(body);
                    if (optimizedBody != body) {
                        #if debug_fluent_api
                        trace('[FluentApiOptimization] Optimized function: $name');
                        #end
                        return makeAST(EDef(name, args, guards, optimizedBody));
                    }
                case EDefp(name, args, guards, body):
                    var optimizedBody = optimizeFluentBody(body);
                    if (optimizedBody != body) {
                        #if debug_fluent_api
                        trace('[FluentApiOptimization] Optimized private function: $name');
                        #end
                        return makeAST(EDefp(name, args, guards, optimizedBody));
                    }
                default:
            }
            return node;
        });
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
            
            // Traverse anonymous functions and clause bodies
            case EFn(clauses):
                makeASTWithMeta(
                    EFn(clauses.map(cl -> {
                        args: cl.args,
                        guard: cl.guard != null ? transformNode(cl.guard, transformer) : null,
                        body: transformNode(cl.body, transformer)
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
        // Look for patterns like:
        // x = f(x, ...)
        // x = g(x, ...)
        // x = h(x, ...)
        // Also handles remote calls like:
        // x = Module.f(x, ...)
        // x = Module.g(x, ...)
        
        if (expressions.length < 2) return null;
        
        var pipelineOps = [];
        var baseVar: String = null;
        var lastExpr: ElixirAST = null;
        
        for (expr in expressions) {
            switch(expr.def) {
                case EMatch(PVar(name), call):
                    switch(call.def) {
                        case ECall(target, func, args):
                            if (args.length > 0) {
                                switch(args[0].def) {
                                    case EVar(argName) if (argName == name):
                                        // Found a pipeline candidate
                                        if (baseVar == null) {
                                            baseVar = name;
                                        }
                                        if (baseVar == name) {
                                            pipelineOps.push({
                                                func: func,
                                                args: args.slice(1),
                                                target: target
                                            });
                                            lastExpr = expr;
                                            continue;
                                        }
                                    default:
                                }
                            }
                        case ERemoteCall(module, func, args):
                            // Handle remote calls like EctoQuery_Impl_.where(query, ...)
                            if (args.length > 0) {
                                switch(args[0].def) {
                                    case EVar(argName) if (argName == name):
                                        // Found a pipeline candidate for remote call
                                        if (baseVar == null) {
                                            baseVar = name;
                                        }
                                        if (baseVar == name) {
                                            pipelineOps.push({
                                                func: func,
                                                args: args.slice(1),
                                                target: module  // Use module as target
                                            });
                                            lastExpr = expr;
                                            continue;
                                        }
                                    default:
                                }
                            }
                        default:
                    }
                default:
            }
            
            // Pattern broken, check if we have enough for a pipeline
            if (pipelineOps.length >= 2) {
                break;
            } else {
                // Reset and continue looking
                pipelineOps = [];
                baseVar = null;
            }
        }
        
        // Create pipeline if we found a pattern
        if (pipelineOps.length >= 2) {
            var pipeline = makeAST(EVar(baseVar));
            
            for (op in pipelineOps) {
                if (op.target != null) {
                    pipeline = makeAST(EPipe(
                        pipeline,
                        makeAST(ERemoteCall(op.target, op.func, op.args))
                    ));
                } else {
                    pipeline = makeAST(EPipe(
                        pipeline,
                        makeAST(ECall(null, op.func, op.args))
                    ));
                }
            }
            
            // Create final assignment
            return makeAST(EMatch(PVar(baseVar), pipeline));
        }
        
        return null;
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
        return transformNode(ast, function(node: ElixirAST): ElixirAST {
            switch(node.def) {
                case EBlock(expressions):
                    // Transform each if statement in the block
                    var transformed = [];
                    for (expr in expressions) {
                        if (expr == null || expr.def == null) {
                            continue;
                        }
                        switch(expr.def) {
                            case EIf(cond, thenBranch, null):  // If without else
                                // Check if the then branch is a single reassignment
                                switch(thenBranch.def) {
                                    case EMatch(PVar(varName), value):
                                        // Check if this is reassigning to an existing variable
                                        // by looking if the value references the same variable
                                        if (referencesVariable(value, varName)) {
                                            // Transform to functional style: var = if cond do new_value else var end
                                            var newIf = makeAST(EIf(
                                                cond,
                                                value,  // Return the new value
                                                makeAST(EVar(varName))  // Return original variable
                                            ));
                                            transformed.push(makeAST(EMatch(PVar(varName), newIf)));
                                        } else {
                                            transformed.push(expr);
                                        }
                                    default:
                                        transformed.push(expr);
                                }
                            default:
                                transformed.push(expr);
                        }
                    }
                    return makeASTWithMeta(EBlock(transformed), node.metadata, node.pos);
                    
                default:
                    return node;
            }
        });
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
        
        // M0 STABILIZATION: Disable underscore prefixing temporarily
        var hasChanges = false;
        /* Disabled to prevent variable mismatches
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
        */
        
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
