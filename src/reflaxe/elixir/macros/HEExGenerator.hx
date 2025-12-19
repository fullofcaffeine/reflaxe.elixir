package reflaxe.elixir.macros;

#if (macro || reflaxe_runtime)
#if (macro && hxx_instrument_sys)
import reflaxe.elixir.macros.MacroTimingHelper;
#end

using StringTools;

/**
 * HEEx code generation from parsed JSX elements
 * Handles proper HEEx syntax, attribute formatting, and LiveView compatibility
 */
import reflaxe.elixir.macros.HXXParser.JSXElement;

typedef JSXSlot = {
    var name: String;
    var content: String;
}

class HEExGenerator {
    
    /**
     * Generate HEEx code from JSX element structure
     */
    public static function generateHEEx(element: JSXElement): String {
        #if (macro && hxx_instrument_sys)
        return MacroTimingHelper.time("HEExGenerator.generateHEEx", () -> generateHEExInternal(element));
        #else
        return generateHEExInternal(element);
        #end
    }

    static function generateHEExInternal(element: JSXElement): String {
        if (element == null || !element.valid) {
            throw "Invalid JSX element provided to HEExGenerator";
        }

        var parts:Array<String> = [];
        if (element.selfClosing) {
            parts.push('<${element.tag}');
            parts.push(generateAttributes(element.attributes));
            parts.push(" />");
        } else {
            parts.push('<${element.tag}');
            parts.push(generateAttributes(element.attributes));
            parts.push(">");
            parts.push(generateContent(element.content));
            parts.push('</${element.tag}>');
        }
        return parts.join("");
    }
    
    /**
     * Generate HEEx-compatible attributes from JSX attributes
     */
    public static function generateAttributes(attributes: Map<String, String>): String {
        if (attributes == null) {
            return "";
        }

        var parts:Array<String> = [];
        for (key in attributes.keys()) {
            var value = attributes.get(key);
            parts.push(" ");
            parts.push(convertAttribute(key, value));
        }

        return parts.join("");
    }
    
    /**
     * Convert JSX attribute to HEEx format
     */
    public static function convertAttribute(key: String, value: String): String {
        // Handle special JSX attributes
        key = switch (key) {
            case "className": "class";
            case "onClick": "phx-click";
            case "onSubmit": "phx-submit";
            case "onChange": "phx-change";
            case "onFocus": "phx-focus";
            case "onBlur": "phx-blur";
            case "onKeyDown": "phx-keydown";
            case "onKeyUp": "phx-keyup";
            default: key;
        };
        
        // Handle LiveView directives
        if (key.startsWith("lv:")) {
            return convertLiveViewDirective(key, value);
        }
        
        // Handle dynamic attributes (binding syntax)
        if (value.startsWith("{") && value.endsWith("}")) {
            var binding = value.substring(1, value.length - 1).trim();
            return '${key}={@${binding}}';
        }
        
        // Handle string attributes
        return '${key}="${value}"';
    }
    
    /**
     * Convert LiveView directives (lv:if, lv:for, etc.)
     */
    public static function convertLiveViewDirective(directive: String, value: String): String {
        return switch (directive) {
            case "lv:if": ':if={@${value}}';
            case "lv:unless": ':unless={@${value}}';
            case "lv:for": ':for={@${value}}';
            case "lv:stream": ':stream={@${value}}';
            case "lv:patch": ':patch="${value}"';
            case "lv:navigate": ':navigate="${value}"';
            default: '${directive}="${value}"'; // Pass through unknown directives
        };
    }
    
    /**
     * Generate content with proper binding syntax
     */
    public static function generateContent(content: String): String {
        #if (macro && hxx_instrument_sys)
        return MacroTimingHelper.time("HEExGenerator.generateContent", () -> generateContentInternal(content));
        #else
        return generateContentInternal(content);
        #end
    }

