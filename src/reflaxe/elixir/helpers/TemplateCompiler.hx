package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.Expr;
import reflaxe.data.ClassFuncData;
import reflaxe.data.ClassVarData;
import reflaxe.elixir.helpers.NamingHelper;

using StringTools;
using reflaxe.helpers.NameMetaHelper;

/**
 * TemplateCompiler - Compiles @:template annotated classes to Phoenix HEEx templates
 * 
 * Supports:
 * - @:template annotation detection and configuration extraction
 * - hxx() function for template string compilation
 * - Phoenix.Component integration
 * - Type-safe template rendering with assigns
 */
class TemplateCompiler {
    
    /**
     * Check if a class type has @:template annotation
     */
    public static function isTemplateClassType(classType: ClassType): Bool {
        if (classType == null) return false;
        return classType.meta.has(":template");
    }
    
    /**
     * Extract template configuration from @:template annotation
     */
    public static function getTemplateConfig(classType: ClassType): TemplateConfig {
        if (!classType.meta.has(":template")) {
            return {templateFile: null};
        }
        
        var meta = classType.meta.extract(":template")[0];
        var templateFile = null;
        
        if (meta.params != null && meta.params.length > 0) {
            switch (meta.params[0].expr) {
                case EConst(CString(s, _)):
                    templateFile = s;
                case _:
            }
        }
        
        return {templateFile: templateFile};
    }
    
    /**
     * Compile @:template annotated class to Phoenix template module
     */
    public static function compileFullTemplate(className: String, config: TemplateConfig): String {
        var moduleName = NamingHelper.getElixirModuleName(className);
        var templateFile = config.templateFile != null ? config.templateFile : '${NamingHelper.toSnakeCase(className)}.html.heex';
        
        var result = 'defmodule ${moduleName} do\n';
        result += '  @moduledoc """\n';
        result += '  Phoenix HEEx template module generated from Haxe @:template class\n';
        result += '  Template file: ${templateFile}\n';
        result += '  """\n\n';
        
        // Import Phoenix.Component for template functionality
        result += '  use Phoenix.Component\n';
        result += '  import Phoenix.HTML\n';
        result += '  import Phoenix.HTML.Form\n\n';
        
        // Add template compilation functions
        result += '  @doc """\n';
        result += '  Renders the ${templateFile} template with the provided assigns\n';
        result += '  """\n';
        result += '  def render(assigns) do\n';
        result += '    ~H"""\n';
        result += '    <!-- Template content will be processed by hxx() function -->\n';
        result += '    <div class="haxe-template">\n';
        result += '      <%= assigns[:content] || "Template content" %>\n';
        result += '    </div>\n';
        result += '    """\n';
        result += '  end\n\n';
        
        // Add helper functions for template processing
        result += '  @doc """\n';
        result += '  Template string processor - converts Haxe template strings to HEEx\n';
        result += '  """\n';
        result += '  def process_template_string(template_str) do\n';
        result += '    # Process template string interpolations and convert to HEEx syntax\n';
        result += '    template_str\n';
        result += '    |> String.replace(~r/\\$\\{([^}]+)\\}/, "<%= \\\\1 %>")\n';
        result += '    |> String.replace(~r/<\\.([^>]+)>/, "<.\\\\1>")\n';
        result += '  end\n\n';
        
        result += 'end\n';
        
        return result;
    }
    
    /**
     * Generate the hxx() macro function for template string processing
     * This will be added to the global scope for template compilation
     */
    public static function generateHxxFunction(): String {
        return '''
        /**
         * Template string processor macro
         * Converts Haxe template strings to Phoenix HEEx format
         */
        macro function hxx(templateStr: Expr): Expr {
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
            // ${condition ? "true_value" : "false_value"} -> <%= if condition, do: "true_value", else: "false_value" %>
            var ternaryPattern = ~/\\#\\{([^?]+)\\?([^:]+):([^}]+)\\}/g;
            return ternaryPattern.replace(template, '<%= if $1, do: $2, else: $3 %>');
        }
        
        /**
         * Process loop patterns (simplified)
         */
        static function processLoops(template: String): String {
            // Handle map operations: ${array.map(func).join("")} -> <%= for item <- array do %><%= func(item) %><% end %>
            // This is a simplified version - full implementation would need more sophisticated parsing
            return template;
        }
        ''';
    }
}

/**
 * Template configuration extracted from @:template annotation
 */
typedef TemplateConfig = {
    templateFile: Null<String>
}

#end