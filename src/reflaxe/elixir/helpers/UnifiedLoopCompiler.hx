#if (macro || elixir_runtime)

package reflaxe.elixir.helpers;

import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.TypedExprTools;
import reflaxe.elixir.ElixirCompiler;

/**
 * UnifiedLoopCompiler: Single source of truth for all loop compilation
 * 
 * WHY: The compiler currently has THREE separate loop compilation systems (LoopCompiler at 4,235 lines,
 *      WhileLoopCompiler at 764 lines, ControlFlowCompiler at 2,929 lines) with overlapping responsibilities
 *      and circular dependencies. This creates maintenance nightmares and inconsistent behavior.
 * 
 * WHAT: Consolidates all loop compilation (for/while/do-while) into a single, well-architected system.
 *       Handles basic loops, array patterns, iterator patterns, and complex transformations through
 *       delegated specialized components rather than a monolithic file.
 * 
 * HOW: Provides a unified entry point that analyzes loop types and delegates to appropriate optimizers.
 *      Initially wraps existing compilers for compatibility, then gradually migrates functionality
 *      into focused sub-components (CoreLoopCompiler, ArrayLoopOptimizer, etc.).
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: One clear purpose - compile all loop types
 * - Open/Closed Principle: Add new optimizers without modifying core logic
 * - Testability: Each optimizer can be tested independently
 * - Maintainability: No file exceeds 1,000 lines vs current 4,235
 * - Performance: Pattern detection happens once, not scattered
 * 
 * EDGE CASES:
 * - Nested loops with variable capture
 * - Break/continue in complex control flow
 * - Iterator patterns with side effects
 * - Mutation detection for recursive transformation
 * - Array building patterns for Enum optimization
 */
@:nullSafety(Off)
class UnifiedLoopCompiler {
    
    /** Reference to main compiler for expression compilation and utilities */
    var compiler: ElixirCompiler;
    
    /**
     * Core loop compiler for basic loop structures
     */
    public var coreLoopCompiler: CoreLoopCompiler;
    
    /**
     * Array loop optimizer for detecting and transforming array patterns
     */
    public var arrayOptimizer: ArrayLoopOptimizer;
    
    /**
     * Loop transformations for complex patterns and mutations
     */
    public var loopTransformations: LoopTransformations;
    
    /** 
     * Legacy compiler reference for gradual migration
     * TODO: Remove after full migration to sub-components
     */
    var legacyLoopCompiler: LoopCompiler;
    
    /**
     * Constructor initializes the unified compiler with legacy support
     * 
     * @param compiler Main ElixirCompiler instance for delegation
     */
    public function new(compiler: ElixirCompiler) {
        this.compiler = compiler;
        
        // Initialize core compiler for basic loop structures
        this.coreLoopCompiler = new CoreLoopCompiler(compiler);
        
        // Initialize array optimizer for pattern detection
        this.arrayOptimizer = new ArrayLoopOptimizer(compiler);
        
        // Initialize loop transformations for complex patterns
        this.loopTransformations = new LoopTransformations(compiler);
        
        // Initialize legacy compiler for gradual migration
        // This will be removed once all functionality is migrated
        this.legacyLoopCompiler = new LoopCompiler(compiler);
        
        #if debug_loop_compilation
//         trace("[UnifiedLoopCompiler] Initialized with core, optimizer, transformations, and legacy compiler support");
        #end
    }
    
    /**
     * Main entry point for all loop compilation
     * 
     * WHY: Provides single, consistent interface for loop compilation
     * WHAT: Analyzes loop type and delegates to appropriate compiler
     * HOW: Pattern matches on TypedExprDef to identify loop variant
     * 
     * @param expr The typed expression containing a loop
     * @return Generated Elixir code for the loop
     */
    public function compileLoop(expr: TypedExpr): String {
        #if debug_loop_compilation
//         trace('[UnifiedLoopCompiler] Compiling loop expression: ${expr.expr}');
        #end
        
        return switch(expr.expr) {
            case TypedExprDef.TWhile(econd, ebody, normalWhile):
                compileWhileLoop(econd, ebody, normalWhile);
                
            case TypedExprDef.TFor(tvar, iterExpr, blockExpr):
                compileForLoop(tvar, iterExpr, blockExpr);
                
            default:
                #if debug_loop_compilation
//                 trace('[UnifiedLoopCompiler] WARNING: Non-loop expression passed to compileLoop');
                #end
                "";
        }
    }
    
