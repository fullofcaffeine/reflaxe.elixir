package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Type.TypedExpr;
import reflaxe.elixir.helpers.NamingHelper;
import reflaxe.elixir.helpers.DebugHelper;
import reflaxe.elixir.helpers.ExpressionCompiler;

/**
 * ArrayMethodCompiler: Specialized compilation of Haxe array methods to idiomatic Elixir Enum functions
 * 
 * WHY: Array method compilation involves complex lambda variable substitution, parameter 
 * ordering differences between Haxe and Elixir, and sophisticated context-sensitive 
 * compilation. This was extracted from ElixirCompiler.hx to follow single responsibility 
 * principle and enable focused testing of array operation transformations.
 * 
 * WHAT: Transforms OOP-style Haxe array method calls to functional Elixir patterns:
 * - `array.map(fn)` → `Enum.map(array, fn)` with lambda variable substitution
 * - `array.filter(predicate)` → `Enum.filter(array, predicate)` 
 * - `array.reduce(acc, fn)` → `Enum.reduce(array, initial, fn)` with parameter reordering
 * - `array.push(item)` → `array ++ [item]` (immutable concatenation)
 * - Array extensions: `exists`, `fold`, `take`, `drop`, `flatMap`
 * 
 * HOW: 
 * 1. Identify array method pattern from method name
 * 2. Disable loop context during argument compilation to prevent interference
 * 3. For lambda arguments, apply variable substitution to ensure proper parameter names
 * 4. Handle parameter ordering differences (Haxe vs Elixir conventions)
 * 5. Generate idiomatic Elixir Enum function calls with proper lambda syntax
 * 6. Apply special handling for reduce functions (parameter reordering)
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Focused only on array method compilation logic
 * - Open/Closed Principle: Extensible for new array patterns without touching main compiler
 * - Testability: Can be unit tested independently from main compiler
 * - Maintainability: Clear separation from other expression compilation concerns
 * - Performance: Specialized optimizations for array-specific patterns
 * 
 * EDGE CASES:
 * - Lambda expressions require variable substitution for proper parameter naming
 * - Reduce function parameter ordering differs between Haxe (acc, item) and Elixir (item, acc)
 * - Loop context must be disabled during argument compilation to prevent interference
 * - Some methods (pop, shift) don't mutate in Elixir (immutable lists)
 * - Complex lambda bodies may contain nested variable references requiring recursive substitution
 * 
 * @see documentation/ARRAY_METHOD_COMPILATION.md - Detailed array method compilation patterns
 */
@:nullSafety(Off)
class ArrayMethodCompiler {
    
    private var compiler: reflaxe.elixir.ElixirCompiler;
    
    public function new(compiler: reflaxe.elixir.ElixirCompiler) {
        this.compiler = compiler;
    }
    
    /**
     * Check if a method name is a common array method
     * 
     * WHY: Need to identify which method calls should be transformed from OOP-style
     * Haxe array methods to functional Elixir Enum operations.
     * 
     * WHAT: Returns true for standard array methods and ArrayTools extension methods
     * including map, filter, reduce operations and array manipulation methods.
     * 
     * HOW: Uses pattern matching to check against known array method names including
     * both standard array methods and static extension methods from ArrayTools.
     */
    public function isArrayMethod(methodName: String): Bool {
        return switch (methodName) {
            case "join", "push", "pop", "length", "map", "filter", 
                 "concat", "contains", "indexOf", "reduce", "forEach",
                 "find", "findIndex", "slice", "splice", "reverse",
                 "sort", "shift", "unshift", "every", "some",
                 // ArrayTools extension methods
                 "fold", "exists", "any", "foreach", "all", 
                 "take", "drop", "flatMap":
                true;
            case _:
                false;
        };
    }
    
