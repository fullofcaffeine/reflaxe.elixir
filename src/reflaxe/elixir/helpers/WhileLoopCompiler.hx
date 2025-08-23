package reflaxe.elixir.helpers;

import haxe.macro.Type;
import haxe.macro.Type.TypedExpr;
import haxe.macro.Type.TVar;
import reflaxe.elixir.helpers.NamingHelper;
import reflaxe.elixir.helpers.DebugHelper;

using StringTools;
using Lambda;

/**
 * WhileLoopCompiler: Advanced While Loop Compilation and Optimization
 * 
 * WHY: Extract complex while loop compilation logic from main compiler
 * - While loop compilation was 1,000+ lines of the most complex code in ElixirCompiler
 * - Y combinator pattern generation required sophisticated AST analysis and transformation
 * - Array building pattern detection needed specialized algorithms for optimization
 * - Variable mutation tracking and functional transformation required dedicated focus
 * - Separation enables comprehensive testing of loop compilation edge cases
 * 
 * WHAT: Comprehensive while loop compilation and optimization utilities
 * - Compiles TWhile expressions to idiomatic Elixir recursive patterns
 * - Detects and optimizes array building patterns using Enum functions
 * - Generates Y combinator patterns for complex stateful loops
 * - Transforms imperative mutations to functional state passing
 * - Provides specialized compilation for do-while vs while patterns
 * 
 * HOW: Advanced AST analysis and functional transformation algorithms
 * - Analyzes loop bodies to detect optimization opportunities (array building, counting, etc.)
 * - Tracks variable mutations and generates functional state management
 * - Uses Y combinator patterns for complex loops with multiple state variables
 * - Applies variable substitution and renaming for consistent code generation
 * - Integrates with ArrayOptimizationCompiler for functional Enum patterns
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Focused exclusively on while loop compilation complexity
 * - Open/Closed Principle: Extensible for new loop optimization patterns without modification
 * - Testability: Isolated loop logic enables comprehensive edge case testing
 * - Maintainability: Clear separation from expression and method compilation concerns
 * - Performance: Optimized loop detection algorithms with pattern-specific optimizations
 * 
 * LOOP COMPILATION STRATEGIES:
 * 1. **Array Building Detection**: Converts imperative array building to Enum.map/filter/reduce
 * 2. **Simple Loops**: Uses lightweight recursive patterns for stateless loops
 * 3. **Complex Stateful Loops**: Generates Y combinator patterns with state tuple passing
 * 4. **Do-While vs While**: Handles execution order differences correctly
 * 5. **Variable Mutation Tracking**: Transforms mutable operations to functional updates
 * 
 * FUTURE DIRECTION:
 * While loop Y combinator patterns are a transitional solution for complex loop compilation.
 * These patterns will be replaced with more idiomatic Elixir approaches:
 * - Stream-based iteration for large datasets (Stream.iterate, Stream.unfold)
 * - Tail-recursive functions with accumulator patterns
 * - GenServer-based iteration for stateful loops
 * - Process-based parallelization for concurrent iteration
 * - Native Elixir recursion patterns instead of JavaScript-style Y combinators
 * 
 * The Y combinator approach was adopted from JavaScript compilation patterns but
 * doesn't align with Elixir's functional programming paradigms. Future versions
 * will generate native Elixir patterns that are more performant and idiomatic.
 * 
 * EDGE CASES:
 * - Complex nested loops requiring multiple Y combinator levels
 * - Array building patterns with complex transformations
 * - Variable scoping issues in Y combinator state management
 * - Break/continue semantics translation to functional patterns
 * - Performance optimization for deeply nested loop analysis
 * 
 * @see documentation/WHILE_LOOP_COMPILATION.md - Complete while loop compilation reference
 * @see documentation/Y_COMBINATOR_PATTERNS.md - Y combinator pattern documentation
 * @see documentation/FUTURE_ELIXIR_PATTERNS.md - Planned idiomatic replacements
 */
@:nullSafety(Off)
class WhileLoopCompiler {
    var compiler: reflaxe.elixir.ElixirCompiler;
    
