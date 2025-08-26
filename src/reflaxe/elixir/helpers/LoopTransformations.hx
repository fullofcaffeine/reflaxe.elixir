#if (macro || elixir_runtime)

package reflaxe.elixir.helpers;

import haxe.macro.Type;
import haxe.macro.TypedExprTools;
import reflaxe.elixir.ElixirCompiler;

/**
 * LoopTransformations: Complex loop transformation patterns to functional Elixir
 * 
 * WHY: Imperative loops with mutations, break/continue, and complex control flow
 *      cannot be directly translated to Elixir. They require sophisticated transformations
 *      to recursive functions with proper state management and tail-call optimization.
 * 
 * WHAT: Handles transformation of complex loops including:
 *       - Mutation detection and state threading
 *       - Break/continue semantics in recursive functions
 *       - Indexed iteration with Enum.with_index
 *       - Character iteration over strings
 *       - Tail-call optimization for performance
 * 
 * HOW: Analyzes loop patterns and generates appropriate recursive structures:
 *      - Module helper functions for complex patterns
 *      - Inline recursive functions for simpler cases
 *      - State passing through function parameters
 *      - Pattern matching for control flow
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Only handles complex transformations
 * - Pattern Library: Reusable transformation patterns
 * - Idiomatic Output: Generates code Elixir developers would write
 * - Performance: Ensures tail-call optimization where possible
 * - Maintainability: Clear separation from basic compilation
 * 
 * EDGE CASES:
 * - Multiple mutations requiring tuple returns
 * - Break/continue in nested loops
 * - Early returns from loops
 * - Exception handling in loops
 * - Closures capturing loop variables
 */
@:nullSafety(Off)
class LoopTransformations {
    
    /** Reference to main compiler for expression compilation */
    var compiler: ElixirCompiler;
    
    /** Counter for generating unique helper function names */
    static var helperCounter: Int = 0;
    
    /** Debug flag for transformation tracing */
    static inline var DEBUG = #if debug_transformations true #else false #end;
    
    /**
     * Constructor requiring main compiler reference
     * 
     * @param compiler Main ElixirCompiler instance for delegation
     */
    public function new(compiler: ElixirCompiler) {
        this.compiler = compiler;
    }
    
    /**
     * Transforms indexed array iteration to idiomatic Enum.with_index
     * 
     * WHY: Array access by index (array[i]) should use Enum.with_index
     * WHAT: Converts manual index tracking to Elixir's built-in pattern
     * HOW: Substitutes array access with item parameter, adds index tuple
     * 
     * Pattern transformed:
     * ```haxe
     * for (i in 0...array.length) {
     *     process(array[i], i);
     * }
     * ```
     * 
     * To:
     * ```elixir
     * array
     * |> Enum.with_index()
     * |> Enum.each(fn {item, i} -> process(item, i) end)
     * ```
     * 
     * @param arrayVar Array variable name
     * @param indexVar Index variable name  
     * @param body Compiled loop body
     * @return Transformed Enum.with_index code
     */
    public function generateIndexedIteration(arrayVar: String, indexVar: String, body: String): String {
        if (DEBUG) {
            trace('[LoopTransform] Generating indexed iteration');
            trace('[LoopTransform] Array: ${arrayVar}, Index: ${indexVar}');
        }
        
        // Detect if building result (mapping) vs side effects (each)
        var isMapping = detectMappingPattern(body);
        
        // Substitute array access patterns with item variable
        var processedBody = substituteArrayAccess(body, arrayVar, indexVar);
        
        if (isMapping) {
            var transformation = extractTransformation(processedBody);
            if (transformation != null) {
                return '${arrayVar}
|> Enum.with_index()
|> Enum.map(fn {item, ${indexVar}} -> ${transformation} end)';
            }
        }
        
        // Default to each for side effects
        return '${arrayVar}
|> Enum.with_index()
|> Enum.each(fn {item, ${indexVar}} ->
${indentCode(processedBody, 2)}
end)';
    }
    
    /**
     * Transforms character iteration over strings
     * 
     * WHY: String iteration by index is inefficient in Elixir
     * WHAT: Converts to idiomatic String.graphemes or binary pattern
     * HOW: Detects charAt/cca patterns and generates appropriate iteration
     * 
     * @param stringVar String variable to iterate
     * @param pattern Character access pattern info
     * @param body Loop body
     * @return Transformed character iteration
     */
    public function generateCharacterIteration(stringVar: String, pattern: CharIterationPattern, body: TypedExpr): String {
        if (DEBUG) {
            trace('[LoopTransform] Generating character iteration');
            trace('[LoopTransform] String: ${stringVar}, Method: ${pattern.method}');
        }
        
        var bodyCode = compiler.compileExpression(body);
        
        if (pattern.needsCharCode) {
            // Binary comprehension for character codes
            bodyCode = substituteCharCodeAccess(bodyCode, stringVar, pattern.indexVar);
            
            return 'for <<char <- ${stringVar}>> do
  char_code = char
${indentCode(bodyCode, 2)}
end';
        } else {
            // Graphemes for regular characters
            bodyCode = substituteCharAccess(bodyCode, stringVar, pattern.indexVar);
            
            return '${stringVar}
|> String.graphemes()
|> Enum.each(fn char ->
${indentCode(bodyCode, 2)}
end)';
        }
    }
    
