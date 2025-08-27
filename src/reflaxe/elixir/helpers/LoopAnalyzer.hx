package reflaxe.elixir.helpers;

#if (macro || elixir_runtime)

import haxe.macro.Type;
import haxe.macro.TypedExprDef;
import reflaxe.elixir.ElixirCompiler;

using reflaxe.helpers.NullHelper;
using reflaxe.helpers.TypedExprHelper;
using StringTools;

/**
 * LoopAnalyzer: Deep AST analysis engine for loop pattern detection and optimization planning
 * 
 * WHY: Loop optimization requires understanding complex patterns before transformation. Separating
 * analysis from compilation follows the Single Responsibility Principle and enables better testing.
 * The analyzer identifies optimization opportunities that various specialized compilers can execute.
 * This separation allows us to add new analyses without modifying compilation logic, and vice versa.
 * 
 * WHAT: Comprehensive loop pattern analysis and metadata extraction:
 * - Loop condition analysis (counter vs iterator patterns)
 * - Body pattern classification (map, filter, reduce, find, etc.)
 * - Variable usage tracking (which variables are read, modified, accumulated)
 * - Side effect detection (I/O operations, external calls)
 * - Break/continue/return flow analysis
 * - Dependency analysis between loop iterations
 * - TVar.id tracking for proper variable identity (following Reflaxe patterns)
 * 
 * HOW: Multi-pass AST traversal with result accumulation:
 * 1. Analyze loop condition to understand iteration pattern
 * 2. Traverse loop body collecting usage patterns
 * 3. Classify overall loop behavior based on collected data
 * 4. Return structured analysis for compiler consumption
 * 5. Track TVar.id for variable collision prevention
 * 
 * ARCHITECTURAL ROLE:
 * - **Service Provider**: Provides analysis services to all loop-related compilers
 * - **Shared Intelligence**: Central repository of loop pattern knowledge
 * - **Decoupling Layer**: Separates "what pattern is this?" from "how to compile it?"
 * - **Extension Point**: New analyses can be added without touching compilers
 * - **TVar.id Authority**: Maintains variable identity mappings following Reflaxe patterns
 * 
 * COLLABORATION WITH OTHER COMPONENTS:
 * - **LoopCompiler**: Main client, uses analysis to decide optimization strategy
 * - **ArrayPatternCompiler**: Consumes array pattern analysis
 * - **ReflectFieldsCompiler**: Uses field iteration analysis
 * - **RangeIterationCompiler**: Relies on range pattern detection
 * - **VariableCompiler**: Coordinates on TVar.id mappings
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Only analyzes, doesn't generate code
 * - Open/Closed: New analyses don't require modifying existing code
 * - Interface Segregation: Each compiler uses only needed analysis
 * - Dependency Inversion: Compilers depend on analysis abstractions
 * - Testability: Analysis logic can be tested without compilation
 * - Reflaxe Alignment: Uses TVar.id patterns from MarkUnusedVariablesImpl
 * 
 * ANALYSIS ACCURACY:
 * - Conservative: When unsure, reports pattern as "unknown"
 * - Complete: Analyzes entire AST, not just top level
 * - Contextual: Considers surrounding code for better detection
 * - Incremental: Can refine analysis with multiple passes
 * 
 * @see LoopCompiler - Primary consumer of analysis results
 * @see documentation/LOOP_ANALYSIS_PATTERNS.md - Pattern catalog
 * @see reflaxe.preprocessors.implementations.MarkUnusedVariablesImpl - TVar.id pattern reference
 */
@:nullSafety(Off)
class LoopAnalyzer {
    
    var compiler: ElixirCompiler;
    
    /**
     * TVar tracking maps following Reflaxe patterns
     * Using Map<Int, TVar> with TVar.id as key (like MarkUnusedVariablesImpl)
     */
    var tvarMap: Map<Int, TVar> = new Map();
    var tvarUsage: Map<Int, {read: Bool, write: Bool, accumulated: Bool}> = new Map();
    
    public function new(compiler: ElixirCompiler) {
        this.compiler = compiler;
    }
    
