package reflaxe.elixir.macros;

#if (macro || reflaxe_runtime)

using StringTools;

typedef JSXPosition = {
    var line: Int;
    var column: Int;
}

typedef JSXElement = {
    var tag: String;
    var content: String;
    var children: Array<JSXElement>;
    var selfClosing: Bool;
    var attributes: Map<String, String>;
    var position: JSXPosition;
    var valid: Bool;
    var errors: Array<String>;
}

/**
 * JSX parsing utilities for HXX macro system
 * Provides enhanced JSX parsing with better error handling and validation
 */
class HXXParser {
    
    /**
     * Enhanced JSX parsing with better error detection
     */
    public static function parseJSXElement(jsx: String, ?position: JSXPosition): JSXElement {
        jsx = jsx.trim();
        
        if (jsx.length == 0) {
            return createErrorElement("Empty JSX input", position);
        }
        
        var element: JSXElement = {
            tag: "",
            content: "",
            children: [],
            selfClosing: false,
            attributes: new Map<String, String>(),
            position: position != null ? position : {line: 1, column: 1},
            valid: true,
            errors: []
        };
        
        try {
            // Enhanced parsing logic
            if (jsx.endsWith("/>")) {
                element.selfClosing = true;
                jsx = jsx.substring(0, jsx.length - 2).trim();
            }
            
            // Find opening tag
            var openTagEnd = jsx.indexOf(">");
            if (openTagEnd == -1 && !element.selfClosing) {
                element.valid = false;
                element.errors.push("Unclosed tag detected");
                return element;
            }
            
            // Extract tag and attributes
            var openTag = element.selfClosing ? jsx.substring(1) : jsx.substring(1, openTagEnd);
            var tagParts = openTag.split(" ");
            element.tag = tagParts[0];
            
            // Parse attributes
            for (i in 1...tagParts.length) {
                var attr = tagParts[i].trim();
                if (attr.contains("=")) {
                    var attrParts = attr.split("=");
                    if (attrParts.length >= 2) {
                        var key = attrParts[0].trim();
                        var value = attrParts[1].trim().replace('"', '').replace("'", "");
                        element.attributes.set(key, value);
                    }
                }
            }
            
            // Extract content for non-self-closing elements
            if (!element.selfClosing) {
                var closeTag = '</${element.tag}>';
                var closeTagStart = jsx.lastIndexOf(closeTag);
                if (closeTagStart == -1) {
                    element.valid = false;
                    element.errors.push('Mismatched tags - missing closing tag for ${element.tag}');
                    return element;
                }
                
                element.content = jsx.substring(openTagEnd + 1, closeTagStart).trim();
                
                // Basic nested element detection
                if (element.content.contains("<") && element.content.contains(">")) {
                    element.children = parseNestedElements(element.content);
                }
            }
            
        } catch (e) {
            element.valid = false;
            element.errors.push('Parsing error: ${Std.string(e)}');
        }
        
        return element;
    }
    
    /**
     * Parse nested elements (basic implementation)
     */
    public static function parseNestedElements(content: String): Array<JSXElement> {
        var elements: Array<JSXElement> = [];
        
        // Simple nested element detection - would be enhanced in full implementation
        var openTags = [];
        var i = 0;
        while (i < content.length) {
            if (content.charAt(i) == "<") {
                var tagEnd = content.indexOf(">", i);
                if (tagEnd != -1) {
                    var tag = content.substring(i + 1, tagEnd);
                    if (tag.startsWith("/")) {
                        // Closing tag
                        if (openTags.length > 0) {
                            openTags.pop();
                        }
                    } else {
                        // Opening tag
                        openTags.push(tag.split(" ")[0]);
                    }
                    i = tagEnd + 1;
                } else {
                    i++;
                }
            } else {
                i++;
            }
        }
        
        return elements;
    }
    
    /**
     * Create error element for parsing failures
     */
    public static function createErrorElement(message: String, ?position: JSXPosition): JSXElement {
        return ({
            tag: "",
            content: "",
            children: [],
            selfClosing: false,
            attributes: new Map<String, String>(),
            position: position != null ? position : {line: 1, column: 1},
            valid: false,
            errors: [message]
        } : JSXElement);
    }
    
