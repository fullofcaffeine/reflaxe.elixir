package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Type.EnumType;
import haxe.macro.Type.EnumField;
import haxe.macro.Type.TypedExpr;

using StringTools;

/**
 * Configuration for an algebraic data type constructor
 */
typedef ADTConstructorConfig = {
    /** Elixir pattern template, use %s for arguments */
    elixirPattern: String,
    /** Number of arguments this constructor expects */
    arity: Int,
    /** Whether this compiles to a simple atom (no tuple wrapper) */
    isAtom: Bool
}

/**
 * Configuration for an algebraic data type
 */
typedef ADTConfig = {
    /** Haxe module name */
    moduleName: String,
    /** Haxe type name */
    typeName: String,
    /** Constructor configurations */
    constructors: Map<String, ADTConstructorConfig>
}

/**
 * AlgebraicDataTypeCompiler - Unified handler for Result, Option, and other algebraic data types
 * 
 * This class eliminates duplicate logic between Result and Option compilation by providing
 * a single, configurable handler for all BEAM-friendly algebraic data types.
 */
class AlgebraicDataTypeCompiler {
    
    /** Cached configurations for known ADT types */
    private static var adtConfigs: Map<String, ADTConfig> = null;
    
    /**
     * Initialize ADT configurations if not already done
     */
    private static function initConfigs(): Void {
        if (adtConfigs != null) return;
        
        adtConfigs = new Map<String, ADTConfig>();
        
        // Result<T,E> configuration
        var resultConstructors = new Map<String, ADTConstructorConfig>();
        resultConstructors.set("ok", {
            elixirPattern: "{:ok, %s}",
            arity: 1,
            isAtom: false
        });
        resultConstructors.set("error", {
            elixirPattern: "{:error, %s}",
            arity: 1,
            isAtom: false
        });
        
        adtConfigs.set("haxe.functional.Result", {
            moduleName: "haxe.functional.Result",
            typeName: "Result",
            constructors: resultConstructors
        });
        
        // Option<T> configuration
        var optionConstructors = new Map<String, ADTConstructorConfig>();
        optionConstructors.set("some", {
            elixirPattern: "{:some, %s}",
            arity: 1,
            isAtom: false
        });
        optionConstructors.set("none", {
            elixirPattern: ":none",
            arity: 0,
            isAtom: true
        });
        
        adtConfigs.set("haxe.ds.Option", {
            moduleName: "haxe.ds.Option",
            typeName: "Option",
            constructors: optionConstructors
        });
    }
    
    /**
     * Check if an enum type is a known algebraic data type
     * @param enumType The enum type to check
     * @return True if this is a known ADT (Result, Option, etc.)
     */
    public static function isADTType(enumType: EnumType): Bool {
        initConfigs();
        return adtConfigs.exists(enumType.module) && 
               adtConfigs.get(enumType.module).typeName == enumType.name;
    }
    
    /**
     * Get the ADT configuration for an enum type
     * @param enumType The enum type
     * @return ADT configuration or null if not a known ADT
     */
    public static function getADTConfig(enumType: EnumType): Null<ADTConfig> {
        initConfigs();
        var config = adtConfigs.get(enumType.module);
        if (config != null && config.typeName == enumType.name) {
            return config;
        }
        return null;
    }
    
