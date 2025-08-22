package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Type.TypedExpr;
import haxe.macro.Type.TVar;
import reflaxe.elixir.helpers.NamingHelper;
import reflaxe.elixir.helpers.DebugHelper;

/**
 * MapToolsCompiler: Specialized compilation of MapTools static extension methods to idiomatic Elixir Map operations
 * 
 * WHY: MapTools extension methods involve complex multi-parameter lambda functions with
 * sophisticated variable substitution patterns. Unlike basic Map operations (handled by 
 * MapCompiler), these static extensions require dual/triple parameter handling, parameter
 * ordering differences, and context-sensitive lambda compilation. This was extracted from
 * ElixirCompiler.hx to isolate MapTools-specific logic and improve maintainability.
 * 
 * WHAT: Transforms MapTools static extension methods to functional Elixir patterns:
 * - `map.filter((k, v) -> bool)` → `Map.filter(map, fn {k, v} -> bool end)`
 * - `map.map((k, v) -> newV)` → `Map.new(map, fn {k, v} -> {k, newV} end)`
 * - `map.reduce(init, (acc, k, v) -> acc)` → `Map.fold(map, init, fn k, v, acc -> acc end)`
 * - `map.any((k, v) -> bool)` → `Enum.any?(Map.to_list(map), fn {k, v} -> bool end)`
 * - Multi-parameter variable substitution with proper naming
 * 
 * HOW: 
 * 1. Identify MapTools extension method patterns
 * 2. Disable loop context during argument compilation to prevent interference
 * 3. For multi-parameter lambdas, extract parameter names and TVar references
 * 4. Apply recursive variable substitution for each parameter (key, value, accumulator)
 * 5. Handle parameter ordering differences between Haxe and Elixir conventions
 * 6. Generate idiomatic Elixir Map function calls with proper tuple/destructuring syntax
 * 7. Convert some operations to Enum functions when Map module doesn't provide equivalent
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Focused only on MapTools extension method compilation
 * - Open/Closed Principle: Extensible for new MapTools patterns without touching main compiler
 * - Testability: Can be unit tested independently with mock Map data
 * - Maintainability: Clear separation from basic Map operations and array operations
 * - Performance: Specialized optimizations for Map-specific lambda patterns
 * 
 * EDGE CASES:
 * - Multi-parameter lambdas require sequential variable substitution to avoid conflicts
 * - Parameter ordering differs between Haxe (acc, key, value) and Elixir (key, value, acc) for reduce
 * - Some Map operations must be converted to Enum operations (any, all, find)
 * - Variable names must be converted to snake_case for Elixir convention
 * - Nested variable references in lambda bodies require recursive substitution
 * - Empty lambda parameters need sensible default names (key, value, acc)
 * 
 * @see documentation/MAP_TOOLS_COMPILATION.md - Detailed MapTools extension compilation patterns
 */
@:nullSafety(Off)
class MapToolsCompiler {
    
    private var compiler: reflaxe.elixir.ElixirCompiler;
    
    public function new(compiler: reflaxe.elixir.ElixirCompiler) {
        this.compiler = compiler;
    }
    
    /**
     * Check if a method name is a MapTools static extension method
     * 
     * WHY: Need to distinguish between basic Map operations (handled by MapCompiler)
     * and sophisticated MapTools extension methods that require multi-parameter lambda handling.
     * 
     * WHAT: Returns true for MapTools extension methods that operate on Map objects
     * with lambda functions for filtering, mapping, reducing, and testing operations.
     * 
     * HOW: Uses pattern matching to identify known MapTools extension method names
     * that require special handling for multi-parameter lambda compilation.
     */
    public function isMapMethod(methodName: String): Bool {
        return switch (methodName) {
            case "filter", "map", "mapKeys", "reduce", "any", "all", 
                 "find", "keys", "values", "toArray", "fromArray", 
                 "merge", "isEmpty", "size":
                true;
            case _:
                false;
        };
    }
    