    /**
     * Analyze array loop condition to extract loop variables
     * 
     * WHY: Understanding loop structure is first step in optimization
     * WHAT: Extracts counter variable, limit variable, and their TVar objects
     * HOW: Pattern match on condition expression structure
     * 
     * CRITICAL: Returns TVar objects for proper identity tracking (not just names)
     * This prevents variable collision issues like g_array < g_array
     */
    public function analyzeArrayLoopCondition(econd: TypedExpr): Null<{indexVar: String, arrayVar: String, indexTVar: Null<TVar>, arrayTVar: Null<TVar>}> {
        #if debug_loop_analyzer
        // trace("[XRay LoopAnalyzer] ANALYZE ARRAY LOOP CONDITION");
        // trace('[XRay LoopAnalyzer] Condition type: ${econd.expr}');
        #end
        
        switch(econd.expr) {
            case TBinop(OpLt, e1, e2):
                // Pattern: counter < limit
                var indexInfo = extractVariableInfo(e1);
                var arrayInfo = extractVariableInfo(e2);
                
                if (indexInfo != null && arrayInfo != null) {
                    #if debug_loop_analyzer
                    // trace('[XRay LoopAnalyzer] ✓ DETECTED: ${indexInfo.name} < ${arrayInfo.name}');
                    // trace('[XRay LoopAnalyzer] Index TVar.id: ${indexInfo.tvar?.id}, Array TVar.id: ${arrayInfo.tvar?.id}');
                    #end
                    
                    return {
                        indexVar: indexInfo.name,
                        arrayVar: arrayInfo.name,
                        indexTVar: indexInfo.tvar,
                        arrayTVar: arrayInfo.tvar
                    };
                }
                
            case TBinop(OpLte, e1, e2):
                // Pattern: counter <= limit (inclusive)
                var indexInfo = extractVariableInfo(e1);
                var arrayInfo = extractVariableInfo(e2);
                
                if (indexInfo != null && arrayInfo != null) {
                    return {
                        indexVar: indexInfo.name,
                        arrayVar: arrayInfo.name,
                        indexTVar: indexInfo.tvar,
                        arrayTVar: arrayInfo.tvar
                    };
                }
                
            case TParenthesis(e):
                // Unwrap parentheses
                return analyzeArrayLoopCondition(e);
                
            case _:
                #if debug_loop_analyzer
                // trace("[XRay LoopAnalyzer] Unknown condition pattern");
                #end
        }
        
        return null;
    }
    
    /**
     * Extract variable information including TVar object
     * 
     * WHY: Need both name and TVar.id for proper identity tracking
     * WHAT: Extracts variable name and TVar object from expressions
     * HOW: Pattern match on TLocal to get TVar reference
     */
    function extractVariableInfo(expr: TypedExpr): Null<{name: String, tvar: Null<TVar>}> {
        switch(expr.expr) {
            case TLocal(v):
                // Track this TVar
                if (!tvarMap.exists(v.id)) {
                    tvarMap.set(v.id, v);
                    tvarUsage.set(v.id, {read: true, write: false, accumulated: false});
                }
                return {name: v.name, tvar: v};
                
            case TParenthesis(e):
                return extractVariableInfo(e);
                
            case _:
                // For non-variable expressions, just get the compiled name
                var name = compiler.compileExpression(expr, false);
                return {name: name, tvar: null};
        }
    }
    
    /**
     * Analyze loop body to determine transformation pattern
     * 
     * WHY: Body analysis determines which optimization to apply
     * WHAT: Classifies loop as map, filter, reduce, find, etc.
     * HOW: Deep AST traversal collecting pattern indicators
     */
    public function analyzeLoopBody(blockExpr: TypedExpr): LoopBodyAnalysis {
        #if debug_loop_analyzer
        // trace("[XRay LoopAnalyzer] ANALYZE LOOP BODY");
        #end
        
        var analysis = new LoopBodyAnalysis();
        analyzeLoopBodyRecursive(blockExpr, analysis);
        
        #if debug_loop_analyzer
        // trace('[XRay LoopAnalyzer] Analysis complete:');
        trace('  - Has return: ${analysis.hasReturn}');
        trace('  - Has break: ${analysis.hasBreak}');
        trace('  - Has continue: ${analysis.hasContinue}');
        trace('  - Modifies accumulator: ${analysis.modifiesAccumulator}');
        trace('  - Has side effects: ${analysis.hasSideEffects}');
        #end
        
        return analysis;
    }
    
