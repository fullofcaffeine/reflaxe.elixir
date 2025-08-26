#if (macro || elixir_runtime)

package reflaxe.elixir.helpers;

import haxe.macro.Type;
import haxe.macro.TypedExprTools;
import reflaxe.elixir.ElixirCompiler;

/**
 * ArrayLoopOptimizer: Detects and optimizes array building patterns in loops
 * 
 * WHY: Imperative array building with push operations is non-idiomatic in Elixir.
 *      Loops that build arrays element-by-element should be transformed to functional
 *      Enum operations (map, filter, reduce) for better performance and readability.
 * 
 * WHAT: Identifies common array building patterns in for/while loops and transforms
 *       them to appropriate Enum functions. Handles filtering, mapping, reduction,
 *       and side-effect patterns with proper variable substitution.
 * 
 * HOW: Analyzes loop conditions for array iteration patterns, examines loop bodies
 *      for accumulation operations, then generates idiomatic Enum function calls
 *      with lambda expressions that preserve the original logic.
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Only handles array pattern optimization
 * - Pattern Recognition: Sophisticated detection of various array operations
 * - Idiomatic Output: Generates Elixir code that experts would write
 * - Performance: Leverages optimized BEAM/Enum implementations
 * - Testability: Clear pattern detection and transformation logic
 * 
 * EDGE CASES:
 * - Nested array operations with temporary variables
 * - Conditional array building (filter patterns)
 * - Complex transformations with multiple statements
 * - Index-dependent operations requiring with_index
 * - Break/continue preventing optimization
 */
@:nullSafety(Off)
class ArrayLoopOptimizer {
    
    /** Reference to main compiler for expression compilation */
    var compiler: ElixirCompiler;
    
    /** Debug tracing for pattern detection */
    static inline var DEBUG = #if debug_array_optimization true #else false #end;
    
    /**
     * Constructor requiring main compiler reference
     * 
     * @param compiler Main ElixirCompiler instance for delegation
     */
    public function new(compiler: ElixirCompiler) {
        this.compiler = compiler;
    }
    
    /**
     * Detects array building patterns in while loops
     * 
     * WHY: Transform desugared for-in loops into idiomatic Enum functions
     * WHAT: Detect while loops with counter < array.length and array access patterns
     * HOW: Analyze condition for comparison, body for array access and accumulation
     * 
     * Pattern detected:
     * ```haxe
     * while (i < array.length) {
     *     result.push(transform(array[i]));
     *     i++;
     * }
     * ```
     * 
     * @param econd Loop condition expression
     * @param ebody Loop body expression
     * @return Pattern info with index/accum variables or null
     */
    public function detectArrayBuildingPattern(econd: TypedExpr, ebody: TypedExpr): Null<ArrayBuildingPattern> {
        if (DEBUG) {
            trace("[ArrayOptimizer] DETECTION START");
            trace('[ArrayOptimizer] Condition type: ${econd.expr}');
        }
        
        // Step 1: Analyze condition for array iteration pattern
        var conditionInfo = analyzeArrayLoopCondition(econd);
        if (conditionInfo == null) {
            if (DEBUG) trace("[ArrayOptimizer] No array loop condition found");
            return null;
        }
        
        if (DEBUG) {
            trace('[ArrayOptimizer] Condition detected: counter=${conditionInfo.indexVar}, array=${conditionInfo.arrayVar}');
        }
        
        // Step 2: Register variable mappings for desugared loops
        // This prevents variable name collisions when Haxe creates multiple "g" variables
        if (conditionInfo.indexTVar != null && conditionInfo.arrayTVar != null) {
            compiler.variableCompiler.setupLoopDesugaringMappings(
                conditionInfo.indexTVar,  // Maps to "g_counter"
                conditionInfo.arrayTVar   // Maps to "g_array"
            );
            
            if (DEBUG) {
                trace('[ArrayOptimizer] Registered variable mappings for desugared loop');
            }
        }
        
        // Step 3: Analyze body for array building operations
        var bodyInfo = analyzeArrayLoopBody(ebody, conditionInfo);
        if (bodyInfo == null) {
            if (DEBUG) trace("[ArrayOptimizer] No array building pattern in body");
            return null;
        }
        
        if (DEBUG) {
            trace('[ArrayOptimizer] Pattern detected! Type: ${bodyInfo.patternType}');
        }
        
        return {
            indexVar: conditionInfo.indexVar,
            arrayVar: conditionInfo.arrayVar,
            accumVar: bodyInfo.accumVar,
            patternType: bodyInfo.patternType,
            transformation: bodyInfo.transformation,
            condition: bodyInfo.filterCondition
        };
    }
    
