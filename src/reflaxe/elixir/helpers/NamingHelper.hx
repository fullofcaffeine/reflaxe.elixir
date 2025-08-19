package reflaxe.elixir.helpers;

/**
 * Utilities for converting between Haxe and Elixir naming conventions
 */
class NamingHelper {
    /**
     * Convert CamelCase to snake_case
     * MyClass -> my_class
     * someMethod -> some_method
     * Also sanitizes Haxe compiler-generated temp variables:
     * _g -> g, _g1 -> g1, _g2 -> g2 (removes leading underscore)
     */
    public static function toSnakeCase(camelCase: String): String {
        // First, handle Haxe's compiler-generated temp variables
        // These start with underscore but should not in Elixir (as _ indicates unused)
        if (camelCase.charAt(0) == '_' && camelCase.length > 1) {
            // Remove the leading underscore for ALL Haxe-generated variables that are actually used
            // This includes: _g, _g1, _g2 (temp vars), _this (iterator reference), etc.
            // In Elixir, underscore prefix means "unused", but these ARE used
            camelCase = camelCase.substr(1);
        }
        
        var result = "";
        for (i in 0...camelCase.length) {
            var char = camelCase.charAt(i);
            if (char >= 'A' && char <= 'Z') {
                if (i > 0) result += "_";
                result += char.toLowerCase();
            } else {
                result += char;
            }
        }
        
        // Handle Elixir reserved keywords by adding suffix
        result = escapeElixirReservedKeyword(result);
        
        return result;
    }
    
    /**
     * Escape Elixir reserved keywords by adding a suffix
     */
    private static function escapeElixirReservedKeyword(name: String): String {
        var elixirReservedKeywords = [
            "fn", "do", "end", "case", "when", "cond", "if", "unless", "else", "elsif",
            "def", "defp", "defmacro", "defmodule", "defstruct", "defprotocol", "defimpl",
            "and", "or", "not", "in", "true", "false", "nil", "super", "try", "catch",
            "rescue", "after", "receive", "with", "quote", "unquote", "for", "import",
            "require", "alias", "use", "spawn", "spawn_link", "spawn_monitor", "send",
            "self", "make_ref", "node", "nodes", "tuple_size", "elem", "put_elem",
            "binary_part", "is_atom", "is_binary", "is_bitstring", "is_boolean", "is_float",
            "is_function", "is_integer", "is_list", "is_map", "is_number", "is_pid",
            "is_port", "is_reference", "is_tuple"
        ];
        
        if (elixirReservedKeywords.indexOf(name) >= 0) {
            return name + "_";
        }
        
        return name;
    }
    
    /**
     * Convert snake_case to CamelCase
     * my_class -> MyClass
     * some_method -> SomeMethod
     */
    public static function toCamelCase(snakeCase: String): String {
        var words = snakeCase.split("_");
        var result = "";
        
        for (word in words) {
            if (word.length > 0) {
                result += word.charAt(0).toUpperCase() + word.substr(1).toLowerCase();
            }
        }
        
        return result;
    }
    
    /**
     * Get valid Elixir module name from Haxe class name
     * Handles nested modules and ensures proper capitalization
     */
    public static function getElixirModuleName(haxeName: String): String {
        // Split on dots for nested modules
        var parts = haxeName.split(".");
        var result = [];
        
        for (part in parts) {
            // Ensure first letter is capitalized for Elixir modules
            if (part.length > 0) {
                var modulePart = sanitizeModuleName(part.charAt(0).toUpperCase() + part.substr(1));
                result.push(modulePart);
            }
        }
        
        return result.join(".");
    }
    
    /**
     * Sanitize module name to be valid in Elixir
     * Fixes invalid prefixes like ___ and ensures proper naming
     */
    public static function sanitizeModuleName(name: String): String {
        // Remove leading underscores (invalid in Elixir module names)
        while (name.length > 0 && name.charAt(0) == "_") {
            name = name.substr(1);
        }
        
        // If name starts with invalid characters, prefix with Haxe
        if (name.length == 0 || name.charAt(0) < 'A' || name.charAt(0) > 'Z') {
            name = "Haxe" + name;
        }
        
        return name;
    }
    
    /**
     * Get valid Elixir function name from Haxe method name
     * Converts to snake_case and handles special cases
     */
    public static function getElixirFunctionName(haxeName: String): String {
        // Convert to snake_case
        var snakeName = toSnakeCase(haxeName);
        
        // Handle special Haxe method names
        switch (snakeName) {
            case "new": return "__struct__";  // Constructor becomes struct constructor
            case "to_string": return "to_string";  // Already correct
            default: return snakeName;
        }
    }
}