    /**
     * Compiles while and do-while loops
     * 
     * WHY: While loops need special handling for mutation and recursion
     * WHAT: Transforms while/do-while into recursive functions or Enum operations
     * HOW: Currently delegates to legacy compiler, will migrate to CoreLoopCompiler
     * 
     * @param econd Loop condition expression
     * @param ebody Loop body expression
     * @param normalWhile True for while, false for do-while
     * @return Generated Elixir code
     */
    public function compileWhileLoop(econd: TypedExpr, ebody: TypedExpr, normalWhile: Bool): String {
        #if debug_loop_compilation
//         trace('[UnifiedLoopCompiler] Compiling while loop (normal: $normalWhile)');
        #end
        
        // Use new ArrayLoopOptimizer when USE_ARRAY_OPTIMIZER is defined
        #if use_array_optimizer
        var arrayPattern = arrayOptimizer.detectArrayBuildingPattern(econd, ebody);
        if (arrayPattern != null) {
            #if debug_loop_compilation
//             trace('[UnifiedLoopCompiler] Detected array building pattern, optimizing with ArrayLoopOptimizer');
            #end
            return arrayOptimizer.compileArrayBuildingLoop(arrayPattern);
        }
        #else
        // Fall back to legacy detection
        var arrayPattern = detectArrayBuildingPattern(econd, ebody);
        if (arrayPattern != null) {
            #if debug_loop_compilation
//             trace('[UnifiedLoopCompiler] Detected array building pattern, optimizing');
            #end
            return compileArrayBuildingLoop(econd, ebody, arrayPattern);
        }
        #end
        
        // Use CoreLoopCompiler for basic loops when USE_CORE_COMPILER is defined
        #if use_core_compiler
        #if debug_loop_compilation
//         trace('[UnifiedLoopCompiler] Using CoreLoopCompiler for basic while loop');
        #end
        return coreLoopCompiler.compileBasicWhileLoop(econd, ebody, normalWhile);
        #else
        // Fall back to legacy compiler
        return legacyLoopCompiler.compileWhileLoop(econd, ebody, normalWhile);
        #end
    }
    
    /**
     * Compiles for loops over iterators and ranges
     * 
     * WHY: For loops can often be optimized to Enum operations
     * WHAT: Transforms for-in loops based on iterator type
     * HOW: Currently delegates to legacy compiler, will migrate to CoreLoopCompiler
     * 
     * @param tvar Loop variable
     * @param iterExpr Iterator expression (array, range, etc.)
     * @param blockExpr Loop body
     * @return Generated Elixir code
     */
    public function compileForLoop(tvar: TVar, iterExpr: TypedExpr, blockExpr: TypedExpr): String {
        #if debug_loop_compilation
//         trace('[UnifiedLoopCompiler] Compiling for loop over: ${iterExpr.expr}');
        #end
        
        // Use ArrayLoopOptimizer for array iteration patterns
        #if use_array_optimizer
        var loopVar = CompilerUtilities.toElixirVarName(tvar);
        var optimized = arrayOptimizer.tryOptimizeArrayIteration(iterExpr, loopVar, blockExpr);
        if (optimized != null) {
            #if debug_loop_compilation
//             trace('[UnifiedLoopCompiler] Optimized array iteration with ArrayLoopOptimizer');
            #end
            return optimized;
        }
        #else
        // Check for simple array transformations that can become Enum operations
        if (canOptimizeToEnum(tvar, iterExpr, blockExpr)) {
            #if debug_loop_compilation
//             trace('[UnifiedLoopCompiler] Optimizing for loop to Enum operation');
            #end
            return optimizeToEnum(tvar, iterExpr, blockExpr);
        }
        #end
        
        // Use CoreLoopCompiler for basic loops when USE_CORE_COMPILER is defined
        #if use_core_compiler
        #if debug_loop_compilation
//         trace('[UnifiedLoopCompiler] Using CoreLoopCompiler for basic for loop');
        #end
        return coreLoopCompiler.compileBasicForLoop(tvar, iterExpr, blockExpr);
        #else
        // Fall back to legacy compiler
        return legacyLoopCompiler.compileForLoop(tvar, iterExpr, blockExpr);
        #end
    }
    
