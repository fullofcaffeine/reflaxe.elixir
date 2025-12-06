package reflaxe.elixir.ast.builders;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.context.BuildContext;
import reflaxe.elixir.ast.builders.IBuilder;

/**
 * Typedef for switch case structure from TypedExprDef
 */
typedef Case = {
    var values: Array<TypedExpr>;
    var expr: TypedExpr;
    @:optional var guard: Null<TypedExpr>;
}

/**
 * BuilderFacade: Router for gradual migration from monolithic to modular builders
 *
 * WHY: Codex architectural review identified the need for safe, incremental migration
 * from the 10,000+ line ElixirASTBuilder to specialized builders. This facade enables
 * feature-flagged routing, allowing us to migrate one pattern at a time without
 * breaking existing functionality.
 *
 * WHAT: Provides a routing layer that:
 * - Routes compilation requests to new builders when enabled
 * - Falls back to legacy implementation when flags are disabled
 * - Allows A/B testing of new implementations
 * - Enables gradual rollout with immediate rollback capability
 *
 * HOW: The facade checks feature flags and routes accordingly:
 * - Feature flags control which builder handles each pattern
 * - New builders are registered with the facade
 * - Legacy fallback ensures nothing breaks during migration
 * - Metrics track which paths are being used
 *
 * ARCHITECTURE BENEFITS:
 * - Safe Migration: Can roll back instantly if issues arise
 * - Incremental Progress: Migrate one pattern at a time
 * - A/B Testing: Compare old vs new implementations
 * - Zero Downtime: No breaking changes during migration
 * - Clear Boundaries: Explicit routing instead of tangled logic
 *
 * USAGE EXAMPLE:
 * ```haxe
 * // In ElixirASTBuilder
 * var facade = new BuilderFacade(this, context);
 * facade.registerBuilder("pattern", new PatternMatchBuilder(context));
 *
 * // Route through facade
 * return facade.routeSwitch(expr, cases, defaultExpr);
 * ```
 *
 * @see BuildContext for feature flag management
 * @see PatternMatchBuilder for example specialized builder
 * @see docs/03-compiler-development/AST_MODULARIZATION_INFRASTRUCTURE.md
 */
class BuilderFacade {
    var context: BuildContext;
    var legacyBuilder: Dynamic; // ElixirASTBuilder instance (kept as Dynamic since it's the main compiler)
    var specializedBuilders: Map<String, IBuilder>;
    var routingMetrics: Map<String, Int>;

    /**
     * Create a new BuilderFacade
     *
     * @param legacyBuilder The original ElixirASTBuilder for fallback
     * @param context Build context with feature flags
     */
    public function new(legacyBuilder: Dynamic, context: BuildContext) {
        this.legacyBuilder = legacyBuilder;
        this.context = context;
        this.specializedBuilders = new Map();
        this.routingMetrics = new Map();
    }

    /**
     * Register a specialized builder
     *
     * @param builderType Type identifier (e.g., "pattern", "loop", "function")
     * @param builder The specialized builder instance
     */
    public function registerBuilder(builderType: String, builder: Dynamic): Void {
        specializedBuilders.set(builderType, builder);
        context.registerBuilder(builderType, builder);

        #if debug_ast_builder
        // DISABLED: trace('[BuilderFacade] Registered ${builderType} builder');
        #end
    }

