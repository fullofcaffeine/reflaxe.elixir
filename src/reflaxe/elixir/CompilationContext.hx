package reflaxe.elixir;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.context.ClauseContext;
import reflaxe.elixir.behaviors.BehaviorTransformer;
import reflaxe.elixir.ast.context.ElixirASTContext;
import reflaxe.elixir.ast.context.BuildContext;
import reflaxe.elixir.ast.builders.BuilderFacade;
import reflaxe.elixir.ast.builders.IBuilder;
import reflaxe.elixir.ast.ReentrancyGuard;
import haxe.macro.Expr.Position;

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
class CompilationContext implements BuildContext {
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
     *
     * Enhanced to support clause-indexed patterns as recommended by Codex:
     * - Preserves pattern variable names through compilation
     * - Has highest priority in variable resolution
     * - Prevents temp variable names (g, g1, g2) from leaking into generated code
     */
    public var patternVariableRegistry: Map<Int, String>;

    /**
     * Clause-indexed pattern variable registry for more granular control
     * Maps clauseIndex -> paramIndex -> variable name
     * This allows tracking pattern variables specific to each case clause
     *
     * WHY: Different case clauses may use different variable names for the same
     * enum parameter position, and we need to preserve each clause's naming
     */
    public var clausePatternRegistry: Map<Int, Map<Int, String>>;

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
    // AST Modularization Infrastructure (Phase 2 Integration)
    // ========================================================================

    /**
     * Shared AST context for modular builders
     * Provides centralized state management for all AST builders
     */
    public var astContext: ElixirASTContext;

    /**
     * Builder facade for gradual migration to modular architecture
     * Routes compilation to specialized builders based on feature flags
     */
    public var builderFacade: Null<BuilderFacade>;

    /**
     * Current position for error reporting
     * Updated as we traverse the AST
     */
    private var currentPosition: Position;

    /**
     * Reentrancy guard to prevent infinite recursion
     * Used when LoopBuilder and other analyzers need to call buildExpr
     */
    public var reentrancyGuard: ReentrancyGuard;

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
        clausePatternRegistry = new Map();

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

        // Initialize AST modularization infrastructure
        astContext = new ElixirASTContext();
        builderFacade = null; // Will be initialized when needed
        currentPosition = null;

        // Initialize reentrancy guard
        reentrancyGuard = new ReentrancyGuard();
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
    // BuildContext Interface Implementation (Phase 2 Integration)
    // ========================================================================

    /**
     * Get the shared AST context
     */
    public function getASTContext(): ElixirASTContext {
        return astContext;
    }

    /**
     * Resolve a variable name using priority hierarchy
     *
     * Priority order (highest to lowest):
     * 1. Pattern variable registry (user-specified pattern names)
     * 2. Current clause context (case-specific mappings)
     * 3. Underscore prefix check (unused variables)
     * 4. Default variable name (fallback)
     *
     * This hierarchy ensures pattern variables preserve their names
     * and don't get replaced with temp variables (g, g1, g2).
     */
    public function resolveVariable(tvarId: Int, defaultName: String): String {
        // Priority 1: Pattern variable registry (highest priority)
        if (patternVariableRegistry.exists(tvarId)) {
            var resolved = patternVariableRegistry.get(tvarId);
            #if debug_pattern_matching
            trace('[ResolveVariable] TVar#${tvarId}: Using pattern registry -> "${resolved}"');
            #end
            return resolved;
        }

        // Priority 2: Current clause context
        if (currentClauseContext != null && currentClauseContext.localToName.exists(tvarId)) {
            var resolved = currentClauseContext.localToName.get(tvarId);
            #if debug_pattern_matching
            trace('[ResolveVariable] TVar#${tvarId}: Using clause context -> "${resolved}"');
            #end
            return resolved;
        }

        // Priority 3: Underscore prefix check
        if (shouldPrefixWithUnderscore(tvarId)) {
            var resolved = "_" + defaultName;
            #if debug_pattern_matching
            trace('[ResolveVariable] TVar#${tvarId}: Adding underscore prefix -> "${resolved}"');
            #end
            return resolved;
        }

        // Priority 4: Default name
        #if debug_pattern_matching
        trace('[ResolveVariable] TVar#${tvarId}: Using default -> "${defaultName}"');
        #end
        return defaultName;
    }

    /**
     * Register a pattern variable from enum matching
     *
     * WHY: Preserves user-specified pattern variable names through compilation
     * to generate idiomatic Elixir patterns instead of temp variables
     */
    public function registerPatternVariable(tvarId: Int, patternName: String): Void {
        patternVariableRegistry.set(tvarId, patternName);

        #if debug_pattern_matching
        trace('[PatternRegistry] Registered TVar#${tvarId} -> "${patternName}"');
        #end
    }

    /**
     * Register a pattern variable for a specific clause and parameter index
     *
     * WHY: Different case clauses may have different variable names for the
     * same enum parameter position. This granular tracking ensures each
     * clause's naming is preserved independently.
     *
     * @param clauseIndex The index of the case clause
     * @param paramIndex The parameter position in the enum constructor
     * @param name The pattern variable name to use
     * @param tvarId Optional TVar ID to also register globally
     */
    public function registerClausePatternVariable(clauseIndex: Int, paramIndex: Int, name: String, ?tvarId: Int): Void {
        if (!clausePatternRegistry.exists(clauseIndex)) {
            clausePatternRegistry.set(clauseIndex, new Map<Int, String>());
        }

        clausePatternRegistry.get(clauseIndex).set(paramIndex, name);

        // Also register globally if TVar ID provided
        if (tvarId != null) {
            registerPatternVariable(tvarId, name);
        }

        #if debug_pattern_matching
        trace('[PatternRegistry] Clause#${clauseIndex} Param#${paramIndex} -> "${name}"' +
              (tvarId != null ? ' (TVar#${tvarId})' : ''));
        #end
    }

