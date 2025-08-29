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
        
        // Option<T> configuration - using idiomatic Elixir patterns
        var optionConstructors = new Map<String, ADTConstructorConfig>();
        optionConstructors.set("some", {
            elixirPattern: "{:ok, %s}",
            arity: 1,
            isAtom: false
        });
        optionConstructors.set("none", {
            elixirPattern: ":error",
            arity: 0,
            isAtom: true
        });
        
        adtConfigs.set("haxe.ds.Option", {
            moduleName: "haxe.ds.Option",
            typeName: "Option",
            constructors: optionConstructors
        });
        
        // OTP ChildSpecFormat configuration
        // This handles enums that represent OTP child specifications
        var childSpecConstructors = new Map<String, ADTConstructorConfig>();
        
        // ModuleRef(module) → module atom
        childSpecConstructors.set("moduleref", {
            elixirPattern: "%s",  // Just the module atom
            arity: 1,
            isAtom: false
        });
        
        // ModuleWithArgs(module, args) → {module, args}
        childSpecConstructors.set("modulewithargs", {
            elixirPattern: "{%s, %s}",  // {Module, args}
            arity: 2,
            isAtom: false
        });
        
        // ModuleWithConfig(module, config) → {module, config}
        childSpecConstructors.set("modulewithconfig", {
            elixirPattern: "{%s, %s}",  // {Module, [config]}
            arity: 2,
            isAtom: false
        });
        
        // Note: We don't add this to adtConfigs by module name since
        // we want to detect it by pattern, not hardcode the type
    }
    
    /**
     * Check if an enum type is a known algebraic data type
     * @param enumType The enum type to check
     * @return True if this is a known ADT (Result, Option, etc.)
     */
    public static function isADTType(enumType: EnumType): Bool {
        initConfigs();
        
        // Only standard library ADTs use idiomatic patterns
        if (adtConfigs.exists(enumType.module) && 
            adtConfigs.get(enumType.module).typeName == enumType.name) {
            return true;
        }
        
        // Check if user-defined enum has explicit annotation for idiomatic patterns
        return hasIdiomaticAnnotation(enumType);
    }
    
    /**
     * Detect which ADT configuration to use based on enum structure
     * @param enumType The annotated enum type to analyze
     * @return ADT configuration matching the enum's structure
     */
    private static function detectADTConfigByStructure(enumType: EnumType): Null<ADTConfig> {
        initConfigs();
        
        // Collect constructor names (lowercased for comparison)
        var constructorNames = [];
        for (field in enumType.constructs) {
            constructorNames.push(field.name.toLowerCase());
        }
        
        // Check for OTP child spec patterns first
        if (detectOTPChildSpecPattern(enumType)) {
            // Return a dynamically created configuration for OTP patterns
            return createOTPChildSpecConfig(enumType);
        }
        
        // Check for Result-like patterns (ok/error, success/failure, etc.)
        var hasOkError = constructorNames.contains("ok") && constructorNames.contains("error");
        var hasSuccessFailure = constructorNames.contains("success") && constructorNames.contains("failure");
        
        if (hasOkError || hasSuccessFailure) {
            return adtConfigs.get("haxe.functional.Result");
        }
        
        // Check for Option-like patterns (some/none, just/nothing, etc.)
        var hasSomeNone = constructorNames.contains("some") && constructorNames.contains("none");
        var hasJustNothing = constructorNames.contains("just") && constructorNames.contains("nothing");
        
        if (hasSomeNone || hasJustNothing) {
            return adtConfigs.get("haxe.ds.Option");
        }
        
        // Default to Option patterns if we can't determine
        // This covers cases where the constructor names don't match common patterns
        return adtConfigs.get("haxe.ds.Option");
    }
    
    /**
     * Detect if an enum represents OTP child specification patterns
     * @param enumType The enum type to check
     * @return True if this looks like an OTP child spec enum
     */
    private static function detectOTPChildSpecPattern(enumType: EnumType): Bool {
        var constructorNames = [];
        for (field in enumType.constructs) {
            constructorNames.push(field.name.toLowerCase());
        }
        
        // Check for OTP child spec constructor patterns
        var hasModulePatterns = 
            constructorNames.contains("moduleref") || 
            constructorNames.contains("modulewithargs") ||
            constructorNames.contains("modulewithconfig") ||
            constructorNames.contains("fullspec");
        
        // Check for restart strategy patterns
        var hasRestartPatterns = 
            constructorNames.contains("permanent") ||
            constructorNames.contains("temporary") ||
            constructorNames.contains("transient");
            
        // Check for supervisor strategy patterns
        var hasSupervisorPatterns =
            constructorNames.contains("oneforone") ||
            constructorNames.contains("oneforall") ||
            constructorNames.contains("restforone");
            
        return hasModulePatterns || hasRestartPatterns || hasSupervisorPatterns;
    }
    
    /**
     * Create an OTP child spec configuration dynamically
     * @param enumType The enum type to create configuration for
     * @return ADT configuration for OTP child specs
     */
    private static function createOTPChildSpecConfig(enumType: EnumType): ADTConfig {
        var constructors = new Map<String, ADTConstructorConfig>();
        
        // Map each constructor to its appropriate pattern
        for (field in enumType.constructs) {
            var fieldName = field.name.toLowerCase();
            
            switch(fieldName) {
                // Child spec patterns
                case "moduleref":
                    constructors.set(fieldName, {
                        elixirPattern: "%s",
                        arity: 1,
                        isAtom: false
                    });
                case "modulewithargs":
                    constructors.set(fieldName, {
                        elixirPattern: "{%s, %s}",
                        arity: 2,
                        isAtom: false
                    });
                case "modulewithconfig":
                    constructors.set(fieldName, {
                        elixirPattern: "{%s, %s}",
                        arity: 2,
                        isAtom: false
                    });
                    
                // Restart strategies
                case "permanent" | "temporary" | "transient":
                    constructors.set(fieldName, {
                        elixirPattern: ':${fieldName}',
                        arity: 0,
                        isAtom: true
                    });
                    
                // Supervisor strategies
                case "oneforone":
                    constructors.set(fieldName, {
                        elixirPattern: ":one_for_one",
                        arity: 0,
                        isAtom: true
                    });
                case "oneforall":
                    constructors.set(fieldName, {
                        elixirPattern: ":one_for_all",
                        arity: 0,
                        isAtom: true
                    });
                case "restforone":
                    constructors.set(fieldName, {
                        elixirPattern: ":rest_for_one",
                        arity: 0,
                        isAtom: true
                    });
                    
                // Default fallback for unknown constructors
                case _:
                    // Infer based on field type
                    if (field.type != null) {
                        switch(field.type) {
                            case TFun(args, _):
                                var arity = args.length;
                                if (arity == 0) {
                                    constructors.set(fieldName, {
                                        elixirPattern: ':${fieldName}',
                                        arity: 0,
                                        isAtom: true
                                    });
                                } else {
                                    // Create tuple pattern with right number of %s placeholders
                                    var placeholders = [for (i in 0...arity) "%s"];
                                    constructors.set(fieldName, {
                                        elixirPattern: '{:${fieldName}, ${placeholders.join(", ")}}',
                                        arity: arity,
                                        isAtom: false
                                    });
                                }
                            case _:
                                // Simple atom
                                constructors.set(fieldName, {
                                    elixirPattern: ':${fieldName}',
                                    arity: 0,
                                    isAtom: true
                                });
                        }
                    }
            }
        }
        
        return {
            moduleName: enumType.module,
            typeName: enumType.name,
            constructors: constructors
        };
    }
    
    /**
     * Check if an enum has explicit annotation for idiomatic patterns
     * @param enumType The enum type to check
     * @return True if the enum has @:elixirIdiomatic annotation
     */
    private static function hasIdiomaticAnnotation(enumType: EnumType): Bool {
        #if macro
        // Check for @:elixirIdiomatic metadata
        for (meta in enumType.meta.get()) {
            if (meta.name == ":elixirIdiomatic") {
                trace("DETECTED @:elixirIdiomatic annotation on " + enumType.name + " in " + enumType.module);
                return true;
            }
        }
        #end
        return false;
    }
    
    /**
     * Get the ADT configuration for an enum type
     * @param enumType The enum type
     * @return ADT configuration or null if not a known ADT
     */
    public static function getADTConfig(enumType: EnumType): Null<ADTConfig> {
        initConfigs();
        
        // Check for standard library ADT
        var config = adtConfigs.get(enumType.module);
        if (config != null && config.typeName == enumType.name) {
            return config;
        }
        
        // Check for user-defined enum with idiomatic annotation
        if (hasIdiomaticAnnotation(enumType)) {
            // Inspect structure to determine Result vs Option patterns
            return detectADTConfigByStructure(enumType);
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