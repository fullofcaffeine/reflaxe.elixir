package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import reflaxe.elixir.helpers.NamingHelper;

using reflaxe.helpers.NameMetaHelper;
using StringTools;

/**
 * Array Loop Optimization Compiler for Reflaxe.Elixir
 * 
 * WHY: Array loop optimization was a massive section of the main ElixirCompiler (600+ lines).
 * This includes complex logic for detecting loop patterns and converting them to idiomatic Elixir Enum functions.
 * 
 * WHAT: Specialized compilation of array-based loops with comprehensive pattern detection:
 * - Early return patterns (Enum.find with reduce_while fallback)
 * - Filtering patterns (Enum.filter with condition extraction)
 * - Mapping patterns (Enum.map with transformation extraction)  
 * - Counting patterns (Enum.count with conditional counting)
 * - Accumulation patterns (Enum.reduce with numeric accumulation)
 * - Complex loop body transformation for side effects (Enum.each)
 * 
 * HOW: The compiler receives loop expressions and:
 * 1. Analyzes the loop body AST to detect specific patterns
 * 2. Extracts loop variables and conditions with proper TVar substitution
 * 3. Generates idiomatic Elixir Enum function calls
 * 4. Handles context management for variable substitution
 * 
 * EDGE CASES:
 * - System variables (_g, _g1, _g2, temp_*, _this*) are filtered out
 * - TVar-based substitution used for robust variable replacement
 * - Loop context management ensures proper variable substitution
 * - Complex loop bodies fallback to Enum.each for side effects
 * 
 * @see documentation/ARRAY_OPTIMIZATION_PATTERNS.md - Complete optimization patterns
 */
@:nullSafety(Off)
class ArrayOptimizationCompiler {
    
    var compiler: Dynamic; // ElixirCompiler reference
    
    /**
     * Create a new array optimization compiler
     * 
     * @param compiler The main ElixirCompiler instance
     */
    public function new(compiler: Dynamic) {
        this.compiler = compiler;
    }
    
    /**
     * Optimize array-based loops to use appropriate Enum functions
     * 
     * WHY: Convert imperative loops to functional Elixir patterns
     * 
     * WHAT: Comprehensive loop analysis and pattern detection:
     * - Early return detection for Enum.find patterns
     * - Filter pattern detection for Enum.filter  
     * - Map pattern detection for Enum.map
     * - Count pattern detection for Enum.count
     * - Accumulation pattern detection for Enum.reduce
     * 
     * HOW:
     * 1. Analyze loop body to detect patterns
     * 2. Extract loop variable with proper naming
     * 3. Generate appropriate Enum function call
     * 
     * @param arrayExpr The array expression being iterated
     * @param ebody The loop body expression
     * @return Generated Elixir Enum function call
     */
    public function optimizeArrayLoop(arrayExpr: String, ebody: TypedExpr): String {
        #if debug_array_optimization_compiler
        trace("[XRay ArrayOptimizationCompiler] OPTIMIZE ARRAY LOOP START");
        trace('[XRay ArrayOptimizationCompiler] Array expr: ${arrayExpr}');
        #end
        
        var bodyAnalysis = analyzeLoopBody(ebody);
        
        // Extract actual loop variable name from the AST
        var loopVar = extractLoopVariableFromBody(ebody);
        if (loopVar == null) loopVar = "item"; // Default fallback
        
        // For counting patterns, try to extract the variable used in condition
        if (bodyAnalysis.hasCountPattern && bodyAnalysis.condition != null) {
            var conditionVar = extractVariableFromCondition(bodyAnalysis.condition);
            if (conditionVar != null) loopVar = conditionVar;
        }
        
        #if debug_array_optimization_compiler
        trace('[XRay ArrayOptimizationCompiler] Loop variable: ${loopVar}');
        trace('[XRay ArrayOptimizationCompiler] Pattern analysis: ${bodyAnalysis}');
        #end
        
        // Dispatch to appropriate pattern generator based on analysis
        // Higher priority patterns checked first
        
        // 1. Check if this is a find pattern (early return)
        if (bodyAnalysis.hasEarlyReturn) {
            #if debug_array_optimization_compiler
            trace("[XRay ArrayOptimizationCompiler] ✓ EARLY RETURN PATTERN DETECTED");
            #end
            return generateEnumFindPattern(arrayExpr, loopVar, ebody);
        }
        
        // 2. Check for filtering pattern BEFORE mapping (filter has higher priority!)
        if (bodyAnalysis.hasFilterPattern && bodyAnalysis.conditionExpr != null) {
            #if debug_array_optimization_compiler
            trace("[XRay ArrayOptimizationCompiler] ✓ FILTER PATTERN DETECTED");
            #end
            return generateEnumFilterPattern(arrayExpr, loopVar, bodyAnalysis.conditionExpr);
        }
        
        // 3. Check for mapping pattern (array transformation) - Lower priority than filtering
        if (bodyAnalysis.hasMapPattern) {
            #if debug_array_optimization_compiler
            trace("[XRay ArrayOptimizationCompiler] ✓ MAP PATTERN DETECTED");
            #end
            return generateEnumMapPattern(arrayExpr, loopVar, ebody);
        }
        
        // 4. Check for counting pattern (lower priority since loops may have increments)
        if (bodyAnalysis.hasCountPattern && bodyAnalysis.conditionExpr != null) {
            #if debug_array_optimization_compiler
            trace("[XRay ArrayOptimizationCompiler] ✓ COUNT PATTERN DETECTED");
            #end
            return generateEnumCountPattern(arrayExpr, loopVar, bodyAnalysis.conditionExpr);
        }
        
        // 5. Check for simple numeric accumulation
        if (bodyAnalysis.hasSimpleAccumulator) {
            #if debug_array_optimization_compiler
            trace("[XRay ArrayOptimizationCompiler] ✓ ACCUMULATOR PATTERN DETECTED");
            #end
            return '(\n' +
                   '  {${bodyAnalysis.accumulator}} = Enum.reduce(${arrayExpr}, ${bodyAnalysis.accumulator}, fn ${loopVar}, acc ->\n' +
                   '    acc + ${loopVar}\n' +
                   '  end)\n' +
                   ')';
        } 
        
        // 6. Default to Enum.each for side effects
        #if debug_array_optimization_compiler
        trace("[XRay ArrayOptimizationCompiler] ✓ DEFAULT EACH PATTERN");
        #end
        var transformedBody = transformComplexLoopBody(ebody);
        var result = '(\n' +
               '  Enum.each(${arrayExpr}, fn ${loopVar} ->\n' +
               '    ${transformedBody}\n' +
               '  end)\n' +
               ')';
        
        #if debug_array_optimization_compiler
        trace('[XRay ArrayOptimizationCompiler] Generated: ${result.substring(0, 100)}...');
        trace("[XRay ArrayOptimizationCompiler] OPTIMIZE ARRAY LOOP END");
        #end
        
        return result;
    }
    
