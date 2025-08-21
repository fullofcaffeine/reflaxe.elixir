package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.Expr;
import reflaxe.BaseCompiler;

using reflaxe.helpers.NullHelper;
using reflaxe.helpers.NameMetaHelper;
using reflaxe.helpers.SyntaxHelper;
using reflaxe.helpers.TypedExprHelper;
using StringTools;

/**
 * Method Call Compiler for Reflaxe.Elixir
 * 
 * WHY: Method call compilation was a massive section of the main ElixirCompiler (400+ lines).
 * This includes complex logic for ADT types, repository operations, PubSub calls, and more.
 * 
 * WHAT: Specialized compilation of method calls with comprehensive patterns:
 * - ADT (Algebraic Data Type) method compilation (Option, Result, etc.)
 * - Repository operation detection and compilation
 * - Phoenix PubSub method handling
 * - Array/Map extension method compilation
 * - Standard library method call transformation
 * - Special handling for reflection and introspection calls
 * 
 * HOW: The compiler receives method call expressions and:
 * 1. Identifies the call pattern (static, instance, extension)
 * 2. Applies appropriate transformation based on target type
 * 3. Generates idiomatic Elixir method calls
 * 4. Handles special framework patterns (Phoenix, Ecto)
 * 
 * @see documentation/METHOD_CALL_COMPILATION.md - Complete method call patterns
 */
@:nullSafety(Off)
class MethodCallCompiler {
    
    var compiler: Dynamic; // ElixirCompiler reference
    
    /**
     * Create a new method call compiler
     * 
     * @param compiler The main ElixirCompiler instance
     */
    public function new(compiler: Dynamic) {
        this.compiler = compiler;
    }
    
