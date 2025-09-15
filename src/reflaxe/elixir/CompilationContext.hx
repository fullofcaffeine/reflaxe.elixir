package reflaxe.elixir;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.context.ClauseContext;
import reflaxe.elixir.behaviors.BehaviorTransformer;

/**
 * CompilationContext: Instance-based compilation state container
 *
 * WHY: Eliminate static state contamination that causes variable shadowing bugs
 * when running tests in parallel. Static variables in ElixirASTBuilder persist
 * across compilation units, causing cross-contamination when tests run with -j8.
 *
 * WHAT: Holds all compilation state as instance fields that previously were
 * static variables. Each compilation unit gets a fresh context, ensuring
 * complete isolation between parallel compilations.
 *
 * HOW: Created by ElixirCompiler at the start of each compilation unit and
 * threaded through the entire AST pipeline (Builder → Transformer → Printer).
 * All former static state access is replaced with context field access.
 *
 * ARCHITECTURE BENEFITS:
 * - Enables parallel test execution without contamination
 * - Allows metadata to flow through compilation pipeline
 * - Provides clear state ownership and lifecycle
 * - Makes debugging easier with isolated state per compilation
 *
 * @see ElixirASTBuilder for usage patterns
 * @see ARCHITECTURE_ANALYSIS_2025_09.md for design rationale
 */
class CompilationContext {
    // ========================================================================
    // Variable Tracking Maps (Primary cause of shadowing bugs)
    // ========================================================================

    /**
     * Maps temporary variable names to their renamed versions
     * Used for avoiding naming conflicts and maintaining consistency
     */
    public var tempVarRenameMap: Map<String, String>;

    /**
     * Tracks which variables should have underscore prefixes (unused variables)
     * Maps TVar.id to whether it needs underscore prefix
     */
    public var underscorePrefixedVars: Map<Int, Bool>;


    /**
     * Variable usage tracking map for determining if variables are used
     * Maps TVar.id to usage status
     */
    public var variableUsageMap: Null<Map<Int, Bool>>;

    // ========================================================================
    // Function and Class Context
    // ========================================================================

    /**
     * Tracks function parameter IDs to distinguish them from local variables
     * Maps parameter name to existence flag
     */
    public var functionParameterIds: Map<String, Bool>;

    /**
     * Flag indicating if we're currently compiling inside a class method
     * Affects how 'this' references are handled
     */
    public var isInClassMethodContext: Bool;

    /**
     * Current receiver parameter name for methods (e.g., "this", "self")
     * Used for proper struct method compilation
     */
    public var currentReceiverParamName: Null<String>;

    // ========================================================================
    // Pattern Matching and Clause Context
    // ========================================================================

    /**
     * Registry for pattern variables extracted from enum patterns
     * Maps TVar.id to the pattern variable name
     */
    public var patternVariableRegistry: Map<Int, String>;

    /**
     * Current clause context for pattern matching compilation
     * Manages variable mappings within case clauses
     */
    public var currentClauseContext: Null<ClauseContext>;

    /**
     * Stack of clause contexts for nested pattern matching
     * Allows proper scoping of pattern variables
     */
    private var clauseContextStack: Array<ClauseContext>;

    // ========================================================================
    // Loop and Code Generation Counters
    // ========================================================================

    /**
     * Counter for generating unique loop variable names
     * Incremented for each loop to avoid naming conflicts
     */
    public var loopCounter: Int;

    /**
     * Counter for generating unique while loop labels
     * Used for Y-combinator pattern generation
     */
    public var whileLoopCounter: Int;

    // ========================================================================
    // Module Context
    // ========================================================================

    /**
     * Current module being compiled
     * Used for generating proper module references
     */
    public var currentModule: Null<String>;

    /**
     * Flag indicating if current module has Phoenix.Presence behavior
     * Affects how certain method calls are generated
     */
    public var currentModuleHasPresence: Bool;

    // ========================================================================
    // Compiler References
    // ========================================================================

    /**
     * Reference to the main ElixirCompiler instance
     * Provides access to compiler-wide functionality
     */
    public var compiler: Null<reflaxe.elixir.ElixirCompiler>;

    /**
     * Behavior transformer for Phoenix/OTP behaviors
     * Handles behavior-specific transformations
     */
    public var behaviorTransformer: Null<BehaviorTransformer>;