    /**
     * Compile MapTools static extension methods to idiomatic Elixir Map module calls
     * 
     * WHY: MapTools methods use multi-parameter lambdas (key, value) and have different
     * parameter ordering conventions than basic Map operations. They require sophisticated
     * variable substitution to generate proper Elixir lambda syntax.
     * 
     * WHAT: Transforms MapTools extension calls to functional Elixir equivalents:
     * - Handle multi-parameter lambda variable substitution
     * - Convert parameter ordering for reduce operations  
     * - Generate proper Elixir tuple destructuring syntax for key-value pairs
     * - Use Map module functions when available, Enum functions when necessary
     * 
     * HOW:
     * 1. Save and disable loop context to prevent compilation interference
     * 2. For lambda arguments, extract TVar references for each parameter
     * 3. Apply sequential variable substitution for key, value, and accumulator parameters
     * 4. Handle parameter ordering differences (especially for reduce)
     * 5. Generate idiomatic Elixir function calls with proper lambda syntax
     * 6. Use Map.to_list conversion when Enum functions are required
     * 
     * @param objStr The compiled map object expression
     * @param methodName The MapTools method being called (e.g., "filter", "map")
     * @param args The method arguments as TypedExpr array
     * @return The compiled Elixir method call
     */
    public function compileMapMethod(objStr: String, methodName: String, args: Array<TypedExpr>): String {
        #if debug_map_tools
        DebugHelper.debugMapTools("compileMapMethod", "Starting compilation", 'Method: ${methodName}, Args: ${args.length}');
        #end
        
        // Save current loop context and disable it for argument compilation
        var previousContext = compiler.isInLoopContext;
        compiler.isInLoopContext = false;
        var compiledArgs = args.map(arg -> compiler.compileExpression(arg));
        compiler.isInLoopContext = previousContext;
        
        return switch (methodName) {
            case "filter":
                // map.filter((k, v) -> bool) → Map.filter(map, fn {k, v} -> bool end)
                if (compiledArgs.length > 0) {
                    // Check if the argument is a lambda that needs variable substitution
                    if (args.length > 0) {
                        switch (args[0].expr) {
                            case TFunction(func):
                                // Handle lambda with two parameters: key and value
                                var keyParamName = func.args.length > 0 ? NamingHelper.toSnakeCase(compiler.getOriginalVarName(func.args[0].v)) : "key";
                                var valueParamName = func.args.length > 1 ? NamingHelper.toSnakeCase(compiler.getOriginalVarName(func.args[1].v)) : "value";
                                var keyParamTVar = func.args.length > 0 ? func.args[0].v : null;
                                var valueParamTVar = func.args.length > 1 ? func.args[1].v : null;
                                
                                // Apply dual variable substitution like in reduce
                                var tempBody = func.expr;
                                if (keyParamTVar != null) {
                                    tempBody = substituteVariableInExpression(tempBody, keyParamTVar, keyParamName);
                                }
                                if (valueParamTVar != null) {
                                    tempBody = substituteVariableInExpression(tempBody, valueParamTVar, valueParamName);
                                }
                                var body = compiler.compileExpression(tempBody);
                                return 'Map.filter(${objStr}, fn {${keyParamName}, ${valueParamName}} -> ${body} end)';
                            case _:
                                return 'Map.filter(${objStr}, ${compiledArgs[0]})';
                        }
                    } else {
                        return 'Map.filter(${objStr}, ${compiledArgs[0]})';
                    }
                } else {
                    objStr;
                }
            case "map":
                // map.map((k, v) -> newV) → Map.new(map, fn {k, v} -> {k, newV} end) 
                if (compiledArgs.length > 0) {
                    if (args.length > 0) {
                        switch (args[0].expr) {
                            case TFunction(func):
                                var keyParamName = func.args.length > 0 ? NamingHelper.toSnakeCase(compiler.getOriginalVarName(func.args[0].v)) : "key";
                                var valueParamName = func.args.length > 1 ? NamingHelper.toSnakeCase(compiler.getOriginalVarName(func.args[1].v)) : "value";
                                var keyParamTVar = func.args.length > 0 ? func.args[0].v : null;
                                var valueParamTVar = func.args.length > 1 ? func.args[1].v : null;
                                
                                var tempBody = func.expr;
                                if (keyParamTVar != null) {
                                    tempBody = substituteVariableInExpression(tempBody, keyParamTVar, keyParamName);
                                }
                                if (valueParamTVar != null) {
                                    tempBody = substituteVariableInExpression(tempBody, valueParamTVar, valueParamName);
                                }
                                var body = compiler.compileExpression(tempBody);
                                return 'Map.new(${objStr}, fn {${keyParamName}, ${valueParamName}} -> {${keyParamName}, ${body}} end)';
                            case _:
                                return 'Map.new(${objStr}, ${compiledArgs[0]})';
                        }
                    } else {
                        return 'Map.new(${objStr}, ${compiledArgs[0]})';
                    }
                } else {
                    objStr;
                }
            case "mapKeys":
                // map.mapKeys((k, v) -> newK) → Map.new(map, fn {k, v} -> {newK, v} end)
                if (compiledArgs.length > 0) {
                    if (args.length > 0) {
                        switch (args[0].expr) {
                            case TFunction(func):
                                var keyParamName = func.args.length > 0 ? NamingHelper.toSnakeCase(compiler.getOriginalVarName(func.args[0].v)) : "key";
                                var valueParamName = func.args.length > 1 ? NamingHelper.toSnakeCase(compiler.getOriginalVarName(func.args[1].v)) : "value";
                                var keyParamTVar = func.args.length > 0 ? func.args[0].v : null;
                                var valueParamTVar = func.args.length > 1 ? func.args[1].v : null;
                                
                                var tempBody = func.expr;
                                if (keyParamTVar != null) {
                                    tempBody = substituteVariableInExpression(tempBody, keyParamTVar, keyParamName);
                                }
                                if (valueParamTVar != null) {
                                    tempBody = substituteVariableInExpression(tempBody, valueParamTVar, valueParamName);
                                }
                                var body = compiler.compileExpression(tempBody);
                                return 'Map.new(${objStr}, fn {${keyParamName}, ${valueParamName}} -> {${body}, ${valueParamName}} end)';
                            case _:
                                return 'Map.new(${objStr}, ${compiledArgs[0]})';
                        }
                    } else {
                        return 'Map.new(${objStr}, ${compiledArgs[0]})';
                    }
                } else {
                    objStr;
                }
            case "reduce":
                // map.reduce(initial, (acc, k, v) -> newAcc) → Map.fold(map, initial, fn k, v, acc -> newAcc end)
                if (compiledArgs.length >= 2) {
                    if (args.length >= 2) {
                        switch (args[1].expr) {
                            case TFunction(func):
                                // Parameters: acc, key, value in Haxe → key, value, acc in Elixir
                                var accParamName = func.args.length > 0 ? NamingHelper.toSnakeCase(compiler.getOriginalVarName(func.args[0].v)) : "acc";
                                var keyParamName = func.args.length > 1 ? NamingHelper.toSnakeCase(compiler.getOriginalVarName(func.args[1].v)) : "key";
                                var valueParamName = func.args.length > 2 ? NamingHelper.toSnakeCase(compiler.getOriginalVarName(func.args[2].v)) : "value";
                                
                                var accParamTVar = func.args.length > 0 ? func.args[0].v : null;
                                var keyParamTVar = func.args.length > 1 ? func.args[1].v : null;
                                var valueParamTVar = func.args.length > 2 ? func.args[2].v : null;
                                
                                var tempBody = func.expr;
                                if (accParamTVar != null) {
                                    tempBody = substituteVariableInExpression(tempBody, accParamTVar, accParamName);
                                }
                                if (keyParamTVar != null) {
                                    tempBody = substituteVariableInExpression(tempBody, keyParamTVar, keyParamName);
                                }
                                if (valueParamTVar != null) {
                                    tempBody = substituteVariableInExpression(tempBody, valueParamTVar, valueParamName);
                                }
                                var body = compiler.compileExpression(tempBody);
                                
                                return 'Map.fold(${objStr}, ${compiledArgs[0]}, fn ${keyParamName}, ${valueParamName}, ${accParamName} -> ${body} end)';
                            case _:
                                return 'Map.fold(${objStr}, ${compiledArgs[0]}, ${compiledArgs[1]})';
                        }
                    } else {
                        return 'Map.fold(${objStr}, ${compiledArgs[0]}, ${compiledArgs[1]})';
                    }
                } else {
                    objStr;
                }
            case "any":
                // map.any((k, v) -> bool) → Enum.any?(Map.to_list(map), fn {k, v} -> bool end)
                if (compiledArgs.length > 0) {
                    if (args.length > 0) {
                        switch (args[0].expr) {
                            case TFunction(func):
                                var keyParamName = func.args.length > 0 ? NamingHelper.toSnakeCase(compiler.getOriginalVarName(func.args[0].v)) : "key";
                                var valueParamName = func.args.length > 1 ? NamingHelper.toSnakeCase(compiler.getOriginalVarName(func.args[1].v)) : "value";
                                var keyParamTVar = func.args.length > 0 ? func.args[0].v : null;
                                var valueParamTVar = func.args.length > 1 ? func.args[1].v : null;
                                
                                var tempBody = func.expr;
                                if (keyParamTVar != null) {
                                    tempBody = substituteVariableInExpression(tempBody, keyParamTVar, keyParamName);
                                }
                                if (valueParamTVar != null) {
                                    tempBody = substituteVariableInExpression(tempBody, valueParamTVar, valueParamName);
                                }
                                var body = compiler.compileExpression(tempBody);
                                return 'Enum.any?(Map.to_list(${objStr}), fn {${keyParamName}, ${valueParamName}} -> ${body} end)';
                            case _:
                                return 'Enum.any?(Map.to_list(${objStr}), ${compiledArgs[0]})';
                        }
                    } else {
                        return 'Enum.any?(Map.to_list(${objStr}), ${compiledArgs[0]})';
                    }
                } else {
                    'false';
                }
            case "all":
                // map.all((k, v) -> bool) → Enum.all?(Map.to_list(map), fn {k, v} -> bool end)
                if (compiledArgs.length > 0) {
                    if (args.length > 0) {
                        switch (args[0].expr) {
                            case TFunction(func):
                                var keyParamName = func.args.length > 0 ? NamingHelper.toSnakeCase(compiler.getOriginalVarName(func.args[0].v)) : "key";
                                var valueParamName = func.args.length > 1 ? NamingHelper.toSnakeCase(compiler.getOriginalVarName(func.args[1].v)) : "value";
                                var keyParamTVar = func.args.length > 0 ? func.args[0].v : null;
                                var valueParamTVar = func.args.length > 1 ? func.args[1].v : null;
                                
                                var tempBody = func.expr;
                                if (keyParamTVar != null) {
                                    tempBody = substituteVariableInExpression(tempBody, keyParamTVar, keyParamName);
                                }
                                if (valueParamTVar != null) {
                                    tempBody = substituteVariableInExpression(tempBody, valueParamTVar, valueParamName);
                                }
                                var body = compiler.compileExpression(tempBody);
                                return 'Enum.all?(Map.to_list(${objStr}), fn {${keyParamName}, ${valueParamName}} -> ${body} end)';
                            case _:
                                return 'Enum.all?(Map.to_list(${objStr}), ${compiledArgs[0]})';
                        }
                    } else {
                        return 'Enum.all?(Map.to_list(${objStr}), ${compiledArgs[0]})';
                    }
                } else {
                    'true';
                }
            case "find":
                // map.find((k, v) -> bool) → Enum.find(Map.to_list(map), fn {k, v} -> bool end)
                if (compiledArgs.length > 0) {
                    if (args.length > 0) {
                        switch (args[0].expr) {
                            case TFunction(func):
                                var keyParamName = func.args.length > 0 ? NamingHelper.toSnakeCase(compiler.getOriginalVarName(func.args[0].v)) : "key";
                                var valueParamName = func.args.length > 1 ? NamingHelper.toSnakeCase(compiler.getOriginalVarName(func.args[1].v)) : "value";
                                var keyParamTVar = func.args.length > 0 ? func.args[0].v : null;
                                var valueParamTVar = func.args.length > 1 ? func.args[1].v : null;
                                
                                var tempBody = func.expr;
                                if (keyParamTVar != null) {
                                    tempBody = substituteVariableInExpression(tempBody, keyParamTVar, keyParamName);
                                }
                                if (valueParamTVar != null) {
                                    tempBody = substituteVariableInExpression(tempBody, valueParamTVar, valueParamName);
                                }
                                var body = compiler.compileExpression(tempBody);
                                return 'Enum.find(Map.to_list(${objStr}), fn {${keyParamName}, ${valueParamName}} -> ${body} end)';
                            case _:
                                return 'Enum.find(Map.to_list(${objStr}), ${compiledArgs[0]})';
                        }
                    } else {
                        return 'Enum.find(Map.to_list(${objStr}), ${compiledArgs[0]})';
                    }
                } else {
                    'nil';
                }
            case "keys":
                // map.keys() → Map.keys(map)
                'Map.keys(${objStr})';
            case "values":
                // map.values() → Map.values(map)
                'Map.values(${objStr})';
            case "toArray":
                // map.toArray() → Map.to_list(map)
                'Map.to_list(${objStr})';
            case "fromArray":
                // MapTools.fromArray(pairs) → Map.new(pairs)
                if (compiledArgs.length > 0) {
                    'Map.new(${compiledArgs[0]})';
                } else {
                    'Map.new()';
                }
            case "merge":
                // map.merge(otherMap) → Map.merge(map, otherMap)
                if (compiledArgs.length > 0) {
                    'Map.merge(${objStr}, ${compiledArgs[0]})';
                } else {
                    objStr;
                }
            case "isEmpty":
                // map.isEmpty() → Map.equal?(map, %{})
                'Map.equal?(${objStr}, %{})';
            case "size":
                // map.size() → Map.size(map)
                'Map.size(${objStr})';
            case _:
                // Default: try to call as a regular method
                '${objStr}.${methodName}(${compiledArgs.join(", ")})';
        };
    }
    
