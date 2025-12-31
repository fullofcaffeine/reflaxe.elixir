package phoenix.types;

import phoenix.types.HXXTypes;

/**
 * HXX Component Registry System
 * 
 * Central registry for all HTML elements and Phoenix components with their type definitions.
 * Provides compile-time lookup and validation for HXX templates.
 * 
 * Architecture:
 * - Static registration of HTML5 elements
 * - Runtime registration of Phoenix components
 * - Attribute name conversion (camelCase → kebab-case)
 * - Type validation and error reporting
 * 
 * Usage:
 * ```haxe
 * var elementType = HXXComponentRegistry.getElementType("input");
 * var isValid = HXXComponentRegistry.validateAttribute("input", "phxClick");
 * ```
 */
class HXXComponentRegistry {
    
    // ========================================================================
    // HTML ELEMENT REGISTRY
    // ========================================================================
    
    /**
     * Registry of HTML5 elements and their attribute types
     */
    private static var htmlElements: Map<String, ElementTypeInfo> = [
        // Form elements
        "input" => {
            name: "input",
            attributeType: "InputAttributes",
            allowedAttributes: getInputAttributes(),
            voidElement: true
        },
        "button" => {
            name: "button",
            attributeType: "ButtonAttributes",
            allowedAttributes: getButtonAttributes(),
            voidElement: false
        },
        "form" => {
            name: "form",
            attributeType: "FormAttributes",
            allowedAttributes: getFormAttributes(),
            voidElement: false
        },
        "select" => {
            name: "select",
            attributeType: "SelectAttributes",
            allowedAttributes: getSelectAttributes(),
            voidElement: false
        },
        "option" => {
            name: "option",
            attributeType: "OptionAttributes",
            allowedAttributes: getOptionAttributes(),
            voidElement: false
        },
        "textarea" => {
            name: "textarea",
            attributeType: "TextAreaAttributes",
            allowedAttributes: getTextAreaAttributes(),
            voidElement: false
        },
        "label" => {
            name: "label",
            attributeType: "LabelAttributes",
            allowedAttributes: getLabelAttributes(),
            voidElement: false
        },
        
        // Text content
        "a" => {
            name: "a",
            attributeType: "AnchorAttributes",
            allowedAttributes: getAnchorAttributes(),
            voidElement: false
        },
        "p" => {
            name: "p",
            attributeType: "ParagraphAttributes",
            allowedAttributes: getGlobalAttributes(),
            voidElement: false
        },
        "div" => {
            name: "div",
            attributeType: "DivAttributes",
            allowedAttributes: getGlobalAttributes(),
            voidElement: false
        },
        "span" => {
            name: "span",
            attributeType: "SpanAttributes",
            allowedAttributes: getGlobalAttributes(),
            voidElement: false
        },
        
        // Headings
        "h1" => {
            name: "h1",
            attributeType: "HeadingAttributes",
            allowedAttributes: getGlobalAttributes(),
            voidElement: false
        },
        "h2" => {
            name: "h2",
            attributeType: "HeadingAttributes",
            allowedAttributes: getGlobalAttributes(),
            voidElement: false
        },
        "h3" => {
            name: "h3",
            attributeType: "HeadingAttributes",
            allowedAttributes: getGlobalAttributes(),
            voidElement: false
        },
        "h4" => {
            name: "h4",
            attributeType: "HeadingAttributes",
            allowedAttributes: getGlobalAttributes(),
            voidElement: false
        },
        "h5" => {
            name: "h5",
            attributeType: "HeadingAttributes",
            allowedAttributes: getGlobalAttributes(),
            voidElement: false
        },
        "h6" => {
            name: "h6",
            attributeType: "HeadingAttributes",
            allowedAttributes: getGlobalAttributes(),
            voidElement: false
        },
        
        // Media
        "img" => {
            name: "img",
            attributeType: "ImageAttributes",
            allowedAttributes: getImageAttributes(),
            voidElement: true
        },
        "video" => {
            name: "video",
            attributeType: "VideoAttributes",
            allowedAttributes: getVideoAttributes(),
            voidElement: false
        },
        "audio" => {
            name: "audio",
            attributeType: "AudioAttributes",
            allowedAttributes: getAudioAttributes(),
            voidElement: false
        },
        
        // Lists
        "ul" => {
            name: "ul",
            attributeType: "ListAttributes",
            allowedAttributes: getListAttributes(),
            voidElement: false
        },
        "ol" => {
            name: "ol",
            attributeType: "ListAttributes",
            allowedAttributes: getListAttributes(),
            voidElement: false
        },
        "li" => {
            name: "li",
            attributeType: "ListItemAttributes",
            allowedAttributes: getListItemAttributes(),
            voidElement: false
        },
        
        // Tables
        "table" => {
            name: "table",
            attributeType: "TableAttributes",
            allowedAttributes: getGlobalAttributes(),
            voidElement: false
        },
        "tr" => {
            name: "tr",
            attributeType: "TableRowAttributes",
            allowedAttributes: getGlobalAttributes(),
            voidElement: false
        },
        "td" => {
            name: "td",
            attributeType: "TableCellAttributes",
            allowedAttributes: getTableCellAttributes(),
            voidElement: false
        },
        "th" => {
            name: "th",
            attributeType: "TableCellAttributes",
            allowedAttributes: getTableCellAttributes(),
            voidElement: false
        },
        
        // Meta elements
        "meta" => {
            name: "meta",
            attributeType: "MetaAttributes",
            allowedAttributes: getMetaAttributes(),
            voidElement: true
        },
        "link" => {
            name: "link",
            attributeType: "LinkAttributes",
            allowedAttributes: getLinkAttributes(),
            voidElement: true
        },
        "script" => {
            name: "script",
            attributeType: "ScriptAttributes",
            allowedAttributes: getScriptAttributes(),
            voidElement: false
        },
        "style" => {
            name: "style",
            attributeType: "StyleAttributes",
            allowedAttributes: getStyleAttributes(),
            voidElement: false
        },
        
        // Semantic HTML5
        "article" => {
            name: "article",
            attributeType: "SemanticAttributes",
            allowedAttributes: getGlobalAttributes(),
            voidElement: false
        },
        "section" => {
            name: "section",
            attributeType: "SemanticAttributes",
            allowedAttributes: getGlobalAttributes(),
            voidElement: false
        },
        "nav" => {
            name: "nav",
            attributeType: "SemanticAttributes",
            allowedAttributes: getGlobalAttributes(),
            voidElement: false
        },
        "aside" => {
            name: "aside",
            attributeType: "SemanticAttributes",
            allowedAttributes: getGlobalAttributes(),
            voidElement: false
        },
        "header" => {
            name: "header",
            attributeType: "SemanticAttributes",
            allowedAttributes: getGlobalAttributes(),
            voidElement: false
        },
        "footer" => {
            name: "footer",
            attributeType: "SemanticAttributes",
            allowedAttributes: getGlobalAttributes(),
            voidElement: false
        },
        "main" => {
            name: "main",
            attributeType: "SemanticAttributes",
            allowedAttributes: getGlobalAttributes(),
            voidElement: false
        },
        
        // Other common elements
        "br" => {
            name: "br",
            attributeType: "GlobalAttributes",
            allowedAttributes: getGlobalAttributes(),
            voidElement: true
        },
        "hr" => {
            name: "hr",
            attributeType: "GlobalAttributes",
            allowedAttributes: getGlobalAttributes(),
            voidElement: true
        },
    ];
    
