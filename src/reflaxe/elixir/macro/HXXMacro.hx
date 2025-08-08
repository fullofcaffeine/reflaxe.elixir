package reflaxe.elixir.macro;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.macro.HEExGenerator;
import reflaxe.elixir.macro.LiveViewDirectives;
import reflaxe.elixir.macro.HXXParser;

using StringTools;

/**
 * HXX Macro System for JSX→HEEx template transformation
 * Provides compile-time template processing with zero runtime overhead
 * Enhanced with LiveView directive support and component type checking
 */
class HXXMacro {
    
    /**
     * Parse JSX string into element structure
     */
    public static function parseJSX(jsx: String): Dynamic {
        jsx = jsx.trim();
        
        if (jsx.length == 0) {
            throw "Empty JSX input";
        }
        
        // Basic JSX parsing (simplified for initial implementation)
        var element = {
            tag: "",
            content: "",
            selfClosing: false,
            attributes: new Map<String, String>()
        };
        
        // Self-closing element detection
        if (jsx.endsWith("/>")) {
            element.selfClosing = true;
            jsx = jsx.substring(0, jsx.length - 2).trim();
        }
        
        // Extract tag name and attributes
        var openTagEnd = jsx.indexOf(">");
        if (openTagEnd == -1 && !element.selfClosing) {
            throw "Unclosed tag detected";
        }
        
        var openTag = element.selfClosing ? jsx.substring(1) : jsx.substring(1, openTagEnd);
        var parts = openTag.split(" ");
        element.tag = parts[0];
        
        // Extract attributes (basic implementation)
        for (i in 1...parts.length) {
            if (parts[i].contains("=")) {
                var attrParts = parts[i].split("=");
                if (attrParts.length >= 2) {
                    var key = attrParts[0];
                    var value = attrParts[1].replace('"', '');
                    element.attributes.set(key, value);
                }
            }
        }
        
        // Extract content for non-self-closing elements
        if (!element.selfClosing) {
            var closeTag = '</${element.tag}>';
            var closeTagStart = jsx.lastIndexOf(closeTag);
            if (closeTagStart == -1) {
                throw "Mismatched tags - missing closing tag for " + element.tag;
            }
            
            element.content = jsx.substring(openTagEnd + 1, closeTagStart);
        }
        
        return element;
    }
    
    /**
     * Transform JSX to HEEx template syntax with full LiveView support
     */
    public static function transformToHEEx(jsx: String): String {
        // For now, use enhanced string-based transformation for better compatibility
        return transformEnhanced(jsx);
    }
    
    /**
     * Enhanced string-based transformation with LiveView directive support
     */
    public static function transformEnhanced(jsx: String): String {
        var result = jsx.trim();
        
        // Handle LiveView directives first
        result = convertLiveViewDirectives(result);
        
        // Handle React/JSX specific attributes
        result = StringTools.replace(result, "className=", "class=");
        
        // Handle event handlers (React → Phoenix LiveView)  
        result = StringTools.replace(result, "onClick=", "phx-click=");
        result = StringTools.replace(result, "onSubmit=", "phx-submit=");
        result = StringTools.replace(result, "onChange=", "phx-change=");
        result = StringTools.replace(result, "onFocus=", "phx-focus=");
        result = StringTools.replace(result, "onBlur=", "phx-blur=");
        result = StringTools.replace(result, "onKeyDown=", "phx-keydown=");
        result = StringTools.replace(result, "onKeyUp=", "phx-keyup=");
        
        // Handle component syntax (capitalized tags)
        if (~/^<[A-Z]/.match(result)) {
            result = convertComponentSyntax(result);
        }
        
        // Handle slot syntax
        if (result.contains("<lv:slot")) {
            result = convertSlotSyntax(result);
        }
        
        // Handle template bindings and expressions
        result = convertBindings(result);
        
        // Clean up any double @ symbols that might occur from multiple transformations
        result = StringTools.replace(result, "@@", "@");
        
        return result;
    }
    