    /**
     * Analyze loop body to extract patterns for optimization
     * 
     * WHY: Different loop patterns require different Enum functions
     * 
     * WHAT: AST analysis to detect:
     * - Early returns (for find patterns)
     * - Conditional increments (for count patterns)
     * - Array pushes (for filter patterns)
     * - Variable assignments (for map patterns)
     * - Numeric accumulation (for reduce patterns)
     * 
     * HOW:
     * 1. Initialize analysis result structure
     * 2. Scan for early return statements
     * 3. Recursively analyze AST structure
     * 4. Check for accumulation patterns via regex fallback
     */
    public function analyzeLoopBody(ebody: TypedExpr): {
        hasSimpleAccumulator: Bool,
        hasEarlyReturn: Bool,
        hasCountPattern: Bool,
        hasFilterPattern: Bool,
        hasMapPattern: Bool,
        accumulator: String,
        loopVar: String,
        isAddition: Bool,
        condition: String,
        conditionExpr: Null<TypedExpr>
    } {
        #if debug_array_optimization_compiler
        trace("[XRay ArrayOptimizationCompiler] ANALYZE LOOP BODY START");
        #end
        
        // Default analysis result
        var result = {
            hasSimpleAccumulator: false,
            hasEarlyReturn: false,
            hasCountPattern: false,
            hasFilterPattern: false,
            hasMapPattern: false,
            accumulator: "sum",
            loopVar: "item", 
            isAddition: false,
            condition: "",
            conditionExpr: null
        };
        
        // Look for early returns (find patterns)
        result.hasEarlyReturn = hasReturnStatement(ebody);
        
        // Analyze AST structure for different patterns
        analyzeLoopBodyAST(ebody, result);
        
        // Look for simple accumulation patterns in the body (fallback)
        var bodyStr = compiler.compileExpression(ebody);
        if (bodyStr == null) return result;
        
        // Check for += pattern: sum += i (numeric accumulation)
        var addPattern = ~/(\w+)\s*=\s*\1\s*\+\s*(\w+)/;
        if (addPattern.match(bodyStr)) {
            result.hasSimpleAccumulator = true;
            result.accumulator = addPattern.matched(1);
            result.loopVar = addPattern.matched(2);
            result.isAddition = true;
        }
        
        #if debug_array_optimization_compiler
        trace('[XRay ArrayOptimizationCompiler] Analysis result: ${result}');
        trace("[XRay ArrayOptimizationCompiler] ANALYZE LOOP BODY END");
        #end
        
        return result;
    }
    
