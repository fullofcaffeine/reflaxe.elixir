package reflaxe.elixir.ast;

/**
 * Minimal name conversion utilities for the AST pipeline
 * 
 * WHY: After removing 75 helper files, we still need basic name conversion
 * WHAT: Provides CamelCase → snake_case and module name extraction
 * HOW: Simple regex-based transformations used across the compiler
 */
class NameUtils {
    /**
     * Convert CamelCase to snake_case
     * 
     * Examples:
     * - TodoApp → todo_app
     * - HTTPServer → http_server
     * - MyHTMLParser → my_html_parser
     */
    public static function toSnakeCase(name: String): String {
        if (name == null || name.length == 0) return name;
        
        // Handle acronyms and consecutive capitals
        var result = ~/([A-Z]+)([A-Z][a-z])/g.replace(name, "$1_$2");
        
        // Insert underscore before single capitals followed by lowercase
        result = ~/([a-z\d])([A-Z])/g.replace(result, "$1_$2");
        
        return result.toLowerCase();
    }
    
    /**
     * Get Elixir module name from fully qualified type string
     * 
     * Examples:
     * - com.example.MyClass → MyClass
     * - MyClass → MyClass
     */
    public static function getElixirModuleName(typeName: String): String {
        var parts = typeName.split(".");
        return parts[parts.length - 1];
    }
    
    /**
     * Convert field/method name to Elixir convention
     * Alias for toSnakeCase for clarity
     */
    public static inline function toElixirName(name: String): String {
        return toSnakeCase(name);
    }
}