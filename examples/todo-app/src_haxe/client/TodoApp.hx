package client;

import shared.TodoTypes;
import client.hooks.Hooks;
import client.utils.DarkMode;
import client.utils.LocalStorage;

/**
 * Main client-side entry point for Todo App
 * Compiles to JavaScript and integrates with Phoenix LiveView
 * 
 * This provides a clean, modular architecture for client-side functionality
 * while maintaining type safety throughout the application.
 */
class TodoApp {
    
    private static var isInitialized: Bool = false;
    
    /**
     * Application entry point
     * Called when the JavaScript loads in the browser
     */
    @:expose
    public static function main(): Void {
        if (isInitialized) {
            trace("TodoApp already initialized");
            return;
        }
        
        trace("Todo App client initializing...");
        
        // Initialize client-side utilities
        initializeUtilities();
        
        // Set up global error handling
        setupGlobalErrorHandling();
        
        // Export hooks for Phoenix LiveView
        exportHooks();
        
        // Initialize UI enhancements
        initializeEnhancements();
        
        isInitialized = true;
        trace("Todo App client ready!");
    }
    
    /**
     * Initialize client-side utilities
     */
    private static function initializeUtilities(): Void {
        DarkMode.initialize();
        LocalStorage.initialize();
    }
    
    /**
     * Set up global error handling for the client
     */
    private static function setupGlobalErrorHandling(): Void {
        js.Browser.window.addEventListener("error", function(event) {
            trace('Client error: ${event.error}');
            // Could send to server for logging via LiveView
            logErrorToServer("javascript_error", {
                message: event.message,
                filename: event.filename,
                lineno: event.lineno,
                colno: event.colno,
                timestamp: Date.now().getTime()
            });
        });
        
        js.Browser.window.addEventListener("unhandledrejection", function(event) {
            trace('Unhandled promise rejection: ${event.reason}');
            logErrorToServer("promise_rejection", {
                reason: Std.string(event.reason),
                timestamp: Date.now().getTime()
            });
        });
    }
    
    /**
     * Export hooks for Phoenix LiveView to use
     * This makes our Haxe hooks available to the Phoenix JavaScript runtime
     */
    private static function exportHooks(): Void {
        var hooks = Hooks.getAll();
        
        // Export to global scope for Phoenix LiveView using modern js.Syntax.code
        js.Syntax.code("
            // Make hooks available globally
            if (typeof window !== 'undefined') {
                window.TodoAppHooks = {0};
                
                // Also export individual hooks for direct access
                window.AutoFocus = {1};
                window.ThemeToggle = {2};
                window.TodoForm = {3};
                window.TodoFilter = {4};
                window.LiveSync = {5};
            }
            
            // Export as ES6 module
            if (typeof module !== 'undefined' && module.exports) {
                module.exports = {
                    Hooks: {0},
                    AutoFocus: {1},
                    ThemeToggle: {2},
                    TodoForm: {3},
                    TodoFilter: {4},
                    LiveSync: {5}
                };
            }
        ", 
            hooks,
            Hooks.getAutoFocus(),
            Hooks.getThemeToggle(),
            Hooks.getTodoForm(),
            Hooks.getTodoFilter(),
            Hooks.getLiveSync()
        );
        
        trace("Phoenix LiveView hooks exported successfully");
    }
    
    /**
     * Initialize UI enhancements and additional features
     */
    private static function initializeEnhancements(): Void {
        // Set up keyboard shortcuts
        setupGlobalKeyboardShortcuts();
        
        // Initialize performance monitoring
        setupPerformanceMonitoring();
        
        // Add CSS enhancements
        addDynamicStyles();
        
        // Initialize accessibility features
        setupAccessibilityFeatures();
    }
    
    /**
     * Set up global keyboard shortcuts
     */
    private static function setupGlobalKeyboardShortcuts(): Void {
        js.Browser.document.addEventListener("keydown", function(e: js.html.KeyboardEvent) {
            // Only handle shortcuts if not in input/textarea (type-safe casting)
            var target = e.target;
            if (target != null && js.Syntax.instanceof(target, js.html.Element)) {
                var element = cast(target, js.html.Element);
                if (element.nodeName == "INPUT" || element.nodeName == "TEXTAREA") {
                    return;
                }
            }
            
            // Global shortcuts
            if (e.ctrlKey || e.metaKey) {
                switch (e.key) {
                    case "k": // Cmd/Ctrl + K: Quick search
                        e.preventDefault();
                        focusSearch();
                    
                    case "n": // Cmd/Ctrl + N: New todo
                        e.preventDefault();
                        triggerNewTodo();
                    
                    case "/": // Cmd/Ctrl + /: Show keyboard shortcuts
                        e.preventDefault();
                        showKeyboardShortcuts();
                }
            }
            
            // Other shortcuts
            switch (e.key) {
                case "?": // Show help
                    if (e.shiftKey) {
                        e.preventDefault();
                        showKeyboardShortcuts();
                    }
            }
        });
    }
    
