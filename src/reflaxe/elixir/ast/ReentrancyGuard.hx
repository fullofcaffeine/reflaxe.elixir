package reflaxe.elixir.ast;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.Expr.Position;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;

/**
 * Processing state for each expression
 */
enum ProcessingState {
    NotStarted;
    InProgress;
    Completed(result: ElixirAST);
}

/**
 * ReentrancyGuard: Prevents Infinite Recursion in AST Building
 *
 * WHY: When analyzers (like LoopBuilder) examine expressions, they may call
 * buildExpr recursively on sub-expressions. If those sub-expressions include
 * the same loop being analyzed, we get infinite recursion. This guard breaks
 * those cycles by tracking expression processing state.
 *
 * WHAT: Provides a tri-state cache that tracks whether each expression is:
 * - NotStarted: Never processed
 * - InProgress: Currently being processed (detects recursion)
 * - Completed: Fully processed with cached result
 *
 * HOW: Before processing any expression that might recurse:
 * 1. Check if already completed (return cached result)
 * 2. Check if in progress (return placeholder to break cycle)
 * 3. Mark as in progress, process, cache result, return
 *
 * ARCHITECTURE BENEFITS:
 * - Prevents stack overflow from infinite recursion
 * - Caches results for performance
 * - Allows complex analyzers to safely traverse AST
 * - Transparent to caller - just wraps build calls
 *
 * EDGE CASES:
 * - Placeholder nodes may need special handling in output
 * - Cache should be cleared between compilation units
 * - Position-based keys may collide in generated code
 */
class ReentrancyGuard {

    /**
     * Cache of expression processing states
     * Uses position as unique identifier (may need refinement)
     */
    var cache: Map<String, ProcessingState>;

    /**
     * Counter for generating unique IDs when position isn't available
     */
    var uniqueIdCounter: Int;

    /**
     * Create a new reentrancy guard
     */
    public function new() {
        cache = new Map();
        uniqueIdCounter = 0;
    }

    /**
     * Process an expression with reentrancy protection
     *
     * WHY: Safely processes expressions that might recurse
     * WHAT: Checks cache state, processes if needed, returns result
     * HOW: Tri-state logic prevents infinite recursion
     *
     * @param expr The typed expression to process
     * @param builder Function that builds the AST (may recurse)
     * @return The built AST or placeholder if recursive
     */
    public function process(expr: TypedExpr, builder: () -> ElixirAST): ElixirAST {
        var key = getExpressionKey(expr);

        #if debug_reentrancy
        // DISABLED: trace('[ReentrancyGuard] Processing expression with key: $key');
        // DISABLED: trace('[ReentrancyGuard] Current state: ${cache.get(key)}');
        #end

        switch(cache.get(key)) {
            case null | NotStarted:
                // First time processing this expression
                cache.set(key, InProgress);

                #if debug_reentrancy
                // DISABLED: trace('[ReentrancyGuard] Starting processing of $key');
                #end

                var result = builder();
                cache.set(key, Completed(result));

                #if debug_reentrancy
                // DISABLED: trace('[ReentrancyGuard] Completed processing of $key');
                #end

                return result;

            case InProgress:
                // Recursion detected! Return placeholder to break cycle
                #if debug_reentrancy
                // DISABLED: trace('[ReentrancyGuard] ⚠️ RECURSION DETECTED for $key - returning placeholder');
                #end

                // Return a nil placeholder to break the cycle
                // This won't affect the output as it's just a temporary placeholder
                return makeAST(ENil);

            case Completed(result):
                // Already processed, return cached result
                #if debug_reentrancy
                // DISABLED: trace('[ReentrancyGuard] Using cached result for $key');
                #end

                return result;
        }
    }

    /**
     * Check if an expression is currently being processed
     *
     * WHY: Allows analyzers to detect recursion without triggering it
     * WHAT: Returns true if expression is marked as InProgress
     * HOW: Simple cache lookup
     */
    public function isInProgress(expr: TypedExpr): Bool {
        var key = getExpressionKey(expr);
        return switch(cache.get(key)) {
            case InProgress: true;
            case _: false;
        };
    }

    /**
     * Clear the cache
     *
     * WHY: Prevents memory leaks between compilation units
     * WHAT: Removes all cached states
     * HOW: Clears the map
     */
    public function clear(): Void {
        cache.clear();
        uniqueIdCounter = 0;

        #if debug_reentrancy
        // DISABLED: trace('[ReentrancyGuard] Cache cleared');
        #end
    }

    /**
     * Generate a unique key for an expression
     *
     * WHY: Need to identify expressions uniquely for caching
     * WHAT: Creates string key from position or unique ID
     * HOW: Uses position when available, generates ID otherwise
     *
     * TODO: This may need refinement - position alone might not be unique
     * in some cases (e.g., generated code). Consider using expr hash.
     */
    function getExpressionKey(expr: TypedExpr): String {
        // Use position as primary key
        if (expr.pos != null) {
            var pos = expr.pos;
            // Create key from position info
            // Note: This assumes position contains file and char range
            return 'expr_${positionToString(pos)}';
        }

        // Fallback: generate unique ID
        // This shouldn't happen in normal compilation
        var id = uniqueIdCounter++;

        #if debug_reentrancy
        // DISABLED: trace('[ReentrancyGuard] Warning: Expression without position, using generated ID: $id');
        #end

        return 'expr_generated_$id';
    }

    /**
     * Convert position to string for use as key
     */
    function positionToString(pos: Position): String {
        // Position is an abstract type in Haxe
        // We'll use a simple string representation
        // This may need adjustment based on actual Position structure
        return Std.string(pos);
    }

    /**
     * Get statistics about the cache
     *
     * WHY: Useful for debugging and performance monitoring
     * WHAT: Returns counts of different states
     * HOW: Iterates cache and counts states
     */
    public function getStats(): {total: Int, inProgress: Int, completed: Int} {
        var stats = {total: 0, inProgress: 0, completed: 0};

        for (state in cache) {
            stats.total++;
            switch(state) {
                case InProgress: stats.inProgress++;
                case Completed(_): stats.completed++;
                case NotStarted: // Shouldn't happen in cache
            }
        }

        return stats;
    }
}

#end