    /**
     * Analyze loop body AST to detect specific patterns
     * 
     * WHY: AST analysis is more reliable than string matching
     * 
     * WHAT: Recursive AST traversal looking for:
     * - TIf with array push operations (filter patterns)
     * - TIf with increment operations (count patterns)
     * - TVar with array access (map patterns)
     * - Direct increment operations (count patterns)
     * 
     * HOW: Pattern matching on TypedExpr structure with recursive descent
     */
    public function analyzeLoopBodyAST(expr: TypedExpr, result: Dynamic): Void {
        #if debug_array_optimization_compiler
        trace("[XRay ArrayOptimizationCompiler] ANALYZE AST NODE");
        #end
        
        switch (expr.expr) {
            case TBlock(exprs):
                for (e in exprs) {
                    analyzeLoopBodyAST(e, result);
                }
                
            case TIf(econd, eif, _):
                // Check for filtering pattern: if (condition) array.push(item)
                // or counting pattern: if (condition) count++
                var condition = compiler.compileExpression(econd);
                
                // Helper function to check for push pattern
                function checkForPush(e: TypedExpr): Bool {
                    switch (e.expr) {
                        case TCall({expr: TField(_, FInstance(_, _, cf))}, _):
                            if (cf.get().name == "push") {
                                return true;
                            }
                        case TBlock(exprs):
                            for (expr in exprs) {
                                if (checkForPush(expr)) return true;
                            }
                        case _:
                    }
                    return false;
                }
                
                // Check if this is a filter pattern (has push call)
                if (checkForPush(eif)) {
                    #if debug_array_optimization_compiler
                    trace("[XRay ArrayOptimizationCompiler] ✓ PUSH PATTERN DETECTED IN IF");
                    #end
                    result.hasFilterPattern = true;
                    result.conditionExpr = econd;
                } else {
                    // Check for counting patterns
                    switch (eif.expr) {
                        case TUnop(OpIncrement, _, {expr: TLocal(v)}):
                            // Found count++ pattern (direct)
                            #if debug_array_optimization_compiler
                            trace("[XRay ArrayOptimizationCompiler] ✓ INCREMENT PATTERN DETECTED");
                            #end
                            result.hasCountPattern = true;
                            result.accumulator = compiler.getOriginalVarName(v);
                            result.condition = condition;
                            result.conditionExpr = econd;
                        case TBlock(blockExprs):
                            // Check for count++ inside block
                            for (blockExpr in blockExprs) {
                                switch (blockExpr.expr) {
                                    case TUnop(OpIncrement, _, {expr: TLocal(v)}):
                                        // Found count++ pattern in block
                                        result.hasCountPattern = true;
                                        result.accumulator = compiler.getOriginalVarName(v);
                                        result.condition = condition;
                                        result.conditionExpr = econd;
                                    case TBinop(OpAssign, {expr: TLocal(v)}, {expr: TBinop(OpAdd, _, _)}):
                                        // Found count = count + 1 pattern in block
                                        result.hasCountPattern = true;
                                        result.accumulator = compiler.getOriginalVarName(v);
                                        result.condition = condition;
                                        result.conditionExpr = econd;
                                    case _:
                                }
                            }
                        case TBinop(OpAssign, {expr: TLocal(v)}, {expr: TBinop(OpAdd, _, _)}):
                            // Found count = count + 1 pattern (direct)
                            result.hasCountPattern = true;
                            result.accumulator = compiler.getOriginalVarName(v);
                            result.condition = condition;
                            result.conditionExpr = econd;
                        case _:
                    }
                }
                
            case TVar(v, init):
                // Check for new variable declarations (potential filtering/mapping)
                if (init != null) {
                    switch (init.expr) {
                        case TArray(e1, e2):
                            // Array access - potential mapping
                            #if debug_array_optimization_compiler
                            trace("[XRay ArrayOptimizationCompiler] ✓ ARRAY ACCESS PATTERN DETECTED");
                            #end
                            result.hasMapPattern = true;
                        case _:
                    }
                }
                
            case TUnop(OpIncrement, false, {expr: TLocal(v)}):
                // Direct increment outside condition - simple counting
                #if debug_array_optimization_compiler
                trace("[XRay ArrayOptimizationCompiler] ✓ DIRECT INCREMENT PATTERN DETECTED");
                #end
                result.hasCountPattern = true;
                result.accumulator = compiler.getOriginalVarName(v);
                
            case _:
        }
    }
    
