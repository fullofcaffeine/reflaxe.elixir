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
     */
    static function processTemplateString(template: String): String {
        // Convert Haxe ${} interpolation to Elixir #{} interpolation
        var processed = template;
        
        // Handle Haxe string interpolation: ${expr} -> #{expr}
        processed = ~/\\$\\{([^}]+)\\}/g.replace(processed, "#{$1}");
        
        // Handle Phoenix component syntax: <.button> stays as <.button>
        // This is already valid HEEx syntax
        
        // Handle conditional rendering and loops
        processed = processConditionals(processed);
        processed = processLoops(processed);
        
        return processed;
    }
    
    /**
     * Process conditional rendering patterns
     */
    static function processConditionals(template: String): String {
        // Convert Haxe ternary to Elixir if/else
        // #{condition ? "true_value" : "false_value"} -> <%= if condition, do: "true_value", else: "false_value" %>
        var ternaryPattern = ~/\\#\\{([^?]+)\\?([^:]+):([^}]+)\\}/g;
        return ternaryPattern.replace(template, '<%= if $1, do: $2, else: $3 %>');
    }
    
    /**
     * Process loop patterns (simplified)
     */
    static function processLoops(template: String): String {
        // Handle map operations: #{array.map(func).join("")} -> <%= for item <- array do %><%= func(item) %><% end %>
        // This is a simplified version - full implementation would need more sophisticated parsing
        
        // Handle basic map/join patterns
        var mapJoinPattern = ~/\\#\\{([^.]+)\\.map\\(([^)]+)\\)\\.join\\("([^"]*)"\\)\\}/g;
        return mapJoinPattern.replace(template, '<%= for item <- $1 do %><%= $2(item) %><% end %>');
    }
    #end
    
    /**
     * Runtime helper for template processing (if needed)
     */
    public static function processRuntimeTemplate(template: String): String {
        // This would be used if runtime template processing is needed
        return template;
    }
}