    /**
     * Validate JSX structure and provide detailed error information
     */
    public static function validateJSXStructure(jsx: String): {valid: Bool, errors: Array<String>} {
        var result = {valid: true, errors: []};
        
        try {
            var element = parseJSXElement(jsx);
            result.valid = element.valid;
            result.errors = element.errors.copy(); // Ensure we get a proper copy
            
            // Additional validation checks
            if (result.valid && jsx.contains("<") && jsx.contains(">")) {
                // Basic tag matching validation
                var openTags = [];
                var i = 0;
                while (i < jsx.length) {
                    if (jsx.charAt(i) == "<") {
                        var tagEnd = jsx.indexOf(">", i);
                        if (tagEnd != -1) {
                            var tagContent = jsx.substring(i + 1, tagEnd);
                            if (tagContent.startsWith("/")) {
                                // Closing tag
                                var tagName = tagContent.substring(1).split(" ")[0];
                                if (openTags.length == 0 || openTags[openTags.length - 1] != tagName) {
                                    result.valid = false;
                                    result.errors.push('Mismatched closing tag: ${tagName}');
                                    break;
                                } else {
                                    openTags.pop();
                                }
                            } else if (!tagContent.endsWith("/")) {
                                // Opening tag (not self-closing)
                                var tagName = tagContent.split(" ")[0];
                                openTags.push(tagName);
                            }
                            i = tagEnd + 1;
                        } else {
                            result.valid = false;
                            result.errors.push("Unclosed tag bracket");
                            break;
                        }
                    } else {
                        i++;
                    }
                }
                
                // Check for unclosed tags
                if (result.valid && openTags.length > 0) {
                    result.valid = false;
                    result.errors.push('Unclosed tags: ${openTags.join(", ")}');
                }
            }
        } catch (e) {
            result.valid = false;
            result.errors.push('Validation error: ${Std.string(e)}');
        }
        
        return result;
    }
    
    /**
     * Extract event handlers from JSX attributes
     */
    public static function extractEventHandlers(attributes: Map<String, String>): Map<String, String> {
        var handlers = new Map<String, String>();
        
        for (key in attributes.keys()) {
            if (key.startsWith("on")) {
                // React-style event handlers
                var phoenixEvent = convertReactEventToPhoenix(key);
                handlers.set(phoenixEvent, attributes.get(key));
            } else if (key.startsWith("phx-")) {
                // Phoenix LiveView event handlers
                handlers.set(key, attributes.get(key));
            }
        }
        
        return handlers;
    }
    
    /**
     * Convert React event handlers to Phoenix LiveView equivalents
     */
    public static function convertReactEventToPhoenix(reactEvent: String): String {
        return switch (reactEvent) {
            case "onClick": "phx-click";
            case "onSubmit": "phx-submit";
            case "onChange": "phx-change";
            case "onFocus": "phx-focus";
            case "onBlur": "phx-blur";
            case "onKeyDown": "phx-keydown";
            case "onKeyUp": "phx-keyup";
            case "onMouseEnter": "phx-mouseenter";
            case "onMouseLeave": "phx-mouseleave";
            default: reactEvent;
        }
    }
    
    /**
     * Extract template bindings from JSX content
     */
    public static function extractBindings(content: String): Array<String> {
        var bindings = [];
        var i = 0;
        
        while (i < content.length) {
            var start = content.indexOf("{", i);
            if (start == -1) break;
            
            var end = content.indexOf("}", start);
            if (end == -1) break;
            
            var binding = content.substring(start + 1, end).trim();
            if (binding.length > 0) {
                bindings.push(binding);
            }
            
            i = end + 1;
        }
        
        return bindings;
    }
    
    /**
     * Check if JSX contains conditional rendering patterns
     */
    public static function hasConditionalRendering(jsx: String): Bool {
        return jsx.contains("&&") || jsx.contains("?") || jsx.contains(":");
    }
    
    /**
     * Check if JSX contains loop rendering patterns
     */
    public static function hasLoopRendering(jsx: String): Bool {
        return jsx.contains(".map(") || jsx.contains(".forEach(") || jsx.contains(".filter(");
    }
}

#end
