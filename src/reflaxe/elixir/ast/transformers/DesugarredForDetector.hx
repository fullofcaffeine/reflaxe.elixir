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
    
    /**
     * Enhanced detection with infrastructure variable elimination
     * 
     * WHY: Infrastructure variables (_g, _g1) shouldn't appear in generated Elixir
     * WHAT: Returns complete data including variable mappings and substitution information
     * HOW: Detects pattern, extracts user variables, builds elimination mapping
     * 
     * ARCHITECTURE BENEFITS:
     * - Provides complete context for idiomatic generation
     * - Eliminates infrastructure variables at detection stage
     * - Centralizes variable mapping logic
     * 
     * @param exprs Array of TypedExpr from a TBlock
     * @return Enhanced data structure with variable mappings or null
     */
    public static function detectAndEliminate(exprs: Array<TypedExpr>): Null<{
        // Original detection data
        counterVar: String,
        limitVar: String,
        startValue: TypedExpr,
        endValue: TypedExpr,
        whileExpr: TypedExpr,
        whileIndex: Int,
        
        // Enhanced elimination data
        userVar: Null<String>,           // User-facing variable (e.g., "i" from "var i = _g")
        arrayVar: Null<String>,          // Array being iterated (if array iteration)
        variableMapping: Map<String, String>,  // Infrastructure → User variable mapping
        eliminationData: {
            isSimpleRange: Bool,         // true for 0...n patterns
            isArrayIteration: Bool,      // true for array iteration
            needsIndexCounter: Bool,     // true if index is used in body
            startLiteral: Null<Int>,     // Literal start value if constant
            endLiteral: Null<Int>        // Literal end value if constant
        }
    }> {
        // First do basic detection
        var basic = detectDesugarredFor(exprs);
        if (basic == null) return null;
        
        #if debug_loop_detection
        trace('[DesugarredForDetector] Basic detection succeeded, enhancing with elimination data');
        #end
        
        // Extract user variable from while body
        var userVar: Null<String> = null;
        switch(basic.whileExpr.expr) {
            case TWhile(_, body, _):
                userVar = extractUserVariable(body, basic.counterVar);
                #if debug_loop_detection
                if (userVar != null) {
                    trace('[DesugarredForDetector] Found user variable: $userVar maps to ${basic.counterVar}');
                }
                #end
            default:
        }
        
        // Build variable mapping
        var mapping = new Map<String, String>();
        if (userVar != null) {
            mapping.set(basic.counterVar, userVar);
        }
        mapping.set(basic.limitVar, "_end");  // Convention: limit vars map to _end
        
        // Analyze pattern type
        var isSimpleRange = false;
        var startLiteral: Null<Int> = null;
        var endLiteral: Null<Int> = null;
        
        // Check for literal start value
        switch(basic.startValue.expr) {
            case TConst(TInt(n)):
                startLiteral = n;
                isSimpleRange = true;
            default:
        }
        
        // Check for literal end value
        switch(basic.endValue.expr) {
            case TConst(TInt(n)):
                endLiteral = n;
            default:
                isSimpleRange = false;  // Not simple if end isn't literal
        }
        
        // Check for array iteration pattern
        var isArrayIteration = false;
        var arrayVar: Null<String> = null;
        switch(basic.whileExpr.expr) {
            case TWhile(_, body, _):
                // Look for array access pattern in body
                if (detectArrayAccess(body)) {
                    isArrayIteration = true;
                    arrayVar = extractArrayVariable(body);
                    #if debug_loop_detection
                    trace('[DesugarredForDetector] Detected array iteration pattern, array: $arrayVar');
                    #end
                }
            default:
        }
        
        // Return enhanced data
        return {
            // Original data
            counterVar: basic.counterVar,
            limitVar: basic.limitVar,
            startValue: basic.startValue,
            endValue: basic.endValue,
            whileExpr: basic.whileExpr,
            whileIndex: basic.whileIndex,
            
            // Enhanced data
            userVar: userVar,
            arrayVar: arrayVar,
            variableMapping: mapping,
            eliminationData: {
                isSimpleRange: isSimpleRange,
                isArrayIteration: isArrayIteration,
                needsIndexCounter: userVar == null,  // If no user var, index is used
                startLiteral: startLiteral,
                endLiteral: endLiteral
            }
        };
    }
    
    /**
     * Detect if a while body contains array access pattern
     * 
     * WHY: Array iteration uses TArrayAccess(_g) pattern
     * WHAT: Returns true if array access with infrastructure var found
     * HOW: Recursively searches for TArrayAccess nodes
     */
    static function detectArrayAccess(expr: TypedExpr): Bool {
        var found = false;
        
        function search(e: TypedExpr): Void {
            switch(e.expr) {
                case TArray(arr, index):
                    // Check if index is infrastructure variable
                    switch(index.expr) {
                        case TLocal(v) if (isInfrastructureVar(v.name)):
                            found = true;
                        default:
                    }
                    
                case TBlock(exprs):
                    for (expr in exprs) search(expr);
                    
                case TVar(_, init) if (init != null):
                    search(init);
                    
                default:
                    // Could add more cases if needed
            }
        }
        
        search(expr);
        return found;
    }
    
    /**
     * Extract array variable name from iteration pattern
     * 
     * WHY: Need to know which array is being iterated
     * WHAT: Returns array variable name or null
     * HOW: Looks for TArrayAccess pattern
     */
    static function extractArrayVariable(expr: TypedExpr): Null<String> {
        var arrayName: Null<String> = null;
        
        function search(e: TypedExpr): Void {
            switch(e.expr) {
                case TArray(arr, index):
                    // Extract array name
                    switch(arr.expr) {
                        case TLocal(v):
                            arrayName = v.name;
                        default:
                    }
                    
                case TBlock(exprs):
                    for (expr in exprs) if (arrayName == null) search(expr);
                    
                case TVar(_, init) if (init != null):
                    search(init);
                    
                default:
            }
        }
        
        search(expr);
        return arrayName;
    }
    
    /**
     * Create substitution map for eliminating infrastructure variables
     * 
     * WHY: Need to replace all infrastructure variable references
     * WHAT: Returns map of old name → new name for substitution
     * HOW: Uses detection data to build comprehensive mapping
     */
    public static function createSubstitutionMap(data: Dynamic): Map<String, String> {
        var map = new Map<String, String>();
        
        // Map counter to user variable or generate name
        if (data.userVar != null) {
            map.set(data.counterVar, data.userVar);
        } else {
            // Generate appropriate name based on context
            var eliminationData = Reflect.field(data, "eliminationData");
            var isArrayIteration = eliminationData != null ? Reflect.field(eliminationData, "isArrayIteration") : false;
            var generatedName = isArrayIteration ? "item" : "i";
            map.set(data.counterVar, generatedName);
        }
        
        // Map limit variable (usually not needed in output)
        map.set(data.limitVar, "_limit");
        
        // Add any additional mappings from variableMapping
        var variableMapping: Map<String, String> = Reflect.field(data, "variableMapping");
        if (variableMapping != null) {
            for (key in variableMapping.keys()) {
                var value = variableMapping.get(key);
                if (value != null && !map.exists(key)) {
                    map.set(key, value);
                }
            }
        }
        
        #if debug_loop_detection
        trace('[DesugarredForDetector] Substitution map created:');
        for (key in map.keys()) {
            trace('  $key → ${map.get(key)}');
        }
        #end
        
        return map;
    }
}

#end