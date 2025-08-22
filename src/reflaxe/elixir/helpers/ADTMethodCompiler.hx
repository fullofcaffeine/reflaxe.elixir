package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Type.TypedExpr;
import haxe.macro.Type.EnumType;
import reflaxe.elixir.helpers.DebugHelper;

/**
 * ADTMethodCompiler: Specialized compilation of Algebraic Data Type static extension methods
 * 
 * WHY: Option and Result types from Haxe's functional programming libraries use static
 * extension methods that require specialized compilation to idiomatic Elixir patterns.
 * These ADT operations involve pattern matching, error handling, and functional composition
 * that need careful translation to maintain semantics. This was extracted from 
 * ElixirCompiler.hx to isolate ADT-specific logic and improve maintainability.
 * 
 * WHAT: Transforms ADT static extension methods to Elixir equivalents:
 * - `Option<T>` methods: map, filter, isSome, isNone, unwrap, etc.
 * - `Result<T, E>` methods: map, flatMap, isOk, isError, unwrap, etc.
 * - Proper static extension method delegation to Tools modules
 * - Type-safe error handling and null safety preservation
 * 
 * HOW: 
 * 1. Identify ADT type from enum type metadata (haxe.ds.Option, haxe.functional.Result)
 * 2. Check if method name is valid for the specific ADT type
 * 3. Compile arguments with proper context isolation
 * 4. Generate static extension call pattern: ToolsModule.method(object, args...)
 * 5. Preserve type safety and error handling semantics in generated code
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Focused only on ADT static extension compilation
 * - Open/Closed Principle: Extensible for new ADT types without touching main compiler
 * - Testability: Can be unit tested independently with mock ADT instances
 * - Maintainability: Clear separation from other method compilation concerns
 * - Type Safety: Preserves functional programming guarantees in generated code
 * 
 * EDGE CASES:
 * - Must preserve null safety semantics of Option type
 * - Result type error handling must translate correctly to Elixir patterns
 * - Static extension methods require proper module qualification
 * - Type parameters need proper handling in generic contexts
 * - Unknown ADT types should fallback gracefully
 * 
 * @see documentation/ADT_METHOD_COMPILATION.md - Detailed ADT method compilation patterns
 */
@:nullSafety(Off)
class ADTMethodCompiler {
    
    private var compiler: reflaxe.elixir.ElixirCompiler;
    
    public function new(compiler: reflaxe.elixir.ElixirCompiler) {
        this.compiler = compiler;
    }
    
    /**
     * Check if a method name is an OptionTools static extension method
     * 
     * WHY: Option<T> provides functional programming operations for nullable values
     * that need to be identified and transformed to maintain type safety semantics.
     * 
     * WHAT: Returns true for Option static extension methods including map, filter,
     * unwrap operations, and type checking methods like isSome/isNone.
     * 
     * HOW: Uses pattern matching to identify known OptionTools method names that
     * require special handling for null safety preservation.
     */
    public function isOptionMethod(methodName: String): Bool {
        return switch (methodName) {
            case "map", "then", "flatMap", "flatten", "filter", "unwrap", 
                 "lazyUnwrap", "or", "lazyOr", "isSome", "isNone", 
                 "all", "values", "toResult", "fromResult", "fromNullable",
                 "toNullable", "toReply", "expect", "some", "none", "apply":
                true;
            case _:
                false;
        };
    }
    
    /**
     * Check if a method name is a ResultTools static extension method
     * 
     * WHY: Result<T, E> provides functional error handling operations that need
     * to be identified and transformed to maintain error semantics in Elixir.
     * 
     * WHAT: Returns true for Result static extension methods including map, flatMap,
     * error handling operations, and type checking methods like isOk/isError.
     * 
     * HOW: Uses pattern matching to identify known ResultTools method names that
     * require special handling for error propagation and type safety.
     */
    public function isResultMethod(methodName: String): Bool {
        return switch (methodName) {
            case "map", "flatMap", "bind", "fold", "filter", "isOk", "isError", 
                 "unwrap", "unwrapOr", "unwrapOrElse", "mapError", "bimap",
                 "ok", "error", "sequence", "traverse", "toOption":
                true;
            case _:
                false;
        };
    }
    
    /**
     * Check if an enum type has static extension methods and compile them
     * 
     * WHY: ADT types like Option and Result use static extension methods for
     * functional operations. These need to be compiled as proper static calls
     * to the corresponding Tools modules rather than instance method calls.
     * 
     * WHAT: Identifies ADT enum types, validates method names, and generates
     * proper static extension calls in the format ToolsModule.method(object, args...).
     * 
     * HOW:
     * 1. Check enum module and name to identify ADT type (Option, Result)
     * 2. Validate that method name is supported for the specific ADT type
     * 3. Compile arguments with proper context isolation
     * 4. Generate static extension call with proper argument ordering
     * 5. Return null if not an ADT type or unsupported method
     * 
     * @param enumType The enum type being called on
     * @param methodName The method name being called
     * @param objStr The compiled object expression
     * @param args The method arguments
     * @return Compiled static extension call or null if not applicable
     */
    public function compileADTStaticExtension(enumType: EnumType, methodName: String, objStr: String, args: Array<TypedExpr>): Null<String> {
        #if debug_adt_methods
        DebugHelper.debugADTMethod("compileADTStaticExtension", "Starting compilation", 'Type: ${enumType.name}, Method: ${methodName}');
        #end
        
        var toolsModule: String = null;
        var isExtensionMethod: Bool = false;
        
        // Check which ADT type this is and if the method is valid
        if (enumType.module == "haxe.ds.Option" && enumType.name == "Option") {
            toolsModule = "OptionTools";
            isExtensionMethod = isOptionMethod(methodName);
            #if debug_adt_methods
            DebugHelper.debugADTMethod("Option Detection", "Identified Option type", 'Method valid: ${isExtensionMethod}');
            #end
        } else if (enumType.module == "haxe.functional.Result" && enumType.name == "Result") {
            toolsModule = "ResultTools";
            isExtensionMethod = isResultMethod(methodName);
            #if debug_adt_methods
            DebugHelper.debugADTMethod("Result Detection", "Identified Result type", 'Method valid: ${isExtensionMethod}');
            #end
        }
        
        if (toolsModule != null && isExtensionMethod) {
            var compiledArgs = args.map(arg -> compiler.compileExpression(arg));
            // Call ToolsModule.method(object, args...) for static extension methods
            var result = '${toolsModule}.${methodName}(${objStr}${compiledArgs.length > 0 ? ", " + compiledArgs.join(", ") : ""})';
            
            #if debug_adt_methods
            DebugHelper.debugADTMethod("ADT Compilation", "✓ SUCCESS", 'Generated: ${result}');
            #end
            
            return result;
        }
        
        #if debug_adt_methods
        DebugHelper.debugADTMethod("ADT Compilation", "Not applicable", 'Module: ${enumType.module}, Name: ${enumType.name}');
        #end
        
        return null;
    }
}

#end