    /**
     * Compiles array building loop to idiomatic Enum function
     * 
     * WHY: Direct translation creates inefficient recursive functions
     * WHAT: Generates appropriate Enum.map/filter/reduce based on pattern
     * HOW: Substitutes variables and creates lambda expressions
     * 
     * @param pattern Detected array building pattern
     * @return Optimized Enum function call
     */
    public function compileArrayBuildingLoop(pattern: ArrayBuildingPattern): String {
        if (DEBUG) {
            trace('[ArrayOptimizer] Generating ${pattern.patternType} pattern');
        }
        
        return switch(pattern.patternType) {
            case Filter:
                generateFilterPattern(pattern);
            case Map:
                generateMapPattern(pattern);
            case FilterMap:
                generateFilterMapPattern(pattern);
            case Reduce:
                generateReducePattern(pattern);
            case Each:
                generateEachPattern(pattern);
        };
    }
    
    /**
     * Tries to optimize array iteration in for loops
     * 
     * WHY: For-in loops over arrays should use Enum functions
     * WHAT: Detects simple transformations without side effects
     * HOW: Analyzes loop body for pure operations
     * 
     * @param iterExpr Iterator expression
     * @param loopVar Loop variable name
     * @param blockExpr Loop body
     * @return Optimized code or null
     */
    public function tryOptimizeArrayIteration(iterExpr: TypedExpr, loopVar: String, blockExpr: TypedExpr): Null<String> {
        // Check if iterating over an array-like structure
        if (!isArrayExpression(iterExpr)) {
            return null;
        }
        
        // Check for break/continue which prevent optimization
        if (hasBreakOrContinue(blockExpr)) {
            return null;
        }
        
        // Analyze what the loop does with array elements
        var operation = analyzeArrayOperation(blockExpr, loopVar);
        if (operation == null) {
            return null;
        }
        
        var array = compiler.compileExpression(iterExpr);
        
        return switch(operation.type) {
            case "map":
                'Enum.map(${array}, fn ${loopVar} -> ${operation.expression} end)';
            case "filter":
                'Enum.filter(${array}, fn ${loopVar} -> ${operation.expression} end)';
            case "each":
                'Enum.each(${array}, fn ${loopVar} -> ${operation.expression} end)';
            default:
                null;
        };
    }
    
    // ═══════════════════════════════════════════════════════════════════
    // PATTERN ANALYSIS
    // ═══════════════════════════════════════════════════════════════════
    
    /**
     * Analyzes loop condition for array iteration pattern
     * 
     * Detects: i < array.length, i < len, etc.
     * 
     * @param econd Condition expression
     * @return Condition info with variables
     */
    function analyzeArrayLoopCondition(econd: TypedExpr): Null<ConditionInfo> {
        // Handle parentheses wrapping
        switch(econd.expr) {
            case TypedExprDef.TParenthesis(e):
                return analyzeArrayLoopCondition(e);
                
            case TypedExprDef.TBinop(OpLt | OpLte, e1, e2):
                // Look for counter < limit pattern
                var counterInfo = extractVariable(e1);
                var limitInfo = extractArrayLength(e2);
                
                if (counterInfo != null && limitInfo != null) {
                    return {
                        indexVar: counterInfo.name,
                        arrayVar: limitInfo.name,
                        indexTVar: counterInfo.tvar,
                        arrayTVar: limitInfo.tvar
                    };
                }
                
            default:
        }
        
        return null;
    }
    
    /**
     * Analyzes loop body for array building operations
     * 
     * @param ebody Loop body
     * @param conditionInfo Info from condition analysis
     * @return Body analysis results
     */
    function analyzeArrayLoopBody(ebody: TypedExpr, conditionInfo: ConditionInfo): Null<BodyAnalysis> {
        switch(ebody.expr) {
            case TypedExprDef.TBlock(exprs):
                return analyzeBlockForArrayOps(exprs, conditionInfo);
                
            case TypedExprDef.TIf(cond, thenExpr, null):
                // Conditional push = filter pattern
                var pushOp = findPushOperation(thenExpr);
                if (pushOp != null) {
                    return {
                        patternType: Filter,
                        accumVar: pushOp.targetArray,
                        transformation: pushOp.value,
                        filterCondition: compiler.compileExpression(cond)
                    };
                }
                
            default:
                // Single expression body
                var pushOp = findPushOperation(ebody);
                if (pushOp != null) {
                    return {
                        patternType: Map,
                        accumVar: pushOp.targetArray,
                        transformation: pushOp.value,
                        filterCondition: null
                    };
                }
        }
        
        return null;
    }
    
