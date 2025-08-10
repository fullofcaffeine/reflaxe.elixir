package reflaxe.elixir;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.helpers.NamingHelper;
import reflaxe.elixir.helpers.FormatHelper;

using StringTools;

/**
 * Type mapping context for more sophisticated type resolution
 */
typedef TypeContext = {
    ?isNullable: Bool,
    ?isGeneric: Bool,
    ?genericBounds: Array<String>,
    ?modulePath: String,
    ?isPhoenix: Bool
}

/**
 * ElixirTyper - Type mapping and typespec generation
 * Maps Haxe types to Elixir types and generates @spec/@type annotations
 * Provides comprehensive type system integration for Phoenix applications
 */
class ElixirTyper {
    
    /**
     * Cache for complex type mappings to improve performance
     */
    private var typeCache: Map<String, String> = new Map();
    
    /**
     * Constructor
     */
    public function new() {}
    
    /**
     * Phoenix-specific type mappings
     */
    private static var phoenixTypes: Map<String, String> = [
        "Conn" => "Plug.Conn.t()",
        "Socket" => "Phoenix.Socket.t()",
        "LiveView" => "Phoenix.LiveView.t()",
        "Channel" => "Phoenix.Channel.t()",
        "Endpoint" => "Phoenix.Endpoint.t()"
    ];
    
    /**
     * Ecto-specific type mappings
     */
    private static var ectoTypes: Map<String, String> = [
        "Schema" => "Ecto.Schema.t()",
        "Changeset" => "Ecto.Changeset.t()",
        "Query" => "Ecto.Query.t()",
        "Repo" => "Ecto.Repo.t()"
    ];
    
    /**
     * Compile a Haxe type to its Elixir equivalent with context
     * @param haxeType The Haxe type string (e.g., "String", "Array<Int>", "Null<String>")
     * @param context Optional type context for enhanced resolution
     * @return Elixir type string (e.g., "String.t()", "list(integer())", "String.t() | nil")
     */
    public function compileType(haxeType: String, ?context: TypeContext): String {
        if (haxeType == null || haxeType.length == 0) {
            return "term()"; // More specific than any() per PRD requirements
        }
        
        // Check cache first for performance
        if (typeCache.exists(haxeType)) {
            var cached = typeCache.get(haxeType);
            return cached != null ? cached : "any()";
        }
        
        var result = compileTypeInternal(haxeType, context);
        
        // Cache the result for future use
        typeCache.set(haxeType, result);
        
        return result;
    }
    
    /**
     * Internal type compilation with full logic
     */
    private function compileTypeInternal(haxeType: String, ?context: TypeContext): String {
        // Handle nullable types first: Null<T> → t | nil
        if (haxeType.indexOf("Null<") == 0) {
            var innerType = extractGenericType(haxeType);
            var innerElixirType = compileType(innerType, context);
            return '${innerElixirType} | nil';
        }
        
        // Handle array types: Array<T> → list(t)  
        if (haxeType.indexOf("Array<") == 0) {
            var elementType = extractGenericType(haxeType);
            var elementElixirType = compileType(elementType, context);
            return 'list(${elementElixirType})';
        }
        
        // Handle map types: Map<K,V> → %{k => v}
        if (haxeType.indexOf("Map<") == 0) {
            var typeParams = extractMapTypes(haxeType);
            var keyType = compileType(typeParams.key, context);
            var valueType = compileType(typeParams.value, context);
            return '%{${keyType} => ${valueType}}';
        }
        
        // Handle Phoenix-specific types
        if (phoenixTypes.exists(haxeType)) {
            var phoenixType = phoenixTypes.get(haxeType);
            return phoenixType != null ? phoenixType : "any()";
        }
        
        // Handle Ecto-specific types
        if (ectoTypes.exists(haxeType)) {
            var ectoType = ectoTypes.get(haxeType);
            return ectoType != null ? ectoType : "any()";
        }
        
        // Handle basic primitive types
        return switch (haxeType) {
            case "Int": "integer()";
            case "Float": "float()";
            case "Bool": "boolean()";
            case "String": "String.t()";
            case "Void": "nil";
            case "Dynamic": "term()"; // Only at interop boundaries - more specific than any()
            case _: handleComplexType(haxeType, context);
        }
    }
    
    /**
     * Generate @spec annotation for a function with enhanced formatting
     * @param funcName Haxe function name
     * @param paramTypes Array of parameter type strings
     * @param returnType Return type string
     * @param context Optional type context
     * @param indentLevel Indentation level for formatting
     * @return Generated @spec annotation
     */
    public function generateFunctionSpec(funcName: String, paramTypes: Array<String>, returnType: String, 
                                       ?context: TypeContext, indentLevel: Int = 1): String {
        var elixirFuncName = NamingHelper.getElixirFunctionName(funcName);
        var elixirParamTypes = paramTypes.map(type -> compileType(type, context));
        var elixirReturnType = compileType(returnType, context);
        
        // Use FormatHelper for proper formatting
        return FormatHelper.formatSpec(elixirFuncName, elixirParamTypes, elixirReturnType, indentLevel);
    }
    
