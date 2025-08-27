#if (macro || elixir_runtime)

package reflaxe.elixir.helpers;

import haxe.macro.Type;
import haxe.macro.TypedExprTools;
import reflaxe.elixir.ElixirCompiler;

/**
 * CoreLoopCompiler: Basic loop compilation without optimizations
 * 
 * WHY: The 4,235-line LoopCompiler mixes basic compilation with complex optimizations,
 *      making it unmaintainable. We need a clean separation between core loop structures
 *      and optimization patterns. This allows for easier testing, debugging, and extension.
 * 
 * WHAT: Handles pure loop compilation for while/do-while/for loops without any
 *       pattern detection or optimization. Generates simple, correct Elixir code
 *       using recursive functions or basic Enum operations.
 * 
 * HOW: Provides minimal, focused implementations for each loop type:
 *      - For loops: Basic Enum.each for iteration
 *      - While loops: Tail-recursive helper functions
 *      - Do-while loops: Modified recursive pattern with initial execution
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Only compiles loops, no optimization
 * - Testability: Simple functions with clear inputs/outputs
 * - Maintainability: Under 800 lines vs 4,235 in LoopCompiler
 * - Clarity: No mixing of concerns between compilation and optimization
 * - Extensibility: Clean base for optimization layers to build upon
 * 
 * EDGE CASES:
 * - Break/continue require special handling in recursive functions
 * - Variable mutations need careful scope management
 * - Nested loops must maintain separate contexts
 * - Empty loop bodies still need valid Elixir syntax
 */
@:nullSafety(Off)
class CoreLoopCompiler {
    
    /** Reference to main compiler for expression compilation */
    var compiler: ElixirCompiler;
    
    /** Counter for generating unique helper function names */
    static var helperFunctionCounter: Int = 0;
    
    /**
     * Constructor requiring main compiler reference
     * 
     * @param compiler Main ElixirCompiler instance for delegation
     */
    public function new(compiler: ElixirCompiler) {
        this.compiler = compiler;
    }
    
