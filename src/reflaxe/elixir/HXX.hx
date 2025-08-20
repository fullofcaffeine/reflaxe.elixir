package reflaxe.elixir;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

/**
 * HXX - Template string processor for Phoenix HEEx templates
 * 
 * Provides the hxx() macro function for converting Haxe template strings
 * to Phoenix HEEx format with proper interpolation and component syntax.
 * 
 * Features:
 * - String interpolation: ${expr} converts to Elixir interpolation syntax
 * - Conditional rendering: ternary -> if/else
 * - Loop transformations: map/join -> for comprehensions
 * - Component syntax preservation: <.button> stays as-is
 * - LiveView event handlers: phx-click, phx-change, etc.
 */
class HXX {
    
    #if macro
    /**
     * Template string processor macro
     * Converts Haxe template strings to Phoenix HEEx format
     */
    public static macro function hxx(templateStr: Expr): Expr {
        return switch (templateStr.expr) {
            case EConst(CString(s, _)):
                var processed = processTemplateString(s);
                macro $v{processed};
            case _:
                Context.error("hxx() expects a string literal", templateStr.pos);
        }
    }
    
    /**
     * Process template string at compile time
     * Handles all transformations from Haxe syntax to HEEx format
     */
    static function processTemplateString(template: String): String {
        // Convert Haxe ${} interpolation to Elixir #{} interpolation
        var processed = template;
        
        // Handle Haxe string interpolation: ${expr} -> #{expr}
        // Fix: Use proper regex escaping - single backslash in Haxe regex literals
        processed = ~/\$\{([^}]+)\}/g.replace(processed, "#{$1}");
        
        // Handle Phoenix component syntax: <.button> stays as <.button>
        // This is already valid HEEx syntax
        
        // Handle conditional rendering and loops
        processed = processConditionals(processed);
        processed = processLoops(processed);
        processed = processComponents(processed);
        processed = processLiveViewEvents(processed);
        
        return processed;
    }
    
    /**
     * Process conditional rendering patterns
     */
    static function processConditionals(template: String): String {
        // Convert Haxe ternary to Elixir if/else
        // #{condition ? "true_value" : "false_value"} -> <%= if condition, do: "true_value", else: "false_value" %>
        // Fix: Use proper regex escaping - single backslash in Haxe regex literals
        var ternaryPattern = ~/#\{([^?]+)\?([^:]+):([^}]+)\}/g;
        return ternaryPattern.replace(template, '<%= if $1, do: $2, else: $3 %>');
    }
    
    /**
     * Process loop patterns (simplified)
     */
    static function processLoops(template: String): String {
        // Handle map operations: #{array.map(func).join("")} -> <%= for item <- array do %><%= func(item) %><% end %>
        // This is a simplified version - full implementation would need more sophisticated parsing
        
        // Handle basic map/join patterns
        // Fix: Use proper regex escaping - single backslash in Haxe regex literals
        var mapJoinPattern = ~/#\{([^.]+)\.map\(([^)]+)\)\.join\("([^"]*)"\)\}/g;
        return mapJoinPattern.replace(template, '<%= for item <- $1 do %><%= $2(item) %><% end %>');
    }
    
    /**
     * Process Phoenix component syntax
     * Preserves <.component> syntax and handles attributes
     */
    static function processComponents(template: String): String {
        // Phoenix components with dot prefix are already valid HEEx
        // Just ensure attributes are properly formatted
        var componentPattern = ~/<\.([a-zA-Z_][a-zA-Z0-9_]*)(\s+[^>]*)?\/>/g;
        return componentPattern.replace(template, "$0");
    }
    
    /**
     * Process LiveView event handlers
     * Ensures phx-* attributes are preserved
     */
    static function processLiveViewEvents(template: String): String {
        // LiveView events (phx-click, phx-change, etc.) are already valid
        // This is a placeholder for future enhancements
        return template;
    }
    
    /**
     * Helper to validate template syntax at compile time
     */
    static function validateTemplate(template: String): Bool {
        // Basic validation to catch common errors early
        var openTags = ~/<([a-zA-Z][a-zA-Z0-9]*)\b[^>]*>/g;
        var closeTags = ~/<\/([a-zA-Z][a-zA-Z0-9]*)>/g;
        
        // Count open and close tags (simplified)
        var opens = [];
        openTags.map(template, function(r) {
            opens.push(r.matched(1));
            return "";
        });
        
        var closes = [];
        closeTags.map(template, function(r) {
            closes.push(r.matched(1));
            return "";
        });
        
        // Basic balance check
        return opens.length == closes.length;
    }
    #end
}