package client.hooks;

import js.html.Element;
import js.html.FormElement;
import js.html.InputElement;
import js.html.TextAreaElement;
import js.html.KeyboardEvent;
import client.extern.Phoenix.LiveViewHook;
import client.utils.LocalStorage;

/**
 * TodoForm hook for enhanced form interactions
 * Handles auto-save, keyboard shortcuts, and form validation
 */
class TodoForm implements LiveViewHook {
    
    public var el: Element;
    
    private var autoSaveTimer: Int = -1;
    private var autoSaveDelay: Int = 1000; // 1 second
    
    public function new() {}
    
    /**
     * Set up form enhancements when mounted
     */
    public function mounted(): Void {
        if (!Std.isOfType(el, FormElement)) {
            trace("TodoForm hook must be attached to a form element");
            return;
        }
        
        setupKeyboardShortcuts();
        setupAutoSave();
        setupFormValidation();
        restoreFormData();
    }
    
    /**
     * Clean up when destroyed
     */
    public function destroyed(): Void {
        clearAutoSaveTimer();
        clearFormData();
    }
    
    /**
     * Set up keyboard shortcuts for the form
     */
    private function setupKeyboardShortcuts(): Void {
        var form: FormElement = cast el;
        
        form.addEventListener("keydown", function(e: KeyboardEvent) {
            // Ctrl/Cmd + Enter: Submit form
            if ((e.ctrlKey || e.metaKey) && e.key == "Enter") {
                e.preventDefault();
                submitForm();
            }
            
            // Escape: Clear form or cancel edit
            if (e.key == "Escape") {
                e.preventDefault();
                clearForm();
                pushEventIfAvailable("cancel_edit", {});
            }
            
            // Ctrl/Cmd + S: Save draft
            if ((e.ctrlKey || e.metaKey) && e.key == "s") {
                e.preventDefault();
                saveDraft();
            }
        });
    }
    
    /**
     * Set up auto-save functionality
     */
    private function setupAutoSave(): Void {
        var inputs = el.querySelectorAll("input, textarea, select");
        
        for (i in 0...inputs.length) {
            var input = inputs[i];
            
            input.addEventListener("input", function(e) {
                scheduleAutoSave();
            });
            
            input.addEventListener("change", function(e) {
                scheduleAutoSave();
            });
        }
    }
    
    /**
     * Set up form validation enhancements
     */
    private function setupFormValidation(): Void {
        var form: FormElement = cast el;
        
        form.addEventListener("submit", function(e) {
            if (!validateForm()) {
                e.preventDefault();
                showValidationErrors();
            }
        });
        
        // Real-time validation on blur
        var inputs = el.querySelectorAll("input[required], textarea[required]");
        for (i in 0...inputs.length) {
            var input = inputs[i];
            input.addEventListener("blur", function(e) {
                validateField(cast e.target);
            });
        }
    }
    
    /**
     * Schedule auto-save with debouncing
     */
    private function scheduleAutoSave(): Void {
        clearAutoSaveTimer();
        
        // Only auto-save if enabled in settings
        if (!LocalStorage.getBoolean("autoSave", true)) return;
        
        autoSaveTimer = js.Browser.window.setTimeout(function() {
            saveDraft();
        }, autoSaveDelay);
    }
    
    /**
     * Clear the auto-save timer
     */
    private function clearAutoSaveTimer(): Void {
        if (autoSaveTimer != -1) {
            js.Browser.window.clearTimeout(autoSaveTimer);
            autoSaveTimer = -1;
        }
    }
    
    /**
     * Save form data as draft
     */
    private function saveDraft(): Void {
        var formData = getFormData();
        var formId = el.getAttribute("id") ?? "default_form";
        
        LocalStorage.setObject('form_draft_${formId}', {
            data: formData,
            timestamp: Date.now().getTime()
        });
        
        // Visual feedback for auto-save
        showSaveIndicator();
    }
    
    /**
     * Restore form data from draft
     */
    private function restoreFormData(): Void {
        var formId = el.getAttribute("id") ?? "default_form";
        var draft = LocalStorage.getObject('form_draft_${formId}');
        
        if (draft != null && draft.data != null) {
            // Check if draft is recent (within 24 hours)
            var now = Date.now().getTime();
            var age = now - draft.timestamp;
            var maxAge = 24 * 60 * 60 * 1000; // 24 hours
            
            if (age < maxAge) {
                setFormData(draft.data);
                showDraftRestoredIndicator();
            } else {
                // Clean up old draft
                clearFormData();
            }
        }
    }
    