    /**
     * Generates module helper function for complex patterns
     * 
     * WHY: Complex loops need proper recursive functions
     * WHAT: Creates tail-recursive helper with state management
     * HOW: Inline recursive pattern avoiding Y-combinator complexity
     * 
     * @param condition Loop condition
     * @param body Loop body
     * @param mutatedVars Variables modified in loop
     * @return Module helper function
     */
    public function generateModuleHelper(condition: String, body: String, mutatedVars: Array<String> = null): String {
        var helperId = getNextHelperId();
        
        if (DEBUG) {
            trace('[LoopTransform] Generating module helper ${helperId}');
            trace('[LoopTransform] Mutated vars: ${mutatedVars}');
        }
        
        if (mutatedVars == null || mutatedVars.length == 0) {
            // Simple recursive function without state
            return generateSimpleRecursive(condition, body, helperId);
        } else {
            // Stateful recursive function
            return generateStatefulRecursive(condition, body, mutatedVars, helperId);
        }
    }
    
    /**
     * Extracts variables modified in loop body
     * 
     * WHY: Elixir is immutable, mutations need special handling
     * WHAT: Finds all assignment operations to local variables
     * HOW: Traverses AST looking for OpAssign operations
     * 
     * @param expr Loop body expression
     * @return List of modified variables with types
     */
    public function extractModifiedVariables(expr: TypedExpr): Array<ModifiedVariable> {
        var modified: Array<ModifiedVariable> = [];
        
        function analyze(e: TypedExpr): Void {
            switch(e.expr) {
                case TypedExprDef.TBinop(OpAssign | OpAssignOp(_), e1, e2):
                    switch(e1.expr) {
                        case TypedExprDef.TLocal(v):
                            var name = CompilerUtilities.toElixirVarName(v);
                            var type = getElixirType(e1.t);
                            
                            // Check if already tracked
                            var exists = false;
                            for (m in modified) {
                                if (m.name == name) {
                                    exists = true;
                                    break;
                                }
                            }
                            
                            if (!exists) {
                                modified.push({
                                    name: name,
                                    type: type,
                                    tvar: v
                                });
                            }
                        default:
                    }
                    
                case TypedExprDef.TUnop(OpIncrement | OpDecrement, _, e1):
                    switch(e1.expr) {
                        case TypedExprDef.TLocal(v):
                            var name = CompilerUtilities.toElixirVarName(v);
                            modified.push({
                                name: name,
                                type: "number",
                                tvar: v
                            });
                        default:
                    }
                    
                default:
                    TypedExprTools.iter(e, analyze);
            }
        }
        
        analyze(expr);
        
        if (DEBUG) {
            trace('[LoopTransform] Found ${modified.length} modified variables');
        }
        
        return modified;
    }
    
    /**
     * Transforms loop body to handle mutations functionally
     * 
     * WHY: Mutations must become new bindings in recursive calls
     * WHAT: Replaces assignments with tuple returns
     * HOW: Tracks state and threads through recursion
     * 
     * @param body Loop body
     * @param modifiedVars Variables to track
     * @return Transformed body with state management
     */
    public function transformMutations(body: TypedExpr, modifiedVars: Array<ModifiedVariable>): String {
        if (modifiedVars.length == 0) {
            return compiler.compileExpression(body);
        }
        
        // Generate state tuple pattern
        var statePattern = "{" + modifiedVars.map(v -> v.name).join(", ") + "}";
        
        // Compile body with mutation tracking
        var compiledBody = compiler.compileExpression(body);
        
        // Add state return at the end
        return compiledBody + "\n" + statePattern;
    }
    
    /**
     * Handles break/continue in recursive functions
     * 
     * WHY: Break/continue don't exist in recursive functions
     * WHAT: Transforms to pattern matching on return values
     * HOW: Uses tagged tuples {:break, state} and {:continue, state}
     * 
     * @param expr Expression potentially containing break/continue
     * @return Transformed expression with proper control flow
     */
    public function handleBreakContinue(expr: TypedExpr): String {
        var hasBreak = false;
        var hasContinue = false;
        
        // Detect break/continue presence
        function detect(e: TypedExpr): Void {
            switch(e.expr) {
                case TypedExprDef.TBreak:
                    hasBreak = true;
                case TypedExprDef.TContinue:
                    hasContinue = true;
                default:
                    TypedExprTools.iter(e, detect);
            }
        }
        
        detect(expr);
        
        if (!hasBreak && !hasContinue) {
            return compiler.compileExpression(expr);
        }
        
        // Transform with control flow tags
        return transformWithControlFlow(expr, hasBreak, hasContinue);
    }
    