    /**
     * Compile Haxe array method calls to idiomatic Elixir Enum functions.
     * 
     * WHY: Haxe uses OOP-style array.method(args) while Elixir uses functional 
     * Enum.method(array, args). Lambda expressions require variable substitution
     * to ensure proper parameter naming in generated Elixir functions.
     * 
     * WHAT: Transforms common array operations to their Elixir equivalents:
     * - `array.map(fn)` → `Enum.map(array, fn)`
     * - `array.filter(fn)` → `Enum.filter(array, fn)` (with variable substitution)
     * - `array.join(sep)` → `Enum.join(array, sep)`
     * - `array.push(item)` → `array ++ [item]`
     * - `array.reduce(fn, init)` → `Enum.reduce(array, init, fn)` (parameter reordering)
     * 
     * HOW:
     * 1. Save and disable loop context to prevent argument compilation interference
     * 2. Compile method arguments with context isolation
     * 3. For lambda arguments, apply variable substitution for proper parameter names
     * 4. Handle special cases like reduce parameter reordering
     * 5. Generate idiomatic Elixir function calls with proper lambda syntax
     * 6. Restore original loop context
     * 
     * @param objStr The compiled array object expression
     * @param methodName The method being called (e.g., "filter", "map")
     * @param args The method arguments as TypedExpr array
     * @return The compiled Elixir method call
     */
    public function compileArrayMethod(objStr: String, methodName: String, args: Array<TypedExpr>): String {
        #if debug_array_methods
        DebugHelper.debugArrayMethod("compileArrayMethod", "Starting compilation", 'Method: ${methodName}, Args: ${args.length}');
        #end
        
        // Save current loop context and disable it for argument compilation
        // Array method arguments should not be subject to loop variable substitution
        var previousContext = compiler.isInLoopContext;
        compiler.isInLoopContext = false;
        var compiledArgs = args.map(arg -> compiler.compileExpression(arg));
        compiler.isInLoopContext = previousContext;
        
        return switch (methodName) {
            case "join":
                // array.join(separator) → Enum.join(array, separator)
                if (compiledArgs.length > 0) {
                    'Enum.join(${objStr}, ${compiledArgs[0]})';
                } else {
                    'Enum.join(${objStr}, "")';
                }
            case "push":
                // array.push(item) → array = array ++ [item]
                // CRITICAL FIX: In Elixir, lists are immutable. ALL push operations need reassignment.
                // We detect simple variables and generate reassignment automatically.
                if (compiledArgs.length > 0) {
                    // Check if objStr is a simple variable that can be reassigned
                    // This handles the common case of: variable.push(item)
                    var isSimpleVariable = ~/^[a-z_][a-z0-9_]*$/i.match(objStr);
                    
                    if (isSimpleVariable) {
                        // Generate reassignment for ALL push operations on simple variables
                        // This fixes the immutability issue where push doesn't actually modify the list
                        '${objStr} = ${objStr} ++ [${compiledArgs[0]}]';
                    } else {
                        // Complex object or expression - can't auto-reassign
                        // Examples: getArray().push(item) or obj.field.push(item)
                        // The calling code must handle reassignment manually
                        '${objStr} ++ [${compiledArgs[0]}]';
                    }
                } else {
                    objStr;
                }
            case "pop":
                // array.pop() → List.last(array) (note: doesn't modify original)
                'List.last(${objStr})';
            case "shift":
                // array.shift() → hd(array) (gets first element, doesn't modify)
                'hd(${objStr})';
            case "unshift":
                // array.unshift(item) → [item | array]
                if (compiledArgs.length > 0) {
                    '[${compiledArgs[0]} | ${objStr}]';
                } else {
                    objStr;
                }
            case "length":
                // array.length → length(array)
                'length(${objStr})';
            case "copy":
                // array.copy() → array (lists are immutable, so just return the list)
                objStr;
            case "reverse":
                // array.reverse() → Enum.reverse(array)
                'Enum.reverse(${objStr})';
            case "sort":
                // array.sort(compareFn) → Enum.sort(array) or Enum.sort_by(array, fn)
                if (compiledArgs.length > 0) {
                    'Enum.sort(${objStr}, ${compiledArgs[0]})';
                } else {
                    'Enum.sort(${objStr})';
                }
            case "map":
                // array.map(fn) → Enum.map(array, fn)
                if (compiledArgs.length > 0) {
                    // Check if the argument is a lambda that needs variable substitution
                    if (args.length > 0) {
                        switch (args[0].expr) {
                            case TFunction(func):
                                // Use centralized context-sensitive compilation
                                var lambda = ExpressionCompiler.compileLambdaWithContext(compiler, func, "item");
                                return 'Enum.map(${objStr}, fn ${lambda.paramName} -> ${lambda.body} end)';
                            case _:
                                // Not a simple lambda, use regular compilation
                                return 'Enum.map(${objStr}, ${compiledArgs[0]})';
                        }
                    } else {
                        return 'Enum.map(${objStr}, ${compiledArgs[0]})';
                    }
                } else {
                    objStr;
                }
            case "filter":
                // array.filter(fn) → Enum.filter(array, fn)
                if (compiledArgs.length > 0) {
                    // Check if the argument is a lambda that needs variable substitution
                    if (args.length > 0) {
                        switch (args[0].expr) {
                            case TFunction(func):
                                // Use centralized context-sensitive compilation
                                var lambda = ExpressionCompiler.compileLambdaWithContext(compiler, func, "item");
                                return 'Enum.filter(${objStr}, fn ${lambda.paramName} -> ${lambda.body} end)';
                            case _:
                                // Not a simple lambda, use regular compilation
                                return 'Enum.filter(${objStr}, ${compiledArgs[0]})';
                        }
                    } else {
                        return 'Enum.filter(${objStr}, ${compiledArgs[0]})';
                    }
                } else {
                    objStr;
                }
            case "concat":
                // array.concat(other) → array ++ other
                if (compiledArgs.length > 0) {
                    '${objStr} ++ ${compiledArgs[0]}';
                } else {
                    objStr;
                }
            case "contains":
                // array.contains(elem) → Enum.member?(array, elem)
                if (compiledArgs.length > 0) {
                    'Enum.member?(${objStr}, ${compiledArgs[0]})';
                } else {
                    'false';
                }
            case "indexOf":
                // array.indexOf(elem) → Enum.find_index(array, &(&1 == elem))
                if (compiledArgs.length > 0) {
                    'Enum.find_index(${objStr}, &(&1 == ${compiledArgs[0]}))';
                } else {
                    'nil';
                }
            case "reduce", "fold":
                // array.reduce((acc, item) -> acc + item, initial) → Enum.reduce(array, initial, fn item, acc -> acc + item end)
                if (compiledArgs.length >= 2) {
                    // Check if the first argument is a lambda that needs variable substitution
                    if (args.length >= 1) {
                        switch (args[0].expr) {
                            case TFunction(func):
                                // Use centralized context-sensitive compilation for reduce
                                // Note: Haxe uses (acc, item) but Elixir uses (item, acc) parameter order
                                
                                // Enable loop context for lambda body compilation
                                var previousContext = compiler.isInLoopContext;
                                compiler.isInLoopContext = true;
                                
                                // Extract parameter information with reordering
                                var accParamTVar = func.args.length > 0 ? func.args[0].v : null;
                                var itemParamTVar = func.args.length > 1 ? func.args[1].v : null;
                                var elixirItemName = "item";
                                var elixirAccName = "acc";
                                
                                // Apply variable substitution for both parameters
                                var bodyAfterAccSubst = accParamTVar != null ? 
                                    compiler.compileExpressionWithTVarSubstitution(func.expr, accParamTVar, elixirAccName) : 
                                    compiler.compileExpression(func.expr);
                                
                                // Apply second parameter substitution
                                var compiledBody = bodyAfterAccSubst;
                                if (itemParamTVar != null) {
                                    var originalItemName = compiler.getOriginalVarName(itemParamTVar);
                                    if (compiledBody != null && originalItemName != null && elixirItemName != null) {
                                        var safeCompiledBody: String = compiledBody;
                                        var safeOriginalName: String = originalItemName;
                                        var safeElixirName: String = elixirItemName;
                                        compiledBody = StringTools.replace(safeCompiledBody, safeOriginalName, safeElixirName);
                                    }
                                }
                                
                                // Restore previous context
                                compiler.isInLoopContext = previousContext;
                                
                                // Elixir's Enum.reduce expects (collection, initial, fn item, acc -> result end)
                                return 'Enum.reduce(${objStr}, ${compiledArgs[1]}, fn ${elixirItemName}, ${elixirAccName} -> ${compiledBody} end)';
                            case _:
                                // Not a simple lambda, use regular compilation
                                return 'Enum.reduce(${objStr}, ${compiledArgs[1]}, ${compiledArgs[0]})';
                        }
                    } else {
                        return 'Enum.reduce(${objStr}, ${compiledArgs[1]}, ${compiledArgs[0]})';
                    }
                } else {
                    objStr; // Not enough arguments for reduce
                }
            case "find":
                // array.find(predicate) → Enum.find(array, predicate)
                if (compiledArgs.length > 0) {
                    // Check if the argument is a lambda that needs variable substitution
                    if (args.length > 0) {
                        switch (args[0].expr) {
                            case TFunction(func):
                                // Use centralized context-sensitive compilation
                                var lambda = ExpressionCompiler.compileLambdaWithContext(compiler, func, "item");
                                return 'Enum.find(${objStr}, fn ${lambda.paramName} -> ${lambda.body} end)';
                            case _:
                                // Not a simple lambda, use regular compilation
                                return 'Enum.find(${objStr}, ${compiledArgs[0]})';
                        }
                    } else {
                        return 'Enum.find(${objStr}, ${compiledArgs[0]})';
                    }
                } else {
                    'nil';
                }
            case "findIndex":
                // array.findIndex(predicate) → Enum.find_index(array, predicate)
                if (compiledArgs.length > 0) {
                    // Check if the argument is a lambda that needs variable substitution
                    if (args.length > 0) {
                        switch (args[0].expr) {
                            case TFunction(func):
                                // Use centralized context-sensitive compilation
                                var lambda = ExpressionCompiler.compileLambdaWithContext(compiler, func, "item");
                                return 'Enum.find_index(${objStr}, fn ${lambda.paramName} -> ${lambda.body} end)';
                            case _:
                                // Not a simple lambda, use regular compilation
                                return 'Enum.find_index(${objStr}, ${compiledArgs[0]})';
                        }
                    } else {
                        return 'Enum.find_index(${objStr}, ${compiledArgs[0]})';
                    }
                } else {
                    'nil';
                }
            case "exists", "any":
                // array.exists(predicate) → Enum.any?(array, predicate)
                if (compiledArgs.length > 0) {
                    // Check if the argument is a lambda that needs variable substitution
                    if (args.length > 0) {
                        switch (args[0].expr) {
                            case TFunction(func):
                                // Use centralized context-sensitive compilation
                                var lambda = ExpressionCompiler.compileLambdaWithContext(compiler, func, "item");
                                return 'Enum.any?(${objStr}, fn ${lambda.paramName} -> ${lambda.body} end)';
                            case _:
                                // Not a simple lambda, use regular compilation
                                return 'Enum.any?(${objStr}, ${compiledArgs[0]})';
                        }
                    } else {
                        return 'Enum.any?(${objStr}, ${compiledArgs[0]})';
                    }
                } else {
                    'false';
                }
            case "foreach", "all":
                // array.foreach(predicate) → Enum.all?(array, predicate)
                if (compiledArgs.length > 0) {
                    // Check if the argument is a lambda that needs variable substitution
                    if (args.length > 0) {
                        switch (args[0].expr) {
                            case TFunction(func):
                                // Use centralized context-sensitive compilation
                                var lambda = ExpressionCompiler.compileLambdaWithContext(compiler, func, "item");
                                return 'Enum.all?(${objStr}, fn ${lambda.paramName} -> ${lambda.body} end)';
                            case _:
                                // Not a simple lambda, use regular compilation
                                return 'Enum.all?(${objStr}, ${compiledArgs[0]})';
                        }
                    } else {
                        return 'Enum.all?(${objStr}, ${compiledArgs[0]})';
                    }
                } else {
                    'true';
                }
            case "forEach":
                // array.forEach(action) → Enum.each(array, action)
                if (compiledArgs.length > 0) {
                    // Check if the argument is a lambda that needs variable substitution
                    if (args.length > 0) {
                        switch (args[0].expr) {
                            case TFunction(func):
                                // Use centralized context-sensitive compilation
                                var lambda = ExpressionCompiler.compileLambdaWithContext(compiler, func, "item");
                                return 'Enum.each(${objStr}, fn ${lambda.paramName} -> ${lambda.body} end)';
                            case _:
                                // Not a simple lambda, use regular compilation
                                return 'Enum.each(${objStr}, ${compiledArgs[0]})';
                        }
                    } else {
                        return 'Enum.each(${objStr}, ${compiledArgs[0]})';
                    }
                } else {
                    ':ok';
                }
            case "take":
                // array.take(n) → Enum.take(array, n)
                if (compiledArgs.length > 0) {
                    'Enum.take(${objStr}, ${compiledArgs[0]})';
                } else {
                    objStr;
                }
            case "drop":
                // array.drop(n) → Enum.drop(array, n)
                if (compiledArgs.length > 0) {
                    'Enum.drop(${objStr}, ${compiledArgs[0]})';
                } else {
                    objStr;
                }
            case "flatMap":
                // array.flatMap(fn) → Enum.flat_map(array, fn)
                if (compiledArgs.length > 0) {
                    // Check if the argument is a lambda that needs variable substitution
                    if (args.length > 0) {
                        switch (args[0].expr) {
                            case TFunction(func):
                                // Use centralized context-sensitive compilation
                                var lambda = ExpressionCompiler.compileLambdaWithContext(compiler, func, "item");
                                return 'Enum.flat_map(${objStr}, fn ${lambda.paramName} -> ${lambda.body} end)';
                            case _:
                                // Not a simple lambda, use regular compilation
                                return 'Enum.flat_map(${objStr}, ${compiledArgs[0]})';
                        }
                    } else {
                        return 'Enum.flat_map(${objStr}, ${compiledArgs[0]})';
                    }
                } else {
                    objStr;
                }
            case _:
                // Default: try to call as a regular method
                '${objStr}.${methodName}(${compiledArgs.join(", ")})';
        };
    }
}

#end