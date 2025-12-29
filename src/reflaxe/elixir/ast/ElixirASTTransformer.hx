package reflaxe.elixir.ast;

#if (macro || reflaxe_runtime)

#if macro
import haxe.macro.Context;
#end

import haxe.macro.Expr.Position;
import reflaxe.elixir.ast.ASTUtils;
import reflaxe.elixir.ast.ElixirAST.VarOrigin;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTBuilder;
import reflaxe.elixir.ast.naming.ElixirAtom;
import reflaxe.elixir.ast.transformers.GuardConditionFlattener;
import reflaxe.elixir.ast.transformers.LoopVariableRestorer;
import reflaxe.elixir.ast.transformers.PatternMatchingTransforms;
import reflaxe.elixir.ast.transformers.StructUpdateTransform;

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
    /**
     * Optional contextual variant of the pass (receives CompilationContext)
     */
    ?contextualPass: ContextualTransformPass,
    /**
     * Optional phase tag used for coarse ordering groups (e.g., "early", "post_interpolate").
     * When omitted, the pass remains in its original relative position unless constrained
     * by runAfter/runBefore.
     */
    ?phase: String,
    /**
     * Optional hard ordering constraints. Each entry indicates a pass name that this
     * pass must run AFTER. Multiple entries are allowed. Names not present in the registry
     * are ignored to keep ordering robust across optional builds.
     */
    ?runAfter: Array<String>,
    /**
     * Optional hard ordering constraints. Each entry indicates a pass name that this
     * pass must run BEFORE. Multiple entries are allowed. Unknown names are ignored.
     */
    ?runBefore: Array<String>
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
    // Public aliases for local transform passes (for registry access)
    public static var alias_abstractMethodThisPass: TransformPass = abstractMethodThisPass;
    public static var alias_arrayLengthFieldToFunctionPass: TransformPass = arrayLengthFieldToFunctionPass;
    public static var alias_comprehensionConversionPass: TransformPass = comprehensionConversionPass;
    public static var alias_conditionalReassignmentPass: TransformPass = conditionalReassignmentPass;
    public static var alias_constantFoldingPass: TransformPass = constantFoldingPass;
    public static var alias_ectoQueryRequirePass: TransformPass = ectoQueryRequirePass;
    public static var alias_fixBareConcatenationsPass: TransformPass = fixBareConcatenationsPass;
    public static var alias_fluentApiOptimizationPass: TransformPass = fluentApiOptimizationPass;
    public static var alias_functionReferenceTransformPass: TransformPass = functionReferenceTransformPass;
    public static var alias_guardGroupingPass: TransformPass = guardGroupingPass;
    public static var alias_heexContentInlinePass: TransformPass = heexContentInlinePass;
    public static var alias_identityPass: TransformPass = identityPass;
    public static var alias_idiomaticEnumPatternMatchingPass: TransformPass = idiomaticEnumPatternMatchingPass;
    public static var alias_immutabilityTransformPass: TransformPass = immutabilityTransformPass;
    public static var alias_instanceMethodTransformPass: TransformPass = instanceMethodTransformPass;
    public static var alias_listEffectLiftingPass: TransformPass = listEffectLiftingPass;
    public static var alias_liveViewCoreComponentsImportPass: TransformPass = liveViewCoreComponentsImportPass;
    public static var alias_loopTransformationPass: TransformPass = loopTransformationPass;
    public static var alias_nullCoalescingInlinePass: TransformPass = nullCoalescingInlinePass;
    public static var alias_numericNoOpCleanupPass: TransformPass = numericNoOpCleanupPass;
    public static var alias_otpChildSpecTransformPass: TransformPass = otpChildSpecTransformPass;
    public static var alias_phoenixComponentImportPass: TransformPass = phoenixComponentImportPass;
    public static var alias_phoenixFunctionMappingPass: TransformPass = phoenixFunctionMappingPass;
    public static var alias_pipelineOptimizationPass: TransformPass = pipelineOptimizationPass;
    public static var alias_prefixUnusedParametersPass: TransformPass = prefixUnusedParametersPass;
    public static var alias_removeRedundantEnumExtractionPass: TransformPass = removeRedundantEnumExtractionPass;
    public static var alias_removeRedundantNilInitPass: TransformPass = removeRedundantNilInitPass;
    public static var alias_selfReferenceTransformPass: TransformPass = selfReferenceTransformPass;
    public static var alias_statementContextTransformPass: TransformPass = statementContextTransformPass;
    public static var alias_stringInterpolationPass: TransformPass = stringInterpolationPass;
    public static var alias_stringMethodTransformPass: TransformPass = stringMethodTransformPass;
    public static var alias_structFieldAssignmentTransformPass: TransformPass = structFieldAssignmentTransformPass;
    public static var alias_supervisorOptionsTransformPass: TransformPass = supervisorOptionsTransformPass;
    public static var alias_throwStatementTransformPass: TransformPass = throwStatementTransformPass;
    public static var alias_tupleElemFieldToFunctionPass: TransformPass = tupleElemFieldToFunctionPass;
    public static var alias_underscoreVariableCleanupPass: TransformPass = underscoreVariableCleanupPass;

    // Public aliases for local transform passes (for registry access)

    // Public aliases for local transform passes (for registry access)

    
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
        #if debug_ast_transformer
        #if sys
        // DISABLED: Sys.println('[XRay AST Transformer] Starting transformation pipeline');
        #else
        // DISABLED: trace('[XRay AST Transformer] Starting transformation pipeline');
        #end
        // DISABLED: trace('[XRay AST Transformer] AST type: ${reflaxe.elixir.util.EnumReflection.enumConstructor(ast.def)}');
        // DISABLED: trace('[XRay AST Transformer] AST metadata: ${ast.metadata}');
        #end
        #if debug_unrolled_comprehension
        // DISABLED: trace('[DEBUG Transform] ElixirASTTransformer.transform() called');
        #end
        
        #if debug_ast_structure
        // Print AST structure for debugging
        switch(ast.def) {
            case EModule(name, _, _):
                // DISABLED: trace('[XRay AST Structure] Module: $name');
            default:
                // DISABLED: trace('[XRay AST Structure] Root: ${ast.def}');
        }
        #end

        var rootName = switch (ast.def) {
            case EModule(name, _, _) | EDefmodule(name, _):
                name;
            default:
                "<root>";
        };

        #if debug_root_names
        #if sys
        Sys.println('[ASTRoot] ' + rootName);
        Sys.stdout().flush();
        #else
        trace('[ASTRoot] ' + rootName);
        #end
        #end

        #if hxx_ast_progress
        transformInvocationCounter++;

        #if sys
        // DISABLED: Sys.println('[ASTProgress] #' + transformInvocationCounter + ' ' + rootName);
        #else
        // DISABLED: trace('[ASTProgress] #' + transformInvocationCounter + ' ' + rootName);
        #end
        #end

        #if hxx_pass_trace
        var passTraceEnabled = false;
        var passTraceFilter = getDefineString("hxx_pass_trace_filter");
        if (passTraceFilter == null || (rootName != null && rootName.indexOf(passTraceFilter) != -1)) {
            passTraceEnabled = true;
        }
        #end
        
        var passes = getEnabledPasses();
        var result = ast;

        #if ((hxx_pass_timing || profile_passes) && !hxx_disable_timing)
        var __pipelineStart = haxe.Timer.stamp();
        // Optional substring filter to reduce timing noise:
        //   -D hxx_pass_timing_filter=Reduce
        var __passTimingFilter = getDefineString("hxx_pass_timing_filter");
        if (__passTimingFilter != null && __passTimingFilter == "") __passTimingFilter = null;
        #end
        
        for (passConfig in passes) {
            // Skip disabled passes - the enabled flag MUST be respected
            if (!passConfig.enabled) {
                #if debug_ast_transformer
                // DISABLED: trace('[XRay AST Transformer] Skipping disabled pass: ${passConfig.name}');
                #end
                continue;
            }

            #if diag_pass_log
            #if sys
            Sys.println('[Pass] ' + passConfig.name);
            Sys.stdout().flush();
            #else
            trace('[Pass] ' + passConfig.name);
            #end
            #end

            #if debug_ast_transformer
            #if sys
            // DISABLED: Sys.println('[XRay AST Transformer] Applying pass: ${passConfig.name}');
            #else
            // DISABLED: trace('[XRay AST Transformer] Applying pass: ${passConfig.name}');
            #end
            #end

            #if hxx_pass_trace
            if (passTraceEnabled) {
                #if sys
                // DISABLED: Sys.println('[PassTrace] module=' + rootName + ' pass=' + passConfig.name + ' start');
                #else
                // DISABLED: trace('[PassTrace] module=' + rootName + ' pass=' + passConfig.name + ' start');
                #end
            }
            #end

            /**
             * PassMetrics (debug_pass_metrics)
             *
             * WHAT
             * - Optional, flag‑gated per‑pass change detector that reports when a pass
             *   modifies the AST during the main transformation loop.
             *
             * WHY
             * - Speeds up diagnosis of "which pass changed this?" without heavy logging
             *   or snapshotting. Helps avoid circular debugging by pinpointing impact.
             *
             * HOW
             * - Before running a pass, render the current AST to a string using the printer.
             * - After the pass, render again and compare. If different, emit a concise
             *   line: `#[PassMetrics] Changed by: <passName>`.
             * - Guarded by `-D debug_pass_metrics`; zero cost and zero output otherwise.
             *
             * EXAMPLES
             * - Build with: `-D debug_pass_metrics` to get a per‑pass change trace.
             * - Typical output:
             *   `#[PassMetrics] Changed by: FilterQueryConsolidate`
             */
            #if debug_pass_metrics
            var __beforePrint: String = null;
            try __beforePrint = reflaxe.elixir.ast.ElixirASTPrinter.print(result, 0) catch (e) {}
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
            #if ((hxx_pass_timing || profile_passes) && !hxx_disable_timing)
            var __t0 = haxe.Timer.stamp();
            #end
            #if debug_transformer_hang
            // Reset cycle detector per pass so visit counts reflect only the current pass.
            visitedNodes = new Map();
            nodeVisitCounter = 0;
            currentPassName = passConfig.name;
            #end
            if (passConfig.contextualPass != null && context != null) {
                #if debug_contextual_passes
                // DISABLED: trace('[XRay Contextual Pass] Using contextual variant for: ${passConfig.name}');
                // DISABLED: trace('[XRay Contextual Pass] Context available: ${context != null}');
                // DISABLED: trace('[XRay Contextual Pass] Variable mappings: ${context.tempVarRenameMap.keys()}');
                #end

                result = passConfig.contextualPass(result, context);
            } else {
                #if debug_contextual_passes
                // DISABLED: trace('[XRay Contextual Pass] Using stateless variant for: ${passConfig.name}');
                // DISABLED: trace('[XRay Contextual Pass] Contextual variant available: ${passConfig.contextualPass != null}');
                // DISABLED: trace('[XRay Contextual Pass] Context provided: ${context != null}');
                #end

                result = passConfig.pass(result);
            }
            #if ((hxx_pass_timing || profile_passes) && !hxx_disable_timing)
            var __elapsedPass = (haxe.Timer.stamp() - __t0) * 1000.0;

            // Apply optional substring filter when present.
            var __shouldLogPass = true;
            if (__passTimingFilter != null) {
                __shouldLogPass = (passConfig.name.indexOf(__passTimingFilter) != -1);
            }

            if (__shouldLogPass) {
                #if sys
                // Append timing to a deterministic file so partial logs survive.
                try {
                    var __log = sys.io.File.append("/tmp/passF-macro.log", false);
                    var __ms = Math.round(__elapsedPass * 100.0) / 100.0;
                    __log.writeString("[PassTiming] module=" + rootName + " name=" + passConfig.name + " ms=" + Std.string(__ms) + "\n");
                    __log.close();
                } catch (e) {
                    // Fallback to stdout if append fails.
                    // DISABLED: Sys.println('[PassTiming] name=' + passConfig.name + ' ms=' + Std.int(__elapsedPass));
                }
                #else
                // DISABLED: trace('[PassTiming] name=' + passConfig.name + ' ms=' + Std.int(__elapsedPass));
                #end
            }
            #end

            #if debug_ast_snapshots
            // Per‑pass function snapshot: when debug_ast_snapshots_func is set,
            // dump the target function after each pass to tmp/ast_flow/passes.
            try {
                PerPassSnapshot.emitFunctionAfterPass(result, passConfig.name);
                PerPassModuleSnapshot.emitModuleAfterPass(result, rootName, passConfig.name);
            } catch (e) {
                #if sys Sys.println('[AST Snapshot] PerPass failed for ' + passConfig.name + ': ' + Std.string(e)); #end
            }
            #end

            #if debug_pass_metrics
            var __afterPrint: String = null;
            var __changed: Bool = false;
            try {
                __afterPrint = reflaxe.elixir.ast.ElixirASTPrinter.print(result, 0);
                __changed = (__beforePrint != __afterPrint);
            } catch (e) {}
            if (__changed) {
                #if sys Sys.println('#[PassMetrics] Changed by: ' + passConfig.name); #else trace('#[PassMetrics] Changed by: ' + passConfig.name); #end
            }
            #end

            #if hxx_pass_trace
            if (passTraceEnabled) {
                #if sys
                // DISABLED: Sys.println('[PassTrace] module=' + rootName + ' pass=' + passConfig.name + ' end');
                #else
                // DISABLED: trace('[PassTrace] module=' + rootName + ' pass=' + passConfig.name + ' end');
                #end
            }
            #end
        }
        
        #if ((hxx_pass_timing || profile_passes) && !hxx_disable_timing)
        var __pipelineElapsed = (haxe.Timer.stamp() - __pipelineStart) * 1000.0;
        #if sys
        try {
            var __totalLog = sys.io.File.append("/tmp/passF-macro.log", false);
            var __ms = Math.round(__pipelineElapsed * 100.0) / 100.0;
            __totalLog.writeString("[PassTiming] module=" + rootName + " name=ElixirASTTransformer.total ms=" + Std.string(__ms) + "\n");
            __totalLog.close();
        } catch (e) {
            // DISABLED: Sys.println('[PassTiming] name=ElixirASTTransformer.total ms=' + Std.int(__pipelineElapsed));
        }
        #else
        // DISABLED: trace('[PassTiming] name=ElixirASTTransformer.total ms=' + Std.int(__pipelineElapsed));
        #end
        #end

        #if debug_ast_transformer
        // DISABLED: trace('[XRay AST Transformer] Transformation complete');
        #end

        // ------------------------------------------------------------------
        // AbsoluteFinal Snapshot (debug_ast_snapshots)
        //
        // WHAT
        // - Optional, flag‑gated AST snapshot immediately before printing.
        // - Captures only the then‑branch of the main guard `if` inside
        //   filter_todos/3 for the todo‑app to minimize noise.
        //
        // WHY
        // - We need to confirm the final shape of the filter branch:
        //   either a named binder `query = String.downcase(search_query)`
        //   precedes Enum.filter, or the downcased query is inlined within
        //   the filter predicate (EFn/ERaw). Pass ordering and rescue/final
        //   rewrites make late shape shifts hard to reason about via logs.
        //
        // HOW
        // - When `-D debug_ast_snapshots` is set, traverse the transformed
        //   AST, find `filter_todos/3` (EDef/EDefp name "filter_todos" with
        //   arity 3), locate the first top‑level EIf within its body, and
        //   print its thenBranch to `tmp/ast_flow/AbsoluteFinal_filter_todos_then_branch.ex`.
        // - Optional defines (if provided) allow function‑level selection:
        //   `-D debug_ast_snapshots_func=filter_todos/3`
        //   `-D debug_ast_snapshots_module=TodoAppWeb.TodoLive`
        //   These are best‑effort; default targets filter_todos/3 globally.
        //
        // EXAMPLES
        // Haxe (goal):
        //   if (searchQuery != "") {
        //     final query = String.downcase(searchQuery);
        //     return Enum.filter(todos, (t) -> String.contains(String.downcase(t.title), query));
        //   } else {
        //     todos;
        //   }
        // Elixir snapshot (then‑branch):
        //   query = String.downcase(search_query)
        //   Enum.filter(todos, fn t -> String.contains?(String.downcase(t.title), query) end)
        //   # or inline: Enum.filter(..., fn t -> String.contains?(String.downcase(t.title), String.downcase(search_query)) end)
        // ------------------------------------------------------------------
        #if debug_ast_snapshots
        try {
            AbsoluteFinalSnapshot.emitFilterTodosThenBranch(result);
        } catch (e) {
            #if sys Sys.println('[AST Snapshot] Failed: ' + Std.string(e)); #else trace('[AST Snapshot] Failed: ' + Std.string(e)); #end
        }
        #end

        #if debug_ast_transformer
        // DISABLED: trace('[XRay AST Transformer] Transformation complete');
        #end
        return result;
    }
    
    /**
     * Get list of enabled transformation passes
     */
    static function getEnabledPasses(): Array<PassConfig> {
        var passes = reflaxe.elixir.ast.transformers.registry.ElixirASTPassRegistry.getEnabledPasses();

        #if macro
        var disableSpec = getDefineString("hxx_disable_passes");
        if (disableSpec != null && disableSpec != "") {
            var tokens = disableSpec.split(",");
            var disabled = new Array<String>();
            for (tok in tokens) {
                var trimmed = tok.trim();
                if (trimmed != "") disabled.push(trimmed);
            }

            if (disabled.length > 0) {
                #if sys
                // DISABLED: Sys.println('[AST PassFilter] hxx_disable_passes=' + disabled.join(","));
                #else
                // DISABLED: trace('[AST PassFilter] hxx_disable_passes=' + disabled.join(","));
                #end

                passes = [
                    for (p in passes)
                    if (!isPassDisabled(p.name, disabled)) p
                ];
            }
        }
        #end

        return passes;
    }

    /**
     * Helper: read a string define in macro context; returns null when absent.
     */
    static inline function getDefineString(name: String): Null<String> {
        #if macro
        try {
            return Context.definedValue(name);
        } catch (_) {
            return null;
        }
        #else
        return null;
        #end
    }

    static function isPassDisabled(passName: String, disabled: Array<String>): Bool {
        for (token in disabled) {
            if (passName == token) return true;
        }
        return false;
    }

    // (debug_ast_snapshots helper moved to a top-level private class below)


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
        // DISABLED: trace('[XRay GuardGrouping] Starting guard grouping pass with three-phase flattener');
        if (ast != null && ast.def != null) {
            // DISABLED: trace('[XRay GuardGrouping] Processing node type: ' + ast.def);
        }
        #end
        
        // Handle null nodes
        if (ast == null) return null;
        
        return switch(ast.def) {
            case EParen(inner):
                // Check if the parentheses wrap a case expression
                #if debug_guard_grouping
                // DISABLED: trace("[XRay GuardGrouping] Found EParen, checking inner content");
                #end
                
                switch(inner?.def) {
                    case ECase(target, clauses):
                        #if debug_guard_grouping
                        // DISABLED: trace("[XRay GuardGrouping] Found ECase inside EParen, transforming");
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
                // DISABLED: trace("[XRay GuardGrouping] Found direct ECase with " + clauses.length + " clauses");
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
        // DISABLED: trace("[XRay GuardGrouping] Examining clause with three-phase flattener");
        if (clause.pattern != null) {
            // DISABLED: trace("[XRay GuardGrouping] Pattern type: " + Type.typeof(clause.pattern));
        }
        if (clause.body != null) {
            // DISABLED: trace("[XRay GuardGrouping] Body def: " + clause.body.def);
        }
        #end
        
        // Phase 1: Collect all guard conditions from nested if-else chains
        var guardBranches = GuardConditionCollector.collectAllGuardConditions(clause.body);
        
        #if debug_guard_grouping
        // DISABLED: trace('[XRay GuardGrouping] Phase 1 - Collected ${guardBranches.length} guard branches');
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
        // DISABLED: trace('[XRay GuardGrouping] Phase 2 - Validation result: canGroup=${validationResult.canGroup}, reason="${validationResult.reason}"');
        #end
        
        // If validation fails, fall back to recursive transformation
        if (!validationResult.canGroup) {
            #if debug_guard_grouping
            // DISABLED: trace('[XRay GuardGrouping] Validation failed: ${validationResult.reason}');
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
        // DISABLED: trace('[XRay GuardGrouping] Phase 3 - Built flat cond expression');
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
                // DISABLED: trace('[XRay RemoveNil] Processing EBlock with ${exprs.length} expressions');
                #end
                // Filter out nil assignments for generated variables
                var filtered = [];
                for (expr in exprs) {
                    var isGeneratedNilAssignment = switch(expr.def) {
                        case EMatch(PVar(varName), rhs) if (rhs != null):
                            #if debug_guard_grouping
                            // DISABLED: trace('[XRay RemoveNil] Checking match for variable: $varName');
                            // DISABLED: trace('[XRay RemoveNil] RHS type: ' + reflaxe.elixir.util.EnumReflection.enumConstructor(rhs.def));
                            #end
                            switch(rhs.def) {
                                case EAtom(a):
                                    var atomStr = (a:String);
                                    #if debug_guard_grouping
                                    // DISABLED: trace('[XRay RemoveNil] Atom value: "$atomStr"');
                                    #end
                                    if (atomStr == "nil") {
                                        // Check if variable name ends with digit (r2, b3, etc.)
                                        var isGenerated = ~/^[a-z]+\d+$/.match(varName);
                                        #if debug_guard_grouping
                                        // DISABLED: trace('[XRay RemoveNil] Is generated variable: $isGenerated for $varName');
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
                    // DISABLED: trace('[XRay GuardGrouping] Fixing variable: $name -> $fixedName');
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
            // DISABLED: trace("[XRay ExtractBranches] Depth " + depth + ", node type: " + (node.def != null ? reflaxe.elixir.util.EnumReflection.enumConstructor(node.def) : "null"));
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
                    // DISABLED: trace("[XRay ExtractBranches] Added branch at depth " + depth);
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
                    // DISABLED: trace("[XRay ExtractBranches] Added final branch at depth " + depth);
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
        // DISABLED: trace('[RemoveRedundantEnumExtraction] Debug mode enabled');
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
                    // DISABLED: trace('[RemoveRedundantEnumExtraction] Processing ECase with ${clauses.length} clauses, target: $targetDebug');
                    #end
                    // Check if this case has an enum binding plan
                    currentCaseHasBindingPlan = node.metadata != null && node.metadata.hasEnumBindingPlan == true;
                    #if debug_enum_extraction
                    if (currentCaseHasBindingPlan) {
                        // DISABLED: trace('[RemoveRedundantEnumExtraction] Found ECase with hasEnumBindingPlan flag');
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
                        #if debug_redundant_extraction
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
                        // DISABLED: trace('[RemoveRedundantEnumExtraction] Clause $i pattern: $patternDebug');
                        #end

                        // Propagate the binding plan flag to the clause body
                        if (currentCaseHasBindingPlan && body != null) {
                            if (body.metadata == null) body.metadata = {};
                            body.metadata.parentHasBindingPlan = true;
                        }

                        // Check if body contains redundant extraction (guard for null bodies)
                        var newBody = if (body == null) null else switch(body.def) {
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
                                        // DISABLED: trace('[RemoveRedundantEnumExtraction] Found node marked as redundant via metadata');
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
                                                    default: reflaxe.elixir.util.EnumReflection.enumConstructor(rhs.def);
                                                };
                                                #if debug_redundant_extraction
                                                // DISABLED: trace('[RemoveRedundantEnumExtraction] Found assignment: $varName = ... (RHS: $rhsDebug, caseTarget: $caseTargetVar)');
                                                #end
                                            } else {
                                                #if debug_redundant_extraction
                                                // DISABLED: trace('[RemoveRedundantEnumExtraction] Found assignment: $varName = null (skipped assignment)');
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
                                            // DISABLED: trace('[RemoveRedundantEnumExtraction] Removing self-assignment: $varName = $varName');
                                            #end
                                        }
                                        // Check if the target variable itself is a temp pattern var
                                        else if (reflaxe.elixir.ast.ElixirASTBuilder.isTempPatternVarName(varName)) {
                                            isRedundant = true;
                                            #if debug_redundant_extraction
                                            // DISABLED: trace('[RemoveRedundantEnumExtraction] Removing temp-var assignment: $varName = ...');
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
                                                        // DISABLED: trace('[RemoveRedundantEnumExtraction] Removing assignment: $varName = $v (non-existent temp var)');
                                                        #end
                                                    }
                                                    // Check for numbered temp vars in RHS: g1, g2, etc.
                                                    else if (v.length > 1 && v.charAt(0) == "g" &&
                                                             v.length == 2 && v.charAt(1) >= '0' && v.charAt(1) <= '9') {
                                                        isRedundant = true;
                                                        #if debug_redundant_extraction
                                                        // DISABLED: trace('[RemoveRedundantEnumExtraction] Removing assignment: $varName = $v (non-existent numbered temp var)');
                                                        #end
                                                    }
                                                    // Check for underscore-prefixed numbered temp vars: _g1, _g2, etc.
                                                    else if (v.length == 3 && v.charAt(0) == "_" && v.charAt(1) == "g" &&
                                                             v.charAt(2) >= '0' && v.charAt(2) <= '9') {
                                                        isRedundant = true;
                                                        #if debug_redundant_extraction
                                                        // DISABLED: trace('[RemoveRedundantEnumExtraction] Removing assignment: $varName = $v (non-existent underscore temp var)');
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
                                                            // DISABLED: trace('[RemoveRedundantEnumExtraction] Removing incorrect assignment: $varName = $v (pattern already extracted value)');
                                                            #end
                                                        }
                                                    }

                                                case ECall(targetExpr, funcName, args) if (funcName == "elem" && args.length == 1):
                                                    #if debug_redundant_extraction
                                                    // DISABLED: trace('[RemoveRedundantEnumExtraction]   - Found elem() call');
                                                    #end
                                                    // Check if elem is extracting from the case target
                                                    var isTargetMatch = switch(targetExpr.def) {
                                                        case EVar(v):
                                                            #if debug_redundant_extraction
                                                            // DISABLED: trace('[RemoveRedundantEnumExtraction]   - elem() target: $v, case target: $caseTargetVar');
                                                            #end
                                                            // Check if this matches the case target variable
                                                            v == caseTargetVar;
                                                        default:
                                                            #if debug_redundant_extraction
                                                            // DISABLED: trace('[RemoveRedundantEnumExtraction]   - elem() target is not a simple variable');
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
                                                            // DISABLED: trace('[RemoveRedundantEnumExtraction] Not redundant - varName: $varName does not match g pattern');
                                                            #end
                                                        }
                                                    } else {
                                                        #if debug_redundant_extraction
                                                        // DISABLED: trace('[RemoveRedundantEnumExtraction] elem() not extracting from case target');
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
                        // DISABLED: trace('[FunctionRef] Found marked field: $field');
                        #end
                        
                        // Extract the actual field name and arity
                        var parts = field.split("__FUNC_REF__");
                        var actualField = parts[0];
                        var arity = parts.length > 1 ? Std.parseInt(parts[1]) : 0;
                        if (arity == null) arity = 0;
                        
                        #if debug_function_reference
                        // DISABLED: trace('[FunctionRef] Transforming to capture: &Module.$actualField/$arity');
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
                    // DISABLED: trace('[NullCoalescing] Found EMatch with name: $name');
                    if (value != null) {
                        switch(value.def) {
                            case EBlock(exprs):
                                // DISABLED: trace('[NullCoalescing] Found block with ${exprs.length} expressions');
                            default:
                                // DISABLED: trace('[NullCoalescing] Value is not a block: ${value.def}');
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
                        // DISABLED: trace("[SuperTransform] Collected module metadata: parentModule=" + 
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
                    // DISABLED: trace("[SuperTransform] Processing ECall:");
                    // DISABLED: trace("  target = " + target);
                    // DISABLED: trace("  methodName = " + methodName);
                    // DISABLED: trace("  args = " + args);
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
                                    // DISABLED: trace("[SuperTransform] Found super." + fieldName + " as first argument");
                                    #end
                                    if (fieldName == "to_string" || fieldName == "toString") {
                                        #if debug_super_handling
                                        // DISABLED: trace("[SuperTransform] Transforming super.toString() call to empty string");
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
                                // DISABLED: trace("[SuperTransform] Direct super as target detected!");
                                // DISABLED: trace("  methodName = " + methodName);
                                // DISABLED: trace("  node.metadata = " + node.metadata);
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
                                    // Constructor super-call: `super(...)` in Haxe becomes a call on the
                                    // synthetic `super` variable with an empty method name (function var call).
                                    //
                                    // Elixir has no inheritance; constructors compile to `Module.new/arity`.
                                    // Rebind `struct` to the parent constructor result so downstream code
                                    // sees the initialized base fields and we avoid invalid `Parent.(...)` calls.
                                    if (methodName == "") {
                                        return makeAST(EMatch(
                                            PVar("struct"),
                                            makeAST(ERemoteCall(
                                                makeAST(EVar(parentModule)),
                                                "new",
                                                args
                                            ))
                                        ));
                                    }

                                    // Special handling for Exception parent (it's a behaviour, not a module with methods)
                                    if (parentModule == "Exception" && (methodName == "toString" || methodName == "to_string")) {
                                        #if debug_super_handling
                                        // DISABLED: trace("[SuperTransform] Special handling for Exception.toString()");
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
                                    // DISABLED: trace("[SuperTransform] Delegating to parent module: " + parentModule);
                                    // DISABLED: trace("[SuperTransform] Parent module type: " + Type.typeof(parentModule));
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
                                    // DISABLED: trace("[SuperTransform] No parent module found, handling toString for exception");
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
                                    // DISABLED: trace("[SuperTransform] No parent module found, keeping super call as is");
                                    #end
                                    node;
                                }
                                
                            case EField(superVar, fieldName):
                                #if debug_super_handling
                                // DISABLED: trace("[SuperTransform] EField target detected:");
                                // DISABLED: trace("  superVar.def = " + superVar.def);
                                // DISABLED: trace("  fieldName = " + fieldName);
                                #end
                                
                                if (superVar.def.match(EVar("super"))) {
                                    #if debug_super_handling
                                    // DISABLED: trace("[SuperTransform] Super method call detected!");
                                    #end
                                    
                                    // This is super.method() call
                                    if (fieldName == "to_string" || fieldName == "toString") {
                                        #if debug_super_handling
                                        // DISABLED: trace("[SuperTransform] Transforming super.toString() for exception class");
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
                                // DISABLED: trace("[SuperTransform] Target is not super or field access, keeping node");
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
        // DISABLED: trace('[XRay PhoenixComponentImport] Starting scan for ~H sigils');
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
                    // DISABLED: trace('[XRay PhoenixComponentImport] Found sigil type: $type');
                    #end
                    if (type == "H") {
                        needsPhoenixComponent = true;
                    }
                case ERaw(code):
                    // Also catch ~H usage present inside raw code blocks (e.g., untyped __elixir__ "~H\"\"\"...\"\"\"")
                    if (code != null && (code.indexOf("~H\"\"\"") != -1 || code.indexOf("~H\"") != -1)) {
                        needsPhoenixComponent = true;
                    } else {
                        // Continue traversal for any nested nodes in raw if needed
                        iterateAST(node, checkForHSigil);
                    }
                default:
                    // For all other node types, recursively visit children
                    iterateAST(node, checkForHSigil);
            }
        }
        
        checkForHSigil(ast);
        
        #if debug_phoenix_component_import
        // DISABLED: trace('[XRay PhoenixComponentImport] Needs Phoenix.Component: $needsPhoenixComponent');
        #end
        
        // Phase 2: Add import if needed
        if (!needsPhoenixComponent) return ast;
        
        return transformNode(ast, function(node: ElixirAST): ElixirAST {
            switch(node.def) {
                case EModule(name, attributes, body):
                    // Handle module nodes constructed via EModule (ModuleBuilder default)
                    // Inject `use Phoenix.Component` at the top of the body when ~H is present
                    var hasImport = false;
                    // Scan existing body for EUse/EImport Phoenix.Component
                    for (stmt in body) switch (stmt.def) {
                        case EUse(mod, _): if (mod == "Phoenix.Component") { hasImport = true; }
                        case EImport(mod, _, _, _): if (mod == "Phoenix.Component") { hasImport = true; }
                        default:
                    }
                    if (!hasImport) {
                        var importStmt = makeAST(EUse("Phoenix.Component", []));
                        var newBody = [importStmt].concat(body);
                        return makeASTWithMeta(EModule(name, attributes, newBody), node.metadata, node.pos);
                    }
                    return node;
                case EDefmodule(name, doBlock):
                    #if debug_phoenix_component_import
                    // DISABLED: trace('[XRay PhoenixComponentImport] Processing defmodule: $name');
                    #end
                    
                    // For defmodule, we need to inject the import into the do block
                    switch(doBlock.def) {
                        case EBlock(statements):
                            #if debug_phoenix_component_import
                            // DISABLED: trace('[XRay PhoenixComponentImport] Defmodule has ${statements.length} statements');
                            #end
                            
                            // Check if Phoenix.Component is already imported or if LiveView is used
                            var hasImport = false;
                            var hasLiveViewUse = false;
                            for (stmt in statements) {
                                switch(stmt.def) {
                                    case EImport(module, _, _, _):
                                        // module is a string in EImport
                                        if (module == "Phoenix.Component") {
                                            hasImport = true;
                                            break;
                                        }
                                    case EUse(module, opts):
                                        // module is a string in EUse
                                        #if debug_phoenix_component_import
                                        // DISABLED: trace('[XRay PhoenixComponentImport] Found EUse: module=$module, opts=$opts');
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
                                                // DISABLED: trace('[XRay PhoenixComponentImport] Checking option: $opt');
                                                #end
                                                switch(opt.def) {
                                                    // Pattern matching with abstract types requires guard clause
                                                case EAtom(atom) if (atom == "live_view"):
                                                        #if debug_phoenix_component_import
                                                        // DISABLED: trace('[XRay PhoenixComponentImport] Found :live_view option - will skip Phoenix.Component');
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
                            
                            /**
                             * LayoutContextHtmlUse Injection
                             *
                             * WHAT
                             * - For modules named `<App>Web.Layouts`, inject `use <App>Web, :html` instead of a raw
                             *   `use Phoenix.Component` so that the full Phoenix 1.7 HTML context is available.
                             *
                             * WHY
                             * - Layout modules commonly return ~H templates and rely on helpers (HTML, VerifiedRoutes,
                             *   controller conveniences). `:html` brings those into scope without app coupling.
                             *
                             * HOW
                             * - Detect EDefmodule with name ending in ".Layouts"; derive `<App>Web` from the prefix before
                             *   "Web" and prepend `use <App>Web, :html` when missing.
                             *
                             * EXAMPLES
                             *   Before:
                             *     defmodule TodoAppWeb.Layouts do
                             *       # (no imports)
                             *       def root(assigns), do: ~H"<head>...</head>"
                             *     end
                             *
                             *   After:
                             *     defmodule TodoAppWeb.Layouts do
                             *       use TodoAppWeb, :html
                             *       def root(assigns), do: ~H"<head>...</head>"
                             *     end
                             */
                            // If this is a Layouts module, ensure `use <App>Web, :html`
                            // so ~H helpers (Phoenix.Component, VerifiedRoutes, controller helpers) are in scope.
                            var isLayoutsModule = (name != null && StringTools.endsWith(name, ".Layouts"));

                            // Don't add Phoenix.Component or additional uses if LiveView is already used
                            if (hasLiveViewUse) {
                                #if debug_phoenix_component_import
                                // DISABLED: trace('[XRay PhoenixComponentImport] Module already has LiveView use statement, skipping Phoenix.Component');
                                #end
                                return node;
                            }
                            
                            // For Layouts modules, prefer `use <App>Web, :html`
                            if (isLayoutsModule) {
                                // Derive <App> from "<App>Web.Layouts"
                                var appIdx = name.indexOf("Web");
                                var appPrefix = appIdx > 0 ? name.substr(0, appIdx) : null;
                                if (appPrefix != null) {
                                    var webModule = appPrefix + "Web";
                                    // Check if `use <App>Web, :html` already exists
                                    var hasHtmlUse = false;
                                    for (stmt in statements) switch (stmt.def) {
                                        case EUse(mod, opts):
                                            if (mod == webModule && opts != null) {
                                                for (o in opts) switch (o.def) { case EAtom(a) if (a == "html"): hasHtmlUse = true; default: }
                                            }
                                        default:
                                    }
                                    if (!hasHtmlUse) {
                                        #if debug_phoenix_component_import
                                        // DISABLED: trace('[XRay PhoenixComponentImport] Adding use ' + webModule + ', :html for Layouts module');
                                        #end
                                        var htmlUse = makeAST(EUse(webModule, [ makeAST(EAtom("html")) ]));
                                        var newStatements = [htmlUse].concat(statements);
                                        var newDoBlock = makeASTWithMeta(EBlock(newStatements), doBlock.metadata, doBlock.pos);
                                        return makeASTWithMeta(EDefmodule(name, newDoBlock), node.metadata, node.pos);
                                    }
                                }
                            } else if (!hasImport) {
                                #if debug_phoenix_component_import
                                // DISABLED: trace('[XRay PhoenixComponentImport] Adding Phoenix.Component import');
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
                case ERaw(code):
                    // Detect remote macro usage in raw injections only when explicitly remote
                    if (code != null && code.indexOf("Ecto.Query.") != -1) found.needs = true;
                // Remote-only gating: do NOT infer from pin operator alone
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
                        case EBlock(statements) | EDo(statements):
                            var found = {needs:false, has:false};
                            for (s in statements) scanForEctoCalls(s, found);
                            if (found.needs && !found.has) {
                                #if debug_ecto_query_require
                                // DISABLED: trace('[EctoQueryRequire] Injecting require into defmodule ' + name);
                                #end
                                var requireStmt = makeAST(ERequire("Ecto.Query", null));
                                var newStatements = [requireStmt].concat(statements);
                                var newDo: ElixirAST = switch (doBlock.def) {
                                    case EBlock(_): makeASTWithMeta(EBlock(newStatements), doBlock.metadata, doBlock.pos);
                                    case EDo(_): makeASTWithMeta(EDo(newStatements), doBlock.metadata, doBlock.pos);
                                    default: doBlock;
                                };
                                return makeASTWithMeta(EDefmodule(name, newDo), n.metadata, n.pos);
                            }
                            #if debug_ecto_query_require
                            if (found.needs && found.has) trace('[EctoQueryRequire] Already has require in defmodule ' + name);
                            if (!found.needs) trace('[EctoQueryRequire] No Ecto.Query usage detected in defmodule ' + name);
                            #end
                            return n;
                        default:
                            return n;
                    }
                case EModule(name, attrs, body):
                    var found2 = {needs:false, has:false};
                    for (b in body) scanForEctoCalls(b, found2);
                    if (found2.needs && !found2.has) {
                        #if debug_ecto_query_require
                        // DISABLED: trace('[EctoQueryRequire] Injecting require into module ' + name);
                        #end
                        var requireStmt2 = makeAST(ERequire("Ecto.Query", null));
                        var newBody = [requireStmt2].concat(body);
                        return makeASTWithMeta(EModule(name, attrs, newBody), n.metadata, n.pos);
                    }
                    #if debug_ecto_query_require
                    if (found2.needs && found2.has) trace('[EctoQueryRequire] Already has require in module ' + name);
                    if (!found2.needs) trace('[EctoQueryRequire] No Ecto.Query usage detected in module ' + name);
                    #end
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
        function isOneLiteral(n: ElixirAST): Bool {
            return switch (n.def) {
                case EInteger(v) if (v == 1): true;
                case EFloat(f) if (f == 1.0): true;
                default: false;
            }
        }
        function rewriteStandaloneInc(n: ElixirAST): Null<ElixirAST> {
            if (n == null || n.def == null) return null;
            return switch (n.def) {
                // Standalone increments/decrements (from ++/-- statements) must rebind the variable
                // to preserve side effects in Elixir.
                case EBinary(Add, {def: EVar(v)}, rhs) if (v != null && isOneLiteral(rhs)):
                    makeASTWithMeta(EMatch(PVar(v), makeAST(EBinary(Add, makeAST(EVar(v)), rhs))), n.metadata, n.pos);
                case EBinary(Subtract, {def: EVar(varName)}, rhs) if (varName != null && isOneLiteral(rhs)):
                    makeASTWithMeta(EMatch(PVar(varName), makeAST(EBinary(Subtract, makeAST(EVar(varName)), rhs))), n.metadata, n.pos);
                case EParen(inner):
                    var rewritten = rewriteStandaloneInc(inner);
                    rewritten != null ? rewritten : null;
                default:
                    null;
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
                        case EBinary(Add, {def: EVar(varName)}, rhs):
                            makeAST(EMatch(PVar(varName), makeAST(EBinary(Add, makeAST(EVar(varName)), rewriteIfIncrements(rhs)))));
                        case EBinary(Add, l2, r2) if (isNumericLiteral(l2) && isNumericLiteral(r2)):
                            makeAST(ENil);
                        default:
                            rewriteIfIncrements(elseB);
                    } else null;
                    makeASTWithMeta(EIf(rewriteIfIncrements(cond), newThen, newElse), n.metadata, n.pos);
                case EBlock(stmts):
                    var out: Array<ElixirAST> = [];
                    for (idx in 0...stmts.length) {
                        var s = stmts[idx];
                        // Drop standalone numeric operations like 0 + 1, but preserve a trailing
                        // bare numeric literal as it may represent an intentional return value
                        // (e.g., final 0 in compare/2).
                        var isLast = (idx == stmts.length - 1);
                        var incRewrite = rewriteStandaloneInc(s);
                        if (incRewrite != null) s = incRewrite;
                        var drop = switch (s.def) {
                            case EBinary(_, l, r) if (isNumericLiteral(l) && isNumericLiteral(r)): true;
                            case EInteger(_) if (!isLast): true; // Only drop bare integer when not last
                            default: false;
                        };
                        if (!drop) out.push(rewriteIfIncrements(s));
                    }
                    makeASTWithMeta(EBlock(out), n.metadata, n.pos);
                case EDo(stmts):
                    var outDo: Array<ElixirAST> = [];
                    for (idx in 0...stmts.length) {
                        var stmt = stmts[idx];
                        var isLast = (idx == stmts.length - 1);
                        var incRewrite = rewriteStandaloneInc(stmt);
                        if (incRewrite != null) stmt = incRewrite;
                        var drop = switch (stmt.def) {
                            case EBinary(_, l, r) if (isNumericLiteral(l) && isNumericLiteral(r)): true;
                            case EInteger(_) if (!isLast): true;
                            default: false;
                        };
                        if (!drop) outDo.push(rewriteIfIncrements(stmt));
                    }
                    makeASTWithMeta(EDo(outDo), n.metadata, n.pos);
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
                    // DISABLED: trace('[PhoenixFunctionMapping] Transforming assign_multiple to assign');
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
        // DISABLED: trace('[XRay LiveViewComponents] Starting scan for component usage');
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
                            // DISABLED: trace('[XRay LiveViewComponents] Found component usage in ~H sigil');
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
        // DISABLED: trace('[XRay LiveViewComponents] Needs CoreComponents: $needsCoreComponents');
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
                    // DISABLED: trace('[XRay LiveViewComponents] Processing defmodule: $name');
                    #end
                    
                    // For defmodule, we need to inject the import into the do block
                    switch(doBlock.def) {
                        case EBlock(statements):
                            // Check if CoreComponents is already imported
                            var hasImport = false;
                            for (stmt in statements) {
                                switch(stmt.def) {
                                    case EImport(module, _, _, _):
                                        if (module == coreComponentsModule) {
                                            hasImport = true;
                                            break;
                                        }
                                    default:
                                }
                            }
                            
                            if (!hasImport) {
                                #if debug_liveview_components
                                // DISABLED: trace('[XRay LiveViewComponents] Adding CoreComponents import: $coreComponentsModule');
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
                    // DISABLED: trace('[InstanceMethodTransform] DEBUG - ECall detected:');
                    // DISABLED: trace('  methodName: ${methodName}');
                    if (target != null) {
                        // DISABLED: trace('  target.def: ${target.def}');
                    }
                    // DISABLED: trace('  args.length: ${args.length}');
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
                        // DISABLED: trace('[InstanceMethodTransform] Detected potential StringBuf method: ${methodName}');
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
                                // DISABLED: trace('[InstanceMethodTransform] Direct method call on var: ${varName}.${methodName}');
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
                                // DISABLED: trace('[InstanceMethodTransform] Struct method call on var: ${varName}.${methodName}');
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
                                // DISABLED: trace('[InstanceMethodTransform] Struct method call: ${field}.${methodName}');
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
                        // DISABLED: trace('[StringMethodTransform] Converting ${methodName} to String.${stringMethod}');
                        if (target != null) {
                            // DISABLED: trace('[StringMethodTransform] Target exists');
                        }
                        // DISABLED: trace('[StringMethodTransform] Args count: ${args.length}');
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
                    // DISABLED: trace('[StringInterpolation] Found concatenation pattern: ${fullNodeStr.substring(0, 200)}');
                    // DISABLED: trace('[StringInterpolation] Left type: ${reflaxe.elixir.util.EnumReflection.enumConstructor(l.def)}');
                    // DISABLED: trace('[StringInterpolation] Right type: ${reflaxe.elixir.util.EnumReflection.enumConstructor(r.def)}');
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
                                
                                // Simplify common shapes for idiomatic interpolation: inspect(Map.get(obj, :field)) -> obj.field
                                function simplifyInterpolationExpr(e: ElixirAST): ElixirAST {
                                    return switch (e.def) {
                                        case ECall(null, "inspect", [inner]):
                                            switch (inner.def) {
                                                case ERemoteCall({def: EVar("Map")}, "get", args) if (args != null && args.length == 2):
                                                    switch (args[1].def) {
                                                        case EAtom(field): makeASTWithMeta(EField(args[0], field), e.metadata, e.pos);
                                                        default: e;
                                                    }
                                                default: e;
                                            }
                                        default:
                                            e;
                                    }
                                }
                                exprToInterpolate = simplifyInterpolationExpr(exprToInterpolate);
                                
                                // Sanitize inline expression for interpolation: ensure no raw multi-statement
                                // blocks appear in function arguments (e.g., Enum.join(<block>, ",")).
                                function sanitizeForInterpolation(n: ElixirAST): ElixirAST {
                                    return transformNode(n, function(x: ElixirAST): ElixirAST {
                                        return switch (x.def) {
                                            case ECall(t, name, args):
                                                var newArgs = [];
                                                for (a in args) switch (a.def) {
                                                    case EBlock(sts) if (sts != null && sts.length > 1):
                                                        newArgs.push(makeAST(ECall(makeAST(EFn([{ args: [], guard: null, body: a }])), "", [])));
                                                    default:
                                                        newArgs.push(a);
                                                }
                                                if (newArgs != args) makeAST(ECall(t, name, newArgs)) else x;
                                            case ERemoteCall(mod, fname, rargs):
                                                var newRArgs = [];
                                                for (a2 in rargs) switch (a2.def) {
                                                    case EBlock(sts2) if (sts2 != null && sts2.length > 1):
                                                        newRArgs.push(makeAST(ECall(makeAST(EFn([{ args: [], guard: null, body: a2 }])), "", [])));
                                                    default:
                                                        newRArgs.push(a2);
                                                }
                                                if (newRArgs != rargs) makeAST(ERemoteCall(mod, fname, newRArgs)) else x;
                                            default:
                                                x;
                                        }
                                    });
                                }
                                // Avoid wrapping trivial expressions (vars, literals, simple field chains)
                                function isTrivialForInterpolation(x: ElixirAST, depth:Int = 0): Bool {
                                    if (x == null || depth > 4) return false;
                                    return switch (x.def) {
                                        case EVar(_): true;
                                        case EInteger(_)|EFloat(_)|EBoolean(_)|ENil|EString(_)|EAtom(_): true;
                                        case EField(obj, _): isTrivialForInterpolation(obj, depth + 1);
                                        default: false;
                                    }
                                }
                                var sanitizedExpr = sanitizeForInterpolation(exprToInterpolate);
                                var exprStr = ElixirASTPrinter.printAST(sanitizedExpr);
                                var trivial = isTrivialForInterpolation(sanitizedExpr);
                                // Only wrap when non-trivial and the printed expression clearly spans multiple
                                // statements or contains a standalone assignment (not a comparison).
                                var needsWrapIife = !trivial && ((exprStr.indexOf('\n') != -1) || (exprStr.indexOf(' = ') != -1 && exprStr.indexOf('==') == -1));
                                var printable = needsWrapIife ? '(fn -> ' + exprStr + ' end).()' : exprStr;
                                result += '#{' + printable + '}';
                            }
                        }
                        
                        result += '"';
                        
                        #if debug_string_interpolation
                        // DISABLED: trace('[StringInterpolation] Transformed to: $result');
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
                    // DISABLED: trace('[StringInterpolation] Found ECase, transforming ${clauses.length} clauses');
                    #end
                    makeASTWithMeta(
                        ECase(
                            transform(expr),
                            clauses.map(clause -> {
                                #if debug_string_interpolation
                                var bodyStr = ElixirASTPrinter.printAST(clause.body);
                                if (bodyStr.indexOf("rgb(") > -1 || bodyStr.indexOf("<>") > -1) {
                                    // DISABLED: trace('[StringInterpolation] Clause body BEFORE transformation: ${bodyStr.substring(0, 200)}');
                                    // DISABLED: trace('[StringInterpolation] Clause body type: ${reflaxe.elixir.util.EnumReflection.enumConstructor(clause.body.def)}');
                                }
                                #end
                                var transformedBody = transform(clause.body);
                                #if debug_string_interpolation
                                var transformedStr = ElixirASTPrinter.printAST(transformedBody);
                                if (bodyStr.indexOf("<>") > -1) {
                                    // DISABLED: trace('[StringInterpolation] Clause body AFTER transformation: ${transformedStr.substring(0, 200)}');
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
        // DISABLED: trace("[LoopTransform] Starting loop transformation pass");
        #end
        
        return transformNode(ast, function(node: ElixirAST): ElixirAST {
            switch(node.def) {
                case ERemoteCall(module, funcName, args):
                    // Check for Enum.reduce_while pattern
                    switch(module.def) {
                        case EVar("Enum"):
                            if (funcName == "reduce_while" && args != null && args.length >= 3) {
                                #if debug_loop_transformation
                                // DISABLED: trace("[LoopTransform] Found Enum.reduce_while call");
                                // DISABLED: trace("[LoopTransform]   Args length: " + args.length);
                                if (args.length >= 3) {
                                    // DISABLED: trace("[LoopTransform]   Third arg (reducer fn) type: " + reflaxe.elixir.util.EnumReflection.enumConstructor(args[2].def));
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
                                                    // DISABLED: trace("[LoopTransform] Found Stream.iterate pattern - WILL ATTEMPT TRANSFORMATION");
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
                                                        // DISABLED: trace("[LoopTransform] Detected simple counter loop");
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
                                                                    // DISABLED: trace("[LoopTransform] Successfully analyzed loop body");
                                                                    // DISABLED: trace("[LoopTransform] Upper bound: " + ElixirASTPrinter.print(loopInfo.upperBound, 0));
                                                                    // DISABLED: trace("[LoopTransform] Has side effects only: " + loopInfo.hasSideEffectsOnly);
                                                                    #end
                                                                    
                                                                    // Transform to idiomatic Elixir
                                                                    if (loopInfo.hasSideEffectsOnly) {
                                                                        // Simple iteration with side effects → Enum.each
                                                                        var range = makeAST(ERange(
                                                                            makeAST(EInteger(0), node.pos),
                                                                            makeAST(EBinary(Subtract, loopInfo.upperBound, makeAST(EInteger(1), node.pos)), node.pos),
                                                                            false, // inclusive range (0..n-1)
                                                                            makeAST(EInteger(1), node.pos)
                                                                        ), node.pos);
                                                                        
                                                                        var eachFunc = makeAST(EFn([{
                                                                            args: [PVar(loopInfo.iteratorVar)],
                                                                            guard: null,
                                                                            body: loopInfo.loopBody
                                                                        }]), node.pos);
                                                                        
                                                                        #if debug_loop_transformation
                                                                        // DISABLED: trace("[LoopTransform] Transforming to Enum.each");
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
                    // Look for pipeline patterns in blocks and collapse them in-place.
                    // IMPORTANT: Preserve all non-pipeline expressions in the block.
                    var optimizedExpressions = detectAndOptimizePipeline(expressions);
                    optimizedExpressions != null
                        ? makeASTWithMeta(EBlock(optimizedExpressions), node.metadata, node.pos)
                        : node;
                    
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
        // DISABLED: trace('[XRay AbstractThis] Starting pass');
        #end
        
        // Add debug to see what nodes we're actually getting
        #if debug_abstract_this
        function debugNode(node: ElixirAST, depth: Int = 0) {
            var indent = [for (i in 0...depth) "  "].join("");
            switch(node.def) {
                case EModule(name, _, body):
                    // DISABLED: trace('$indent[XRay AbstractThis] Module: $name with ${body.length} definitions');
                    for (def in body) debugNode(def, depth + 1);
                case EDef(name, _, _, body):
                    // DISABLED: trace('$indent[XRay AbstractThis] Def: $name');
                    debugNode(body, depth + 1);
                case EFn(clauses):
                    // DISABLED: trace('$indent[XRay AbstractThis] !! Found EFn with ${clauses.length} clauses !!');
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
                    // DISABLED: trace('[XRay AbstractThis] Processing EFn with ${clauses.length} clauses');
                    #end
                    // Check if this is an abstract method with "this" parameter
                    var fixedClauses = [];
                    var hasChanges = false;
                    
                    for (clause in clauses) {
                        if (clause.args.length > 0) {
                            switch(clause.args[0]) {
                                case PVar(paramName) if (paramName.indexOf("this") == 0 || paramName == "_struct" || paramName == "struct"):
                                    #if debug_abstract_this
                                    // DISABLED: trace('[XRay AbstractThis] Found function with this/struct parameter: $paramName');
                                    // DISABLED: trace('[XRay AbstractThis] Body before fix: ${ElixirASTPrinter.print(clause.body, 0)}');
                                    #end
                                    
                                    // Found a "this", "this_1", "struct", or "_struct" parameter
                                    // Replace "struct" or "this" with the actual parameter name in body
                                    var fixedBody = replaceStructWithParam(clause.body, paramName);
                                    
                                    #if debug_abstract_this
                                    // DISABLED: trace('[XRay AbstractThis] Body after fix: ${ElixirASTPrinter.print(fixedBody, 0)}');
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
                        // DISABLED: trace('[XRay AbstractThis] Applied fix to function');
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
        // DISABLED: trace('[XRay ListEffectLifting] Starting pass');
        #end
        
        return transformNode(ast, function(node: ElixirAST): ElixirAST {
            switch(node.def) {
                case EList(elements):
                    #if debug_effect_lifting
                    // DISABLED: trace('[XRay ListEffectLifting] Processing list with ${elements.length} elements');
                    #end
                    
                    // Check if any element has side effects
                    var hasEffects = false;
                    var liftedStatements: Array<ElixirAST> = [];
                    var pureElements: Array<ElixirAST> = [];
                    
                    for (i in 0...elements.length) {
                        var elem = elements[i];
                        #if debug_effect_lifting
                        // DISABLED: trace('[XRay ListEffectLifting] Checking element $i: ${ElixirASTPrinter.print(elem, 0).substring(0, 50)}');
                        #end
                        
                        switch(elem.def) {
                            case EMatch(left, right):
                                // Assignment inside list - needs lifting
                                #if debug_effect_lifting
                                // DISABLED: trace('[XRay ListEffectLifting] Found assignment in element $i');
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
                                // DISABLED: trace('[XRay ListEffectLifting] Found block in element $i with ${exprs.length} expressions');
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
                                            // DISABLED: trace('[XRay ListEffectLifting] Found nested list with effects');
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
                        // DISABLED: trace('[XRay ListEffectLifting] Lifting ${liftedStatements.length} statements');
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
                                                // DISABLED: trace('[XRay StructFieldAssignment] Found field assignment pattern: $fieldName = ...');
                                                // DISABLED: trace('[XRay StructFieldAssignment] Transforming to Map.put($varName, :$fieldName, ...)');
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
            // DISABLED: trace('[XRay StatementContext] Processing node: ${node.def}, context: ${isStatementContext ? "statement" : "expression"}');
            #end

            // First, recursively transform children with appropriate context
            var transformed = switch(node.def) {
                case EDefmodule(name, doBlock):
                    // Process the module's do block in statement context
                    #if debug_ast_transformer
                    // DISABLED: trace('[XRay StatementContext] Processing EDefmodule: $name');
                    #end
                    makeASTWithMeta(
                        EDefmodule(name, transformWithContext(doBlock, true)),
                        node.metadata, node.pos
                    );
                    
                case EBlock(expressions):
                    // In a block, all but the last expression are in statement context
                    #if debug_ast_transformer
                    // DISABLED: trace('[XRay StatementContext] Processing EBlock with ${expressions.length} expressions');
                    #end
                    var newExpressions = [];
                    for (i in 0...expressions.length) {
                        var isLast = (i == expressions.length - 1);
                        var childContext = isLast ? isStatementContext : true;
                        #if debug_ast_transformer
                        if (expressions[i] != null && expressions[i].def != null) {
                            var exprType = reflaxe.elixir.util.EnumReflection.enumConstructor(expressions[i].def);
                            // DISABLED: trace('[XRay StatementContext] Block expr $i/${expressions.length}: $exprType, context: ${childContext ? "statement" : "expression"}');
                        }
                        #end
                        newExpressions.push(transformWithContext(expressions[i], childContext));
                    }
                    makeASTWithMeta(EBlock(newExpressions), node.metadata, node.pos);

                case EDo(expressions):
                    // EDo behaves like a block for statement/expression context purposes.
                    var newExpressions = [];
                    for (i in 0...expressions.length) {
                        var isLast = (i == expressions.length - 1);
                        var childContext = isLast ? isStatementContext : true;
                        newExpressions.push(transformWithContext(expressions[i], childContext));
                    }
                    makeASTWithMeta(EDo(newExpressions), node.metadata, node.pos);
                    
                case EDef(name, args, guards, body):
                    // Function body is a block - let it handle its own statement/expression context
                    // The block will mark all but the last expression as statement context
                    #if debug_ast_transformer
                    // DISABLED: trace('[XRay StatementContext] Processing EDef: $name, body type: ${body.def}');
                    #end
                    makeASTWithMeta(
                        EDef(name, args, guards, transformWithContext(body, false)),
                        node.metadata, node.pos
                    );
                    
                case EDefp(name, args, guards, body):
                    // Function body is a block - let it handle its own statement/expression context  
                    // The block will mark all but the last expression as statement context
                    #if debug_ast_transformer
                    // DISABLED: trace('[XRay StatementContext] Processing EDefp: $name, body type: ${body.def}');
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

                case ECond(clauses):
                    makeASTWithMeta(
                        ECond(clauses.map(c -> {
                            condition: transformWithContext(c.condition, false),
                            body: transformWithContext(c.body, isStatementContext)
                        })),
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

                case EWith(clauses, doBlock, elseBlock):
                    makeASTWithMeta(
                        EWith(
                            clauses.map(c -> { pattern: c.pattern, expr: transformWithContext(c.expr, false) }),
                            transformWithContext(doBlock, isStatementContext),
                            elseBlock != null ? transformWithContext(elseBlock, isStatementContext) : null
                        ),
                        node.metadata, node.pos
                    );

                case ETry(body, rescueClauses, catchClauses, afterBlock, elseBlock):
                    makeASTWithMeta(
                        ETry(
                            transformWithContext(body, isStatementContext),
                            rescueClauses != null ? rescueClauses.map(r -> { pattern: r.pattern, varName: r.varName, body: transformWithContext(r.body, isStatementContext) }) : [],
                            catchClauses != null ? catchClauses.map(c -> { kind: c.kind, pattern: c.pattern, body: transformWithContext(c.body, isStatementContext) }) : [],
                            afterBlock != null ? transformWithContext(afterBlock, true) : null,
                            elseBlock != null ? transformWithContext(elseBlock, isStatementContext) : null
                        ),
                        node.metadata, node.pos
                    );

                case EParen(inner):
                    makeASTWithMeta(EParen(transformWithContext(inner, isStatementContext)), node.metadata, node.pos);

                case EFn(clauses):
                    // Anonymous functions have their own block context; treat clause bodies like def bodies.
                    makeASTWithMeta(
                        EFn(clauses.map(cl -> {
                            args: cl.args,
                            guard: cl.guard != null ? transformWithContext(cl.guard, false) : null,
                            body: transformWithContext(cl.body, false)
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
                inline function remoteCallNeedsRebind(module: ElixirAST, funcName: String): Bool {
                    var moduleName: Null<String> = switch(module.def) {
                        case EAtom(atom): atom; // ElixirAtom implicitly converts to String
                        case EVar(name): name;  // name is already String
                        default: null;
                    };

                    if (moduleName == null) return false;

                    return switch(moduleName) {
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
                        case "Bytes":
                            // Haxe Bytes API is mutable, but Elixir binaries are immutable; our Bytes module
                            // returns updated structs from mutating operations. In statement position, ensure
                            // the first argument is rebound so mutations persist.
                            funcName == "set" || funcName == "blit" || funcName == "fill" || funcName.startsWith("set_");
                        default:
                            false;
                    };
                }

                inline function isInfraDiscardVar(name: String): Bool {
                    if (name == null) return false;
                    if (name == "g" || name == "_g") return true;
                    return ~/^_?g[0-9]+$/.match(name);
                }

                switch(transformed.def) {
                    case ERemoteCall(module, funcName, args):
                        #if debug_ast_transformer
                        // DISABLED: trace('[XRay StatementContext] Checking ERemoteCall: module=${module.def}, func=$funcName, args=${args.length}');
                        #end
                        if (remoteCallNeedsRebind(module, funcName) && args.length >= 1) {
                            // First arg should be the variable being modified
                            switch(args[0].def) {
                                case EVar(varName):
                                    // Transform to: varName = Module.operation(varName, ...)
                                    return makeASTWithMeta(
                                        EMatch(PVar(varName), transformed),
                                        node.metadata, node.pos
                                    );
                                default:
                                    // Not a simple variable, can't reassign
                            }
                        }

                    case ECall(target, funcName, args) if (target != null):
                        if (remoteCallNeedsRebind(target, funcName) && args.length >= 1) {
                            switch (args[0].def) {
                                case EVar(varName):
                                    return makeASTWithMeta(
                                        EMatch(PVar(varName), transformed),
                                        node.metadata, node.pos
                                    );
                                default:
                            }
                        }

                    // Discard binder form: `_ = Module.op(var, ...)` should still rebind the var.
                    case EMatch(pattern, expr):
                        var isDiscard = switch (pattern) {
                            case PWildcard: true;
                            case PVar("_"): true;
                            default: false;
                        };
                        if (isDiscard) {
                            switch (expr.def) {
                                case ERemoteCall(module, funcName, args) if (args != null && args.length >= 1 && remoteCallNeedsRebind(module, funcName)):
                                    switch (args[0].def) {
                                        case EVar(varName):
                                            return makeASTWithMeta(EMatch(PVar(varName), expr), node.metadata, node.pos);
                                        default:
                                    }
                                case ECall(target, funcName, args) if (target != null && args != null && args.length >= 1 && remoteCallNeedsRebind(target, funcName)):
                                    switch (args[0].def) {
                                        case EVar(varName):
                                            return makeASTWithMeta(EMatch(PVar(varName), expr), node.metadata, node.pos);
                                        default:
                                    }
                                default:
                            }
                        }

                    case EBinary(Match, left, right):
                        var isDiscard = switch (left.def) {
                            case EVar(name) if (name == "_" || isInfraDiscardVar(name)): true;
                            default: false;
                        };
                        if (isDiscard) {
                            switch (right.def) {
                                case ERemoteCall(module, funcName, args) if (args != null && args.length >= 1 && remoteCallNeedsRebind(module, funcName)):
                                    switch (args[0].def) {
                                        case EVar(varName):
                                            return makeASTWithMeta(EMatch(PVar(varName), right), node.metadata, node.pos);
                                        default:
                                    }
                                case ECall(target, funcName, args) if (target != null && args != null && args.length >= 1 && remoteCallNeedsRebind(target, funcName)):
                                    switch (args[0].def) {
                                        case EVar(varName):
                                            return makeASTWithMeta(EMatch(PVar(varName), right), node.metadata, node.pos);
                                        default:
                                    }
                                default:
                            }
                        }
                        
                    case EBinary(Concat, left, right):
                        // Check for list concatenation in statement context
                        switch(left.def) {
                            case EVar(varName):
                                #if debug_ast_transformer
                                // DISABLED: trace('[XRay StatementContext] Wrapping ++ with reassignment to: $varName');
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
                    // DISABLED: trace('[XRay ImmutabilityTransform] Found method $name with struct parameter');
                    #end
                    var updatedBody = transformStructFieldAssignments(body, args);
                    if (updatedBody != body) {
                        #if debug_ast_transformer
                        // DISABLED: trace('[XRay ImmutabilityTransform] Transformed body for method $name');
                        #end
                        makeASTWithMeta(
                            EDef(name, args, guards, updatedBody),
                            node.metadata,
                            node.pos
                        );
                    } else {
                        #if debug_ast_transformer
                        // DISABLED: trace('[XRay ImmutabilityTransform] No transformation needed for method $name');
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
                                        // DISABLED: trace('[XRay ImmutabilityTransform] Skipping array variable field: struct.$fieldName');
                                        #end
                                        // Regular array concatenation
                                        makeAST(EBinary(Concat, target, makeAST(EList([item]))));
                                    } else {
                                        // Transform to struct update: %{struct | field: struct.field ++ [item]}
                                        #if debug_ast_transformer
                                        // DISABLED: trace('[XRay ImmutabilityTransform] Transforming struct.$fieldName.push(item) to struct update');
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
                                // DISABLED: trace('[XRay ImmutabilityTransform] Skipping array variable: $fieldName');
                                #end
                                // Regular array concatenation, not struct update
                                makeAST(EBinary(Concat, target, makeAST(EList([item]))));
                            } else {
                                // We need to transform this to a struct update
                                #if debug_ast_transformer
                                // DISABLED: trace('[XRay ImmutabilityTransform] Transforming $fieldName.push(item) to struct update');
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
        // DISABLED: trace('[XRay transformStructFieldAssignments] Analyzing body for field assignments');
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
                    // DISABLED: trace('[XRay transformStructFieldAssignments] Found root assignment');
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
        // DISABLED: trace('[XRay transformStructFieldAssignments] hasFieldAssignment: $hasFieldAssignment, has root: ${fieldUpdates.exists("root")}');
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
        // DISABLED: trace("[FluentApiOptimization] Starting optimization pass");
        #end

        return transformNode(ast, function(node) {
            switch(node.def) {
                case EDef(name, args, guards, body):
                    var optimizedBody = optimizeFluentBody(body);
                    if (optimizedBody != body) {
                        #if debug_fluent_api
                        // DISABLED: trace('[FluentApiOptimization] Optimized function: $name');
                        #end
                        return makeASTWithMeta(EDef(name, args, guards, optimizedBody), node.metadata, node.pos);
                    }
                case EDefp(name, args, guards, body):
                    var optimizedBody = optimizeFluentBody(body);
                    if (optimizedBody != body) {
                        #if debug_fluent_api
                        // DISABLED: trace('[FluentApiOptimization] Optimized private function: $name');
                        #end
                        return makeASTWithMeta(EDefp(name, args, guards, optimizedBody), node.metadata, node.pos);
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
                                // DISABLED: trace('[FluentApiOptimization] Found fluent pattern - optimizing');
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
        // DISABLED: trace('[XRay ArrayLengthField] Starting array length field to function transformation');
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
                // DISABLED: trace('[XRay ArrayLengthField] Transforming ${targetStr}.length to length($targetStr)');
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
    // Large budget so normal multi-pass pipelines don't false-positive.
    private static var maxNodeVisits: Int = 500000;
    #if hxx_ast_progress
    private static var transformInvocationCounter: Int = 0;
    #end
    #if debug_transformer_hang
    private static var currentPassName: String = "";
    #end

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

    /**
     * transformNode
     *
     * WHAT
     * - Recursively traverses and rebuilds the Elixir AST while applying a node-local transformer.
     * - Includes full recursion into EDo (do/end) bodies to ensure inner statements participate in passes.
     *
     * WHY
     * - Several shape-based passes (e.g., filter query consolidation) must operate on statements
     *   placed inside if/with/do blocks. Missing recursion into EDo caused late guards to miss
     *   legitimate targets, producing undefined variable issues.
     *
     * HOW
     * - Mirrors EBlock recursion for EDo: transforms each expression, then rebuilds the enclosing node.
     * - All other nodes retain prior recursion semantics; ERaw remains non-transformable by design.
     *
     * EXAMPLES
     * Before (no EDo recursion):
     *   if cond do
     *     Enum.filter(list, fn t -> uses_query end)
     *   end
     *   # Passes did not see the inner filter call.
     *
     * After (with EDo recursion):
     *   Same input; passes visit and may promote/bind/inline query deterministically.
     */
    public static function transformNode(ast: ElixirAST, transformer: (ElixirAST) -> ElixirAST): ElixirAST {
        // Handle null AST nodes or nodes with null def
        if (ast == null || ast.def == null) {
            return ast;  // Return as-is if null
        }

        #if debug_transformer_hang
        nodeVisitCounter++;

        // Create a unique identifier for this node
        var nodeId = reflaxe.elixir.util.EnumReflection.enumConstructor(ast.def) + "_" + Std.string(ast.pos);

        // Track visit frequency
        var visits = visitedNodes.get(nodeId);
        if (visits == null) visits = 0;
        visits++;
        visitedNodes.set(nodeId, visits);

        // Log breadcrumbs
        if (nodeVisitCounter % 1000 == 0) {
            // DISABLED: trace('[TRANSFORMER BREADCRUMB] Node ${nodeVisitCounter}: ${reflaxe.elixir.util.EnumReflection.enumConstructor(ast.def)}');
        }

        // Detect excessive visits to same node (cycle)
        if (visits > 1000) {
            // DISABLED: trace('[CYCLE DETECTED] Node ${nodeId} visited ${visits} times!');
            // DISABLED: trace('[CYCLE DETECTED] AST def: ${ast.def}');
            #if debug_transformer_hang
            // DISABLED: trace('[CYCLE DETECTED] Current pass: ' + currentPassName);
            #end
            throw 'Infinite recursion detected in transformer: ${nodeId}';
        }

        // Overall safety limit
        if (nodeVisitCounter > maxNodeVisits) {
            // DISABLED: trace('[TRANSFORMER HANG] Exceeded ${maxNodeVisits} node visits');
            // DISABLED: trace('[TRANSFORMER HANG] Last node: ${reflaxe.elixir.util.EnumReflection.enumConstructor(ast.def)}');
            throw 'Transformer exceeded maximum node visit limit';
        }
        #end

        // First transform children
        var transformed = switch(ast.def) {
            case EModule(name, attributes, body):
                var bodyResult = transformArray(body, transformer);
                var attrChanged = false;
                var newAttributes: Array<EAttribute> = attributes;
                if (attributes != null) {
                    var outAttrs: Array<EAttribute> = [];
                    for (a in attributes) {
                        var newVal = transformNode(a.value, transformer);
                        if (newVal != a.value) attrChanged = true;
                        outAttrs.push({name: a.name, value: newVal});
                    }
                    if (attrChanged) newAttributes = outAttrs;
                }
                if (bodyResult.changed || attrChanged) {
                    makeASTWithMeta(
                        EModule(name, newAttributes, bodyResult.array),
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

            case EDefmacro(name, args, guards, body):
                makeASTWithMeta(
                    EDefmacro(name, args,
                        guards != null ? transformNode(guards, transformer) : null,
                        transformNode(body, transformer)
                    ),
                    ast.metadata,
                    ast.pos
                );

            case EDefmacrop(name, args, guards, body):
                makeASTWithMeta(
                    EDefmacrop(name, args,
                        guards != null ? transformNode(guards, transformer) : null,
                        transformNode(body, transformer)
                    ),
                    ast.metadata,
                    ast.pos
                );
                
            // Blocks
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

            // Transform do-end blocks by visiting each expression
            case EDo(body):
                var doResult = transformArray(body, transformer);
                if (doResult.changed) {
                    makeASTWithMeta(
                        EDo(doResult.array),
                        ast.metadata,
                        ast.pos
                    );
                } else {
                    ast;
                }
                
            case EIf(condition, thenBranch, elseBranch):
                makeASTWithMeta(
                    EIf(transformNode(condition, transformer),
                        transformNode(thenBranch, transformer),
                        elseBranch != null ? transformNode(elseBranch, transformer) : null),
                    ast.metadata,
                    ast.pos
                );

            case EUnless(condition, body, elseBranch):
                makeASTWithMeta(
                    EUnless(
                        transformNode(condition, transformer),
                        transformNode(body, transformer),
                        elseBranch != null ? transformNode(elseBranch, transformer) : null
                    ),
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

            case ECond(clauses):
                makeASTWithMeta(
                    ECond(clauses.map(c -> {
                        condition: transformNode(c.condition, transformer),
                        body: transformNode(c.body, transformer)
                    })),
                    ast.metadata,
                    ast.pos
                );

            case EWith(clauses, doBlock, elseBlock):
                makeASTWithMeta(
                    EWith(
                        clauses.map(c -> { pattern: c.pattern, expr: transformNode(c.expr, transformer) }),
                        transformNode(doBlock, transformer),
                        elseBlock != null ? transformNode(elseBlock, transformer) : null
                    ),
                    ast.metadata,
                    ast.pos
                );

            case ETry(body, rescueClauses, catchClauses, afterBlock, elseBlock):
                makeASTWithMeta(
                    ETry(
                        transformNode(body, transformer),
                        rescueClauses != null ? rescueClauses.map(r -> { pattern: r.pattern, varName: r.varName, body: transformNode(r.body, transformer) }) : [],
                        catchClauses != null ? catchClauses.map(c -> { kind: c.kind, pattern: c.pattern, body: transformNode(c.body, transformer) }) : [],
                        afterBlock != null ? transformNode(afterBlock, transformer) : null,
                        elseBlock != null ? transformNode(elseBlock, transformer) : null
                    ),
                    ast.metadata,
                    ast.pos
                );

            case ERaise(exception, attributes):
                makeASTWithMeta(
                    ERaise(
                        transformNode(exception, transformer),
                        attributes != null ? transformNode(attributes, transformer) : null
                    ),
                    ast.metadata,
                    ast.pos
                );

            case EThrow(value):
                makeASTWithMeta(
                    EThrow(transformNode(value, transformer)),
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

            case EParen(expr):
                makeASTWithMeta(
                    EParen(transformNode(expr, transformer)),
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

            case EMacroCall(macroName, args, doBlock):
                makeASTWithMeta(
                    EMacroCall(
                        macroName,
                        args.map(a -> transformNode(a, transformer)),
                        transformNode(doBlock, transformer)
                    ),
                    ast.metadata,
                    ast.pos
                );

            case ERemoteCall(module, funcName, args):
                makeASTWithMeta(
                    ERemoteCall(
                        transformNode(module, transformer),
                        funcName,
                        args.map(a -> transformNode(a, transformer))
                    ),
                    ast.metadata,
                    ast.pos
                );

            case EPipe(left, right):
                makeASTWithMeta(
                    EPipe(transformNode(left, transformer), transformNode(right, transformer)),
                    ast.metadata,
                    ast.pos
                );

            case EField(target, field):
                makeASTWithMeta(
                    EField(transformNode(target, transformer), field),
                    ast.metadata,
                    ast.pos
                );

            case EAccess(target, key):
                makeASTWithMeta(
                    EAccess(transformNode(target, transformer), transformNode(key, transformer)),
                    ast.metadata,
                    ast.pos
                );

            case ERange(start, end, exclusive, step):
                makeASTWithMeta(
                    ERange(
                        transformNode(start, transformer),
                        transformNode(end, transformer),
                        exclusive,
                        step != null ? transformNode(step, transformer) : null
                    ),
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

            case EStruct(module, fields):
                makeASTWithMeta(
                    EStruct(module, fields.map(f -> { key: f.key, value: transformNode(f.value, transformer) })),
                    ast.metadata,
                    ast.pos
                );

            case EStructUpdate(struct, fields):
                makeASTWithMeta(
                    EStructUpdate(transformNode(struct, transformer), fields.map(f -> { key: f.key, value: transformNode(f.value, transformer) })),
                    ast.metadata,
                    ast.pos
                );

            case EKeywordList(pairs):
                makeASTWithMeta(
                    EKeywordList(pairs.map(p -> { key: p.key, value: transformNode(p.value, transformer) })),
                    ast.metadata,
                    ast.pos
                );

            case EBitstring(segments):
                makeASTWithMeta(
                    EBitstring(segments.map(s -> {
                        value: transformNode(s.value, transformer),
                        size: s.size != null ? transformNode(s.size, transformer) : null,
                        type: s.type,
                        modifiers: s.modifiers
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

            case EPin(expr):
                makeASTWithMeta(
                    EPin(transformNode(expr, transformer)),
                    ast.metadata,
                    ast.pos
                );

            case ECapture(expr, arity):
                makeASTWithMeta(
                    ECapture(transformNode(expr, transformer), arity),
                    ast.metadata,
                    ast.pos
                );

            case EUse(module, options):
                makeASTWithMeta(
                    EUse(module, options != null ? options.map(o -> transformNode(o, transformer)) : []),
                    ast.metadata,
                    ast.pos
                );

            case EModuleAttribute(name, value):
                makeASTWithMeta(
                    EModuleAttribute(name, transformNode(value, transformer)),
                    ast.metadata,
                    ast.pos
                );

            case EQuote(options, expr):
                makeASTWithMeta(
                    EQuote(options != null ? options.map(o -> transformNode(o, transformer)) : [], transformNode(expr, transformer)),
                    ast.metadata,
                    ast.pos
                );

            case EUnquote(expr):
                makeASTWithMeta(
                    EUnquote(transformNode(expr, transformer)),
                    ast.metadata,
                    ast.pos
                );

            case EUnquoteSplicing(expr):
                makeASTWithMeta(
                    EUnquoteSplicing(transformNode(expr, transformer)),
                    ast.metadata,
                    ast.pos
                );

            case EReceive(clauses, after):
                makeASTWithMeta(
                    EReceive(
                        clauses.map(c -> {
                            pattern: c.pattern,
                            guard: c.guard != null ? transformNode(c.guard, transformer) : null,
                            body: transformNode(c.body, transformer)
                        }),
                        after != null ? {
                            timeout: transformNode(after.timeout, transformer),
                            body: transformNode(after.body, transformer)
                        } : null
                    ),
                    ast.metadata,
                    ast.pos
                );

            case ESend(target, message):
                makeASTWithMeta(
                    ESend(transformNode(target, transformer), transformNode(message, transformer)),
                    ast.metadata,
                    ast.pos
                );

            case EFragment(tag, attributes, children):
                makeASTWithMeta(
                    EFragment(
                        tag,
                        attributes != null ? attributes.map(a -> { name: a.name, value: transformNode(a.value, transformer) }) : [],
                        children != null ? children.map(c -> transformNode(c, transformer)) : []
                    ),
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
    static function detectAndOptimizePipeline(expressions: Array<ElixirAST>): Null<Array<ElixirAST>> {
        // Collapse contiguous patterns like:
        //   x = f(x, ...)
        //   x = g(x, ...)
        // into:
        //   x = x |> f(...) |> g(...)
        //
        // IMPORTANT: This runs on EBlock nodes and MUST preserve any non-pipeline
        // expressions before/after the collapsed segment. Dropping them can erase
        // required bindings and side effects (e.g., broadcasts, initial bindings).

        if (expressions.length < 2) return null;

        var didChange = false;
        var optimizedExpressions: Array<ElixirAST> = [];

        function parsePipelineAssign(expr: ElixirAST): Null<{ varName: String, func: String, args: Array<ElixirAST>, target: Null<ElixirAST> }> {
            return switch (expr.def) {
                case EMatch(PVar(varName), call):
                    switch (call.def) {
                        case ECall(target, func, args):
                            (args.length > 0 && switch (args[0].def) { case EVar(argName): argName == varName; default: false; })
                                ? { varName: varName, func: func, args: args.slice(1), target: target }
                                : null;
                        case ERemoteCall(module, func, args):
                            (args.length > 0 && switch (args[0].def) { case EVar(argName): argName == varName; default: false; })
                                ? { varName: varName, func: func, args: args.slice(1), target: module }
                                : null;
                        default:
                            null;
                    }
                default:
                    null;
            };
        }

        function buildPipelineAssign(baseVar: String, ops: Array<{ func: String, args: Array<ElixirAST>, target: Null<ElixirAST> }>, metaFrom: ElixirAST): ElixirAST {
            var pipeline = makeAST(EVar(baseVar));
            for (op in ops) {
                pipeline = makeAST(EPipe(
                    pipeline,
                    op.target != null
                        ? makeAST(ERemoteCall(op.target, op.func, op.args))
                        : makeAST(ECall(null, op.func, op.args))
                ));
            }
            return makeASTWithMeta(EMatch(PVar(baseVar), pipeline), metaFrom.metadata, metaFrom.pos);
        }

        var index = 0;
        while (index < expressions.length) {
            var expr = expressions[index];

            var first = parsePipelineAssign(expr);
            if (first == null) {
                optimizedExpressions.push(expr);
                index++;
                continue;
            }

            var baseVar = first.varName;
            var ops: Array<{ func: String, args: Array<ElixirAST>, target: Null<ElixirAST> }> = [
                { func: first.func, args: first.args, target: first.target }
            ];

            var scanIndex = index + 1;
            var lastExprInChain = expr;
            while (scanIndex < expressions.length) {
                var next = parsePipelineAssign(expressions[scanIndex]);
                if (next == null || next.varName != baseVar) break;
                ops.push({ func: next.func, args: next.args, target: next.target });
                lastExprInChain = expressions[scanIndex];
                scanIndex++;
            }

            if (ops.length >= 2) {
                didChange = true;
                optimizedExpressions.push(buildPipelineAssign(baseVar, ops, lastExprInChain));
                index = scanIndex;
            } else {
                optimizedExpressions.push(expr);
                index++;
            }
        }

        return didChange ? optimizedExpressions : null;
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
                    // DISABLED: trace('[XRay RemoveRedundantNilInit] Processing _new function');
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
                                                                    // DISABLED: trace('[XRay RemoveRedundantNilInit] Removing this1 = nil in _new function');
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
                    // DISABLED: trace('[XRay RemoveRedundantNilInit] Processing EBlock with ${expressions.length} expressions');
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
                                    // DISABLED: trace('[XRay RemoveRedundantNilInit] Found nil assignment for var: $varName at index $i');
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
                                // DISABLED: trace('[XRay RemoveRedundantNilInit] Removing standalone variable reference: $v');
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
                                        // DISABLED: trace('[XRay RemoveRedundantNilInit] Found "this1" nil assignment at index $i');
                                        #end
                                        // Check immediate next expression for reassignment
                                        if (i + 1 < expressions.length) {
                                            var nextExpr = expressions[i + 1];
                                            if (nextExpr != null && nextExpr.def != null) {
                                                #if debug_ast_transformer
                                                // DISABLED: trace('[XRay RemoveRedundantNilInit] Next expr at ${i+1}: ${nextExpr.def}');
                                                #end
                                                switch(nextExpr.def) {
                                                case EMatch(PVar(nextVarName), value) if (nextVarName == varName):
                                                    if (isNilValue(value)) {
                                                        // Don't skip if it's another nil
                                                        #if debug_ast_transformer
                                                        // DISABLED: trace('[XRay RemoveRedundantNilInit] Next assignment is also nil, not skipping');
                                                        #end
                                                    } else {
                                                        // Non-nil reassignment - skip the initial nil AND check if there's a useless variable reference after
                                                        #if debug_ast_transformer
                                                        // DISABLED: trace('[XRay RemoveRedundantNilInit] REMOVING redundant nil init for abstract constructor var: $varName');
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
                                                                        // DISABLED: trace('[XRay RemoveRedundantNilInit] Found standalone variable reference after assignment, marking for removal');
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
                                                        // DISABLED: trace('[XRay RemoveRedundantNilInit] Next expr is not a match for $varName');
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
                                                                // DISABLED: trace('[XRay RemoveRedundantNilInit] Removing redundant nil init for: $varName (reassigned at index $j)');
                                                                #end
                                                                shouldSkip = true;
                                                                break;
                                                        }
                                                    default:
                                                }
                                                j++;
	                                            }
	                                        }
	                                    } else {
	                                        // Generic redundant-nil elimination for ordinary locals.
	                                        //
	                                        // WHY
	                                        // - Haxe often emits uninitialized locals as `var x;` which we lower to
	                                        //   `x = nil` followed by a dominating `x = <value>` assignment.
	                                        // - In Elixir this triggers WAE: the initial binding is overwritten before use.
	                                        //
	                                        // HOW
	                                        // - If we see `x = nil` and, before any read of `x`, we see a later *top-level*
	                                        //   reassignment `x = <non-nil>`, we can drop the initial nil bind.
	                                        // - We stay conservative: any read of `x` before the reassignment keeps the init.
	                                        var j = i + 1;
	                                        while (j < expressions.length) {
	                                            var checkExpr = expressions[j];
	                                            if (checkExpr == null || checkExpr.def == null) {
	                                                j++;
	                                                continue;
	                                            }

	                                            // Stop when we see a reassignment to the same variable.
	                                            var reassigned: Null<ElixirAST> = null;
	                                            switch (checkExpr.def) {
	                                                case EMatch(PVar(nextVarName), value) if (nextVarName == varName):
	                                                    reassigned = value;
	                                                case EBinary(Match, leftAst, valueAst):
	                                                    reassigned = switch (leftAst.def) {
	                                                        case EVar(nextVarName) if (nextVarName == varName): valueAst;
	                                                        default: null;
	                                                    };
	                                                default:
	                                            }

	                                            if (reassigned != null) {
	                                                if (!isNilValue(reassigned)) {
	                                                    // Only remove the nil init when the reassignment does not depend
	                                                    // on the prior binding (e.g., `x = if cond, do: v, else: x`).
	                                                    if (!reflaxe.elixir.ast.analyzers.VariableUsageCollector.usedInFunctionScope(reassigned, varName)) {
	                                                        shouldSkip = true;
	                                                    }
	                                                }
	                                                break;
	                                            }

	                                            // Any read of the variable before reassignment means the nil init is meaningful.
	                                            if (reflaxe.elixir.ast.analyzers.VariableUsageCollector.usedInFunctionScope(checkExpr, varName)) {
	                                                break;
	                                            }

	                                            j++;
	                                        }
	                                    }
	                                }
                            default:
                                // Not a match expression
                        }

                        if (!shouldSkip) {
                            // Children are already transformed by transformNode; do not recurse here.
                            filtered.push(expr);
                        } else {
                            #if debug_ast_transformer
                            // DISABLED: trace('[XRay RemoveRedundantNilInit] Skipping redundant nil init at index $i');
                            #end
                        }
                        i++;
                    }

                    // Only create new block if we removed something
                    if (filtered.length != expressions.length) {
                        #if debug_ast_transformer
                        // DISABLED: trace('[XRay RemoveRedundantNilInit] Removed ${expressions.length - filtered.length} redundant nil assignments from block');
                        #end
                        return makeASTWithMeta(EBlock(filtered), node.metadata, node.pos);
                    } else {
                        return node;
                    }
                    
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
        // DISABLED: trace('[XRay PrefixUnusedParams] PASS START');
        #end
        
        return transformNode(ast, function(node: ElixirAST): ElixirAST {
            switch(node.def) {
                // Handle regular function definitions
                case EDef(name, args, guards, body):
                    #if debug_ast_transformer
                    // DISABLED: trace('[XRay PrefixUnusedParams] Found EDef: $name with ${args.length} args');
                    #end
                    var result = handleFunctionParameters(args, guards, body);
                    if (result.hasChanges) {
                        #if debug_ast_transformer
                        // DISABLED: trace('[XRay PrefixUnusedParams] Updated EDef: $name');
                        #end
                        return makeASTWithMeta(EDef(name, result.args, guards, result.body), node.metadata, node.pos);
                    }
                    return node;
                    
                case EDefp(name, args, guards, body):
                    var result = handleFunctionParameters(args, guards, body);
                    if (result.hasChanges) {
                        #if debug_ast_transformer
                        // DISABLED: trace('[XRay PrefixUnusedParams] Updated EDefp: $name');
                        #end
                        return makeASTWithMeta(EDefp(name, result.args, guards, result.body), node.metadata, node.pos);
                    }
                    return node;
                    
                case EDefmacro(name, args, guards, body):
                    var result = handleFunctionParameters(args, guards, body);
                    if (result.hasChanges) {
                        #if debug_ast_transformer
                        // DISABLED: trace('[XRay PrefixUnusedParams] Updated EDefmacro: $name');
                        #end
                        return makeASTWithMeta(EDefmacro(name, result.args, guards, result.body), node.metadata, node.pos);
                    }
                    return node;
                    
                case EDefmacrop(name, args, guards, body):
                    var result = handleFunctionParameters(args, guards, body);
                    if (result.hasChanges) {
                        #if debug_ast_transformer
                        // DISABLED: trace('[XRay PrefixUnusedParams] Updated EDefmacrop: $name');
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
                        // DISABLED: trace('[XRay PrefixUnusedParams] Updated EFn with ${clauses.length} clauses');
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

	        inline function isPreservedParamName(name: String): Bool {
	            // Phoenix HEEx (~H) requires a variable literally named `assigns` in scope.
	            // We preserve `assigns`/`_assigns` so later HEEx passes can materialize ~H safely.
	            return name == "assigns" || name == "_assigns";
	        }
	        
	        function markUsedNamesInTemplateString(template: String): Void {
	            if (template == null || template.length == 0) return;
	            if (template.indexOf("<%") == -1 && template.indexOf("{") == -1) return;
	
	            inline function markUsedFromElixirCode(code: String): Void {
	                if (code == null || code.length == 0) return;
	                inline function isIdentChar(c: String): Bool {
	                    if (c == null || c.length == 0) return false;
	                    var ch = c.charCodeAt(0);
	                    return (ch >= 48 && ch <= 57) || (ch >= 65 && ch <= 90) || (ch >= 97 && ch <= 122) || c == "_";
	                }
	                function codeUsesName(codeStr: String, varName: String): Bool {
	                    var start = 0;
	                    while (codeStr != null) {
	                        var pos = codeStr.indexOf(varName, start);
	                        if (pos == -1) break;
	                        var before = pos > 0 ? codeStr.substr(pos - 1, 1) : null;
	                        var afterIdx = pos + varName.length;
	                        var after = afterIdx < codeStr.length ? codeStr.substr(afterIdx, 1) : null;
	                        if (!isIdentChar(before) && !isIdentChar(after)) return true;
	                        start = pos + varName.length;
	                    }
	                    return false;
	                }
	                for (name => used in paramNames) {
	                    if (used == true) continue;
	                    if (codeUsesName(code, name)) {
	                        paramNames.set(name, true);
	                    }
	                }
	            }
	
	            // Scan EEx/HEEx blocks (<% ... %>)
	            var cursor = 0;
	            while (cursor < template.length) {
	                var startIndex = template.indexOf("<%", cursor);
	                if (startIndex == -1) break;
	                var endIndex = template.indexOf("%>", startIndex + 2);
	                if (endIndex == -1) break;
	                var innerCode = template.substr(startIndex + 2, endIndex - (startIndex + 2));
	                markUsedFromElixirCode(innerCode);
	                cursor = endIndex + 2;
	            }
	
	            // Scan HEEx attribute expressions ({ ... }) outside of EEx blocks.
	            var i = 0;
	            while (i < template.length) {
	                var eexStart = template.indexOf("<%", i);
	                var braceStart = template.indexOf("{", i);
	                if (braceStart == -1) break;
	                if (eexStart != -1 && eexStart < braceStart) {
	                    var eexEnd = template.indexOf("%>", eexStart + 2);
	                    if (eexEnd == -1) break;
	                    i = eexEnd + 2;
	                    continue;
	                }
	
	                var depth = 1;
	                var j = braceStart + 1;
	                var quote: Null<String> = null;
	                while (j < template.length && depth > 0) {
	                    var ch = template.charAt(j);
	                    if (quote != null) {
	                        if (ch == "\\" && j + 1 < template.length) {
	                            j += 2;
	                            continue;
	                        }
	                        if (ch == quote) quote = null;
	                        j++;
	                        continue;
	                    }
	                    if (ch == "\"" || ch == "'") {
	                        quote = ch;
	                        j++;
	                        continue;
	                    }
	                    if (ch == "{") {
	                        depth++;
	                    } else if (ch == "}") {
	                        depth--;
	                    } else if (ch == "<" && j + 1 < template.length && template.charAt(j + 1) == "%") {
	                        var nestedEnd = template.indexOf("%>", j + 2);
	                        if (nestedEnd == -1) break;
	                        j = nestedEnd + 2;
	                        continue;
	                    }
	                    j++;
	                }
	                if (depth != 0) break;
	
	                var exprCode = template.substr(braceStart + 1, (j - 1) - (braceStart + 1));
	                markUsedFromElixirCode(exprCode);
	                i = j;
	            }
	        }
	        
	        function extractParamNames(pattern: EPattern) {
	            switch(pattern) {
	                case PVar(name):
	                    // Track all named parameters (including underscored ones) so we can:
                    // - mark usage accurately (even for `_arg` style params)
                    // - replace truly unused params with `_` (wildcard) to avoid duplicate-binder warnings.
                    if (name != null && name != "" && name != "_") {
                        // Some parameter names are semantically required (or referenced indirectly)
                        // by framework macros (e.g., Phoenix HEEx requires `assigns`).
                        paramNames.set(name, isPreservedParamName(name)); // true = treat as used
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
        // DISABLED: trace('[XRay PrefixUnusedParams] Found parameters: ' + [for (name => _ in paramNames) name].join(", "));
        #end
        
        // If no parameters to check, return early
        if (Lambda.count(paramNames) == 0) {
            return {args: args, body: body, hasChanges: false};
        }
        
	        // Check which parameters are used in the body (and guards if present)
	        function markUsedVars(ast: ElixirAST) {
	            switch(ast.def) {
	                case EString(template):
	                    markUsedNamesInTemplateString(template);
	                case EVar(name):
	                    if (paramNames.exists(name)) {
	                        paramNames.set(name, true); // Mark as used
	                        #if debug_ast_transformer
	                        // DISABLED: trace('[XRay PrefixUnusedParams] Found usage of param: $name');
                        #end
                    }
                case EField(target, _):
                    // Check if the target is a parameter being accessed
                    switch(target.def) {
                        case EVar(name):
                            if (paramNames.exists(name)) {
                                paramNames.set(name, true); // Mark as used
                                #if debug_ast_transformer
                                // DISABLED: trace('[XRay PrefixUnusedParams] Found field access on param: $name');
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
                                // DISABLED: trace('[XRay PrefixUnusedParams] Found bracket access on param: $name');
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
                                // DISABLED: trace('[XRay PrefixUnusedParams] Found struct update on param: $name');
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
                            // DISABLED: trace('[XRay PrefixUnusedParams] Found param usage in ERaw: $name in code: ${code.substring(0, 100)}...');
                            #end
                        }
                    }
                case EKeywordList(pairs):
                    // Check values in keyword list for parameter usage
                    for (pair in pairs) {
                        markUsedVars(pair.value);
                        #if debug_ast_transformer
                        // DISABLED: trace('[XRay PrefixUnusedParams] Checking keyword list value for parameter usage');
                        #end
                    }
	                case ESigil(type, _content, _modifiers) if (type == "H" || type == "h"):
	                    // Phoenix HEEx (~H) requires an `assigns` variable in scope, even when
	                    // the function body only references assigns implicitly via `@foo`.
	                    if (paramNames.exists("assigns")) paramNames.set("assigns", true);
	                    if (paramNames.exists("_assigns")) paramNames.set("_assigns", true);

	                    // Also treat any function parameters referenced inside the ~H content string
	                    // as "used" so we don't rewrite their binders to `_`. This is required for
	                    // cases like `defp render_post(post) do ~H"... <%= post.title %> ..." end`.
	                    markUsedNamesInTemplateString(_content);

	                    // When available, traverse the builder-attached typed HEEx AST so that
	                    // parameter usage inside attribute expressions is counted as "used".
	                    var meta = ast.metadata;
                    if (meta != null && meta.heexAST != null) {
                        function walkHeex(node: ElixirAST) {
                            if (node == null || node.def == null) return;
                            switch (node.def) {
                                case EFragment(_tag, attributes, children):
                                    if (attributes != null) {
                                        for (a in attributes) if (a != null && a.value != null) markUsedVars(a.value);
                                    }
                                    if (children != null) {
                                        for (c in children) if (c != null) walkHeex(c);
                                    }
                                default:
                                    markUsedVars(node);
                            }
                        }

                        for (node in meta.heexAST) {
                            if (node != null) walkHeex(node);
                        }
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
        
        var hasChanges = false;

        // Replace unused parameters with the wildcard `_` (PWildcard).
        //
        // WHY:
        // - Prefixing unused params with `_name` can still produce warnings when the same
        //   underscored binder appears multiple times (e.g., `_arg, _arg`), because those
        //   are real variables and must match equal values.
        // - Haxe cannot emit duplicate argument names, so repeated binders are always
        //   compiler-generated hygiene artifacts; `_` is the correct Elixir idiom.
        //
        // HOW:
        // - After usage analysis, convert any unused `PVar(name)` (including underscored)
        //   into `PWildcard`. No body rewrite is needed because the variable is unused.
        function rewriteUnusedInPattern(pattern: EPattern): EPattern {
            if (pattern == null) return pattern;
            return switch(pattern) {
                case PVar(name):
                    var used = (name != null && paramNames.exists(name)) ? paramNames.get(name) : true;
                    if (name != null && name != "" && name != "_" && used == false) {
                        hasChanges = true;
                        PWildcard;
                    } else {
                        pattern;
                    }
                case PTuple(patterns):
                    PTuple(patterns.map(rewriteUnusedInPattern));
                case PList(patterns):
                    PList(patterns.map(rewriteUnusedInPattern));
                case PCons(head, tail):
                    PCons(rewriteUnusedInPattern(head), rewriteUnusedInPattern(tail));
                case PMap(pairs):
                    PMap([for (pair in pairs) {key: pair.key, value: rewriteUnusedInPattern(pair.value)}]);
                case PStruct(name, fields):
                    PStruct(name, [for (f in fields) {key: f.key, value: rewriteUnusedInPattern(f.value)}]);
                case PPin(p):
                    PPin(rewriteUnusedInPattern(p));
                case PAlias(varName, inner):
                    // If the alias binder itself is unused, drop it to `_` and keep matching on inner.
                    var used = (varName != null && paramNames.exists(varName)) ? paramNames.get(varName) : true;
                    if (varName != null && varName != "" && varName != "_" && used == false) {
                        hasChanges = true;
                        rewriteUnusedInPattern(inner);
                    } else {
                        PAlias(varName, rewriteUnusedInPattern(inner));
                    }
                case PBinary(segments):
                    PBinary([for (seg in segments) {size: seg.size, type: seg.type, modifiers: seg.modifiers, pattern: rewriteUnusedInPattern(seg.pattern)}]);
                default:
                    pattern;
            };
        }

        var newArgs = args.map(rewriteUnusedInPattern);
        if (!hasChanges) return {args: args, body: body, hasChanges: false};
        return {args: newArgs, body: body, hasChanges: true};
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
    public static function iterateAST(node: ElixirAST, visitor: ElixirAST -> Void): Void {
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
	            case EUnless(condition, body, elseBranch):
	                if (condition != null) visitor(condition);
	                if (body != null) visitor(body);
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
	            case EPipe(left, right):
	                if (left != null) visitor(left);
	                if (right != null) visitor(right);
	            case EUnary(op, expr):
	                if (expr != null) visitor(expr);
	            case ERaise(exception, attributes):
	                if (exception != null) visitor(exception);
	                if (attributes != null) visitor(attributes);
	            case EThrow(value):
	                if (value != null) visitor(value);
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
	            case EStructUpdate(struct, fields):
	                if (struct != null) visitor(struct);
	                for (field in fields) if (field != null && field.value != null) visitor(field.value);
	            case EAccess(target, key):
	                if (target != null) visitor(target);
	                if (key != null) visitor(key);
	            case EBitstring(segments):
	                for (seg in segments) {
	                    if (seg == null) continue;
	                    if (seg.value != null) visitor(seg.value);
	                    if (seg.size != null) visitor(seg.size);
	                }
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
	            case ERange(start, end, _exclusive, step):
	                if (start != null) visitor(start);
	                if (end != null) visitor(end);
	                if (step != null) visitor(step);
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
	            case EUse(_module, options):
	                for (opt in options) if (opt != null) visitor(opt);
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
	            case EFragment(_tag, attributes, children):
	                if (attributes != null) {
	                    for (a in attributes) if (a != null && a.value != null) visitor(a.value);
	                }
	                if (children != null) {
	                    for (c in children) if (c != null) visitor(c);
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
                    // DISABLED: trace('[XRay OTPChildSpec] Processing EList with ${elements.length} elements');
                    for (i in 0...elements.length) {
                        var elem = elements[i];
                        if (elem.metadata != null && elem.metadata.requiresIdiomaticTransform == true) {
                            // DISABLED: trace('[XRay OTPChildSpec] Element $i has requiresIdiomaticTransform flag!');
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
            case ERange(start, end, exclusive, step):
                makeASTWithMeta(
                    ERange(
                        transformer(start),
                        transformer(end),
                        exclusive,
                        step != null ? transformer(step) : null
                    ),
                    node.metadata,
                    node.pos
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
        // DISABLED: trace("[XRay OTPChildSpec] Starting idiomatic enum transformation pass");
        #end
        
        var transformCount = 0;
        
        function transformIdiomaticNode(node: ElixirAST): ElixirAST {
            #if (debug_otp_child_spec && debug_otp_child_spec_verbose)
            // Very verbose - show every node being checked
            // DISABLED: trace('[XRay OTPChildSpec] Checking node type: ${reflaxe.elixir.util.EnumReflection.enumConstructor(node.def)}');
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
                // DISABLED: trace('[XRay OTPChildSpec] Found node #${++transformCount} with requiresIdiomaticTransform flag');
                // DISABLED: trace('[XRay OTPChildSpec] Node def: ${nodeWithTransformedChildren.def}');
                #end
                // Apply transformation using shared utility
                var transformed = reflaxe.elixir.ast.ElixirAST.applyIdiomaticEnumTransformation(nodeWithTransformedChildren);
                #if debug_otp_child_spec
                // DISABLED: trace('[XRay OTPChildSpec] Transformed to: ${transformed.def}');
                #end
                return transformed;
            }
            
            return nodeWithTransformedChildren;
        }
        
        var result = transformIdiomaticNode(ast);
        
        #if debug_otp_child_spec
        // DISABLED: trace('[XRay OTPChildSpec] Pass complete. Transformed ${transformCount} nodes');
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
        // DISABLED: trace('[XRay TupleElemField] Starting tuple elem field to function transformation');
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
                // DISABLED: trace('[XRay TupleElemField] Found .elem field access on: $targetStr');
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
                    // DISABLED: trace('[XRay TupleElemField] Transforming ${targetStr}.elem(${args.length} args) to elem($targetStr, ...)');
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
        // DISABLED: trace('[XRay EnumPatternMatching] Starting idiomatic enum pattern matching pass');
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
                                // DISABLED: trace('[XRay EnumPatternMatching] Found enum tag check pattern on elem(0) as ECall');
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
                        // DISABLED: trace('[XRay EnumPatternMatching] Found potential enum tag check pattern with .elem field access');
                        #end
                        isEnumTagCheck = true;
                        baseExpr = tupleExpr;
                    default:
                }
                
                if (isEnumTagCheck) {
                    
                    #if debug_ast_transformer
                    // DISABLED: trace('[XRay EnumPatternMatching] Transforming enum case to idiomatic pattern matching');
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
        // DISABLED: trace('[XRay EnumPatternMatching] Transforming clause with pattern: ${clause.pattern}');
        #end
        
        // Extract the tag value from the pattern
        var tagValue = switch(clause.pattern) {
            case PLiteral(ast):
                switch(ast.def) {
                    case EInteger(tag): tag;
                    default:
                        #if debug_ast_transformer
                        // DISABLED: trace('[XRay EnumPatternMatching] Non-integer pattern, keeping as-is');
                        #end
                        return clause; // Can't transform non-integer patterns
                }
            default: 
                #if debug_ast_transformer
                // DISABLED: trace('[XRay EnumPatternMatching] Non-literal pattern, keeping as-is');
                #end
                return clause; // Can't transform non-literal patterns
        };
        
        // Analyze the body to find parameter extraction patterns
        var extractedParams = analyzeEnumParameterExtraction(clause.body, baseExpr);
        
        #if debug_ast_transformer
        // DISABLED: trace('[XRay EnumPatternMatching] Found ${extractedParams.length} extracted parameters');
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
        // DISABLED: trace('[XRay EnumPatternMatching] Created tuple pattern with ${extractedParams.length + 1} elements');
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
        // DISABLED: trace('[XRay UnderscoreCleanup] Starting underscore variable cleanup pass');
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
                        // DISABLED: trace('[XRay UnderscoreCleanup] Found used underscore variable: $name at ${node.pos}');
                        #end
                    }
                    
                case ERemoteCall(module, funcName, args):
                    #if debug_ast_transformer
                    // DISABLED: trace('[XRay UnderscoreCleanup] Found ERemoteCall: $funcName with ${args.length} args');
                    #end
                    // Recursively collect from module and all arguments
                    if (module != null) collectVariables(module);
                    for (arg in args) {
                        collectVariables(arg);
                    }
                    
                case EFn(clauses):
                    #if debug_ast_transformer
                    // DISABLED: trace('[XRay UnderscoreCleanup] Found EFn with ${clauses.length} clauses');
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
                    // DISABLED: trace('[XRay UnderscoreCleanup] PRESERVING infrastructure variable: $varName (used in switch desugaring)');
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
                    // DISABLED: trace('[XRay UnderscoreCleanup] Renaming used numeric: $varName -> $newName');
                    #end
                }
                // Other underscore variables are left as-is (might be intentional)
            } else {
                #if debug_ast_transformer
                if (varName.charAt(0) == "_" && varName.length > 1) {
                    // DISABLED: trace('[XRay UnderscoreCleanup] Keeping unused underscore variable: $varName');
                }
                #end
            }
        }
        
        // Phase 3: Apply renaming throughout the AST
        if (renameMap.keys().hasNext()) {
            #if debug_ast_transformer
            // DISABLED: trace('[XRay UnderscoreCleanup] Applying ${Lambda.count(renameMap)} variable renamings');
            #end
            return applyVariableRenaming(ast, renameMap);
        }
        
        #if debug_ast_transformer
        // DISABLED: trace('[XRay UnderscoreCleanup] No underscore variables need renaming');
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
                        // DISABLED: trace('[XRay UnderscoreCleanup] Renaming EVar: $name -> ${renameMap.get(name)}');
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
        // DISABLED: trace('[Array Comprehension Transform] Starting reconstruction pass');
        #end
        #if debug_unrolled_comprehension
        // DISABLED: trace('[DEBUG Transform] unrolledComprehensionReconstructionPass called');
        #end
        
        function reconstructComprehension(ast: ElixirAST): ElixirAST {
            return switch(ast.def) {
                case EBlock(stmts) if (ast.metadata != null && ast.metadata.isUnrolledComprehension == true):
                    #if debug_array_comprehension
                    // DISABLED: trace('[Array Comprehension Transform] ✓ Found marked block with ${stmts.length} statements');
                    // DISABLED: trace('[Array Comprehension Transform]   Metadata: ${ast.metadata}');
                    #end
                    
                    // Analyze the block to reconstruct comprehension
                    var comprehension = analyzeAndReconstructComprehension(stmts);
                    if (comprehension != null) {
                        #if debug_array_comprehension
                        // DISABLED: trace('[Array Comprehension Transform] ✓ Successfully reconstructed as for comprehension');
                        #end
                        comprehension;
                    } else {
                        #if debug_array_comprehension
                        // DISABLED: trace('[Array Comprehension Transform] ✗ Could not reconstruct, keeping as block');
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
        // DISABLED: trace('[Array Comprehension Transform] Analyzing block for reconstruction');
        #end
        
        // Check first statement: should be g = []
        var iterVar = switch(stmts[0].def) {
            case EBinary(Match, {def: EVar(varName)}, {def: EList([])}):
                varName;
            case _:
                return null;
        };
        
        #if debug_array_comprehension
        // DISABLED: trace('[Array Comprehension Transform]   Found initialization: $iterVar = []');
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
                    // DISABLED: trace('[Array Comprehension Transform]   Unknown statement pattern: ${stmts[i].def}');
                    #end
            }
        }
        
        #if debug_array_comprehension
        // DISABLED: trace('[Array Comprehension Transform]   Extracted ${elements.length} elements');
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
        // DISABLED: trace('[Array Comprehension Transform]   Simple range: $isSimpleRange, Nested: $hasNestedComprehensions');
        #end
        
        // Generate appropriate comprehension
        if (isSimpleRange) {
            // Simple range comprehension: for i <- 0..n, do: i
            var range = makeAST(ERange(makeAST(EInteger(0)), makeAST(EInteger(rangeEnd)), false, makeAST(EInteger(1))));
            var generator: EGenerator = {
                pattern: PVar("i"),
                expr: range
            };
            var body = makeAST(EVar("i")); // Simple case: just return the iterator
            
            return makeAST(EFor([generator], [], body, null, null));
        } else if (hasNestedComprehensions) {
            // Nested comprehension: for i <- 0..n, do: for j <- 0..m, do: expr
            // For now, reconstruct the outer comprehension
            var range = makeAST(ERange(makeAST(EInteger(0)), makeAST(EInteger(rangeEnd)), false, makeAST(EInteger(1))));
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
            // DISABLED: trace('[Array Comprehension Transform]   Complex pattern, not reconstructing');
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
            var range = makeAST(ERange(makeAST(EInteger(0)), makeAST(EInteger(rangeEnd)), false, makeAST(EInteger(1))));
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
        // DISABLED: trace("[XRay SupervisorOptions] Starting supervisor options transformation");
        switch(ast.def) {
            case EDefmodule(name, _):
                // DISABLED: trace('[XRay SupervisorOptions] Processing module: $name');
            case _:
                // DISABLED: trace('[XRay SupervisorOptions] Processing non-module AST');
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
                    // DISABLED: trace('[XRay SupervisorOptions] Found variable assignment in transformSupervisorCalls: $name');
                case EMap(_):
                    // DISABLED: trace('[XRay SupervisorOptions] Found map in transformSupervisorCalls');
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
                        // DISABLED: trace("[XRay SupervisorOptions] Found Supervisor.start_link call");
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
                        // DISABLED: trace('[XRay SupervisorOptions] Found variable assignment: $varName');
                    }
                    #end
                    
                    if (varName != null && (varName == "opts" || varName.indexOf("option") != -1 || varName.indexOf("config") != -1)) {
                        // This might be supervisor options
                        #if debug_ast_transformer
                        // DISABLED: trace('[XRay SupervisorOptions] Variable $varName looks like options, checking if it\'s a map...');
                        #end
                        
                        var transformedExpr = transformSupervisorOptions(expr);
                        if (transformedExpr != expr) {
                            #if debug_ast_transformer
                            // DISABLED: trace('[XRay SupervisorOptions] ✓ Transformed options assignment for variable: $varName');
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
                // DISABLED: trace('[XRay SupervisorOptions] Analyzing map with ${pairs.length} pairs');
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
                        // DISABLED: trace('[XRay SupervisorOptions] Checking key: $keyName (hasStrategy=$hasStrategy, hasMaxRestarts=$hasMaxRestarts)');
                        #end
                    }
                }
                
                // If it has at least strategy (required) and one other supervisor field, convert it
                if (hasStrategy && (hasMaxRestarts || hasMaxSeconds || hasName)) {
                    #if debug_ast_transformer
                    // DISABLED: trace("[XRay SupervisorOptions] Converting map to keyword list for supervisor options");
                    #end
                    
                    // Convert EMapPair to EKeywordPair with normalization for strategy atom
                    var keywordPairs: Array<EKeywordPair> = [];
                    for (pair in pairs) {
                        var key = switch(pair.key.def) {
                            case EAtom(name): name;
                            case _: continue; // Skip non-atom keys
                        };
                        var value = pair.value;
                        // Normalize strategy value to a clean atom without a leading colon
                        if (key == "strategy") {
                            switch (value.def) {
                                case EAtom(a):
                                    var aStr:String = a;
                                    if (aStr != null && aStr.length > 0 && aStr.charAt(0) == ':') {
                                        var trimmed = aStr.substr(1);
                                        value = makeAST(EAtom(ElixirAtom.raw(trimmed)));
                                    }
                                case EString(s):
                                    if (s != null && s.length > 0 && s.charAt(0) == ':') {
                                        var trimmed2 = s.substr(1);
                                        value = makeAST(EAtom(ElixirAtom.raw(trimmed2)));
                                    }
                                default:
                            }
                        }
                        
                        // Note: Snake_case conversion for atoms is handled systematically
                        // in ElixirASTBuilder.toElixirAtomName(), not here
                        keywordPairs.push({key: key, value: value});
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
}

#if debug_ast_snapshots
private class AbsoluteFinalSnapshot {
    public static function emitFilterTodosThenBranch(ast: ElixirAST): Void {
        // Optional narrowing: module and func can be provided via defines.
        var wantFunc = getDefineString('debug_ast_snapshots_func');
        var wantModule = getDefineString('debug_ast_snapshots_module');

        // Default target if none provided
        if (wantFunc == null || wantFunc == '') wantFunc = 'filter_todos/3';

        var targetName = extractFuncName(wantFunc);
        var targetArity = extractArity(wantFunc);

        var thenBranch: ElixirAST = null;
        var seenFuncs: Array<String> = [];

        traverse(ast, function(node) {
            // Attempt capture from any function node we see
            tryCaptureFromDef(node, targetName, targetArity, function(b) thenBranch = b);
            if (thenBranch != null) return; // short‑circuit
            // Optional module narrowing: no‑op unless set
            switch (node.def) {
                case EModule(modName, _, _):
                    #if sys Sys.println('[AST Snapshot] In module: ' + modName); #end
                    if (wantModule != null && wantModule != '' && modName != wantModule) {
                        // Note: we don't prune traversal here to avoid skipping nested defs
                    }
                case EDef(name, args, _, _) | EDefp(name, args, _, _):
                    if (seenFuncs.indexOf(name + '/' + (args != null ? args.length : 0)) == -1)
                        seenFuncs.push(name + '/' + (args != null ? args.length : 0));
                default:
            }
        });

        if (thenBranch != null) {
            var code = safePrint(thenBranch);
            writeSnapshot('tmp/ast_flow', 'AbsoluteFinal_filter_todos_then_branch.ex', code);
            #if sys Sys.println('[AST Snapshot] Wrote then‑branch to tmp/ast_flow/AbsoluteFinal_filter_todos_then_branch.ex'); #else trace('[AST Snapshot] Wrote then‑branch'); #end
            // If module name filter is set, dump observed functions for debugging
            if (wantModule != null && wantModule != '') {
                var fnDump = seenFuncs.join("\n");
                writeSnapshot('tmp/ast_flow', 'AbsoluteFinal_' + targetName + '_observed_functions.txt', fnDump);
            }
        } else {
            #if sys Sys.println('[AST Snapshot] filter_todos/3 then‑branch not found'); #else trace('[AST Snapshot] then‑branch not found'); #end
        }
    }

    static function tryCaptureFromDef(node: ElixirAST, targetName: String, targetArity: Int, onFound: ElixirAST -> Void): Void {
        switch (node.def) {
            case EDef(name, args, _, body) | EDefp(name, args, _, body):
                #if sys Sys.println('[AST Snapshot] Saw def ' + name + '/' + (args != null ? args.length : 0)); #end
                if (name == targetName && args != null && args.length == targetArity) {
                    var firstIf = findFirstIf(body);
                    if (firstIf != null) onFound(firstIf.thenBranch);
                }
            default:
        }
    }

    static function findFirstIf(node: ElixirAST): { condition: ElixirAST, thenBranch: ElixirAST, elseBranch: Null<ElixirAST> } {
        var found: { condition: ElixirAST, thenBranch: ElixirAST, elseBranch: Null<ElixirAST> } = null;
        traverse(node, function(n) {
            if (found != null) return; // short‑circuit
            switch (n.def) {
                case EIf(cond, thenB, elseB):
                    found = { condition: cond, thenBranch: thenB, elseBranch: elseB };
                default:
            }
        });
        return found;
    }

    static function traverse(node: ElixirAST, f: ElixirAST -> Void): Void {
        if (node == null) return;
        function visitor(n: ElixirAST): Void {
            if (n == null) return;
            f(n);
            // Recursively visit child nodes via transformAST with identity
            ElixirASTTransformer.transformAST(n, function(child) {
                visitor(child);
                return child;
            });
        }
        visitor(node);
    }

    static function safePrint(node: ElixirAST): String {
        try {
            return reflaxe.elixir.ast.ElixirASTPrinter.print(node, 0);
        } catch (e) {
            return '// <printer error> ' + Std.string(e);
        }
    }

    static function extractFuncName(spec: String): String {
        var idx = spec.lastIndexOf('/');
        return idx >= 0 ? spec.substr(0, idx) : spec;
    }

    static function extractArity(spec: String): Int {
        var idx = spec.lastIndexOf('/');
        if (idx < 0) return 0;
        var s = spec.substr(idx + 1);
        return Std.parseInt(s);
    }

    static function getDefineString(name: String): Null<String> {
        #if macro
        try return haxe.macro.Context.definedValue(name) catch (_) return null;
        #else
        return null;
        #end
    }

    static function writeSnapshot(dir: String, file: String, content: String): Void {
        #if sys
        if (!sys.FileSystem.exists(dir)) sys.FileSystem.createDirectory(dir);
        var full = dir + '/' + file;
        sys.io.File.saveContent(full, content);
        #end
    }
}
#end // debug_ast_snapshots

#if debug_ast_snapshots
private class PerPassSnapshot {
    static var passIndex:Int = 0;

		    public static function emitFunctionAfterPass(ast: ElixirAST, passName:String):Void {
		        var spec = getDefineString('debug_ast_snapshots_func');
		        if (spec == null || spec == '') return;
        var targetName = extractFuncName(spec);
        var targetArity = extractArity(spec);
        var fnNode: Null<ElixirAST> = null;
        traverse(ast, function(n) {
            switch (n.def) {
                case EDef(name, args, _, _) | EDefp(name, args, _, _):
                    if (name == targetName && args != null && args.length == targetArity) fnNode = n;
                default:
            }
        });
		        if (fnNode == null) { passIndex++; return; }
		        var code = safePrint(fnNode);
		        var dir = 'tmp/ast_flow/passes';
		        #if (macro || sys) if (!sys.FileSystem.exists(dir)) sys.FileSystem.createDirectory(dir); #end
		        var file = dir + '/' + Std.string(passIndex) + '_' + sanitize(passName) + '.ex';
		        #if (macro || sys) sys.io.File.saveContent(file, code); #end
		        passIndex++;
		    }

    static function sanitize(s:String):String {
        if (s == null) return 'pass';
        return s.split(' ').join('_').split('/').join('_');
    }
    static function getDefineString(name: String): Null<String> {
        #if macro
        try return haxe.macro.Context.definedValue(name) catch (_) return null;
        #else
        return null;
        #end
    }
    static function extractFuncName(spec: String): String {
        var idx = spec.lastIndexOf('/');
        return idx >= 0 ? spec.substr(0, idx) : spec;
    }
    static function extractArity(spec: String): Int {
        var idx = spec.lastIndexOf('/');
        if (idx < 0) return 0;
        var s = spec.substr(idx + 1);
        return Std.parseInt(s);
    }

    static function traverse(node: ElixirAST, f: ElixirAST -> Void): Void {
        if (node == null) return;
        function visitor(n: ElixirAST): Void {
            if (n == null) return;
            f(n);
            ElixirASTTransformer.transformAST(n, function(child) {
                visitor(child);
                return child;
            });
        }
        visitor(node);
    }

    static function safePrint(node: ElixirAST): String {
        try {
            return reflaxe.elixir.ast.ElixirASTPrinter.print(node, 0);
        } catch (e) {
            return '// <printer error> ' + Std.string(e);
        }
    }
}
#end // debug_ast_snapshots

#if debug_ast_snapshots
private class PerPassModuleSnapshot {
    static var passIndex:Int = 0;

		    public static function emitModuleAfterPass(ast: ElixirAST, rootName: String, passName: String): Void {
	        var moduleFilter = getDefineString('debug_ast_snapshots_module');
        if (moduleFilter == null || moduleFilter == '') { passIndex++; return; }
        if (rootName == null || rootName.indexOf(moduleFilter) == -1) { passIndex++; return; }

        var code = safePrint(ast);
        var containsFilter = getDefineString('debug_ast_snapshots_contains');
        if (containsFilter != null && containsFilter != '') {
            // Allow space in define values via URL-style encoding, e.g.:
            //   -D debug_ast_snapshots_contains=defmodule%20Main
            containsFilter = containsFilter.split('%20').join(' ');
            if (code.indexOf(containsFilter) == -1) { passIndex++; return; }
		        }
		        var dir = 'tmp/ast_flow/passes_module2';
		        #if (macro || sys) if (!sys.FileSystem.exists(dir)) sys.FileSystem.createDirectory(dir); #end
		        var file = dir + '/' + Std.string(passIndex) + '_' + sanitize(rootName) + '_' + sanitize(passName) + '.ex';
		        #if (macro || sys) sys.io.File.saveContent(file, code); #end
		        passIndex++;
		    }

    static function sanitize(s:String):String {
        if (s == null) return 'pass';
        return s.split(' ').join('_').split('/').join('_');
    }

    static function getDefineString(name: String): Null<String> {
        #if macro
        try return haxe.macro.Context.definedValue(name) catch (_) return null;
        #else
        return null;
        #end
    }

    static function safePrint(node: ElixirAST): String {
        try {
            return reflaxe.elixir.ast.ElixirASTPrinter.print(node, 0);
        } catch (e) {
            return '// <printer error> ' + Std.string(e);
        }
    }
}
#end // debug_ast_snapshots

#end // (macro || reflaxe_runtime)