    /**
     * Substitute a variable in an expression for MapTools dual/triple parameter support
     * 
     * WHY: MapTools methods use multi-parameter lambdas like (key, value) or (acc, key, value)
     * that require recursive variable substitution throughout the lambda body to ensure
     * proper parameter naming in generated Elixir code.
     * 
     * WHAT: Recursively traverses TypedExpr AST and replaces all references to a specific
     * TVar with a target variable name, handling nested expressions like binary operations,
     * field accesses, and function calls.
     * 
     * HOW: Uses pattern matching on TypedExpr structure to recursively apply substitution
     * to all sub-expressions while preserving AST structure and type information.
     */
    private function substituteVariableInExpression(expr: TypedExpr, sourceTVar: TVar, targetVarName: String): TypedExpr {
        return switch (expr.expr) {
            case TLocal(v):
                if (v == sourceTVar) {
                    // Create new expression with substituted variable reference
                    var compiledExpr = compiler.compileExpression(expr);
                    var substitutedExpr: Null<String> = null;
                    if (compiledExpr != null && v.name != null && targetVarName != null) {
                        var safeCompiledExpr: String = compiledExpr;
                        var safeVarName: String = v.name;
                        var safeTargetName: String = targetVarName;
                        substitutedExpr = StringTools.replace(safeCompiledExpr, safeVarName, safeTargetName);
                    }
                    // Return expression that compiles to the substituted string
                    {expr: TConst(TString(substitutedExpr)), t: expr.t, pos: expr.pos};
                } else {
                    expr;
                }
            case TBinop(op, e1, e2):
                var newE1 = substituteVariableInExpression(e1, sourceTVar, targetVarName);
                var newE2 = substituteVariableInExpression(e2, sourceTVar, targetVarName);
                {expr: TBinop(op, newE1, newE2), t: expr.t, pos: expr.pos};
            case TField(e, fa):
                var newE = substituteVariableInExpression(e, sourceTVar, targetVarName);
                {expr: TField(newE, fa), t: expr.t, pos: expr.pos};
            case TCall(e, args):
                var newE = substituteVariableInExpression(e, sourceTVar, targetVarName);
                var newArgs = args.map(arg -> substituteVariableInExpression(arg, sourceTVar, targetVarName));
                {expr: TCall(newE, newArgs), t: expr.t, pos: expr.pos};
            case _:
                // For other cases, no substitution needed
                expr;
        };
    }
}

#end