    public function new(compiler: reflaxe.elixir.ElixirCompiler) {
        this.compiler = compiler;
    }
    
    /**
     * Compile while loop with variable renamings applied.
     * 
     * WHY: Support variable substitution during while loop compilation
     * WHAT: Applies variable renaming map during while loop code generation
     * HOW: Delegates to main while loop compilation with renaming context
     * 
     * This function handles the case where while loops need to be compiled
     * with specific variable renamings for proper scope management and
     * integration with surrounding code patterns.
     * 
     * @param econd The while loop condition
     * @param ebody The while loop body
     * @param normalWhile True for while loops, false for do-while
     * @param renamings Map of original variable names to target names
     * @return Generated Elixir code for the while loop
     */
    public function compileWhileLoopWithRenamings(econd: TypedExpr, ebody: TypedExpr, normalWhile: Bool, renamings: Map<String, String>): String {
        #if debug_patterns
        DebugHelper.debugPattern("While loop with renamings", "Variable substitution compilation", 'normalWhile: $normalWhile, renamings: ${[for (k in renamings.keys()) '$k -> ${renamings[k]}'].join(", ")}');
        #end
        
        // Apply renamings during compilation
        var transformedCondition = compiler.compileExpressionWithRenaming(econd, renamings);
        var transformedBody = compiler.compileExpressionWithRenaming(ebody, renamings);
        
        // Ensure variable mappings are established in the current context
        function ensureVariableMapping(expr: TypedExpr): Void {
            switch (expr.expr) {
                case TLocal(v):
                    var originalName = compiler.getOriginalVarName(v);
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
        
        // Use Y combinator pattern for renamed while loops
        if (normalWhile) {
            return '(\n' +
                   '  loop_helper = fn loop_fn ->\n' +
                   '    if ${transformedCondition} do\n' +
                   '      try do\n' +
                   '        ${transformedBody}\n' +
                   '        loop_fn.(loop_fn)\n' +
                   '      catch\n' +
                   '        :break -> nil\n' +
                   '        :continue -> loop_fn.(loop_fn)\n' +
                   '      end\n' +
                   '    else\n' +
                   '      nil\n' +
                   '    end\n' +
                   '  end\n' +
                   '  try do\n' +
                   '    loop_helper.(loop_helper)\n' +
                   '  catch\n' +
                   '    :break -> nil\n' +
                   '  end\n' +
                   ')';
        } else {
            // do-while with renamings
            return '(\n' +
                   '  ${transformedBody}\n' +
                   '  loop_helper = fn loop_fn ->\n' +
                   '    if ${transformedCondition} do\n' +
                   '      ${transformedBody}\n' +
                   '      loop_fn.(loop_fn)\n' +
                   '    else\n' +
                   '      nil\n' +
                   '    end\n' +
                   '  end\n' +
                   '  loop_helper.(loop_helper)\n' +
                   ')';
        }
    }
    
    /**
     * Main while loop compilation function with comprehensive optimization detection.
     * 
     * WHY: Provide comprehensive while loop compilation with multiple optimization strategies
     * WHAT: Analyzes loop patterns and applies appropriate compilation strategies
     * HOW: Uses pattern detection, variable analysis, and Y combinator generation
     * 
     * This is the main entry point for while loop compilation. It performs comprehensive
     * analysis of the loop structure to determine the most appropriate compilation strategy:
     * 
     * 1. Array building pattern detection for Enum function optimization
     * 2. Variable mutation analysis for functional state management
     * 3. Y combinator generation for complex stateful loops
     * 4. Simple recursive patterns for stateless loops
     * 
     * The function generates idiomatic Elixir code that preserves the semantics of the
     * original while loop while leveraging Elixir's functional programming strengths.
     * 
     * @param econd The while loop condition expression
     * @param ebody The while loop body expression
     * @param normalWhile True for while loops, false for do-while loops
     * @return Generated Elixir code for the while loop
     */
    public function compileWhileLoop(econd: TypedExpr, ebody: TypedExpr, normalWhile: Bool): String {
        // TEMPORARY DEBUG: Check if we're getting any array operations
        var condStr = compiler.compileExpression(econd);
        if (condStr.indexOf("length") >= 0) {
            trace('[DEBUG WHILE] Found length in WhileLoopCompiler: ${condStr}');
        }
        #if debug_patterns
        DebugHelper.debugPattern("Y combinator generation", "While loop compilation", 'normalWhile: $normalWhile');
        #end
        
        #if debug_ast
        DebugHelper.debugAST("While loop condition", econd);
        DebugHelper.debugAST("While loop body", ebody);
        #end
        
        // First check if this is an array-building pattern that wasn't optimized
        var arrayBuildPattern = detectArrayBuildingPattern(ebody);
        if (arrayBuildPattern != null) {
            return compileArrayBuildingLoop(econd, ebody, arrayBuildPattern);
        }
        
        // Extract variables that are modified in the loop
        var modifiedVars = extractModifiedVariables(ebody);
        var condition = compiler.compileExpression(econd);
        
        // Transform the loop body to handle mutations functionally
        var transformedBody = transformLoopBodyMutations(ebody, modifiedVars, normalWhile, condition);
        
        if (normalWhile) {
            // while (condition) { body }
            if (modifiedVars.length > 0) {
                // Convert variable names to snake_case for consistency
                var stateVarsInit = modifiedVars.map(v -> {
                    var snakeName = NamingHelper.toSnakeCase(v.name);
                    return snakeName;
                });
                var stateVars = stateVarsInit.join(", ");
                
                // Generate initial values - use nil for all loop variables
                var initialValues = modifiedVars.map(v -> {
                    return "nil";
                }).join(", ");
                
                // Use a simple recursive pattern that avoids scoping issues
                // by passing the function as a parameter (Y combinator style)
                #if debug_y_combinator
                DebugHelper.debugYCombinator("Y combinator generation", "Building complex pattern", 'stateVars: $stateVars, condition: $condition');
                #end
                
                var yCombinatorResult = '(\n' +
                       '  loop_helper = fn loop_fn, {${stateVars}} ->\n' +
                       '    if ${condition} do\n' +
                       '      try do\n' +
                       '        ${transformedBody}\n' +
                       '        loop_fn.(loop_fn, {${stateVars}})\n' +
                       '      catch\n' +
                       '        :break -> {${stateVars}}\n' +
                       '        :continue -> loop_fn.(loop_fn, {${stateVars}})\n' +
                       '      end\n' +
                       '    else\n' +
                       '      {${stateVars}}\n' +
                       '    end\n' +
                       '  end\n' +
                       '  {${stateVars}} = try do\n' +
                       '    loop_helper.(loop_helper, {${initialValues}})\n' +
                       '  catch\n' +
                       '    :break -> {${initialValues}}\n' +
                       '  end\n' +
                       ')';
                
                #if debug_y_combinator
                DebugHelper.debugYCombinator("Y combinator generation", "Complex pattern complete", 'Result: ${yCombinatorResult.substring(0, 100)}...');
                #end
                
                return yCombinatorResult;
            } else {
                // Simple loop without state - use Y combinator pattern
                var body = compiler.compileExpression(ebody);
                return '(\n' +
                       '  loop_helper = fn loop_fn ->\n' +
                       '    if ${condition} do\n' +
                       '      try do\n' +
                       '        ${body}\n' +
                       '        loop_fn.(loop_fn)\n' +
                       '      catch\n' +
                       '        :break -> nil\n' +
                       '        :continue -> loop_fn.(loop_fn)\n' +
                       '      end\n' +
                       '    else\n' +
                       '      nil\n' +
                       '    end\n' +
                       '  end\n' +
                       '  try do\n' +
                       '    loop_helper.(loop_helper)\n' +
                       '  catch\n' +
                       '    :break -> nil\n' +
                       '  end\n' +
                       ')';
            }
        } else {
            // do { body } while (condition)
            if (modifiedVars.length > 0) {
                // Convert variable names to snake_case for consistency
                var stateVarsInit = modifiedVars.map(v -> {
                    var snakeName = NamingHelper.toSnakeCase(v.name);
                    return snakeName;
                });
                var stateVars = stateVarsInit.join(", ");
                
                // Generate initial values
                var initialValues = modifiedVars.map(v -> {
                    return "nil";
                }).join(", ");
                
                // For do-while, execute body once then use recursive pattern
                return '(\n' +
                       '  {${stateVars}} = {${initialValues}}\n' +
                       '  ${transformedBody}\n' +
                       '  loop_helper = fn loop_fn, {${stateVars}} ->\n' +
                       '    if ${condition} do\n' +
                       '      ${transformedBody}\n' +
                       '      loop_fn.(loop_fn, {${stateVars}})\n' +
                       '    else\n' +
                       '      {${stateVars}}\n' +
                       '    end\n' +
                       '  end\n' +
                       '  {${stateVars}} = loop_helper.(loop_helper, {${stateVars}})\n' +
                       ')';
            } else {
                var body = compiler.compileExpression(ebody);
                return '(\n' +
                       '  ${body}\n' +
                       '  loop_helper = fn loop_fn ->\n' +
                       '    if ${condition} do\n' +
                       '      ${body}\n' +
                       '      loop_fn.(loop_fn)\n' +
                       '    else\n' +
                       '      nil\n' +
                       '    end\n' +
                       '  end\n' +
                       '  loop_helper.(loop_helper)\n' +
                       ')';
            }
        }
    }
    
    /**
     * Detect if a loop body is building an array (common desugared pattern).
     * 
     * WHY: Array building is a common pattern that can be optimized to Enum functions
     * WHAT: Analyzes loop body structure to identify array construction patterns
     * HOW: Looks for specific AST patterns involving array concatenation and index variables
     * 
     * Array building patterns often come from desugared array comprehensions or
     * manual array construction loops. These can be converted to more idiomatic
     * Elixir patterns using Enum.map, Enum.filter, or Enum.reduce functions.
     * 
     * Detection patterns:
     * - Index variable increment (i++)
     * - Array variable concatenation (arr = arr ++ [item])
     * - Element access from source array (array[i])
     * 
     * @param ebody The loop body expression to analyze
     * @return Pattern info if detected: {indexVar, accumVar, arrayExpr}
     */
    public function detectArrayBuildingPattern(ebody: TypedExpr): Null<{indexVar: String, accumVar: String, arrayExpr: String}> {
        // Look for patterns like:
        // _g = 0;
        // _g1 = [];
        // while (_g < array.length) {
        //     var item = array[_g];
        //     _g++;
        //     _g1 = _g1 ++ [transform(item)];
        // }
        
        var indexVar: String = null;
        var accumVar: String = null;
        var arrayExpr: String = null;
        
        function checkExpr(expr: TypedExpr): Bool {
            switch (expr.expr) {
                case TBlock(exprs):
                    for (e in exprs) {
                        if (checkExpr(e)) return true;
                    }
                case TBinop(OpAssign, e1, e2):
                    // Look for array concatenation pattern: var = var ++ [...]
                    switch (e1.expr) {
                        case TLocal(v):
                            var varName = compiler.getOriginalVarName(v);
                            switch (e2.expr) {
                                case TBinop(OpAdd, e3, e4):
                                    // Check if this is array concatenation
                                    switch (e3.expr) {
                                        case TLocal(v2) if (compiler.getOriginalVarName(v2) == varName):
                                            // Found pattern: var = var ++ something
                                            // Check if the right side is an array
                                            switch (e4.expr) {
                                                case TArrayDecl(_):
                                                    accumVar = varName;
                                                    return true;
                                                case _:
                                            }
                                        case _:
                                    }
                                case _:
                            }
                        case _:
                    }
                case TUnop(OpIncrement, _, e):
                    // Look for index increment
                    switch (e.expr) {
                        case TLocal(v):
                            indexVar = compiler.getOriginalVarName(v);
                        case _:
                    }
                case _:
            }
            return false;
        }
        
        if (checkExpr(ebody)) {
            if (indexVar != null && accumVar != null) {
                return {
                    indexVar: indexVar,
                    accumVar: accumVar,
                    arrayExpr: "[]"  // Will be determined from context
                };
            }
        }
        
        return null;
    }
    
    /**
     * Compile array building loop using idiomatic Elixir Enum functions.
     * 
     * WHY: Convert imperative array building to functional Enum operations
     * WHAT: Transforms array building loops into Enum.map, Enum.filter, or similar
     * HOW: Analyzes the array building pattern and generates appropriate Enum calls
     * 
     * Array building patterns can be optimized into more idiomatic Elixir code
     * using the Enum module functions. This provides better performance and
     * more readable code compared to imperative loop patterns.
     * 
     * @param econd The loop condition (usually index < array.length)
     * @param ebody The loop body containing array building logic
     * @param pattern The detected array building pattern info
     * @return Generated Elixir code using Enum functions
     */
    public function compileArrayBuildingLoop(econd: TypedExpr, ebody: TypedExpr, pattern: {indexVar: String, accumVar: String, arrayExpr: String}): String {
        #if debug_patterns
        DebugHelper.debugPattern("Array building optimization", "Converting to Enum functions", 'indexVar: ${pattern.indexVar}, accumVar: ${pattern.accumVar}');
        #end
        
        // Try to extract the transformation applied to each element
        var transformation = extractArrayTransformation(ebody, pattern.indexVar, pattern.accumVar);
        
        // For now, use a generic Enum.map pattern
        // In the future, this could detect specific patterns like filter, reduce, etc.
        if (transformation != null) {
            return 'Enum.map(${pattern.arrayExpr}, fn ${pattern.indexVar} -> ${transformation} end)';
        } else {
            // Fallback to generic while loop compilation
            return compileWhileLoopGeneric(econd, ebody, true);
        }
    }
    
    /**
     * Extract the transformation applied to array elements in building pattern.
     * 
     * WHY: Identify the transformation logic for Enum function generation
     * WHAT: Analyzes loop body to extract element transformation expression
     * HOW: Traverses AST to find the expression used to transform array elements
     * 
     * This function analyzes the loop body to identify how individual array
     * elements are transformed during the building process. This information
     * is used to generate appropriate Enum.map or similar function calls.
     * 
     * @param ebody The loop body expression
     * @param indexVar The index variable name
     * @param accumVar The accumulator variable name
     * @return The transformation expression or null if not found
     */
    public function extractArrayTransformation(ebody: TypedExpr, indexVar: String, accumVar: String): Null<String> {
        function findTransform(expr: TypedExpr): Null<String> {
            switch (expr.expr) {
                case TBlock(expressions):
                    for (e in expressions) {
                        var result = findTransform(e);
                        if (result != null) return result;
                    }
                case TBinop(OpAssign, target, value):
                    // Look for assignment to accumulator
                    switch (target.expr) {
                        case TLocal(v) if (compiler.getOriginalVarName(v) == accumVar):
                            switch (value.expr) {
                                case TBinop(OpAdd, _, arrayExpr):
                                    switch (arrayExpr.expr) {
                                        case TArrayDecl(elements):
                                            if (elements.length > 0) {
                                                return compiler.compileExpression(elements[0]);
                                            }
                                        case _:
                                    }
                                case _:
                            }
                        case _:
                    }
                case _:
            }
            return null;
        }
        
        return findTransform(ebody);
    }
    
    /**
     * Generic while loop compilation fallback.
     * 
     * WHY: Provide fallback compilation for complex loops that can't be optimized
     * WHAT: Generates standard Y combinator pattern for any while loop
     * HOW: Uses variable mutation tracking and functional state management
     * 
     * This function provides a generic compilation approach for while loops
     * that don't match specific optimization patterns. It analyzes variable
     * mutations and generates appropriate Y combinator patterns with state
     * management for functional equivalence to the original loop.
     * 
     * @param econd The loop condition expression
     * @param ebody The loop body expression
     * @param normalWhile True for while loops, false for do-while
     * @return Generated Elixir code using Y combinator pattern
     */
    public function compileWhileLoopGeneric(econd: TypedExpr, ebody: TypedExpr, normalWhile: Bool): String {
        #if debug_patterns
        DebugHelper.debugPattern("Generic while loop", "Y combinator pattern", 'normalWhile: $normalWhile');
        #end
        
        var condition = compiler.compileExpression(econd);
        var body = compiler.compileExpression(ebody);
        
        // Extract variables that are modified in the loop for state management
        var modifiedVars = extractModifiedVariables(ebody);
        
        if (modifiedVars.length > 0) {
            // Complex loop with state variables
            var stateVars = modifiedVars.map(v -> NamingHelper.toSnakeCase(v.name)).join(", ");
            var initialValues = modifiedVars.map(v -> "nil").join(", ");
            
            if (normalWhile) {
                return '(\n' +
                       '  loop_helper = fn loop_fn, {${stateVars}} ->\n' +
                       '    if ${condition} do\n' +
                       '      ${body}\n' +
                       '      loop_fn.(loop_fn, {${stateVars}})\n' +
                       '    else\n' +
                       '      {${stateVars}}\n' +
                       '    end\n' +
                       '  end\n' +
                       '  {${stateVars}} = loop_helper.(loop_helper, {${initialValues}})\n' +
                       ')';
            } else {
                return '(\n' +
                       '  {${stateVars}} = {${initialValues}}\n' +
                       '  ${body}\n' +
                       '  loop_helper = fn loop_fn, {${stateVars}} ->\n' +
                       '    if ${condition} do\n' +
                       '      ${body}\n' +
                       '      loop_fn.(loop_fn, {${stateVars}})\n' +
                       '    else\n' +
                       '      {${stateVars}}\n' +
                       '    end\n' +
                       '  end\n' +
                       '  {${stateVars}} = loop_helper.(loop_helper, {${stateVars}})\n' +
                       ')';
            }
        } else {
            // Simple loop without state
            if (normalWhile) {
                return '(\n' +
                       '  loop_helper = fn loop_fn ->\n' +
                       '    if ${condition} do\n' +
                       '      ${body}\n' +
                       '      loop_fn.(loop_fn)\n' +
                       '    else\n' +
                       '      nil\n' +
                       '    end\n' +
                       '  end\n' +
                       '  loop_helper.(loop_helper)\n' +
                       ')';
            } else {
                return '(\n' +
                       '  ${body}\n' +
                       '  loop_helper = fn loop_fn ->\n' +
                       '    if ${condition} do\n' +
                       '      ${body}\n' +
                       '      loop_fn.(loop_fn)\n' +
                       '    else\n' +
                       '      nil\n' +
                       '    end\n' +
                       '  end\n' +
                       '  loop_helper.(loop_helper)\n' +
                       ')';
            }
        }
    }
    
    /**
     * Extract variables that are modified within a loop expression.
     * 
     * WHY: Identify variables that need functional state management in loops
     * WHAT: Analyzes expression AST to find variables that are assigned/modified
     * HOW: Recursively traverses expression looking for assignment operations
     * 
     * This function is critical for determining which variables need to be
     * managed as state in functional loop patterns. Variables that are modified
     * within the loop need to be passed through the recursive function calls
     * to maintain their state across iterations.
     * 
     * @param expr The expression to analyze for variable modifications
     * @return Array of modified variables with their names and types
     */
    public function extractModifiedVariables(expr: TypedExpr): Array<{name: String, type: String}> {
        var modifiedVars: Array<{name: String, type: String}> = [];
        
        function analyzeExpr(e: TypedExpr): Void {
            switch (e.expr) {
                case TBinop(OpAssign, target, _):
                    switch (target.expr) {
                        case TLocal(v):
                            var varName = compiler.getOriginalVarName(v);
                            var existingVar = modifiedVars.find(mv -> mv.name == varName);
                            if (existingVar == null) {
                                modifiedVars.push({
                                    name: varName,
                                    type: compiler.typeToString(v.t)
                                });
                            }
                        case _:
                    }
                case TUnop(OpIncrement | OpDecrement, _, target):
                    switch (target.expr) {
                        case TLocal(v):
                            var varName = compiler.getOriginalVarName(v);
                            var existingVar = modifiedVars.find(mv -> mv.name == varName);
                            if (existingVar == null) {
                                modifiedVars.push({
                                    name: varName,
                                    type: compiler.typeToString(v.t)
                                });
                            }
                        case _:
                    }
                case TBlock(expressions):
                    for (expr in expressions) analyzeExpr(expr);
                case TIf(cond, ifExpr, elseExpr):
                    analyzeExpr(cond);
                    analyzeExpr(ifExpr);
                    if (elseExpr != null) analyzeExpr(elseExpr);
                case TWhile(cond, body, _):
                    analyzeExpr(cond);
                    analyzeExpr(body);
                case TFor(_, it, body):
                    analyzeExpr(it);
                    analyzeExpr(body);
                case TCall(e, args):
                    analyzeExpr(e);
                    for (arg in args) analyzeExpr(arg);
                case TBinop(_, e1, e2):
                    analyzeExpr(e1);
                    analyzeExpr(e2);
                case TVar(_, init):
                    if (init != null) analyzeExpr(init);
                case _:
            }
        }
        
        analyzeExpr(expr);
        return modifiedVars;
    }
    
    /**
     * Transform loop body mutations to functional state management.
     * 
     * WHY: Convert imperative mutations to functional state passing patterns
     * WHAT: Transforms assignment operations to state tuple management
     * HOW: Replaces variable assignments with tuple destructuring and reconstruction
     * 
     * This function is responsible for converting imperative-style variable
     * mutations within loop bodies to functional state management patterns
     * that work with Elixir's immutable data structures and Y combinator patterns.
     * 
     * The transformation ensures that:
     * - Variable assignments become tuple updates
     * - State is properly threaded through recursive calls
     * - Original semantics are preserved in functional form
     * 
     * @param expr The loop body expression to transform
     * @param modifiedVars Array of variables that are modified in the loop
     * @param normalWhile True for while loops, false for do-while
     * @param condition The loop condition string for context
     * @return Transformed expression with functional state management
     */
    public function transformLoopBodyMutations(expr: TypedExpr, modifiedVars: Array<{name: String, type: String}>, normalWhile: Bool, condition: String): String {
        return switch (expr.expr) {
            case TBlock(expressions):
                // Transform each expression in the block
                var transformedExprs = expressions.map(e -> transformLoopBodyMutations(e, modifiedVars, normalWhile, condition));
                transformedExprs.join("\n");
                
            case TBinop(OpAssign, target, value):
                switch (target.expr) {
                    case TLocal(v):
                        var varName = compiler.getOriginalVarName(v);
                        var snakeVarName = NamingHelper.toSnakeCase(varName);
                        var compiledValue = compiler.compileExpression(value);
                        // For functional loops, update the variable in the state tuple
                        '${snakeVarName} = ${compiledValue}';
                    case _:
                        compiler.compileExpression(expr);
                }
                
            case TUnop(OpIncrement, _, target):
                switch (target.expr) {
                    case TLocal(v):
                        var varName = compiler.getOriginalVarName(v);
                        var snakeVarName = NamingHelper.toSnakeCase(varName);
                        '${snakeVarName} = ${snakeVarName} + 1';
                    case _:
                        compiler.compileExpression(expr);
                }
                
            case TUnop(OpDecrement, _, target):
                switch (target.expr) {
                    case TLocal(v):
                        var varName = compiler.getOriginalVarName(v);
                        var snakeVarName = NamingHelper.toSnakeCase(varName);
                        '${snakeVarName} = ${snakeVarName} - 1';
                    case _:
                        compiler.compileExpression(expr);
                }
                
            case TVar(v, init):
                // Handle variable declarations in loop body
                var varName = compiler.getOriginalVarName(v);
                var snakeVarName = NamingHelper.toSnakeCase(varName);
                if (init != null) {
                    var initValue = compiler.compileExpression(init);
                    '${snakeVarName} = ${initValue}';
                } else {
                    '${snakeVarName} = nil';
                }
                
            case _:
                // For other expressions, compile normally
                compiler.compileExpression(expr);
        };
    }
}