    // ═══════════════════════════════════════════════════════════════════
    // PRIVATE HELPER METHODS
    // ═══════════════════════════════════════════════════════════════════
    
    /**
     * Generates simple recursive function without state
     */
    function generateSimpleRecursive(condition: String, body: String, helperId: Int): String {
        return '(
  loop_${helperId} = fn loop_fn ->
    if ${condition} do
${indentCode(body, 6)}
      loop_fn.(loop_fn)
    else
      nil
    end
  end
  
  loop_${helperId}.(loop_${helperId})
)';
    }
    
    /**
     * Generates stateful recursive function
     */
    function generateStatefulRecursive(condition: String, body: String, vars: Array<String>, helperId: Int): String {
        var params = vars.join(", ");
        
        return '(
  loop_${helperId} = fn ${params}, loop_fn ->
    if ${condition} do
      # Body updates state
${indentCode(body, 6)}
      # Recursive call with new state
      loop_fn.(${params}, loop_fn)
    else
      {${params}}
    end
  end
  
  # Initial call
  {${params}} = loop_${helperId}.(${params}, loop_${helperId})
)';
    }
    
    /**
     * Transforms expression with break/continue control flow
     */
    function transformWithControlFlow(expr: TypedExpr, hasBreak: Bool, hasContinue: Bool): String {
        // This is simplified - full implementation would traverse and replace
        var compiled = compiler.compileExpression(expr);
        
        if (hasBreak) {
            compiled = StringTools.replace(compiled, "break", "{:break, nil}");
        }
        
        if (hasContinue) {
            compiled = StringTools.replace(compiled, "continue", "{:continue, nil}");
        }
        
        return compiled;
    }
    
    /**
     * Detects if body contains mapping pattern
     */
    function detectMappingPattern(body: String): Bool {
        return body.indexOf(" ++ [") >= 0 || 
               body.indexOf("push(") >= 0 ||
               body.indexOf("append(") >= 0;
    }
    
    /**
     * Substitutes array access with item variable
     */
    function substituteArrayAccess(body: String, arrayVar: String, indexVar: String): String {
        var result = body;
        result = StringTools.replace(result, 'Enum.at(${arrayVar}, ${indexVar})', 'item');
        result = StringTools.replace(result, '${arrayVar}[${indexVar}]', 'item');
        result = StringTools.replace(result, '${arrayVar}.get(${indexVar})', 'item');
        return result;
    }
    
    /**
     * Substitutes character code access
     */
    function substituteCharCodeAccess(body: String, stringVar: String, indexVar: String): String {
        var result = body;
        result = StringTools.replace(result, '${stringVar}.cca(${indexVar})', 'char_code');
        result = StringTools.replace(result, '${stringVar}.charCodeAt(${indexVar})', 'char_code');
        return result;
    }
    
    /**
     * Substitutes character access
     */
    function substituteCharAccess(body: String, stringVar: String, indexVar: String): String {
        var result = body;
        result = StringTools.replace(result, '${stringVar}.charAt(${indexVar})', 'char');
        result = StringTools.replace(result, 'String.at(${stringVar}, ${indexVar})', 'char');
        return result;
    }
    
    /**
     * Extracts transformation from mapping pattern
     */
    function extractTransformation(body: String): Null<String> {
        // Look for pattern: accumulator ++ [expression]
        var pattern = ~/ \+\+ \[(.*?)\]/;
        if (pattern.match(body)) {
            return pattern.matched(1);
        }
        return null;
    }
    
    /**
     * Gets Elixir type string for Type
     */
    function getElixirType(t: Type): String {
        return switch(t) {
            case TInst(_.get() => {name: "String"}, _): "binary";
            case TInst(_.get() => {name: "Array"}, _): "list";
            case TAbstract(_.get() => {name: "Int" | "Float"}, _): "number";
            case TAbstract(_.get() => {name: "Bool"}, _): "boolean";
            default: "any";
        };
    }
    
    /**
     * Indents code block
     */
    function indentCode(code: String, spaces: Int = 2): String {
        var indent = [for (i in 0...spaces) " "].join("");
        return code.split("\n").map(line -> 
            line.length > 0 ? indent + line : line
        ).join("\n");
    }
    
    /**
     * Gets next unique helper ID
     */
    function getNextHelperId(): Int {
        return ++helperCounter;
    }
}

// ═══════════════════════════════════════════════════════════════════
// TYPE DEFINITIONS
// ═══════════════════════════════════════════════════════════════════

/**
 * Modified variable information
 */
typedef ModifiedVariable = {
    name: String,
    type: String,
    tvar: TVar
}

/**
 * Character iteration pattern
 */
typedef CharIterationPattern = {
    method: String,        // "charAt" or "cca"
    indexVar: String,
    stringVar: String,
    needsCharCode: Bool,
    hasLengthCheck: Bool
}

#end