    /**
     * Set up performance monitoring
     */
    private static function setupPerformanceMonitoring(): Void {
        // Monitor page load performance using modern PerformanceNavigationTiming API
        js.Browser.window.addEventListener("load", function() {
            if (js.Browser.window.performance != null) {
                try {
                    // Use modern PerformanceNavigationTiming API instead of deprecated timing
                    var entries = js.Browser.window.performance.getEntriesByType("navigation");
                    if (entries.length > 0) {
                        var navTiming: js.html.PerformanceNavigationTiming = cast entries[0];
                        var domLoadTime = navTiming.domContentLoadedEventEnd - navTiming.domContentLoadedEventStart;
                        var fullLoadTime = navTiming.loadEventEnd - navTiming.fetchStart;
                        
                        trace('DOM load time: ${domLoadTime}ms, Full page load: ${fullLoadTime}ms');
                        logMetricToServer("dom_load_time", domLoadTime);
                        logMetricToServer("page_load_time", fullLoadTime);
                    } else {
                        // Fallback for browsers that don't support PerformanceNavigationTiming
                        trace("PerformanceNavigationTiming not supported, using basic measurement");
                    }
                } catch (e: Dynamic) {
                    trace('Performance monitoring error: ${e}');
                }
            }
        });
        
        // Monitor LiveView connection time
        monitorLiveViewPerformance();
    }
    
    /**
     * Add dynamic CSS styles for enhancements
     */
    private static function addDynamicStyles(): Void {
        var style = js.Browser.document.createStyleElement();
        style.textContent = '
            /* Todo App Enhanced Styles */
            .todo-item {
                transition: all 0.2s ease;
            }
            
            .todo-item:hover {
                transform: translateX(2px);
            }
            
            .updated-highlight {
                background: rgba(59, 130, 246, 0.1);
                border-left: 3px solid #3B82F6;
                animation: highlightFade 2s ease-out;
            }
            
            @keyframes highlightFade {
                from { 
                    background: rgba(59, 130, 246, 0.3);
                    transform: scale(1.01);
                }
                to { 
                    background: rgba(59, 130, 246, 0.1);
                    transform: scale(1);
                }
            }
            
            .theme-toggle-clicked {
                transform: scale(0.95);
                transition: transform 0.1s ease;
            }
            
            .connection-status {
                font-size: 0.75rem;
                color: #6B7280;
            }
            
            .connection-status.online {
                color: #10B981;
            }
            
            .connection-status.offline {
                color: #EF4444;
            }
            
            /* Keyboard shortcuts overlay */
            .keyboard-shortcuts-overlay {
                position: fixed;
                top: 0;
                left: 0;
                right: 0;
                bottom: 0;
                background: rgba(0, 0, 0, 0.8);
                z-index: 1000;
                display: flex;
                align-items: center;
                justify-content: center;
            }
            
            .keyboard-shortcuts-panel {
                background: white;
                dark:bg-gray-800;
                border-radius: 0.5rem;
                padding: 2rem;
                max-width: 500px;
                max-height: 80vh;
                overflow-y: auto;
            }
        ';
        js.Browser.document.head.appendChild(style);
    }
    
    /**
     * Set up accessibility features
     */
    private static function setupAccessibilityFeatures(): Void {
        // Add skip links for keyboard navigation
        addSkipLinks();
        
        // Enhance focus management
        setupFocusManagement();
        
        // Add ARIA live regions for status updates
        setupLiveRegions();
    }
    
    /**
     * Add skip links for accessibility
     */
    private static function addSkipLinks(): Void {
        var skipLinks = js.Browser.document.createDivElement();
        skipLinks.className = "sr-only focus:not-sr-only focus:absolute focus:top-4 focus:left-4 z-50";
        skipLinks.innerHTML = '
            <a href="#main-content" class="bg-blue-600 text-white px-4 py-2 rounded-md">
                Skip to main content
            </a>
            <a href="#todo-form" class="bg-blue-600 text-white px-4 py-2 rounded-md ml-2">
                Skip to new todo form
            </a>
        ';
        js.Browser.document.body.insertBefore(skipLinks, js.Browser.document.body.firstChild);
    }
    