    /**
     * Compile TCall call expressions with special case handling
     * 
     * WHY: TCall expressions need sophisticated analysis for compile-time functions and special syntax
     * 
     * WHAT: Transform Haxe method calls to appropriate Elixir function call patterns
     * 
     * HOW:
     * 1. Check for special compile-time function calls (getAppName, etc.)
     * 2. Handle function parameter calls with .() syntax
     * 3. Detect framework-specific calls (Elixir syntax, TypeSafeChildSpec)
     * 4. Delegate to standard method call compilation
     * 
     * @param e The function expression being called
     * @param el The array of argument expressions
     * @return Compiled Elixir function call expression
     */
    public function compileCallExpression(e: TypedExpr, el: Array<TypedExpr>): String {
        #if debug_method_call_compiler
        trace("[XRay MethodCallCompiler] CALL EXPRESSION COMPILATION START");
        trace('[XRay MethodCallCompiler] Call expression type: ${e.expr}');
        trace('[XRay MethodCallCompiler] Arguments count: ${el.length}');
        #end
        
        // Check for special compile-time function calls
        var result = switch (e.expr) {
            case TLocal(v) if (v.name == "getAppName"):
                #if debug_method_call_compiler
                trace("[XRay MethodCallCompiler] ✓ COMPILE-TIME getAppName DETECTED");
                #end
                // Resolve app name at compile-time from @:appName annotation
                var appName = AnnotationSystem.getEffectiveAppName(compiler.currentClassType);
                '"${appName}"';
                
            case TLocal(v):
                #if debug_method_call_compiler
                trace("[XRay MethodCallCompiler] ✓ LOCAL FUNCTION CALL DETECTED");
                #end
                // Check if this is a function parameter being called
                // Function parameters need special syntax in Elixir: func_name.(args)
                var varType = v.t;
                var isFunction = switch (varType) {
                    case TFun(_, _): true;
                    case _: false;
                };
                
                if (isFunction) {
                    #if debug_method_call_compiler
                    trace("[XRay MethodCallCompiler] ✓ FUNCTION PARAMETER CALL (.() syntax)");
                    #end
                    // This is a function parameter being called - use Elixir's .() syntax
                    var functionName = NamingHelper.toSnakeCase(v.name);
                    var compiledArgs = el.map(arg -> compiler.compileExpression(arg));
                    '${functionName}.(${compiledArgs.join(", ")})';
                } else {
                    // Regular local function call - delegate to standard method compilation
                    compileMethodCall(e, el);
                }
                
            case TField(obj, field):
                #if debug_method_call_compiler
                trace("[XRay MethodCallCompiler] ✓ FIELD METHOD CALL DETECTED");
                #end
                var fieldName = switch (field) {
                    case FInstance(_, _, cf) | FStatic(_, cf) | FClosure(_, cf): cf.get().name;
                    case FAnon(cf): cf.get().name;
                    case FEnum(_, ef): ef.name;
                    case FDynamic(s): s;
                };
                
                #if debug_method_call_compiler
                trace('[XRay MethodCallCompiler] Field name: ${fieldName}');
                #end
                
                // Check for super method calls (TField on TSuper)
                if (obj.expr.match(TConst(TSuper)) && fieldName == "toString") {
                    #if debug_method_call_compiler
                    trace("[XRay MethodCallCompiler] ✓ SUPER.toString() DETECTED");
                    #end
                    // Handle super.toString() specially for exception classes
                    return '"Exception"';
                }
                
                // Check for elixir.Syntax calls and transform them to __elixir__ injection
                if (compiler.isElixirSyntaxCall(obj, fieldName)) {
                    #if debug_method_call_compiler
                    trace("[XRay MethodCallCompiler] ✓ ELIXIR SYNTAX CALL DETECTED");
                    #end
                    return compiler.compileElixirSyntaxCall(fieldName, el);
                }
                
                // Check for TypeSafeChildSpec enum constructor calls
                if (compiler.isTypeSafeChildSpecCall(obj, fieldName)) {
                    #if debug_method_call_compiler
                    trace("[XRay MethodCallCompiler] ✓ TYPESAFE CHILDSPEC CALL DETECTED");
                    #end
                    return compiler.compileTypeSafeChildSpecCall(fieldName, el);
                }
                
                if (fieldName == "getAppName") {
                    #if debug_method_call_compiler
                    trace("[XRay MethodCallCompiler] ✓ CLASS.getAppName() DETECTED");
                    #end
                    // Handle Class.getAppName() calls
                    var appName = AnnotationSystem.getEffectiveAppName(compiler.currentClassType);
                    return '"${appName}"';
                }
                
                // Regular field method call - delegate to standard method compilation
                compileMethodCall(e, el);
                
            case _:
                #if debug_method_call_compiler
                trace("[XRay MethodCallCompiler] ✓ STANDARD METHOD CALL");
                #end
                // Not a special function call, proceed normally
                compileMethodCall(e, el);
        };
        
        #if debug_method_call_compiler
        trace('[XRay MethodCallCompiler] Generated call: ${result != null ? result.substring(0, 100) + (result.length > 100 ? "..." : "") : "null"}');
        trace("[XRay MethodCallCompiler] CALL EXPRESSION COMPILATION END");
        #end
        
        return result;
    }
    
    /**
     * Compile method call with repository operation detection
     * 
     * WHY: Method calls need special handling for different patterns
     * 
     * WHAT: Comprehensive method call processing including:
     * - Repository operations (Repo.method calls)
     * - Phoenix PubSub operations
     * - HXX template function calls
     * - ADT type method calls
     * - Array/Map extension methods
     * 
     * HOW:
     * 1. Analyze method call pattern and target type
     * 2. Apply appropriate transformation
     * 3. Generate idiomatic Elixir code
     * 
     * @param e Function expression being called
     * @param args Arguments to the method call
     * @return Generated Elixir method call
     */
    public function compileMethodCall(e: TypedExpr, args: Array<TypedExpr>): String {
        #if debug_method_call_compiler
        trace("[XRay MethodCallCompiler] COMPILE CALL START");
        trace('[XRay MethodCallCompiler] Method expr: ${e.expr}');
        #end
        
        // Check for repository operations (Repo.method calls)
        var result = switch (e.expr) {
            case TField(obj, fa):
                compileFieldMethodCall(obj, fa, args);
            case TCall(funcExpr, callArgs):
                compileNestedCall(funcExpr, callArgs, args);
            case _:
                compileGenericCall(e, args);
        };
        
        #if debug_method_call_compiler
        trace('[XRay MethodCallCompiler] Generated call: ${result.substring(0, 100)}...');
        trace("[XRay MethodCallCompiler] COMPILE CALL END");
        #end
        
        return result;
    }
    