    /**
     * Route switch/case compilation
     *
     * @param expr Expression being switched on
     * @param cases Array of switch cases
     * @param defaultExpr Default case expression
     * @return Compiled ElixirAST
     */
    public function routeSwitch(expr: TypedExpr, cases: Array<Case>, defaultExpr: Null<TypedExpr>): ElixirAST {
        if (context.isFeatureEnabled("use_new_pattern_builder")) {
            recordRouting("pattern.new");

            var patternBuilder = specializedBuilders.get("pattern");
            if (patternBuilder != null) {
                #if debug_ast_builder
                // DISABLED: trace('[BuilderFacade] Routing switch to PatternMatchBuilder');
                #end

                try {
                    // TODO: Re-enable when PatternMatchBuilder is fixed
                    // Cast to PatternMatchBuilder to access specific methods
                    // var pmBuilder = cast(patternBuilder, PatternMatchBuilder);
                    // return pmBuilder.buildCaseExpression(expr, cases, defaultExpr, null);
                    throw "PatternMatchBuilder disabled";
                } catch (e: Dynamic) {
                    #if debug_ast_builder
                    // DISABLED: trace('[BuilderFacade] PatternMatchBuilder failed, falling back: ${e}');
                    #end
                    // Fall through to legacy
                }
            }
        }

        recordRouting("pattern.legacy");
        #if debug_ast_builder
        // DISABLED: trace('[BuilderFacade] Using legacy switch compilation');
        #end

        // Call legacy implementation
        return legacyBuilder.compileSwitch(expr, cases, defaultExpr);
    }

    /**
     * Route loop compilation
     *
     * @param condition Loop condition
     * @param body Loop body
     * @return Compiled ElixirAST
     */
    public function routeLoop(condition: TypedExpr, body: TypedExpr): ElixirAST {
        // TODO: Implement LoopBuilder in Phase 3
        /*
        if (context.isFeatureEnabled("use_new_loop_builder")) {
            recordRouting("loop.new");

            var loopBuilder = specializedBuilders.get("loop");
            if (loopBuilder != null) {
                #if debug_ast_builder
                // DISABLED: trace('[BuilderFacade] Routing loop to LoopBuilder');
                #end

                try {
                    // Would need cast to LoopBuilder when implemented
                    return loopBuilder.buildLoop(condition, body);
                } catch (e: Dynamic) {
                    #if debug_ast_builder
                    // DISABLED: trace('[BuilderFacade] LoopBuilder failed, falling back: ${e}');
                    #end
                    // Fall through to legacy
                }
            }
        }
        */

        recordRouting("loop.legacy");
        #if debug_ast_builder
        // DISABLED: trace('[BuilderFacade] Using legacy loop compilation');
        #end

        // Call legacy implementation
        return legacyBuilder.compileWhile(condition, body);
    }

    /**
     * Route function compilation
     *
     * @param field Class field representing the function
     * @param expr Function body expression
     * @return Compiled ElixirAST
     */
    public function routeFunction(field: ClassField, expr: TypedExpr): ElixirAST {
        // TODO: Implement FunctionBuilder in Phase 3
        /*
        if (context.isFeatureEnabled("use_new_function_builder")) {
            recordRouting("function.new");

            var functionBuilder = specializedBuilders.get("function");
            if (functionBuilder != null) {
                #if debug_ast_builder
                // DISABLED: trace('[BuilderFacade] Routing function to FunctionBuilder');
                #end

                try {
                    // Would need cast to FunctionBuilder when implemented
                    return functionBuilder.buildFunction(field, expr);
                } catch (e: Dynamic) {
                    #if debug_ast_builder
                    // DISABLED: trace('[BuilderFacade] FunctionBuilder failed, falling back: ${e}');
                    #end
                    // Fall through to legacy
                }
            }
        }
        */

        recordRouting("function.legacy");
        #if debug_ast_builder
        // DISABLED: trace('[BuilderFacade] Using legacy function compilation');
        #end

        // Call legacy implementation
        return legacyBuilder.compileFunction(field, expr);
    }