    /**
     * Detects array building patterns in loops for optimization
     * 
     * WHY: Common pattern that can be optimized to Enum.map/filter
     * WHAT: Identifies loops that build arrays element by element
     * HOW: Analyzes loop body for push operations on accumulators
     * 
     * TODO: Extract to ArrayLoopOptimizer
     */
    function detectArrayBuildingPattern(econd: TypedExpr, ebody: TypedExpr): Null<{indexVar: String, accumVar: String, arrayExpr: String}> {
        // Delegate to legacy compiler for now
        return legacyLoopCompiler.detectArrayBuildingPattern(econd, ebody);
    }
    
    /**
     * Compiles array building loops with optimization
     * 
     * WHY: Direct translation creates inefficient recursive functions
     * WHAT: Transforms array building patterns to Enum operations
     * HOW: Uses detected pattern to generate appropriate Enum call
     * 
     * TODO: Extract to ArrayLoopOptimizer
     */
    function compileArrayBuildingLoop(econd: TypedExpr, ebody: TypedExpr, pattern: {indexVar: String, accumVar: String, arrayExpr: String}): String {
        return legacyLoopCompiler.compileArrayBuildingLoop(econd, ebody, pattern);
    }
    
    /**
     * Checks if a for loop can be optimized to Enum operations
     * 
     * WHY: Functional iteration is more idiomatic in Elixir
     * WHAT: Analyzes loop structure for optimization potential
     * HOW: Checks for simple transformations without side effects
     * 
     * TODO: Extract to LoopPatternDetector
     */
    function canOptimizeToEnum(tvar: TVar, iterExpr: TypedExpr, blockExpr: TypedExpr): Bool {
        // Simple heuristic for now - check if iterating over array with no break/continue
        return switch(iterExpr.expr) {
            case TypedExprDef.TLocal(_) | TypedExprDef.TField(_, _): 
                !containsBreakOrContinue(blockExpr);
            case TypedExprDef.TArrayDecl(_):
                !containsBreakOrContinue(blockExpr);
            default: 
                false;
        }
    }
    
    /**
     * Optimizes for loop to Enum operation
     * 
     * WHY: Enum operations are more idiomatic and performant
     * WHAT: Transforms for loops to Enum.map/each/filter
     * HOW: Analyzes loop body to determine appropriate Enum function
     * 
     * TODO: Extract to ArrayLoopOptimizer
     */
    function optimizeToEnum(tvar: TVar, iterExpr: TypedExpr, blockExpr: TypedExpr): String {
        // For now, just delegate to legacy compiler
        // This will be properly implemented in ArrayLoopOptimizer
        return legacyLoopCompiler.compileForLoop(tvar, iterExpr, blockExpr);
    }
    
    /**
     * Utility to check for break/continue in expression tree
     * 
     * WHY: Break/continue prevent Enum optimization
     * WHAT: Recursively searches for control flow statements
     * HOW: Traverses TypedExpr tree looking for TBreak/TContinue
     * 
     * TODO: Extract to LoopPatternDetector
     */
    function containsBreakOrContinue(expr: TypedExpr): Bool {
        var found = false;
        
        function check(e: TypedExpr): Void {
            if (found) return;
            
            switch(e.expr) {
                case TypedExprDef.TBreak | TypedExprDef.TContinue:
                    found = true;
                case TypedExprDef.TWhile(econd, ebody, _) | TypedExprDef.TFor(_, econd, ebody):
                    // Don't check inside nested loops - they have their own scope
                    return;
                default:
                    TypedExprTools.iter(e, check);
            }
        }
        
        check(expr);
        return found;
    }
    
