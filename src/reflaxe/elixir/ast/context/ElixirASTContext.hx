package reflaxe.elixir.ast.context;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.builders.IBuilder;

/**
 * Type alias for enum binding plan
 * Maps parameter indices to their final names and usage status
 */
typedef EnumBindingPlan = Map<Int, {finalName: String, isUsed: Bool}>;

/**
 * ElixirASTContext: Shared compilation state and coordination for AST pipeline
 *
 * WHY: Centralizes cross-cutting concerns that span multiple AST phases (Builder,
 * Transformer, Printer). Prevents duplication and ensures consistency of variable
 * mappings, metadata, and compiler state across the entire pipeline.
 *
 * WHAT: Provides unified management of:
 * - Variable name mappings across scopes
 * - Pattern variable registry for enum matching
 * - Metadata storage for transformation decisions
 * - ClauseContext integration for switch cases
 * - Test progress tracking for incremental compilation
 * - Naming conventions and transformations
 *
 * HOW: Acts as a shared context object passed through compilation phases:
 * - Created at compilation start with initial state
 * - Populated during building phase with mappings and metadata
 * - Consulted during transformation for decisions
 * - Used during printing for final name resolution
 * - Maintains priority hierarchy for variable resolution
 *
 * ARCHITECTURE BENEFITS:
 * - Single Source of Truth: All phases use same context
 * - Coordination: Solves competing variable mapping systems
 * - Testability: Context can be mocked/tested independently
 * - Extensibility: New concerns added without changing phases
 * - Performance: Avoids redundant computations
 *
 * EDGE CASES:
 * - Variable shadowing across nested scopes
 * - Pattern variables vs temp variables conflicts
 * - Cross-phase metadata synchronization
 * - Priority resolution for competing mappings
 *
 * @see ElixirASTBuilder for context creation and population
 * @see ElixirASTTransformer for context consultation
 * @see ClauseContext for case-specific variable management
 */
class ElixirASTContext {
    // ===== Variable Mapping Systems =====

    /**
     * Global variable mapping: TVar.id -> Elixir name
     * Used for top-level and function-level variables
     */
    public var globalVariableMap: Map<Int, String> = new Map();

    /**
     * Pattern variable registry: TVar.id -> pattern name
     * Has highest priority - preserves user-specified names from patterns
     */
    public var patternVariableRegistry: Map<Int, String> = new Map();

    /**
     * Renamed variable tracking: TVar.id -> {original, renamed}
     * Tracks when Haxe renames variables to avoid shadowing (e.g., options → options2)
     * This allows us to detect and handle field references that use original names
     * while the variable has been renamed
     */
    public var renamedVariableMap: Map<Int, {original: String, renamed: String}> = new Map();

    /**
     * Temp variable mappings: temp name -> actual name
     * Maps generated temps (g, g1) to meaningful names
     */
    public var tempVariableMap: Map<String, String> = new Map();

    /**
     * Active clause contexts stack
     * Push/pop as we enter/exit switch cases
     */
    public var clauseContextStack: Array<ClauseContext> = [];

    // ===== Metadata Storage =====

    /**
     * Node metadata by unique ID
     * Stores transformation hints, patterns detected, etc.
     */
    public var nodeMetadata: Map<String, Dynamic> = new Map();

    /**
     * Enum type information cache
     * Avoids repeated lookups during compilation
     */
    public var enumTypeCache: Map<String, EnumType> = new Map();

    /**
     * Idiomatic enum markers
     * Tracks which enums have @:elixirIdiomatic metadata
     */
    public var idiomaticEnums: Map<String, Bool> = new Map();

    /**
     * Pattern context flag
     * True when building pattern matching expressions (case patterns)
     */
    public var isInPattern: Bool = false;

    /**
     * Enum binding plans storage
     * Maps unique IDs to EnumBindingPlan instances for cross-phase access
     * This allows the binding plans to survive from builder to transformer phase
     */
    public var enumBindingPlans: Map<String, EnumBindingPlan> = new Map();

    // ===== Test Progress Tracking =====

    /**
     * Current test being compiled
     * Used for incremental test runner integration
     */
    public var currentTestPath: String = null;