    /**
     * Recursively analyze loop body collecting pattern data
     * 
     * WHY: Deep traversal needed for complete pattern understanding
     * WHAT: Visits all AST nodes collecting pattern indicators
     * HOW: Pattern matching with recursive descent
     */
    function analyzeLoopBodyRecursive(expr: TypedExpr, analysis: LoopBodyAnalysis): Void {
        switch(expr.expr) {
            case TReturn(e):
                analysis.hasReturn = true;
                if (e != null) {
                    analysis.returnExpression = e;
                }
                
            case TBreak:
                analysis.hasBreak = true;
                
            case TContinue:
                analysis.hasContinue = true;
                
            case TBinop(OpAssign, target, value):
                analyzeAssignment(target, value, analysis);
                
            case TCall(func, args):
                analyzeMethodCall(func, args, analysis);
                
            case TIf(cond, thenExpr, elseExpr):
                analysis.hasConditional = true;
                analysis.condition = cond;
                analyzeLoopBodyRecursive(thenExpr, analysis);
                if (elseExpr != null) {
                    analyzeLoopBodyRecursive(elseExpr, analysis);
                }
                
            case TBlock(exprs):
                for (e in exprs) {
                    analyzeLoopBodyRecursive(e, analysis);
                }
                
            case TLocal(v):
                // Track variable usage
                if (tvarUsage.exists(v.id)) {
                    var usage = tvarUsage.get(v.id);
                    usage.read = true;
                    tvarUsage.set(v.id, usage);
                }
                
            case TVar(v, init):
                // Track new variable declarations
                tvarMap.set(v.id, v);
                tvarUsage.set(v.id, {read: false, write: init != null, accumulated: false});
                if (init != null) {
                    analyzeLoopBodyRecursive(init, analysis);
                }
                
            case _:
                // Continue traversal for other expression types
                expr.iter(e -> analyzeLoopBodyRecursive(e, analysis));
        }
    }
    
    /**
     * Analyze assignment patterns for accumulation detection
     * 
     * WHY: Accumulation patterns indicate reduce operations
     * WHAT: Detects array push, counter increment, etc.
     * HOW: Pattern match on assignment structure
     */
    function analyzeAssignment(target: TypedExpr, value: TypedExpr, analysis: LoopBodyAnalysis): Void {
        // Check if this is an accumulator pattern
        switch(target.expr) {
            case TLocal(v):
                if (tvarUsage.exists(v.id)) {
                    var usage = tvarUsage.get(v.id);
                    usage.write = true;
                    
                    // Check if it's accumulation (e.g., x = x + 1)
                    if (referencesVariable(value, v.id)) {
                        usage.accumulated = true;
                        analysis.modifiesAccumulator = true;
                        analysis.accumulator = v.name;
                    }
                    
                    tvarUsage.set(v.id, usage);
                }
                
            case TArray(arr, index):
                // Array element assignment
                analysis.modifiesArray = true;
                
            case _:
        }
        
        // Recursively analyze the value expression
        analyzeLoopBodyRecursive(value, analysis);
    }
    
    /**
     * Analyze method calls for side effects and patterns
     * 
     * WHY: Method calls can indicate map/filter patterns or side effects
     * WHAT: Identifies array operations, I/O, external calls
     * HOW: Check method names and targets
     */
    function analyzeMethodCall(func: TypedExpr, args: Array<TypedExpr>, analysis: LoopBodyAnalysis): Void {
        switch(func.expr) {
            case TField(obj, FInstance(_, _, cf)):
                var methodName = cf.get().name;
                
                // Check for array operations
                if (methodName == "push" || methodName == "add") {
                    analysis.modifiesAccumulator = true;
                    analysis.arrayPushOperation = true;
                }
                
                // Check for I/O operations
                if (methodName == "write" || methodName == "print" || methodName == "log") {
                    analysis.hasSideEffects = true;
                }
                
            case TField(_, FStatic(_, cf)):
                // Static method calls might be side effects
                analysis.hasSideEffects = true;
                
            case _:
        }
        
        // Analyze arguments
        for (arg in args) {
            analyzeLoopBodyRecursive(arg, analysis);
        }
    }
    
