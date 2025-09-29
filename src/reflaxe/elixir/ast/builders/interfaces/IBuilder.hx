package reflaxe.elixir.ast.builders.interfaces;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.context.BuildContext;

/**
 * IBuilder: Base Interface for All AST Builders
 * 
 * WHY: Provides a common contract for all specialized builders, enabling:
 * - Dynamic builder resolution based on expression type
 * - Testability through interface mocking
 * - Clear separation of concerns between builders
 * - Prevention of circular dependencies
 * 
 * WHAT: Defines the minimal API that all builders must implement:
 * - canHandle: Determines if this builder handles a specific expression
 * - build: Converts TypedExpr to ElixirAST
 * - getPriority: Resolution order when multiple builders match
 * 
 * HOW: Builders register themselves with BuilderRegistry and are called
 * based on their canHandle predicate and priority. The BuildContext
 * carries state through the recursive building process.
 * 
 * ARCHITECTURE BENEFITS:
 * - Open/Closed: New builders can be added without modifying existing code
 * - Single Responsibility: Each builder handles one type of expression
 * - Dependency Inversion: High-level builder depends on interface, not implementations
 * - Interface Segregation: Minimal interface - builders only implement what they need
 */
interface IBuilder {
    /**
     * Check if this builder can handle the given expression
     * 
     * @param expr The TypedExpr to check
     * @param context Current build context with state
     * @return True if this builder should handle the expression
     */
    function canHandle(expr: TypedExpr, context: BuildContext): Bool;
    
    /**
     * Build ElixirAST from the given expression
     * 
     * @param expr The TypedExpr to convert
     * @param context Build context with state and helper methods
     * @return The generated ElixirAST node, or null if cannot build
     */
    function build(expr: TypedExpr, context: BuildContext): Null<ElixirAST>;
    
    /**
     * Get builder priority (higher = checked first)
     * Used when multiple builders can handle the same expression
     * 
     * @return Priority value, default is 0
     */
    function getPriority(): Int;
    
    /**
     * Get builder name for debugging
     * 
     * @return Human-readable builder name
     */
    function getName(): String;
}

#end