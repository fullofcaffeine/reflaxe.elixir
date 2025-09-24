package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.Type.TypedExprDef;

/**
 * DESUGARED FOR LOOP DETECTION MODULE
 * 
 * WHY: When Haxe compiles for loops to a lower-level representation, it generates
 * a sequence of statements in a TBlock: var g=0; var g1=5; while(g<g1){...g++}.
 * This pattern needs to be detected at the TBlock level to generate idiomatic Elixir.
 * 
 * WHAT: Detects desugared for loop patterns in TBlock expressions and extracts
 * the complete context (counter variable, limit variable, start/end values, while loop).
 * This enables the compiler to generate Enum.each or comprehensions instead of while loops.
 * 
 * HOW: Analyzes TBlock statements for the characteristic pattern:
 * 1. TVar with infrastructure name (g, _g, g1, _g1, etc.) initialized to start value
 * 2. TVar with infrastructure name initialized to end value
 * 3. TWhile loop using those variables in condition
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Only handles desugared for loop detection
 * - Clean Interface: Simple detect method returns structured data or null
 * - Reusable: Can be used by both ElixirASTBuilder and transformers
 * - Testable: Clear input/output contract
 * 
 * EDGE CASES:
 * - Handles both g and _g prefixes for infrastructure variables
 * - Supports numeric suffixes (g1, g2, _g1, _g2, etc.)
 * - Returns null for non-matching patterns to allow fallback
 */
class DesugarredForDetector {
    
    /**
     * Infrastructure variable pattern matching g, g1, g2, _g, _g1, _g2, etc.
     */
    static final INFRASTRUCTURE_VAR_PATTERN = ~/^_?g[0-9]*$/;
    
    /**
     * Detect if a TBlock contains a desugared for loop pattern
     * 
     * WHY: TBlock is where we can see the complete pattern with initialization and loop
     * WHAT: Returns structured data about the for loop or null if not detected
     * HOW: Checks for sequential TVar statements followed by TWhile
     * 
     * @param exprs Array of TypedExpr from a TBlock
     * @return Null if not a desugared for loop, otherwise structured data about the pattern
     */
    public static function detectDesugarredFor(exprs: Array<TypedExpr>): Null<{
        counterVar: String,      // Name of counter variable (e.g., "g")
        limitVar: String,         // Name of limit variable (e.g., "g1")
        startValue: TypedExpr,    // Start value expression
        endValue: TypedExpr,      // End value expression
        whileExpr: TypedExpr,     // The while loop expression
        whileIndex: Int           // Index of while loop in exprs array
    }> {
        // Need at least 3 statements: counter init, limit init, while loop
        if (exprs.length < 3) return null;
        
        // Track infrastructure variables and their init values
        var counterVar: String = null;
        var counterInit: TypedExpr = null;
        var limitVar: String = null;
        var limitInit: TypedExpr = null;
        var whileIndex = -1;
        var whileExpr: TypedExpr = null;
        
        // Scan for the pattern
        var foundCounter = false;
        var foundLimit = false;
        
        for (i in 0...exprs.length) {
            switch(exprs[i].expr) {
                case TVar(v, init) if (init != null && isInfrastructureVar(v.name)):
                    // Found infrastructure variable initialization
                    if (!foundCounter) {
                        // First infrastructure var is the counter
                        counterVar = v.name;
                        counterInit = init;
                        foundCounter = true;
                        #if debug_loop_detection
                        trace('[DesugarredForDetector] Found counter var: $counterVar');
                        #end
                    } else if (!foundLimit) {
                        // Second infrastructure var is the limit
                        limitVar = v.name;
                        limitInit = init;
                        foundLimit = true;
                        #if debug_loop_detection
                        trace('[DesugarredForDetector] Found limit var: $limitVar');
                        #end
                    }
                    
                case TWhile(cond, body, _) if (foundCounter && foundLimit):
                    // Check if while uses our infrastructure variables
                    if (usesInfrastructureVars(cond, counterVar, limitVar)) {
                        whileIndex = i;
                        whileExpr = exprs[i];
                        #if debug_loop_detection
                        trace('[DesugarredForDetector] Found matching while loop at index $i');
                        #end
                        break; // Found complete pattern
                    }
                    
                default:
                    // Continue scanning
            }
        }
        
        // Return if we found the complete pattern
        if (counterVar != null && limitVar != null && whileExpr != null) {
            return {
                counterVar: counterVar,
                limitVar: limitVar,
                startValue: counterInit,
                endValue: limitInit,
                whileExpr: whileExpr,
                whileIndex: whileIndex
            };
        }
        
        return null;
    }
    
    /**
     * Check if a variable name matches the infrastructure pattern
     * 
     * WHY: Infrastructure variables follow a specific naming pattern
     * WHAT: Returns true if the name matches g, g1, _g, _g1, etc.
     * HOW: Uses regex pattern matching
     */
    static function isInfrastructureVar(name: String): Bool {
        return INFRASTRUCTURE_VAR_PATTERN.match(name);
    }
    
    /**
     * Check if an expression uses the specified infrastructure variables
     * 
     * WHY: Need to verify the while condition uses our tracked variables
     * WHAT: Returns true if the expression references the counter and/or limit variables
     * HOW: Recursively checks the expression tree for TLocal references
     */
    static function usesInfrastructureVars(expr: TypedExpr, counterVar: String, limitVar: String): Bool {
        var uses = false;
        
        function checkExpr(e: TypedExpr): Void {
            switch(e.expr) {
                case TLocal(v):
                    if (v.name == counterVar || v.name == limitVar) {
                        uses = true;
                    }
                    
                case TBinop(_, e1, e2):
                    checkExpr(e1);
                    checkExpr(e2);
                    
                case TUnop(_, _, e):
                    checkExpr(e);
                    
                case TParenthesis(e):
                    checkExpr(e);
                    
                case TBlock(exprs):
                    for (expr in exprs) checkExpr(expr);
                    
                case TIf(econd, eif, eelse):
                    checkExpr(econd);
                    checkExpr(eif);
                    if (eelse != null) checkExpr(eelse);
                    
                default:
                    // Other expression types - continue search if needed
            }
        }
        
        checkExpr(expr);
        return uses;
    }
    
    /**
     * Extract the user variable name from the while loop body
     * 
     * WHY: The body often starts with var i = g to create user-friendly variable name
     * WHAT: Returns the user variable name or null if not found
     * HOW: Checks if first statement in body is a TVar assignment from counter
     */
    public static function extractUserVariable(whileBody: TypedExpr, counterVar: String): Null<String> {
        switch(whileBody.expr) {
            case TBlock(exprs) if (exprs.length > 0):
                // Check first statement for TVar assignment from counter
                switch(exprs[0].expr) {
                    case TVar(v, init) if (init != null):
                        // Check if initializing from counter variable
                        switch(init.expr) {
                            case TLocal(localVar) if (localVar.name == counterVar):
                                return v.name;
                            default:
                        }
                    default:
                }
            default:
        }
        return null;
    }
}

#end