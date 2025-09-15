package reflaxe.elixir.ast.context;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.Expr.Position;
import reflaxe.elixir.ast.ElixirAST;

/**
 * BuildContext: Shared interface for AST builders to access compilation state
 *
 * WHY: Provides a consistent interface for all builder modules to access shared
 * compilation state, variable mappings, and metadata. Prevents tight coupling
 * between builders and the main compiler while ensuring consistent behavior.
 *
 * WHAT: Defines the contract that all builders can rely on:
 * - Access to shared AST context
 * - Variable resolution services
 * - Metadata storage and retrieval
 * - Position tracking for error reporting
 * - Module and type information
 *
 * HOW: Implemented by ElixirASTBuilder and passed to specialized builders:
 * - Each builder receives a BuildContext instance
 * - Builders use context for variable resolution and metadata
 * - Context maintains consistency across builder modules
 * - Changes propagate through shared ElixirASTContext
 *
 * ARCHITECTURE BENEFITS:
 * - Dependency Inversion: Builders depend on interface, not implementation
 * - Testability: Can mock BuildContext for unit testing builders
 * - Modularity: Builders remain independent and focused
 * - Consistency: All builders use same resolution logic
 * - Extensibility: New context features don't break existing builders
 *
 * @see ElixirASTBuilder for main implementation
 * @see BinaryOpBuilder, CoreExprBuilder for usage examples
 * @see ElixirASTContext for underlying shared state
 */
interface BuildContext {
    /**
     * Get the shared AST context
     * Provides access to all compilation state
     */
    function getASTContext(): ElixirASTContext;

    /**
     * Resolve a variable name using priority hierarchy
     * Checks pattern registry, clause context, and global mappings
     *
     * @param tvarId Variable ID from TypedExpr
     * @param defaultName Default name if no mapping found
     * @return Resolved Elixir variable name
     */
    function resolveVariable(tvarId: Int, defaultName: String): String;

    /**
     * Register a pattern variable from enum matching
     * These have highest priority in resolution
     *
     * @param tvarId Variable ID
     * @param patternName User-specified pattern name
     */
    function registerPatternVariable(tvarId: Int, patternName: String): Void;

    /**
     * Get current position for error reporting
     * Used when generating error messages
     *
     * @return Current source position
     */
    function getCurrentPosition(): Position;

    /**
     * Set current position for error tracking
     * Updated as we traverse the AST
     *
     * @param pos New position
     */
    function setCurrentPosition(pos: Position): Void;

    /**
     * Get the current module type being compiled
     * Provides context about the containing module
     *
     * @return Current module type or null
     */
    function getCurrentModule(): Null<ModuleType>;

    /**
     * Get the current class type being compiled
     * Provides context about the containing class
     *
     * @return Current class type or null
     */
    function getCurrentClass(): Null<ClassType>;

    /**
     * Store metadata for an AST node
     * Used to pass hints to transformer phase
     *
     * @param nodeId Unique identifier for the node
     * @param metadata Transformation hints and patterns detected
     */
    function setNodeMetadata(nodeId: String, metadata: Dynamic): Void;

    /**
     * Generate a unique node ID for metadata tracking
     * Ensures each node can be uniquely identified
     *
     * @return Unique node identifier
     */
    function generateNodeId(): String;

    /**
     * Check if a type is an idiomatic enum
     * Determines transformation strategy
     *
     * @param enumType Enum type to check
     * @return True if enum has @:elixirIdiomatic metadata
     */
    function isIdiomaticEnum(enumType: EnumType): Bool;

    /**
     * Get or create a clause context for a switch case
     * Manages variable mappings within case bodies
     *
     * @param caseIndex Index of the case in switch
     * @return ClauseContext for the case
     */
    function getClauseContext(caseIndex: Int): ClauseContext;

    /**
     * Push a clause context onto the stack
     * Called when entering a switch case
     *
     * @param context Context to activate
     */
    function pushClauseContext(context: ClauseContext): Void;

    /**
     * Pop the current clause context
     * Called when exiting a switch case
     *
     * @return Previous context
     */
    function popClauseContext(): ClauseContext;

    /**
     * Get module name with proper transformation
     * Applies naming conventions (snake_case, etc.)
     *
     * @param originalName Original module name
     * @return Transformed Elixir module name
     */
    function getModuleName(originalName: String): String;

    /**
     * Get function name with proper transformation
     * Applies naming conventions for Elixir
     *
     * @param originalName Original function name
     * @return Transformed Elixir function name
     */
    function getFunctionName(originalName: String): String;

    /**
     * Check if currently building within a pattern
     * Affects how certain expressions are compiled
     *
     * @return True if in pattern context
     */
    function isInPattern(): Bool;

    /**
     * Set pattern context state
     * Updated when entering/exiting patterns
     *
     * @param inPattern New pattern state
     */
    function setInPattern(inPattern: Bool): Void;

    /**
     * Get the current function being compiled
     * Provides context about containing function
     *
     * @return Current function or null
     */
    function getCurrentFunction(): Null<ClassField>;

    /**
     * Report a compilation warning
     * Non-fatal issues that should be reported
     *
     * @param message Warning message
     * @param pos Position in source
     */
    function warning(message: String, ?pos: Position): Void;

    /**
     * Report a compilation error
     * Fatal issues that stop compilation
     *
     * @param message Error message
     * @param pos Position in source
     */
    function error(message: String, ?pos: Position): Void;
}

#end