    /**
     * Extract loop variable name from AST by finding TLocal references
     * 
     * WHY: Loop variable names need to be preserved for proper Elixir generation
     * 
     * WHAT: AST traversal to find meaningful variable names, filtering out:
     * - System variables (_g, _g1, _g2)
     * - Temporary variables (temp_*, _this*)
     * 
     * HOW: Recursive descent looking for TLocal nodes with non-system names
     */
    public function extractLoopVariableFromBody(expr: TypedExpr): Null<String> {
        switch (expr.expr) {
            case TLocal(v):
                // Check if this is an array access pattern indicating iteration variable
                var originalName = compiler.getOriginalVarName(v);
                if (originalName != "_g" && originalName != "_g1" && originalName != "_g2") {
                    return originalName;
                }
                
            case TBlock(exprs):
                // Look through block for variable references
                for (e in exprs) {
                    var result = extractLoopVariableFromBody(e);
                    if (result != null) return result;
                }
                
            case TIf(econd, eif, eelse):
                // Check condition and branches
                var result = extractLoopVariableFromBody(econd);
                if (result != null) return result;
                result = extractLoopVariableFromBody(eif);
                if (result != null) return result;
                if (eelse != null) {
                    result = extractLoopVariableFromBody(eelse);
                    if (result != null) return result;
                }
                
            case TReturn(e) if (e != null):
                return extractLoopVariableFromBody(e);
                
            case TField(e, fa):
                // Look for patterns like todo.id
                return extractLoopVariableFromBody(e);
                
            case TBinop(op, e1, e2):
                // Check both operands
                var result = extractLoopVariableFromBody(e1);
                if (result != null) return result;
                return extractLoopVariableFromBody(e2);
                
            case _:
                // Continue searching in nested expressions
        }
        return null;
    }
    
    /**
     * Check if expression contains return statements
     * 
     * WHY: Return statements indicate early exit patterns (Enum.find)
     * 
     * WHAT: Recursive AST scan for TReturn nodes
     * 
     * HOW: Pattern matching with recursive descent
     */
    public function hasReturnStatement(expr: TypedExpr): Bool {
        switch (expr.expr) {
            case TReturn(_):
                return true;
            case TBlock(exprs):
                for (e in exprs) {
                    if (hasReturnStatement(e)) return true;
                }
            case TIf(_, eif, eelse):
                if (hasReturnStatement(eif)) return true;
                if (eelse != null && hasReturnStatement(eelse)) return true;
            case _:
        }
        return false;
    }
    
    /**
     * Generate Enum.find pattern for early return loops
     * 
     * WHY: Early returns are best expressed as Enum.find operations
     * 
     * WHAT: Convert return-based loops to:
     * - Simple Enum.find for basic conditions
     * - Enum.reduce_while for complex cases
     * 
     * HOW:
     * 1. Extract condition from return statement
     * 2. Generate simple Enum.find if possible
     * 3. Fallback to reduce_while for complex cases
     */
    public function generateEnumFindPattern(arrayExpr: String, loopVar: String, ebody: TypedExpr): String {
        #if debug_array_optimization_compiler
        trace("[XRay ArrayOptimizationCompiler] GENERATE FIND PATTERN START");
        #end
        
        // Set loop context to enable aggressive variable substitution
        var previousContext = compiler.isInLoopContext;
        compiler.isInLoopContext = true;
        
        // Extract the condition from the if statement
        var condition = extractConditionFromReturn(ebody);
        if (condition != null) {
            // Generate Enum.find for simple cases
            // Restore previous loop context
            compiler.isInLoopContext = previousContext;
            var result = 'Enum.find(${arrayExpr}, fn ${loopVar} -> ${condition} end)';
            
            #if debug_array_optimization_compiler
            trace('[XRay ArrayOptimizationCompiler] Simple find: ${result}');
            trace("[XRay ArrayOptimizationCompiler] GENERATE FIND PATTERN END");
            #end
            
            return result;
        }
        
        // Fallback to reduce_while for complex cases
        var result = '(\n' +
               '  Enum.reduce_while(${arrayExpr}, nil, fn ${loopVar}, _acc ->\n' +
               '    ${transformFindLoopBody(ebody, loopVar)}\n' +
               '  end)\n' +
               ')';
        
        // Restore previous loop context
        compiler.isInLoopContext = previousContext;
        
        #if debug_array_optimization_compiler
        trace('[XRay ArrayOptimizationCompiler] Complex reduce_while: ${result.substring(0, 100)}...');
        trace("[XRay ArrayOptimizationCompiler] GENERATE FIND PATTERN END");
        #end
        
        return result;
    }
    