    // ========================================================================
    // PHOENIX COMPONENT REGISTRY
    // ========================================================================
    
    /**
     * Registry of Phoenix components (populated dynamically)
     */
    private static var phoenixComponents: Map<String, ComponentDefinition> = new Map();
    
    // ========================================================================
    // PUBLIC API
    // ========================================================================
    
    /**
     * Get element type information
     */
    public static function getElementType(elementName: String): Null<ElementTypeInfo> {
        return htmlElements.get(elementName.toLowerCase());
    }
    
    /**
     * Check if an element is registered
     */
    public static function isRegisteredElement(elementName: String): Bool {
        return htmlElements.exists(elementName.toLowerCase()) || 
               phoenixComponents.exists(elementName);
    }
    
    /**
     * Validate if an attribute is allowed for an element
     */
    public static function validateAttribute(elementName: String, attributeName: String): Bool {
        var element = htmlElements.get(elementName.toLowerCase());
        if (element == null) {
            // Check Phoenix components
            var component = phoenixComponents.get(elementName);
            if (component != null) {
                return validateComponentAttribute(component, attributeName);
            }
            return false;
        }
        
        return element.allowedAttributes.indexOf(attributeName) != -1;
    }
    
    /**
     * Get allowed attributes for an element
     */
    public static function getAllowedAttributes(elementName: String): Array<String> {
        var element = htmlElements.get(elementName.toLowerCase());
        if (element != null) {
            return element.allowedAttributes;
        }
        
        var component = phoenixComponents.get(elementName);
        if (component != null) {
            return component.attributes.map(a -> a.name);
        }
        
        return [];
    }
    
