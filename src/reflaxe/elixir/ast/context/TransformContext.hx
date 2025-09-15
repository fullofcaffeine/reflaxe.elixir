package reflaxe.elixir.ast.context;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;

/**
 * TransformContext: Shared interface for AST transformers to access and modify compilation state
 *
 * WHY: Provides a consistent interface for transformation passes to access metadata,
 * perform lookups, and coordinate transformations. Ensures transformers remain
 * focused on their specific concerns while accessing shared context.
 *
 * WHAT: Defines the contract for transformation passes:
 * - Read metadata attached during building phase
 * - Access variable mappings and resolutions
 * - Track transformation state and decisions
 * - Coordinate between transformation passes
 * - Report transformation statistics
 *
 * HOW: Implemented by ElixirASTTransformer and passed to transformation passes:
 * - Each pass receives a TransformContext instance
 * - Passes read metadata to make transformation decisions
 * - Context tracks which transformations have been applied
 * - Ensures passes don't conflict or duplicate work
 *
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Each pass focuses on one transformation
 * - Coordination: Passes can check what others have done
 * - Debugging: Track which transformations affected each node
 * - Performance: Avoid redundant transformations
 * - Extensibility: New passes integrate easily
 *
 * @see ElixirASTTransformer for main implementation
 * @see ElixirASTContext for underlying shared state
 */
interface TransformContext {
    /**
     * Get the shared AST context
     * Provides access to all compilation state
     */
    function getASTContext(): ElixirASTContext;

    /**
     * Get metadata for a node
     * Used to read hints from builder phase
     *
     * @param nodeId Node identifier
     * @return Metadata or null if none
     */
    function getNodeMetadata(nodeId: String): Dynamic;

    /**
     * Update metadata for a node
     * Used to pass information between passes
     *
     * @param nodeId Node identifier
     * @param metadata New or updated metadata
     */
    function setNodeMetadata(nodeId: String, metadata: Dynamic): Void;

    /**
     * Check if a transformation has been applied to a node
     * Prevents duplicate transformations
     *
     * @param nodeId Node identifier
     * @param transformName Name of transformation
     * @return True if already applied
     */
    function hasTransformation(nodeId: String, transformName: String): Bool;

    /**
     * Mark a transformation as applied to a node
     * Records that a pass has modified this node
     *
     * @param nodeId Node identifier
     * @param transformName Name of transformation
     */
    function markTransformed(nodeId: String, transformName: String): Void;

    /**
     * Get all transformations applied to a node
     * Useful for debugging and understanding changes
     *
     * @param nodeId Node identifier
     * @return Array of transformation names
     */
    function getAppliedTransformations(nodeId: String): Array<String>;

    /**
     * Resolve a variable name
     * Uses priority hierarchy from AST context
     *
     * @param tvarId Variable ID
     * @param defaultName Default if not found
     * @return Resolved name
     */
    function resolveVariable(tvarId: Int, defaultName: String): String;

    /**
     * Check if in idiomatic transformation mode
     * Some transformations only apply to idiomatic types
     *
     * @return True if generating idiomatic patterns
     */
    function isIdiomaticMode(): Bool;

    /**
     * Set idiomatic transformation mode
     * Controls which transformation patterns apply
     *
     * @param idiomatic New mode setting
     */
    function setIdiomaticMode(idiomatic: Bool): Void;

    /**
     * Get the current transformation pass name
     * Identifies which pass is currently running
     *
     * @return Current pass name
     */
    function getCurrentPass(): String;

    /**
     * Set the current transformation pass
     * Updated as passes execute
     *
     * @param passName Name of the pass
     */
    function setCurrentPass(passName: String): Void;

    /**
     * Check if a pattern should be transformed
     * Based on metadata and configuration
     *
     * @param pattern Pattern type to check
     * @return True if transformation should apply
     */
    function shouldTransformPattern(pattern: String): Bool;

    /**
     * Register a pattern detection
     * Records what patterns were found
     *
     * @param nodeId Node where pattern detected
     * @param pattern Pattern type detected
     */
    function registerPatternDetection(nodeId: String, pattern: String): Void;

    /**
     * Get statistics for a transformation pass
     * Used for reporting and optimization
     *
     * @param passName Pass to get stats for
     * @return Statistics object
     */
    function getPassStatistics(passName: String): TransformStats;

    /**
     * Record a transformation metric
     * Tracks performance and effectiveness
     *
     * @param metric Metric name
     * @param value Metric value
     */
    function recordMetric(metric: String, value: Dynamic): Void;

    /**
     * Check if node has specific metadata flag
     * Convenience method for boolean flags
     *
     * @param nodeId Node identifier
     * @param flag Flag name to check
     * @return True if flag is set
     */
    function hasMetadataFlag(nodeId: String, flag: String): Bool;

    /**
     * Get configuration value
     * Access transformation configuration
     *
     * @param key Configuration key
     * @return Configuration value or null
     */
    function getConfig(key: String): Dynamic;

    /**
     * Create a sub-context for nested transformations
     * Used when recursively transforming children
     *
     * @return New context inheriting current state
     */
    function createSubContext(): TransformContext;

    /**
     * Report transformation warning
     * Non-fatal issues during transformation
     *
     * @param message Warning message
     */
    function warning(message: String): Void;

    /**
     * Report transformation info
     * Debugging information about transformations
     *
     * @param message Info message
     */
    function info(message: String): Void;
}

/**
 * Transformation statistics tracking
 */
typedef TransformStats = {
    /**
     * Number of nodes examined
     */
    var nodesExamined: Int;

    /**
     * Number of nodes transformed
     */
    var nodesTransformed: Int;

    /**
     * Patterns detected
     */
    var patternsDetected: Map<String, Int>;

    /**
     * Time spent in pass (milliseconds)
     */
    var executionTime: Float;

    /**
     * Custom metrics
     */
    var customMetrics: Map<String, Dynamic>;
}

#end