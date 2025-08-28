#if (macro || elixir_runtime)

package reflaxe.elixir.helpers;

import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.TypedExprTools;
import reflaxe.elixir.ElixirCompiler;

/**
 * UnifiedLoopCompiler: Minimal, focused loop compilation
 * 
 * WHY: Previous architecture had 10,000+ lines across 10+ files with massive duplication.
 *      This created maintenance nightmares, bugs like g_array mismatches, and confusion.
 * 
 * WHAT: Single source of truth for ALL loop compilation. Handles for/while/do-while
 *       with clear, simple transformations. No duplication, no complex pattern detection.
 * 
 * HOW: Direct AST-to-Elixir transformation. Special handling for TLocal to avoid
 *      variable mapping issues. Everything else delegates to compiler.compileExpression.
 * 
 * ARCHITECTURE BENEFITS:
 * - Under 500 lines (vs 10,000+ before)
 * - Single responsibility: compile loops
 * - No duplicate Enum generation
 * - Clear TLocal handling prevents g_array bugs
 * - Testable and maintainable
 */
@:nullSafety(Off)
class UnifiedLoopCompiler {
    
    /** Reference to main compiler for expression compilation */
    var compiler: ElixirCompiler;
    
    /**
     * Constructor
     * @param compiler Main ElixirCompiler instance
     */
    public function new(compiler: ElixirCompiler) {
        this.compiler = compiler;
    }
    
    /**
     * Main entry point for loop compilation
     * @param expr The loop expression (TFor or TWhile)
     * @return Generated Elixir code
     */
    public function compileLoop(expr: TypedExpr): String {
        return switch(expr.expr) {
            case TypedExprDef.TWhile(econd, ebody, normalWhile):
                compileWhileLoop(econd, ebody, normalWhile);
                
            case TypedExprDef.TFor(tvar, iterExpr, blockExpr):
                compileForLoop(tvar, iterExpr, blockExpr);
                
            default:
                "";
        }
    }
    