    /**
     * Check if an expression references a specific variable
     * 
     * WHY: Needed to detect accumulation patterns
     * WHAT: Searches expression tree for variable reference
     * HOW: Recursive traversal looking for TLocal with matching ID
     */
    function referencesVariable(expr: TypedExpr, varId: Int): Bool {
        var found = false;
        
        function search(e: TypedExpr): Void {
            if (found) return;
            
            switch(e.expr) {
                case TLocal(v):
                    if (v.id == varId) {
                        found = true;
                    }
                case _:
                    e.iter(search);
            }
        }
        
        search(expr);
        return found;
    }
    
    /**
     * Classify loop pattern based on analysis
     * 
     * WHY: Pattern classification determines optimization strategy
     * WHAT: Maps analysis results to pattern type
     * HOW: Decision tree based on analysis flags
     */
    public function classifyLoopPattern(analysis: LoopBodyAnalysis): LoopPattern {
        // Early return pattern indicates find operation
        if (analysis.hasReturn && analysis.hasConditional) {
            return LoopPattern.Find;
        }
        
        // Array push indicates map operation
        if (analysis.arrayPushOperation && !analysis.hasConditional) {
            return LoopPattern.Map;
        }
        
        // Conditional array push indicates filter
        if (analysis.arrayPushOperation && analysis.hasConditional) {
            return LoopPattern.Filter;
        }
        
        // Accumulation indicates reduce
        if (analysis.modifiesAccumulator && !analysis.arrayPushOperation) {
            return LoopPattern.Reduce;
        }
        
        // Side effects only indicates foreach
        if (analysis.hasSideEffects && !analysis.modifiesAccumulator) {
            return LoopPattern.ForEach;
        }
        
        // Counter increment in conditional indicates count
        if (analysis.hasConditional && analysis.accumulator != null) {
            return LoopPattern.Count;
        }
        
        // Default to unknown
        return LoopPattern.Unknown;
    }
    
    /**
     * Get variable usage information
     * 
     * WHY: Compilers need to know which variables are actually used
     * WHAT: Returns usage flags for a variable
     * HOW: Lookup in tvarUsage map by TVar.id
     */
    public function getVariableUsage(varId: Int): Null<{read: Bool, write: Bool, accumulated: Bool}> {
        return tvarUsage.get(varId);
    }
    
    /**
     * Check if a variable is unused (following Reflaxe patterns)
     * 
     * WHY: Unused variables should be marked with -reflaxe.unused
     * WHAT: Determines if variable is never read
     * HOW: Check usage flags
     */
    public function isVariableUnused(varId: Int): Bool {
        var usage = tvarUsage.get(varId);
        return usage != null && !usage.read;
    }
}

/**
 * Loop body analysis results
 * Structured data about loop characteristics
 */
class LoopBodyAnalysis {
    public var hasReturn: Bool = false;
    public var hasBreak: Bool = false;
    public var hasContinue: Bool = false;
    public var hasConditional: Bool = false;
    public var hasSideEffects: Bool = false;
    
    public var modifiesAccumulator: Bool = false;
    public var modifiesArray: Bool = false;
    public var arrayPushOperation: Bool = false;
    
    public var accumulator: String = null;
    public var condition: TypedExpr = null;
    public var returnExpression: TypedExpr = null;
    
    public function new() {}
}

/**
 * Loop pattern classification
 */
enum LoopPattern {
    Map;      // Transform each element
    Filter;   // Select elements matching condition
    Find;     // Find first matching element
    Reduce;   // Accumulate to single value
    ForEach;  // Side effects only
    Count;    // Count matching elements
    Unknown;  // Cannot optimize
}

#end