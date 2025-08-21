package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.Type.TFunc;
import reflaxe.elixir.helpers.NamingHelper;

using reflaxe.helpers.NameMetaHelper;

/**
 * Context-Sensitive Expression Compiler for Reflaxe.Elixir
 * 
 * CORE PRINCIPLE: Context-Sensitive Expression Compilation
 * ========================================================
 * 
 * When compiling expressions that change the compilation context (lambdas, loops, closures),
 * we need proper context management that:
 * 
 * 1. **Preserves outer scope context** - Don't lose current compilation state
 * 2. **Establishes inner scope context** - Set up the new compilation environment  
 * 3. **Restores context after compilation** - Return to previous state cleanly
 * 4. **Is reusable across expression types** - Don't duplicate context logic
 * 
 * This prevents issues like:
 * - Variable substitution failing in lambda bodies
 * - Incorrect scope resolution in nested expressions
 * - Context bleeding between different compilation phases
 * 
 * USAGE PATTERN:
 * ```haxe
 * var result = ExpressionCompiler.withContext(compiler, context, () -> {
 *     return compileInnerExpression();
 * });
 * ```
 * 
 * ARCHITECTURAL BENEFITS:
 * - Single point of context management 
 * - Consistent behavior across all expression types
 * - Easy to test and maintain
 * - Clear separation of concerns
 * - Prevents context-related bugs
 * 
 * This pattern should be used for ANY expression compilation that changes context:
 * - Lambda expressions in array methods (filter, map, etc.)
 * - Loop body compilation (for, while)
 * - Closure compilation
 * - Pattern matching compilation
 * - Any future context-sensitive expressions
 */
/**
 * Compilation context state for managing variable substitution and scope
 */
typedef CompilationContext = {
    var isInLoopContext: Bool;
    var currentParameterMap: Map<String, String>;
}

/**
 * Lambda compilation result containing parameter names and compiled body
 */
typedef LambdaResult = {
    paramName: String,
    body: String
}

/**
 * Two-parameter lambda compilation result (for reduce, Map operations, etc.)
 */
typedef TwoParamLambdaResult = {
    param1: String,
    param2: String, 
    body: String
}

@:nullSafety(Off)
class ExpressionCompiler {
    
    /**
     * Helper function to create compilation context
     */
    private static function createCompilationContext(isInLoopContext: Bool = false, parameterMap: Map<String, String> = null): CompilationContext {
        return {
            isInLoopContext: isInLoopContext,
            currentParameterMap: parameterMap != null ? parameterMap : new Map<String, String>()
        };
    }
    
    /**
     * Compile a single-parameter lambda function with proper context management.
     * 
     * This is the primary method for compiling lambda expressions in array methods
     * like filter, map, find, etc. It ensures proper variable substitution by
     * managing the loop context during compilation.
     * 
     * @param compiler The main ElixirCompiler instance
     * @param func The TFunc representing the lambda function
     * @param defaultParamName Default parameter name if no arguments exist
     * @return LambdaResult with parameter name and compiled body
     */
    public static function compileLambdaWithContext(
        compiler: Dynamic, // ElixirCompiler - using Dynamic to avoid circular imports
        func: TFunc, 
        defaultParamName: String = "item"
    ): LambdaResult {
        
        // Extract parameter information
        var paramName = func.args.length > 0 ? 
            NamingHelper.toSnakeCase(getOriginalVarName(compiler, func.args[0].v)) : 
            defaultParamName;
        var paramTVar = func.args.length > 0 ? func.args[0].v : null;
        
        // Create context for lambda compilation
        var context = createCompilationContext(true); // Enable loop context for variable substitution
        
        // Compile with managed context
        var body = withContext(compiler, context, () -> {
            if (paramTVar != null) {
                // Debug output to understand substitution
                trace('ExpressionCompiler: Substituting ${paramTVar.name} (id: ${paramTVar.id}) with ${paramName}');
                var result = compiler.compileExpressionWithTVarSubstitution(func.expr, paramTVar, paramName);
                trace('ExpressionCompiler: Substitution result: ${result}');
                return result;
            } else {
                return compiler.compileExpression(func.expr);
            }
        });
        
        return {
            paramName: paramName,
            body: body
        };
    }
    
