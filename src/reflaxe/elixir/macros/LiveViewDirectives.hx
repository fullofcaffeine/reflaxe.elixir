package reflaxe.elixir.macros;

#if (macro || reflaxe_runtime)

using StringTools;

/**
 * LiveView-specific directive handling and validation
 * Supports LiveView attributes, component syntax, and slot compilation
 */
class LiveViewDirectives {
    
    /**
     * LiveView directive definitions with validation rules
     */
    public static var DIRECTIVES = [
        "lv:if" => {type: "conditional", requiresAssign: true},
        "lv:unless" => {type: "conditional", requiresAssign: true},
        "lv:for" => {type: "loop", requiresAssign: true},
        "lv:stream" => {type: "stream", requiresAssign: true},
        "lv:patch" => {type: "navigation", requiresAssign: false},
        "lv:navigate" => {type: "navigation", requiresAssign: false},
        "lv:slot" => {type: "slot", requiresAssign: false}
    ];
    
    /**
     * Check if attribute is a LiveView directive
     */
    public static function isLiveViewDirective(attribute: String): Bool {
        return attribute.startsWith("lv:") || attribute.startsWith(":");
    }
    
    /**
     * Validate LiveView directive usage
     */
    public static function validateDirective(directive: String, value: String, context: Dynamic): {valid: Bool, errors: Array<String>} {
        var result = {valid: true, errors: []};
        
        var directiveName = directive.startsWith("lv:") ? directive : "lv:" + directive.substring(1);
        
        if (!DIRECTIVES.exists(directiveName)) {
            result.valid = false;
            result.errors.push('Unknown LiveView directive: ${directive}');
            return result;
        }
        
        var directiveInfo = DIRECTIVES.get(directiveName);
        
        // Validate assign requirement
        if (directiveInfo.requiresAssign && !value.startsWith("@")) {
            // Check if it's a valid binding expression
            if (!isValidBinding(value)) {
                result.valid = false;
                result.errors.push('Directive ${directive} requires a valid assign or binding expression');
            }
        }
        
        // Type-specific validations
        switch (directiveInfo.type) {
            case "conditional":
                result = validateConditionalDirective(directive, value);
            case "loop":
                result = validateLoopDirective(directive, value);
            case "stream":
                result = validateStreamDirective(directive, value);
            case "navigation":
                result = validateNavigationDirective(directive, value);
            case "slot":
                result = validateSlotDirective(directive, value, context);
        }
        
        return result;
    }
    
    /**
     * Validate conditional directive (lv:if, lv:unless)
     */
    static function validateConditionalDirective(directive: String, value: String): {valid: Bool, errors: Array<String>} {
        var result = {valid: true, errors: []};
        
        if (value.trim().length == 0) {
            result.valid = false;
            result.errors.push('Conditional directive ${directive} requires a condition expression');
        }
        
        // Check for common logical operators
        if (value.contains("&&") || value.contains("||")) {
            result.errors.push('Complex logical expressions in ${directive} should use Elixir syntax (and, or)');
        }
        
        return result;
    }
    
    /**
     * Validate loop directive (lv:for)
     */
    static function validateLoopDirective(directive: String, value: String): {valid: Bool, errors: Array<String>} {
        var result = {valid: true, errors: []};
        
        if (!value.contains(" <- ") && !value.contains(".")) {
            result.valid = false;
            result.errors.push('Loop directive ${directive} requires valid enumerable expression');
        }
        
        return result;
    }
    
    /**
     * Validate stream directive (lv:stream)
     */
    static function validateStreamDirective(directive: String, value: String): {valid: Bool, errors: Array<String>} {
        var result = {valid: true, errors: []};
        
        if (!value.contains("stream") && !isValidAssign(value)) {
            result.valid = false;
            result.errors.push('Stream directive ${directive} requires valid stream assign');
        }
        
        return result;
    }
    