    /**
     * Extract condition from return statement in loop body
     * 
     * WHY: Simple find patterns have extractable conditions
     * 
     * WHAT: Find if(condition) return pattern and extract condition
     * 
     * HOW: AST traversal looking for TIf with TReturn in then branch
     */
    public function extractConditionFromReturn(expr: TypedExpr): Null<String> {
        switch (expr.expr) {
            case TBlock(exprs):
                for (e in exprs) {
                    var result = extractConditionFromReturn(e);
                    if (result != null) return result;
                }
            case TIf(econd, eif, _):
                switch (eif.expr) {
                    case TReturn(_):
                        return compiler.compileExpression(econd);
                    case _:
                }
            case _:
        }
        return null;
    }
    
    /**
     * Transform loop body for find patterns with reduce_while
     * 
     * WHY: Complex find patterns need reduce_while with :halt/:cont
     * 
     * WHAT: Convert if/return to {:halt, value} / {:cont, nil} pattern
     * 
     * HOW:
     * 1. Find if statements with return in body
     * 2. Transform to halt/cont pattern
     * 3. Handle nested blocks
     */
    public function transformFindLoopBody(expr: TypedExpr, loopVar: String): String {
        switch (expr.expr) {
            case TBlock(exprs):
                var result = "";
                for (e in exprs) {
                    switch (e.expr) {
                        case TIf(econd, eif, _):
                            var condition = compiler.compileExpression(econd);
                            // Check what's inside the eif (then branch)
                            switch (eif.expr) {
                                case TReturn(retExpr):
                                    var returnValue = retExpr != null ? compiler.compileExpression(retExpr) : loopVar;
                                    result += 'if ${condition} do\n' +
                                             '      {:halt, ${returnValue}}\n' +
                                             '    else\n' +
                                             '      {:cont, nil}\n' +
                                             '    end';
                                case TBlock(blockExprs):
                                    // Handle block containing return
                                    for (blockExpr in blockExprs) {
                                        switch (blockExpr.expr) {
                                            case TReturn(retExpr):
                                                var returnValue = retExpr != null ? compiler.compileExpression(retExpr) : loopVar;
                                                result += 'if ${condition} do\n' +
                                                         '      {:halt, ${returnValue}}\n' +
                                                         '    else\n' +
                                                         '      {:cont, nil}\n' +
                                                         '    end';
                                            case _:
                                        }
                                    }
                                case _:
                            }
                        case _:
                    }
                }
                return result;
            case TIf(econd, eif, _):
                // Handle direct if statement (not wrapped in block)
                var condition = compiler.compileExpression(econd);
                switch (eif.expr) {
                    case TReturn(retExpr):
                        var returnValue = retExpr != null ? compiler.compileExpression(retExpr) : loopVar;
                        return 'if ${condition} do\n' +
                               '      {:halt, ${returnValue}}\n' +
                               '    else\n' +
                               '      {:cont, nil}\n' +
                               '    end';
                    case _:
                }
            case _:
        }
        return '# Complex loop body transformation needed';
    }
    
    /**
     * Generate Enum.count pattern for conditional counting
     * 
     * WHY: Conditional counting is idiomatic as Enum.count with predicate
     * 
     * WHAT: Convert count++ patterns to Enum.count(array, fn x -> condition end)
     * 
     * HOW:
     * 1. Convert loop variable to snake_case
     * 2. Extract TVar for robust substitution
     * 3. Apply variable substitution to condition
     * 4. Generate Enum.count call
     */
    public function generateEnumCountPattern(arrayExpr: String, loopVar: String, conditionExpr: TypedExpr): String {
        #if debug_array_optimization_compiler
        trace("[XRay ArrayOptimizationCompiler] GENERATE COUNT PATTERN START");
        #end
        
        // Convert the loop variable name to snake_case for Elixir
        var targetVar = NamingHelper.toSnakeCase(loopVar);
        
        // Find what TVar the condition expression actually references
        var referencedTVar = findFirstLocalTVar(conditionExpr);
        
        // If the condition references a variable, use TVar-based substitution
        var condition: String;
        if (referencedTVar != null) {
            condition = compiler.compileExpressionWithTVarSubstitution(conditionExpr, referencedTVar, targetVar);
        } else {
            condition = compiler.compileExpression(conditionExpr);
        }
        
        var result = 'Enum.count(${arrayExpr}, fn ${targetVar} -> ${condition} end)';
        
        #if debug_array_optimization_compiler
        trace('[XRay ArrayOptimizationCompiler] Generated count: ${result}');
        trace("[XRay ArrayOptimizationCompiler] GENERATE COUNT PATTERN END");
        #end
        
        return result;
    }
    