    /**
     * Compiles a basic for loop without optimizations
     * 
     * WHY: For loops are fundamental control structures that need correct compilation
     * WHAT: Transforms for-in loops to Enum.each operations
     * HOW: Extracts loop variable, compiles iterator and body, wraps in Enum.each
     * 
     * @param tvar Loop variable
     * @param iterExpr Expression producing the iterable
     * @param blockExpr Loop body
     * @return Basic Enum.each implementation
     */
    public function compileBasicForLoop(tvar: TVar, iterExpr: TypedExpr, blockExpr: TypedExpr): String {
        #if debug_core_loops
//         trace('[CoreLoopCompiler] Compiling basic for loop');
//         trace('[CoreLoopCompiler] Loop var: ${tvar.name}');
        #end
        
        var loopVar = toElixirVarName(tvar);
        var iterable = compiler.compileExpression(iterExpr);
        var body = compiler.compileExpression(blockExpr);
        
        // Handle different iterator types
        var iteratorCode = switch(iterExpr.expr) {
            case TypedExprDef.TCall(e, _):
                // Check for range iterator (0...n)
                var callStr = compiler.compileExpression(e);
                if (callStr.indexOf("IntIterator.new") >= 0) {
                    // Extract range bounds for IntIterator
                    handleIntIterator(iterExpr);
                } else {
                    iterable; // Use compiled expression as-is
                }
            default:
                iterable;
        };
        
        #if debug_core_loops
//         trace('[CoreLoopCompiler] Generated: Enum.each over ${iteratorCode}');
        #end
        
        return 'Enum.each(${iteratorCode}, fn ${loopVar} ->
${indentCode(body)}
end)';
    }
    
    /**
     * Compiles a basic while loop without optimizations
     * 
     * WHY: While loops need translation to recursive functions in functional Elixir
     * WHAT: Generates a tail-recursive helper function for the while loop
     * HOW: Creates a local recursive function that checks condition and recurses
     * 
     * @param econd Loop condition
     * @param ebody Loop body
     * @param normalWhile true for while, false for do-while
     * @return Recursive function implementation
     */
    public function compileBasicWhileLoop(econd: TypedExpr, ebody: TypedExpr, normalWhile: Bool): String {
        #if debug_core_loops
//         trace('[CoreLoopCompiler] Compiling basic while loop (normal: ${normalWhile})');
        #end
        
        var condition = compiler.compileExpression(econd);
        var body = compiler.compileExpression(ebody);
        
        if (normalWhile) {
            // Standard while loop - check condition first
            return generateWhileHelper(condition, body);
        } else {
            // Do-while loop - execute body at least once
            return generateDoWhileHelper(condition, body);
        }
    }
    
    /**
     * Compiles a do-while loop (execute body then check condition)
     * 
     * WHY: Do-while guarantees at least one execution of the body
     * WHAT: Modified recursive pattern with initial body execution
     * HOW: Executes body once, then enters recursive loop if condition holds
     * 
     * @param econd Loop condition
     * @param ebody Loop body
     * @return Do-while implementation with guaranteed first execution
     */
    public function compileDoWhileLoop(econd: TypedExpr, ebody: TypedExpr): String {
        return compileBasicWhileLoop(econd, ebody, false);
    }
    
    /**
     * Generates a helper function for standard while loops
     * 
     * WHY: Elixir doesn't have imperative while loops, needs recursion
     * WHAT: Creates an inline recursive function with condition checking
     * HOW: Defines and immediately calls a tail-recursive function
     * 
     * @param condition Compiled condition expression
     * @param body Compiled body expression
     * @return Inline recursive function
     */
    private function generateWhileHelper(condition: String, body: String): String {
        var helperId = getNextHelperId();
        
        #if debug_core_loops
//         trace('[CoreLoopCompiler] Generating while helper ${helperId}');
        #end
        
        // Use Stream.unfold for idiomatic Elixir loops
        // This is what Elixir developers would actually write
        return 'Stream.unfold(nil, fn _ ->
  if ${condition} do
${indentCode(body, 4)}
    {nil, nil}
  else
    nil
  end
end) |> Stream.run()';
    }
    
    /**
     * Generates a helper function for do-while loops
     * 
     * WHY: Do-while needs at least one execution before condition check
     * WHAT: Modified recursive pattern with guaranteed first execution
     * HOW: Executes body once, then enters conditional recursion
     * 
     * @param condition Compiled condition expression
     * @param body Compiled body expression
     * @return Do-while implementation
     */
    private function generateDoWhileHelper(condition: String, body: String): String {
        var helperId = getNextHelperId();
        
        #if debug_core_loops
//         trace('[CoreLoopCompiler] Generating do-while helper ${helperId}');
        #end
        
        // Execute body once, then use Stream.unfold for remaining iterations
        return '(
  # Execute body at least once
${indentCode(body)}
  
  # Then use idiomatic stream pattern for remaining iterations
  Stream.unfold(nil, fn _ ->
    if ${condition} do
${indentCode(body, 6)}
      {nil, nil}
    else
      nil
    end
  end) |> Stream.run()
)';
    }
    
    /**
     * Handles IntIterator for range-based loops
     * 
     * WHY: Haxe's IntIterator (0...n) should map to Elixir ranges
     * WHAT: Extracts range bounds and generates appropriate range syntax
     * HOW: Analyzes IntIterator.new call to extract start/end values
     * 
     * @param iterExpr The IntIterator expression
     * @return Elixir range expression (e.g., "0..4")
     */
    private function handleIntIterator(iterExpr: TypedExpr): String {
        // Extract range bounds from IntIterator.new(start, end) call
        switch(iterExpr.expr) {
            case TypedExprDef.TCall(_, args) if (args.length == 2):
                var start = compiler.compileExpression(args[0]);
                var end = compiler.compileExpression(args[1]);
                
                // Haxe ranges are exclusive, Elixir ranges are inclusive
                // So 0...5 in Haxe becomes 0..4 in Elixir
                return '${start}..(${end} - 1)';
                
            default:
                // Fallback to compiled expression
                return compiler.compileExpression(iterExpr);
        }
    }
    
    /**
     * Compiles break statement in loop context
     * 
     * WHY: Break needs special handling in recursive functions
     * WHAT: Generates early return from recursive function
     * HOW: Returns a special value that stops recursion
     * 
     * @return Break implementation for current loop context
     */
    public function compileBreak(): String {
        #if debug_core_loops
//         trace('[CoreLoopCompiler] Compiling break statement');
        #end
        
        // In recursive functions, break is implemented as early return
        // This needs to be handled by the loop generator to check for break values
        return '{:break, nil}';
    }
    
    /**
     * Compiles continue statement in loop context
     * 
     * WHY: Continue needs to skip to next iteration
     * WHAT: Generates immediate recursive call
     * HOW: Calls the loop function without executing remaining body
     * 
     * @return Continue implementation for current loop context
     */
    public function compileContinue(): String {
        #if debug_core_loops
//         trace('[CoreLoopCompiler] Compiling continue statement');
        #end
        
        // Continue is implemented as immediate recursion
        // The loop function needs to be in scope for this to work
        return '{:continue, nil}';
    }
    
    /**
     * Handles variable mutations within loops
     * 
     * WHY: Elixir is immutable, so mutations need special handling
     * WHAT: Tracks modified variables for proper scoping
     * HOW: Returns list of variables that need to be passed through recursion
     * 
     * @param loopBody The loop body to analyze
     * @return List of mutated variables
     */
    public function detectMutatedVariables(loopBody: TypedExpr): Array<String> {
        var mutatedVars: Array<String> = [];
        
        function analyze(expr: TypedExpr): Void {
            switch(expr.expr) {
                case TypedExprDef.TBinop(OpAssign | OpAssignOp(_), e1, _):
                    switch(e1.expr) {
                        case TypedExprDef.TLocal(v):
                            var varName = toElixirVarName(v);
                            if (mutatedVars.indexOf(varName) == -1) {
                                mutatedVars.push(varName);
                            }
                        default:
                    }
                default:
                    TypedExprTools.iter(expr, analyze);
            }
        }
        
        analyze(loopBody);
        
        #if debug_core_loops
//         trace('[CoreLoopCompiler] Detected mutated variables: ${mutatedVars}');
        #end
        
        return mutatedVars;
    }
    
    /**
     * Generates a while loop with mutable state
     * 
     * WHY: Loops often modify variables that need to persist across iterations
     * WHAT: Creates recursive function with state parameters
     * HOW: Passes mutated variables as parameters through recursion
     * 
     * @param condition Loop condition
     * @param body Loop body
     * @param mutatedVars Variables that are modified in the loop
     * @return Stateful recursive implementation
     */
    public function generateStatefulWhileLoop(condition: String, body: String, mutatedVars: Array<String>): String {
        var helperId = getNextHelperId();
        
        #if debug_core_loops
//         trace('[CoreLoopCompiler] Generating stateful while loop with vars: ${mutatedVars}');
        #end
        
        if (mutatedVars.length == 0) {
            // No state to track, use simple version
            return generateWhileHelper(condition, body);
        }
        
        // Generate parameter list for state
        var params = mutatedVars.join(", ");
        var args = mutatedVars.join(", ");
        
        // Note: Body needs to be modified to return updated state
        // This is a simplified version - full implementation would transform the body
        return '(
  loop_${helperId} = fn ${params}, loop_fn ->
    if ${condition} do
      # Body should update and return state
${indentCode(body, 6)}
      # Recursive call with updated state
      loop_fn.(${args}, loop_fn)
    else
      {${params}}
    end
  end
  
  # Initial call with current state
  {${params}} = loop_${helperId}.(${args}, loop_${helperId})
)';
    }
    
    // ═══════════════════════════════════════════════════════════════════
    // UTILITY FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════
    
    /**
     * Converts Haxe variable to Elixir naming convention
     * 
     * @param tvar The typed variable
     * @return Snake_case Elixir variable name
     */
    private function toElixirVarName(tvar: TVar): String {
        // Delegate to naming utilities (simplified here)
        return CompilerUtilities.toElixirVarName(tvar);
    }
    
    /**
     * Indents code for proper formatting
     * 
     * @param code Code to indent
     * @param spaces Number of spaces (default: 2)
     * @return Indented code
     */
    private function indentCode(code: String, spaces: Int = 2): String {
        return CompilerUtilities.indentCode(code, spaces);
    }
    
    /**
     * Gets next unique helper function ID
     * 
     * @return Unique helper function identifier
     */
    private function getNextHelperId(): Int {
        return ++helperFunctionCounter;
    }
    
    /**
     * Checks if expression contains break or continue
     * 
     * WHY: Break/continue affect how we generate loop code
     * WHAT: Recursively searches for control flow statements
     * HOW: Traverses AST looking for TBreak/TContinue
     * 
     * @param expr Expression to analyze
     * @return true if break/continue found
     */
    public function hasBreakOrContinue(expr: TypedExpr): Bool {
        var found = false;
        
        function check(e: TypedExpr): Void {
            if (found) return;
            
            switch(e.expr) {
                case TypedExprDef.TBreak | TypedExprDef.TContinue:
                    found = true;
                case TypedExprDef.TWhile(_, _, _) | TypedExprDef.TFor(_, _, _):
                    // Don't check inside nested loops
                    return;
                default:
                    TypedExprTools.iter(e, check);
            }
        }
        
        check(expr);
        return found;
    }
    
    /**
     * Compile while loop with variable renamings applied
     * 
     * WHY: Support variable substitution during while loop compilation for proper scope management
     * WHAT: Applies variable renaming map during while loop code generation  
     * HOW: Transforms condition and body with renamings, then generates idiomatic recursive pattern
     * 
     * This method handles cases where while loops need to be compiled with specific
     * variable renamings for integration with surrounding code patterns, particularly
     * in desugared array operations.
     * 
     * @param econd The while loop condition
     * @param ebody The while loop body
     * @param normalWhile True for while loops, false for do-while
     * @param renamings Map of original variable names to target names
     * @return Generated Elixir code for the while loop with renamings applied
     */
    public function compileWhileLoopWithRenamings(econd: TypedExpr, ebody: TypedExpr, normalWhile: Bool, renamings: Map<String, String>): String {
        #if debug_loops
        // trace('[XRay CoreLoop] Compiling while loop with renamings');
        // trace('[XRay CoreLoop] Renamings: ${[for (k in renamings.keys()) '$k -> ${renamings[k]}'].join(", ")}');
        #end
        
        // Apply renamings during compilation
        var transformedCondition = compiler.compileExpressionWithRenaming(econd, renamings);
        var transformedBody = compiler.compileExpressionWithRenaming(ebody, renamings);
        
        // Ensure variable mappings are established in the current context
        function ensureVariableMapping(expr: TypedExpr): Void {
            switch (expr.expr) {
                case TLocal(v):
                    var originalName = toElixirVarName(v);
                    if (renamings.exists(originalName)) {
                        // Add to current function parameter mapping for consistency
                        compiler.currentFunctionParameterMap.set(originalName, renamings.get(originalName));
                    }
                case TBlock(expressions):
                    for (e in expressions) ensureVariableMapping(e);
                case TBinop(_, e1, e2):
                    ensureVariableMapping(e1);
                    ensureVariableMapping(e2);
                case TCall(e, args):
                    ensureVariableMapping(e);
                    for (arg in args) ensureVariableMapping(arg);
                case TIf(cond, ifExpr, elseExpr):
                    ensureVariableMapping(cond);
                    ensureVariableMapping(ifExpr);
                    if (elseExpr != null) ensureVariableMapping(elseExpr);
                case TWhile(cond, body, _):
                    ensureVariableMapping(cond);
                    ensureVariableMapping(body);
                case TFor(_, it, body):
                    ensureVariableMapping(it);
                    ensureVariableMapping(body);
                case TVar(_, init):
                    if (init != null) ensureVariableMapping(init);
                case _:
            }
        }
        
        ensureVariableMapping(econd);
        ensureVariableMapping(ebody);
        
        // Generate idiomatic Elixir recursive function pattern (no Y combinator)
        // Use a module-level private function or Stream.unfold for complex loops
        if (normalWhile) {
            // For simple loops with renamings, use Stream.unfold pattern
            return 'Stream.unfold(nil, fn _ ->\n' +
                   '  if ${transformedCondition} do\n' +
                   '    ${indentCode(transformedBody, 4)}\n' +
                   '    {nil, nil}\n' +
                   '  else\n' +
                   '    nil\n' +
                   '  end\n' +
                   'end) |> Stream.run()';
        } else {
            // do-while: execute once, then use Stream.unfold for remaining iterations
            return '(\n' +
                   '  ${transformedBody}\n' +
                   '  Stream.unfold(nil, fn _ ->\n' +
                   '    if ${transformedCondition} do\n' +
                   '      ${indentCode(transformedBody, 6)}\n' +
                   '      {nil, nil}\n' +
                   '    else\n' +
                   '      nil\n' +
                   '    end\n' +
                   '  end) |> Stream.run()\n' +
                   ')';
        }
    }
}

#end