    /**
     * Compile field-based method call (obj.method())
     * 
     * WHY: Most method calls are field access patterns
     */
    private function compileFieldMethodCall(obj: TypedExpr, fa: FieldAccess, args: Array<TypedExpr>): String {
        var methodName = compiler.getFieldName(fa);
        var objStr = compiler.compileExpression(obj);
        
        // Detect Phoenix.PubSub operations
        if (objStr == "Phoenix.PubSub" || objStr == "PubSub") {
            return compilePubSubCall(methodName, args);
        }
        
        // Detect HXX template function calls
        if (objStr == "HXX" && methodName == "hxx") {
            return compiler.compileHxxCall(args);
        }
        
        // Also handle direct hxx() calls (via import HXX.*)
        if (methodName == "hxx" && args.length == 1) {
            return compiler.compileHxxCall(args);
        }
        
        // Check for special tool methods (OptionTools, ResultTools, etc.)
        if (objStr == "OptionTools" && compiler.isOptionMethod(methodName)) {
            var compiledArgs = args.map(arg -> compiler.compileExpression(arg));
            return 'OptionTools.${methodName}(${compiledArgs.join(", ")})';
        } else if (objStr == "ResultTools" && compiler.isResultMethod(methodName)) {
            var compiledArgs = args.map(arg -> compiler.compileExpression(arg));
            return 'ResultTools.${methodName}(${compiledArgs.join(", ")})';
        } else if (objStr == "ArrayTools" && compiler.isArrayMethod(methodName)) {
            return compileArrayToolsCall(methodName, args);
        } else if (objStr == "MapTools" && compiler.isMapMethod(methodName)) {
            return compileMapToolsCall(methodName, args);
        }
        
        // Check if this is an ADT type (Option<T>, Result<T,E>, etc.) with static extension methods
        switch (obj.t) {
            case TEnum(enumRef, _):
                var enumType = enumRef.get();
                var compiled = compiler.compileADTStaticExtension(enumType, methodName, objStr, args);
                if (compiled != null) return compiled;
            case _:
                // Continue with normal method call handling
        }
        
        // Check if this is an Array method call
        switch (obj.t) {
            case TInst(t, _) if (t.get().name == "Array"):
                return compiler.compileArrayMethod(objStr, methodName, args);
            case _:
                // Continue with normal method call handling
        }
        
        // Check if this is a common array method on a Dynamic type
        if (compiler.isArrayMethod(methodName)) {
            return compiler.compileArrayMethod(objStr, methodName, args);
        }
        
        // Handle other method calls normally
        var compiledArgs = args.map(arg -> compiler.compileExpression(arg));
        
        // Check for standard library ADT constructor calls
        if (AlgebraicDataTypeCompiler.isADTTypeName(objStr)) {
            return compileADTConstructorCall(objStr, methodName, args);
        }
        
        // Check if methodName already contains a module path (from @:native annotation)
        if (methodName.indexOf(".") >= 0) {
            // Method name is fully qualified (e.g., "Enum.map")
            return methodName + "(" + [objStr].concat(compiledArgs).join(", ") + ")";
        } else {
            // Standard method call
            return objStr + "." + compiler.toElixirName(methodName) + "(" + compiledArgs.join(", ") + ")";
        }
    }
    
    /**
     * Compile Phoenix PubSub method calls
     * 
     * WHY: PubSub methods need the app's PubSub module as first argument
     */
    private function compilePubSubCall(methodName: String, args: Array<TypedExpr>): String {
        var compiledArgs = args.map(arg -> compiler.compileExpression(arg));
        
        // PubSub methods need the app's PubSub module as first argument
        var appName = compiler.getCurrentAppName();
        var pubsubModule = appName + ".PubSub";
        
        return switch (methodName) {
            case "subscribe":
                // Phoenix.PubSub.subscribe(TodoApp.PubSub, topic)
                "Phoenix.PubSub.subscribe(" + pubsubModule + ", " + compiledArgs.join(", ") + ")";
            case "broadcast":
                // Phoenix.PubSub.broadcast(TodoApp.PubSub, topic, message)
                "Phoenix.PubSub.broadcast(" + pubsubModule + ", " + compiledArgs.join(", ") + ")";
            case "broadcast_from":
                // Phoenix.PubSub.broadcast_from(TodoApp.PubSub, from_pid, topic, message)
                "Phoenix.PubSub.broadcast_from(" + pubsubModule + ", " + compiledArgs.join(", ") + ")";
            default:
                // Other PubSub methods
                "Phoenix.PubSub." + methodName + "(" + pubsubModule + ", " + compiledArgs.join(", ") + ")";
        };
    }
    