    /**
     * Test compilation results
     * Maps test path to success/failure status
     */
    public var testResults: Map<String, TestResult> = new Map();

    // ===== Naming Conventions =====

    /**
     * Module name transformations
     * CamelCase -> snake_case mappings
     */
    public var moduleNameMap: Map<String, String> = new Map();

    /**
     * Function name transformations
     * Method names to Elixir function names
     */
    public var functionNameMap: Map<String, String> = new Map();

    // ===== Feature Flags System (Codex Recommendation - January 2025) =====

    /**
     * Feature flags for gradual migration to new builders
     *
     * These flags control which specialized builders are active at runtime.
     * They work in two ways:
     *
     * 1. Build-time configuration via Haxe compiler definitions:
     *    haxe build.hxml -D use_new_pattern_builder
     *    This sets the default state for the entire compilation
     *
     * 2. Runtime configuration via setFeatureFlag():
     *    context.setFeatureFlag("use_new_pattern_builder", true)
     *    This allows dynamic control during compilation phases
     *
     * The combination allows:
     * - CI/CD to enable features via build flags
     * - Gradual rollout with percentage-based routing
     * - Emergency rollback without recompilation
     * - A/B testing of implementations
     *
     * Convention: Feature flags follow pattern "use_new_${builderType}_builder"
     * Examples: use_new_pattern_builder, use_new_loop_builder
     */
    public var featureFlags: Map<String, Bool> = new Map();

    /**
     * Registered specialized builders implementing IBuilder interface
     * Maps builder type to concrete implementation for type-safe routing
     *
     * Type safety achieved via IBuilder interface instead of Dynamic
     * Allows polymorphic storage while maintaining compile-time checks
     */
    public var registeredBuilders: Map<String, IBuilder> = new Map();

    // ===== Lifecycle Management (Codex Recommendation - January 2025) =====

    /**
     * Compilation phase tracking
     * Ensures proper initialization and cleanup
     */
    public var currentPhase: CompilationPhase = CompilationPhase.NotStarted;

    /**
     * Node ID counter for unique identification
     * Reset at start of each compilation
     */
    private var nodeIdCounter: Int = 0;

    // ===== Constructor =====

    public function new() {
        // Initialize with empty state
        // Will be populated during compilation
        initializeFeatureFlags();
    }