    /**
     * Generate Enum.filter pattern for filtering arrays
     * 
     * WHY: Array filtering is idiomatic as Enum.filter with predicate
     * 
     * WHAT: Convert if(condition) push patterns to Enum.filter(array, fn x -> condition end)
     * 
     * HOW:
     * 1. Convert loop variable to snake_case
     * 2. Extract TVar for robust substitution
     * 3. Apply variable substitution to condition
     * 4. Generate Enum.filter call
     */
    public function generateEnumFilterPattern(arrayExpr: String, loopVar: String, conditionExpr: TypedExpr): String {
        #if debug_array_optimization_compiler
        trace("[XRay ArrayOptimizationCompiler] GENERATE FILTER PATTERN START");
        #end
        
        // Convert the loop variable name to snake_case for Elixir
        var targetVar = NamingHelper.toSnakeCase(loopVar);
        
        // Find what TVar the condition expression actually references
        var referencedTVar = findFirstLocalTVar(conditionExpr);
        
        // If the condition references a variable, use TVar-based substitution
        var condition: String;
        if (referencedTVar != null) {
            condition = compiler.compileExpressionWithTVarSubstitution(conditionExpr, referencedTVar, targetVar);
        } else {
            condition = compiler.compileExpression(conditionExpr);
        }
        
        var result = 'Enum.filter(${arrayExpr}, fn ${targetVar} -> ${condition} end)';
        
        #if debug_array_optimization_compiler
        trace('[XRay ArrayOptimizationCompiler] Generated filter: ${result}');
        trace("[XRay ArrayOptimizationCompiler] GENERATE FILTER PATTERN END");
        #end
        
        return result;
    }
    
    /**
     * Generate Enum.map pattern for transforming arrays
     * 
     * WHY: Array transformation is idiomatic as Enum.map
     * 
     * WHAT: Convert transformation patterns to Enum.map(array, fn x -> transformation end)
     * 
     * HOW:
     * 1. Convert loop variable to snake_case
     * 2. Extract TVar for robust substitution
     * 3. Apply variable substitution to transformation
     * 4. Generate Enum.map call
     */
    public function generateEnumMapPattern(arrayExpr: String, loopVar: String, ebody: TypedExpr): String {
        #if debug_array_optimization_compiler
        trace("[XRay ArrayOptimizationCompiler] GENERATE MAP PATTERN START");
        #end
        
        // Convert the loop variable name to snake_case for Elixir
        var targetVar = NamingHelper.toSnakeCase(loopVar);
        
        // Find what TVar the body expression actually references
        var referencedTVar = findFirstLocalTVar(ebody);
        
        // If the body references a variable, use TVar-based substitution
        var transformation: String;
        if (referencedTVar != null) {
            transformation = compiler.compileExpressionWithTVarSubstitution(ebody, referencedTVar, targetVar);
        } else {
            transformation = compiler.compileExpression(ebody);
        }
        
        var result = 'Enum.map(${arrayExpr}, fn ${targetVar} -> ${transformation} end)';
        
        #if debug_array_optimization_compiler
        trace('[XRay ArrayOptimizationCompiler] Generated map: ${result}');
        trace("[XRay ArrayOptimizationCompiler] GENERATE MAP PATTERN END");
        #end
        
        return result;
    }
    
    /**
     * Find the first local TVar referenced in an expression
     * 
     * WHY: TVar-based substitution is more robust than string matching
     * 
     * WHAT: AST traversal to find TLocal nodes, filtering system variables
     * 
     * HOW: Recursive descent with system variable filtering
     */
    public function findFirstLocalTVar(expr: TypedExpr): Null<TVar> {
        switch (expr.expr) {
            case TLocal(v):
                var varName = compiler.getOriginalVarName(v);
                // Skip system variables
                if (!isSystemVariable(varName)) {
                    return v;
                }
                
            case TField(e, fa):
                // For field access like "v.id", find the base variable
                return findFirstLocalTVar(e);
                
            case TBinop(op, e1, e2):
                // Check both sides, return the first non-system variable found
                var left = findFirstLocalTVar(e1);
                if (left != null) return left;
                return findFirstLocalTVar(e2);
                
            case TUnop(op, postFix, e):
                return findFirstLocalTVar(e);
                
            case TParenthesis(e):
                return findFirstLocalTVar(e);
                
            case TCall(e, args):
                // Check the function call and its arguments
                var result = findFirstLocalTVar(e);
                if (result != null) return result;
                for (arg in args) {
                    result = findFirstLocalTVar(arg);
                    if (result != null) return result;
                }
                
            case _:
                // Other expression types don't contain local variables we care about
        }
        return null;
    }
    