    /**
     * Compile ArrayTools static extension calls
     * 
     * WHY: ArrayTools methods need to be converted to idiomatic Elixir Enum calls
     */
    private function compileArrayToolsCall(methodName: String, args: Array<TypedExpr>): String {
        // ArrayTools static extensions need to be compiled to idiomatic Elixir Enum calls
        // The first argument is the array, remaining arguments are method parameters
        if (args.length > 0) {
            var arrayExpr = compiler.compileExpression(args[0]);  // First arg is the array
            var methodArgs = args.slice(1);             // Remaining args are method parameters
            return compiler.compileArrayMethod(arrayExpr, methodName, methodArgs);
        } else {
            // Fallback for methods with no arguments
            return "ArrayTools." + methodName + "()";
        }
    }
    
    /**
     * Compile MapTools static extension calls
     * 
     * WHY: MapTools methods need to be converted to idiomatic Elixir Map calls
     */
    private function compileMapToolsCall(methodName: String, args: Array<TypedExpr>): String {
        // MapTools static extensions need to be compiled to idiomatic Elixir Map calls
        // The first argument is the map, remaining arguments are method parameters
        if (args.length > 0) {
            var mapExpr = compiler.compileExpression(args[0]);    // First arg is the map
            var methodArgs = args.slice(1);             // Remaining args are method parameters
            return compiler.compileMapMethod(mapExpr, methodName, methodArgs);
        } else {
            // Fallback for methods with no arguments
            return "MapTools." + methodName + "()";
        }
    }
    
    /**
     * Compile ADT constructor calls that weren't detected as FEnum
     * 
     * WHY: Some ADT calls come through as regular method calls
     */
    private function compileADTConstructorCall(objStr: String, methodName: String, args: Array<TypedExpr>): String {
        var config = AlgebraicDataTypeCompiler.getADTConfigByTypeName(objStr);
        if (config != null) {
            // Verify this is actually the standard library type, not a user-defined type
            var enumType = null;
            try {
                var fullTypeName = config.moduleName + "." + config.typeName;
                var adtType = haxe.macro.Context.getType(fullTypeName);
                switch (adtType) {
                    case TEnum(enumRef, _):
                        enumType = enumRef.get();
                        // Additional check: ensure this is actually an ADT type
                        if (!AlgebraicDataTypeCompiler.isADTType(enumType)) {
                            enumType = null; // Not actually a standard library ADT
                        }
                    case _:
                }
            } catch (e: Dynamic) {
                // Fallback if type not found - definitely not a standard library type
            }
            
            if (enumType != null) {
                // Create a fake enum field for the method call
                var fakeField = null;
                for (field in enumType.constructs) {
                    if (field.name.toLowerCase() == methodName.toLowerCase()) {
                        fakeField = field;
                        break;
                    }
                }
                
                if (fakeField != null) {
                    var compiled = AlgebraicDataTypeCompiler.compileADTMethodCall(enumType, methodName, args, (expr) -> compiler.compileExpression(expr));
                    if (compiled != null) return compiled;
                }
            }
        }
        
        // Fall back to regular method call
        var compiledArgs = args.map(arg -> compiler.compileExpression(arg));
        return objStr + "." + compiler.toElixirName(methodName) + "(" + compiledArgs.join(", ") + ")";
    }
    
    /**
     * Compile nested function calls
     */
    private function compileNestedCall(funcExpr: TypedExpr, callArgs: Array<TypedExpr>, args: Array<TypedExpr>): String {
        // This handles complex nested calls - delegate to compiler for now
        return compiler.compileExpression(funcExpr) + "(" + args.map(arg -> compiler.compileExpression(arg)).join(", ") + ")";
    }
    
    /**
     * Compile generic method calls
     */
    private function compileGenericCall(e: TypedExpr, args: Array<TypedExpr>): String {
        var functionName = compiler.compileExpression(e);
        var compiledArgs = args.map(arg -> compiler.compileExpression(arg));
        return functionName + "(" + compiledArgs.join(", ") + ")";
    }
}

#end