    /**
     * Initialize feature flags from compiler definitions
     *
     * Feature flags control which compilation strategies and optimizations are active.
     * They work at two levels:
     *
     * 1. **Builder Routing** (all disabled by default for safety):
     *    - Controls which implementation handles AST building
     *    - Allows gradual migration from monolithic to modular builders
     *    - Default: Use legacy implementation until new builders proven stable
     *
     * 2. **Transformer Passes** (mix of enabled/disabled based on maturity):
     *    - Controls which optimizations and idiomaticizations are applied
     *    - Some enabled by default for better code quality
     *    - Others disabled until thoroughly tested
     *
     * **Default Strategy**:
     * - New builders: DISABLED - Require explicit opt-in for testing
     * - Idiomatic transforms: ENABLED - Generate readable Elixir by default
     * - Experimental optimizations: DISABLED - Avoid surprises in production
     *
     * **Override Methods**:
     * - Build-time: `haxe build.hxml -D use_new_pattern_builder`
     * - Runtime: `context.setFeatureFlag("use_new_pattern_builder", true)`
     * - Percentage rollout: `facade.enableGradualMigration("pattern", 25)`
     *
     * **Testing Strategy**:
     * - CI can enable all flags: `-D enable_all_features`
     * - Debugging can disable all: `-D disable_all_transformations`
     * - A/B testing via percentage routing in BuilderFacade
     *
     * @see BuilderFacade for routing implementation
     * @see ElixirASTTransformer for transformation passes
     */
    private function initializeFeatureFlags(): Void {
        // ================================================================================
        // BUILDER ROUTING FLAGS
        // Default: DISABLED - New builders must prove stability before becoming default
        // ================================================================================

        /**
         * Pattern matching builder (switch/case expressions)
         * DEFAULT: DISABLED - Legacy implementation is battle-tested
         * Enable when: Testing pattern matching improvements
         * Risk: Low - Pattern matching is well-isolated
         */
        #if use_new_pattern_builder
        featureFlags.set("use_new_pattern_builder", true);
        #else
        featureFlags.set("use_new_pattern_builder", false);
        #end

        /**
         * Loop builder (while/for loops)
         * DEFAULT: DISABLED - Complex loop transformations need validation
         * Enable when: Testing comprehension generation
         * Risk: Medium - Loops have many edge cases
         */
        #if use_new_loop_builder
        featureFlags.set("use_new_loop_builder", true);
        #else
        featureFlags.set("use_new_loop_builder", false);
        #end

        /**
         * Function builder (method compilation)
         * DEFAULT: DISABLED - Critical path, needs extensive testing
         * Enable when: Testing function signature improvements
         * Risk: High - Affects all function generation
         */
        #if use_new_function_builder
        featureFlags.set("use_new_function_builder", true);
        #else
        featureFlags.set("use_new_function_builder", false);
        #end

        /**
         * Comprehension builder (array operations)
         * DEFAULT: DISABLED - New implementation not complete
         * Enable when: Testing optimized list operations
         * Risk: Low - Limited scope to array methods
         */
        #if use_new_comprehension_builder
        featureFlags.set("use_new_comprehension_builder", true);
        #else
        featureFlags.set("use_new_comprehension_builder", false);
        #end

        // ================================================================================
        // TRANSFORMER OPTIMIZATION FLAGS
        // Mix of enabled/disabled based on stability and impact
        // ================================================================================

        /**
         * Loop to comprehension transformation
         * DEFAULT: ENABLED - Produces idiomatic Elixir code
         *
         * WHY USEFUL: Converts imperative loops to functional comprehensions
         * - Transforms: `while(i<10) { array.push(i*2); i++; }`
         * - Into: `for i <- 0..9, do: i * 2`
         *
         * WHEN TO DISABLE:
         * - Debugging loop compilation issues
         * - Preserving exact imperative semantics
         * - Performance testing (rare cases where loops are faster)
         *
         * BENEFITS:
         * - More readable Elixir code
         * - Better BEAM optimization
         * - Follows Elixir community conventions
         */
        #if enable_loop_to_comprehension
        featureFlags.set("enable_loop_to_comprehension", true);
        #else
        featureFlags.set("enable_loop_to_comprehension", true); // Default enabled for idiomatic code
        #end

        /**
         * Idiomatic enum pattern generation
         * DEFAULT: ENABLED - Critical for readable pattern matching
         *
         * WHY USEFUL: Uses Elixir atoms instead of integer indices
         * - Transforms: `case elem(result, 0) do 0 -> ...`
         * - Into: `case result do {:ok, value} -> ...`
         *
         * WHEN TO DISABLE:
         * - Debugging pattern matching issues
         * - Comparing with Haxe's internal representation
         * - Testing index-based optimizations
         *
         * BENEFITS:
         * - Human-readable patterns
         * - Elixir developer friendly
         * - Better error messages
         */
        #if enable_idiomatic_enums
        featureFlags.set("enable_idiomatic_enums", true);
        #else
        featureFlags.set("enable_idiomatic_enums", true); // Default enabled
        #end

        /**
         * Skip redundant extraction in patterns
         * DEFAULT: DISABLED - Safety first, optimization second
         *
         * WHY USEFUL: Removes unnecessary elem() calls after pattern matching
         * - Removes: `{:ok, g} -> g = elem(result, 1)` (g already extracted)
         * - Keeps just: `{:ok, g} ->`
         *
         * WHEN TO ENABLE:
         * - Production builds for cleaner output
         * - After thorough testing
         * - When targeting Elixir developers reading generated code
         *
         * RISKS:
         * - May break edge cases with complex patterns
         * - Needs comprehensive test coverage
         * - Could affect debugging visibility
         */
        #if disable_redundant_extraction
        featureFlags.set("disable_redundant_extraction", true);
        #else
        featureFlags.set("disable_redundant_extraction", false); // Default keep for safety
        #end

        /**
         * Pipe operator transformation
         * DEFAULT: DISABLED - Experimental feature
         *
         * WHY USEFUL: Generates idiomatic Elixir pipelines
         * - Transforms: `process(validate(transform(data)))`
         * - Into: `data |> transform() |> validate() |> process()`
         *
         * WHEN TO ENABLE:
         * - Targeting Elixir-first codebases
         * - After validating transformation correctness
         * - For better code readability
         *
         * CHALLENGES:
         * - Complex to detect safe transformation points
         * - Must preserve evaluation order
         * - Needs to handle error cases
         */
        #if enable_pipe_operator
        featureFlags.set("enable_pipe_operator", true);
        #else
        featureFlags.set("enable_pipe_operator", false); // Default off until stable
        #end

        /**
         * Preserve integer indices in pattern matching
         * DEFAULT: DISABLED - Atoms are more idiomatic
         *
         * WHY USEFUL: Maintains Haxe's internal representation
         * - Keeps: `case elem(enum, 0) do 0 -> ...`
         * - Instead of: `case enum do {:constructor, ...} -> ...`
         *
         * WHEN TO ENABLE:
         * - Debugging enum compilation
         * - Performance critical code (marginal benefit)
         * - Interfacing with integer-based external systems
         *
         * TRADE-OFFS:
         * - Less readable code
         * - Harder to debug
         * - Not idiomatic Elixir
         */
        #if preserve_integer_indices
        featureFlags.set("preserve_integer_indices", true);
        #else
        featureFlags.set("preserve_integer_indices", false); // Default use atoms
        #end

        #if debug_ast_builder
        var enabledFlags = [];
        for (flag in featureFlags.keys()) {
            if (featureFlags.get(flag)) {
                enabledFlags.push(flag);
            }
        }
        if (enabledFlags.length > 0) {
            trace('[ElixirASTContext] Feature flags enabled: ${enabledFlags.join(", ")}');
        } else {
            trace('[ElixirASTContext] All feature flags disabled (default safe mode)');
        }
        #end
    }