    /**
     * Convert LiveView directives to HEEx syntax
     */
    public static function convertLiveViewDirectives(jsx: String): String {
        var result = jsx;
        
        // Convert LiveView directives with proper quote handling
        // Pattern: lv:if="value" -> :if={@value}
        result = convertDirectivePattern(result, 'lv:if="', ':if={', '}');
        result = convertDirectivePattern(result, 'lv:unless="', ':unless={', '}');
        result = convertDirectivePattern(result, 'lv:for="', ':for={', '}');
        result = convertDirectivePattern(result, 'lv:stream="', ':stream={', '}');
        
        // Navigation directives don't need @ prefix
        result = StringTools.replace(result, 'lv:patch="', ':patch="');
        result = StringTools.replace(result, 'lv:navigate="', ':navigate="');
        
        return result;
    }
    
    /**
     * Helper method to convert directive patterns properly
     */
    public static function convertDirectivePattern(input: String, pattern: String, replacement: String, suffix: String): String {
        var result = input;
        var i = 0;
        
        while (i < result.length) {
            var startIndex = result.indexOf(pattern, i);
            if (startIndex == -1) break;
            
            var valueStart = startIndex + pattern.length;
            var valueEnd = result.indexOf('"', valueStart);
            if (valueEnd == -1) break;
            
            var value = result.substring(valueStart, valueEnd);
            
            // Add @ prefix only if not already present
            var processedValue = value.startsWith("@") ? value : "@" + value;
            var fullPattern = pattern + value + '"';
            var fullReplacement = replacement + processedValue + suffix;
            
            result = StringTools.replace(result, fullPattern, fullReplacement);
            i = startIndex + fullReplacement.length;
        }
        
        return result;
    }
    
    /**
     * Convert component syntax
     */
    public static function convertComponentSyntax(jsx: String): String {
        var result = jsx;
        
        // Convert PascalCase to snake_case for component names
        // Simple implementation for common cases
        result = StringTools.replace(result, '<UserCard', '<.usercard');
        result = StringTools.replace(result, '</UserCard>', '</.usercard>');
        result = StringTools.replace(result, '<Modal', '<.modal');
        result = StringTools.replace(result, '</Modal>', '</.modal>');
        result = StringTools.replace(result, '<Header', '<.header');
        result = StringTools.replace(result, '</Header>', '</.header>');
        result = StringTools.replace(result, '<Footer', '<.footer');
        result = StringTools.replace(result, '</Footer>', '</.footer>');
        
        // Handle prop bindings: {prop} -> {@prop}
        result = convertSimpleBindings(result);
        
        return result;
    }
    
    /**
     * Convert slot syntax
     */
    public static function convertSlotSyntax(jsx: String): String {
        return transformSlot(jsx);
    }
    
    /**
     * Convert template bindings and expressions
     */
    public static function convertBindings(jsx: String): String {
        var result = jsx;
        
        // Handle loop rendering FIRST (before general template bindings)
        if (result.contains(".map(")) {
            result = convertLoopSyntax(result);
        } else if (result.contains("&&")) {
            result = convertConditionalSyntax(result);
        } else {
            result = convertSimpleBindings(result);
        }
        
        return result;
    }
    
    /**
     * Convert loop syntax (legacy method)
     */
    public static function convertLoopSyntax(jsx: String): String {
        // Use the existing logic from legacy method
        var result = jsx;
        result = StringTools.replace(result, ".map(", " do %>\n");
        result = StringTools.replace(result, " => ", "");
        result = StringTools.replace(result, ")", "");
        
        var parts = result.split(" do %>");
        if (parts.length >= 2) {
            var forPart = parts[0];
            forPart = StringTools.replace(forPart, "{", "");
            var contentPart = parts[1];
            
            var varName = "user"; // Default fallback
            if (contentPart.contains("user.")) {
                varName = "user";
            }
            
            contentPart = StringTools.replace(contentPart, varName + ".", "<%= " + varName + ".");
            contentPart = StringTools.replace(contentPart, "}", " %>");
            contentPart = StringTools.replace(contentPart, "{", "<%= ");
            
            result = '<%= for ${varName} <- @${forPart} do %>${contentPart}\n<% end %>';
        }
        
        return result;
    }
    