    /**
     * Resolve a pattern variable name for a specific clause and parameter
     *
     * @param clauseIndex The case clause index
     * @param paramIndex The parameter position
     * @return The registered name or null if not found
     */
    public function resolveClausePatternVariable(clauseIndex: Int, paramIndex: Int): Null<String> {
        if (clausePatternRegistry.exists(clauseIndex)) {
            return clausePatternRegistry.get(clauseIndex).get(paramIndex);
        }
        return null;
    }

    /**
     * Get current position for error reporting
     */
    public function getCurrentPosition(): Position {
        return currentPosition;
    }

    /**
     * Set current position for error tracking
     */
    public function setCurrentPosition(pos: Position): Void {
        currentPosition = pos;
    }

    /**
     * Get the current module type being compiled
     */
    public function getCurrentModule(): Null<ModuleType> {
        // This would need to be added to track the actual ModuleType
        // For now return null as we track module name only
        return null;
    }

    /**
     * Get the current class type being compiled
     */
    public function getCurrentClass(): Null<ClassType> {
        // This would need to be added to track the actual ClassType
        // For now return null
        return null;
    }

    /**
     * Store metadata for an AST node
     */
    public function setNodeMetadata(nodeId: String, metadata: Dynamic): Void {
        // Delegate to astContext
        astContext.setNodeMetadata(nodeId, metadata);
    }

    /**
     * Generate a unique node ID for metadata tracking
     */
    public function generateNodeId(): String {
        return astContext.generateNodeId();
    }

    /**
     * Check if a type is an idiomatic enum
     */
    public function isIdiomaticEnum(enumType: EnumType): Bool {
        return enumType.meta.has(":elixirIdiomatic");
    }

    /**
     * Get or create a clause context for a switch case
     */
    public function getClauseContext(caseIndex: Int): ClauseContext {
        // For now, create a new one each time
        // Could be enhanced to cache by index
        return new ClauseContext();
    }

    /**
     * Get module name with proper transformation
     */
    public function getModuleName(originalName: String): String {
        // Apply snake_case transformation
        return toSnakeCase(originalName);
    }

    /**
     * Get function name with proper transformation
     */
    public function getFunctionName(originalName: String): String {
        // Apply snake_case transformation
        return toSnakeCase(originalName);
    }

    /**
     * Check if currently building within a pattern
     */
    public function isInPattern(): Bool {
        return astContext.isInPattern;
    }

    /**
     * Set pattern context state
     */
    public function setInPattern(inPattern: Bool): Void {
        astContext.isInPattern = inPattern;
    }

    /**
     * Get the current function being compiled
     */
    public function getCurrentFunction(): Null<ClassField> {
        // This would need to be tracked
        return null;
    }

    /**
     * Report a compilation warning
     */
    public function warning(message: String, ?pos: Position): Void {
        #if macro
        haxe.macro.Context.warning(message, pos != null ? pos : haxe.macro.Context.currentPos());
        #end
    }

    /**
     * Report a compilation error
     */
    public function error(message: String, ?pos: Position): Void {
        #if macro
        haxe.macro.Context.error(message, pos != null ? pos : haxe.macro.Context.currentPos());
        #end
    }

    /**
     * Get expression builder callback for delegation
     */
    public function getExpressionBuilder(): (TypedExpr) -> ElixirAST {
        // Return a function that calls ElixirASTBuilder
        return function(expr: TypedExpr): ElixirAST {
            return reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(expr, this);
        };
    }

    /**
     * Get type builder callback for delegation
     */
    public function getTypeBuilder(): (Type) -> ElixirAST {
        // Would need implementation
        return function(type: Type): ElixirAST {
            return makeAST(EAtom("todo_type"));
        };
    }

    /**
     * Get pattern builder callback for delegation
     */
    public function getPatternBuilder(clauseContext: ClauseContext): (TypedExpr) -> ElixirAST {
        // Would delegate to pattern building logic
        return function(expr: TypedExpr): ElixirAST {
            var oldContext = currentClauseContext;
            currentClauseContext = clauseContext;
            var result = reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(expr, this);
            currentClauseContext = oldContext;
            return result;
        };
    }

    /**
     * Register a specialized builder for feature-flagged routing
     */
    public function registerBuilder(builderType: String, builder: IBuilder): Void {
        astContext.registerBuilder(builderType, builder);
    }

    /**
     * Check if a feature flag is enabled
     */
    public function isFeatureEnabled(flag: String): Bool {
        return astContext.isFeatureEnabled(flag);
    }

    /**
     * Enable or disable a feature flag
     */
    public function setFeatureFlag(flag: String, enabled: Bool): Void {
        astContext.setFeatureFlag(flag, enabled);
    }

    /**
     * Helper function to convert to snake_case
     */
    private static function toSnakeCase(name: String): String {
        var result = "";
        for (i in 0...name.length) {
            var char = name.charAt(i);
            if (char == char.toUpperCase() && i > 0) {
                result += "_" + char.toLowerCase();
            } else {
                result += char.toLowerCase();
            }
        }
        return result;
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
        trace('  AST context initialized: ${astContext != null}');
        trace('  Feature flags: ${astContext.featureFlags}');
    }
    #end
}

#end