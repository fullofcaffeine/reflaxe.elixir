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
        if (e != null) {
        }
        #end
        
        // In Elixir, everything is an expression, including returns
        // We don't need a special return statement, just the expression itself
        if (e != null) {
            // Check if it's a switch, potentially wrapped in metadata
            if (isSwitchExpression(e)) {
                #if debug_ast_builder
                #end
                // Process the switch with special handling
                return processReturnSwitch(e, context);
            }
            
            // Normal return expression
            var result = if (context.compiler != null) {
                // CRITICAL FIX: Call ElixirASTBuilder.buildFromTypedExpr directly to preserve context
                // Using compiler.compileExpressionImpl creates a NEW context, losing ClauseContext registrations
                reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(e, context);
            } else {
                return null;
            };
            
            if (result == null) {
                #if debug_ast_builder
                #end
                return makeAST(ENil).def;
            }
            
            return result.def;
        } else {
            // Empty return - explicit nil
            #if debug_ast_builder
            #end
            return ENil;
        }
    }
    
    /**
     * Check if expression is a switch (possibly wrapped in metadata or infrastructure variable pattern)
     *
     * WHY: Switch expressions in returns need special handling
     * WHAT: Detects TSwitch, including when wrapped in TMeta or desugared with infrastructure variables
     * HOW: Recursively checks through metadata wrappers and detects TBlock([TVar(_g), TSwitch(_g)])
     *
     * CRITICAL FIX: Handles Haxe's desugaring of `return switch(expr)` to:
     *   TReturn(TBlock([TVar(_g, expr), TSwitch(TLocal(_g), ...)]))
     *
     * @param e Expression to check
     * @return true if this is or contains a switch
     */
    static function isSwitchExpression(e: TypedExpr): Bool {
        if (e == null) return false;

        return switch(e.expr) {
            case TSwitch(_, _, _): true;

            // CRITICAL: Unwrap TMeta and check inside
            case TMeta(_, innerExpr):
                // Check if inner is infrastructure pattern or recursively check for switch
                switch(innerExpr.expr) {
                    case TBlock(exprs) if (exprs.length >= 2):
                        // Check for infrastructure pattern inside TMeta
                        checkInfrastructurePattern(exprs);
                    default:
                        isSwitchExpression(innerExpr);
                }

            case TParenthesis(innerExpr): isSwitchExpression(innerExpr);

            // CRITICAL FIX: Detect infrastructure variable pattern at top level
            // Pattern: TBlock([TVar(_g, init), TSwitch(TLocal(_g), ...)])
            case TBlock(exprs) if (exprs.length >= 2):
                checkInfrastructurePattern(exprs);

            default: false;
        };
    }

    /**
     * Check if expressions match infrastructure variable pattern
     */
    static function checkInfrastructurePattern(exprs: Array<TypedExpr>): Bool {
        // Check last expression is switch
        var lastExpr = exprs[exprs.length - 1];
        return switch(lastExpr.expr) {
            case TSwitch(target, _, _):
                // CRITICAL: Unwrap TParenthesis from target (Haxe wraps TLocal(_g) in parentheses)
                var unwrappedTarget = switch(target.expr) {
                    case TParenthesis(inner): inner;
                    default: target;
                };

                // Check if switch target is TLocal
                switch(unwrappedTarget.expr) {
                    case TLocal(v):
                        // Check if there's a preceding TVar with same variable
                        for (i in 0...exprs.length - 1) {
                            switch(exprs[i].expr) {
                                case TVar(tvar, init) if (init != null && tvar.id == v.id):
                                    // Found infrastructure variable pattern!
                                    #if debug_ast_builder
                                    #end
                                    return true;
                                default:
                            }
                        }
                        false;
                    default:
                        false;
                }
            default:
                false;
        };
    }
    
    /**
     * Process a switch expression in a return statement
     *
     * WHY: Switch returns may need special metadata preservation and infrastructure variable elimination
     * WHAT: Handles switch with proper context, including desugared patterns
     * HOW: Delegates to compiler with metadata handling and variable substitution
     *
     * CRITICAL FIX: When the switch uses an infrastructure variable (_g), we:
     * 1. Detect the TBlock([TVar(_g, init), TSwitch(TLocal(_g), ...)]) pattern
     * 2. Replace TLocal(_g) with the original init expression
     * 3. Compile the switch with the correct target expression
     *
     * @param e The switch expression
     * @param context Compilation context
     * @return ElixirASTDef for the switch
     */
    static function processReturnSwitch(e: TypedExpr, context: CompilationContext): Null<ElixirASTDef> {
        // CRITICAL FIX: Unwrap TMeta first (infrastructure pattern often wrapped in :ast metadata)
        var unwrappedExpr = switch(e.expr) {
            case TMeta(_, innerExpr): innerExpr;
            default: e;
        };

        // CRITICAL FIX: Check for infrastructure variable pattern
        var processedExpr = switch(unwrappedExpr.expr) {
            case TBlock(exprs) if (exprs.length >= 2):
                var lastExpr = exprs[exprs.length - 1];
                switch(lastExpr.expr) {
                    case TSwitch(target, cases, edef):
                        // CRITICAL: Unwrap TParenthesis from target
                        var unwrappedTarget = switch(target.expr) {
                            case TParenthesis(inner): inner;
                            default: target;
                        };

                        switch(unwrappedTarget.expr) {
                            case TLocal(v):
                                // Find the TVar that initialized this variable
                                var originalExpr: Null<TypedExpr> = null;
                                for (i in 0...exprs.length - 1) {
                                    switch(exprs[i].expr) {
                                        case TVar(tvar, init) if (init != null && tvar.id == v.id):
                                            #if debug_ast_builder
                                            #end
                                            originalExpr = init;
                                            break;
                                        default:
                                    }
                                }

                                if (originalExpr != null) {
                                    // Create new TSwitch with original expression instead of TLocal(_g)
                                    var newSwitch: TypedExpr = {
                                        expr: TSwitch(originalExpr, cases, edef),
                                        pos: lastExpr.pos,
                                        t: lastExpr.t
                                    };
                                    #if debug_ast_builder
                                    #end
                                    newSwitch;
                                } else {
                                    lastExpr;
                                }
                            default:
                                lastExpr;
                        }
                    default:
                        unwrappedExpr;
                }
            default:
                unwrappedExpr;
        };

        // Extract switch from potential metadata wrapper
        var switchExpr = extractSwitch(processedExpr);
        if (switchExpr == null) {
            // Not actually a switch after all
            return if (context.compiler != null) {
                // CRITICAL FIX: Call ElixirASTBuilder.buildFromTypedExpr directly to preserve context
                // Using compiler.compileExpressionImpl creates a NEW context, losing ClauseContext registrations
                var result = reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(processedExpr, context);
                result != null ? result.def : null;
            } else {
                null;
            };
        }

        // Compile the switch expression
        var result = if (context.compiler != null) {
            // CRITICAL FIX: Call ElixirASTBuilder.buildFromTypedExpr directly to preserve context
            // Using compiler.compileExpressionImpl creates a NEW context, losing ClauseContext registrations
            reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(switchExpr, context);
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