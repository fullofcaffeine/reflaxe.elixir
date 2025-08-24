package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.Context;
import reflaxe.elixir.ElixirCompiler;import haxe.macro.Expr;
import reflaxe.elixir.ElixirCompiler;import reflaxe.BaseCompiler;
import reflaxe.elixir.ElixirCompiler;
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
    
    var compiler: reflaxe.elixir.ElixirCompiler; // ElixirCompiler reference
    
    /**
     * Create a new method call compiler
     * 
     * @param compiler The main ElixirCompiler instance
     */
    public function new(compiler: reflaxe.elixir.ElixirCompiler) {
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
                if (isElixirSyntaxCall(obj, fieldName)) {
                    #if debug_method_call_compiler
                    trace("[XRay MethodCallCompiler] ✓ ELIXIR SYNTAX CALL DETECTED");
                    #end
                    return compileElixirSyntaxCall(fieldName, el);
                }
                
                // Check for TypeSafeChildSpec enum constructor calls
                if (isTypeSafeChildSpecCall(obj, fieldName)) {
                    #if debug_method_call_compiler
                    trace("[XRay MethodCallCompiler] ✓ TYPESAFE CHILDSPEC CALL DETECTED");
                    #end
                    return compileTypeSafeChildSpecCall(fieldName, el);
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
        
        #if debug_state_threading
        trace('[XRay MethodCallCompiler] 🔍 Method call: ${objStr}.${methodName}() - StateThreading: ${compiler.isStateThreadingEnabled()}');
        #end
        
        /**
         * STATE THREADING TRANSFORMATION
         * 
         * WHY: Method calls on mutable structs need to capture return values
         * WHAT: Transform struct.method() to struct = struct.method() for mutating methods
         * HOW: Check if object is a struct reference and method is mutating
         */
        if (compiler.isStateThreadingEnabled() && isStructMethodCall(obj, fa)) {
            #if debug_state_threading
            trace('[XRay MethodCallCompiler] 🔧 Potential struct method call: ${objStr}.${methodName}()');
            #end
            
            // Check if this is a mutating method that should capture return value
            if (isMutatingStructMethod(obj, methodName)) {
                var compiledArgs = args.map(arg -> compiler.compileExpression(arg));
                var callExpression = objStr + "." + compiler.toElixirName(methodName) + "(" + compiledArgs.join(", ") + ")";
                
                #if debug_state_threading
                trace('[XRay MethodCallCompiler] ✓ Transforming mutating method call: ${objStr} = ${callExpression}');
                #end
                
                // Return the assignment form
                return objStr + " = " + callExpression;
            }
        }
        
        // Detect Phoenix.PubSub operations
        if (objStr == "Phoenix.PubSub" || objStr == "PubSub") {
            return compilePubSubCall(methodName, args);
        }
        
        /*
         * PHOENIX.LIVEVIEW.ASSIGN_MULTIPLE FIX EXPLANATION:
         * 
         * Problem: Generated code was calling non-existent Phoenix.LiveView.assign_multiple/2
         * Root Cause: Haxe inline function with __elixir__() wasn't being properly inlined
         * 
         * Original broken implementation (inline function):
         * ```haxe
         * static inline function assign_multiple<TAssigns>(socket: Socket<TAssigns>, assigns: TAssigns): Socket<TAssigns> {
         *     return untyped __elixir__("Phoenix.LiveView.assign(socket, assigns)");
         * }
         * ```
         * This relied on Haxe's inlining mechanism to replace the function call with raw Elixir code,
         * but the inlining wasn't happening properly in the compiler context.
         * 
         * Correct solution (extern function with @:native):
         * ```haxe
         * @:native("assign")
         * static function assign_multiple<TAssigns>(socket: Socket<TAssigns>, assigns: TAssigns): Socket<TAssigns>;
         * ```
         * This works because:
         * 1. MethodCallCompiler.compileStaticCall() line 230 calls compiler.getFieldName(fa)
         * 2. ElixirCompiler.getFieldName() (lines 2158-2167) properly extracts @:native annotation
         * 3. Generated code becomes Phoenix.LiveView.assign() instead of Phoenix.LiveView.assign_multiple()
         * 
         * WHY @:native works:
         * - Static extern methods go through proper field access compilation path
         * - getFieldName() checks for @:native metadata and extracts the native name
         * - The compiler's existing @:native handling works correctly for static extern functions
         * 
         * This demonstrates the proper pattern for mapping Haxe method names to different target names:
         * Use @:native annotations on extern functions rather than inline + __elixir__() hacks.
         * 
         * WHEN TO USE __elixir__() INSTEAD:
         * The __elixir__() pattern should ONLY be used in these emergency scenarios:
         * 1. Complex multi-line Elixir code that cannot be expressed as a single method call
         * 2. Raw Elixir syntax that has no Haxe equivalent (e.g., complex pattern matching)
         * 3. Temporary workarounds during development while proper externs are being written
         * 4. Code injection that requires multiple Elixir expressions or statements
         * 
         * Examples where __elixir__() is appropriate:
         * ```haxe
         * static inline function complexPattern<T>(value: T): Result<T, String> {
         *     return untyped __elixir__("
         *         case value do
         *           {:ok, result} when is_map(result) -> {:ok, result}
         *           {:error, reason} -> {:error, to_string(reason)}
         *           other -> {:error, \"Invalid format: #{inspect(other)}\"}
         *         end
         *     ");
         * }
         * ```
         * 
         * The key principle: @:native for single method mapping, __elixir__() for complex code injection.
         */
        
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
    
    /**
     * Compile elixir.Syntax method calls to __elixir__ injection calls
     * 
     * WHY: elixir.Syntax provides type-safe access to Elixir-specific syntax patterns
     * that can't be expressed in Haxe. These need to be transformed into direct Elixir
     * code generation while maintaining compile-time validation.
     * 
     * WHAT: Transforms type-safe elixir.Syntax calls into the underlying __elixir__
     * injection mechanism that Reflaxe processes via targetCodeInjectionName.
     * Supports: code, plainCode, atom, tuple, keyword, map, list, pipe, match
     * 
     * HOW: Pattern matches on method names and generates appropriate Elixir syntax:
     * 1. Validates argument counts and types at compile-time
     * 2. Handles placeholder substitution for parameterized code injection
     * 3. Generates idiomatic Elixir patterns (atoms, tuples, maps, etc.)
     * 4. Provides error reporting for invalid usage
     * 
     * @param methodName The elixir.Syntax method being called (code, atom, tuple, etc.)
     * @param args The arguments to the method call
     * @return Compiled Elixir code
     */
    public function compileElixirSyntaxCall(methodName: String, args: Array<TypedExpr>): String {
        return switch (methodName) {
            case "code":
                // elixir.Syntax.code(code, ...args) → direct injection
                if (args.length == 0) {
                    Context.error("elixir.Syntax.code requires at least one String argument.", Context.currentPos());
                    "";
                } else {
                    // Get the code string from the first argument
                    var codeString = switch (args[0].expr) {
                        case TConst(TString(s)): s;
                        case _: 
                            Context.error("elixir.Syntax.code first parameter must be a constant String.", args[0].pos);
                            "";
                    };
                    
                    // Compile the remaining arguments
                    var compiledArgs = [];
                    for (i in 1...args.length) {
                        compiledArgs.push(compiler.compileExpression(args[i]));
                    }
                    
                    // Validate placeholder count matches argument count (js.Syntax pattern)
                    var placeholderCount = 0;
                    ~/{(\d+)}/g.map(codeString, function(ereg) {
                        var num = Std.parseInt(ereg.matched(1));
                        if (num != null && num >= placeholderCount) {
                            placeholderCount = num + 1;
                        }
                        return ereg.matched(0);
                    });
                    
                    if (placeholderCount > compiledArgs.length) {
                        Context.error('elixir.Syntax.code() requires ${placeholderCount} arguments but ${compiledArgs.length} provided', Context.currentPos());
                    }
                    
                    // Replace {N} placeholders with compiled arguments (following js.Syntax pattern)
                    var result = ~/{(\d+)}/g.map(codeString, function(ereg) {
                        var num = Std.parseInt(ereg.matched(1));
                        return (num != null && num < compiledArgs.length) ? compiledArgs[num] : ereg.matched(0);
                    });
                    
                    return result;
                }
                
            case "plainCode":
                // elixir.Syntax.plainCode(code) → direct injection without interpolation
                if (args.length != 1) {
                    Context.error("elixir.Syntax.plainCode requires exactly one String argument.", Context.currentPos());
                    "";
                } else {
                    switch (args[0].expr) {
                        case TConst(TString(s)): s;
                        case _:
                            Context.error("elixir.Syntax.plainCode parameter must be a constant String.", args[0].pos);
                            "";
                    }
                }
                
            case "atom":
                // elixir.Syntax.atom(name) → :name
                if (args.length != 1) {
                    Context.error("elixir.Syntax.atom requires exactly one String argument.", Context.currentPos());
                    "";
                } else {
                    switch (args[0].expr) {
                        case TConst(TString(s)): ':$s';
                        case _:
                            var atomName = compiler.compileExpression(args[0]);
                            ':${atomName}';
                    }
                }
                
            case "tuple":
                // elixir.Syntax.tuple(...args) → {arg1, arg2, ...}
                var compiledArgs = args.map(arg -> compiler.compileExpression(arg));
                '{${compiledArgs.join(", ")}}';
                
            case "keyword":
                // elixir.Syntax.keyword([key1, value1, key2, value2]) → [key1: value1, key2: value2]
                if (args.length != 1) {
                    Context.error("elixir.Syntax.keyword requires exactly one Array argument.", Context.currentPos());
                    "";
                } else {
                    switch (args[0].expr) {
                        case TArrayDecl(elements):
                            if (elements.length % 2 != 0) {
                                Context.error("elixir.Syntax.keyword array must have an even number of elements (key-value pairs).", args[0].pos);
                                "";
                            } else {
                                var pairs = [];
                                var i = 0;
                                while (i < elements.length) {
                                    var key = compiler.compileExpression(elements[i]);
                                    var value = compiler.compileExpression(elements[i + 1]);
                                    pairs.push('${key}: ${value}');
                                    i += 2;
                                }
                                '[${pairs.join(", ")}]';
                            }
                        case _:
                            Context.error("elixir.Syntax.keyword parameter must be an array literal.", args[0].pos);
                            "";
                    }
                }
                
            case "map":
                // elixir.Syntax.map([key1, value1, key2, value2]) → %{key1 => value1, key2 => value2}
                if (args.length != 1) {
                    Context.error("elixir.Syntax.map requires exactly one Array argument.", Context.currentPos());
                    "";
                } else {
                    switch (args[0].expr) {
                        case TArrayDecl(elements):
                            if (elements.length % 2 != 0) {
                                Context.error("elixir.Syntax.map array must have an even number of elements (key-value pairs).", args[0].pos);
                                "";
                            } else {
                                var pairs = [];
                                var i = 0;
                                while (i < elements.length) {
                                    var key = compiler.compileExpression(elements[i]);
                                    var value = compiler.compileExpression(elements[i + 1]);
                                    pairs.push('${key} => ${value}');
                                    i += 2;
                                }
                                '%{${pairs.join(", ")}}';
                            }
                        case _:
                            Context.error("elixir.Syntax.map parameter must be an array literal.", args[0].pos);
                            "";
                    }
                }
                
            case "list":
                // elixir.Syntax.list(...args) → [arg1, arg2, ...]
                var compiledArgs = args.map(arg -> compiler.compileExpression(arg));
                '[${compiledArgs.join(", ")}]';
                
            case "pipe":
                // elixir.Syntax.pipe(initial, ...operations) → initial |> op1 |> op2 |> ...
                if (args.length < 2) {
                    Context.error("elixir.Syntax.pipe requires at least two arguments (initial value and operations).", Context.currentPos());
                    "";
                } else {
                    var initial = compiler.compileExpression(args[0]);
                    var operations = [];
                    for (i in 1...args.length) {
                        operations.push(compiler.compileExpression(args[i]));
                    }
                    '${initial} |> ${operations.join(" |> ")}';
                }
                
            case "match":
                // elixir.Syntax.match(value, patterns) → case value do patterns end
                if (args.length != 2) {
                    Context.error("elixir.Syntax.match requires exactly two arguments (value and patterns).", Context.currentPos());
                    "";
                } else {
                    var value = compiler.compileExpression(args[0]);
                    var patterns = switch (args[1].expr) {
                        case TConst(TString(s)): s;
                        case _:
                            Context.error("elixir.Syntax.match patterns must be a constant String.", args[1].pos);
                            "";
                    };
                    'case ${value} do\n  ${StringTools.replace(patterns, "\\n", "\n  ")}\nend';
                }
                
            case _:
                Context.error('Unknown elixir.Syntax method: ${methodName}', Context.currentPos());
                "";
        };
    }
    
    /**
     * Check if a method call is a TypeSafeChildSpec enum constructor call
     * 
     * WHY: TypeSafeChildSpec provides type-safe child specification construction for
     * OTP supervision trees, requiring special compilation to Elixir childspec format.
     * 
     * WHAT: Identifies static calls on TypeSafeChildSpec enum constructors that need
     * to be compiled directly to Elixir child specification tuples.
     * 
     * HOW: Examines the TypedExpr to check if it references the elixir.otp.TypeSafeChildSpec enum.
     * 
     * @param obj The object expression being called on  
     * @param fieldName The constructor name being called
     * @return True if this is a TypeSafeChildSpec constructor call
     */
    public function isTypeSafeChildSpecCall(obj: TypedExpr, fieldName: String): Bool {
        // Check if the object is a reference to TypeSafeChildSpec enum
        switch (obj.expr) {
            case TTypeExpr(moduleType):
                switch (moduleType) {
                    case TEnumDecl(enumRef):
                        var enumType = enumRef.get();
                        return enumType.name == "TypeSafeChildSpec" && 
                               enumType.pack.join(".") == "elixir.otp";
                    case _:
                        return false;
                }
            case _:
                return false;
        }
    }
    
    /**
     * Compile TypeSafeChildSpec enum constructor calls directly to ChildSpec format
     * 
     * WHY: TypeSafeChildSpec constructors need to generate proper Elixir child
     * specifications that follow OTP supervision tree patterns.
     * 
     * WHAT: Transforms TypeSafeChildSpec enum constructors to appropriate Elixir
     * child specification format. Supports: PubSub, Repo, Endpoint, Telemetry.
     * 
     * HOW: Pattern matches on constructor names and generates the corresponding
     * Elixir module references or child specification tuples with proper naming.
     * 
     * @param fieldName The TypeSafeChildSpec constructor name
     * @param args The constructor arguments
     * @return Compiled Elixir child specification
     */
    public function compileTypeSafeChildSpecCall(fieldName: String, args: Array<TypedExpr>): String {
        var appName = reflaxe.elixir.helpers.AnnotationSystem.getEffectiveAppName(compiler.currentClassType);
        
        return switch (fieldName) {
            case "PubSub":
                if (args.length == 1) {
                    var nameArg = compiler.compileExpression(args[0]);
                    // Handle different formats of name argument
                    var cleanName = if (nameArg.indexOf("<>") >= 0) {
                        // For concatenations like 'app_name <> ".PubSub"', keep as-is (already has proper quotes)
                        nameArg;
                    } else {
                        // For simple strings like '"TodoApp.PubSub"', remove quotes for atom format
                        StringTools.replace(nameArg, '"', '');
                    };
                    // Generate modern tuple format for Phoenix.PubSub with atom name
                    '{Phoenix.PubSub, name: ${cleanName}}';
                } else {
                    // Default name based on app - generate as atom
                    '{Phoenix.PubSub, name: ${appName}.PubSub}';
                }
                
            case "Repo":
                // Generate simple module reference
                '${appName}.Repo';
                
            case "Endpoint":
                // Generate simple module reference  
                '${appName}Web.Endpoint';
                
            case "Telemetry":
                // Generate simple module reference
                '${appName}Web.Telemetry';
                
            case _:
                // Fallback to regular enum compilation for unknown constructors
                if (args.length == 0) {
                    ':${reflaxe.elixir.helpers.NamingHelper.toSnakeCase(fieldName)}';
                } else {
                    var argList = args.map(function(arg) return compiler.compileExpression(arg)).join(", ");
                    '{:${reflaxe.elixir.helpers.NamingHelper.toSnakeCase(fieldName)}, ${argList}}';
                }
        };
    }
    
    /**
     * Check if a method call is an elixir.Syntax static method call
     * 
     * WHY: elixir.Syntax calls need special handling as they generate direct Elixir
     * code injection rather than standard method calls.
     * 
     * WHAT: Identifies static method calls on the elixir.Syntax class for special compilation.
     * 
     * HOW: Examines the TypedExpr to see if it references elixir.Syntax module type.
     * 
     * @param obj The object expression being called on
     * @param fieldName The method name being called
     * @return True if this is an elixir.Syntax method call
     */
    public function isElixirSyntaxCall(obj: TypedExpr, fieldName: String): Bool {
        switch (obj.expr) {
            case TTypeExpr(moduleType):
                // Check if this is the elixir.Syntax module
                switch (moduleType) {
                    case TClassDecl(c):
                        var classRef = c.get();
                        var fullPath = classRef.pack.join(".") + (classRef.pack.length > 0 ? "." : "") + classRef.name;
                        return fullPath == "elixir.Syntax";
                    case TTypeDecl(t):
                        // Handle typedef case (though elixir.Syntax should be a class)
                        var typeRef = t.get();
                        var fullPath = typeRef.pack.join(".") + (typeRef.pack.length > 0 ? "." : "") + typeRef.name;
                        return fullPath == "elixir.Syntax";
                    case _:
                        return false;
                }
            case _:
                return false;
        }
    }
    
    /**
     * Check if a method call is on a struct instance
     * 
     * WHY: We only transform method calls on struct instances, not static calls
     * WHAT: Detect if the object is a struct reference (local variable or field access)
     * HOW: Check the object expression type and structure
     */
    private function isStructMethodCall(obj: TypedExpr, fa: FieldAccess): Bool {
        // Check if object is a local variable or field access that could be a struct
        switch (obj.expr) {
            case TLocal(_):
                // Local variable could be a struct instance
                return true;
            case TField(_, _):
                // Field access could be accessing a struct field
                return true;
            case _:
                // Other expressions are unlikely to be struct instances
                return false;
        }
    }
    
    /**
     * Check if a method on a struct is mutating and should capture return value
     * 
     * WHY: Only mutating methods need return value capture transformation
     * WHAT: Identify methods that modify struct state
     * HOW: Check method name patterns and known mutating operations
     */
    private function isMutatingStructMethod(obj: TypedExpr, methodName: String): Bool {
        // Common mutating method patterns
        var mutatingPatterns = [
            "write", "add", "push", "pop", "remove", "clear", "set", "update",
            "append", "prepend", "insert", "delete", "merge", "replace",
            "quote_", "fields_string", "class_string"  // JsonPrinter specific methods
        ];
        
        for (pattern in mutatingPatterns) {
            if (methodName == pattern || methodName.indexOf(pattern) == 0) {
                #if debug_state_threading
                trace('[XRay MethodCallCompiler] ✓ Detected mutating method: ${methodName}');
                #end
                return true;
            }
        }
        
        return false;
    }
}

#end