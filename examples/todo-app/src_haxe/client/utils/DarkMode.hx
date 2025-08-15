package client.utils;

import js.Browser;
import js.html.Element;

/**
 * Dark mode management utility
 * Handles theme detection, toggling, and persistence
 */
class DarkMode {
    
    private static inline var THEME_KEY = "theme";
    private static inline var DARK_CLASS = "dark";
    
    /**
     * Initialize dark mode system
     */
    public static function initialize(): Void {
        // Apply saved theme or system preference immediately
        applyTheme();
        
        // Set up theme toggle button if present
        setupToggleButton();
    }
    
    /**
     * Check if dark mode is currently enabled
     */
    public static function isEnabled(): Bool {
        return Browser.document.documentElement.classList.contains(DARK_CLASS);
    }
    
    /**
     * Toggle between light and dark mode
     */
    public static function toggle(): Void {
        if (isEnabled()) {
            setLightMode();
        } else {
            setDarkMode();
        }
    }
    
    /**
     * Enable dark mode
     */
    public static function setDarkMode(): Void {
        Browser.document.documentElement.classList.add(DARK_CLASS);
        LocalStorage.setString(THEME_KEY, "dark");
        updateToggleButton();
    }
    
    /**
     * Enable light mode
     */
    public static function setLightMode(): Void {
        Browser.document.documentElement.classList.remove(DARK_CLASS);
        LocalStorage.setString(THEME_KEY, "light");
        updateToggleButton();
    }
    
    /**
     * Get the current theme preference
     */
    public static function getTheme(): String {
        var saved = LocalStorage.getString(THEME_KEY);
        if (saved != null) return saved;
        
        // Check system preference
        if (Browser.window.matchMedia != null) {
            var darkMediaQuery = Browser.window.matchMedia("(prefers-color-scheme: dark)");
            return darkMediaQuery.matches ? "dark" : "light";
        }
        
        return "light";
    }
    
    /**
     * Apply the theme based on saved preference or system setting
     */
    private static function applyTheme(): Void {
        if (getTheme() == "dark") {
            Browser.document.documentElement.classList.add(DARK_CLASS);
        } else {
            Browser.document.documentElement.classList.remove(DARK_CLASS);
        }
    }
    
    /**
     * Set up the theme toggle button functionality
     */
    private static function setupToggleButton(): Void {
        var toggleButton = Browser.document.getElementById("theme-toggle");
        if (toggleButton == null) return;
        
        toggleButton.addEventListener("click", function(e) {
            e.preventDefault();
            toggle();
        });
        
        updateToggleButton();
    }
    
    /**
     * Update the toggle button icons based on current theme
     */
    private static function updateToggleButton(): Void {
        var darkIcon = Browser.document.getElementById("theme-toggle-dark-icon");
        var lightIcon = Browser.document.getElementById("theme-toggle-light-icon");
        
        if (darkIcon == null || lightIcon == null) return;
        
        if (isEnabled()) {
            // Dark mode is active, show light icon (to switch to light)
            darkIcon.classList.add("hidden");
            lightIcon.classList.remove("hidden");
        } else {
            // Light mode is active, show dark icon (to switch to dark)
            darkIcon.classList.remove("hidden");
            lightIcon.classList.add("hidden");
        }
    }
}