    /**
     * Compile for-in loops to Enum.each
     * 
     * CRITICAL: Special handling for TLocal to prevent g_array issues
     * 
     * @param tvar Loop variable
     * @param iterExpr Expression being iterated
     * @param blockExpr Loop body
     * @return Elixir Enum.each code
     */
    public function compileForLoop(tvar: TVar, iterExpr: TypedExpr, blockExpr: TypedExpr): String {
        // Convert loop variable to Elixir naming
        var loopVar = NamingHelper.toSnakeCase(tvar.name);
        
        // CRITICAL: Handle TLocal specially to avoid g_array mapping issues
        var iterable = compileIterableExpr(iterExpr);
        
        // Compile loop body
        var body = compiler.compileExpression(blockExpr);
        
        // Generate simple Enum.each
        return 'Enum.each(${iterable}, fn ${loopVar} ->
${CompilerUtilities.indentCode(body, 2)}
end)';
    }
    
    /**
     * Compile while loops using recursive functions
     * 
     * @param econd Loop condition
     * @param ebody Loop body
     * @param normalWhile True for while, false for do-while
     * @return Elixir recursive function
     */
    public function compileWhileLoop(econd: TypedExpr, ebody: TypedExpr, normalWhile: Bool): String {
        // Check for array filter pattern: for (x in arr) if (cond) result.push(x)
        var filterPattern = detectArrayFilterPattern(econd, ebody);
        if (filterPattern != null) {
            return compileFilterPattern(filterPattern);
        }
        
        // Check for array map pattern: for (x in arr) result.push(transform(x))
        var mapPattern = detectArrayMapPattern(econd, ebody);
        if (mapPattern != null) {
            return compileMapPattern(mapPattern);
        }
        
        // Check for simple for-in pattern that Haxe desugared to while
        var forInPattern = detectForInPattern(econd, ebody);
        if (forInPattern != null) {
            return compileForInPattern(forInPattern);
        }
        
        // Generate simple recursive function for while loops
        var condition = compiler.compileExpression(econd);
        var body = compiler.compileExpression(ebody);
        
        if (normalWhile) {
            // while (condition) { body }
            return '(fn loop ->
  if ${condition} do
    ${CompilerUtilities.indentCode(body, 4)}
    loop.()
  end
end).()';
        } else {
            // do { body } while (condition)
            return '(fn loop ->
  ${CompilerUtilities.indentCode(body, 2)}
  if ${condition} do
    loop.()
  end
end).()';
        }
    }
    
    /**
     * Special handling for iterable expressions to avoid variable mapping issues
     * 
     * WHY: TLocal variables were being incorrectly mapped through desugaring system
     * WHAT: Direct conversion to snake_case for simple variables
     * HOW: Check if TLocal, convert directly, otherwise use normal compilation
     * 
     * @param expr The iterable expression
     * @return Compiled expression string
     */
    private function compileIterableExpr(expr: TypedExpr): String {
        return switch(expr.expr) {
            case TLocal(v):
                // Direct conversion for local variables - no mapping!
                var name = v.name;
                if (name.charAt(0) == "_") {
                    name = name.substr(1);
                }
                NamingHelper.toSnakeCase(name);
            case _:
                // For everything else, use normal compilation
                compiler.compileExpression(expr);
        };
    }
    
    /**
     * Detect for-in patterns that Haxe desugared to while loops
     * 
     * Haxe transforms: for (item in array) { ... }
     * Into: var i = 0; while (i < array.length) { var item = array[i]; ... i++; }
     * 
     * @param econd While condition
     * @param ebody While body
     * @return Pattern info if detected, null otherwise
     */
    private function detectForInPattern(econd: TypedExpr, ebody: TypedExpr): Null<ForInPattern> {
        // Look for pattern: i < array.length
        switch(econd.expr) {
            case TBinop(OpLt, e1, e2):
                switch(e2.expr) {
                    case TField(arrayExpr, FInstance(_, _, cf)) if (cf.get().name == "length"):
                        // Found array.length comparison
                        // Check body for array access pattern
                        if (hasArrayAccess(ebody, arrayExpr)) {
                            return {
                                array: arrayExpr,
                                body: ebody
                            };
                        }
                    case _:
                }
            case _:
        }
        return null;
    }
    
    /**
     * Check if expression contains array access
     */
    private function hasArrayAccess(expr: TypedExpr, arrayExpr: TypedExpr): Bool {
        var found = false;
        
        function check(e: TypedExpr): Void {
            if (found) return;
            
            switch(e.expr) {
                case TArray(arr, _):
                    // Check if this is accessing our array
                    if (exprEquals(arr, arrayExpr)) {
                        found = true;
                    }
                case _:
                    TypedExprTools.iter(e, check);
            }
        }
        
        check(expr);
        return found;
    }
    
    /**
     * Simple expression equality check
     */
    private function exprEquals(e1: TypedExpr, e2: TypedExpr): Bool {
        return switch([e1.expr, e2.expr]) {
            case [TLocal(v1), TLocal(v2)]: v1.id == v2.id;
            case _: false;
        }
    }
    
    /**
     * Compile detected for-in pattern to Enum.each
     */
    private function compileForInPattern(pattern: ForInPattern): String {
        // Extract the array expression
        var arrayExpr = compileIterableExpr(pattern.array);
        
        // For now, generate simple Enum.each
        // TODO: Extract item variable name from body pattern
        var body = compiler.compileExpression(pattern.body);
        
        return '${arrayExpr}
|> Enum.with_index()
|> Enum.each(fn {item, _index} ->
${CompilerUtilities.indentCode(body, 2)}
end)';
    }
    
    /**
     * Check if expression contains TFor loops (utility for ElixirCompiler)
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
            case TIf(_, eif, eelse):
                if (checkForTForInExpression(eif)) return true;
                if (eelse != null && checkForTForInExpression(eelse)) return true;
            case _:
        }
        return false;
    }
    
    /**
     * Check if expression contains TWhile loops (utility for ElixirCompiler)
     */
    public function containsTWhileExpression(expr: TypedExpr): Bool {
        if (expr == null) return false;
        
        switch (expr.expr) {
            case TWhile(_, _, _):
                return true;
            case TBlock(exprs):
                for (e in exprs) {
                    if (containsTWhileExpression(e)) return true;
                }
            case TIf(_, eif, eelse):
                if (containsTWhileExpression(eif)) return true;
                if (eelse != null && containsTWhileExpression(eelse)) return true;
            case TFor(_, _, ebody):
                return containsTWhileExpression(ebody);
            case _:
        }
        return false;
    }
    
    /**
     * Detect array filter pattern in desugared while loop
     * 
     * Pattern: for (x in arr) if (cond) result.push(x)
     * Desugared: while (i < arr.length) { var x = arr[i]; if (cond) result.push(x); i++; }
     */
    private function detectArrayFilterPattern(econd: TypedExpr, ebody: TypedExpr): Null<FilterPattern> {
        // TDD: Just return null for now - implement when test actually needs it
        return null;
    }
    
    /**
     * Detect array map pattern in desugared while loop
     * 
     * Pattern: for (x in arr) result.push(transform(x))
     * Desugared: while (i < arr.length) { var x = arr[i]; result.push(transform(x)); i++; }
     */
    private function detectArrayMapPattern(econd: TypedExpr, ebody: TypedExpr): Null<MapPattern> {
        // TDD: Just return null for now - implement when test actually needs it
        return null;
    }
    
    /**
     * Compile filter pattern to Enum.filter
     */
    private function compileFilterPattern(pattern: FilterPattern): String {
        var arrayExpr = compileIterableExpr(pattern.array);
        var condition = compiler.compileExpression(pattern.condition);
        
        return '${pattern.resultVar} = Enum.filter(${arrayExpr}, fn ${pattern.itemVar} ->
  ${condition}
end)';
    }
    
    /**
     * Compile map pattern to Enum.map
     */
    private function compileMapPattern(pattern: MapPattern): String {
        var arrayExpr = compileIterableExpr(pattern.array);
        var transform = compiler.compileExpression(pattern.transform);
        
        return '${pattern.resultVar} = Enum.map(${arrayExpr}, fn ${pattern.itemVar} ->
  ${transform}
end)';
    }
}

/**
 * Pattern info for detected for-in loops
 */
private typedef ForInPattern = {
    array: TypedExpr,
    body: TypedExpr
}

/**
 * Pattern info for detected filter operations
 */
private typedef FilterPattern = {
    array: TypedExpr,
    itemVar: String,
    condition: TypedExpr,
    resultVar: String
}

/**
 * Pattern info for detected map operations  
 */
private typedef MapPattern = {
    array: TypedExpr,
    itemVar: String,
    transform: TypedExpr,
    resultVar: String
}

#end