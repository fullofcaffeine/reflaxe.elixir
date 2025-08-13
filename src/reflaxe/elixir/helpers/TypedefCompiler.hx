package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import reflaxe.helpers.SyntaxHelper;

using StringTools;
using reflaxe.helpers.NullableMetaAccessHelper;
using reflaxe.helpers.TypeHelper;
using reflaxe.helpers.NameMetaHelper;

/**
 * Compiler helper for Haxe typedef compilation to Elixir @type specifications.
 * 
 * Handles typedef→@type transformation including:
 * - Simple type aliases (typedef UserId = Int)
 * - Structural types (typedef User = {name: String, age: Int})
 * - Function types (typedef Handler = (String) -> Void)
 * - Generic types (typedef Result<T> = {ok: T})
 * 
 * Follows established ElixirCompiler helper delegation pattern.
 */
class TypedefCompiler {
    
    /**
     * Reference to the main compiler for expression compilation
     */
    private var compiler: Dynamic;
    
    /**
     * Constructor
     */
    public function new() {}
    
    /**
     * Sets the compiler reference for expression compilation
     */
    public function setCompiler(c: Dynamic): Void {
        compiler = c;
    }
    
    /**
     * Main entry point for typedef compilation
     * Compiles a Haxe typedef to Elixir @type specification
     */
    public static function compileTypedef(defType: DefType): String {
        var output = new StringBuf();
        
        // Extract typedef name and convert to snake_case
        var typedefName = convertToSnakeCase(defType.name);
        
        // Add documentation if available
        if (defType.doc != null && defType.doc.length > 0) {
            output.add('@typedoc """');
            output.add('\n');
            output.add(defType.doc);
            output.add('\n');
            output.add('"""');
            output.add('\n');
        }
        
        // Start type declaration
        output.add('@type ');
        output.add(typedefName);
        
        // Handle type parameters for generic types
        if (defType.params != null && defType.params.length > 0) {
            output.add('(');
            var paramNames = [];
            for (param in defType.params) {
                paramNames.push(param.name.toLowerCase());
            }
            output.add(paramNames.join(', '));
            output.add(')');
        }
        
        output.add(' :: ');
        
        // Compile the actual type based on its structure
        var typeSpec = compileType(defType.type, defType.params);
        output.add(typeSpec);
        
        return output.toString();
    }
    
    /**
     * Compiles a Type to its Elixir typespec representation
     */
    public static function compileType(type: Type, ?typeParams: Array<TypeParameter>): String {
        return switch(type) {
            case TAnonymous(a):
                // Anonymous structure - compile to map type
                compileAnonymousType(a.get(), typeParams);
                
            case TInst(t, params):
                var className = t.get().name;
                // Check if this is a type parameter reference
                if (typeParams != null) {
                    for (param in typeParams) {
                        if (param.name == className) {
                            return param.name.toLowerCase();
                        }
                    }
                }
                // Otherwise compile as regular type instance
                compileInstType(t.get(), params, typeParams);
                
            case TAbstract(a, params):
                // Abstract type - map to Elixir equivalent
                compileAbstractType(a.get(), params, typeParams);
                
            case TFun(args, ret):
                // Function type - compile to function spec
                compileFunctionType(args, ret, typeParams);
                
            case TDynamic(_):
                // Dynamic type - maps to any()
                "any()";
                
            case TType(t, params):
                // Another typedef reference
                var refName = convertToSnakeCase(t.get().name);
                if (params != null && params.length > 0) {
                    var paramSpecs = params.map(p -> compileType(p, typeParams));
                    refName + '(' + paramSpecs.join(', ') + ')';
                } else {
                    refName + '()';
                }
                
            default:
                // Fallback for unhandled types
                "any()";
        }
    }
    
    /**
     * Compiles anonymous structure to Elixir map type
     */
    private static function compileAnonymousType(anon: AnonType, ?typeParams: Array<TypeParameter>): String {
        var fields = anon.fields;
        
        if (fields.length == 0) {
            return "%{}";
        }
        
        var output = new StringBuf();
        output.add('%{\n');
        
        var fieldSpecs = [];
        for (field in fields) {
            var fieldName = convertToSnakeCase(field.name);
            var fieldType = compileType(field.type, typeParams);
            
            // Check if field is optional
            var isOptional = field.meta.has(":optional") || 
                            isNullableType(field.type);
            
            if (isOptional) {
                fieldSpecs.push('  optional(:' + fieldName + ') => ' + fieldType);
            } else {
                fieldSpecs.push('  ' + fieldName + ': ' + fieldType);
            }
        }
        
        output.add(fieldSpecs.join(',\n'));
        output.add('\n}');
        
        return output.toString();
    }
    
    /**
     * Check if a type is nullable (Null<T>)
     */
    private static function isNullableType(type: Type): Bool {
        return switch(type) {
            case TAbstract(a, _) if (a.get().name == "Null"): true;
            default: false;
        }
    }
    
    /**
     * Compiles type instance to Elixir type
     */
    private static function compileInstType(classType: ClassType, params: Array<Type>, ?typeParams: Array<TypeParameter>): String {
        // Check if this is a type parameter reference
        if (typeParams != null) {
            for (param in typeParams) {
                if (param.name == classType.name) {
                    return param.name.toLowerCase();
                }
            }
        }
        
        return switch(classType.name) {
            case "String": "String.t()";
            case "Array": 
                if (params != null && params.length > 0) {
                    "list(" + compileType(params[0], typeParams) + ")";
                } else {
                    "list(any())";
                }
            case "Map":
                if (params != null && params.length >= 2) {
                    "%{optional(" + compileType(params[0], typeParams) + ") => " + compileType(params[1], typeParams) + "}";
                } else {
                    "map()";
                }
            default:
                // Custom class type - use module name
                var moduleName = classType.name;
                moduleName + ".t()";
        }
    }
    
    /**
     * Compiles abstract type to Elixir type
     */
    private static function compileAbstractType(abstractType: AbstractType, params: Array<Type>, ?typeParams: Array<TypeParameter>): String {
        return switch(abstractType.name) {
            case "Int": "integer()";
            case "Float": "float()";
            case "Bool": "boolean()";
            case "Void": ":ok";
            case "Null":
                if (params != null && params.length > 0) {
                    compileType(params[0], typeParams) + " | nil";
                } else {
                    "nil";
                }
            case "Dynamic": "any()";
            default: "any()";
        }
    }
    
    /**
     * Compiles function type to Elixir function spec
     */
    private static function compileFunctionType(args: Array<{name: String, opt: Bool, t: Type}>, ret: Type, ?typeParams: Array<TypeParameter>): String {
        var output = new StringBuf();
        output.add('(');
        
        if (args.length == 0) {
            output.add('() -> ');
        } else {
            var argTypes = [];
            for (arg in args) {
                argTypes.push(compileType(arg.t, typeParams));
            }
            output.add(argTypes.join(', '));
            output.add(' -> ');
        }
        
        output.add(compileType(ret, typeParams));
        output.add(')');
        
        return output.toString();
    }
    
    /**
     * Converts CamelCase to snake_case
     */
    private static function convertToSnakeCase(name: String): String {
        // Handle special cases
        if (name == name.toUpperCase()) {
            return name.toLowerCase();
        }
        
        // Convert CamelCase to snake_case
        var result = "";
        for (i in 0...name.length) {
            var char = name.charAt(i);
            if (i > 0 && char == char.toUpperCase() && char != "_") {
                result += "_";
            }
            result += char.toLowerCase();
        }
        
        return result;
    }
}

#end