    /**
     * Gets statistics about current compiler state for monitoring
     * 
     * WHY: Track migration progress and identify remaining work
     * WHAT: Returns counts of legacy vs new compilation paths
     * HOW: Tracks internal counters (when implemented)
     */
    public function getStatistics(): {legacyCalls: Int, optimizedCalls: Int} {
        // TODO: Implement counters
        return {legacyCalls: 0, optimizedCalls: 0};
    }
    
    /**
     * Utility to check if expression contains TFor loops
     * 
     * WHY: ElixirCompiler needs to detect loop patterns for compilation decisions
     * WHAT: Recursively searches for TFor nodes in expression tree
     * HOW: Traverses TypedExpr tree looking for TFor expressions
     * 
     * @param expr Expression to check
     * @return True if expression contains any TFor nodes
     */
    public function checkForTForInExpression(expr: TypedExpr): Bool {
        if (expr == null) return false;
        
        switch (expr.expr) {
            case TFor(_, _, _):
                return true;
            case TBlock(exprs):
                for (e in exprs) {
                    if (checkForTForInExpression(e)) return true;
                }
                return false;
            case TIf(_, eif, eelse):
                if (checkForTForInExpression(eif)) return true;
                if (eelse != null && checkForTForInExpression(eelse)) return true;
                return false;
            case _:
                return false;
        }
    }
    
    /**
     * Utility to check if expression contains TWhile loops
     * 
     * WHY: ElixirCompiler needs to detect while patterns for compilation strategies
     * WHAT: Recursively searches for TWhile nodes in expression tree
     * HOW: Deep traversal of all expression types checking for TWhile
     * 
     * @param expr Expression to check
     * @return True if expression contains any TWhile nodes
     */
    public function containsTWhileExpression(expr: TypedExpr): Bool {
        if (expr == null) return false;
        
        switch (expr.expr) {
            case TWhile(_, _, _):
                // Found a TWhile
                return true;
                
            case TBlock(exprs):
                // Recursively check all expressions in the block
                for (e in exprs) {
                    if (containsTWhileExpression(e)) return true;
                }
                return false;
                
            case TIf(_, eif, eelse):
                // Check both branches of if-statement
                if (containsTWhileExpression(eif)) return true;
                if (eelse != null && containsTWhileExpression(eelse)) return true;
                return false;
                
            case TFor(_, _, ebody):
                // For loops might contain while loops in their body
                return containsTWhileExpression(ebody);
                
            case TSwitch(_, cases, defaultCase):
                // Check all switch cases
                for (c in cases) {
                    if (containsTWhileExpression(c.expr)) return true;
                }
                if (defaultCase != null && containsTWhileExpression(defaultCase)) return true;
                return false;
                
            case TTry(etry, catches):
                // Check try block
                if (containsTWhileExpression(etry)) return true;
                // Check catch blocks
                for (c in catches) {
                    if (containsTWhileExpression(c.expr)) return true;
                }
                return false;
                
            case TFunction(func):
                // Check function body
                return containsTWhileExpression(func.expr);
                
            case TCall(e, args):
                // Check function expression and arguments
                if (containsTWhileExpression(e)) return true;
                for (arg in args) {
                    if (containsTWhileExpression(arg)) return true;
                }
                return false;
                
            case TBinop(_, e1, e2):
                // Check both operands
                return containsTWhileExpression(e1) || containsTWhileExpression(e2);
                
            case TUnop(_, _, e):
                // Check operand
                return containsTWhileExpression(e);
                
            case TArray(e1, e2):
                // Check array and index expressions
                return containsTWhileExpression(e1) || containsTWhileExpression(e2);
                
            case TArrayDecl(exprs):
                // Check all array elements
                for (e in exprs) {
                    if (containsTWhileExpression(e)) return true;
                }
                return false;
                
            case TField(e, _):
                // Check field access target
                return containsTWhileExpression(e);
                
            case TVar(_, init):
                // Check variable initialization
                return init != null ? containsTWhileExpression(init) : false;
                
            case _:
                // All other expression types don't contain TWhile
                return false;
        }
    }
}

#end