    // ========================================================================
    // Constructor and Initialization
    // ========================================================================

    /**
     * Creates a new compilation context with fresh state
     * All maps are initialized empty, flags set to defaults
     */
    public function new() {
        // Initialize all maps
        tempVarRenameMap = new Map();
        underscorePrefixedVars = new Map();
        variableUsageMap = new Map();
        functionParameterIds = new Map();
        patternVariableRegistry = new Map();

        // Initialize clause context stack
        clauseContextStack = [];
        currentClauseContext = null;

        // Set default flags
        isInClassMethodContext = false;
        currentReceiverParamName = null;
        currentModule = null;
        currentModuleHasPresence = false;

        // Initialize counters
        loopCounter = 0;
        whileLoopCounter = 0;

        // Compiler references will be set by ElixirCompiler
        compiler = null;
        behaviorTransformer = null;
    }

    // ========================================================================
    // Clause Context Management
    // ========================================================================

    /**
     * Push a new clause context onto the stack
     * Used when entering a new pattern matching scope
     *
     * @param ctx The clause context to push
     */
    public function pushClauseContext(ctx: ClauseContext): Void {
        clauseContextStack.push(ctx);
        currentClauseContext = ctx;
    }

    /**
     * Pop the current clause context from the stack
     * Used when exiting a pattern matching scope
     *
     * @return The popped clause context, or null if stack was empty
     */
    public function popClauseContext(): Null<ClauseContext> {
        if (clauseContextStack.length == 0) {
            currentClauseContext = null;
            return null;
        }

        var popped = clauseContextStack.pop();
        currentClauseContext = clauseContextStack.length > 0 ?
                               clauseContextStack[clauseContextStack.length - 1] :
                               null;
        return popped;
    }

    /**
     * Get the current clause context without modifying the stack
     *
     * @return The current clause context or null if none
     */
    public function getCurrentClauseContext(): Null<ClauseContext> {
        return currentClauseContext;
    }

    // ========================================================================
    // Variable Tracking Helpers
    // ========================================================================

    /**
     * Check if a variable should have an underscore prefix
     *
     * @param varId The TVar.id to check
     * @return True if the variable should be prefixed with underscore
     */
    public function shouldPrefixWithUnderscore(varId: Int): Bool {
        return underscorePrefixedVars.exists(varId) && underscorePrefixedVars.get(varId);
    }

    /**
     * Register a variable as needing underscore prefix
     *
     * @param varId The TVar.id to register
     */
    public function markAsUnderscorePrefixed(varId: Int): Void {
        underscorePrefixedVars.set(varId, true);
    }

    /**
     * Check if a temporary variable has a rename mapping
     *
     * @param tempName The temporary variable name
     * @return The renamed version or null if no mapping exists
     */
    public function getTempVarRename(tempName: String): Null<String> {
        return tempVarRenameMap.get(tempName);
    }

    /**
     * Register a temporary variable rename mapping
     *
     * @param tempName The temporary variable name
     * @param newName The new name to use
     */
    public function registerTempVarRename(tempName: String, newName: String): Void {
        tempVarRenameMap.set(tempName, newName);
    }

    // ========================================================================
    // Module Context Helpers
    // ========================================================================

    /**
     * Set the current module being compiled
     *
     * @param moduleName The module name
     * @param hasPresence Whether the module has Phoenix.Presence behavior
     */
    public function setCurrentModule(moduleName: String, hasPresence: Bool = false): Void {
        currentModule = moduleName;
        currentModuleHasPresence = hasPresence;
    }

    /**
     * Clear the current module context
     * Called when exiting module compilation
     */
    public function clearModuleContext(): Void {
        currentModule = null;
        currentModuleHasPresence = false;
    }

    // ========================================================================
    // Debug Support
    // ========================================================================

    #if debug_compilation_context
    /**
     * Dump the current context state for debugging
     */
    public function dumpState(): Void {
        trace('[CompilationContext] State dump:');
        trace('  tempVarRenameMap entries: ${Lambda.count(tempVarRenameMap)}');
        trace('  underscorePrefixedVars entries: ${Lambda.count(underscorePrefixedVars)}');
        trace('  currentModule: $currentModule');
        trace('  isInClassMethodContext: $isInClassMethodContext');
        trace('  clauseContextStack depth: ${clauseContextStack.length}');
    }
    #end
}

#end