    /**
     * Check if a variable name represents a system-generated variable
     * 
     * WHY: System variables should be filtered out from user-facing names
     * 
     * WHAT: Pattern matching for common system variable patterns:
     * - Compiler temporaries (_g, _g1, _g2)
     * - Temp variables (temp_*)
     * - This references (_this*)
     * - Function arguments (arg0, arg1)
     * 
     * HOW: String pattern matching with common prefixes
     */
    public function isSystemVariable(varName: String): Bool {
        if (varName == null) return true;
        
        // Common system variable patterns
        return varName == "_g" || 
               varName == "_g1" || 
               varName == "_g2" ||
               varName.startsWith("temp_") ||
               varName.startsWith("_this") ||
               varName.startsWith("arg0") ||
               varName.startsWith("arg1") ||
               varName == "target" ||  // Generated target variables
               varName == "value" ||   // Generic value variables
               varName.length <= 1;    // Single character vars are usually system
    }
    
    /**
     * Extract variable name from condition string using regex
     * 
     * WHY: String-based fallback when AST traversal fails
     * 
     * WHAT: Regex pattern matching to find variable names in conditions
     * 
     * HOW: Common condition patterns like "variable.field > value"
     */
    public function extractVariableFromCondition(condition: String): Null<String> {
        if (condition == null || condition.length == 0) return null;
        
        // Look for patterns like "v.field" or "variable" at start of condition
        var fieldPattern = ~/^(\w+)\./;
        if (fieldPattern.match(condition)) {
            var varName = fieldPattern.matched(1);
            if (!isSystemVariable(varName)) {
                return varName;
            }
        }
        
        // Look for standalone variable at start
        var varPattern = ~/^(\w+)\s*[><=!]/;
        if (varPattern.match(condition)) {
            var varName = varPattern.matched(1);
            if (!isSystemVariable(varName)) {
                return varName;
            }
        }
        
        return null;
    }
    
    /**
     * Transform complex loop body for Enum.each patterns
     * 
     * WHY: Complex loops that don't fit other patterns need side-effect handling
     * 
     * WHAT: Basic expression compilation with proper context
     * 
     * HOW: Delegate to main compiler with loop context
     */
    public function transformComplexLoopBody(ebody: TypedExpr): String {
        // For complex loop bodies that don't fit standard patterns,
        // compile them as-is for Enum.each
        return compiler.compileExpression(ebody);
    }
    
    /**
     * Find the loop variable by looking for patterns like "v.field" where v is the loop variable
     * 
     * WHY: Needed for proper variable identification in loop contexts
     * 
     * WHAT: AST traversal to find field access patterns that indicate loop variables
     * 
     * HOW: Look for TField patterns first, then fallback to recursive search
     */
    public function findFirstTLocalInExpression(expr: TypedExpr): Null<TVar> {
        // Look for TField patterns first (like v.id, v.completed) which indicate loop variables
        var fieldVar = findTLocalFromFieldAccess(expr);
        if (fieldVar != null) return fieldVar;
        
        // Fallback to first TLocal found
        return findFirstTLocalInExpressionRecursive(expr);
    }
    
    /**
     * Find TLocal from field access patterns (e.g., v.id -> return v)
     * 
     * WHY: Field access patterns are strong indicators of loop variables
     * 
     * WHAT: Look for TField(TLocal(v), _) patterns in AST
     * 
     * HOW: Recursive traversal looking specifically for field access patterns
     */
    public function findTLocalFromFieldAccess(expr: TypedExpr): Null<TVar> {
        switch (expr.expr) {
            case TField(e, fa):
                switch (e.expr) {
                    case TLocal(v):
                        var varName = compiler.getOriginalVarName(v);
                        if (varName != "_g" && varName != "_g1" && varName != "_g2" && 
                            !varName.startsWith("temp_") && !varName.startsWith("_this")) {
                            return v;
                        }
                    case _:
                        // Not a TLocal field access
                }
            case TBlock(exprs):
                for (e in exprs) {
                    var result = findTLocalFromFieldAccess(e);
                    if (result != null) return result;
                }
            case TBinop(_, e1, e2):
                var result = findTLocalFromFieldAccess(e1);
                if (result != null) return result;
                return findTLocalFromFieldAccess(e2);
            case TIf(econd, eif, eelse):
                var result = findTLocalFromFieldAccess(econd);
                if (result != null) return result;
                result = findTLocalFromFieldAccess(eif);
                if (result != null) return result;
                if (eelse != null) {
                    result = findTLocalFromFieldAccess(eelse);
                    if (result != null) return result;
                }
            case TCall(e, args):
                var result = findTLocalFromFieldAccess(e);
                if (result != null) return result;
                for (arg in args) {
                    result = findTLocalFromFieldAccess(arg);
                    if (result != null) return result;
                }
            case _:
        }
        return null;
    }
    
