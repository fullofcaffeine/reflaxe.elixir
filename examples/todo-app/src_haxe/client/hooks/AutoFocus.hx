package client.hooks;

import js.html.Element;
import js.html.InputElement;
import js.html.TextAreaElement;
import client.extern.Phoenix.LiveViewHook;

/**
 * AutoFocus hook for automatic focus on form inputs
 * Focuses the element when mounted and optionally when updated
 */
class AutoFocus implements LiveViewHook {
    
    public var el: Element;
    
    public function new() {}
    
    /**
     * Focus the element when mounted
     */
    public function mounted(): Void {
        focusElement();
    }
    
    /**
     * Optionally focus again when updated (if specified in data attributes)
     */
    public function updated(): Void {
        var refocusOnUpdate = el.getAttribute("data-refocus-on-update");
        if (refocusOnUpdate == "true") {
            focusElement();
        }
    }
    
    /**
     * Focus the element with proper type checking
     */
    private function focusElement(): Void {
        // Small delay to ensure the element is fully rendered
        js.Browser.window.setTimeout(function() {
            try {
                if (Std.isOfType(el, InputElement)) {
                    var input: InputElement = cast el;
                    input.focus();
                    
                    // Position cursor at end if it's a text input
                    if (input.type == "text" || input.type == "email" || input.type == "search") {
                        var length = input.value.length;
                        input.setSelectionRange(length, length);
                    }
                } else if (Std.isOfType(el, TextAreaElement)) {
                    var textarea: TextAreaElement = cast el;
                    textarea.focus();
                    
                    // Position cursor at end
                    var length = textarea.value.length;
                    textarea.setSelectionRange(length, length);
                } else {
                    // Generic focus for other elements
                    el.focus();
                }
            } catch (e: Dynamic) {
                trace('AutoFocus error: $e');
            }
        }, 10);
    }
}