    /**
     * Register a Phoenix component
     */
    public static function registerComponent(component: ComponentDefinition): Void {
        phoenixComponents.set(component.name, component);
    }
    
    /**
     * Convert camelCase attribute name to kebab-case for HTML/HEEx output
     * Also supports snake_case input (converts to kebab-case)
     */
    public static function toHtmlAttribute(name: String): String {
        return switch(name) {
            // Special HTML cases
            case "className": "class";
            case "htmlFor": "for";
            case "httpEquiv": "http-equiv";
            case "crossOrigin": "crossorigin";
            case "acceptCharset": "accept-charset";
            case "accessKey": "accesskey";
            case "contentEditable": "contenteditable";
            case "contextMenu": "contextmenu";
            case "tabIndex": "tabindex";
            case "autoComplete": "autocomplete";
            case "autoFocus": "autofocus";
            case "autoPlay": "autoplay";
            case "dateTime": "datetime";
            case "encType": "enctype";
            case "formAction": "formaction";
            case "formEncType": "formenctype";
            case "formMethod": "formmethod";
            case "formNoValidate": "formnovalidate";
            case "formTarget": "formtarget";
            case "frameBorder": "frameborder";
            case "marginHeight": "marginheight";
            case "marginWidth": "marginwidth";
            case "maxLength": "maxlength";
            case "minLength": "minlength";
            case "noValidate": "novalidate";
            case "readOnly": "readonly";
            case "rowSpan": "rowspan";
            case "colSpan": "colspan";
            case "srcDoc": "srcdoc";
            case "srcLang": "srclang";
            case "srcSet": "srcset";
            case "useMap": "usemap";
            case "itemProp": "itemprop";
            
            // Phoenix LiveView with snake_case (phx_click -> phx-click)
            case s if (StringTools.startsWith(s, "phx_")):
                s.split("_").join("-");
                
            // Phoenix LiveView with camelCase (phxClick -> phx-click)
            case s if (StringTools.startsWith(s, "phx") && s.indexOf("_") == -1):
                "phx-" + camelToKebab(s.substring(3));
                
            // ARIA attributes with snake_case (aria_label -> aria-label)
            case s if (StringTools.startsWith(s, "aria_")):
                s.split("_").join("-");
                
            // ARIA attributes with camelCase (ariaLabel -> aria-label)
            case s if (StringTools.startsWith(s, "aria") && s.indexOf("_") == -1):
                "aria-" + camelToKebab(s.substring(4));
                
            // Data attributes with snake_case (data_test_id -> data-test-id)
            case s if (StringTools.startsWith(s, "data_")):
                s.split("_").join("-");
                
            // Data attributes with camelCase (dataTestId -> data-test-id)
            case s if (StringTools.startsWith(s, "data") && s.indexOf("_") == -1):
                "data-" + camelToKebab(s.substring(4));
                
            // Already has hyphens (already in kebab-case)
            case s if (s.indexOf("-") != -1):
                s;
                
            // Has underscores (snake_case -> kebab-case)
            case s if (s.indexOf("_") != -1):
                s.split("_").join("-");
                
            // Simple lowercase (no conversion needed)
            case s if (s == s.toLowerCase()):
                s;
                
            // Default: camelCase to kebab-case
            default: 
                camelToKebab(name);
        }
    }
    
    /**
     * Convert camelCase to kebab-case
     */
    private static function camelToKebab(str: String): String {
        var result = "";
        for (i in 0...str.length) {
            var char = str.charAt(i);
            if (char == char.toUpperCase() && i > 0) {
                result += "-" + char.toLowerCase();
            } else {
                result += char.toLowerCase();
            }
        }
        return result;
    }
    
    // ========================================================================
    // PRIVATE HELPERS
    // ========================================================================
    
    private static function validateComponentAttribute(component: ComponentDefinition, attributeName: String): Bool {
        for (attr in component.attributes) {
            if (attr.name == attributeName) {
                return true;
            }
        }
        // Check global attributes
        return getGlobalAttributes().indexOf(attributeName) != -1;
    }
    
    // ========================================================================
    // ATTRIBUTE LISTS
    // ========================================================================
    