    /**
     * Set up focus management
     */
    private static function setupFocusManagement(): Void {
        // Trap focus in modals when open
        // This would be expanded based on specific modal implementations
    }
    
    /**
     * Set up ARIA live regions for status updates
     */
    private static function setupLiveRegions(): Void {
        var liveRegion = js.Browser.document.createDivElement();
        liveRegion.id = "live-region";
        liveRegion.setAttribute("aria-live", "polite");
        liveRegion.setAttribute("aria-atomic", "true");
        liveRegion.className = "sr-only";
        js.Browser.document.body.appendChild(liveRegion);
    }
    
    /**
     * Focus the search input
     */
    private static function focusSearch(): Void {
        var searchInput = js.Browser.document.querySelector('input[type="text"][placeholder*="Search"]');
        if (searchInput != null) {
            searchInput.focus();
        }
    }
    
    /**
     * Trigger new todo creation
     */
    private static function triggerNewTodo(): Void {
        var newTodoButton = js.Browser.document.querySelector('[phx-click="toggle_form"]');
        if (newTodoButton != null) {
            newTodoButton.click();
        }
    }
    
    /**
     * Show keyboard shortcuts overlay
     */
    private static function showKeyboardShortcuts(): Void {
        var overlay = js.Browser.document.querySelector(".keyboard-shortcuts-overlay");
        if (overlay != null) {
            overlay.style.display = "flex";
            return;
        }
        
        // Create shortcuts overlay
        overlay = js.Browser.document.createDivElement();
        overlay.className = "keyboard-shortcuts-overlay";
        overlay.innerHTML = '
            <div class="keyboard-shortcuts-panel">
                <h3 class="text-lg font-bold mb-4">Keyboard Shortcuts</h3>
                <div class="space-y-2 text-sm">
                    <div><kbd>Ctrl/Cmd + K</kbd> - Focus search</div>
                    <div><kbd>Ctrl/Cmd + N</kbd> - New todo</div>
                    <div><kbd>Ctrl/Cmd + /</kbd> - Show shortcuts</div>
                    <div><kbd>Alt + 1/2/3</kbd> - Filter todos</div>
                    <div><kbd>Escape</kbd> - Close forms/modals</div>
                    <div><kbd>Ctrl/Cmd + Enter</kbd> - Submit form</div>
                </div>
                <button class="mt-4 px-4 py-2 bg-gray-200 rounded close-shortcuts">Close</button>
            </div>
        ';
        
        // Add close functionality
        overlay.addEventListener("click", function(e) {
            if (e.target == overlay || e.target.classList.contains("close-shortcuts")) {
                overlay.style.display = "none";
            }
        });
        
        js.Browser.document.body.appendChild(overlay);
    }
    
    /**
     * Monitor LiveView performance
     */
    private static function monitorLiveViewPerformance(): Void {
        // This would hook into Phoenix LiveView events to monitor connection performance
        // For now, just a placeholder
        trace("LiveView performance monitoring initialized");
    }
    
    /**
     * Log error to server via LiveView
     */
    private static function logErrorToServer(type: String, details: Dynamic): Void {
        // This would use Phoenix LiveView to send error logs to the server
        // For now, just store locally
        LocalStorage.setObject('last_error_${type}', {
            type: type,
            details: details,
            timestamp: Date.now().getTime()
        });
    }
    
    /**
     * Log metric to server
     */
    private static function logMetricToServer(metric: String, value: Float): Void {
        // This would send performance metrics to the server
        LocalStorage.setNumber('metric_${metric}', value);
    }
    
    /**
     * Get hook definitions for PhoenixApp integration.
     * 
     * Called by PhoenixApp to retrieve hook definitions without
     * automatically initializing everything. This allows PhoenixApp
     * to control initialization timing and error handling.
     */
    public static function getHooks(): Dynamic {
        return Hooks.getAll();
    }
    
    /**
     * Utility function for client-side state management
     */
    public static function getClientState(): ClientState {
        return {
            darkMode: DarkMode.isEnabled(),
            autoSave: LocalStorage.getBoolean("autoSave", true),
            lastSync: Date.now().getTime()
        };
    }
    
    /**
     * Update client state
     */
    public static function updateClientState(state: ClientState): Void {
        if (state.darkMode != DarkMode.isEnabled()) {
            DarkMode.toggle();
        }
        
        LocalStorage.setBoolean("autoSave", state.autoSave);
    }
    
    /**
     * Announce status update to screen readers
     */
    public static function announceStatus(message: String): Void {
        var liveRegion = js.Browser.document.getElementById("live-region");
        if (liveRegion != null) {
            liveRegion.textContent = message;
        }
    }
}