    /**
     * Finds push operations in expressions
     * 
     * @param expr Expression to search
     * @return Push operation info or null
     */
    function findPushOperation(expr: TypedExpr): Null<PushOperation> {
        switch(expr.expr) {
            case TypedExprDef.TCall(e, args):
                var callStr = compiler.compileExpression(e);
                if (callStr.indexOf(".push") >= 0 && args.length == 1) {
                    // Extract target array name
                    var parts = callStr.split(".push");
                    return {
                        targetArray: parts[0],
                        value: compiler.compileExpression(args[0])
                    };
                }
                
            case TypedExprDef.TBlock(exprs):
                // Search in block
                for (e in exprs) {
                    var op = findPushOperation(e);
                    if (op != null) return op;
                }
                
            default:
        }
        
        return null;
    }
    
    // ═══════════════════════════════════════════════════════════════════
    // PATTERN GENERATION
    // ═══════════════════════════════════════════════════════════════════
    
    /**
     * Generates Enum.filter pattern
     */
    function generateFilterPattern(pattern: ArrayBuildingPattern): String {
        var condition = pattern.condition != null ? pattern.condition : "true";
        return 'Enum.filter(${pattern.arrayVar}, fn item -> ${condition} end)';
    }
    
    /**
     * Generates Enum.map pattern
     */
    function generateMapPattern(pattern: ArrayBuildingPattern): String {
        var transform = pattern.transformation != null ? pattern.transformation : "item";
        return 'Enum.map(${pattern.arrayVar}, fn item -> ${transform} end)';
    }
    
    /**
     * Generates combined filter and map pattern
     */
    function generateFilterMapPattern(pattern: ArrayBuildingPattern): String {
        var condition = pattern.condition != null ? pattern.condition : "true";
        var transform = pattern.transformation != null ? pattern.transformation : "item";
        
        return '${pattern.arrayVar}
  |> Enum.filter(fn item -> ${condition} end)
  |> Enum.map(fn item -> ${transform} end)';
    }
    