    // ===== Variable Resolution (Priority Hierarchy) =====

    /**
     * Resolve variable name with priority hierarchy
     *
     * Priority order:
     * 1. Pattern variable registry (user-specified names)
     * 2. Current clause context (case-specific mappings)
     * 3. Global variable map (function/module level)
     * 4. Default variable name (fallback)
     *
     * @param tvarId Variable ID from TypedExpr
     * @param defaultName Default name if no mapping found
     * @return Resolved Elixir variable name
     */
    public function resolveVariable(tvarId: Int, defaultName: String): String {
        // Priority 1: Pattern variables have highest priority
        if (patternVariableRegistry.exists(tvarId)) {
            return patternVariableRegistry.get(tvarId);
        }

        // Priority 2: Check current clause context
        var currentClause = getCurrentClauseContext();
        if (currentClause != null && currentClause.localToName.exists(tvarId)) {
            return currentClause.localToName.get(tvarId);
        }

        // Priority 3: Global variable map
        if (globalVariableMap.exists(tvarId)) {
            return globalVariableMap.get(tvarId);
        }

        // Priority 4: Default name
        return defaultName;
    }

    /**
     * Register a pattern variable extraction
     * These have highest priority in resolution
     */
    public function registerPatternVariable(tvarId: Int, patternName: String): Void {
        patternVariableRegistry.set(tvarId, patternName);
    }

    /**
     * Register a temp variable mapping
     * Maps generated names (g, g1) to meaningful names
     */
    public function registerTempMapping(tempName: String, actualName: String): Void {
        tempVariableMap.set(tempName, actualName);
    }

    /**
     * Register a renamed variable
     * Called when Haxe renames a variable to avoid shadowing
     * @param tvarId The variable ID
     * @param originalName The original variable name (e.g., "options")
     * @param renamedName The renamed variable name (e.g., "options2")
     */
    public function registerRenamedVariable(tvarId: Int, originalName: String, renamedName: String): Void {
        renamedVariableMap.set(tvarId, {original: originalName, renamed: renamedName});
        // Also update the global variable map to use the renamed name
        globalVariableMap.set(tvarId, renamedName);

        #if debug_variable_renaming
        trace('[ElixirASTContext] Registered renamed variable: $originalName -> $renamedName (ID: $tvarId)');
        #end
    }