    /**
     * Generate multiple @spec annotations for function overloads
     * @param funcName Function name
     * @param overloads Array of parameter/return type combinations
     * @param context Optional type context
     * @param indentLevel Indentation level
     * @return Generated @spec annotations
     */
    public function generateFunctionOverloadSpecs(funcName: String, 
                                                overloads: Array<{params: Array<String>, returns: String}>,
                                                ?context: TypeContext, indentLevel: Int = 1): String {
        var specs = [];
        for (signature in overloads) {
            specs.push(generateFunctionSpec(funcName, signature.params, signature.returns, context, indentLevel));
        }
        return specs.join("\n");
    }
    
    /**
     * Generate @type definition for a struct/class with enhanced formatting
     * @param typeName The type name
     * @param fields Array of field definitions
     * @param context Optional type context
     * @param indentLevel Base indentation level
     * @return Generated @type definition
     */
    public function generateTypeDefinition(typeName: String, fields: Array<{name: String, type: String}>, 
                                         ?context: TypeContext, indentLevel: Int = 1): String {
        var baseIndent = FormatHelper.indent("", indentLevel);
        var fieldIndent = FormatHelper.indent("", indentLevel + 1);
        
        var result = baseIndent + "@type t() :: %__MODULE__{\n";
        
        for (i in 0...fields.length) {
            var field = fields[i];
            var fieldName = NamingHelper.toSnakeCase(field.name);
            var fieldType = compileType(field.type, context);
            var comma = (i < fields.length - 1) ? "," : "";
            result += fieldIndent + '${fieldName}: ${fieldType}${comma}\n';
        }
        
        result += baseIndent + "}";
        return result;
    }
    
    /**
     * Generate union type definition
     * @param typeName Type name
     * @param variants Array of variant types
     * @param context Optional type context
     * @param indentLevel Base indentation level
     * @return Generated union @type definition
     */
    public function generateUnionTypeDefinition(typeName: String, variants: Array<String>, 
                                               ?context: TypeContext, indentLevel: Int = 1): String {
        var baseIndent = FormatHelper.indent("", indentLevel);
        var variantIndent = FormatHelper.indent("", indentLevel + 1);
        
        var result = baseIndent + "@type t() ::\n";
        
        for (i in 0...variants.length) {
            var variant = variants[i];
            var elixirType = compileType(variant, context);
            var separator = (i < variants.length - 1) ? " |" : "";
            result += variantIndent + '${elixirType}${separator}\n';
        }
        
        return result;
    }
    
    /**
     * Generate @opaque type definition for hidden implementation details
     * @param typeName Type name
     * @param baseType Base type to wrap
     * @param context Optional type context
     * @param indentLevel Base indentation level
     * @return Generated @opaque definition
     */
    public function generateOpaqueTypeDefinition(typeName: String, baseType: String,
                                                ?context: TypeContext, indentLevel: Int = 1): String {
        var baseIndent = FormatHelper.indent("", indentLevel);
        var elixirBaseType = compileType(baseType, context);
        return baseIndent + '@opaque t() :: ${elixirBaseType}';
    }
    
    /**
     * Check if a type string is a valid Elixir type
     * @param typeStr The type string to validate
     * @return True if valid Elixir type
     */
    public function isValidElixirType(typeStr: String): Bool {
        if (typeStr == null || typeStr.length == 0) return false;
        
        // Basic validation - check for common Elixir type patterns
        var validPatterns = [
            "integer()", "float()", "boolean()", "String.t()", "nil",
            "list(", "%{", " | ", "term()", "any()", "atom()"
        ];
        
        for (pattern in validPatterns) {
            if (typeStr.indexOf(pattern) >= 0) return true;
        }
        
        return false;
    }
    
    /**
     * Check if a type string is a Haxe type
     * @param typeStr The type string to check
     * @return True if Haxe type
     */
    public function isHaxeType(typeStr: String): Bool {
        if (typeStr == null || typeStr.length == 0) return false;
        
        // Check for Haxe-specific patterns
        var haxePatterns = ["Array<", "Map<", "Null<", "Int", "Float", "Bool", "String", "Void", "Dynamic"];
        
        for (pattern in haxePatterns) {
            if (typeStr.indexOf(pattern) >= 0) return true;
        }
        
        // If it contains Elixir-specific syntax, it's not a Haxe type
        if (typeStr.indexOf("String.t()") >= 0) return false;
        if (typeStr.indexOf("integer()") >= 0) return false;
        
        return true;
    }
    
    /**
     * Extract the inner type from a generic type like Array<T> or Null<T>
     * @param genericType The generic type string
     * @return The inner type
     */
    private function extractGenericType(genericType: String): String {
        var startIndex = genericType.indexOf("<") + 1;
        var endIndex = genericType.lastIndexOf(">");
        
        if (startIndex > 0 && endIndex > startIndex) {
            return genericType.substring(startIndex, endIndex);
        }
        
        return "any()"; // Fallback
    }
    