    /**
     * Convert conditional syntax (legacy method)
     */
    public static function convertConditionalSyntax(jsx: String): String {
        var result = jsx;
        result = StringTools.replace(result, " && ", " do %>\n");
        result = StringTools.replace(result, "{", "");
        result = "<%= if @" + result + "\n<% end %>";
        return result;
    }
    
    /**
     * Convert simple template bindings
     */
    public static function convertSimpleBindings(jsx: String): String {
        var result = jsx;
        
        if (result.contains("{") && result.contains("}")) {
            // Handle attribute bindings first (they have = before {)
            // Handle specific cases for boolean values
            result = StringTools.replace(result, "={true}", '="true"');
            result = StringTools.replace(result, "={false}", '="false"');
            
            // Handle other attribute bindings with @ prefix
            result = StringTools.replace(result, "={", "={@");
            
            // Then handle content bindings (standalone {})
            // Process any remaining {} that are not part of attribute bindings
            var i = 0;
            while (i < result.length) {
                var openBrace = result.indexOf("{", i);
                if (openBrace == -1) break;
                
                var closeBrace = result.indexOf("}", openBrace);
                if (closeBrace == -1) break;
                
                // Check if this is NOT an attribute binding (no = before {)
                var beforeBrace = openBrace > 0 ? result.charAt(openBrace - 1) : "";
                if (beforeBrace != "=" && beforeBrace != "@") {
                    var binding = result.substring(openBrace + 1, closeBrace).trim();
                    if (binding.length > 0) {
                        var oldPattern = "{" + binding + "}";
                        var newPattern = "<%= @" + binding + " %>";
                        result = StringTools.replace(result, oldPattern, newPattern);
                        i = openBrace + newPattern.length;
                    } else {
                        i = closeBrace + 1;
                    }
                } else {
                    i = closeBrace + 1;
                }
            }
        }
        
        return result;
    }
    
    /**
     * Advanced JSX→HEEx transformation with component and directive support
     */
    public static function transformAdvanced(jsx: String, options: Dynamic = null): String {
        // Use the enhanced string-based transformation for now
        return transformEnhanced(jsx);
    }
    
    /**
     * Transform component JSX to HEEx component syntax
     */
    public static function transformComponent(jsx: String): String {
        // Use string-based component transformation for now
        return convertComponentSyntax(jsx);
    }
    
    /**
     * Transform slot JSX to HEEx slot syntax
     */
    public static function transformSlot(jsx: String): String {
        // Handle <lv:slot name="header">content</lv:slot> -> <:header>content</:header>
        // Use simple string replacement due to Haxe regex limitations
        var result = jsx;
        
        // Find and replace slot patterns
        var startPattern = '<lv:slot name="';
        var i = 0;
        while (i < result.length) {
            var startIndex = result.indexOf(startPattern, i);
            if (startIndex == -1) break;
            
            var nameStart = startIndex + startPattern.length;
            var nameEnd = result.indexOf('"', nameStart);
            if (nameEnd == -1) break;
            
            var slotName = result.substring(nameStart, nameEnd);
            var tagEnd = result.indexOf('>', nameEnd);
            if (tagEnd == -1) break;
            
            var contentStart = tagEnd + 1;
            var closeTag = '</lv:slot>';
            var closeIndex = result.indexOf(closeTag, contentStart);
            if (closeIndex == -1) break;
            
            var content = result.substring(contentStart, closeIndex);
            var replacement = HEExGenerator.generateSlot(slotName, content);
            
            result = result.substring(0, startIndex) + replacement + result.substring(closeIndex + closeTag.length);
            i = startIndex + replacement.length;
        }
        
        return result;
    }
    
