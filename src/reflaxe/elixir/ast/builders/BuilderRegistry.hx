package reflaxe.elixir.ast.builders;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.context.BuildContext;
import reflaxe.elixir.ast.builders.interfaces.IBuilder;

/**
 * BuilderRegistry: Central Registry for AST Builders
 * 
 * WHY: The previous modularization attempt failed because modules were tightly
 * coupled. This registry pattern provides loose coupling through dynamic
 * builder resolution based on expression type and feature flags.
 * 
 * WHAT: Manages:
 * - Registration of specialized builders
 * - Dynamic builder resolution based on canHandle predicates
 * - Priority-based ordering when multiple builders match
 * - Feature flag integration for gradual migration
 * - Fallback to legacy builder for unhandled expressions
 * 
 * HOW: Builders register themselves with the registry. When building an expression:
 * 1. Registry checks all registered builders in priority order
 * 2. First builder whose canHandle returns true gets to build
 * 3. If no builder handles it, fallback to legacy ElixirASTBuilder
 * 
 * ARCHITECTURE BENEFITS:
 * - Open/Closed: New builders added without modifying existing code
 * - Loose Coupling: Builders don't know about each other
 * - Gradual Migration: Can replace parts of ElixirASTBuilder incrementally
 * - Testing: Can register mock builders for unit tests
 * - Performance: Only active builders are checked
 * 
 * EDGE CASES:
 * - Circular dependencies prevented through BuildContext delegation
 * - Priority conflicts resolved by registration order
 * - Feature flags allow A/B testing of new builders
 */
class BuilderRegistry {
    // Registered builders by type
    private var builders: Array<IBuilder> = [];
    
    // Legacy fallback (ElixirASTBuilder)
    private var legacyBuilder: Dynamic;
    
    // Feature flags for gradual migration
    private var featureFlags: Map<String, Bool> = new Map();
    
    /**
     * Create a new builder registry
     * 
     * @param legacy The legacy ElixirASTBuilder for fallback
     */
    public function new(legacy: Dynamic) {
        this.legacyBuilder = legacy;
        initializeDefaultFlags();
    }
    
    /**
     * Initialize default feature flags
     */
    private function initializeDefaultFlags(): Void {
        // Start with all new builders disabled for safety
        featureFlags.set("use_pattern_builder", false);
        featureFlags.set("use_loop_optimizer", false);
        featureFlags.set("use_enum_handler", false);
        featureFlags.set("use_variable_analyzer", false);
        featureFlags.set("use_comprehension_builder", false);
    }
    
    /**
     * Register a builder with the registry
     * 
     * @param builder The builder to register
     */
    public function registerBuilder(builder: IBuilder): Void {
        builders.push(builder);
        // Sort by priority (higher first)
        builders.sort((a, b) -> b.getPriority() - a.getPriority());
        
        #if debug_builder_registry
        trace('[BuilderRegistry] Registered ${builder.getName()} with priority ${builder.getPriority()}');
        #end
    }
    
    /**
     * Build an expression by finding the appropriate builder
     * 
     * @param expr The expression to build
     * @param context The build context
     * @return The built ElixirAST node
     */
    public function build(expr: TypedExpr, context: BuildContext): ElixirAST {
        // Check registered builders first
        for (builder in builders) {
            if (builder.canHandle(expr, context)) {
                #if debug_builder_registry
                trace('[BuilderRegistry] Using ${builder.getName()} for ${expr.expr}');
                #end
                
                var result = builder.build(expr, context);
                if (result != null) {
                    return result;
                }
            }
        }
        
        // Fallback to legacy builder
        #if debug_builder_registry
        trace('[BuilderRegistry] Falling back to legacy builder for ${expr.expr}');
        #end
        
        return legacyBuilder.buildFromTypedExpr(expr, context);
    }
    
    /**
     * Set a feature flag
     * 
     * @param flag The flag name
     * @param enabled Whether to enable or disable
     */
    public function setFeatureFlag(flag: String, enabled: Bool): Void {
        featureFlags.set(flag, enabled);
        
        #if debug_builder_registry
        trace('[BuilderRegistry] Feature flag "$flag" set to $enabled');
        #end
    }
    
    /**
     * Check if a feature flag is enabled
     * 
     * @param flag The flag name
     * @return True if enabled
     */
    public function isFeatureEnabled(flag: String): Bool {
        return featureFlags.get(flag) == true;
    }
    
    /**
     * Get all registered builders for debugging
     * 
     * @return Array of registered builders
     */
    public function getBuilders(): Array<IBuilder> {
        return builders.copy();
    }
    
    /**
     * Clear all registered builders (useful for testing)
     */
    public function clearBuilders(): Void {
        builders = [];
    }
    
    /**
     * Enable gradual migration mode
     * Allows mixing new and old builders based on feature flags
     * 
     * @param builderType The type of builder to conditionally enable
     */
    public function enableGradualMigration(builderType: String): Void {
        switch (builderType) {
            case "pattern":
                setFeatureFlag("use_pattern_builder", true);
            case "loop":
                setFeatureFlag("use_loop_optimizer", true);
            case "enum":
                setFeatureFlag("use_enum_handler", true);
            case "variable":
                setFeatureFlag("use_variable_analyzer", true);
            case "comprehension":
                setFeatureFlag("use_comprehension_builder", true);
            case "all":
                // Enable all new builders (risky!)
                setFeatureFlag("use_pattern_builder", true);
                setFeatureFlag("use_loop_optimizer", true);
                setFeatureFlag("use_enum_handler", true);
                setFeatureFlag("use_variable_analyzer", true);
                setFeatureFlag("use_comprehension_builder", true);
        }
    }
}

#end