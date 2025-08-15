package client.hooks;

import js.html.Element;
import js.html.ButtonElement;
import client.extern.Phoenix.LiveViewHook;
import client.utils.DarkMode;

/**
 * Theme toggle hook for dark/light mode switching
 * Manages theme toggle button state and interactions
 */
class ThemeToggle implements LiveViewHook {
    
    public var el: Element;
    
    public function new() {}
    
    /**
     * Set up theme toggle when mounted
     */
    public function mounted(): Void {
        setupToggleButton();
        updateButtonState();
    }
    
    /**
     * Update button state when the component updates
     */
    public function updated(): Void {
        updateButtonState();
    }
    
    /**
     * Set up click event listener for the toggle button
     */
    private function setupToggleButton(): Void {
        if (!Std.isOfType(el, ButtonElement)) {
            trace("ThemeToggle hook must be attached to a button element");
            return;
        }
        
        var button: ButtonElement = cast el;
        
        button.addEventListener("click", function(e) {
            e.preventDefault();
            
            // Toggle the theme
            DarkMode.toggle();
            
            // Update button visual state
            updateButtonState();
            
            // Optional: Notify LiveView of theme change
            var theme = DarkMode.isEnabled() ? "dark" : "light";
            pushEventIfAvailable("theme_changed", {theme: theme});
            
            // Add visual feedback
            addClickFeedback(button);
        });
    }
    
    /**
     * Update the button's visual state based on current theme
     */
    private function updateButtonState(): Void {
        var button: ButtonElement = cast el;
        var isDark = DarkMode.isEnabled();
        
        // Update button title/tooltip
        button.title = isDark ? "Switch to light mode" : "Switch to dark mode";
        
        // Update aria-label for accessibility
        button.setAttribute("aria-label", isDark ? "Switch to light mode" : "Switch to dark mode");
        
        // Update data attribute for CSS styling
        button.setAttribute("data-theme", isDark ? "dark" : "light");
        
        // Update icon visibility if icons are present
        updateIconVisibility(isDark);
    }
    
    /**
     * Update icon visibility for dark/light mode icons
     */
    private function updateIconVisibility(isDark: Bool): Void {
        var darkIcon = el.querySelector("#theme-toggle-dark-icon");
        var lightIcon = el.querySelector("#theme-toggle-light-icon");
        
        if (darkIcon != null && lightIcon != null) {
            if (isDark) {
                // Dark mode active, show light icon (to switch to light)
                darkIcon.classList.add("hidden");
                lightIcon.classList.remove("hidden");
            } else {
                // Light mode active, show dark icon (to switch to dark)
                darkIcon.classList.remove("hidden");
                lightIcon.classList.add("hidden");
            }
        }
    }
    
    /**
     * Add visual feedback when button is clicked
     */
    private function addClickFeedback(button: ButtonElement): Void {
        // Add a temporary class for click animation
        button.classList.add("theme-toggle-clicked");
        
        // Remove the class after animation
        js.Browser.window.setTimeout(function() {
            button.classList.remove("theme-toggle-clicked");
        }, 200);
    }
    
    /**
     * Push event to LiveView if the pushEvent function is available
     */
    private function pushEventIfAvailable(event: String, payload: Dynamic): Void {
        try {
            // Check if pushEvent is available on this hook instance
            var pushEvent = Reflect.field(this, "pushEvent");
            if (pushEvent != null && Reflect.isFunction(pushEvent)) {
                pushEvent(event, payload);
            }
        } catch (e: Dynamic) {
            // Silently handle if pushEvent is not available
            trace('Could not push event ${event}: ${e}');
        }
    }
}