    /**
     * Recursive search for TLocal nodes in expressions
     * 
     * WHY: Fallback method when field access patterns don't work
     * 
     * WHAT: Comprehensive AST traversal to find any TLocal nodes
     * 
     * HOW: Pattern matching on all expression types with recursive descent
     */
    public function findFirstTLocalInExpressionRecursive(expr: TypedExpr): Null<TVar> {
        switch (expr.expr) {
            case TLocal(v):
                // Skip compiler-generated variables
                var varName = compiler.getOriginalVarName(v);
                if (varName != "_g" && varName != "_g1" && varName != "_g2" && 
                    !varName.startsWith("temp_") && !varName.startsWith("_this")) {
                    return v;
                }
            case TBlock(exprs):
                // Look through block expressions
                for (e in exprs) {
                    var result = findFirstTLocalInExpressionRecursive(e);
                    if (result != null) return result;
                }
            case TBinop(_, e1, e2):
                // Check both operands
                var result = findFirstTLocalInExpressionRecursive(e1);
                if (result != null) return result;
                return findFirstTLocalInExpressionRecursive(e2);
            case TField(e, fa):
                // Look in the base expression (e.g., for "v.id", check "v")
                return findFirstTLocalInExpressionRecursive(e);
            case TCall(e, args):
                // Check function and arguments
                var result = findFirstTLocalInExpressionRecursive(e);
                if (result != null) return result;
                for (arg in args) {
                    result = findFirstTLocalInExpressionRecursive(arg);
                    if (result != null) return result;
                }
            case TIf(econd, eif, eelse):
                // Check condition and branches
                var result = findFirstTLocalInExpressionRecursive(econd);
                if (result != null) return result;
                result = findFirstTLocalInExpressionRecursive(eif);
                if (result != null) return result;
                if (eelse != null) {
                    result = findFirstTLocalInExpressionRecursive(eelse);
                    if (result != null) return result;
                }
            case TUnop(_, _, e):
                // Check the operand
                return findFirstTLocalInExpressionRecursive(e);
            case TArray(e1, e2):
                // Check array and index
                var result = findFirstTLocalInExpressionRecursive(e1);
                if (result != null) return result;
                return findFirstTLocalInExpressionRecursive(e2);
            case TParenthesis(e):
                // Check the parenthesized expression
                return findFirstTLocalInExpressionRecursive(e);
            case _:
                // Other expression types
        }
        return null;
    }
    
    /**
     * Find the first local variable referenced in an expression (string-based)
     * 
     * WHY: Some legacy code still uses string-based variable matching
     * 
     * WHAT: Convert TVar to string and apply system variable filtering
     * 
     * HOW: Use findFirstLocalTVar and convert result to string
     */
    public function findFirstLocalVariable(expr: TypedExpr): Null<String> {
        switch (expr.expr) {
            case TLocal(v):
                var varName = compiler.getOriginalVarName(v);
                // Skip system variables
                if (!isSystemVariable(varName)) {
                    return varName;
                }
                
            case TField(e, fa):
                // For field access like "v.id", find the base variable
                return findFirstLocalVariable(e);
                
            case TBinop(op, e1, e2):
                // Check both sides, return the first non-system variable found
                var left = findFirstLocalVariable(e1);
                if (left != null) return left;
                return findFirstLocalVariable(e2);
                
            case TUnop(op, postFix, e):
                return findFirstLocalVariable(e);
                
            case TParenthesis(e):
                return findFirstLocalVariable(e);
                
            case TCall(e, args):
                // Check the function call and its arguments
                var result = findFirstLocalVariable(e);
                if (result != null) return result;
                for (arg in args) {
                    result = findFirstLocalVariable(arg);
                    if (result != null) return result;
                }
                
            case _:
                // Other expression types don't contain local variables we care about
        }
        return null;
    }
}

#end