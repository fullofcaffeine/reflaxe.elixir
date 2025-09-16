package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;

/**
 * FunctionUsageCollector: Tracks function usage within modules
 *
 * WHY: Elixir can warn about unused private functions. By tracking which
 * functions are called, we can generate appropriate @compile directives
 * to suppress warnings for intentionally unused functions.
 *
 * WHAT: Collects information about function declarations and calls to
 * determine which private functions are never used.
 *
 * HOW: Tracks function definitions and call sites during compilation,
 * maintaining maps of function usage patterns.
 *
 * NOTE: This is a stub implementation for Phase 2 integration.
 * Full implementation will be added in Phase 3.
 */
class FunctionUsageCollector {
    public var currentModule: String;

    private var declaredFunctions: Map<String, Bool>;
    private var calledFunctions: Map<String, Bool>;

    public function new() {
        declaredFunctions = new Map();
        calledFunctions = new Map();
        currentModule = "";
    }

    /**
     * Collect function calls from an expression
     */
    public function collectCalls(expr: TypedExpr): Void {
        // Stub implementation
        // Full implementation would traverse and track function calls
    }

    /**
     * Get list of unused private functions
     */
    public function getUnusedPrivateFunctions(): Array<String> {
        // Stub implementation - return empty array
        return [];
    }

    /**
     * Get list of unused private functions with arity info
     */
    public function getUnusedPrivateFunctionsWithArity(): Array<{name: String, arity: Int}> {
        // Stub implementation - return empty array
        return [];
    }

    #if debug_function_usage
    public function printStats(): Void {
        trace('[FunctionUsageCollector] Module: $currentModule');
        trace('[FunctionUsageCollector] Declared: ${Lambda.count(declaredFunctions)} functions');
        trace('[FunctionUsageCollector] Called: ${Lambda.count(calledFunctions)} functions');
    }
    #end
}

#end