    /**
     * Validate navigation directive (lv:patch, lv:navigate)
     */
    static function validateNavigationDirective(directive: String, value: String): {valid: Bool, errors: Array<String>} {
        var result = {valid: true, errors: []};
        
        if (value.trim().length == 0) {
            result.valid = false;
            result.errors.push('Navigation directive ${directive} requires a path');
        }
        
        return result;
    }
    
    /**
     * Validate slot directive
     */
    static function validateSlotDirective(directive: String, value: String, context: Dynamic): {valid: Bool, errors: Array<String>} {
        var result = {valid: true, errors: []};
        
        if (context != null && context.componentName == null) {
            result.valid = false;
            result.errors.push('Slot directive can only be used within components');
        }
        
        return result;
    }
    
    /**
     * Check if value is a valid binding expression
     */
    static function isValidBinding(value: String): Bool {
        // Allow assign syntax (@variable), direct variable access, or function calls
        return value.startsWith("@") || 
               ~/^[a-zA-Z_][a-zA-Z0-9_]*(\.[a-zA-Z_][a-zA-Z0-9_]*)*$/.match(value) ||
               value.contains("(") && value.contains(")");
    }
    
    /**
     * Check if value is a valid assign reference
     */
    static function isValidAssign(value: String): Bool {
        return value.startsWith("@") || value.contains("assign");
    }
    
    /**
     * Convert LiveView directive to HEEx attribute syntax
     */
    public static function convertToHEExAttribute(directive: String, value: String): String {
        var heexDirective = directive.startsWith("lv:") ? ":" + directive.substring(3) : directive;
        
        return switch (directive) {
            case "lv:if" | "lv:unless" | "lv:for" | "lv:stream":
                '${heexDirective}={@${value}}';
            case "lv:patch" | "lv:navigate":
                '${heexDirective}="${value}"';
            case "lv:slot":
                heexDirective; // Slots have special syntax
            default:
                '${heexDirective}="${value}"';
        };
    }
    
    /**
     * Extract component props and validate types (simplified for compatibility)
     */
    public static function extractComponentProps(element: Dynamic): {props: Map<String, String>, errors: Array<String>} {
        var props = new Map<String, String>();
        var errors = [];
        
        // For now, return empty props due to Dynamic iteration limitations in Haxe
        // This will be enhanced in future iterations with proper type definitions
        
        return {props: props, errors: errors};
    }
    
    /**
     * Check if attribute is an event handler
     */
    static function isEventHandler(attribute: String): Bool {
        return attribute.startsWith("phx-") || 
               attribute.startsWith("on") ||
               ["click", "submit", "change", "focus", "blur", "keydown", "keyup"].contains(attribute);
    }
    
    /**
     * Validate component prop type (basic validation)
     */
    static function validatePropType(propName: String, value: String): {valid: Bool, errors: Array<String>} {
        var result = {valid: true, errors: []};
        
        // Basic type validations based on common patterns
        if (propName.endsWith("_id") && !~/^\d+$/.match(value) && !value.startsWith("@")) {
            result.errors.push('Prop ${propName} should be numeric or assign reference');
        }
        
        if (propName.startsWith("is_") && !["true", "false"].contains(value) && !value.startsWith("@")) {
            result.errors.push('Boolean prop ${propName} should be true/false or assign reference');
        }
        
        return result;
    }
    
    /**
     * Generate component invocation with proper Phoenix LiveView syntax
     */
    public static function generateComponentCall(componentName: String, props: Map<String, String>, content: String = ""): String {
        var result = '<.${componentName}';
        
        // Add props
        for (key in props.keys()) {
            var value = props.get(key);
            if (value.startsWith("{") && value.endsWith("}")) {
                // Binding syntax
                var binding = value.substring(1, value.length - 1);
                result += ' ${key}={@${binding}}';
            } else {
                // String literal
                result += ' ${key}="${value}"';
            }
        }
        
        if (content.trim().length == 0) {
            result += " />";
        } else {
            result += ">\n${content}\n</.${componentName}>";
        }
        
        return result;
    }
}

#end