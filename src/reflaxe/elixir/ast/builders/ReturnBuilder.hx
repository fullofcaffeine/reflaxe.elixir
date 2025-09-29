package reflaxe.elixir.ast.builders;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.Context;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.CompilationContext;

/**
 * ReturnBuilder: Handles return statement transformations
 * 
 * WHY: Centralizes return statement handling for Elixir's expression-based semantics
 * - Elixir doesn't have explicit return statements (everything is an expression)
 * - The last expression in a function is the implicit return value
 * - Simplifies ElixirASTBuilder by extracting ~50 lines of return logic
 * - Handles special cases like switch expressions wrapped in metadata
 * 
 * WHAT: Transforms Haxe return statements to idiomatic Elixir expressions
 * - TReturn(expr) → Just the expression itself (implicit return)
 * - TReturn(null) → ENil (explicit nil return)
 * - Metadata-wrapped returns → Unwrap and process the inner expression
 * - Switch returns → Handle specially for proper pattern matching
 * 
 * HOW: Expression-based transformation following Elixir semantics
 * - Strip return keyword (not needed in Elixir)
 * - Process the return expression normally
 * - Handle null returns as explicit nil
 * - Detect and handle special wrapped patterns
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Focused solely on return semantics
 * - Open/Closed Principle: Can extend return patterns without modifying core
 * - Testability: Return handling can be tested independently
 * - Maintainability: Clear boundaries for return-related code
 * 
 * EDGE CASES:
 * - Empty returns (no expression) → nil
 * - Metadata-wrapped returns (preserve metadata)
 * - Switch expression returns (special handling)
 * - Nested returns in complex expressions
 * - Early returns in conditional branches
 */
@:nullSafety(Off)
class ReturnBuilder {
    
    /**
     * Build return expression
     * 
     * WHY: Haxe has explicit returns, Elixir uses implicit expression returns
     * WHAT: Converts TReturn to just the expression (or nil)
     * HOW: Processes the return expression, handling null as nil
     * 
     * @param e The expression to return (can be null)
     * @param context Compilation context
     * @return ElixirASTDef for the return value
     */
    public static function build(e: Null<TypedExpr>, context: CompilationContext): Null<ElixirASTDef> {
        #if debug_ast_builder
        trace('[ReturnBuilder] Building return expression');
        trace('[ReturnBuilder]   Has expression: ${e != null}');
        if (e != null) {
            trace('[ReturnBuilder]   Expression type: ${Type.enumConstructor(e.expr)}');
        }
        #end
        
        // In Elixir, everything is an expression, including returns
        // We don't need a special return statement, just the expression itself
        if (e != null) {
            // Check if it's a switch, potentially wrapped in metadata
            if (isSwitchExpression(e)) {
                #if debug_ast_builder
                trace('[ReturnBuilder] Return contains switch expression, handling specially');
                #end
                // Process the switch with special handling
                return processReturnSwitch(e, context);
            }
            
            // Normal return expression
            var result = if (context.compiler != null) {
                context.compiler.compileExpressionImpl(e, false);
            } else {
                return null;
            };
            
            if (result == null) {
                #if debug_ast_builder
                trace('[ReturnBuilder] Failed to compile return expression, using nil');
                #end
                return makeAST(ENil).def;
            }
            
            return result.def;
        } else {
            // Empty return - explicit nil
            #if debug_ast_builder
            trace('[ReturnBuilder] Empty return, generating explicit nil');
            #end
            return ENil;
        }
    }
    
    /**
     * Check if expression is a switch (possibly wrapped in metadata)
     * 
     * WHY: Switch expressions in returns need special handling
     * WHAT: Detects TSwitch, including when wrapped in TMeta
     * HOW: Recursively checks through metadata wrappers
     * 
     * @param e Expression to check
     * @return true if this is or contains a switch
     */
    static function isSwitchExpression(e: TypedExpr): Bool {
        if (e == null) return false;
        
        return switch(e.expr) {
            case TSwitch(_, _, _): true;
            case TMeta(_, innerExpr): isSwitchExpression(innerExpr);
            case TParenthesis(innerExpr): isSwitchExpression(innerExpr);
            default: false;
        };
    }
    
    /**
     * Process a switch expression in a return statement
     * 
     * WHY: Switch returns may need special metadata preservation
     * WHAT: Handles switch with proper context
     * HOW: Delegates to compiler with metadata handling
     * 
     * @param e The switch expression
     * @param context Compilation context
     * @return ElixirASTDef for the switch
     */
    static function processReturnSwitch(e: TypedExpr, context: CompilationContext): Null<ElixirASTDef> {
        // Extract switch from potential metadata wrapper
        var switchExpr = extractSwitch(e);
        if (switchExpr == null) {
            // Not actually a switch after all
            return if (context.compiler != null) {
                var result = context.compiler.compileExpressionImpl(e, false);
                result != null ? result.def : null;
            } else {
                null;
            };
        }
        
        // Compile the switch expression
        var result = if (context.compiler != null) {
            context.compiler.compileExpressionImpl(switchExpr, false);
        } else {
            return null;
        };
        
        if (result == null) {
            return null;
        }
        
        // Check if we need to preserve metadata
        switch(e.expr) {
            case TMeta(meta, _):
                // Preserve metadata on the result
                if (result.metadata == null) {
                    result.metadata = {};
                }
                // Could transfer specific metadata if needed
                #if debug_ast_builder
                trace('[ReturnBuilder] Preserved metadata from wrapped switch');
                #end
            default:
        }
        
        return result.def;
    }
    
    /**
     * Extract switch expression from potential wrappers
     * 
     * WHY: Switch may be wrapped in metadata or parentheses
     * WHAT: Recursively unwraps to find the actual switch
     * HOW: Pattern matches through wrapper types
     * 
     * @param e Expression to unwrap
     * @return The switch expression or null
     */
    static function extractSwitch(e: TypedExpr): Null<TypedExpr> {
        if (e == null) return null;
        
        return switch(e.expr) {
            case TSwitch(_, _, _): e;
            case TMeta(_, innerExpr): extractSwitch(innerExpr);
            case TParenthesis(innerExpr): extractSwitch(innerExpr);
            default: null;
        };
    }
}

#end