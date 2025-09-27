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
     * - RGB → rgb (not r_g_b)
     * - describeRGB → describe_rgb
     */
    public static function toSnakeCase(name: String): String {
        if (name == null || name.length == 0) return name;
        
        // First, handle sequences of capitals followed by lowercase
        // This converts "XMLParser" to "XML_Parser", "HTMLElement" to "HTML_Element"
        var result = ~/([A-Z]+)([A-Z][a-z])/g.replace(name, "$1_$2");
        
        // Insert underscore between lowercase/digit and uppercase
        // This converts "parseJSON" to "parse_JSON", "htmlElement" to "html_Element"
        result = ~/([a-z\d])([A-Z])/g.replace(result, "$1_$2");
        
        // Now lowercase everything
        // "XML_Parser" → "xml_parser", "parse_JSON" → "parse_json"
        // "RGB" stays as "RGB" then becomes "rgb" (no underscores inserted)
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
    
    /**
     * Check if a name is a reserved keyword in Elixir
     */
    public static function isElixirReserved(name: String): Bool {
        // Elixir reserved keywords
        var reserved = [
            "after", "and", "catch", "cond", "do", "else", "end", "false", "fn",
            "in", "nil", "not", "or", "rescue", "true", "when", "with",
            // Also include common special forms
            "alias", "case", "def", "defp", "defmodule", "defmacro", "defmacrop",
            "defstruct", "defdelegate", "defprotocol", "defimpl", "for", "if",
            "import", "quote", "receive", "require", "super", "try", "unless",
            "unquote", "use"
        ];
        return reserved.indexOf(name) >= 0;
    }
    
    /**
     * Convert name to safe Elixir function name, handling reserved keywords
     */
    public static function toSafeElixirFunctionName(name: String): String {
        var snakeName = toSnakeCase(name);

        // If it's a reserved keyword, prefix with underscore or suffix with _fn
        if (isElixirReserved(snakeName)) {
            return snakeName + "_fn";
        }

        return snakeName;
    }

    /**
     * Convert name to safe Elixir parameter name, handling reserved keywords
     * Parameters get underscore prefix to avoid conflicts
     */
    public static function toSafeElixirParameterName(name: String): String {
        var snakeName = toSnakeCase(name);

        // If it's a reserved keyword, prefix with underscore to make it safe
        if (isElixirReserved(snakeName)) {
            return "_" + snakeName;
        }

        return snakeName;
    }
}