    /**
     * Compile a two-parameter lambda function (for reduce, Map operations, etc.)
     * 
     * @param compiler The main ElixirCompiler instance  
     * @param func The TFunc representing the lambda function
     * @param param1Default Default name for first parameter
     * @param param2Default Default name for second parameter
     * @return TwoParamLambdaResult with both parameter names and compiled body
     */
    public static function compileTwoParamLambdaWithContext(
        compiler: Dynamic,
        func: TFunc,
        param1Default: String = "acc",
        param2Default: String = "item"
    ): TwoParamLambdaResult {
        
        // Extract parameter information
        var param1 = func.args.length > 0 ? 
            NamingHelper.toSnakeCase(getOriginalVarName(compiler, func.args[0].v)) : 
            param1Default;
        var param2 = func.args.length > 1 ? 
            NamingHelper.toSnakeCase(getOriginalVarName(compiler, func.args[1].v)) : 
            param2Default;
            
        var param1TVar = func.args.length > 0 ? func.args[0].v : null;
        var param2TVar = func.args.length > 1 ? func.args[1].v : null;
        
        // Create context for lambda compilation
        var context = createCompilationContext(true);
        
        // Compile with managed context and sequential variable substitution
        var body = withContext(compiler, context, () -> {
            var tempExpr = func.expr;
            
            // Apply substitutions in sequence
            if (param1TVar != null) {
                tempExpr = compiler.compileExpressionWithTVarSubstitution(tempExpr, param1TVar, param1);
            }
            if (param2TVar != null) {
                tempExpr = compiler.compileExpressionWithTVarSubstitution(tempExpr, param2TVar, param2);
            }
            
            return compiler.compileExpression(tempExpr);
        });
        
        return {
            param1: param1,
            param2: param2,
            body: body
        };
    }
    
    /**
     * Execute a compilation function with managed context state.
     * 
     * This is the core context management function that ensures proper
     * preservation and restoration of compilation context.
     * 
     * @param compiler The main ElixirCompiler instance
     * @param context The compilation context to establish
     * @param compilationFn The function to execute with the given context
     * @return The result of the compilation function
     */
    public static function withContext<T>(
        compiler: Dynamic,
        context: CompilationContext,
        compilationFn: () -> T
    ): T {
        
        // Save current context state
        var previousLoopContext = compiler.isInLoopContext;
        var previousParameterMap = compiler.currentFunctionParameterMap;
        
        // Establish new context
        compiler.isInLoopContext = context.isInLoopContext;
        
        // Add parameter mappings if provided
        for (key in context.currentParameterMap.keys()) {
            compiler.currentFunctionParameterMap.set(key, context.currentParameterMap.get(key));
        }
        
        try {
            // Execute compilation with new context
            var result = compilationFn();
            
            // Restore previous context
            compiler.isInLoopContext = previousLoopContext;
            compiler.currentFunctionParameterMap = previousParameterMap;
            
            return result;
            
        } catch (e: Dynamic) {
            // Ensure context is restored even if compilation fails
            compiler.isInLoopContext = previousLoopContext;
            compiler.currentFunctionParameterMap = previousParameterMap;
            throw e;
        }
    }
    
    /**
     * Create a loop context for variable substitution in iterative operations
     */
    public static function createLoopContext(): CompilationContext {
        return createCompilationContext(true);
    }
    
    /**
     * Create a function context for parameter mapping
     */
    public static function createFunctionContext(parameterMap: Map<String, String>): CompilationContext {
        return createCompilationContext(false, parameterMap);
    }
    
    /**
     * Helper function to get original variable name (delegates to compiler)
     */
    private static function getOriginalVarName(compiler: Dynamic, v: TVar): String {
        return compiler.getOriginalVarName(v);
    }
}

#end