    private static function getGlobalAttributes(): Array<String> {
        return [
            // Core
            "id", "className", "style", "title",
            // Accessibility
            "role", "ariaLabel", "ariaLabelledby", "ariaDescribedby", 
            "ariaHidden", "tabIndex",
            // Phoenix LiveView
            "phxClick", "phxChange", "phxSubmit", "phxBlur", "phxFocus",
            "phxKeydown", "phxKeyup", "phxMouseenter", "phxMouseleave",
            "phxHook", "phxTarget", "phxDebounce", "phxThrottle", 
            "phxUpdate", "phxTrackStatic", "phxShow",
            // Data attributes are dynamic
            "data*"
        ];
    }
    
    private static function getInputAttributes(): Array<String> {
        return getGlobalAttributes().concat([
            "type", "name", "value", "placeholder", "required", "disabled",
            "readonly", "autofocus", "autocomplete", "pattern", "min", "max",
            "minLength", "maxLength", "step", "form", "accept", "multiple", "list"
        ]);
    }
    
    private static function getButtonAttributes(): Array<String> {
        return getGlobalAttributes().concat([
            "type", "name", "value", "disabled", "form", "formAction",
            "formMethod", "formTarget", "formNoValidate"
        ]);
    }
    
    private static function getFormAttributes(): Array<String> {
        return getGlobalAttributes().concat([
            "action", "method", "enctype", "target", "noValidate", "autocomplete",
            "phxSubmit", "phxChange", "phxTriggerAction"
        ]);
    }
    
    private static function getSelectAttributes(): Array<String> {
        return getGlobalAttributes().concat([
            "name", "multiple", "size", "required", "disabled", "form"
        ]);
    }
    
    private static function getOptionAttributes(): Array<String> {
        return getGlobalAttributes().concat([
            "value", "label", "selected", "disabled"
        ]);
    }
    
    private static function getTextAreaAttributes(): Array<String> {
        return getGlobalAttributes().concat([
            "name", "rows", "cols", "placeholder", "required", "disabled",
            "readonly", "maxLength", "minLength", "wrap", "form"
        ]);
    }
    
    private static function getLabelAttributes(): Array<String> {
        return getGlobalAttributes().concat([
            "htmlFor", "form"
        ]);
    }
    
    private static function getAnchorAttributes(): Array<String> {
        return getGlobalAttributes().concat([
            "href", "target", "rel", "download", "hreflang", "type",
            "referrerPolicy", "phxLink", "phxLinkState"
        ]);
    }
    
    private static function getImageAttributes(): Array<String> {
        return getGlobalAttributes().concat([
            "src", "alt", "width", "height", "loading", "decoding",
            "crossorigin", "srcset", "sizes", "usemap", "ismap"
        ]);
    }
    
    private static function getVideoAttributes(): Array<String> {
        return getGlobalAttributes().concat([
            "src", "poster", "width", "height", "autoplay", "controls",
            "loop", "muted", "preload", "crossorigin"
        ]);
    }
    
    private static function getAudioAttributes(): Array<String> {
        return getGlobalAttributes().concat([
            "src", "autoplay", "controls", "loop", "muted", "preload", "crossorigin"
        ]);
    }
    
    private static function getListAttributes(): Array<String> {
        return getGlobalAttributes().concat([
            "reversed", "start", "type"
        ]);
    }
    
    private static function getListItemAttributes(): Array<String> {
        return getGlobalAttributes().concat([
            "value"
        ]);
    }
    
    private static function getTableCellAttributes(): Array<String> {
        return getGlobalAttributes().concat([
            "colspan", "rowspan", "headers", "scope"
        ]);
    }
    
    private static function getMetaAttributes(): Array<String> {
        return [
            "name", "content", "httpEquiv", "charset", "property"
        ];
    }
    
    private static function getLinkAttributes(): Array<String> {
        return [
            "href", "rel", "type", "media", "sizes", "crossorigin",
            "integrity", "referrerPolicy", "as"
        ];
    }
    
    private static function getScriptAttributes(): Array<String> {
        return getGlobalAttributes().concat([
            "src", "type", "async", "defer", "crossorigin",
            "integrity", "noModule", "referrerPolicy"
        ]);
    }
    
    private static function getStyleAttributes(): Array<String> {
        return getGlobalAttributes().concat([
            "media", "nonce"
        ]);
    }
}

/**
 * Element type information
 */
typedef ElementTypeInfo = {
    name: String,
    attributeType: String,
    allowedAttributes: Array<String>,
    voidElement: Bool,
}
