package reflaxe.elixir.helpers;

/**
 * Utilities for converting between Haxe and Elixir naming conventions
 */
class NamingHelper {
    /**
     * Convert CamelCase to snake_case
     * MyClass -> my_class
     * someMethod -> some_method
     */
    public static function toSnakeCase(camelCase: String): String {
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
        return result;
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