    /**
     * Extract key and value types from Map<K,V>
     * @param mapType The map type string
     * @return Object with key and value types
     */
    private function extractMapTypes(mapType: String): {key: String, value: String} {
        var startIndex = mapType.indexOf("<") + 1;
        var endIndex = mapType.lastIndexOf(">");
        
        if (startIndex > 0 && endIndex > startIndex) {
            var typeParams = mapType.substring(startIndex, endIndex);
            var commaIndex = typeParams.indexOf(",");
            
            if (commaIndex > 0) {
                var keyType = typeParams.substring(0, commaIndex).trim();
                var valueType = typeParams.substring(commaIndex + 1).trim();
                return {key: keyType, value: valueType};
            }
        }
        
        return {key: "any()", value: "any()"}; // Fallback
    }
    
    /**
     * Handle complex types that don't match basic patterns
     * @param haxeType The complex Haxe type
     * @param context Optional type context
     * @return Elixir type equivalent
     */
    private function handleComplexType(haxeType: String, ?context: TypeContext): String {
        // Handle function types: (String, Int) -> String
        if (haxeType.indexOf("->") > 0) {
            return compileFunctionType(haxeType, context);
        }
        
        // Handle tuple types: {String, Int, Bool}
        if (haxeType.indexOf("{") == 0 && haxeType.indexOf("}") > 0) {
            return compileTupleType(haxeType, context);
        }
        
        // Handle generic types: Either<String, Int>
        if (haxeType.indexOf("<") > 0 && !isBuiltinGeneric(haxeType)) {
            return compileGenericType(haxeType, context);
        }
        
        // Handle custom types - convert to module reference
        if (~/^[A-Z]/.match(haxeType)) {
            var moduleName = NamingHelper.getElixirModuleName(haxeType);
            return '${moduleName}.t()';
        }
        
        // Handle lowercase custom types (might be atoms or variables)
        if (~/^[a-z]/.match(haxeType)) {
            return ':${haxeType}'; // Convert to atom
        }
        
        // Fallback - avoid any() per PRD requirements, use more specific type
        return "term()"; // More specific than any() for unknown types
    }
    
    /**
     * Compile function type signatures
     * @param funcType Function type string like "(String, Int) -> String"
     * @param context Type context
     * @return Elixir function type
     */
    private function compileFunctionType(funcType: String, ?context: TypeContext): String {
        var arrowIndex = funcType.indexOf("->");
        if (arrowIndex < 0) return "function()";
        
        var paramsPart = funcType.substring(0, arrowIndex).trim();
        var returnPart = funcType.substring(arrowIndex + 2).trim();
        
        // Extract parameters from (String, Int) format
        if (paramsPart.indexOf("(") == 0) {
            paramsPart = paramsPart.substring(1, paramsPart.length - 1);
        }
        
        var paramTypes = paramsPart.split(",").map(p -> compileType(p.trim(), context));
        var returnType = compileType(returnPart, context);
        
        var paramStr = paramTypes.join(", ");
        return '(${paramStr} -> ${returnType})';
    }
    
    /**
     * Compile tuple types
     * @param tupleType Tuple type string like "{String, Int, Bool}"
     * @param context Type context
     * @return Elixir tuple type
     */
    private function compileTupleType(tupleType: String, ?context: TypeContext): String {
        var inner = tupleType.substring(1, tupleType.length - 1);
        var elementTypes = inner.split(",").map(t -> compileType(t.trim(), context));
        return '{${elementTypes.join(", ")}}';
    }
    
    /**
     * Compile generic custom types
     * @param genericType Generic type string like "Either<String, Int>"
     * @param context Type context
     * @return Elixir type equivalent
     */
    private function compileGenericType(genericType: String, ?context: TypeContext): String {
        var baseType = genericType.substring(0, genericType.indexOf("<"));
        var typeParams = extractGenericType(genericType);
        
        // For custom generics, convert to module reference with parameters
        var moduleName = NamingHelper.getElixirModuleName(baseType);
        var paramTypes = typeParams.split(",").map(t -> compileType(t.trim(), context));
        
        // Return parameterized type - this could be enhanced based on specific generic patterns
        return '${moduleName}.t(${paramTypes.join(", ")})';
    }
    
    /**
     * Check if a generic type is a built-in (Array, Map, Null)
     * @param genericType The generic type to check
     * @return True if built-in generic
     */
    private function isBuiltinGeneric(genericType: String): Bool {
        var builtins = ["Array<", "Map<", "Null<"];
        for (builtin in builtins) {
            if (genericType.indexOf(builtin) == 0) return true;
        }
        return false;
    }
    
    /**
     * Clear the type cache (useful for testing or memory management)
     */
    public function clearCache(): Void {
        typeCache.clear();
    }
    
    /**
     * Get type cache statistics
     * @return Object with cache size and hit information
     */
    public function getCacheStats(): {size: Int, keys: Array<String>} {
        var keys = [];
        for (key in typeCache.keys()) {
            keys.push(key);
        }
        return {size: keys.length, keys: keys};
    }
}

#end