    /**
     * Compile an ADT constructor to proper Elixir pattern
     * @param enumType The enum type
     * @param enumField The enum constructor field
     * @param args Arguments to the constructor
     * @param compileExpr Function to compile individual expressions
     * @return Compiled Elixir pattern
     */
    public static function compileADTPattern(
        enumType: EnumType, 
        enumField: EnumField, 
        args: Array<TypedExpr>,
        compileExpr: TypedExpr -> Null<String>
    ): Null<String> {
        var config = getADTConfig(enumType);
        if (config == null) return null;
        
        var fieldName = enumField.name.toLowerCase();
        var constructorConfig = config.constructors.get(fieldName);
        if (constructorConfig == null) return null;
        
        // Handle atoms (no arguments)
        if (constructorConfig.isAtom) {
            return constructorConfig.elixirPattern;
        }
        
        // Handle constructors with arguments
        if (args.length == 0) {
            // Constructor called without arguments - return bare atom
            var atomName = fieldName;
            return ':${atomName}';
        } else if (args.length == 1) {
            // Single argument - use the pattern template
            var compiledArg = compileExpr(args[0]);
            if (compiledArg == null) compiledArg = "nil";
            return constructorConfig.elixirPattern.replace("%s", compiledArg);
        } else {
            // Multiple arguments - wrap in tuple
            var compiledArgs = args.map(arg -> {
                var compiled = compileExpr(arg);
                return compiled != null ? compiled : "nil";
            });
            var argTuple = '{${compiledArgs.join(", ")}}';
            return constructorConfig.elixirPattern.replace("%s", argTuple);
        }
    }
    
    /**
     * Compile an ADT field access (without arguments)
     * @param enumType The enum type
     * @param enumField The enum constructor field
     * @return Compiled Elixir pattern for field access
     */
    public static function compileADTFieldAccess(enumType: EnumType, enumField: EnumField): Null<String> {
        var config = getADTConfig(enumType);
        if (config == null) return null;
        
        var fieldName = enumField.name.toLowerCase();
        var constructorConfig = config.constructors.get(fieldName);
        if (constructorConfig == null) return null;
        
        if (constructorConfig.isAtom) {
            // Atoms like :none are returned as-is
            return constructorConfig.elixirPattern;
        } else if (constructorConfig.arity == 1) {
            // Constructors that take arguments become partial functions
            return 'fn value -> ${constructorConfig.elixirPattern.replace("%s", "value")} end';
        } else {
            // Zero-arity constructors become bare atoms
            return ':${fieldName}';
        }
    }
    
    /**
     * Compile an ADT constructor call for method-style invocation
     * @param enumType The enum type  
     * @param methodName The method name (constructor name)
     * @param args The arguments
     * @param compileExpr Function to compile individual expressions
     * @return Compiled Elixir pattern or null if not applicable
     */
    public static function compileADTMethodCall(
        enumType: EnumType,
        methodName: String,
        args: Array<TypedExpr>,
        compileExpr: TypedExpr -> Null<String>
    ): Null<String> {
        var config = getADTConfig(enumType);
        if (config == null) return null;
        
        var fieldName = methodName.toLowerCase();
        var constructorConfig = config.constructors.get(fieldName);
        if (constructorConfig == null) return null;
        
        // Handle atoms
        if (constructorConfig.isAtom) {
            return constructorConfig.elixirPattern;
        }
        
        // Handle constructors with arguments
        if (args.length == 0) {
            return ':${fieldName}';
        } else if (args.length == 1) {
            var compiledArg = compileExpr(args[0]);
            if (compiledArg == null) compiledArg = "nil";
            return constructorConfig.elixirPattern.replace("%s", compiledArg);
        } else {
            var compiledArgs = args.map(arg -> {
                var compiled = compileExpr(arg);
                return compiled != null ? compiled : "nil";
            });
            var argTuple = '{${compiledArgs.join(", ")}}';
            return constructorConfig.elixirPattern.replace("%s", argTuple);
        }
    }
    
    /**
     * Check if a type name refers to a known ADT type
     * @param typeName The type name (e.g., "Result", "Option")
     * @return True if this is a known ADT type name
     */
    public static function isADTTypeName(typeName: String): Bool {
        initConfigs();
        for (config in adtConfigs) {
            if (config.typeName == typeName) {
                return true;
            }
        }
        return false;
    }
    
    /**
     * Get ADT configuration by type name
     * @param typeName The type name (e.g., "Result", "Option")
     * @return ADT configuration or null if not found
     */
    public static function getADTConfigByTypeName(typeName: String): Null<ADTConfig> {
        initConfigs();
        for (config in adtConfigs) {
            if (config.typeName == typeName) {
                return config;
            }
        }
        return null;
    }
}

#end