    /**
     * Get the renamed mapping for a variable
     * @param tvarId The variable ID
     * @return The mapping or null if not renamed
     */
    public function getRenamedMapping(tvarId: Int): Null<{original: String, renamed: String}> {
        return renamedVariableMap.get(tvarId);
    }

    /**
     * Check if a variable name is the original name of a renamed variable
     * Used to detect field references that still use the original name
     * @param name The field name to check
     * @return The renamed variable ID if found, null otherwise
     */
    public function findRenamedVariableByOriginalName(name: String): Null<Int> {
        for (id in renamedVariableMap.keys()) {
            var mapping = renamedVariableMap.get(id);
            if (mapping != null && mapping.original == name) {
                return id;
            }
        }
        return null;
    }

    // ===== Clause Context Management =====

    /**
     * Push a new clause context onto the stack
     * Called when entering a switch case
     */
    public function pushClauseContext(context: ClauseContext): Void {
        clauseContextStack.push(context);
    }

    /**
     * Pop the current clause context
     * Called when exiting a switch case
     */
    public function popClauseContext(): ClauseContext {
        return clauseContextStack.pop();
    }

    /**
     * Get the current active clause context
     * Returns null if not in a switch case
     */
    public function getCurrentClauseContext(): Null<ClauseContext> {
        return clauseContextStack.length > 0 ? clauseContextStack[clauseContextStack.length - 1] : null;
    }

    // ===== Metadata Management =====

    /**
     * Store metadata for an AST node
     * Used to pass information between phases
     */
    public function setNodeMetadata(nodeId: String, metadata: Dynamic): Void {
        nodeMetadata.set(nodeId, metadata);
    }

    /**
     * Retrieve metadata for an AST node
     */
    public function getNodeMetadata(nodeId: String): Dynamic {
        return nodeMetadata.get(nodeId);
    }

    /**
     * Check if an enum is idiomatic
     * Caches the result for performance
     */
    public function isIdiomaticEnum(enumName: String, enumType: EnumType): Bool {
        if (!idiomaticEnums.exists(enumName)) {
            var isIdiomatic = enumType != null && enumType.meta.has(":elixirIdiomatic");
            idiomaticEnums.set(enumName, isIdiomatic);
        }
        return idiomaticEnums.get(enumName);
    }

    /**
     * Store an enum binding plan for later retrieval
     * Used to pass binding plans from builder to transformer phase
     *
     * @param id Unique identifier for this binding plan
     * @param plan The EnumBindingPlan to store
     */
    public function storeEnumBindingPlan(id: String, plan: EnumBindingPlan): Void {
        #if debug_enum_binding_collision
        // Check for collision - same ID being reused
        if (enumBindingPlans.exists(id)) {
            var existingPlan = enumBindingPlans.get(id);
            trace('[COLLISION WARNING] Enum binding plan ID already exists: $id');
            trace('[COLLISION WARNING] Existing plan has ${Lambda.count(existingPlan)} entries');
            trace('[COLLISION WARNING] New plan has ${Lambda.count(plan)} entries');

            // Check if plans are different
            var isDifferent = false;
            for (key in plan.keys()) {
                if (!existingPlan.exists(key) ||
                    existingPlan.get(key).finalName != plan.get(key).finalName) {
                    isDifferent = true;
                    break;
                }
            }
            if (isDifferent) {
                trace('[COLLISION ERROR] Plans are DIFFERENT - this will cause issues!');
            }
        }

        // Log plan creation details
        trace('[ElixirASTContext] Storing enum binding plan:');
        trace('  ID: $id');
        trace('  Plan size: ${Lambda.count(plan)}');
        trace('  Container size after: ${Lambda.count(enumBindingPlans) + 1}');
        #end

        enumBindingPlans.set(id, plan);

        #if debug_enum_extraction
        trace('[ElixirASTContext] Stored enum binding plan with ID: $id');
        #end
    }

    /**
     * Retrieve an enum binding plan by its ID
     * Returns null if no plan exists with the given ID
     *
     * @param id The unique identifier of the binding plan
     * @return The stored EnumBindingPlan or null
     */
    // Track lookup frequency to detect loops
    private var lookupFrequency: Map<String, Int> = new Map();

