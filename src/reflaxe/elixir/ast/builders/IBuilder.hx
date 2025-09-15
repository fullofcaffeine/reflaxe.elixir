package reflaxe.elixir.ast.builders;

#if (macro || reflaxe_runtime)

/**
 * IBuilder: Common interface for all specialized AST builders
 *
 * WHY: Provides type safety instead of using Dynamic for builder registration.
 * Ensures all builders have a consistent interface and can be type-checked.
 *
 * WHAT: Defines the minimal contract that all builders must implement:
 * - Identification via getType()
 * - Status reporting via isReady()
 *
 * HOW: Each specialized builder implements this interface, allowing:
 * - Type-safe storage in registeredBuilders Map
 * - Consistent error handling across builders
 * - Clear contract for builder implementations
 *
 * @see PatternMatchBuilder for implementation example
 * @see BuilderFacade for usage in routing
 */
interface IBuilder {
    /**
     * Get the builder type identifier
     * Used for routing and feature flag association
     *
     * @return Builder type (e.g., "pattern", "loop", "function")
     */
    function getType(): String;

    /**
     * Check if builder is ready for use
     * Can validate dependencies and configuration
     *
     * @return True if builder can be used
     */
    function isReady(): Bool;
}

#end