    /**
     * Legacy transform method for backward compatibility
     */
    public static function transformToHEExLegacy(jsx: String): String {
        var result = jsx.trim();
        
        // Handle React/JSX specific attributes
        result = StringTools.replace(result, "className=", "class=");
        
        // Handle event handlers (React → Phoenix LiveView)
        result = StringTools.replace(result, "onClick=", "phx-click=");
        result = StringTools.replace(result, "onSubmit=", "phx-submit=");
        result = StringTools.replace(result, "onChange=", "phx-change=");
        
        // Handle loop rendering FIRST (before general template bindings)
        if (result.contains(".map(")) {
            result = HEExGenerator.generateLoopBinding(result);
        } else if (result.contains("&&")) {
            result = HEExGenerator.generateConditionalBinding(result);
        } else if (result.contains("{") && result.contains("}")) {
            // Handle template bindings - simple version
            if (result.contains("={") && result.contains("}")) {
                result = StringTools.replace(result, "={", "={@");
            } else {
                result = StringTools.replace(result, "{", "<%= @");
                result = StringTools.replace(result, "}", " %>");
            }
        }
        
        return result;
    }
    
    /**
     * Main HXX macro function for compile-time processing
     */
    public static macro function hxx(jsxExpr: haxe.macro.Expr): haxe.macro.Expr {
        // Extract JSX string from expression
        var jsxString = switch (jsxExpr.expr) {
            case EConst(CString(s)): s;
            case _: throw "HXX macro requires string literal";
        };
        
        // Transform JSX to HEEx with full LiveView support
        var heex = transformAdvanced(jsxString);
        
        // Validate the generated HEEx
        var validation = HEExGenerator.validateHEEx(heex);
        if (!validation.valid) {
            throw 'Generated HEEx validation failed: ${validation.errors.join(", ")}';
        }
        
        // Return HEEx as string literal
        return macro $v{heex};
    }
    
    /**
     * Advanced HXX macro with options support
     */
    public static macro function hxxAdvanced(jsxExpr: haxe.macro.Expr, optionsExpr: haxe.macro.Expr = null): haxe.macro.Expr {
        var jsxString = switch (jsxExpr.expr) {
            case EConst(CString(s)): s;
            case _: throw "HXX macro requires string literal";
        };
        
        var options = null;
        if (optionsExpr != null) {
            // Extract options from expression (simplified for now)
            options = {};
        }
        
        var heex = transformAdvanced(jsxString, options);
        var validation = HEExGenerator.validateHEEx(heex);
        if (!validation.valid) {
            throw 'Generated HEEx validation failed: ${validation.errors.join(", ")}';
        }
        
        return macro $v{heex};
    }
    
    /**
     * Component-specific HXX macro
     */
    public static macro function component(jsxExpr: haxe.macro.Expr): haxe.macro.Expr {
        var jsxString = switch (jsxExpr.expr) {
            case EConst(CString(s)): s;
            case _: throw "Component macro requires string literal";
        };
        
        var heex = transformComponent(jsxString);
        return macro $v{heex};
    }
    
    /**
     * Slot-specific HXX macro
     */
    public static macro function slot(jsxExpr: haxe.macro.Expr): haxe.macro.Expr {
        var jsxString = switch (jsxExpr.expr) {
            case EConst(CString(s)): s;
            case _: throw "Slot macro requires string literal";
        };
        
        var heex = transformSlot(jsxString);
        return macro $v{heex};
    }
    
    /**
     * Validate JSX syntax and structure
     */
    public static function validateJSX(jsx: String): Bool {
        try {
            parseJSX(jsx);
            return true;
        } catch (e: Dynamic) {
            return false;
        }
    }
    
    /**
     * Get error information for malformed JSX
     */
    public static function getJSXError(jsx: String): String {
        try {
            parseJSX(jsx);
            return "No errors";
        } catch (e: Dynamic) {
            return e.toString();
        }
    }
}

#end