    public function getEnumBindingPlan(id: String): Null<EnumBindingPlan> {
        #if debug_enum_binding_collision
        // Track lookup frequency
        var frequency = lookupFrequency.get(id);
        if (frequency == null) frequency = 0;
        frequency++;
        lookupFrequency.set(id, frequency);

        // Warn about excessive lookups (possible loop)
        if (frequency > 100) {
            trace('[LOOKUP WARNING] Plan ID "$id" has been looked up $frequency times - possible loop!');
        }
        if (frequency % 50 == 0 && frequency > 0) {
            trace('[LOOKUP INFO] Plan ID "$id" lookup count: $frequency');
        }
        #end

        var plan = enumBindingPlans.get(id);

        #if debug_enum_extraction
        if (plan != null) {
            trace('[ElixirASTContext] Retrieved enum binding plan with ID: $id');
        } else {
            trace('[ElixirASTContext] No enum binding plan found for ID: $id');
        }
        #end

        return plan;
    }

    // ===== Test Progress Integration =====

    /**
     * Mark a test as started
     */
    public function startTest(testPath: String): Void {
        currentTestPath = testPath;
        testResults.set(testPath, TestResult.InProgress);
    }

    /**
     * Mark a test as completed
     */
    public function completeTest(success: Bool): Void {
        if (currentTestPath != null) {
            testResults.set(currentTestPath, success ? TestResult.Success : TestResult.Failure);
            currentTestPath = null;
        }
    }

    /**
     * Get test results for reporting
     */
    public function getTestResults(): Map<String, TestResult> {
        return testResults.copy();
    }

    // ===== Naming Convention Helpers =====

    /**
     * Get or compute module name transformation
     */
    public function getModuleName(originalName: String): String {
        if (!moduleNameMap.exists(originalName)) {
            // Apply transformation and cache
            var transformed = transformModuleName(originalName);
            moduleNameMap.set(originalName, transformed);
        }
        return moduleNameMap.get(originalName);
    }

    /**
     * Get or compute function name transformation
     */
    public function getFunctionName(originalName: String): String {
        if (!functionNameMap.exists(originalName)) {
            // Apply transformation and cache
            var transformed = transformFunctionName(originalName);
            functionNameMap.set(originalName, transformed);
        }
        return functionNameMap.get(originalName);
    }

    // ===== Private Helpers =====

    private function transformModuleName(name: String): String {
        // Implementation would use existing naming utilities
        // This is a placeholder for the actual transformation
        return name; // TODO: Apply snake_case transformation
    }

    private function transformFunctionName(name: String): String {
        // Implementation would use existing naming utilities
        // This is a placeholder for the actual transformation
        return name; // TODO: Apply snake_case transformation
    }

    // ===== Feature Flag Management =====

    /**
     * Check if a feature flag is enabled
     *
     * @param flag Feature flag name
     * @return True if enabled, false otherwise
     */
    public function isFeatureEnabled(flag: String): Bool {
        return featureFlags.exists(flag) && featureFlags.get(flag);
    }

    /**
     * Set a feature flag value
     *
     * @param flag Feature flag name
     * @param enabled Whether to enable or disable
     */
    public function setFeatureFlag(flag: String, enabled: Bool): Void {
        featureFlags.set(flag, enabled);

        #if debug_ast_builder
        trace('[ElixirASTContext] Feature flag ${flag} = ${enabled}');
        #end
    }

    /**
     * Register a specialized builder
     *
     * @param builderType Type identifier (e.g., "pattern", "loop")
     * @param builder The builder instance implementing IBuilder
     */
    public function registerBuilder(builderType: String, builder: IBuilder): Void {
        // Validate builder type matches what it reports
        if (builder.getType() != builderType) {
            throw 'Builder type mismatch: expected ${builderType}, got ${builder.getType()}';
        }

        // Check builder is ready
        if (!builder.isReady()) {
            throw 'Builder ${builderType} is not ready for registration';
        }

        registeredBuilders.set(builderType, builder);

        #if debug_ast_builder
        trace('[ElixirASTContext] Registered ${builderType} builder (ready=${builder.isReady()})');
        #end
    }