    static function generateContentInternal(content: String): String {
        if (content == null || content.trim().length == 0) {
            return "";
        }

        var result = content;

        // Handle template bindings: {variable} -> <%= @variable %>
        // Use a simple string replacement approach for Haxe compatibility
        var i = 0;
        while (i < result.length) {
            var start = result.indexOf("{", i);
            if (start == -1) break;

            var end = result.indexOf("}", start);
            if (end == -1) break;

            var binding = result.substring(start + 1, end).trim();
            var replacement = "";

            // Check for conditional rendering: condition && element
            if (binding.contains(" && ")) {
                replacement = generateConditionalBinding(binding);
            }
            // Check for loop rendering: array.map(item => ...)
            else if (binding.contains(".map(")) {
                replacement = generateLoopBinding(binding);
            }
            // Simple variable binding
            else {
                replacement = '<%= @${binding} %>';
            }

            result = result.substring(0, start) + replacement + result.substring(end + 1);
            i = start + replacement.length;
        }

        return result;
    }
    
    /**
     * Generate conditional rendering HEEx syntax
     */
    public static function generateConditionalBinding(binding: String): String {
        var parts = binding.split(" && ");
        if (parts.length >= 2) {
            var condition = parts[0].trim();
            var content = parts[1].trim();
            return '<%= if @${condition} do %>\n${content}\n<% end %>';
        }
        return binding; // Fallback
    }
    
    /**
     * Generate loop rendering HEEx syntax
     */
    public static function generateLoopBinding(binding: String): String {
        // Pattern: users.map(user => content)
        var mapIndex = binding.indexOf(".map(");
        if (mapIndex == -1) return binding;
        
        var arrayName = binding.substring(0, mapIndex).trim();
        var mapContent = binding.substring(mapIndex + 5); // Skip ".map("
        
        // Extract variable and content
        var arrowIndex = mapContent.indexOf(" => ");
        if (arrowIndex == -1) return binding;
        
        var itemVar = mapContent.substring(0, arrowIndex).trim();
        var content = mapContent.substring(arrowIndex + 4);
        
        // Remove closing parenthesis
        if (content.endsWith(")")) {
            content = content.substring(0, content.length - 1);
        }
        
        return '<%= for ${itemVar} <- @${arrayName} do %>\n${content}\n<% end %>';
    }
    
    /**
     * Generate component with proper slot handling
     */
    public static function generateComponent(componentName: String, props: Map<String, String>, slots: Array<JSXSlot>): String {
        #if (macro && hxx_instrument_sys)
        return MacroTimingHelper.time("HEExGenerator.generateComponent", () -> generateComponentInternal(componentName, props, slots));
        #else
        return generateComponentInternal(componentName, props, slots);
        #end
    }

    static function generateComponentInternal(componentName: String, props: Map<String, String>, slots: Array<JSXSlot>): String {
        var parts:Array<String> = [];
        parts.push('<.${componentName}');

        for (key in props.keys()) {
            var value = props.get(key);
            parts.push(' ${key}={@${value}}');
        }

        if (slots.length == 0) {
            parts.push(" />");
        } else {
            parts.push(">\n");
            for (slot in slots) {
                parts.push(generateSlot(slot.name, slot.content));
            }
            parts.push('</.${componentName}>');
        }

        return parts.join("");
    }
    
    /**
     * Generate slot syntax: <lv:slot name="header"> -> <:header>content</:header>
     */
    public static function generateSlot(slotName: String, content: String): String {
        return '<:${slotName}>${content}</:${slotName}>\n';
    }
    
    /**
     * Validate generated HEEx for Phoenix LiveView compatibility
     */
    public static function validateHEEx(heex: String): {valid: Bool, errors: Array<String>} {
        var result = {valid: true, errors: []};
        
        // Check for common HEEx syntax issues
        if (heex.contains("<%=") && !heex.contains("%>")) {
            result.valid = false;
            result.errors.push("Unclosed HEEx expression tag");
        }
        
        if (heex.contains("<:") && !heex.contains("</:")) {
            result.valid = false;
            result.errors.push("Unclosed HEEx slot tag");
        }
        
        // Check for LiveView directive syntax
        var directivePattern = ~/:(\w+)=\{[^}]*\}/g;
        if (!directivePattern.match(heex) && heex.contains(":")) {
            result.valid = false;
            result.errors.push("Invalid LiveView directive syntax");
        }
        
        return result;
    }
}

#end