    /**
     * Get form data as an object
     */
    private function getFormData(): Dynamic {
        var form: FormElement = cast el;
        var formData = new js.html.FormData(form);
        var data = {};
        
        // Convert FormData to plain object
        untyped __js__("
            for (let [key, value] of formData.entries()) {
                data[key] = value;
            }
        ");
        
        return data;
    }
    
    /**
     * Set form data from an object
     */
    private function setFormData(data: Dynamic): Void {
        for (field in Reflect.fields(data)) {
            var value = Reflect.field(data, field);
            var input = el.querySelector('[name="$field"]');
            
            if (input != null) {
                if (Std.isOfType(input, InputElement)) {
                    var inputEl: InputElement = cast input;
                    inputEl.value = Std.string(value);
                } else if (Std.isOfType(input, TextAreaElement)) {
                    var textareaEl: TextAreaElement = cast input;
                    textareaEl.value = Std.string(value);
                }
            }
        }
    }
    
    /**
     * Validate the entire form
     */
    private function validateForm(): Bool {
        var form: FormElement = cast el;
        var isValid = true;
        
        var requiredInputs = el.querySelectorAll("input[required], textarea[required]");
        for (i in 0...requiredInputs.length) {
            var input = requiredInputs[i];
            if (!validateField(cast input)) {
                isValid = false;
            }
        }
        
        return isValid;
    }
    
    /**
     * Validate a single field
     */
    private function validateField(input: Element): Bool {
        var isValid = true;
        
        if (Std.isOfType(input, InputElement)) {
            var inputEl: InputElement = cast input;
            
            // Check required
            if (inputEl.required && StringTools.trim(inputEl.value) == "") {
                showFieldError(inputEl, "This field is required");
                isValid = false;
            } else {
                clearFieldError(inputEl);
            }
        }
        
        return isValid;
    }
    
    /**
     * Show validation error for a field
     */
    private function showFieldError(input: InputElement, message: String): Void {
        input.classList.add("border-red-500", "focus:border-red-500");
        input.classList.remove("border-gray-300", "focus:border-blue-500");
        
        // Find or create error message element
        var errorId = '${input.name}_error';
        var existingError = js.Browser.document.getElementById(errorId);
        
        if (existingError == null) {
            var errorEl = js.Browser.document.createDivElement();
            errorEl.id = errorId;
            errorEl.className = "text-red-500 text-sm mt-1";
            errorEl.textContent = message;
            input.parentElement.appendChild(errorEl);
        } else {
            existingError.textContent = message;
        }
    }
    
    /**
     * Clear validation error for a field
     */
    private function clearFieldError(input: InputElement): Void {
        input.classList.remove("border-red-500", "focus:border-red-500");
        input.classList.add("border-gray-300", "focus:border-blue-500");
        
        var errorId = '${input.name}_error';
        var errorEl = js.Browser.document.getElementById(errorId);
        if (errorEl != null) {
            errorEl.remove();
        }
    }
    
    /**
     * Submit the form
     */
    private function submitForm(): Void {
        var form: FormElement = cast el;
        if (validateForm()) {
            form.submit();
            clearFormData(); // Clear draft after successful submit
        }
    }
    
    /**
     * Clear the form
     */
    private function clearForm(): Void {
        var form: FormElement = cast el;
        form.reset();
        clearFormData();
    }
    
    /**
     * Clear saved form data
     */
    private function clearFormData(): Void {
        var formId = el.getAttribute("id") ?? "default_form";
        LocalStorage.remove('form_draft_${formId}');
    }
    
    /**
     * Show visual indicator for auto-save
     */
    private function showSaveIndicator(): Void {
        // Implementation would show a subtle "saved" indicator
        // For now, just log it
        trace("Form auto-saved");
    }
    
    /**
     * Show indicator that draft was restored
     */
    private function showDraftRestoredIndicator(): Void {
        // Implementation would show "draft restored" message
        trace("Form draft restored");
    }
    
    /**
     * Show validation errors
     */
    private function showValidationErrors(): Void {
        // Focus on first invalid field
        var firstInvalid = el.querySelector(".border-red-500");
        if (firstInvalid != null) {
            firstInvalid.focus();
        }
    }
    
    /**
     * Push event to LiveView if available
     */
    private function pushEventIfAvailable(event: String, payload: Dynamic): Void {
        try {
            var pushEvent = Reflect.field(this, "pushEvent");
            if (pushEvent != null && Reflect.isFunction(pushEvent)) {
                pushEvent(event, payload);
            }
        } catch (e: Dynamic) {
            trace('Could not push event ${event}: ${e}');
        }
    }
}