    /**
     * Get a registered builder by type
     *
     * @param builderType Type of builder to retrieve
     * @return The builder instance or null if not registered
     */
    public function getBuilder(builderType: String): Null<IBuilder> {
        return registeredBuilders.get(builderType);
    }

    // ===== Lifecycle Management =====

    /**
     * Initialize context for a new compilation run
     * Clears transient state while preserving configuration
     *
     * WHY: Codex identified that state from previous compilations
     * can leak and cause issues. This ensures clean slate.
     */
    public function beginCompilation(): Void {
        // Clear transient state
        globalVariableMap.clear();
        patternVariableRegistry.clear();
        tempVariableMap.clear();
        renamedVariableMap.clear();
        clauseContextStack = [];
        nodeMetadata.clear();
        testResults.clear();
        enumBindingPlans.clear();

        // Keep cached transformations and feature flags
        // moduleNameMap and functionNameMap are kept for performance
        // featureFlags and registeredBuilders persist across runs

        // Reset counters
        nodeIdCounter = 0;
        currentTestPath = null;

        // Update phase
        currentPhase = CompilationPhase.Building;

        #if debug_ast_builder
        trace('[ElixirASTContext] Compilation started - state cleared');
        #end
    }

    /**
     * Transition to transformation phase
     * Validates state and prepares for transformations
     */
    public function beginTransformation(): Void {
        if (currentPhase != CompilationPhase.Building) {
            throw 'Invalid phase transition: ${currentPhase} -> Transformation';
        }

        currentPhase = CompilationPhase.Transforming;

        #if debug_ast_builder
        trace('[ElixirASTContext] Entered transformation phase');
        trace('  - Variable mappings: ${Lambda.count(globalVariableMap)}');
        trace('  - Pattern variables: ${Lambda.count(patternVariableRegistry)}');
        trace('  - Node metadata: ${Lambda.count(nodeMetadata)}');
        #end
    }

    /**
     * Transition to printing phase
     * Final phase before output generation
     */
    public function beginPrinting(): Void {
        if (currentPhase != CompilationPhase.Transforming) {
            throw 'Invalid phase transition: ${currentPhase} -> Printing';
        }

        currentPhase = CompilationPhase.Printing;

        #if debug_ast_builder
        trace('[ElixirASTContext] Entered printing phase');
        #end
    }

    /**
     * Complete compilation and cleanup
     * Marks end of compilation run
     */
    public function endCompilation(): Void {
        currentPhase = CompilationPhase.Completed;

        #if debug_ast_builder
        trace('[ElixirASTContext] Compilation completed');
        if (Lambda.count(testResults) > 0) {
            var successful = 0;
            var failed = 0;
            for (result in testResults) {
                switch (result) {
                    case Success: successful++;
                    case Failure: failed++;
                    case InProgress: // Shouldn't happen
                }
            }
            trace('  Test results: ${successful} passed, ${failed} failed');
        }
        #end
    }

    /**
     * Generate a unique node ID
     * Used for metadata tracking across phases
     *
     * @return Unique identifier for this compilation run
     */
    public function generateNodeId(): String {
        return 'node_${nodeIdCounter++}';
    }

    /**
     * Reset context to initial state
     * Emergency reset for error recovery
     */
    public function reset(): Void {
        // Clear everything
        globalVariableMap.clear();
        patternVariableRegistry.clear();
        tempVariableMap.clear();
        renamedVariableMap.clear();
        clauseContextStack = [];
        nodeMetadata.clear();
        enumTypeCache.clear();
        idiomaticEnums.clear();
        testResults.clear();
        moduleNameMap.clear();
        functionNameMap.clear();
        enumBindingPlans.clear();

        // Reset to defaults
        nodeIdCounter = 0;
        currentTestPath = null;
        currentPhase = CompilationPhase.NotStarted;

        // Reinitialize
        initializeFeatureFlags();

        #if debug_ast_builder
        trace('[ElixirASTContext] FULL RESET - All state cleared');
        #end
    }
}

/**
 * Test result enumeration for progress tracking
 */
enum TestResult {
    InProgress;
    Success;
    Failure;
}

/**
 * Compilation phase tracking
 * Ensures proper lifecycle management
 */
enum CompilationPhase {
    NotStarted;
    Building;
    Transforming;
    Printing;
    Completed;
}

#end