    /**
     * Generates Enum.reduce pattern for complex accumulation
     */
    function generateReducePattern(pattern: ArrayBuildingPattern): String {
        var transform = pattern.transformation != null ? pattern.transformation : "item";
        return 'Enum.reduce(${pattern.arrayVar}, [], fn item, acc -> 
    [${transform} | acc]
  end) |> Enum.reverse()';
    }
    
    /**
     * Generates Enum.each for side effects
     */
    function generateEachPattern(pattern: ArrayBuildingPattern): String {
        var body = pattern.transformation != null ? pattern.transformation : "nil";
        return 'Enum.each(${pattern.arrayVar}, fn item -> ${body} end)';
    }
    
    // ═══════════════════════════════════════════════════════════════════
    // UTILITY FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════
    
    /**
     * Checks if expression is an array or list
     */
    function isArrayExpression(expr: TypedExpr): Bool {
        return switch(expr.expr) {
            case TypedExprDef.TArrayDecl(_): true;
            case TypedExprDef.TLocal(_): true; // Assume local vars could be arrays
            case TypedExprDef.TField(_, _): true; // Field access could be array
            default: false;
        };
    }
    
    /**
     * Checks for break/continue in expression tree
     */
    function hasBreakOrContinue(expr: TypedExpr): Bool {
        var found = false;
        
        function check(e: TypedExpr): Void {
            if (found) return;
            
            switch(e.expr) {
                case TypedExprDef.TBreak | TypedExprDef.TContinue:
                    found = true;
                default:
                    TypedExprTools.iter(e, check);
            }
        }
        
        check(expr);
        return found;
    }
    
    /**
     * Analyzes what operation is performed on array elements
     */
    function analyzeArrayOperation(expr: TypedExpr, loopVar: String): Null<{type: String, expression: String}> {
        // Simplified analysis - check for common patterns
        var compiled = compiler.compileExpression(expr);
        
        // Check if it's a transformation (uses loop var and returns value)
        if (compiled.indexOf(loopVar) >= 0) {
            // Check for side effects (assignments, function calls)
            if (compiled.indexOf(" = ") >= 0 || compiled.indexOf(".(") >= 0) {
                return {type: "each", expression: compiled};
            } else {
                return {type: "map", expression: compiled};
            }
        }
        
        return null;
    }
    
    /**
     * Extracts variable from expression
     */
    function extractVariable(expr: TypedExpr): Null<{name: String, tvar: TVar}> {
        switch(expr.expr) {
            case TypedExprDef.TLocal(v):
                return {
                    name: CompilerUtilities.toElixirVarName(v),
                    tvar: v
                };
            default:
                return null;
        }
    }
    
    /**
     * Extracts array from length access
     */
    function extractArrayLength(expr: TypedExpr): Null<{name: String, tvar: TVar}> {
        switch(expr.expr) {
            case TypedExprDef.TField(e, FInstance(_, _, cf)):
                // Check if accessing length field
                if (cf.get().name == "length") {
                    return extractVariable(e);
                }
            case TypedExprDef.TLocal(v):
                // Direct variable (might be pre-computed length)
                return {
                    name: CompilerUtilities.toElixirVarName(v),
                    tvar: v
                };
            default:
        }
        return null;
    }
    
    /**
     * Analyzes block for array operations
     */
    function analyzeBlockForArrayOps(exprs: Array<TypedExpr>, conditionInfo: ConditionInfo): Null<BodyAnalysis> {
        // Look for pattern: item = array[i]; result.push(transform(item)); i++;
        
        var hasIndexIncrement = false;
        var arrayAccess: Null<String> = null;
        var pushOperation: Null<PushOperation> = null;
        
        for (expr in exprs) {
            // Check for index increment
            if (isIndexIncrement(expr, conditionInfo.indexVar)) {
                hasIndexIncrement = true;
            }
            
            // Check for array access
            var access = findArrayAccess(expr, conditionInfo);
            if (access != null) {
                arrayAccess = access;
            }
            
            // Check for push operation
            var push = findPushOperation(expr);
            if (push != null) {
                pushOperation = push;
            }
        }
        
        if (hasIndexIncrement && pushOperation != null) {
            return {
                patternType: Map,
                accumVar: pushOperation.targetArray,
                transformation: pushOperation.value,
                filterCondition: null
            };
        }
        
        return null;
    }
    
    /**
     * Checks if expression is index increment
     */
    function isIndexIncrement(expr: TypedExpr, indexVar: String): Bool {
        switch(expr.expr) {
            case TypedExprDef.TUnop(OpIncrement, _, e):
                var v = extractVariable(e);
                return v != null && v.name == indexVar;
                
            case TypedExprDef.TBinop(OpAssign, e1, e2):
                var v = extractVariable(e1);
                if (v != null && v.name == indexVar) {
                    // Check for i = i + 1 pattern
                    var compiled = compiler.compileExpression(e2);
                    return compiled == '${indexVar} + 1';
                }
                
            default:
        }
        
        return false;
    }
    
    /**
     * Finds array access in expression
     */
    function findArrayAccess(expr: TypedExpr, conditionInfo: ConditionInfo): Null<String> {
        switch(expr.expr) {
            case TypedExprDef.TArray(e1, e2):
                var arr = extractVariable(e1);
                var idx = extractVariable(e2);
                
                if (arr != null && idx != null &&
                    arr.name == conditionInfo.arrayVar &&
                    idx.name == conditionInfo.indexVar) {
                    return 'item'; // This will be the lambda parameter
                }
                
            default:
        }
        
        return null;
    }
}

// ═══════════════════════════════════════════════════════════════════
// TYPE DEFINITIONS
// ═══════════════════════════════════════════════════════════════════

/**
 * Array building pattern types
 */
enum ArrayPatternType {
    Filter;      // Conditional push
    Map;         // Transform and push
    FilterMap;   // Filter then transform
    Reduce;      // Complex accumulation
    Each;        // Side effects only
}

/**
 * Detected array building pattern
 */
typedef ArrayBuildingPattern = {
    indexVar: String,
    arrayVar: String,
    accumVar: String,
    patternType: ArrayPatternType,
    transformation: Null<String>,
    condition: Null<String>
}

/**
 * Condition analysis result
 */
typedef ConditionInfo = {
    indexVar: String,
    arrayVar: String,
    indexTVar: Null<TVar>,
    arrayTVar: Null<TVar>
}

/**
 * Body analysis result
 */
typedef BodyAnalysis = {
    patternType: ArrayPatternType,
    accumVar: String,
    transformation: Null<String>,
    filterCondition: Null<String>
}

/**
 * Push operation info
 */
typedef PushOperation = {
    targetArray: String,
    value: String
}

#end