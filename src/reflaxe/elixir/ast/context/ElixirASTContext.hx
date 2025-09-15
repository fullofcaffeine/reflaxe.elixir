package reflaxe.elixir.ast.context;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import reflaxe.elixir.ast.ElixirAST;

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

    // ===== Constructor =====

    public function new() {
        // Initialize with empty state
        // Will be populated during compilation
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
}

/**
 * Test result enumeration for progress tracking
 */
enum TestResult {
    InProgress;
    Success;
    Failure;
}

#end