    /**
     * Route array comprehension compilation
     *
     * @param generator Source array expression
     * @param mapper Mapping function
     * @param filter Optional filter expression
     * @return Compiled ElixirAST
     */
    public function routeComprehension(generator: TypedExpr, mapper: TypedExpr, filter: Null<TypedExpr>): ElixirAST {
        // TODO: Implement ComprehensionBuilder in Phase 3
        /*
        if (context.isFeatureEnabled("use_new_comprehension_builder")) {
            recordRouting("comprehension.new");

            var comprehensionBuilder = specializedBuilders.get("comprehension");
            if (comprehensionBuilder != null) {
                #if debug_ast_builder
                // DISABLED: trace('[BuilderFacade] Routing comprehension to ComprehensionBuilder');
                #end

                try {
                    // Would need cast to ComprehensionBuilder when implemented
                    return comprehensionBuilder.buildComprehension(generator, mapper, filter);
                } catch (e: Dynamic) {
                    #if debug_ast_builder
                    // DISABLED: trace('[BuilderFacade] ComprehensionBuilder failed, falling back: ${e}');
                    #end
                    // Fall through to legacy
                }
            }
        }
        */

        recordRouting("comprehension.legacy");
        #if debug_ast_builder
        // DISABLED: trace('[BuilderFacade] Using legacy comprehension compilation');
        #end

        // Call legacy implementation
        return legacyBuilder.compileComprehension(generator, mapper, filter);
    }

    /**
     * Enable gradual migration for a specific pattern
     *
     * @param builderType Type of builder to enable
     * @param percentage Percentage of requests to route to new builder (0-100)
     */
    public function enableGradualMigration(builderType: String, percentage: Int): Void {
        if (percentage < 0 || percentage > 100) {
            throw 'Invalid percentage: ${percentage}. Must be 0-100.';
        }

        var flagName = 'use_new_${builderType}_builder';

        // Simple percentage-based routing
        var random = Std.random(100);
        var shouldEnable = random < percentage;

        context.setFeatureFlag(flagName, shouldEnable);

        #if debug_ast_builder
        // DISABLED: trace('[BuilderFacade] Gradual migration for ${builderType}: ${percentage}% (enabled=${shouldEnable})');
        #end
    }

    /**
     * Record routing decision for metrics
     *
     * @param route The route taken (e.g., "pattern.new", "pattern.legacy")
     */
    function recordRouting(route: String): Void {
        if (!routingMetrics.exists(route)) {
            routingMetrics.set(route, 0);
        }
        routingMetrics.set(route, routingMetrics.get(route) + 1);
    }

    /**
     * Get routing metrics report
     *
     * @return String report of routing decisions
     */
    public function getMetricsReport(): String {
        var report = ["BuilderFacade Routing Metrics:"];

        for (route in routingMetrics.keys()) {
            var count = routingMetrics.get(route);
            report.push('  ${route}: ${count} calls');
        }

        // Calculate percentages
        var totalByType = new Map<String, Int>();
        for (route in routingMetrics.keys()) {
            var parts = route.split(".");
            var type = parts[0];
            var impl = parts[1];

            if (!totalByType.exists(type)) {
                totalByType.set(type, 0);
            }
            totalByType.set(type, totalByType.get(type) + routingMetrics.get(route));
        }

        report.push("\nMigration Progress:");
        for (type in totalByType.keys()) {
            var total = totalByType.get(type);
            var newCount = routingMetrics.exists('${type}.new') ? routingMetrics.get('${type}.new') : 0;
            var percentage = total > 0 ? Math.round((newCount / total) * 100) : 0;
            report.push('  ${type}: ${percentage}% migrated (${newCount}/${total})');
        }

        return report.join("\n");
    }

    /**
     * Reset all feature flags to use legacy implementations
     * Emergency rollback mechanism
     */
    public function rollbackAll(): Void {
        var flags = [
            "use_new_pattern_builder",
            "use_new_loop_builder",
            "use_new_function_builder",
            "use_new_comprehension_builder"
        ];

        for (flag in flags) {
            context.setFeatureFlag(flag, false);
        }

        #if debug_ast_builder
        // DISABLED: trace('[BuilderFacade] EMERGENCY ROLLBACK - All builders disabled');
        #end
    }

    /**
     * Enable all new builders for full migration
     * Use with caution - preferably after thorough testing
     */
    public function enableAll(): Void {
        var flags = [
            "use_new_pattern_builder",
            "use_new_loop_builder",
            "use_new_function_builder",
            "use_new_comprehension_builder"
        ];

        for (flag in flags) {
            context.setFeatureFlag(flag, true);
        }

        #if debug_ast_builder
        // DISABLED: trace('[BuilderFacade] All new builders enabled');
        #end
    }
}

#end