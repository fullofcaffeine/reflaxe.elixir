package reflaxe.elixir.ast.builders;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.Context;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.CompilationContext;

/**
 * ConstructorBuilder: Handles constructor call compilation (TNew)
 * 
 * WHY: Centralizes constructor transformation logic from ElixirASTBuilder
 * - Extracts ~65 lines of constructor handling logic
 * - Handles Ecto schemas, Maps, and regular classes differently
 * - Manages instance method detection
 * - Determines struct vs constructor function generation
 * 
 * WHAT: Transforms Haxe TNew to appropriate Elixir structures
 * - Ecto schemas → Struct literals %ModuleName{}
 * - Map types → Empty maps %{}
 * - Classes with methods → Module.new() calls
 * - Data classes → Struct literals
 * 
 * HOW: Pattern detection based on class metadata and fields
 * - Check for @:schema annotation for Ecto models
 * - Detect Map types by class name
 * - Analyze fields to find instance methods
 * - Check for constructor presence
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Focused on constructor transformations
 * - Open/Closed: Easy to add new constructor patterns
 * - Testability: Constructor patterns testable independently
 * - Maintainability: ~65 lines extracted to focused module
 * - Performance: Pattern detection optimized in one place
 * 
 * EDGE CASES:
 * - Empty constructors → Empty structs/maps
 * - @:native metadata → Use native module name
 * - StringMap/IntMap → Regular Elixir maps
 * - Classes without methods → Struct literals
 * - Classes with methods → Module.new() calls
 */
@:nullSafety(Off)
class ConstructorBuilder {
    
    /**
     * Build constructor call expression
     * 
     * WHY: Constructors in Haxe map to different Elixir patterns
     * WHAT: Detects class type and generates appropriate construction
     * HOW: Analyze class metadata and fields
     * 
     * @param c Class reference
     * @param params Type parameters (unused in Elixir)
     * @param el Constructor arguments
     * @param context Compilation context
     * @return ElixirASTDef for the constructor call
     */
    public static function build(c: Ref<ClassType>, params: Array<Type>, el: Array<TypedExpr>, context: CompilationContext): Null<ElixirASTDef> {
        var classType = c.get();
        var className = classType.name;
        
        #if debug_ast_builder
        trace('[ConstructorBuilder] Building constructor for class: $className');
        trace('[ConstructorBuilder]   Arguments: ${el.length}');
        trace('[ConstructorBuilder]   Has @:schema: ${classType.meta.has("schema")}');
        #end
        
        // Compile arguments
        var args = [for (e in el) context.compiler.compileExpressionImpl(e, false)];
        
        // ====================================================================
        // PATTERN 1: Ecto Schemas
        // ====================================================================
        if (classType.meta.has("schema")) {
            #if debug_ast_builder
            trace('[ConstructorBuilder] ✓ Detected Ecto schema, generating struct literal');
            #end
            return buildEctoSchema(classType, className);
        }
        
        // ====================================================================
        // PATTERN 2: Map Types
        // ====================================================================
        if (isMapType(className)) {
            #if debug_ast_builder
            trace('[ConstructorBuilder] ✓ Detected Map type, generating empty map');
            #end
            return EMap([]);
        }
        
        // ====================================================================
        // PATTERN 3: Regular Classes
        // ====================================================================
        var hasInstanceMethods = hasInstanceMethodsCheck(classType);
        var hasConstructor = classType.constructor != null;
        
        #if debug_ast_builder
        trace('[ConstructorBuilder] Class analysis:');
        trace('[ConstructorBuilder]   Has instance methods: $hasInstanceMethods');
        trace('[ConstructorBuilder]   Has constructor: $hasConstructor');
        #end
        
        if (hasInstanceMethods || hasConstructor) {
            // Call the module's new function: ModuleName.new(args)
            #if debug_ast_builder
            trace('[ConstructorBuilder] Generating Module.new() call');
            #end
            var moduleRef = makeAST(EVar(className));
            return ECall(moduleRef, "new", args);
        } else {
            // Simple data class - create as struct
            #if debug_ast_builder
            trace('[ConstructorBuilder] Generating struct literal for data class');
            #end
            return EStruct(className, []);
        }
    }
    
    /**
     * Build Ecto schema struct literal
     * 
     * WHY: Ecto schemas use struct literals, not constructor functions
     * WHAT: Extract module name from metadata and generate struct
     * HOW: Check @:native metadata for custom module name
     */
    static function buildEctoSchema(classType: ClassType, defaultName: String): ElixirASTDef {
        // Get the full module name from @:native or use className
        var moduleName = if (classType.meta.has("native")) {
            var nativeMeta = classType.meta.extract("native");
            if (nativeMeta.length > 0 && nativeMeta[0].params != null && nativeMeta[0].params.length > 0) {
                switch(nativeMeta[0].params[0].expr) {
                    case EConst(CString(s, _)):
                        s;
                    default:
                        defaultName;
                }
            } else {
                defaultName;
            }
        } else {
            defaultName;
        };
        
        // Generate struct literal: %ModuleName{}
        return EStruct(moduleName, []);
    }
    
    /**
     * Check if class name represents a Map type
     * 
     * WHY: Map types should generate %{}, not structs
     * WHAT: Check for common Map class names
     * HOW: String matching on class name
     */
    static function isMapType(className: String): Bool {
        return className == "StringMap" || 
               className == "Map" || 
               className == "IntMap" ||
               StringTools.endsWith(className, "Map");
    }
    
    /**
     * Check if class has instance methods
     * 
     * WHY: Classes with methods need Module.new(), data classes use structs
     * WHAT: Analyze class fields for non-static methods
     * HOW: Iterate fields and check if they're methods and not static
     */
    static function hasInstanceMethodsCheck(classType: ClassType): Bool {
        for (field in classType.fields.get()) {
            // Instance methods are FMethod that are not in the statics list
            if (field.kind.match(FMethod(_))) {
                // Check if this field is NOT in the statics array
                var isStatic = false;
                for (staticField in classType.statics.get()) {
                    if (staticField.name == field.name) {
                        isStatic = true;
                        break;
                    }
                }
                if (!isStatic) {
                    return true;
                }
            }
        }
        return false;
    }
}

#end